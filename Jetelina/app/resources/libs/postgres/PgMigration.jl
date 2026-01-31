"""
module: PgDBController

Author: Ono keiji

Description:
	Migrate existing tables to Jetelina tables for PostgreSQL

functions
    function getTableList() collect the existing table's column data type
    function collect_columns_data_type(String::tablename) collect the existing table's column data type

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

export getTableList, collect_columns_data_type

"""
function getTableList()

	collect the existing table's column data type

    # Arguments
- return: table list in json or DataFrame	
"""
function getTableList()
    df = DataFrame()
    conn = PgDBController.open_connection()
    # Fixing as 'public' in schemaname. This is the protocol.
    table_str = """select tablename from pg_tables where schemaname='public'"""
    try
        df = DataFrame(columntable(LibPQ.execute(conn, table_str)))
        # do not include usertable and ivm table in the return
        DataFrames.filter!(row -> row.tablename != "jetelina_user_table" && row.tablename ∉ Df_JsJvList[!,:jv] , df)

        #===
            Tips:
                select tables that does not have 'jetelina_delete_flg' in it among df
        ===#
    catch err
        JLog.writetoLogfile("PgMigration.getTableList() error: $err")
        return DataFrame() # return empty DataFrame if got fail
    finally
        PgDBController.close_connection(conn)
    end

    return df
end

"""
function collect_columns_data_type(String::tablename)

	collect the existing table's column data type

    # Arguments
- `tablename:String`: existing table name
- return: columns data type list in json or DataFrame	
"""
function collect_columns_data_type(String::tablename)
end

"""
function createDummyTable()

    create a dummy table for testing
"""
function createDummyTable()
    result::Bool = true
    tablename::String = "mig_dum"
    column_str::String = """
        id integer,
        name varchar
    """
    createStr::String = """
    	create table if not exists $tablename(
    		$column_str   
    	);
    """

    conn = PgDBController.open_connection()

    try
        LibPQ.execute(conn, createStr)
    catch err
        @info "PgMigration.createDummyTable() error:: $err"
        result = false
    finally
        PgDBController.close_connection(conn)
    end

    if result
        @info "success to create $tablename"
    end


end
"""
function dropDummyTable()

    drop the dummy table
"""
function dropDummyTable()
    result::Bool = true
    tablename::String = "mig_dum"
    dropStr::String = """
        drop table if exists $tablename;
    """

    conn = PgDBController.open_connection()

    try
        LibPQ.execute(conn, dropStr)
    catch err
        @info "PgMigration.dropDummyTable() error:: $err"
        result = false
    finally
        PgDBController.close_connection(conn)
    end

    if result
        @info "success to delete $tablename"
    end

end

end