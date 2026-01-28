"""
module: RsSQLSentenceManager

Author: Ono keiji

Description:
	DB controller for Redis

functions
	keyDuplicationCheck(key::String)  confirm duplication, if 'key' exists in JC["sqllistfile"].but checking is in Df_JetelinaSqlList, not the real file, because of execution speed. 
	createApiInsertSentence() create redis general set sentence.
	createApiUpdateSentence(key) create redis set sentence.this sentence is for updating an existence data.
	createApiSelectSentence(key) create redis get sentence.
"""
module RsSQLSentenceManager

using DataFrames, StatsBase
using Genie, Genie.Requests, Genie.Renderer.Json
using Jetelina.InitApiSqlListManager.ApiSqlListManager, Jetelina.JMessage

JMessage.showModuleInCompiling(@__MODULE__)

export keyDuplicationCheck, createApiInsertSentence, createApiUpdateSentence, createApiSelectSentence

"""
function keyDuplicationCheck(key::String)

	confirm duplication, if 'key' exists in JC["sqllistfile"].
	but checking is in Df_JetelinaSqlList, not the real file, because of execution speed. 

# Arguments
- `key::String`: key name
- return::Bool : exist -> ture
				 not exist -> false
"""
function keyDuplicationCheck(key::String)
	ret::Bool = false
	#===
		Tips:
			ApiSql...readSql...()[1] contains true/false.
			ApiSql...readSql...()[2] contains dataframe list if [] is true, in the case of false is nothing.
	===#			
	if 0 < nrow(ApiSqlListManager.Df_JetelinaSqlList)
		df = ApiSqlListManager.Df_JetelinaSqlList
		ex = filter(:sql => s -> s == key, df)
		if(0<nrow(ex))
			ret = true
		end
	end

	return ret
end
"""
function createApiInsertSentence()

	create redis general set sentence.

# Arguments
- return: String: 
"""
function createApiInsertSentence()
	ret::String = ""
	str =  """set::"""
	if(!keyDuplicationCheck(str))
		ret = str
	end

	return ret
end
"""
function createApiUpdateSentence(key)

	create redis set sentence.
	this sentence is for updating an existence data

# Arguments
- `key::String`: key name
- return: String: 
"""
function createApiUpdateSentence(key)
	ret::String = ""
	str =  """set:$key:{value}"""
	if(!keyDuplicationCheck(str))
		ret = str
	end

	return ret
end
"""
function createApiSelectSentence(key)

	create redis get sentence.

# Arguments
- `key::String`: key name
- return: String
"""
function createApiSelectSentence(key)
	ret::String = ""
	str =  """get:$key"""
	if(!keyDuplicationCheck(str))
		ret = str
	end

	return ret
end
end
