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

function dumdatainsert(conn)
    result::Bool = true
    tablename::String = "mig_dum"

    column_str::String = """
        small,intg,big,decim,num,rea,mone,name,day,timezone,jsonstr,jsonbstr,xmlstr,booleanstr
    """
    value_str::String = """
        1,20,100,0.11,1.1,1.001,-1,'keiji','1962-05-25',now(),'{"json":"json data"}','{"jsonb":"json b data"}','<xml>XML Data</xml>',true
    """
    insertStr::String = """
    	insert into $tablename ( $column_str
            ) 
            values(
                $value_str
    	    );
    """

    try
        LibPQ.execute(conn, insertStr)
    catch err
        @info "PgMigration.dumdatainsert() error:: $err"
        result = false
    finally
    end

    if result
        @info "success to dumdatainsert $tablename"
    end

    return result
end

function selectDummyTable(conn,colname::String)
    result::Bool = true
    tablename::String = "mig_dum"
    selectStr::String = """
        select $colname from $tablename;
    """

    try
        df = DataFrame(columntable(LibPQ.execute(conn, selectStr)))
        @info string(colname," -> ", df)
    catch err
        @info "PgMigration.selectDummyTable() error:: $err"
        result = false
    finally
    end

    if result
        @info "success to selectDummyTable $colname"
    end

    return result
end

function columntypeofDummyTable(conn)
    result::Bool = true
    tablename::String = "jetelina_user_table" #"mig_dum"
    selectStr::String = """
        select * from $tablename;
    """

    try
        dd = LibPQ.execute(conn, selectStr)
#        df = DataFrame(columntable(LibPQ.execute(conn, selectStr)))
        df = DataFrame(columntable(dd))
        columns = names(df)
        @info column_type = nonmissingtype.(eltype.(eachcol(df)))
        @info LibPQ.column_types(dd)
    catch err
        @info "PgMigration.columntypeofDummyTable() error:: $err"
        result = false
    finally
    end

    if result
        @info "success to columntypeofDummyTable $tablename"
    end

    return result
end
end