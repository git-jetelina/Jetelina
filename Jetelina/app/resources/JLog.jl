"""
module: JLog

Author: Ono keiji

Description:
	read and write to log file

functions
	writetoLogfile(s)  write 's' to log file. date format is "yyyy-mm-dd HH:MM:SS".'s' is available whatever type.
	writetoSQLLogfile(apino, exetime, dbtype)  write executed sql with its apino to SQL log file. date format is "yyyy-mm-dd HH:MM:SS".
	writetoOperationHistoryfile(operationstr::String) write operation history to the file.
	getLogHash() return a hash number for identifying log data.
	searchinLogfile(errnum::String)	searching orderd log as 'errnum' in log file
"""
module JLog

using Logging, Dates
using Jetelina.JFiles, Jetelina.JMessage, Jetelina.JSession
import Jetelina.InitConfigManager.ConfigManager as j_config

JMessage.showModuleInCompiling(@__MODULE__)

export writetoLogfile, writetoSQLLogfile, writetoOperationHistoryfile, getLogHash, searchinLogfile

"""
function _logfileOpen()

	this function is hopefully be private.
	open log file. the log file is defined in Jetelina config file.

# Arguments
- return::tuple (IOStream, Logging.SimpleLogger)
"""
function _logfileOpen()
	logfile = JFiles.getFileNameFromLogPath(j_config.JC["logfile"])
	logfilemaxsize = parse(Int, j_config.JC["logfilesize"])

	try
		if ispath(logfile)
			logfilemaxsize = logfilemaxsize*1000000 # transfer to MB
			if logfilemaxsize < filesize(logfile)
				# file rotation
				_fileRotation(logfile)
			end
		end

		io = open(logfile, "a+")
		logger = SimpleLogger(io)
		return io, logger
	catch err
		println("JLog._logfileOpen(): $err")
	end
end
"""
function writetoLogfile(s)

	write 's' to log file. date format is "yyyy-mm-dd HH:MM:SS".'s' is available whatever type.
	in this function, trying to use Logging.with_logger()

# Arguments
- `s`: data to write in log file. String/Integer... whatever
"""
function writetoLogfile(s)
	# put date
	ss = string(Dates.format(now(), "yyyy-mm-dd HH:MM:SS"), " ", s)

	io, logger = _logfileOpen()
	with_logger(logger) do
		# do not delete this @info
		@info ss
	end

	_closeLogfile(io)
end
"""
function _closeLogfile(io::IOStream)

	this function is hopefully be private.
	close log file after fushing memory,

# Arguments
- `io::IOStream`: IOStream    
"""
function _closeLogfile(io::IOStream)
	flush(io)
	close(io)
end

"""
function writetoSQLLogfile(apino::String, exetime, dbtype::String)

	write executed sql with its apino to SQL log file. date format is "yyyy-mm-dd HH:MM:SS".
	in this function, trying to be simple file accessing, not use Logging module

# Arguments
- `apino` : apino ex. ji101
- `exetime`: api execution time. converted from Float64 to Float32, because it is enough and general, maybe.
- `dbtype`: using database name. ex. postgresql, mysql, redis, mongodb
"""
function writetoSQLLogfile(apino, exetime, dbtype)
	#==
		Tips:
			csv format is requested by SQLAnalyzer.
			ref: SQLAnalyzer.createAnalyzedJsonFile()
	===#
	sqllogfile = JFiles.getFileNameFromLogPath(j_config.JC["sqllogfile"])
	sqlfilemaxsize = parse(Int, j_config.JC["sqllogfilesize"])

	thefirstflg::Bool = true
    if !isfile(sqllogfile)
        thefirstflg = false
    end

	log_str = string(Dates.format(now(), "yyyy-mm-dd HH:MM:SS"), ",", apino, ",", exetime, ",", dbtype)

	try
		if ispath(sqllogfile)
			sqlfilemaxsize = sqlfilemaxsize*1000000 # transfer to MB
			if sqlfilemaxsize < filesize(sqllogfile)
				# file rotation
				_fileRotation(sqllogfile)
			end
		end

		open(sqllogfile, "a+") do f
            if !thefirstflg
                println(f, string(j_config.JC["file_column_time"], ',', j_config.JC["file_column_apino"], ',', j_config.JC["file_column_api_execution_time"], ',', j_config.JC["file_column_db"]))
            end

			println(f, log_str)
		end
	catch err
		writetoLogfile("JLog.writeToSQLLogfile() error: $err")
		return
	end
end
"""
function writetoOperationHistoryfile(operationstr::String)

	write operation history to the file. date format is "yyyy-mm-dd HH:MM:SS".
	in this function, trying to be simple file accessing, not use Logging module
	this file may will be used with DataFrames, therefore takes csv format so far.

# Arguments
- `operationstr::String`: operation string ex. create table_aa by keiji
"""
function writetoOperationHistoryfile(operationstr::String)
	#===
		Tips:
			JSession.get() returns tuple as (username, userid)
	===#
	operationfile = JFiles.getFileNameFromLogPath(j_config.JC["operationhistoryfile"])
	operationfilemaxsize = parse(Int, j_config.JC["operationhistoryfilesize"])
	sessiondata = JSession.get()

	thefirstflg::Bool = true
    if !isfile(operationfile)
        thefirstflg = false
    end

	hd = Dates.format(now(), "yyyy-mm-dd HH:MM:SS")
	whosename = sessiondata[1]
	whoseid   = sessiondata[2]
	log_str = """{"date":"$hd","operation":"$operationstr","name":"$whosename","userid":$whoseid}"""
#	log_str = string(Dates.format(now(), "yyyy-mm-dd HH:MM:SS"), ",\"", operationstr, "\",", sessiondata[1], ",", sessiondata[2])

	try
		if ispath(operationfile)
			operationfilemaxsize = operationfilemaxsize*1000000 # transfer to MB
			if operationfilemaxsize < filesize(operationfile)
				# file rotation
				_fileRotation(operationfile)
			end
		end

		open(operationfile, "a+") do f
            if !thefirstflg
                println(f, string(j_config.JC["file_column_time"], ',', j_config.JC["file_column_operation"], ',', j_config.JC["file_column_username"], ',', j_config.JC["file_column_userid"]))
            end

			println(f, log_str)
		end
	catch err
		writetoLogfile("JLog.writetoOperationHistoryfile() error: $err")
		return
	end
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
	mv(f,b)
end
"""
function getLogHash()

	return a hash number for identifying log data

# Arguments
- return::hash number  e.g. 0x2b97846807e6a54a
"""
function getLogHash()
	return _createHash()
end
"""
function _createHash()

	create hash code from date

# Arguments
- return::hash code  e.g. 0x2b97846807e6a54a
"""
function _createHash()
	#===
		Tips:
			p is a number whatever, as long as a uniquness
	===#
	p = string(Dates.format(now(), "yymmddMMSS"),rand(1:1000))
	return hash(p)
end
"""
function searchinLogfile(errnum::String)

	searching orderd log as 'errnum' in log file

# Arguments
- `errnum::String`: target 'errnum'
- return::String: log line within 'errnum'

"""
function searchinLogfile(errnum::String)
	logfile = JFiles.getFileNameFromLogPath(j_config.JC["logfile"])
	open(logfile, "r") do fl
		#===
			Tips:
				read log lines from the latest one with using 'Iterators.reverse()'
		===#
		for ss in Iterators.reverse(eachline(fl, keep = false))
			if contains(ss,errnum)
				return ss
			end
		end
	end
end

end
