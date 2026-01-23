"""
module: PgTestDBController

Author: Ono keiji

Description:
	test db controller for PostgreSQL.
	this module might should be integrated in PgDBController module.:-p

functions
	open_connection()  open connection to the test db.
	close_connection( conn::LibPQ.Connection )  close the test db connection
	doSelect(sql::String)  execute ordered sql sentence on test db and acquire its speed.
	measureSqlPerformance()  execute 'select' sql sentence and write the execution speed into a file
"""
module PgTestDBController

using CSV, LibPQ, DataFrames, IterTools, Tables
using Jetelina.JFiles, Jetelina.JLog, Jetelina.JMessage
import Jetelina.InitConfigManager.ConfigManager as j_config

JMessage.showModuleInCompiling(@__MODULE__)

export measureSqlPerformance

"""
function open_connection()

	open connection to the test db.
	connection parameters are set by global variables.

# Arguments
- return: LibPQ.Connection object    
"""
function open_connection()
	con_str = string("host='", j_config.JC["host"],
		"' port='", j_config.JC["pg_port"],
		"' user='", j_config.JC["pg_user"],
		"' password='", j_config.JC["pg_password"],
		"' sslmode='", j_config.JC["pg_sslmode"],
		"' dbname='", j_config.JC["pg_testdbname"], "'")

	return conn = LibPQ.Connection(con_str)
end

"""
function close_connection( conn::LibPQ.Connection )

	close the test db connection

# Arguments
- `conn:LibPQ.Connection`: LibPQ.Connection object
"""
function close_connection(conn::LibPQ.Connection)
	close(conn)
end

"""
function doSelect(sql::String)

	execute ordered sql sentence on test db and acquire its speed.

# Arguments
- `sql::String`: execute sql sentense
- return: boolean: false in fale.
"""
function doSelect(sql::String)
	conn = open_connection()
	try
		#===
			Tips:
				acquire data are 'max','best',"mean'.
		===#
		exetime = []
		looptime = 10
		for loop in 1:looptime
			stats = @timed z = LibPQ.execute(conn, sql)
			push!(exetime, stats.time)
		end

		return findmax(exetime), findmin(exetime), sum(exetime) / looptime
	catch err
		println(err)
		JLog.writetoLogfile("PgTestDBController.doSelect() with $sql error : $err")
		return false
	finally
		# close the connection
		close_connection(conn)
	end
end

"""
function measureSqlPerformance()

	execute 'select' sql sentence and write the execution speed into a file
	Attention: JC["experimentsqllistfile"] is created when SQLAnalyzer.main()(indeed createAnalyzedJsonFile()) runs.
			   JC["experimentsqllistfile"] does not created if there were not sql.log file and data in it.
			   yes, this measure..() function is called after creating that file in SQLAnalyzer, but for secure. maybe too much.:p

"""
function measureSqlPerformance()
	#===
		Tips:
			I know it can use Df_JetelinaSqlList here, but wanna leave a evidence what sql are executed.
			That's reason why JC["experimentsqllistfile"] file is opend here.
	===#
	sqlFile = JFiles.getFileNameFromConfigPath(j_config.JC["experimentsqllistfile"])
	if isfile(sqlFile)
		sqlPerformanceFile = JFiles.getFileNameFromConfigPath(string(j_config.JC["sqlperformancefile"], ".test"))
		open(sqlPerformanceFile, "w") do f
			println(f, string(j_config.JC["file_column_apino"], ',', j_config.JC["file_column_max"], ',', j_config.JC["file_column_min"], ',', j_config.JC["file_column_mean"]))
			df = CSV.read(sqlFile, DataFrame)
			for i in 1:size(df, 1)
				if startswith(df.apino[i], "js")
					p = doSelect(df.sql[i])
					fno::String = df.apino[i]
					fmax::Float64 = p[1][1]
					fmin::Float64 = p[2][1]
					fmean::Float64 = p[3]
					s = """$fno,$fmax,$fmin,$fmean"""
					println(f, s)
				end
			end
		end
	end
end

end
