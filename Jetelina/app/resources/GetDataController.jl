"""
module: GetDataController

Author: Ono keiji

Description:
	get i/f of ajax

functions
	logout() logout procedure. update jetelina_user_table.logoutdate.
	getTableList() calling DBDataController.getTableList() with json mode. the return is json form naturally.
	getApiAccessData() get JC["apiaccesscountfile"] data file name. this file  contains access cound data in each sql due to sql.txt log file.
	getDBAccessData() get JC["dbaccesscountfile"] data file name. this file  contains access numbers data in each database due to sql.txt log file.
	getTableCombiVsAccessRelationData()  get JC["tablecombinationfile"] data file name. this file is analyzed data for table combination.
	getPerformanceRealData()  get JC["sqlperformancefile"] data file name. this file is analyzed data for real sql execution speed.
	getPerformanceTestData()  get JC["sqlperformancefile"] data file name but it is '.test' suffix. this file is analyzed data for sql execution speed on test db.
	checkExistImproveApiFile()  get JC["improvesuggestionfile"] data file name. this file contains an improving suggestion data of a target api. 
	getApiList()  get registering api list in json style.api list is refered in Df_JetelinaSqlList.
	getConfigHistory() get configuration change history in json style.
	getOperationHistory() get operation history in json style.
	getWorkingDBList() get db list that is working.
"""
module GetDataController

using Genie, Genie.Requests, Genie.Renderer.Json, DataFrames, Dates, JSON
using Jetelina.JFiles, Jetelina.InitApiSqlListManager.ApiSqlListManager, Jetelina.DBDataController, Jetelina.JMessage, Jetelina.JSession
import Jetelina.InitConfigManager.ConfigManager as j_config

JMessage.showModuleInCompiling(@__MODULE__)

export logout, getTableList, getTableCombiVsAccessRelationData, getPerformanceRealData, getPerformanceTestData, checkExistImproveApiFile, getApiList, getConfigHistory, getOperationHistory, getWorkingDBList

"""
function logout()

	logout procedure. update jetelina_user_table.logoutdate.
"""
function logout()
	uid = JSession.get()[2]
	key1 = "logoutdate"
	key2 = "last_dbtype"
	value = "now()"

	if !isnothing(uid)
		DBDataController.updateUserInfo(uid, key2, JSession.getDBType())
		ret = DBDataController.updateUserData(uid, key1, value)
	end

	# session data clear
	JSession.clear()

	return ret
end
"""
function getTableList()

	calling DBDataController.getTableList() with json mode.
	the return is json form naturally.
"""
function getTableList()
	if !isnothing(JSession.get())
		return DBDataController.getTableList("json")
	else
		return nothing
	end
end
"""
function getApiAccessData()

	get JC["apiaccesscountfile"] data file name. this file  contains access numbers data in each sql due to sql.txt log file.

# Arguments
- return: JC["apiaccesscountfile"] file name with its path
"""
function getApiAccessData()
	if !isnothing(JSession.get())

		f = JFiles.getFileNameFromLogPath(j_config.JC["apiaccesscountfile"])
		max_f_lines::Int = j_config.JC["json_max_lines"]

		if isfile(f)
			ret = "{\"Jetelina\":["
			linecount::Int = 0

			try
				for line in eachline(f)
					#			for line in Iterators.reverse(eachline(f))
					linecount += 1
					ret = string(ret, line, ",")
					if max_f_lines < linecount
						break
					end
				end

				ret = strip(ret, ',')
				return string(ret, "],\"result\":true}")
			catch err
				@error "ConfigManager.getApiAccessData() error: $err"
				return false
			end
		else
			return false
		end
	else
		return false
	end
end

"""
function getDBAccessData()

	get JC["dbaccesscountfile"] data file name. this file  contains access numbers data in each database due to sql.txt log file.

# Arguments
- return: JC["dbaccesscountfile"] file name with its path
"""
function getDBAccessData()
	if !isnothing(JSession.get())
		f = JFiles.getFileNameFromLogPath(j_config.JC["dbaccesscountfile"])
		max_f_lines::Int = j_config.JC["json_max_lines"]

		if isfile(f)
			ret = "{\"Jetelina\":["
			linecount::Int = 0

			try
				for line in eachline(f)
					#			for line in Iterators.reverse(eachline(f))
					linecount += 1
					ret = string(ret, line, ",")
					if max_f_lines < linecount
						break
					end
				end

				ret = strip(ret, ',')
				return string(ret, "],\"result\":true}")
			catch err
				@error "ConfigManager.getDBAccessData() error: $err"
				return false
			end
		else
			return false
		end
	else
		return false
	end
end

"""
function getTableCombiVsAccessRelationData()

	get JC["tablecombinationfile"] data file name. this file is analyzed data for table combination.

# Arguments
- return: JC["tablecombinationfile"] file name with its path
"""
function getTableCombiVsAccessRelationData()
	if !isnothing(JSession.get())
		f = JFiles.getFileNameFromLogPath(j_config.JC["tablecombinationfile"])
		if isfile(f)
			return readchomp(f)
		else
			return false
		end
	else
		return false
	end
end
"""
function getPerformanceRealData()

	get JC["sqlperformancefile"] data file name. this file is analyzed data for real sql execution speed.

# Arguments
- return: JC["sqlperformancefile"] of json style with its path
"""
function getPerformanceRealData()
	if !isnothing(JSession.get())
		f = JFiles.getFileNameFromLogPath(string(j_config.JC["sqlperformancefile"], ".json"))
		if isfile(f)
			return readchomp(f)
		else
			return false
		end
	else
		return false
	end
end
"""
function getPerformanceTestData()

	get JC["sqlperformancefile"] data file name but it is '.test' suffix. this file is analyzed data for sql execution speed on test db.

# Arguments
- return: JC["sqlperformancefile"] of json style with its path
"""
function getPerformanceTestData()
	if !isnothing(JSession.get())
		f = JFiles.getFileNameFromLogPath(string(j_config.JC["sqlperformancefile"], ".test.json"))
		if isfile(f)
			return readchomp(f)
		else
			return false
		end
	else
		return false
	end
end

function checkExistImproveApiFile()
	getImproveApiFile(false)
end
function getSuggestionData()
	getImproveApiFile(true)
end
"""
function checkExistImproveApiFile()

	get JC["improvesuggestionfile"] data file name. this file contains an improving suggestion data of a target api. 

# Arguments
- `flg::Bool`: activity. true -> fetch suggestion data, false -> just checking 
- return: JC["improvesuggestionfile"] file name with its path    
"""
function getImproveApiFile(flg::Bool)
	periodd::Int = j_config.JC["period_collect_data"]
	ret = "{\"Jetelina\":["
	rethead = ret
	isdata::Bool = false;

	#===
		Tips:
			provide only 10 days data to the client.
			may this '10' will be changeable, but it is fixed in ver3.0. guess enough. :)
	===#
	pastday::Date = floor(today(),Day) - Day(periodd)
	pastdaytime = Dates.date2epochdays(pastday)
	nowadays::Date = Dates.today()
	nowadaystime = Dates.date2epochdays(nowadays)

	if !isnothing(JSession.get())
		f = JFiles.getFileNameFromLogPath(j_config.JC["improvesuggestionfile"])
		if isfile(f)
			try
				for line in Iterators.reverse(eachline(f))
					jj = JSON.parse(line)
					if !isnothing(jj["date"])
						infdate::Date = Dates.Date(jj["date"])
						infdatetime = Dates.date2epochdays(infdate)
						
						if pastdaytime <= infdatetime <= nowadaystime
							ret = string(ret, line, ",")
						end
					end
				end

				isdata = true
				ret = strip(ret, ',')
#				return string(ret, "],\"result\":true}")
			catch err
				@error "ConfigManager.checkExistImproveApiFile() error: $err"
				return false
			end
		else
#			return string(ret,"{\"nothing\":\"everything fine\"}")
			ret = "{\"nothing\":\"everything fine\"}"
		end
	else
		return false
	end

	if flg
		return string(ret, "],\"result\":true}")
	else
		return string(rethead,"{\"issuggestion\":",isdata,"}],\"result\":true}")
	end
end
"""
function getApiList()

	get registering api list in json style.
	api list is refered in Df_JetelinaSqlList.
"""
function getApiList()
	if !isnothing(JSession.get())
		#===
				Tips:
					ApiSql...readSql...()[1] contains true/false.
					ApiSql...readSql...()[2] contains dataframe list if [] is true, in the case of false is nothing.
		===#
		if 0 < nrow(ApiSqlListManager.Df_JetelinaSqlList)
			return Genie.Renderer.Json.json(Dict("result" => true, "Jetelina" => copy.(eachrow(reverse(ApiSqlListManager.Df_JetelinaSqlList)))))
		else
			# not found SQL list
			return Genie.Renderer.Json.json(Dict("result" => false, "Jetelina" => "[{}]", "errmsg" => "Oops! there is no api list data"))
		end
	else
		return Genie.Renderer.Json.json(Dict("result" => false, "Jetelina" => "[{}]", "errmsg" => "Oops! there is no api list data"))
	end
end
"""
function getConfigHistory()

	get configuration change history in json style.
"""
function getConfigHistory()
	if !isnothing(JSession.get())
		f = JFiles.getFileNameFromLogPath(j_config.JC["config_change_history_file"])
		readlinecount::Int = j_config.JC["configchangehistoryreadlinecount"]
		if isfile(f)
			ret = "{\"Jetelina\":["
			linecount::Int = 0

			try
				for line in Iterators.reverse(eachline(f))
					linecount += 1
					ret = string(ret, line, ",")
					if readlinecount < linecount
						break
					end
				end

				ret = strip(ret, ',')
				return string(ret, "],\"result\":true}")
			catch err
				@error "ConfigManager.getConfigHistory() error: $err"
				return false
			end
		else
			return false
		end
	else
		return false
	end
end
"""
function getOperationHistory()

	get operation history in json style.
"""
function getOperationHistory()
	if !isnothing(JSession.get())
		f = JFiles.getFileNameFromLogPath(j_config.JC["operationhistoryfile"])
		readlinecount::Int = j_config.JC["operationhistoryreadlinecount"]

		if isfile(f)
			ret = "{\"Jetelina\":["
			linecount::Int = 0

			try
				for line in Iterators.reverse(eachline(f))
					linecount += 1
					ret = string(ret, line, ",")
					if readlinecount < linecount
						break
					end
				end

				ret = strip(ret, ',')
				return string(ret, "],\"result\":true}")
			catch err
				@error "ConfigManager.getOperationHistory() error: $err"
				return false
			end
		else
			return false
		end
	else
		return false
	end
end
"""
function getWorkingDBList()
	
	get db list that is working.
"""
function getWorkingDBList()
	if !isnothing(JSession.get())
		postgres = j_config.JC["pg_work"]
		pgivm = j_config.JC["pg_ivm"]
		mysql = j_config.JC["my_work"]
		redis = j_config.JC["redis_work"]
		mongodb = j_config.JC["mongodb_work"]

		df = DataFrame("postgres" => postgres, "pgivm" => pgivm, "mysql" => mysql, "redis" => redis, "mongodb" => mongodb)
		return Genie.Renderer.Json.json(Dict("result" => true, "Jetelina" => copy.(eachrow(df))))
	else
		return Genie.Renderer.Json.json(Dict("result" => false, "Jetelina" => "[{}]"))
	end
end

end
