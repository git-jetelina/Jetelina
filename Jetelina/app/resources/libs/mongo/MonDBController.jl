"""
module: MonDBController

Author: Ono keiji

Description:
	DB controller for MongoDB

functions
	open_connection() open connection to the DB.
	open_collection(jcollection::String) open "collection" to the DB.
	close_connection()  close the DB connection, but attention...
	dataInsertFromJson(collectionname::String, fname::String) insert csv file data ordered by 'fname' into table. the table name is the csv file name.
	documentDuplicationChk(collection::Mongoc.Collection, bson::Mongoc.BSON) check for existing document.
	dropTable(jcollection::String, ableName::Vector) delete the documents. this function name is not showing the real action, but to match with other libs.
	getDocumentList(jcollection::String,s::String) get all 'document' in 'jcollection'.
	executeApi(json_d::Dict,df_api::DataFrame) execute API order by json data
	prepareDbEnvironment(mode::String) database connection checking, and initializing database if needed
"""
#===
		Tips:
			words against RDBMS

			  |   RDBMS   |  MongoDB  |
			  | database  | database  |
			  | table     | collection|
			  | row       | document  |
			  | column    | field     |
===#
module MonDBController

using Genie, Genie.Renderer, Genie.Renderer.Json
using CSV, Mongoc, DataFrames, IterTools, Tables, Dates, JSON3
using Jetelina.JFiles, Jetelina.JLog, Jetelina.InitApiSqlListManager.ApiSqlListManager, Jetelina.JMessage, Jetelina.JSession
import Jetelina.InitConfigManager.ConfigManager as j_config

JMessage.showModuleInCompiling(@__MODULE__)

include("MonDataTypeList.jl")
include("MonSQLSentenceManager.jl")

export open_connection, open_collection, close_connection, dataInsertFromJson, dropTable, getDocumentList, executeApi, prepareDbEnvironment

"""
function open_connection()

	open connection to the DB.
	connection parameters are set by global variables.

# Arguments
- return: Mongoc.Client object
"""
function open_connection()
	host = string(j_config.JC["mongodb_host"])
	port = parse(Int, j_config.JC["mongodb_port"])
	db = string(j_config.JC["mongodb_dbname"])
	user = string(j_config.JC["mongodb_user"])
	password = string(j_config.JC["mongodb_password"])

	connectionstr::String = ""

	if user == "" || password == ""
		connectionstr = """mongodb://$host:$port"""
	else
		connectionstr = """mongodb://$user:$password@$host/?authSource=admin"""
	end

	client = Mongoc.Client(connectionstr)
	return client[db]
end
"""
function open_collection(jcollection::String)

	open "collection" to the DB.
	this function is for setting "collection" in Mongoc.Client.

# Arguments
- `jcollection: String`: Monogdb collection name
- return: Mongoc.Client with setting collection
"""
function open_collection(jcollection::String)
	if isnothing(jcollection) || length(jcollection) == 0
		jcollection = string(j_config.JC["mongodb_collection"])
	end

	database = open_connection()
	return database[jcollection]
end
"""
function close_connection()

	Attention:
		this function is for preventing of misunderstanding.
		Mongoc module does not have a disconnect function, because the Client() has the function in it.
		Indeed there is finalizer() in Client() to disconnect the connection automatically when the connection has been focused out.
		this is very smart behavior but easy to misunderstand in how to disconnect, I think. Sometimes a programer likes to make clear its logic no matter what implicit definitions.
		therefore this close_connection() keeps alive in case you would feel unsafe, but not working.

"""
function close_connection()
	# empty :p
end
"""
function dataInsertFromJson(collectionname::String, fname::String)

	insert json file data ordered by 'fname' into collection.

	Caution:
		regurate 1 collection , max 64 index(mean 64 json data) in this version.
		no check at size e.g. BSON size(max16mb). rely on user, this time. :)

# Arguments
- `collectionname: String`: ordered collection name
- `fname: String`: json file name
- return: boolean: true -> success, false -> get fail
"""
function dataInsertFromJson(collectionname::String, fname::String)
	ret::Bool = true
	jmsg::String = string("compliment me!")

	if isnothing(collectionname) || length(collectionname) == 0
		collectionname = string(j_config.JC["mongodb_collection"])
	end
	#===
		Tips:
			should set the parameter in open_collection() in order to change the collection.
			but the collection is fixed in the earliest version.
			will may need to modify parameters in dataInsertFromJson() as well if would be changed by ordering.  
	===#
	collection = open_collection(collectionname)

	# do it all at once
	#bsons = Mongoc.read_bson_from_json(fname)
	#result = append!(collection,bsons)

	# do it one by one
	jdata = Mongoc.BSONJSONReader(fname)
	insertapi::Bool = true
	insertDataCount::Int = 0

	for bson in jdata
		if documentDuplicationChk(collection, bson) == false
			insertDataCount += 1
			# data insert
			push!(collection, bson)
			_createApis(collectionname, bson["j_table"], insertapi)
			insertapi = false
		end
	end

	if insertDataCount == 0
		ret = false
		jmsg = "may these 'j_table' are duplicated, check them."
	end

	return json(Dict("result" => ret, "filename" => "$fname", "message from Jetelina" => jmsg))
end
"""
function documentDuplicationChk(collection::Mongoc.Collection, bson::Mongoc.BSON)

	check for existing document.

# Arguments
- `collection: Mongoc.Collection`: ordered Collection
- `bson: Mongoc.BSON`: target document
- return: boolean: true -> not exist, false -> is already
"""
function documentDuplicationChk(collection::Mongoc.Collection, bson::Mongoc.BSON)
	ret::Bool = false

	#	j_table = bson["j_table"]
	#	bson = Mongoc.find_one(collection,Mongoc.BSON("""{ "j_table":"$j_table"}"""))
	jb = Mongoc.find_one(collection, bson)
	if !isnothing(jb)
		ret = true
	end

	return ret
end
function _createApis(collectionname::String, j_table::String, insertapi::Bool)
	ret_i::Tuple = (Bool, String)
	ret_u::Tuple = (Bool, String)
	ret_d::Tuple = (Bool, String)
	ret_s::Tuple = (Bool, String)
	dbname::String = "mongodb"
	#===
		Tips:
			'subquery' is be contained in the sql list file as alternative sql.
			'tablename_arr' is be contained in the relation file as alternative relation tables vs api.
			the both are fixed in order as 'collection name','table name'. 
			because of this, the rule in every database are protected.

			ref: ApiSqlListManager.writeTolist(sql::String,subquery::String,tablename_arr::Vector{String},db::String)
	===#
	tablename_arr::Vector{String} = []
	subquery::String = ""
	if !isnothing(collectionname)
		subquery = collectionname
		push!(tablename_arr, collectionname)
	else
		push!(tablename_arr, "")
	end

	if !isnothing(j_table)
		subquery = string(subquery, ",", j_table)
		push!(tablename_arr, j_table)
	else
		subquery = string(sql, ",", "")
		push!(tablename_arr, "")
	end

	#===
		Tips:
			this __only...() function is checking for existing "ji" yet in Df_JetelinaSqlList DataFrame.
			subset() can hires 2 args for execution "and" logic, in this case, one is ":db" the other is ":subquery".
			but this "and" logic is critical in case of initial entry. i mean there is no mongodb apis yet.
			therefore take 2 steps as below.

			ref. https://dataframes.juliadata.org/stable/lib/functions/#DataFrames.subset
	===#
	function __onlyonejiinonecollection()
		#		df = subset(ApiSqlListManager.Df_JetelinaSqlList, :db => ByRow(==(dbname)), :subquery=>ByRow(contains(collectionname)), skipmissing = true)
		df = subset(ApiSqlListManager.Df_JetelinaSqlList, :db => ByRow(==(dbname)), skipmissing = true)
		if 0 < nrow(df)
			dfc = subset(df, :subquery => ByRow(contains(collectionname)), skipmissing = true)
			for i ∈ 1:nrow(dfc)
				if startswith("ji", dfc[!, :apino][i])
					return true, dfc[!, :apino][i]
				end
			end
		end

		return false
	end

	# create api in each bson
	#===
	insert
		Tips:
			insert api "ji" is only one for each collection.
			because this "ji" is for inserting a document.
			__onlyonejiinonecollection() is for checking "ji" duplication as strictly private function.

		Caution:
			but in this version has been applied a fixed database.
	===#
	if insertapi
		insert_str = MonSQLSentenceManager.createApiInsertSentence()
		#		if (insert_str != "") && ( ApiSqlListManager.sqlDuplicationCheck(insert_str,"",dbname)[1] == false )
		if (insert_str != "") && (__onlyonejiinonecollection() == false)
			#===
				Tips:
					this "col" is just for matiching to the third argument in .writeTolist()
			===#
			col::Vector{String} = []
			push!(col, collectionname)
			ret_i = ApiSqlListManager.writeTolist(insert_str, collectionname, col, dbname)
		end
	end
	#===
		Tips:
			update and select(find) works with a plane json format data that is provided by an user.
			therefore an argument in each functions(createApi...) are to be empty.
	===#
	# update (set)
	update_str = MonSQLSentenceManager.createApiUpdateSentence("")
	if (update_str != "")
		ret_u = ApiSqlListManager.writeTolist(update_str, subquery, tablename_arr, dbname)
	end

	delete_str = MonSQLSentenceManager.createApiDeleteSentence(j_table)
	if (delete_str != "")
		ret_d = ApiSqlListManager.writeTolist(delete_str, subquery, tablename_arr, dbname)
	end

	# select (find)
	select_str = MonSQLSentenceManager.createApiSelectSentence(j_table)
	if (select_str != "")
		ret_s = ApiSqlListManager.writeTolist(select_str, subquery, tablename_arr, dbname)
	end

	return ret_i, ret_u, ret_d, ret_s
	#	return ret_i, ret_u, ret_s
end
"""
function dropTable(jcollection::String, ableName::Vector)

	delete the documents. this function name is not showing the real action, but to match with other libs.

# Arguments
- `jcollection:String`: collection name
- `tableName: Vector`: ordered tables name
- return: tuple (boolean: true -> success/false -> get fail, JSON)
"""
function dropTable(jcollection::String, tableName::Vector)
	ret = ""
	jmsg::String = string("compliment me!")
	rettables::String = join(tableName, ",") # ["a","b"] -> "a,b" oh ＼(^o^)／

	documents = open_collection(jcollection)

	try
		r = Mongoc.BSON()
		for j_table in tableName
			# drop the tableName
			selector = Mongoc.BSON("j_table" => j_table)
			r = Mongoc.delete_one(documents, selector)
		end

		if 0 < r["deletedCount"]
			ret = json(Dict("result" => true, "tablename" => "$rettables", "message from Jetelina" => jmsg))
		else
			ret = json(Dict("result" => true, "tablename" => "$rettables", "message from Jetelina" => "not found"))
		end

		# write to operationhistoryfile
		JLog.writetoOperationHistoryfile(string("delete ", rettables, " documents"))
	catch err
		errnum = JLog.getLogHash()
		ret = json(Dict("result" => false, "tablename" => "$rettables", "errmsg" => "$err", "errnum" => "$errnum"))
		JLog.writetoLogfile("[errnum:$errnum] MonDBController.dropTable() with $rettables error : $err")
		return false, ret
	finally
	end

	return true, ret
end
"""
function getDocumentList(jcollection::String, s::String)

	get all 'document' in 'jcollection'.

# Arguments
- `jcollection:String`: collection name
- `s:String`: 'json' -> required JSON form to return
			'dataframe' -> required DataFrames form to return
- return: document list
"""
function getDocumentList(jcollection::String, s::String)
	jmsg::String = string("compliment me!")
	keyword::String = "j_table"
	docArr::Array = []

	documents = open_collection(jcollection)

	for j_table in documents
		push!(docArr, j_table[keyword])
	end

	df = DataFrame(j_table = docArr)
	if s == "json"
		return json(Dict("result" => true, "Jetelina" => copy.(eachrow(reverse(df))), "message from Jetelina" => jmsg))
	elseif s == "dataframe"
		return df
	end
end
"""
function getKeys(jcollection::String, j_table::String)

	get all 'key' in 'jcollection'.

# Arguments
- `jcollection:String`: collection name
- `j_table:String`    : "j_table" name in the collection. this is the unique key.
- `s:String`: 'json' -> required JSON form to return
			'dataframe' -> required DataFrames form to return
- return: document list
"""
function getKeys(jcollection::String, j_table::String)
	keyarr::Array = []
	valuearr::Array = []
	jmsg::String = string("compliment me!")

	if isnothing(jcollection) || length(jcollection) == 0
		jcollection = string(j_config.JC["mongodb_collection"])
	end

	jbsons = open_collection(jcollection)
	if 0 < length(jbsons)
		jb = Mongoc.find_one(jbsons, Mongoc.BSON("""{ "j_table":"$j_table"}"""))
		if 0 < length(jb)
			for (k, v) in jb
				push!(valuearr, k)
			end
		end
	end

	if 0 < length(valuearr)
		df = DataFrame(keyarr = valuearr)
		ret = json(Dict("result" => true, "tablename" => "$j_table", "Jetelina" => copy.(eachrow(df)), "message from Jetelina" => jmsg))
	else
		ret = json(Dict("result" => false, "tablename" => "$j_table", "Jetelina" => "[{}]"))
	end

	return ret
end
"""
function executeApi(json_d::Dict,df_api::DataFrame)

	execute API order by json data
	this function is a parent function that calls _executeApi()
	determine the target then executs it in _executeApi()

# Arguments
- `json_d::Dict`:  json raw data, uncertain data type        
- `df_api::DataFrame`: a part of api/sql DataFrame data        
- return: insert/update/delete -> true/false
		select               -> json format data
		error                -> false
"""
function executeApi(json_d::Dict, df_api::DataFrame)
	return _executeApi(json_d, df_api)
end
"""
function _executeApi(apino::String, df_api::DataFrame)

	execute API with creating SQL sentence
	this is a private function that is called by executeApi()

# Arguments
- `apino::String`:  apino
- `df_api::DataFrame`: target mongodb api dataframe        
- return: insert/update/delete -> true/false
		select               -> json format data
		error                -> false
"""
function _executeApi(json_d::Dict, df_api::DataFrame)
	apino = json_d["apino"]
	ret = ""
	j_table::String = ""
	collectionname::String = ""
	jmsg::String = string("compliment me!")

	alternative_subquery = df_api[!, :subquery][1]
	if !startswith(apino, "ji")
		sub = split(alternative_subquery, ",")
		collectionname = string(sub[1])
		j_table = string(sub[2])        # this 'j_table' is unique in each documents
	else
		json_d_string = JSON3.write(json_d["new document"])
		j_table = Mongoc.BSON(json_d_string)["j_table"]
		collectionname = alternative_subquery
	end

	if j_table != "" && !isnothing(j_table) && !ismissing(j_table)
		findstr = """{\"j_table\":\"$j_table\"}"""
		bson = Mongoc.BSON(findstr)
		collection = open_collection(collectionname)

		if startswith(apino, "js")
			# find
			finddata_bson::Array = []
			finddata_json::Array = []

			if df_api[!, :sql][1] != "{find}"
				# something ordered
			end

			doc = Mongoc.find(collection, bson)
			if isnothing(doc) == false
				for d in doc
					jd = Mongoc.as_json(d)
					push!(finddata_json, jd)
				end
			end

			if 0 < length(finddata_json)
				ret = json(Dict("result" => true, "Jetelina" => [finddata_json], "message from Jetelina" => jmsg))
			else
				ret = json(Dict("result" => false, "Jetelina" => "[{}]", "message from Jetelina" => "not found"))
			end
		elseif startswith(apino, "ju")
			#===
				Tips:
					'update' is applied to a specific document as an unique determined 'j_table'. 
			===#
			for (k, v) in json_d
				if k != "apino"
					udstr::String = ""
					p = string(eltype(v))
					if p != "Char"
						#===
							Tips:
								in case: Integer, Float, Boolean....
						===#
						udstr = "{\"$k\": $v}"
					else
						#===
							Tips:
								in case: String, Date
						===#
						udstr = "{\"$k\": \"$v\"}"
					end

					updata = Mongoc.BSON("""{"\$set": $udstr}""")
					ret = Mongoc.update_one(collection, bson, updata)
				end
			end

			if 0 < ret["matchedCount"]
				ret = json(Dict("result" => true, "Jetelina" => "[{}]", "message from Jetelina" => jmsg))
			else
				# what happend?
				@info "failed in update " ret
			end
		elseif startswith(apino, "jd")
			ret = Mongoc.delete_one(collection, bson)
			if 0 < ret["deletedCount"]
				ret = json(Dict("result" => true, "Jetelina" => "[{}]", "message from Jetelina" => jmsg))
				# update SQL list
				tables::Vector = [j_table]
				ApiSqlListManager.deleteTableFromlist(tables)
			else
				# what happend?
				@info "failed in delete " ret
			end
		elseif startswith(apino, "ji")
			ret = false
			if isnothing(Mongoc.find_one(collection, bson))
				# new document
				newdoc = JSON3.write(json_d["new document"])
				insertbson = Mongoc.BSON(newdoc)
				push!(collection, insertbson)
				j_table = insertbson["j_table"]
				ret = json(Dict("result" => true, "Jetelina" => "[{}]", "message from Jetelina" => jmsg))

				#===
					Tips:
						after data insertion, check it once then create APIs sentences.
						because the result of push!() is too difficult to judge the succession.

					Caution:
						"insert" and "delete" apis are created only in uploading file, thus ret_i and ret_d do not be used in below.
				===#

				# create new apis
				(ret_i, ret_u, ret_d, ret_s) = _createApis(collectionname, j_table, false)

				if ret_u[1] && ret_s[1] && ret_d[1]
					apino_u = ret_u[2]
					apino_s = ret_s[2]
					ret = json(Dict("result" => true, "Jetelina" => "[{}]", "apino" => ["$apino_u", "$apino_s"], "message from Jetelina" => jmsg))
				elseif ret_u[1]
					apino_u = ret_u[2]
					jmsg = "only update api has been created, select api is why?"
					ret = json(Dict("result" => true, "Jetelina" => "[{}]", "apino" => ["$apino_u", ""], "message from Jetelina" => jmsg))
				elseif ret_s[1]
					apino_s = ret_s[2]
					jmsg = "only select api has been created, update api is why?"
					ret = json(Dict("result" => true, "Jetelina" => "[{}]", "apino" => ["", "$apino_s"], "message from Jetelina" => jmsg))
				end
			else
				# duplication, then nothing to do
				jmsg = "your ordered '$j_table' is already in there"
				ret = json(Dict("result" => false, "Jetelina" => "[{}]", "message from Jetelina" => jmsg))
			end
		end
	else
		jmsg = "need an unique 'j_table', check it."
		ret = json(Dict("result" => false, "Jetelina" => "[{}]", "message from Jetelina" => jmsg))
	end

	return ret
end




"""
function prepareDbEnvironment()

	database connection checking, and initializing database if needed
		
# Arguments
- `mode::String`: 'init' -> initialize, others -> connection check
				  but this parameter does not have any meaning in here, 
				  just match with the same name function of mysql/postgresql. :p
- return: success -> true, fail -> false
"""
function prepareDbEnvironment(mode::String)
	ret::Bool = false
	try
		open_connection()
		close_connection() # dummy :p
		return true, ""
	catch err
		errnum = JLog.getLogHash()
		JLog.writetoLogfile("[errnum:$errnum] MonDBController.prepareDbEnvironment() error : $err")
		return ret, errnum
	finally
	end
end

end
