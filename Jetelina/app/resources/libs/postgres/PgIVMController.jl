"""
module: PgIVMController

Author: Ono keiji

Description:
	pg_ivm: incrementally maintainable materialized view extension controller for PostgreSQL

functions
    checkIVMExistence(conn) checkin' ivm is availability
    compareJsAndJv(conn, apino) compare max/min/mean execution speed between js* and jv*.
    createIVMtable(conn, apino::String) create ivm table from the apino's sql sentence
    dropIVMtable(ivmapino::String) drop ivm table
    collectIvmCandidateApis() collect apis that is using multiple tables in JC["tableapifile"].
    executeJVApi(conn,ivmapino::String) do experimental execution of target ivm api sql sentence
    jvSqlSentence(ivmapino::String) create sql sentence for ivm table
    executeJSApi(conn, apino::String) execute ordered sql(js*) sentence to compare with jv* execution speed
"""
module PgIVMController

using Genie, Genie.Renderer, Genie.Renderer.Json
using CSV, LibPQ, DataFrames, IterTools, Tables, Dates
using Jetelina.JFiles, Jetelina.JLog, Jetelina.InitApiSqlListManager.ApiSqlListManager, Jetelina.JMessage, Jetelina.JSession, Jetelina.DBDataController.PgDBController
import Jetelina.InitConfigManager.ConfigManager as j_config

JMessage.showModuleInCompiling(@__MODULE__)

export checkIVMExistence, createIVMtable, dropIVMtable, compareJsAndJv, collectIvmCandidateApis, executeJVApi

"""
function checkIVMExistence(conn)

    checkin' ivm is availability
	
# Arguments
- `conn::LibPQ.Connection`: postgresql connection 
- return: available -> true, not available -> false
"""
function checkIVMExistence(conn)
    ret = true # true -> ivm is available false -> not exist

    sql_str = """select * from pg_available_extensions where name ='pg_ivm';"""

    try
        sql_ret = LibPQ.execute(conn, sql_str)
        retnum = LibPQ.num_affected_rows(sql_ret)
        if retnum == 0
            ret = false
        end
    catch err
        ret = false
        JLog.writetoLogfile("PgIVMController.checkIVMExistence() error: $err")
    finally
    end

    if ret
        j_config.configParamUpdate(Dict("pg_ivm"=>ret))        
    end

    return ret
end
"""
function createIVMtable(conn, apino::String)

    create ivm table from the apino's sql sentence

# Arguments
- `conn::LibPQ.Connection`: postgresql connection 
- `apino::String`: apino in Df_JetelinaSqlList
- return: Boolean: true -> success, false -> couldn't create ivm table 	
"""
function createIVMtable(conn, apino::String)
    target_api = subset(ApiSqlListManager.Df_JetelinaSqlList, :apino => ByRow(==(apino)), skipmissing = true)
#    regulatedclauses::Array = ["having","union","intersect","except","distinct on","tablesample","value","tablesample","for update","share"]
#    allowclauses::Array = ["order by","limit","offset"]
    regulatedclauses::Array = split(j_config.JC["pg_regulatedclauses"],",")
    allowclauses::Array = split(j_config.JC["pg_allowclauses"],",")
    ivmsafe::Bool = true

    #===
        Tips:
            1. target api name(apino) should be changed to the ivm specail name. eg. js10 -> jv10
            2. escape "'" in the target sql sentence with "''", because "''" is the way of escaping in sql
            3. due to pg_ivm regulation, some clauses are band to create ivm table

            then simply kick execute()
    ===#
    ivmapino::String = replace(apino, "js" => "jv")

    ivmsubquery::Array = []
    jvsubquery = string(target_api[!,:subquery][1])
    for ac in allowclauses
        if contains(jvsubquery,ac)
            # take over the allowclauses to jv*, if there were in js*
            ss = split(jvsubquery)
            if 0<length(ss)
                for i in eachindex(ss)
                    if ss[i] ∈ allowclauses
                        # expecting the next (ss[i+1]) is integer number e.g. 100 or {limit} if ss[i] were "limit"
                        if !isnothing(ss[i+1])                            
                            push!(ivmsubquery, string(ss[i]," ",ss[i+1]))
                            jvsubquery = replace(jvsubquery, string(ss[i]," ",ss[i+1]) => "")
                        end
                    end
                end
            end
        end
    end

#    @info "ivmsubquery " ivmsubquery
#    @info "jvsubquery " jvsubquery
    
    sql::String = replace(string(target_api[!,:sql][1], " ", jvsubquery), "'" => "''")
    
    # regulated...にある句が存在した場合、ivm化はしない
#    for rc in regulatedclauses
#        if contains(sql, rc)
    if any(contains.(sql,regulatedclauses))
        ivmsafe = false
#       end
    end

    if ivmsafe
        executesql::String = """select pgivm.create_immv('$ivmapino','$sql');""" 

        try
            LibPQ.execute(conn, executesql)
            return true
        catch err
            println(err)
            JLog.writetoLogfile("PgIVMController.createIVMtable() with $ivmapino error : $err")
            return false
        finally
        end
    else
        return false
    end
end
"""
function dropIVMtable(ivmapino::String)

    drop ivm table

#Arguments
- `ivmapino::String`: apino as ivm
- return: tuple (boolean: true -> success/false -> get fail, JSON)
"""
function dropIVMtable(ivmapino::String)
    PgDBController.dropTable(["$ivmapino"])
end
"""
function compareJsAndJv(conn, apino)

    compare max/min/mean execution speed between js* and jv*.

# Arguments
- `apino`: target apino
"""
function compareJsAndJv(conn, apino)
#	apis::Array = collectIvmCandidateApis()
    ivmnized::String = "created ivm table for $apino"

    #
    #   Tips:
    #       this function is called when the target sql(apino) is constructed by multi tables.
    #       the sql has already registered in the sql list file.
    #       this function executes 2 steps
    #            1. creat ivm table for the sql if the api is not in "js vs jv" file yet.
    #               but it does not execute if the sql clause has some clauses sentences that are not permitted to use in creating ivm table.
    #               this checking of clauses are worked in createIVMtable()
    #            2. execute js and jv aps sevraltimes at background.
    #               then compares each speed.
    #               add the js to "js vs jv" file, if the execution speed of jv is better than js one.
    #               this adding is done in writeToMatchinglist()
    #            3. the created ivm table keeps alive if jv nized has been, but it is dropped if it were not.
    #               this dropping is handled in dropIVMtable()
    #
    jsjvdf = ApiSqlListManager.Df_JsJvList

    if string(apino) ∉ jsjvdf[!,:js] 
        try
    #        for apino in apis
                ret = createIVMtable(conn, string(apino))
                if ret
                    ivmapino::String = replace(apino, "js" => "jv")
                    jsspeed = executeJSApi(conn, string(apino))
                    jvspeed = executeJVApi(conn, ivmapino)

                    if j_config.JC["debug"]
                        @info "jsspeed: " jsspeed
                        @info "jvspeed: " jvspeed
                        @info "speed compare: jv_mean - js_mean " (jvspeed[3] - jsspeed[3])
                    end

                    #===
                        Tips:
                            in case js* is faster than jv*, use js* then drop jv* table
                            in case jv* is marverous, write the apino to js/jv matching file (j_config.JC["jsjvmatchingfile"])
                    ===#
                    if jsspeed[3] < jvspeed[3]
                        dropIVMtable(ivmapino)
                        ivmnized = "ivm table for $apino has not been created"
                    else
                        ApiSqlListManager.writeToMatchinglist(string(apino))
                    end

                    JLog.writetoLogfile(string("PgIVMController.compareJsAndJv(): $ivmnized because speed(jv): ", jvspeed[3], " is faster than spped(js): ", jsspeed[3]))
                end
    #       end
        catch err
            println(err)
            JLog.writetoLogfile("PgIVMController.compareJsAndJv() error : $err")
        finally
        end
    end
end

"""
function collectIvmCandidateApis() 
	
	collect apis that is using multiple tables in JC["tableapifile"].
    collected apis are matched with JC["jsjvmatchingfile"], then be removed existense jv* from the collected ones.

	Attention:
		this function is limited in PostgreSQL, because of IVM

# Arguments
- return: array of jv* candidates 
"""
function collectIvmCandidateApis()
    tableapiFile = JFiles.getFileNameFromConfigPath(j_config.JC["tableapifile"])
    #===
        Tips:
            both Df_JsJvList and jsjvFile can use here, but hired jsjvFile.
            because wanna unify the procedure with tableapiFile, and do not require an execution speed. :)
    ===#
    jsjvFile = JFiles.getFileNameFromConfigPath(j_config.JC["jsjvmatchingfile"])

    ret = []

    try
        open(tableapiFile, "r") do f
            for l in eachline(f, keep=false)
                p = split(l, ':')
				if p[3] == "postgresql"
					#===
					Tips:
						p[1] is unique api number.
						p[2] has possibility multi data. e.g table1,table2
					===#
					t = split(p[2], ',')
					if 1<length(t)
						push!(ret, p[1])
					end
				end
            end
        end

        if isfile(jsjvFile)
            open(jsjvFile, "r") do f
                for l in eachline(f, keep=false)
                    p = split(l, ',')
                    if p[1] ∈ ret 
                        setdiff(ret,[p[1]])
                    end
                end
            end
        end
    catch err
        println(err)
        JLog.writetoLogfile("PgIVMController.collectIvmCandidateApis() error: $err")
        return false
    end

    return ret

end

"""
function executeJVApi(conn,ivmapino::String)

    do experimental execution of target ivm api sql sentence
    sql sentence in ivm is definitly simple sql. e.g select * from <ivm table name>

# Arguments
- `conn::LibPQ.Connection`: postgresql connection 
- `ivmapino::String`: apino as ivm
- return:  false -> boolean false true -> tubple(max, min, mean) 	
"""
function executeJVApi(conn, ivmapino::String)
    sql::String = jvSqlSentence(ivmapino)
    return PgDBController.doSelect(sql, "measure")
end
"""
function jvSqlSentence(ivmapino::String)

    create sql sentence for ivm table
    indeed, this sql is simple, could put in executeJVApi(), but this sql has possible called in PgDBController,
    therefore made it this func

# Arguments
- `ivmapino::String`: apino
- return: sql string
"""
function jvSqlSentence(ivmapino::String)
    if startswith(ivmapino, "js")
        ivmapino = replace(ivmapino,"js" => "jv")
    end

    return """select * from $ivmapino"""
end
"""
function executeJSApi(conn, apino::String)

	execute ordered sql(js*) sentence to compare with jv* execution speed

# Arguments
- `apino::String`: execute target api number e.g js10
- return: ((max speed, sample number),(minimum speed, sample number), mean ), fale -> boolean: false. 
"""
function executeJSApi(conn, apino::String)
    target_api = subset(ApiSqlListManager.Df_JetelinaSqlList, :apino => ByRow(==(apino)), skipmissing = true)
    sql::String = string(target_api[!,:sql][1], " ", target_api[!,:subquery][1])

    return PgDBController.doSelect(sql,"measure")
end

end