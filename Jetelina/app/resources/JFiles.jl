"""
module: JFiles

Author: Ono keiji

Description:
	determaine the path of Jetelina files

functions
	getFileNameFromConfigPath(fname)  get full path of Jetelina Configuration files
	getJsFileNameFromPublicPath(fname)  get full path of Jetelina public files
	getFileNameFromLogPath(fname)  get full path of Jetelina log files
	fileBackup(fname::String) back up the ordered file with date suffix. ex. <file>.txt -> <file>.txt.yyyymmdd-HHMMSS
"""
module JFiles

using Dates
using Jetelina.JMessage

JMessage.showModuleInCompiling(@__MODULE__)

export getFileNameFromConfigPath, getJsFileNameFromPublicPath, getFileNameFromLogPath, fileBackup

"""
function getFileNameFromConfigPath(fname)

	get full path of Jetelina Configuration files 

# Arguments
- `fname: String`: target file name. expect String type, but not limited to that.
- return: full path of the tartget name. this path is under Genie zone.
"""
function getFileNameFromConfigPath(fname)
	return string(joinpath(@__DIR__, "config", fname))
end
"""
function getJsFileNameFromPublicPath(fname)

	get full path of Jetelina public files

# Arguments
- `fname: String`: target file name. expect String type, but not limited to that.
- return: full path of the tartget name. this path is under Genie zone.
"""
function getJsFileNameFromPublicPath(fname)
	return string(joinpath(@__DIR__, "..", "..", "public", "jetelina", "js", fname))
end
"""
function getFileNameFromLogPath(fname)

	get full path of Jetelina log files

# Arguments
- `fname: String`: target file name. expect String type, but not limited to that.
- return: full path of the tartget name. this path is under Genie zone.
"""
function getFileNameFromLogPath(fname)
	return string(joinpath(@__DIR__, "log", fname))
end
"""
function fileBackup(fname::String)

	back up the ordered file with date suffix. ex. <file>.txt -> <file>.txt.yyyymmdd-HHMMSS

# Arguments
- `fname::String`: target file name
"""
function fileBackup(fname::String)
	backupfilesuffix = Dates.format(now(), "yyyymmdd-HHMMSS")
	cp(fname, string(fname, backupfilesuffix), force = true)
end

end
