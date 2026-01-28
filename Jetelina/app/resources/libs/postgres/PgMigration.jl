"""
module: PgDBController

Author: Ono keiji

Description:
	Migrate existing tables to Jetelina tables for PostgreSQL

functions

"""
module PgMigration

#using Genie, Genie.Renderer, Genie.Renderer.Json
using CSV, LibPQ, DataFrames, IterTools, Tables, Dates
using Jetelina.JFiles, Jetelina.JLog, Jetelina.InitApiSqlListManager.ApiSqlListManager, Jetelina.JMessage, Jetelina.JSession
import Jetelina.InitConfigManager.ConfigManager as j_config

JMessage.showModuleInCompiling(@__MODULE__)

include("PgDataTypeList.jl")
include("PgSQLSentenceManager.jl")
include("PgIVMController.jl")

export create_jetelina_database

"""
function create_jetelina_database()

	create 'jetelina' database.
    BUT, look like LibPQ does not support this substitution string so far, therefore abandon to create 'jetelinadb' now and 
    keep working in default 'pg_dbname'.
    will be real someday, hopefully  ・ω・

    # Arguments
- `s:String`: 'json' -> required JSON form to return
			'dataframe' -> required DataFrames form to return
- return: table list in json or DataFrame
	
"""
end