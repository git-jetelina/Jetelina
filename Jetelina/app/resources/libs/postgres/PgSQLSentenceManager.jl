"""
module: PgSQLSentenceManager

Author: Ono keiji

Description:
	General DB action controller

functions
	checkSubQuery(subquery::String) check posted subquery strings wheather exists any illegal strings in it.
	createApiInsertSentence(tn::String,cs::String,ds::String) create sql input sentence by queries.
	createApiUpdateSentence(tn::String,us::Any) create sql update sentence by queries.
	createApiDeleteSentence(tn::String) create sql delete sentence by query.
	createApiSelectSentence(json_d::Dict,mode::String) create select sentence of SQL from posting data,
	createExecutionSqlSentence(json_dict::Dict, df::DataFrame) create real execution SQL sentence.
"""
module PgSQLSentenceManager

using DataFrames, StatsBase
using Genie, Genie.Requests, Genie.Renderer.Json
using Jetelina.InitApiSqlListManager.ApiSqlListManager, Jetelina.JMessage

JMessage.showModuleInCompiling(@__MODULE__)

export checkSubQuery, createApiInsertSentence, createApiUpdateSentence, createApiDeleteSentence, createApiSelectSentence, createExecutionSqlSentence

"""
function checkSubQuery(subquery::String)

	check posted subquery strings wheather exists any illegal strings in it.
	because subquery is free format posting data by user. 

# Arguments
- `subquery::String`: posted subquery
- return:  subquery string after processing
"""
function checkSubQuery(subquery::String)
    return replace.(subquery, ";" => "")
end
"""
function createApiInsertSentence(tn::String,cs::String,ds::String)

	create sql input sentence by queries.
	this function executs when csv file uploaded.

# Arguments
- `tn::String`: table name
- `cs::String`: column name strings
- `ds::String`: data strings
- return: String: sql insert sentence
"""
function createApiInsertSentence(tn::String, cs::String, ds::String)
    return """insert into $tn ($cs) values($ds)"""
end
"""
function createApiUpdateSentence(tn::String,us::Any)

	create sql update sentence by queries.
	this function executs when csv file uploaded.

# Arguments
- `tn::String`: table name
- `us::Any`: update strings
- return: Tuple: (sql update sentence, sub query sentence)
"""
function createApiUpdateSentence(tn::String, us::Any)
    jtid = string(tn, "_jt_id")
    return """update $tn set $us""", """where $jtid={jt_id}"""
end
"""
function createApiDeleteSentence(tn::String)

	create sql delete sentence by query.
	this function executs when csv file uploaded.

# Arguments
- `tn::String`: table name
- return: Tuple: (sql delete sentence, sub query sentence)
"""
function createApiDeleteSentence(tn::String)
    jtid = string(tn, "_jt_id")
    return """update $tn set jetelina_delete_flg=1""", """where $jtid={jt_id}"""
end
"""
function createApiSelectSentence(json_d::Dict, mode::String)

	create API and SQL select sentence from posting data,then append it to JC["tableapifile"].

# Arguments
- `json_d::Dict`: json data
- `mode::String`: 'ok'->real  'pre'->test
- return: 
        in case of mode = 'ok', try to create a sql sentence, then the return is tuple of (multitable::boolean, json)
            1. if the sql is already existing -> (false, json {"resembled":true})
		    2. if the sql is the new one (not in the list),
               try to append it to the list anyhow,
               in case of succeeding, 
                  i) if it had only a table -> (false, json {"apino":"<something no>"})
                 ii) if it had multi tables -> (true, json {"apino":"<something no>"})
               in case of failing  -> (false, false)
"""
function createApiSelectSentence(json_d, mode::String)
    item_d = json_d["item"]
    subq_d = json_d["subquery"]
    multitable::Bool = false

    #===
        add "jetelina_delete_flg=0" (meaning alive data) to sub query string.
        because the js* api only manages living data. 
    ===#
    function _addJetelinaDeleteFlg2Subquery(subq_d,tarr)
        if 1<length(tarr)
            jdf = "jetelina_delete_flg=0 "
            for i ∈ 1:length(tarr)
                if 1<i
                    subq_d = string(subq_d,")and( ",tarr[i],".",jdf)
                else
                    subq_d = string(subq_d," and((",tarr[i],".",jdf)
                end
            end

            subq_d = string(subq_d,"))")
        else
        end

        return subq_d
    end
    #==
    	Tips:
    		item_d:column post data from dashboard.html is expected below json style
    			{ 'item'.'["<table name>.<column name>","<table name>.<column name>",...]' }
    		then parcing it by jsonpayload("item") 
    			item_d -> ["<table name>.<column name1>","<table name>.<column name2>",...]

    		then handle it as an array data
    			[1] -> <table name>.<column name1>
    		furthermore deviding it to <table name> and <column name> by '.' 
    			table name  -> <table name>
    			column name -> <column name1>
    			use these to create sql sentence.
   	==#
    if (subq_d != "")
        subq_d = checkSubQuery(subq_d)
    end

    selectSql::String = ""
    tableName::String = ""
    #===
   		Tips: 
   			put into array to write it to JC["tableapifile"]. 
   			This is used in ApiSqlListManager.writeTolist().
    ===#
    tablename_arr::Vector{String} = []

    for i ∈ 1:length(item_d)
        t = split(item_d[i], ".")
        t1 = strip(t[1])
        t2 = strip(t[2])
        if 0 < length(selectSql)
            #===
                Tips: 
                    should be justfified this columns line for analyzing in SQLAnalyzer.
                        ex. select ftest.id,ftest.name from.....
            ===#
            selectSql = """$selectSql,$t1.$t2"""
        else
            selectSql = """$t1.$t2"""
        end

        if (0 < length(tableName))
            if (!contains(tableName, t1))
                tableName = """$tableName,$t1 as $t1"""
                push!(tablename_arr, t1)
            end
        else
            tableName = """$t1 as $t1"""
            push!(tablename_arr, t1)
        end
    end

    selectSql = """select $selectSql from $tableName"""

    subq_d = _addJetelinaDeleteFlg2Subquery(subq_d, tablename_arr)

    if mode != "pre"
        ck = ApiSqlListManager.sqlDuplicationCheck(selectSql, subq_d, "postgresql")
        if ck[1]
            # already exist it. return it and do nothing.
            return (multitable, Dict("result" => false, "resembled" => ck[2]))
        else
            # yes this is the new
            ret = ApiSqlListManager.writeTolist(selectSql, subq_d, tablename_arr, "postgresql")
            #===
                Tips:
                    writeTolist() returns tuple({true/false,apino/null}).
                    return apino in json style if the first in tuple were true.
            ===#
            if ret[1]
                if 1 < length(tablename_arr)
                    multitable = true
                end
                
                return (multitable, Dict("result" => true, "apino" => ret[2]))
            else
                return (multitable, json(Dict("result" => ret[1])))
            end
        end
    else
        # pre execution sql sentence
        keyword::String = "ignore" # protocol
        if contains(subq_d,keyword)
            subq_d = ""
        end

        return (multitable, string(selectSql," ",subq_d));
    end
end
"""
function createExecutionSqlSentence(json_dict::Dict, df::DataFrame)

	create real execution SQL sentence.
	using 'ignore' and 'subquery' as keywords to create SQL sentence. 
	These are the 'PROTOCOL' in using DataFrame of SQL list and posting data I/F.
	
	Attention: this select sentence searchs only 'jetelina_delete_flg=0" data.

# Arguments
- `json_dict::Dict`:  json raw data, uncertain data type        
- `df::DataFrame`: dataframe of target api data. a part of Df_JetelinaSqlList 
- return::String SQL sentence
"""
function createExecutionSqlSentence(json_dict::Dict, df::DataFrame)
    keyword1::String = "ignore" # protocol
    keyword2::String = "subquery" # protocol
    j_del_flg::String = "jetelina_delete_flg=0" # absolute select condition
    subquery_str::String = "" # contain df.subquery[1]. see Tips
    ret::String = "" # return sql sentence
    json_subquery_dict = Dict()
    execution_sql::String = ""

    #===
   		Tips:
   			this is a private function.
   			this function manages building 'jetelina_delete_flg' subquery.
   			in order to handle multi table, this 'jetelina_delete_flg' is also set as multi.
   			i mean
   				table1.jetelina_delete_flg=0 and table2.jetelina_delete_flg=0 and....

   			Caution: any local variables are not be duplicated with global ones. 
   	===#
    function __create_j_del_flg(sql::String)
        del_flg::String = "jetelina_delete_flg=0" # absolute select condition

        div_sql = split(sql, "from")
        if !isnothing(div_sql)
            if contains(div_sql[2], ',')
                tables = split(div_sql[2], ',')
                if !isnothing(tables)
                    multi_del_flg::String = ""
                    for i in eachindex(tables)
                        table = split(tables[i], "as")
                        if !isnothing(table)
                            if length(multi_del_flg) == 0
                                multi_del_flg = string(strip(table[1]), ".jetelina_delete_flg=0")
                            else
                                multi_del_flg = string(multi_del_flg, " and ", strip(table[1]), ".jetelina_delete_flg=0")
                            end
                        end
                    end

                    del_flg = multi_del_flg
                end
            end
        end

        return del_flg
    end

    #===
    	Tips:
    		this is a private function.
    		this function manages building subquery string.
    		because of 'limit' or something like this additions, 'jetelina_delete_flg' position has to be arranged.
    		i think it is good as setting it at the head, like
    			select .... where jetelina_delete_flg=0 and table1.something='aaa' limit 10 

    		Caution: any local variables are not be duplicated with global ones. 
    ===#
    function __create_subquery_str(sub_str::String, del_str::String)
        sub_ret::String = sub_str

        if contains(sub_str, "where")
            ss = split(sub_str, "where")
            if !isnothing(ss)
                sub_ret = string("where ", del_str, " and ", strip(ss[2]))
            end
        end

        return sub_ret
    end

    if 0 < length(json_dict)
        #===
        	Tips:
        		case in 'insert' has a chance of 'missing' in df.subquery[1].

        		Attention: 
        			using 'subquery_str' String type has a benefit rather than using df.subquery[1],
        			because df fields length are fixed as DataFrame when it was created.
        			I mean using straight as df.* may happen over flow in the case of concate strings.
        				ex. df.subquery[1] -> fixed String(10) in DataFrame
        						 df.subquery[1] = string(df.subquery[1], "AAAAAAAA") -> maybe get over flow 
        ===#
        if !ismissing(df.subquery[1])
            subquery_str = df.subquery[1]
        end

        if contains(json_dict["apino"], "js")
            # select
            if !isnothing(subquery_str) && !contains(subquery_str, keyword1) && !ismissing(subquery_str)
                #===
                	Tips:
                		set subquery data in json to df.subquery.
                		because it combines later with df.sql.
                		managing df.subquery is very advantageous process at here.
                ===#
                if haskey(json_dict, keyword2)
                    sp = split(json_dict[keyword2], ",")
                    if !isnothing(sp)
                        for ii in eachindex(sp)
                            if ii == 1 || ii == length(sp)
                                sp[ii] = replace.(sp[ii], "[" => "", "]" => "", "\"" => "", "'" => "")
                            end

                            ssp = split(sp[ii], ":")
                            if !isnothing(ssp) && 1 < length(ssp)
                                json_subquery_dict[strip(ssp[1])] = strip(ssp[2])
                            end
                        end
                    end

                    for (k, v) in json_subquery_dict
                        kk = string("{", k, "}")
                        subquery_str = replace.(subquery_str, kk => v)
                    end

                    # this private function __create_j_del_flg() is defined above.
                    j_del_flg = __create_j_del_flg(df.sql[1])
                    # this private function __create_subquery_str is defined above as well.
                    subquery_str = __create_subquery_str(subquery_str, j_del_flg)
                end
            else
                subquery_str = string("where ", j_del_flg)
            end
        elseif contains(json_dict["apino"], "ju") || contains(json_dict["apino"], "jd")
            # update/delete
            #   json_dict["subquery"] is always point to {jt_id}
            json_dict["jt_id"] = json_dict["subquery"]
        else
            # insert/update
            #   insert always needs to add 'jetelina_delete_flg' as 0.
            json_dict["jetelina_delete_flg"] = 0
        end

        execution_sql = string(df.sql[1], " ", subquery_str)

        #==
        	Tips:
        		json data bind to the sql sentence.
        		Dict() is used alike associative array.
    	===#
        for (k, v) in json_dict
            kk = string("{", k, "}")
            execution_sql = replace.(execution_sql, kk => v)
        end

        ret = execution_sql
    end

    return ret
end
end
