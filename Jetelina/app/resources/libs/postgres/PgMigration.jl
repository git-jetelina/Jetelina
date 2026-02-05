"""
module: PgMigration

Author: Ono keiji

Description:
	Migrate existing tables to Jetelina tables for PostgreSQL

functions
    function getTableList(conn) collect the existing table's column data type
    function collect_columns_data_type(String::tablename) collect the existing table's column data type

"""
module PgMigration

#using Genie, Genie.Renderer, Genie.Renderer.Json
using CSV, LibPQ, DataFrames, IterTools, Tables, Dates
using Jetelina.JFiles, Jetelina.JLog, Jetelina.InitApiSqlListManager.ApiSqlListManager, Jetelina.JMessage, Jetelina.JSession
import Jetelina.InitConfigManager.ConfigManager as j_config

JMessage.showModuleInCompiling(@__MODULE__)

export getTableList, collect_columns_data_type

"""
function getTableList(conn)

	collect the existing table's column data type

    # Arguments
- `conn::LibPQ.Connection`: postgresql connection 
- return: table list in json or DataFrame	
"""
function getTableList(conn)
    df = DataFrame()
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
function collect_columns_data_type()
end

"""
function createDummyTable(conn)

    create a dummy table for testing
"""
function createDummyTable(conn)
    result::Bool = true
    tablename::String = "mig_dum"
    column_str::String = """
        small smallint,
        intg integer,
        big bigint,
        decim decimal,
        num numeric,
        rea real,
        mone money,
        name varchar,
        day date,
        timezone time,
        jsonstr json,
        jsonbstr jsonb,
        xmlstr xml,
        booleanstr boolean
    """
    createStr::String = """
    	create table if not exists $tablename(
    		$column_str   
    	);
    """

    try
        LibPQ.execute(conn, createStr)
    catch err
        @info "PgMigration.createDummyTable() error:: $err"
        result = false
    finally
    end

    if result
        @info "success to create $tablename"
    end

    return result
end
"""
function dropDummyTable(conn)

    drop the dummy table
"""
function dropDummyTable(conn)
    result::Bool = true
    tablename::String = "mig_dum"
    dropStr::String = """
        drop table if exists $tablename;
    """

    try
        LibPQ.execute(conn, dropStr)
    catch err
        @info "PgMigration.dropDummyTable() error:: $err"
        result = false
    finally
    end

    if result
        @info "success to delete $tablename"
    end

    return result
end

end