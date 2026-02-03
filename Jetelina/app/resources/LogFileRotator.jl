"""
module: LogFileRotator

Author: Ono keiji

Description:
    This module is for rotating Jetelina log files.
	
functions
	main() wrap function for executing _executerotating() that is the real file rotating function.
	stoprotating() manual stopper for log file totating repeat.
"""
module LogFileRotator

using Dates
using Jetelina.JMessage, Jetelina.JFiles, Jetelina.JLog, Jetelina.ApiAccessCounter 
import Jetelina.InitConfigManager.ConfigManager as j_config

JMessage.showModuleInCompiling(@__MODULE__)

const interval::Integer = 1200 # 20 min = 60*20
procflg = Ref(true) # rotation process progressable -> true, stop/error -> false

"""
function main()

	wrap function for executing _executerotating() that is the real file rotating function.
"""
function main()
	ft = j_config.JC["logfile_rotation_open"]
	tt = j_config.JC["logfile_rotation_close"]
		 
	task = @async while procflg[]
		if ft < Dates.format(now(),"HH:MM") < tt
			_executerotating()
			JLog.writetoLogfile(string("LogFileRotator.main() rotated log file in : ",Dates.format(now(), "yyyy-mm-dd-HH:MM")))
			ApiAccessCounter.collectApiAccessNumbers()
		end

		sleep(interval)
	end
end
"""
function _executerotating()

	execute log and sql log files
"""
function _executerotating()
	logfile = JFiles.getFileNameFromLogPath(j_config.JC["logfile"])
	sqllogfile = JFiles.getFileNameFromLogPath(j_config.JC["sqllogfile"])
	_fileRotation(logfile)
	_fileRotation(sqllogfile)
end
"""
function _fileRotation(f::String)

	"f" file move to "f.yyyy-mm-dd..." file.

# Arguments
- `f::String`: file name
"""
function _fileRotation(f::String)
#	b = string(f,".",Dates.format(now(), "yyyy-mm-dd-HH:MM"))
	b = string(f,".",Dates.format(now(), "yyyy-mm-dd"))
	if ispath(f)
		mv(f,b)
	end
end
"""
function stoprotating()

	manual stopper for log file totating repeat
"""
function stoprotating()
	procflg[] = false
end

end