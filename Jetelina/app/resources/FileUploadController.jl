"""
module: FileUploadController

Author: Ono keiji

Description:
	csv file upload controller

functions
	read(csvfname::String) read csv file, then insert the csv data into DB.
	fup() upload the csv file from fileuplaod.html.
"""
module FileUploadController

using Genie, Genie.Requests
using CSV, DataFrames
using Jetelina.JLog, Jetelina.DBDataController, Jetelina.JMessage
import Jetelina.InitConfigManager.ConfigManager as j_config

JMessage.showModuleInCompiling(@__MODULE__)

export read, fup

"""
function read( csvfname::String )

	read csv file, then insert the csv data into DB.


# Arguments
- `csvfname: String`: csv file name. Expect string data of JC["fileuploadpath"] + <csv file name>.
"""
function read(csvfname::String)  
    # write to operationhistoryfile
    JLog.writetoOperationHistoryfile(string("create table", ",", csvfname))
	return DBDataController.dataInsertFromCSV(csvfname)
end

"""
function fup()

	upload the csv file from fileuplaod.html.
	caution: ':upfile'(html tag id) is depend on fileupload.html
"""
function fup()
    if infilespayload(:upfile)
        csvfilename = ""
        files = Genie.Requests.filespayload()
        for f in files
            csvfilename = joinpath(@__DIR__, j_config.JC["fileuploadpath"], f[2].name)
            write(csvfilename, f[2].data)
        end

        read(csvfilename)
    else
        "No file uploaded"
    end
end
end
