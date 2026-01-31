"""
module: MonSQLSentenceManager

Author: Ono keiji

Description:
	DB controller for Redis

functions
	keyDuplicationCheck(str::String)  confirm duplication, if 'str' exists in JC["sqllistfile"].but checking is in Df_JetelinaSqlList, not the real file, because of execution speed. 
	createApiInsertSentence() create MongoDB general set sentence.
	createApiUpdateSentence(str::String) create MongoDB update sentence.
	createApiSelectSentence(str::String) create MongoDB find sentence.
"""
module MonSQLSentenceManager

using DataFrames, StatsBase, JSON
using Genie, Genie.Requests, Genie.Renderer.Json
using Jetelina.InitApiSqlListManager.ApiSqlListManager, Jetelina.JMessage

JMessage.showModuleInCompiling(@__MODULE__)

export keyDuplicationCheck, createApiInsertSentence, createApiUpdateSentence, createApiSelectSentence

"""
function keyDuplicationCheck(str::String)

	confirm duplication, if 'str' exists in JC["sqllistfile"].
	but checking is in Df_JetelinaSqlList, not the real file, because of execution speed. 

# Arguments
- `str::String`: something json key data
- return::Bool : exist -> ture
				 not exist -> false
"""
function keyDuplicationCheck(str::String)
	ret::Bool = false
	#===
		Tips:
			ApiSql...readSql...()[1] contains true/false.
			ApiSql...readSql...()[2] contains dataframe list if [] is true, in the case of false is nothing.
	===#			
	if 0 < nrow(ApiSqlListManager.Df_JetelinaSqlList)
		df = ApiSqlListManager.Df_JetelinaSqlList
		ex = filter(:sql => s -> s == str, df)
		if(0<nrow(ex))
			ret = true
		end
	end

	return ret
end
"""
function createApiInsertSentence()

	create MongoDb general insert sentence.
	this function always inserts a new collection, therefore no need to check for duplication in the sql list, maybe.

# Arguments
- return: String: 
"""
function createApiInsertSentence()
	ret::String =  "{insert}"

	return ret
end
"""
function createApiUpdateSentence(str::String)

	create mongodb update sentence.
	this function always works for an unique collection, therefore no need to check for duplication in the sql list, maybe.

# Arguments
- `str::String`: json string
- return: String: 
"""
function createApiUpdateSentence(str::String)
	ret::String =  "{update}"

	return ret
end
"""
function createApiDeleteSentence(str::String)

	create document delete sentence.

# Arguments
- `str::String`: document name
- return: Tuple: (sql delete sentence, sub query sentence)
"""
function createApiDeleteSentence(str::String)
	return "{delete}"
end
"""
function createApiSelectSentence(str::String)

	create MongoDB find sentence.
	'find' is fit on Mongo,but use 'select' word to make match with other DB's API.
	this function always works for an unique collection, therefore no need to check for duplication in the sql list, maybe.

# Arguments
- `str::String`: json string
- return: String
"""
function createApiSelectSentence(str::String)
	ret::String =  "{find}"

	return ret
end

function createApiSelectSentenceByselectedKeys(json_d::Dict, mode::String)
    item_d = json_d["item"]
	collectionname = json_d["collection"]
	tablename_arr::Vector{String} = []

	#===
		Tips:
			ok i know "subquery" is ridicurous name, but to unify it into other db functions. :p
	===#
	subquery::String = """$collectionname"""
	push!(tablename_arr, collectionname)

	dic = Dict()

    for i ∈ 1:length(item_d)
        t = split(item_d[i], ".")
		
		if haskey(dic, t[1]) == false
			dic[t[1]] = []
		end

		push!(dic[t[1]],t[2])

		if t[1] ∉ tablename_arr
			push!(tablename_arr,t[1])
		end

		if !contains(subquery,t[1])
			subquery = string(subquery,",",t[1])
		end
	end

	if mode != "pre"
		#==
			Tips:
				create 'finde' sentence then write it into JetelinaSqlList
		===#
		# ApiSqlListManager.sqlDuplicationCheck()
		if 0<length(dic)
			findStr = JSON.json(Dict(k => v for (k,v) in dic))
			ret = ApiSqlListManager.writeTolist(findStr, subquery, tablename_arr, "mongodb")
			if ret[1]
                return JSON.json(Dict("result" => true, "apino" => ret[2]))
			else
				return ret[1]
			end
		end

	else
		# find文を組み立てて返す
	end
end
end
