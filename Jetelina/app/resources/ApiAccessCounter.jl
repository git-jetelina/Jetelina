"""
module: ApiAccessCounter

Author: Ono keiji

Description:
	Counting Api access numbers from sql.log
	
functions
	* main() this function set as for kicking createAna..() from outer function.
	collectApiAccessNumbers() 	collect each api(sql) access numbers.
	createAnalyzedJsonFile(df::DataFrame)  create json file for result of sql execution speed analyze data.
    createApiSpeedFile(df::DataFrame) create csv file for each api performance data.
	stopanalyzer() manual stopper for repeating analyzring
"""
module ApiAccessCounter

using JSON, LibPQ, Tables, CSV, DataFrames, StatsBase, DelimitedFiles, Dates
using Genie, Genie.Renderer, Genie.Renderer.Json
using Jetelina.JLog, Jetelina.JFiles, Jetelina.JMessage
import Jetelina.InitConfigManager.ConfigManager as j_config

JMessage.showModuleInCompiling(@__MODULE__)

#procflg = Ref(true) # analyze process progressable -> true, stop/error -> false

"""
function main()

	wrap function for executing collectApiAccessNumbers() that is the real analyzing function.
	this function set as for kicking createAna..() from outer function.

    deprecated: because quiting async

"""
function main()
#   interval::Integer = parse(Int, j_config.JC["analyze_interval"])

#    if isinteger(interval)
#        interval = interval * 60 * 60 # transfer hr -> sec
#        JLog.writetoLogfile(string("ApiAccessCounter.main() start with : ", j_config.JC["analyze_interval"], " hr interval"))

#        task = @async while procflg[]
#            collectApiAccessNumbers()
#            sleep(interval)
#        end
#    else
#        err = string(JC["analyze_interval"], " is not set in perfect")
#        println(err)
#        JLog.writetoLogfile("ApiAccessCounter.main() error: $err")
#    end
end
"""
function collectApiAccessNumbers()

	collect each api(sql) access numbers.

    Attention: 
        this function is called in LogFileRotator.main() when log files have been rotated in daily

"""
function collectApiAccessNumbers()
    #===
    		Tips:
    			read sql.log file
    				log/sql.log 
                        ex. 
                            time,apino,exectime,db
                            2024-11-05 10:46:33,js4,0.00123,postgresql
                                       ・
                                       ・
    	===#
    sqllogfile = getFileNameFromLogPath(string(j_config.JC["sqllogfile"],".",Dates.format(now(), "yyyy-mm-dd")))
    if !isfile(sqllogfile)
#        procflg[] = false
        errmsg::String = """oh my, there is no log file: $sqllogfile"""
        JLog.writetoLogfile("ApiAccessCounter.collectApiAccessNumbers() error: $errmsg")
        return
    end

    #===
        Tips:
            this 'reading_max_lines' is for secure.
            because who knows how much big the file is.
    ===#
    maxrow::Int = j_config.JC["reading_max_lines"]
    df = CSV.read(sqllogfile, DataFrame, limit=maxrow)
    #===
    	Tips:
    		start to collect data for creating analyzing files.
    		1. api access number
    		2. database access number
    		3. api execution speed   mean/max/min and standard deviation
    ===#
    #===
    	Tips:
    		get uniqeness 'apino' for '1' & '3'
    ===#
    u_api = unique(df[:, :apino])
    part_df = DataFrame(apino=String[], access_numbers=Int[], database=String[])
    part_df_speed = DataFrame(apino=String[], mean=Float64[], max=Float64[], min=Float64[], database=String[])

    u_api_size = length(u_api)
    if 0 < u_api_size
        for i ∈ 1:u_api_size
            ac = 0
            # collect access numbers for each unique API. make "access_numbers"
            dd = filter(:apino => x -> x == u_api[i], df)
            ac = nrow(dd)
            db = dd[:, :db][1]
            speedMax = maximum(dd[:, :exectime])
            speedMin = minimum(dd[:, :exectime])
            speedMean = mean(dd[:, :exectime])
            # move it to here becase it has changed each column name to each sql name.
            push!(part_df, [u_api[i], ac, db])
            push!(part_df_speed, [u_api[i], speedMean, speedMax, speedMin, db])
        end

        createAnalyzedJsonFile(part_df, JFiles.getFileNameFromLogPath(j_config.JC["apiaccesscountfile"]), 1)
        createApiSpeedFile(part_df_speed)
    end
    #===
    	Tips:
    		get uniqeness 'db' for '2'
    ===#
    u_db = unique(df[:, :db])
    part_df = DataFrame(database=String[], access_numbers=Int[])
    u_db_size = length(u_db)
    if 0 < u_db_size
        for i ∈ 1:u_db_size
            ac = 0
            # collect access numbers for each unique API. make "access_numbers"
            dd = filter(:db => x -> x == u_db[i], df)
            ac = nrow(dd)
            # move it to here becase it has changed each column name to each sql name.
            push!(part_df, [u_db[i], ac])
        end

        createAnalyzedJsonFile(part_df, JFiles.getFileNameFromLogPath(j_config.JC["dbaccesscountfile"]), 2)
        JLog.writetoLogfile(string("ApiAccessCounter.collectApiAccessNumbers() in : ",Dates.format(now(), "yyyy-mm-dd-HH:MM")))
    end
end
"""
function createAnalyzedJsonFile(df::DataFrame, jsonfile::String, type::Int)

	create json file for result of sql execution speed analyze data.

# Arguments
- `df::DataFrame`: target dataframe data
- `jsonfile::String`: be operated json file name
- `type::Int`: type of analyzing, 1->api access number, 2->db access number, 3->api speed
"""
function createAnalyzedJsonFile(df::DataFrame, jsonfile::String, type::Int)
    this_df = copy(df)
    date = Dates.today()
    if type == 1
        select!(this_df, :apino, :access_numbers, :database)
    elseif type == 2
        select!(this_df, :database, :access_numbers)
    end

    open(jsonfile, "a+") do f
        println(f, JSON.json(Dict("result" => true, "date" => date, "Jetelina" => copy.(eachrow(this_df)))))
    end
end
"""
function createApiSpeedFile(df::DataFrame)

	create csv file for each api performance data.

# Arguments
- `df::DataFrame`: target dataframe data
"""
function createApiSpeedFile(df::DataFrame)
    apfs::String = joinpath(@__DIR__, JFiles.getFileNameFromLogPath(j_config.JC["apiperformancedatapath"]))
    date::Date = Dates.today()
    stdoutdata::Array = []

	#===
		function _checkApiStandardDeviation
			checking the api execution speed 'mean' is in its standard deviation
		# Arguments
		- `fname::String`: target api's file name
		- `meanSpeed::Float64`: api execution speed 'mean'
		- `return::Taple(Bool,Int)`: true -> meanSpeed is in σ〜3σ of the standard deviation, false -> is not in there: meaning deprecated
                                     0 -> in case of true 1,2,3 -> in case of false and out of σ,2σ,3σ  
	===#
	function _checkApiStandardDeviation(fname, meanSpeed)
		stdjudge::Bool = true
		stdfname::String = string(fname, "_std")
		σ::Int = 0
	
		if isfile(stdfname)
			# compare meanSpeed with std
			stddf = CSV.read(stdfname, DataFrame, header=false)
			if 0 < nrow(df)
				mn = stddf[!, :1][1]
				sn = stddf[!, :2][1]
                if sn != 0.0
                    if meanSpeed<(mn - (sn)) || (mn + (sn))<meanSpeed
                        stdjudge = false
                        σ = 1
                    elseif meanSpeed<(mn - (2*sn)) || (mn + (2*sn))<meanSpeed
                        stdjudge = false
                        σ = 2
                    elseif meanSpeed<(mn - (3*sn)) || (mn + (3*sn))<meanSpeed
                        stdjudge = false
                        σ = 3
                    end
                end
			end
		end
	
		return stdjudge, σ
	end
	#===
		function _createStdFile		
			create and update api's standard deviation data file
		# Arguments
		- `fname::String`: target api's file name
	===#
	function _createStdFile(fname)
		stdfname::String = string(fname, "_std")
		maxrow::Int = j_config.JC["json_max_lines"]
		apidf = CSV.read(fname, DataFrame, limit=maxrow)
		stdparams = []
	
		for i in 1:nrow(apidf)
			if apidf[i,:std]
				push!(stdparams, apidf[i, :mean])
			end
		end
	
		totalSpeedMean = mean(apidf[!, :mean])
	
		stddata::Float64 = 0.0
		if 1 < length(stdparams)
			stddata = std(stdparams)
		else
			stddata = stdparams[1]
		end
	
		open(stdfname, "w+") do ff
			println(ff, string(totalSpeedMean, ",", stddata))
		end
	end

    #
    #  from here is this function workin'
    #
    suggestion_df = DataFrame(type=String[], apino=String[], mean=Float64[], sigma=Float64[],  database=String[])

    if !isdir(apfs)
        mkpath(apfs)
    end

    for i ∈ 1:nrow(df)
        fname = joinpath(apfs, string(df[i, :apino]))

        try
            # write the api performance to the file
            thefirstflg::Bool = true
            stdflg::Bool = true

            if !isfile(fname)
                thefirstflg = false
            end

            #===
   				Tips:
   					before append the data to the file, check the mean data is in its standared deviation.
   					_checkApiStandardDeviation() returns true/false, true meaning is normal execution speed, false is should raise an alert.
					but the data is appended to the file anyhow.
					then create its standared deviation file if _checkApiStandardDeviation() retuned true.
   			===#
			stdflg, sigma = _checkApiStandardDeviation(fname, df[i, :mean])

            open(fname, "a+") do f
                if !thefirstflg
                    println(f, string("date", ",", j_config.JC["file_column_mean"], ',', j_config.JC["file_column_max"]), ',', j_config.JC["file_column_min"], ",", "std")
                end

                println(f, string(date, ",", df[i, :mean], ",", df[i, :max], ",", df[i, :min], ",", stdflg))
            end

            if stdflg
                # update the standard deviation file 
                _createStdFile(fname)
            else
                # create suggestion file for raising alert to an user
                push!(suggestion_df,["[deprecated api]",df[i,:apino],df[i,:mean],sigma,df[i,:database]])
            end
        catch err
#            procflg[] = false
            println(err)
            JLog.writetoLogfile("ApiAccessCounter.createApiSpeedFile() error: $err")
            return
        finally
        end
    end

    if 0<nrow(suggestion_df)
        sugfname::String = joinpath(@__DIR__, JFiles.getFileNameFromLogPath(j_config.JC["improvesuggestionfile"]))
        open(sugfname,"a+") do ff
            println(ff, JSON.json(Dict("result" => true, "date" => date, "Jetelina" => copy.(eachrow(suggestion_df)))))
        end
    end
end
"""
function stopanalyzer()

	manual stopper for analyzring repeat
"""
function stopanalyzer()
#    procflg[] = false
end

end
