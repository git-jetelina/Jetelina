"""
	module: Jtest

	Author: Ono keiji

	Description:
		module & total testing in jetelina

	functions
"""

module Jtest

using DataFrames, Genie, Genie.Renderer, Genie.Renderer.Json
using Jetelina.InitApiSqlListManager.ApiSqlListManager, Jetelina.JMessage, Jetelina.JLog, Jetelina.JSession
import Jetelina.InitConfigManager.ConfigManager as j_config

JMessage.showModuleInCompiling(@__MODULE__)

function __init__()
    @info "init Jtest"
end

function doDbtest()
    setSession()
    execDbTest()
end

function execDbTest() 
    if j_config.JC["debug"]
        if j_config.JC["dbtype"] == "postgresql"
            @info "read postgresql"
            csvfile == "testdata4postgres.csv"
        elseif j_config.JC["dbtype"] == "mysql"
            @info "read mysql"
            csvfile == "testdata4mysql.csv"
        elseif j_config.JC["dbtype"] == "redis"
            @info "read redis"
            csvfile == "testdata4redis.csv"
        elseif j_config.JC["dbtype"] == "mongodb"
            @info "read mongodb"
            csvfile == "testdata4mongodb.csv"
        elseif j_config.JC["dbtype"] == "oracle"
            @info "read oracle"
        end

        testdatapath::String = "testdata"
        fname::String = joinpath(@__DIR__, j_config.JC["testpath"], testdatapath, csvfile)
        DBDataController.dataInsertFromCSV(fname)
    else
        @info "need to be debug mode"
    end
end

function setSession()
    # after loginなら不要かなぁ
end

end