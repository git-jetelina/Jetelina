"""
module: SQLAnalyzer

Author: Ono keiji

Description:
	Analyze execution speed of all SQL sentences. 
	
functions
-- Attention: these funcs do not work in v3.0. because had become unnecessary. but who knows when they will be resurrected. ---
	main() this function set as for kicking createAna..() from outer function.
	createAnalyzedJsonFile() create json file for result of sql execution speed analyze data.
	extractColumnsFromSql(s::String)  pick up columns data from 's'.
	collectSqlAccessNumbers(df::DataFrame)  collect each sql access numbers then write out it to JC["apiaccesscountfile"] file in JSON form for showing its graph in stats panel.
	experimentalCreateView(df::DataFrame)  create view tables for test and execute all sql sentences for analyzing.
	createView(df::DataFrame)  create view table from a sql sentence that has multi tables and hight use in the running db.
	dropTestDB(conn)  drop testdb. doubtfull. :-p
	creatTestDB()    create testdb by using running db(JC["pg_dbname"]). only postgresql now. other db should be impremented later.
	tableCopy(df::DataFrame) copy some data from the running db to the test db. the number of copy data are ordered in JC["selectlimit"].
	stopanalyzer() manual stopper for repeating analyzring

-- these funcs works in v3.1. special funcs for ivm in postgresql---
	collectIvmCandidateApis() collect apis that is using multiple tables in JC["tableapifile"].
    compareJsAndJv() compare max/min/mean execution speed between js* and jv*.
    executeJSApi(apino::String) execute ordered sql(js*) sentence to compare with jv* execution speed
	executeIVMtest(apino::String) experimental execution of ivm-tized table 
"""
module SQLAnalyzer

using JSON, LibPQ, Tables, CSV, DataFrames, StatsBase, DelimitedFiles, Dates
using Genie, Genie.Renderer, Genie.Renderer.Json
using Jetelina.JLog, Jetelina.JFiles, Jetelina.JMessage, Jetelina.InitApiSqlListManager.ApiSqlListManager
import Jetelina.InitConfigManager.ConfigManager as j_config

JMessage.showModuleInCompiling(@__MODULE__)

#===
	Note:
		The same reason in DBDataController.jl
		quote,
			`wanna these include() in init(), but not all DBData.. are been included(), thus sometimes 'not found method ..' happen.
			guess should have a procedure alike JTimer.jl, I mean should include these in a dummy file to kick init(). :P  `

===#
include("libs/postgres/PgDBController.jl")
include("libs/postgres/PgIVMController.jl")

procflg = Ref(true) # analyze process progressable -> true, stop/error -> false

function __init__()
    @info "=========SQLAnalyzer.jl init==========="
#    include("DBDataController.jl")
#    if j_config.JC["dbtype"] == "postgresql"
#        include("libs/postgres/PgDBController.jl")
#        include("libs/postgres/PgTestDBController.jl")
#        include("libs/postgres/PgDataTypeList.jl")
#		include("libs/postgres/PgIVMController.jl")
#    elseif j_config.JC["dbtype"] == "mysql"
#    elseif j_config.JC["dbtype"] == "oracle"
#    end
end

"""
function main()

	wrap function for executing createAnalyzedJsonFile() that is the real analyzing function.
	this function set as for kicking createAna..() from outer function.
"""
function main()
    interval::Integer = parse(Int, j_config.JC["analyze_interval"])
    if isinteger(interval)
        interval = interval * 60 * 60 # transfer hr -> sec
        JLog.writetoLogfile(string("SQLAnalyzer.main() start with : ", j_config.JC["analyze_interval"], " hr interval"))

        task = @async while procflg[]
            createAnalyzedJsonFile()
            sleep(interval)
        end
    else
        err = string(JC["analyze_interval"], " is not set in perfect")
        println(err)
        JLog.writetoLogfile("SQLAnalyzer.main() error: $err")
    end
end

"""
function createAnalyzedJsonFile()

	create json file for result of sql execution speed analyze data.

# Arguments

"""
function createAnalyzedJsonFile()
    tablecombinationfile = JFiles.getFileNameFromLogPath(j_config.JC["tablecombinationfile"])
    # delete this file if it exists, because this file is always fresh.
    rm(tablecombinationfile, force=true)

    #===
    		Tips:
    			read sql.log file
    				log/sql.log ex. js314,"select ftest.sex,ftest.age,ftest.name from ftest as ftest "

    			the delimite of this file is ' ', that why expect right justify in select sentences.
    				ex.    select ftest2.id,ftest2.name from ...     OK
    					select ftest2.id, ftest2.name from ....   NG
    										^^

    			wondering is it ok if sql.log has more than one milion lines.
    			maybe should consider to rotate sql.log files. this is in #ticket 1254 
    	===#
    sqllogfile = getFileNameFromLogPath(j_config.JC["sqllogfile"])
    if !isfile(sqllogfile)
        return
    end

    maxrow::Int = j_config.JC["reading_max_lines"]
    df = CSV.read(sqllogfile, DataFrame, limit=maxrow)
    #===
    		Tips:
    			get uniqeness
    			Attention: analyze only select sql
    				ex. 
    				"js312,"  "select ftest.name,ftest.age,ftest2.name,ftest2.age,ftest3.age,ftest3.dumy from ftest as ftest,ftest2 as ftest2,ftest3 as ftest3 where ftest.id=ftest2.id and ftest.id=ftest3.id"  ""
    				"js312,"  "select ftest.name,ftest.age,ftest2.name,ftest2.age,ftest3.age,ftest3.dumy from ftest as ftest,ftest2 as ftest2,ftest3 as ftest3 where ftest.id=ftest2.id and ftest.id=ftest3.id"  ""

    				-->
    				"js312,"  "select ftest.name,ftest.age,ftest2.name,ftest2.age,ftest3.age,ftest3.dumy from ftest as ftest,ftest2 as ftest2,ftest3 as ftest3 where ftest.id=ftest2.id and ftest.id=ftest3.id"  ""

    			do uniqueness with 'apino' because of difference 'where' sentences, maybe.
    	===#
    filter!(:apino => p -> startswith(p, "js"), df)
    u = unique(df[:, :apino])
    #===
    		Tips:
    			steps for analyzing
    				1.make unique sql statements
    				2.pick up only the columns part
    				3.find the max access numbers among the longest combination number sql sentence
    				4.collect each sql access numbers
    				5.experimental sql execution in test db, if there were a target table that had possibilities in inproving
    				6.write this relation data to JC["tablecombinationfile"] file in JSON form
    	===#
    #==
    		step1:
    			unique 'apino' in 'u', then count access numbers in sql.log.  ex. u[i] === ....
    	==#
    #===
    		Tips:
    			shape the data
    				ex. 
    				apino      sql         combination         access numbers
    				js10    select ....  ['ftest3','ftest2']      2
    				js22    select ....  ['ftest4','ftest2']      5
    				js30    select ....  ['ftest2']              10

    			hire js22 because it is the highest access numbers among higher combination number(js10,js22) to create a client view graph 'stats panel'.
    			js30 may does not need to be created in 'stats panel' so that it is the best number but it has low combination number. 
    	===#
    sql_df = DataFrame(apino=String[], sql=String[], combination=Vector{String}[], access_numbers=Float64[])

    u_size = length(u)
    if 0 < u_size
        for i ∈ 1:u_size
            ac = 0
            # collect access numbers for each unique SQL. make "access_numbers"
            dd = filter(:apino => x -> x == u[i], df)
            ac = nrow(dd)
            table_arr = String[]
            tables = String[]

            #==
            				step2:
            					pick up columns from sql sentence. the columns are between 'select' and 'from'.
            						ex. select <columns> from <tables> where ...  -> <columns> 

            					this can do because of unified sql sentence by Jetelina created.  <-- importance!
            			==#
            cols = extractColumnsFromSql(df[:, :sql][i])
            c = split(cols[1], ",")

            for j ∈ 1:length(c)
                #===
                					Tips:
                						c[j] -> <table name>.<column name>
                						then spliting to
                						cc[1]:table name
                						cc[2]:column name 
                				===#
                cc = split(c[j], ".")

                #===
                					Tips:
                						reject master tables.
                						master tables has 'master' in their own name. this is the protocol. <-- importance!
                				===#
                if !contains(cc[1], "master")
                    # logical NOT in Julia, yes.
                    if cc[1] ∉ table_arr
                        push!(table_arr, cc[1]) # push except master table without duplication.
                    end

                    push!(tables, cc[1])  # collect table names used in the sql sentence, whatever.
                end
            end

            #===
            				Tips:
            					push the best number of table in tables[] as 'basic table' to the head of table_arr.
            					in the case of multi candidates in 'basic table', they are ordered in Ascii.
            						ex. there are candidates as 'a','b'(they are same number), will hire 'a'. hum.. alright. 

            					this 'basic table' is to be x-axis order in 'Access vs Combination' graph in the conditon panel, that is drwawn by Plotly.js.

            					mode() is included in StatsBase.jl to return the mode of tables array.

            					then sql_df will be alike below, you can see 'basic table' is in the head of 'combination' array data,

            						Row │ apino   sql                                    combination                        access_numbers 
            							│ String  String                                 Array…                             Float64       
            				─────┼───────────────────────────────────────────────────
            						1 │ js312   select ftest.name,ftest.age,ftes…  ["ftest", "ftest", "ftest2", "ft…            5.0
            						2 │ js313   select ftest.name,ftest.age,ftes…  ["ftest", "ftest", "ftest2", "ft…            3.0
            						3 │ js314   select ftest.name,ftest.age,ftes…  ["ftest", "ftest", "ftest2", "ft…            1.0
            			===#
            pushfirst!(table_arr, mode(tables))
            # move it to here becase it has changed each column name to each sql name.
            push!(sql_df, [u[i], df[:, :sql][i], table_arr, ac])
        end

        #===
        			create JC["experimentsqllistfile"] for executing them on test db
        		===#
        experimentFile = JFiles.getFileNameFromConfigPath(j_config.JC["experimentsqllistfile"])
        # delete this file if it exists, becaus this file is always fresh.
        rm(experimentFile, force=true)

        try
            CSV.write(experimentFile, Dict(eachrow(sql_df)), header=[j_config.JC["file_column_apino"], j_config.JC["file_column_sql"]])
        catch err
            procflg[] = false
            println(err)
            JLog.writetoLogfile("SQLAnalyzer.createAnalyzedJsonFile() error: $err")
            return
        finally
        end
        #===
        			↑ preparation.
        			↓ analyzing.
        		===#

        #==
        			step3:
        				first of all, collect each sql access numbers for showing it on stats panel. 
        		==#
        collectSqlAccessNumbers(sql_df)

        # find the sql that is the longest combination number
        c_len = length.(sql_df.combination)
        p = findall(x -> x == maximum(c_len), c_len) # 'p' has the index number of the max data

        #==
        			step4:
        				find the max access numbers among the longest combination number sql sentence.
        		==#
        accn = sql_df[p, :access_numbers]
        pp = findall(x -> x == maximum(accn), accn)

        # then the target sql sentence is this.
        target = sql_df[pp, :]

        #===
        			Tips:
        				execute an experimental sql test(step5,6) on test db if there were a target.
        		===#
        if (0 < nrow(target))
            #==
            				step5: 
            					good!. let's analyze it in testdb.
            			==#
            experimentalCreateView(target)

            #===
            				Tips:
            					from here for showing the anlyzed graph in conditional pane.
            					the analyzing has been done above.
            			===#
            # delete ':sql' column from 'sql_df', because it is unnecessary in the json file.
            select!(sql_df, :apino, :combination, :access_numbers)

            #===
            				Tips:
            					this tips is complicated, that why still in Japanese.
            					what here is doing, 
            						ex.
            							replace 'combination' with 'Row No.' of each table.

            							Row │ apino          combination                    access_numbers 
            								│ String           Array…                         Float64       
            							──┼────────────────────────────────
            							1   │ js312  ["ftest", "ftest2", "ftest3"]            5.0
            							2   │ js313  ["ftest", "ftest2", "ftest3"]            5.0
            							3   │ js314  ["ftest", "ftest2", "ftest3"]            5.0

            							ftest3.idはftest3にあるので→x座標:3(ftest3)
            							ftest3.idはftest4+ftest2が代表値なので → (3+4)/2(tableが2つだから)=3.5 ←y座標になる
            							よって、ftest3.idの座標は(3,3.5)

            							”access numbers”はk-means法の"重み"として考えているけど、上記座標取得方法なら不要になる、が一応保持しておく、念のため。


            						最終的に、カラム名とカラム座標値のMatrixをファイルに格納する(一旦ね)。
            			===#
            table_df = DBDataController.getTableList("dataframe")

            #===
            				rejecting 'master' tables. master tables names 'master' in their own table name.
            				here is important .( ｰ`дｰ´)ｷﾘｯ
            			===#
            filter!(:tablename => x -> !contains(x, "master"), table_df)

            #===
            				Tips:
            				by Ph. Kaminski
            					this is able to do because 'table_df.tablename' is unique.
            					refer d("ftest"=>1 "ftest2=>4...) to get the index, then put them into combination.
            			===#
            d = Dict(table_df.tablename .=> axes(table_df, 1))
            sql_df.combination = [getindex.(Ref(d), x) for x in sql_df.combination]

            # normalize all access numbers by the biggest 'access_numbers'
            sql_df.access_numbers = sql_df.access_numbers / maximum(sql_df.access_numbers)

            if j_config.JC["debug"]
                @info "SQLAnalyzer.createAnalyzedJsonFile(): " JSON.json(Dict("Jetelina" => copy.(eachrow(sql_df))))
            end
            #===
            				Tips:
            					use plain JSON module insted of Genie.Renderer.Json module, because Genie's module put http protocol header(ex. HTTP 200) in the output.
            					the conditional panel will call this as a plain file in being called RestAPI. 
            			===#
            #==
            				step6:
            					write this relation data to JC["tablecombinationfile"] file in JSON form.
            			==#
            open(tablecombinationfile, "w") do f
                println(f, JSON.json(Dict("Jetelina" => copy.(eachrow(sql_df)))))
            end
        end
    end
end
"""
function  extractColumnsFromSql(s::String)

	pick up columns data from 's'.

# Arguments
-`s::String`: expected sql sentence. ex. select .... from .....
- return: tuple   column strngs, select or from strings
"""
function extractColumnsFromSql(s::String)
    ad::String = ""
    cs::String = ""
    if contains(s, "select")
        ss = split(s, "select ")
        cs = string(ss[2])
        ad = "select"
        if contains(cs, "from")
            ss = split(cs, " from")
            cs = string(ss[1])
            ad = string("from", ss[2])
        end
    end

    return cs, ad
end

"""
function collectSqlAccessNumbers(df::DataFrame)

	collect each sql access numbers then write out it to JC["apiaccesscountfile"] file in JSON form for showing its graph in stats panel.

# Arguments
- `df::DataFrame`: target dataframe data
"""
function collectSqlAccessNumbers(df::DataFrame)
    this_df = copy(df)
    sqlaccessnumberfile = JFiles.getFileNameFromLogPath(j_config.JC["apiaccesscountfile"])
    # delete this file if it exists, because this file is always fresh.
    rm(sqlaccessnumberfile, force=true)

    select!(this_df, :apino, :access_numbers)
    open(sqlaccessnumberfile, "w") do f
        println(f, JSON.json(Dict("Jetelina" => copy.(eachrow(this_df)))))
    end
end
"""
function experimentalCreateView(df::DataFrame)

	create view tables for test and execute all sql sentences for analyzing.

# Arguments
- `df::DataFrame`: target dataframe data
"""
function experimentalCreateView(df::DataFrame)

    #===
    		Tips:
    			1.ready test db
    			2.copy all table in running to test db, but not all line
    			3.execute 'create view' in order to sql sentence, the api are changed order by it
    			4.execute all api in create view in 3 on test db, and compare with the latest data. then write them out to 'report file' for viewing stats panel
    			5.do not forget to delete the test db after analyzing
    	===#

    #1
    table_df = creatTestDB()
    #2
    tableCopy(table_df)
    #3
    dict = createView(df)
    dict_apino_arr = []
    if 0 < length(dict)
        for i in keys(dict)
            #===
            				Tips:
            					i->key, dict[i]->value
            					ex. i->js101, dict[i]->select ....
            			===#
            push!(dict_apino_arr, i)
        end
    end

    #===
    		Tips:
    			open JC["experimentsqllistfile"] and call sql sentences.
    			execute PgTestDBController.doSelect(sql) with the 'sql' in the PgTestDBController.measureSqlPerformance().
    	===#
    #4
    PgTestDBController.measureSqlPerformance()
    #===
    		Tips: Attention.
    			compare the each api performance between JC["sqlperformancefile"](running db) and ..test(test db).
    			each data(max/min/mean) are normalized by the max data.
    			each data in test db are normalized by the real db max data.

    			be a json file
    				be DataFrame Jeteli..file(①),Jeteli..file.test(②).
    				normalize each number of each api no by the max number of ①.
    				normalize each number of each api no of ② by the max number of ①.
    				put something mark on the target api no in ① and ②.

    			then rely on js code in conditional panel after all.

    			does not check every file existing checking since here, because they are absolutely existing.
    	===#
    sqlPerformanceFile_real = JFiles.getFileNameFromConfigPath(j_config.JC["sqlperformancefile"])
    sqlPerformanceFile_test = string(sqlPerformanceFile_real, ".test")

    df_real = CSV.read(sqlPerformanceFile_real, DataFrame)
    df_test = CSV.read(sqlPerformanceFile_test, DataFrame)

    if j_config.JC["debug"]
        println("===SQLAnalyer.experimentalCreateView()===")
        println("before normalize df_real", df_real)
        println("before normalize df_test", df_test)
    end
    #===
    		Tips:
    		  df_real contains the real sql execution speed on the real db
    		  df_test contains the experimental sql exectution speed on the test db.

    		  here, define standard speed data due to df_real.
    		  then normalize both df_real and df_test data by this standard data for being able to compare the both speed data.

    		  Attention: std_max is due to minimum(). std_mean is calculated by sum() divide the row number of df_real.
    	===#
    std_max = minimum(df_real.max)
    std_min = maximum(df_real.min)
    std_mean = sum(df_real.mean) / nrow(df_real) #size(df_real)[1]

    df_real.max = df_real.max / std_max
    df_real.min = df_real.min / std_min
    df_real.mean = df_real.mean / std_mean

    df_test.max = df_test.max / std_max
    df_test.min = df_test.min / std_min
    df_test.mean = df_test.mean / std_mean

    if j_config.JC["debug"]
        println("===SQLAnalyer.experimentalCreateView()===")
        println("after normalize df_real", df_real)
        println("std_max:", std_max, " std_min:", std_min, " std_mean:", std_mean)
        println("df_real.max:", df_real.max, " df_real.min:", df_real.min, " df_real.mean:", df_real.mean)
        println("after normalize df_test", df_test)
        println("df_test.max:", df_test.max, " df_test.min:", df_test.min, " df_test.mean:", df_test.mean)
    end

    sqlPerformanceFile_real_json = JFiles.getFileNameFromLogPath(string(j_config.JC["sqlperformancefile"], ".json"))
    sqlPerformanceFile_test_json = string(sqlPerformanceFile_real_json, ".test.json")
    improveApisFile = JFiles.getFileNameFromLogPath(string(j_config.JC["improvesuggestionfile"]))

    # delete all files if they exists, because these files are always fresh.
    rm(sqlPerformanceFile_real_json, force=true)
    rm(sqlPerformanceFile_test_json, force=true)
    rm(improveApisFile, force=true)

    #===
    		Tips:
    			find each 'apino' in df_real/df_test exists in dict_apino_arr.
    			capitalize the 'apino' if existed.
    			this capitalized 'apino' will be highlighted on the graph in conditional panel by js program.
    	===#
    improve_apis = Dict()

    for i ∈ 1:length(dict_apino_arr)
        #===
        			Tips:
        				'p' returns the index number,Vector{Int64} type, if it were in.
        				can use this index number because of being garanteed df_real.apino was uniqueness.
        		===#
        p = findall(x -> x == dict_apino_arr[i], df_real.apino)
        if 0 < length(p)
            #===
            				Tips:
            					both df_real and df_test are Matrixfloat64} array,
            					then diff_speed is also to be array.
            			===#
            diff_speed = df_test[p, :mean] / df_real[p, :mean]

            if j_config.JC["debug"]
                println("===SQLAnalyer.experimentalCreateView()===")
                println("diff_speed:", dict_apino_arr[i], " -> ", diff_speed[1], " ", typeof(diff_speed))
            end
            #===
            				Tips:
            					propose 'do?' if sql execution speed were improved over 25%.
            					'25%' is provisionally.
            			===#
            if diff_speed[1] < 0.75
                improve_apis[dict_apino_arr[i]] = diff_speed[1]
            end
        end
    end

    open(sqlPerformanceFile_real_json, "w") do f
        println(f, JSON.json(Dict("Jetelina" => copy.(eachrow(df_real)))))
    end

    open(sqlPerformanceFile_test_json, "w") do f
        println(f, JSON.json(Dict("Jetelina" => copy.(eachrow(df_test)))))
    end

    if 0 < length(improve_apis)
        open(improveApisFile, "w") do f
            println(f, JSON.json("Jetelina" => improve_apis))
        end
    end

end

"""
function  createView(df::DataFrame)

	create view table from a sql sentence that has multi tables and hight use in the running db.

# Arguments
-`df::DataFrame`: DataFrames object. contains sql list.
- return: Dict:  
	return: Dict() create viewしたことにより更新されたapinoとsql
"""
function createView(df::DataFrame)
    # not only one target
    create_view_str = String[]
    newapilist = Dict()

    for i ∈ 1:nrow(df)
        viewtable = string(df.apino[i], "_view")
        targetsql = df.sql[i]

        #===
        			Tips:
        				adding 'as' sentence for preventing happening 'Duplication column error'.😁めんどくせー
        					ex.
        						select ftest.name,ftest2.name,.....
        						->
        						select ftest.name as ftest_name,ftest2.name as ftest2_name,.....

        			extractColumnsFromSql() funciton returns as tuple,
        				[1]:column strings
        				[2]:'select' or strings after 'from' 

        			at the same time, have to update the original api.
        			colulmn name of creating view table is 'pp' below. Let's create it in the loop.
        			api for creating view is going to update to the api file. may easy to handle later if it were Dict() type:'<api name>=><new sql>'.
        		===#
        columns_str = extractColumnsFromSql(targetsql)
        editedtargetsql = ""
        newapisql = ""
        if 0 < length(columns_str[1])
            c = split(columns_str[1], ',')
            for ii ∈ 1:length(c)
                p = c[ii]
                pp = replace(p, '.' => '_')
                c[ii] = """$p as $pp"""

                if 0 < length(editedtargetsql)
                    editedtargetsql = string(editedtargetsql, ',', c[ii])
                    newapisql = string(newapisql, ',', pp)
                else
                    editedtargetsql = string("select", ' ', c[ii])
                    newapisql = string("select", ' ', pp)
                end
            end
        end

        # expecting column_str[2] is the strings after 'from'. it does not may betrayed.
        targetsql = string(editedtargetsql, ' ', columns_str[2])
        newapisql = string(newapisql, " from ", viewtable)
        newapilist[df.apino[i]] = newapisql
        cvs = """create view $viewtable as $targetsql;"""
        push!(create_view_str, cvs)
    end

    tconn = PgTestDBController.open_connection()

    try
        for i ∈ 1:length(create_view_str)
            execute(tconn, create_view_str[i])
        end
    catch err
        procflg[] = false
        println(err)
        JLog.writetoLogfile("SQLAnalyzer.createView() error: $err")
    finally
        PgTestDBController.close_connection(tconn)
        return newapilist
    end
end

"""
function dropTestDB(conn)

	drop testdb. doubtfull. :-p

# Arguments
- `conn`: db connection object
- return: 
"""
function dropTestDB(conn)
    dbdrop = string("drop database if exists ", j_config.JC["pg_testdbname"])
    return PgDBController.execute(conn, dbdrop)
end

"""
function creatTestDB()

	create testdb by using running db(JC["pg_dbname"]).
	
	only postgresql now. other db should be impremented later.
"""
function creatTestDB()
    if j_config.JC["dbtype"] == "postgresql"
        conn = PgDBController.open_connection()

        try
            #===
            				Tips:
            					drop testdb before copying if it were.
            					postgresql does not have 'if exist' term in its 'create database' sentence.
            			===#
            dropTestDB(conn)

            dbcopy = string("create database ", j_config.JC["pg_testdbname"])
            execute(conn, dbcopy)

            #===
            				Tips:
            					acquire table list in the running db after successing create test database.
            			===#
            return DBDataController.getTableList("dataframe")
        catch err
            procflg[] = false
            println(err)
            JLog.writetoLogfile("SQLAnalyzer.creatTestDB() error: $err")
        finally
            PgDBController.close_connection(conn)
        end

    elseif j_config.JC["dbtype"] == "mysql"
    elseif j_config.JC["dbtype"] == "oracle"
    end
end

"""
function tableCopy(df::DataFrame)

	copy some data from the running db to the test db. the number of copy data are ordered in JC["selectlimit"].
	has taken 2 steps,
		1.create table
		2.copy data
	
	because some database does not have 'copy' command in it.
	the copy execution rely on _load_table!().

# Arguments
- `df::DataFrame`: DataFrame object.
"""
function tableCopy(df::DataFrame)
    tconn = PgTestDBController.open_connection()
    conn = PgDBController.open_connection()

    try
        for i ∈ 1:size(df)[1]
            tn = df[!, :tablename][i]
            selectsql = string("select * from ", tn, " limit ", j_config.JC["selectlimit"])
            altdf = DataFrame(columntable(LibPQ.execute(conn, selectsql)))
            _load_table!(tconn, altdf, tn)
        end
    catch err
        procflg[] = false
        println(err)
        JLog.writetoLogfile("SQLAnalyzer.tableCopy() error: $err")
    finally
        PgDBController.close_connection(conn)
        PgTestDBController.close_connection(tconn)
    end
end
"""
function _load_table!(conn, df::DataFrame, tablename::Vector{String}, columns=names(df))

	hopefully private function.

	ref. https://discourse.julialang.org/t/how-to-create-a-table-in-a-database-using-dataframes/75759/2

# Arguments
- `conn`: database connection object. it depend on database lib.
- `df::DataFrame`:: dataframe object
- `tablename::String`: ordered table name
- `columns=..`: this is the optional value. to make table columns name as dataframe's one. 
"""
function _load_table!(conn, df::DataFrame, tablename::String, columns=names(df))
    # acquire columns type to array
    column_type = nonmissingtype.(eltype.(eachcol(df)))
    # define DataFrame column
    column_type_string = Array{Union{Nothing,String}}(nothing, length(columns))
    # columns(id,name,sex,....) in creating table
    column_str = string()

    for i ∈ 1:length(columns)
        #===
        			Tips:
        				'column_type[i]' are 'DataType' due to eltype().
        				need to change the data type to 'String' to call getDataTypeInDataFrame().
        		===#
        column_type_string[i] = PgDataTypeList.getDataType(string(column_type[i]))
        column_str = string(column_str, " ", columns[i], " ", column_type_string[i], ",")
    end

    # reject the last ','
    column_str = chop(column_str)

    # build 'create table' sentence
    create_table_str = """create table if not exists $tablename ( $column_str );"""
    # build 'insert' sentence
    table_column_names = join(string.(columns), ", ")
    placeholders = join(("\$$num" for num in 1:length(columns)), ", ")
    data = select(df, columns)

    try
        execute(conn, "BEGIN;")
        # execute 'create table'
        execute(conn, create_table_str)
        # execute 'insert'. load!() may not be exported in LibPQ module.
        LibPQ.load!(
            data,
            conn,
            "INSERT INTO $tablename ($(table_column_names)) VALUES ($placeholders)",
        )

        execute(conn, "COMMIT;")
    catch err
        procflg[] = false
        println(err)
        JLog.writetoLogfile("SQLAnalyzer._load_table!() error: $err")
        execute(conn, "ROLLBACK;")
    finally
    end
end
"""
function stopanalyzer()

	manual stopper for analyzring repeat
"""
function stopanalyzer()
    procflg[] = false
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
        JLog.writetoLogfile("SQLAnalyzer.collectIvmCandidateApis() error: $err")
        return false
    end

    return ret

end
"""
function compareJsAndJv()

    compare max/min/mean execution speed between js* and jv*.

"""
function compareJsAndJv()
    conn = PgDBController.open_connection()
	apis::Array = collectIvmCandidateApis()

    try
        for apino in apis
            jsspeed = executeJSApi(conn, string(apino))
            jvspeed = executeIVMtest(conn, string(apino))

            if j_config.JC["debug"]
                @info "jsspeed: " jsspeed
                @info "jvspeed: " jvspeed
                @info "speed compare: jv_mean - js_mean " (jvspeed[3] - jsspeed[3])
            end

            if jsspeed[3] < jvspeed[3]
                ivmapino::String = replace(apino, "js" => "jv")
                @info "dropped " ivmapino
                PgIVMController.dropIVMtable(conn, ivmapino)
            else
                @info "write to the file " apino
                ApiSqlListManager.writeToMatchinglist(string(apino))
            end
        end
    catch err
        println(err)
		JLog.writetoLogfile("PgIVMController.compareJsAndJv() error : $err")
    finally
		# close the connection
		PgDBController.close_connection(conn)
    end
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
#    sql::String = replace(string(target_api[!,:sql][1], " ", target_api[!,:subquery][1]), "'" => "''")
    
#    conn = PgDBController.open_connection()
	try
		#===
			Tips:
				acquire data are 'max','best',"mean'.
		===#
		exetime = []
		looptime = 10
		for loop in 1:looptime
			stats = @timed z = LibPQ.execute(conn, sql)
			push!(exetime, stats.time)
		end

		return findmax(exetime), findmin(exetime), sum(exetime) / looptime
	catch err
		println(err)
		JLog.writetoLogfile("PgTestDBController.executeJSApi() with $sql error : $err")
		return false
	finally
		# close the connection
#		PgDBController.close_connection(conn)
	end
end

"""
function executeIVMtest(conn, apino::String) 
	
	experimental execution of ivm-tized table 

# Arguments
- `apino::String`: execute target api number e.g js10
- return: ((max speed, sample number),(minimum speed, sample number), mean ), fale -> boolean: false. 
"""
function executeIVMtest(conn, apino::String) 
#    mode::Bool = false  # true -> create and keep it  false -> create then drop it

#	for apino in apis
		@info "apino is " apino
#		PgIVMController.createIVMtable(string(apino),mode)
		return PgIVMController.createIVMtable(conn, apino)
#	end
end

end
