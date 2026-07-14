"""
	module: Jtest

	Author: Ono keiji

	Description:
		module & total testing in jetelina

	functions
"""

module Jtest

using DataFrames, Genie, Genie.Renderer, Genie.Renderer.Json, GenieSession, JSON3
using Jetelina.InitApiSqlListManager.ApiSqlListManager, Jetelina.JMessage, Jetelina.JLog, Jetelina.JSession, Jetelina.DBDataController
import Jetelina.InitConfigManager.ConfigManager as j_config

JMessage.showModuleInCompiling(@__MODULE__)

function __init__()
    if j_config.JC["debug"]
        @info "init Jtest"
    end
end

function doDbtest()
    execDbTest()
end

function execDbTest() 
    if j_config.JC["debug"]
        csvfile::String = ""
        if j_config.JC["dbtype"] == "postgresql"
            csvfile = j_config.JC["test4pg"]
        elseif j_config.JC["dbtype"] == "mysql"
            csvfile = j_config.JC["test4my"]
        elseif j_config.JC["dbtype"] == "redis"
            csvfile = j_config.JC["test4rd"]
        elseif j_config.JC["dbtype"] == "mongodb"
            csvfile = j_config.JC["test4md"]
        elseif j_config.JC["dbtype"] == "oracle"
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
                tableName = [string(splitext(splitdir(fname)[2])[1])]
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