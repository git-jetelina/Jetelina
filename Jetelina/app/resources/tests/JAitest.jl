"""
	module: JAitest.jl

	Author: Ono keiji

	Description:
		ai chat testing in jetelina

	functions
        doDbtest() wrapper function for execDbTest()
        execDbTest() execute each database test
"""

module JAitest

using DataFrames, JSON3, CSV
using Jetelina.JAiE5ChatController
import Jetelina.InitConfigManager.ConfigManager as j_config

function __init__()
        @info "init JAitest"
end
"""
function doTest()


"""
function doTest(fname::String)
    testfile::String = joinpath(@__DIR__, j_config.JC["testpath"], fname)
	try
		#
        # read tset csv File
		#
		f = open(testfile, "r")
		l = readlines(f)
		close(f)

        # hit JAiE5ChatController
		for i ∈ 1:length(l)
            if !startswith(l[i], "#")
                cmdraw= l[i]
                arr = String.(collect(first(CSV.File(IOBuffer(cmdraw), delim=',', header=false, quotechar='"', types=String))))
                ret = JAiE5ChatController.getAiChatCommand(arr[2])

                if ret[1] == strip(arr[1])
                    println("success: ", string(arr[2]," -> ", ret[1]))
                else
                    println("fail: ", string(arr[2]," -> ", ret[1]))
                end
            end
		end

    # compare the return
	catch err
		@error "JAitest.doTest() error: $err"
	end

    
end
end