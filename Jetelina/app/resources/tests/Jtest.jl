"""
	module: Jtest

	Author: Ono keiji

	Description:
		module & total testing in jetelina

	functions
        doDbtest() wrapper function for execDbTest()
        execDbTest() execute each database test
"""

module Jtest

using DataFrames, Genie, Genie.Renderer, Genie.Renderer.Json, GenieSession, JSON3, CSV, Mongoc
using Jetelina.InitApiSqlListManager.ApiSqlListManager, Jetelina.JMessage, Jetelina.JLog, Jetelina.JSession, Jetelina.DBDataController
import Jetelina.InitConfigManager.ConfigManager as j_config

JMessage.showModuleInCompiling(@__MODULE__)

function __init__()
    if j_config.JC["debug"]
        @info "init Jtest"
    end
end
"""
function doDbtest()

	wrapper function for execDbTest()
    this function is called by GetDataController

"""
function doDbtest()
    execDbTest()
end
"""
function execDbTest()

	execute each database test

# Arguments
- return::json or boolean: success->json  fail->boolean
"""
function execDbTest() 
    pgsql::String = "postgresql"
    mysql::String = "mysql"
    mongd::String = "mongodb"
    redis::String = "redis"
    oracl::String = "oracle"

    function _getRedisKeys(fname)
        df = DataFrame(CSV.File(fname))
        key_arr::Vector{String} = []
        for i ∈ 1:nrow(df)
            push!(key_arr, lowercase(df.key[i]))
        end

        return key_arr
    end

    function _getMongoKeys(fname)
        jdata = Mongoc.BSONJSONReader(fname)
        key_arr::Vector{String} = []
        for bson in jdata
            push!(key_arr,bson["j_table"])
        end

        return key_arr
    end

    if j_config.JC["debug"]
        csvfile::String = ""
        if j_config.JC["dbtype"] == pgsql
            csvfile = j_config.JC["test4pg"]
        elseif j_config.JC["dbtype"] == mysql
            csvfile = j_config.JC["test4my"]
        elseif j_config.JC["dbtype"] == redis
            csvfile = j_config.JC["test4rd"]
        elseif j_config.JC["dbtype"] == mongd
            csvfile = j_config.JC["test4md"]
        elseif j_config.JC["dbtype"] == oracl
        end

        fname::String = joinpath(@__DIR__, j_config.JC["testpath"], csvfile)
        #
        #  create test table & jetelina apis
        #
        ri = DBDataController.dataInsertFromCSV(fname)
        insert_ret = JSON3.read(String(ri.body))
        if insert_ret.result
            uid = JSession.get()[2]
            ur = DBDataController.refUserInfo(uid, "stichwort", 1)
            if !ismissing(ur[:,:stichwort][1])
                sw = replace(ur[:,:stichwort][1], "\""=>"")
                dtype = j_config.JC["dbtype"]
                tableName::Vector = []
                if dtype == pgsql || dtype == mysql
                    tableName = [string(splitext(splitdir(fname)[2])[1])]
                elseif dtype == mongd
                    tableName = _getMongoKeys(fname)
                elseif dtype == redis
                    tableName = _getRedisKeys(fname)
                end
                #
                #  delete the created test table & jetelina apis
                #
                rd = DBDataController.dropTable(tableName, sw)
                return rd
            end
        else 
            @info "oh smth error"
            return ri
        end
    else
        @info "need to be debug mode"
    end
end

end