"""
module: ConfigManager

Author: Ono keiji

Description:
	read configuration parameters from Jetelina.cnf file
	then set them to global variables

contain functions
	__init__()
	createScenario()  create scenario.js file from base.jdic and JetelinaConfig.cnf files. this function is mandatory working to realize Jetelina Chatting.
	switchDbType() update 'dbtype' parameter every switching data base. 
	configParamUpdate(d::Dict) update a configuration parameter in the configuration file.
"""

module ConfigManager
using Dates
using Jetelina.JFiles, Jetelina.JMessage, Jetelina.JSession

JMessage.showModuleInCompiling(@__MODULE__)

export JC, createScenario, configParamUpdate, switchDbType

# configration file name
const defaultConfigFile = "JetelinaConfig.cnf"

"""
function __init__()

	auto start this when the server starting.
	this function calls _readConfig function.
"""
function __init__()
	@info "=======ConfigManager init=========="
	_readConfig()
	createScenario()
end

"""
function _readConfig()

	this function is hopefully be private.
	read configuration parameters from JetelinaConfig.cnf file,
	then set them to the global variables.
"""
function _readConfig()
	configfile = JFiles.getFileNameFromConfigPath(defaultConfigFile)

	try
		f = open(configfile, "r")
		l = readlines(f)
		global JC = Dict{String, Any}()
		global JS_DRAFT_CONFIG = Dict{String, Any}()
		dicmark::String = "@jdic" # a line text that has this mark is for jetelina dictionary
		k::Integer = 0

		for i ∈ 1:length(l)
			lowertext = lowercase(l[i])
			if !startswith(lowertext, "#") && !startswith(lowertext, dicmark) && 0 < length(l[i])
				ret = _getSetting(l[i])
				if ret[2] == "true" || ret[2] == "false"
					JC[ret[1]] = parse(Bool, ret[2])
				else
					JC[ret[1]] = ret[2]
				end
			elseif startswith(lowertext, dicmark)
				ret = _getDic(l[i])
				JS_DRAFT_CONFIG[ret[1]] = ret[2]
			end
		end

		close(f)
	catch err
		@error "ConfigManager._readConfig() error: $err"
		return false
	end

	return true
end

"""
function _getSetting(s::String)

	this function is hopefully be private.
	get value from 's'. 's' is expected 'name=value' style.
	return trimed array.

# Arguments
- `s::String`:  configuration data in 'name=value'. ex. 'debug = true'
- return: trimed array [1]:NAME,[2]:value  ex. [1]:"DEBUG",[2]:"true"
"""
function _getSetting(s::String)
	t = split(s, "=")
	t[1] = strip(t[1])
	t[2] = strip(t[2])

	return t
end

"""
function _getDic(s::String)

	this function is hopefully be private.
	get value from 's'. 's' is expected '@jdic name:value' style.
	return trimed array.

# Arguments
- `s::String`:  configuration data in '@jdic name:value'. ex. '@jdic debug:'debug command''
- return: trimed array [1]:NAME,[2]:value  ex. [1]:"debug",[2]:"[debug command]"
"""
function _getDic(s::String)
	t = split(s, "@jdic")
	if !isnothing(t[2]) && 0 < length(t[2])
		if contains(t[2], ':')
			p = split(t[2], ':')
			p[1] = strip(p[1])
			p[2] = strip(p[2])
			val = SubString(t[2], length(p[1]) + 3)
			p[2] = string('[', val, ']')
			return p
		end
	end
end
"""
function createScenario()

	create scenario.js file from base.jdic and JetelinaConfig.cnf files.
	this function is mandatory working to realize Jetelina Chatting.
	'scenario[]' is handling for the function/stats panel.
	'config[]' is handling for configuration parameters that are defined in JetelinaConfig.cnf.

# Arguments
"""
function createScenario()
	basefile = getFileNameFromConfigPath("base.jdic")
	scenariofile = getJsFileNameFromPublicPath("scenario.js")
	scenariofile_tmp = getJsFileNameFromPublicPath("scenario.js.tmp")
	jdicmark::String = "@jdic"

	try
		#
		# read base.jdic
		#
		f = open(basefile, "r")
		l = readlines(f)
		close(f)

		#
		# create scenario temp file then write base.jdic into it
		#
		tf = open(scenariofile_tmp, "w")
		#
		# Tips:
		#   this "let scena..." is for definiting as parameters in js file.
		#   printing "scenario[...]=[...]" has meaning of array parameters because of this difinition.
		#
		println(tf, "let scenario = []; let config = [];")

		for i ∈ 1:length(l)
			if startswith(l[i], jdicmark)
				ret = _getDic(l[i])

				println(tf, string("scenario[\"", ret[1], "\"]=", ret[2], ";"))
			end
		end

		#
		# append the config file dictionary to scenario file
		#
		js_d_c::Array = collect(keys(JS_DRAFT_CONFIG))
		for i ∈ 1:length(js_d_c)
			println(tf, string("config[\"", js_d_c[i], "\"]=", JS_DRAFT_CONFIG[js_d_c[i]], ";"))
		end

		close(tf)
		mv(scenariofile_tmp, scenariofile, force = true)
	catch err
		@error "ConfigManager._fileupdate() error $param changes with $prev -> $var: $err"
	end
end
"""
function switchDbType() 
	
	update 'dbtype' parameter every switching data base. 

#Arguments
- `db::String`: database to use
"""
function switchDbType(db)
	configParamUpdate(Dict("dbtype"=>db))
end
"""
function configParamUpdate(d::Dict)

	update a configuration parameter in the configuration file.
	the param is ensured as is not 'nothing' in PostDataController.configParamUpdate().

# Arguments
- `dd::Dict`:  json style configuration parameter
"""
function configParamUpdate(d::Dict)
	dn = collect(keys(d))
	
	configfile = JFiles.getFileNameFromConfigPath(defaultConfigFile)
	configfile_tmp = string(configfile, ".tmp")
	configChangeHistoryFile = JFiles.getFileNameFromLogPath(JC["config_change_history_file"])

	#===
		Tips:
			exceptionkeywords are for avoiding to require JSession
			isexeckey contains '0' or '1' as much as numbers of dn
			indeed '0' is true(yes matching), '1' is false(nop)
			then you could judge by studying isexckey later
	===#
	exceptionkeywords = ["jetelinadb","pg_ivm"]
	isexckey = exceptionkeywords .∉ Ref(dn)
	needJsession = true
	if 1 in isexckey
		needJsession = false
	end

	try
		f = open(configfile, "r+")
		tf = open(configfile_tmp, "w")
		l = readlines(f)
		history_previous::String = ""
		history_latest::String = ""

		for n ∈ 1:length(dn)
			param = dn[n]
			var = d[dn[n]]
			prev = string(JC[param])
			#
			#  Tips:
			#     update it on memory as global parameters.
			#     this changing is temporary updating.
			#
			if var == "true" || var == "false"
				JC[param] = parse(Bool, var)
			else
				JC[param] = var

				#===
					Tips:
						if "jetelinadb" parameter exists in dn, this is the initialize process.
						therefore there is no session data, skip it.
				===#
#				if "jetelinadb" ∉ dn
				if needJsession
					# also rewrite the session data
					if(param == "dbtype")
						JSession.setDBType(var)
					end
				end
			end
			#
			#  Tips:
			#     update it in the file at the same time.
			#     this changing is for parmanent updating.
			#
			for i ∈ 1:length(l)
				if startswith(l[i], param)
					pv = split(l[i],"=")
					if param == strip(pv[1])
						l[i] = replace(l[i], prev => var, count = 1)

						history_previous = string("\"",param,"\":","\"",prev,"\",",history_previous)
						history_latest = string(",\"",param,"\":","\"",var,"\"",history_latest)
					end
				end
			end
		end
		#
		# Tips:
		#	then write all to the file for making it persistent
		#
		for i ∈ 1:length(l)
			println(tf, l[i])
		end

		close(tf)
		close(f)
		mv(configfile_tmp, configfile, force = true)
		
		#
		#  write the history
		#
		open(configChangeHistoryFile,"a+") do h 
			hd = Dates.format(now(), "yyyy-mm-dd HH:MM:SS")
			history_previous = strip(history_previous,',')
			history_latest = strip(history_latest,',')
			
			# ref. around 242
			operator = ""
#			if "jetelinadb" ∉ dn
			if needJsession
				operator = JSession.get()[1];
			else
				operator = "it is me"
			end

			historyString = """{"date":"$hd","name":"$operator","previous":{$history_previous},"latest":{$history_latest}}"""
			println(h,historyString)
		end

		return true
	catch err
		@error "ConfigManager.configParamUpdate() error: $err"
		return false
	end
end

end
