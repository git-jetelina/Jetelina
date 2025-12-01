"""
module: ApiSqlListManager

Author: Ono keiji

Description:
	manage JC["sqllistfile"] file.
	this file determines a corrensponding SQL sentence to API.

functions
	getApiSequenceNumber()  get api sequence number from apisequencenumber in dataframe then update it +1
	readSqlList2DataFrame() import registered SQL sentence list in JC["sqllistfile"] to DataFrame.this function set the sql list data in the global variable 'Df_JetelinaSqlList' as DataFrame object.
	writeTolist(sql::String, subquery::String, tablename_arr::Vector{String}, db::String) create api no and write it to JC["sqllistfile"] order by SQL sentence.
	deleteTableFromlist(tablename::Vector) delete tables name from JC["sqllistfile"] synchronized with dropping table.
	deleteApiFromList(apis:Vector) delete api by ordering from JC["sqllistfile"] file, then refresh the DataFrame.
	getRelatedList(searchKey::String,target::String) earch in JetelinaTableApiRelation file to find 'target' due to 'searchKey'
	sqlDuplicationCheck(nsql::String, subq::String)  confirm duplication, if 'nsql' exists in JC["sqllistfile"].but checking is in Df_JetelinaSqlList, not the real file, because of execution speed. 

-- special funcs for ivm in postgresql---
    jsjvmatching2DataFrame() import js* jv* api matching list in JC["jsjvmatchingfile"] to DataFrame.this function set the matching list data in the global variable 'Df_jsJvList' as DataFrame object.
    writeToMatchinglist(apino::String) write js* and jv* matching to JC["jsjvmatchingfile"].
    deleteJvApiFromMatchingList(apis:Vector) delete api by ordering from JC["jsjvmatchingfile"] file, then refresh the DataFrame.
"""
module ApiSqlListManager

using DataFrames, CSV
using Jetelina.JFiles, Jetelina.JMessage, Jetelina.JLog
import Jetelina.InitConfigManager.ConfigManager as j_config

JMessage.showModuleInCompiling(@__MODULE__)

export Df_JetelinaSqlList, readSqlList2DataFrame, writeTolist, deleteTableFromlist, sqlDuplicationCheck, jsjvmatching2DataFrame, Df_JsJvList

"""
function __init__()

	this is the initialize process for importing registered SQL sentence list in JC["sqllistfile"] to DataFrame.
"""
function __init__()
    @info "=======ApiSqlListManager init=========="
    _setApiSequenceNumber()
end
"""
function _setApiSequenceNumber
	create api sequence number dataframe from the existing api numbers.
	this is the private function.
	this function set the sequence number 
		e.g.
			next api no will be 114 from
				ji111 .....
				js112 .....
				jd113 .....

	how to refer apisequencenumber  ..ApiSqlListManager.apisequencenumber.apino[1]
	how to update apisequencenumber ..ApiSqlListManager.apisequencenumber.apino[1] += 1
"""
function _setApiSequenceNumber()
    global Df_JetelinaSqlList = DataFrame()
    p = readSqlList2DataFrame()
    if p[1]
        df = p[2]
        #===
        	Tips:
        		Df_JetelinaSqlList is a global data.
        		this data has a possibility be accessed by other program, 
        		therefore it is listed in the export list 
        ===#
        Df_JetelinaSqlList = df
        existapino::Array = chop.(df.apino, head=2, tail=0)
        nextapino::Int = 1
        if 0 < nrow(df)
            nextapino = maximum(parse.(Int, existapino)) + 1
        end

        global apisequencenumber = DataFrame(apino=nextapino)

        if j_config.JC["debug"]
            @info apisequencenumber
        end
    end

    #===
        Tips:
            these are special for ivm in postgresql.
            jsjvmatching2DataFrame() retuns false if the target file were not, in case not postgresql.
            but set Df_Js... if the file existed, even if not postgresql. any problems?
    ===#
    pp = jsjvmatching2DataFrame()
    if pp[1]
        global Df_JsJvList = pp[2]
    end

end
"""
function getApiSequenceNumber()
	get api sequence number from apisequencenumber in dataframe then update it +1

# Arguments
- return: Integer: api sequence number 	
"""
function getApiSequenceNumber()
    ret::Int = apisequencenumber.apino[1]
    apisequencenumber.apino[1] += 1
    return ret
end
"""
function readSqlList2DataFrame()

	import registered SQL sentence list in JC["sqllistfile"] to DataFrame.
	this function set the sql list data in the global variable 'Df_JetelinaSqlList' as DataFrame object.

# Arguments
- return: Tuple: suceeded (true::Boolean, list of api/sql::DataFrames)
				 failed   (false::Boolean, nothing)

"""
function readSqlList2DataFrame()
    sqlFile = JFiles.getFileNameFromConfigPath(j_config.JC["sqllistfile"])
    if isfile(sqlFile)
        df = CSV.read(sqlFile, DataFrame)
        if j_config.JC["debug"]
            @info "ApiSqlListManager.readSqlList2DataFrame() sql list in DataFrame: ", df
        end

        #===
        			Tips:
        				to refresh Df_Jete....., 'global' keyword is mandatory. 😯
        		===#
        global Df_JetelinaSqlList = df

        return true, df
    end

    return false, nothing
end
"""
function writeTolist(sql::String, subquery::String, tablename_arr::Vector{String}, db::String)

	create api no and write it to JC["sqllistfile"] order by SQL sentence.
	
# Arguments
- `sql::String`: sql sentence
- `subquery::String`: sub query sentence
- `tablename_arr::Vector{String}`: table name list that are used in 'sql'
- `db::String`: data base name  e.g. postgresql,mysql,redis
- return: Tuple: suceeded (true::Boolean, api number name::String)
				 failed   (false::Boolean, nothing)
"""
function writeTolist(sql::String, subquery::String, tablename_arr::Vector{String}, db::String)
    sql = strip(sql)
    sqlFile = JFiles.getFileNameFromConfigPath(j_config.JC["sqllistfile"])
    tableapiFile = JFiles.getFileNameFromConfigPath(j_config.JC["tableapifile"])

    suffix = string()

    #===
    			Tips:
    				insert/update/select are for RDBMS
    				set/get are for Redis
    		===#
    if db == "postgresql" || db == "mysql"
        #===
        if startswith(sql, "insert") || (startswith(sql, "set") && (sql == "set::"))
            suffix = "ji"
        elseif startswith(sql, "update") && contains(sql, "jetelina_delete_flg=1")
            suffix = "jd"
        elseif startswith(sql, "update") || (startswith(sql, "set") && (sql != "set::"))
            suffix = "ju"
        elseif startswith(sql, "select") || startswith(sql, "get")
            suffix = "js"
        end
        ===#
        if startswith(sql, "insert")
            suffix = "ji"
        elseif startswith(sql, "update") && contains(sql, "jetelina_delete_flg=1")
            suffix = "jd"
        elseif startswith(sql, "update")
            suffix = "ju"
        elseif startswith(sql, "select")
            suffix = "js"
        end
    elseif db == "redis"
        if (startswith(sql, "set") && (sql == "set::"))
            suffix = "ji"
        elseif startswith(sql, "update") && contains(sql, "jetelina_delete_flg=1")
            #===
                Caution:
                    in fact, there is no 'jd' api in redis
            ===#
            suffix = "jd"
        elseif (startswith(sql, "set") && (sql != "set::"))
            suffix = "ju"
        elseif startswith(sql, "get")
            suffix = "js"
        end
    elseif db == "mongodb"
        if startswith(sql, "{insert")
            suffix = "ji"
        elseif startswith(sql, "{delete")
            suffix = "jd"
        elseif startswith(sql, "{update")
            suffix = "ju"
        else
            suffix = "js"
            sql = replace.(sql, "\"" => "\"\"")
        end
    end

    seq_no = getApiSequenceNumber()
    sqlsentence = """$suffix$seq_no,\"$sql\",\"$subquery\",\"$db\""""

    # write the sql to the file
    thefirstflg = true
    if !isfile(sqlFile)
        thefirstflg = false
    end

    try
        open(sqlFile, "a") do f
            if !thefirstflg
                println(f, string(j_config.JC["file_column_apino"], ',', j_config.JC["file_column_sql"], ',', j_config.JC["file_column_subquery"]), ',', j_config.JC["file_column_db"])
            end

            #            CSV.write(f, Tables.table([sqlsentence]); append=true)
            println(f, sqlsentence)
        end
    catch err
        JLog.writetoLogfile("ApiSqlListManager.writeTolist() error: $err")
        return false, nothing
    end

    # write the relation between tables and api to the file
    try
        open(tableapiFile, "a") do ff
            println(ff, string(suffix, seq_no, ":", join(tablename_arr, ","), ":", db))
        end
    catch err
        JLog.writetoLogfile("ApiSqlListManager.writeTolist() error: $err")
        return false, nothing
    end

    # update DataFrame
    readSqlList2DataFrame()

    #===
        Caution:
            .writetoOperationHistoryfile() requests the session data in it, 
            but mongodb has the document insertion webapi that creates the related apis,
            of course there is no issue in the case of executing on Jetelina console, but via webapi,
            therefore, now, to be exception it, tbh do not wanna change .writetoO...() now. :p
    ===#
    if db != "mongodb"
        # write to operationhistoryfile
        JLog.writetoOperationHistoryfile(string("create api", ",", suffix, seq_no))
    end

    return true, string(suffix, seq_no)
end
"""
function deleteTableFromlist(tablename::Vector)

	delete table name from JC["sqllistfile"] and JC["tableapifile"] synchronized with dropping table.

# Arguments
- `tablename::Vector`: target tables name
- return: boolean: true -> all done ,  false -> something failed
"""
function deleteTableFromlist(tablename::Vector)
    sqlFile = JFiles.getFileNameFromConfigPath(j_config.JC["sqllistfile"])
    tableapiFile = JFiles.getFileNameFromConfigPath(j_config.JC["tableapifile"])
    sqlTmpFile = string(sqlFile, ".tmp")
    tableapiTmpFile = string(tableapiFile, ",tmp")

    targetapi = []
    untargetapi = []

    # take the backup file
    JFiles.fileBackup(tableapiFile)
    JFiles.fileBackup(sqlFile)

    try
        open(tableapiTmpFile, "w") do ttaf
            open(tableapiFile, "r") do taf
                #===
                					Tips: 
                						'keep=false' omits the line-feed in each line, then do println()
                				===#
                for ss in eachline(taf, keep=false)
                    if contains(ss, ':')
                        p = split(ss, ":") # api_name:table,table,....
                        #===
                        							Tips:
                        								there is a chance to exist the same table name in postgres and mysql,
                        								therefore look at p[3]
                        						===#
                        if (p[3] == j_config.JC["dbtype"])
                            tmparr = split(p[2], ',')
                            for i in eachindex(tablename)
                                if tablename[i] ∈ tmparr
                                    push!(targetapi, p[1]) # ["js1","ji2,.....]
                                    setdiff!(untargetapi, [p[1]])
                                else
                                    # remain others in the file
                                    push!(untargetapi, p[1]) # ["js1","ji2,.....]
                                end
                            end
                        end
                    end
                end

                #===
                					Tips:
                						return to the file top ＼(^o^)／
                						indeed, there are 3 funcs in julia
                						   - seek(taf,0) move 'taf' to the position '0'
                						   - seekstart(taf) same above
                						   - seekend(taf) move 'taf' to the position tail

                						seek(taf,0) can apply here, but use seekstart(taf) because the position is obvioous
                				===#
                seekstart(taf)

                for ss in eachline(taf, keep=false)
                    if contains(ss, ':')
                        p = split(ss, ":") # api_name:table,table,....
                        if p[1] ∉ targetapi
                            println(ttaf, ss)
                        end
                    end
                end
            end
        end
    catch err
        JLog.writetoLogfile("ApiSqlListManager.deleteTableFromlist() error: $err")
        return false
    end

    # remain SQL sentence not include in the target api
    try
        open(sqlTmpFile, "w") do tf
            open(sqlFile, "r") do f
                for ss in eachline(f, keep=false)
                    p = split(ss, "\"") # js1,"select..."
                    if rstrip(p[1], ',') ∉ targetapi
                        # write out sql that does not contain the target table
                        println(tf, ss)
                    else
                    end
                end
            end
        end
    catch err
        JLog.writetoLogfile("ApiSqlListManager.deleteTableFromlist() error: $err")
        return false
    end

    # change the file name
    mv(sqlTmpFile, sqlFile, force=true)
    mv(tableapiTmpFile, tableapiFile, force=true)

    # update DataFrame
    readSqlList2DataFrame()

    return true
end
"""
function deleteApiFromList(apis:Vector)

	delete api by ordering from JC["sqllistfile"] and JC["tableapifile"] file, then refresh the DataFrame.
	
# Arguments
- `apis::Vector`: target apis name
- return: boolean: true -> all done ,  false -> something failed
"""
function deleteApiFromList(apis::Vector)
    #===
    		Tips:
    			apis is Array. ex. apino:["js100","js102"]
    			insert(ji*),update(ju*),delete(jd*) api are forbidden to delete.
    			only select(js*) is able to be rejected from api list.
    	===#
    for a in apis
        if (!startswith(a, "js"))
            return false
        end
    end

    apiFile = JFiles.getFileNameFromConfigPath(j_config.JC["sqllistfile"])
    tableapiFile = JFiles.getFileNameFromConfigPath(j_config.JC["tableapifile"])
    apiFile_tmp = string(apiFile, ".tmp")
    tableapiTmpFile = string(tableapiFile, ",tmp")

    # take the backup file
    JFiles.fileBackup(tableapiFile)
    JFiles.fileBackup(apiFile)

    try
        open(apiFile_tmp, "w") do tio
            open(apiFile, "r") do io
                for ss in eachline(io, keep=false)
                    p = split(ss, ",")
                    if p[1] ∉ apis
                        # remain others in the file
                        println(tio, ss)
                    end
                end
            end
        end
    catch err
        JLog.writetoLogfile("ApiSqlListManager.deleteApiFromList() error: $err")
        return false
    end

    try
        open(tableapiTmpFile, "w") do ttaf
            open(tableapiFile, "r") do taf
                # Tips: delete line feed by 'keep=false', then do println()
                for ss in eachline(taf, keep=false)
                    p = split(ss, ":")
                    if p[1] ∉ apis
                        println(ttaf, ss)
                    end
                end
            end
        end
    catch err
        JLog.writetoLogfile("ApiSqlListManager.deleteApiFromlist() error: $err")
        return false
    end

    # change the file name.
    mv(apiFile_tmp, apiFile, force=true)
    mv(tableapiTmpFile, tableapiFile, force=true)

    # postgresql special
    if j_config.JC["dbtype"] == "postgresql" 
        # delete apis from js* vs jv* matching file as well 
        #===
            Tips:
                wanted to do this here, because as much as synchrolize with the above
        ===#
        deleteJvApiFromMatchingList(apis)
    end

    # update DataFrame
    readSqlList2DataFrame()

    # write to operationhistoryfile
    JLog.writetoOperationHistoryfile(string("delete api", ",", join(apis, ",")))

    return true
end
"""
function getRelatedList(searchKey::String, target::String)

	search in JetelinaTableApiRelation file to find 'target' due to 'searchKey'
	
# Arguments
- `searchKey::String`: 'table' or 'api'
- `target::String`: searching target string, e.g. 'js100' or 'testtable', sometimes array possible in case 'table' e.g 'testtable1,testtable2..' 
- return: Vector: the result of finding, in case 'api' is single data, in case 'talbe' has possibility multi data
"""
function getRelatedList(searchKey::String, target::String)
    tableapiFile = JFiles.getFileNameFromConfigPath(j_config.JC["tableapifile"])
    ret = []

    try
        open(tableapiFile, "r") do taf
            for ss in eachline(taf, keep=false)
                key::String = ""
                p = split(ss, ':')
                if searchKey == "table"
                    #===
                    						Tips:
                    							there is a chance to exist the same table name in postgres and mysql,
                    							therefore look at p[3]
                    					===#
                    if (p[3] == j_config.JC["dbtype"])
                        c = split(p[2], ',')
                        keys = split(target, ',')
                        for i in eachindex(keys)
                            for ii in eachindex(c)
                                if keys[i] == c[ii]
                                    push!(ret, p[1])
                                end
                            end
                        end
                    end
                else
                    c = p[1]
                    #===
                    						Tips:
                    							p[1] is unique api number.
                    					===#
                    if target == p[1]
                        #===
                        							Tips:
                        								p[2] has possibility multi data. e.g table1,table2
                        						===#
                        c = split(p[2], ',')
                        for i in eachindex(c)
                            push!(ret, c[i])
                        end
                    end
                end
            end
        end
    catch err
        JLog.writetoLogfile("ApiSqlListManager.getRelatedList() error: $err")
        return false
    end

    return convert(Vector{String}, ret)
end
"""
function sqlDuplicationCheck(nsql::String, subq::String)

	confirm duplication, if 'nsql' exists in JC["sqllistfile"].
	but checking is in Df_JetelinaSqlList, not the real file, because of execution speed. 

# Arguments
- `nsql::String`: sql sentence
- `subq::String`: sub query string for 'nsql'
- return:  tuple style
		   exist     -> ture, api no(ex.js100)
		   not exist -> false
"""
function sqlDuplicationCheck(nsql::String, subq::String, dbtype::String)
    if 0 < nrow(Df_JetelinaSqlList)
        df = subset(ApiSqlListManager.Df_JetelinaSqlList, :db => ByRow(==(dbtype)), skipmissing=true)

        for i ∈ 1:nrow(df)
            if dbtype != "mongodb"
                if df[!, :sql][i] == nsql && coalesce(df[!, :subquery][i], "") == subq
                    return true, df[!, :apino][i]
                end
            else
                #===
                    Tips:
                        only one 'ji*' api for mongodb
                ===#
                if startswith("ji", df[!, :apino][i])
                    return true, df[!, :apino][i]
                end
            end
        end
    end

    # consequently, not exist.
    return false
end
"""
function jsjvmatching2DataFrame()

	import js* jv* api matching list in JC["jsjvmatchingfile"] to DataFrame.
	this function set the matching list data in the global variable 'Df_jsJvList' as DataFrame object.

# Arguments
- return: Tuple: suceeded (true::Boolean, list of api/sql::DataFrames)
				 failed   (false::Boolean, nothing)

"""
function jsjvmatching2DataFrame()
    global Df_JsJvList = DataFrame()
    jsjvFile = JFiles.getFileNameFromConfigPath(j_config.JC["jsjvmatchingfile"])
    if isfile(jsjvFile)
        df = CSV.read(jsjvFile, DataFrame)
        if j_config.JC["debug"]
            @info "ApiSqlListManager.jsjvmatching2DataFrame() list in DataFrame: ", df
        end

        Df_JsJvList = df

        return true, df
    end

    return false, nothing
end
"""
function writeToMatchinglist(apino::String)

	write js* and jv* matching to JC["jsjvmatchingfile"].
	
# Arguments
- `apino::String`: js* apino
- return: Boolean: true -> suceeded false -> failed
"""
function writeToMatchinglist(apino::String)
    jsjvFile = JFiles.getFileNameFromConfigPath(j_config.JC["jsjvmatchingfile"])
    ivmapino::String = replace(apino, "js" => "jv")

    # write the sql to the file
    thefirstflg = true
    if !isfile(jsjvFile)
        thefirstflg = false
    end

    # write the sql to the file
    try
        open(jsjvFile, "a") do f
            if !thefirstflg
                println(f, "js,","jv")
            end

            println(f, string(apino, ",", ivmapino))
        end
    catch err
        JLog.writetoLogfile("ApiSqlListManager.writeToMatchinglist() $apino error: $err")
        return false
    end

    # update DataFrame
    jsjvmatching2DataFrame()

    return true
end
"""
function deleteJvApiFromMatchingList(apis:Vector)

	delete api by ordering from JC["jsjvmatchingfile"] file, then refresh the DataFrame.
	
# Arguments
- `apis::Vector`: target apis name
- return: boolean: true -> all done ,  false -> something failed
"""
function deleteJvApiFromMatchingList(apis::Vector)
    #===
    	Tips:
    		apis is Array. ex. apino:["js100","js102"]
    		insert(ji*),update(ju*),delete(jd*) api are forbidden to delete.
    		only select(js*) is able to be rejected from api list.
    ===#
    for a in apis
        if (!startswith(a, "js"))
            return false
        end
    end

    jsjvFile = JFiles.getFileNameFromConfigPath(j_config.JC["jsjvmatchingfile"])
    jsjvFile_tmp = string(jsjvFile, ".tmp")

    # take the backup file
    JFiles.fileBackup(jsjvFile)

    try
        open(jsjvFile_tmp, "w") do tf
            open(jsjvFile, "r") do f
                for ss in eachline(f, keep=false)
                    p = split(ss, ",")
                    if p[1] ∉ apis
                        # remain others in the file
                        println(tf, ss)
                    end
                end
            end
        end
    catch err
        JLog.writetoLogfile("ApiSqlListManager.deleteJvApiFromMatchingList() error: $err")
        return false
    end

    # change the file name.
    mv(jsjvFile_tmp, jsjvFile, force=true)

    # update DataFrame
    jsjvmatching2DataFrame()

    # write to operationhistoryfile
    JLog.writetoOperationHistoryfile(string("delete jv api", ",", join(apis, ",")))

    return true
end

end
