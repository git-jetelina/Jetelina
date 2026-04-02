"""
module: MyMigration

Author: Ono keiji

Description:
	Migrate existing tables to Jetelina tables for MySQL

functions
    getTableList(conn) collect the existing table's column data type
    collect_columns_data(conn, tablename::String, type::Integer) collect the existing table's column data type
    execute_migration(conn, tablearray::Vector)	migration execution
    revert_migration(conn, tableName::String) revert the migrated table to the origin
"""
module MyMigration

#using Genie, Genie.Renderer, Genie.Renderer.Json
using CSV, MySQL, DataFrames, IterTools, Tables, Dates
using Jetelina.JFiles, Jetelina.JLog, Jetelina.InitApiSqlListManager.ApiSqlListManager, Jetelina.JMessage, Jetelina.JSession
import Jetelina.InitConfigManager.ConfigManager as j_config

JMessage.showModuleInCompiling(@__MODULE__)

export getTableList, collect_columns_data, execute_migration, revert_migration

"""
function getTableList(conn)

	collect the existing table's column data type

    # Arguments
- `conn::MySQL.Connection`: MySQL connection 
- return: table list in json or DataFrame	
"""
function getTableList(conn)
    #===
        checking "jetelina_delete_flg" exsists in the table
            is     -> false
            is not -> true
    ===#
    function _chkJetelina(tablename::String)
        isjdf::Bool = true
        targetcolumnaname::String = "jetelina_delete_flg"
        selectStr = """
            select * from $tablename
        """

        dff = DataFrame(columntable(DBInterface.execute(conn, selectStr)))
        if 0<=size(dff)[1]            
            if targetcolumnaname ∉ names(dff)
                isjdf = false
            end
        end

        return isjdf
    end

    df = DataFrame()
    # Fixing as 'public' in schemaname. This is the protocol.
    table_str = """select table_name from information_schema.tables where table_schema='jetelina';"""
    try
        df = DataFrame(columntable(DBInterface.execute(conn, table_str)))
        # do not include usertable and ivm table in the return
        DataFrames.filter!(row -> row.TABLE_NAME != "jetelina_user_table", df)
        #===
            Tips:
                select tables that does not have 'jetelina_delete_flg' in it among df
        ===#
        if 1 < size(df)[1]
            tnarry = []
            for i in 1:size(df, 1)
                tn = string(df[!,:TABLE_NAME][i])
                if !_chkJetelina(tn)
                    #===
                        tn is for migrating table because it has not "jetelina_delete_flg" column in there yet
                    ===#
                    push!(tnarry,tn)
                end
            end
            
            df = copy(DataFrame(tablename = tnarry))
        end
    catch err
        JLog.writetoLogfile("MyMigration.getTableList() error: $err")
        return DataFrame() # return empty DataFrame if got fail
    finally
    end

    return df
end

"""
function execute_migration(conn, tablearray::Vector)

	migration execution

# Arguments
- `conn::MySQL.Connection`: MySQL connection 
- `tablearray:Array`: target table name list
- return: success -> true, fail -> false	
"""
function execute_migration(conn, tablearray::Vector)
    delflg::String = "jetelina_delete_flg"
    ret::Bool = true

    try
        for i in 1:length(tablearray)
            tn::String = string(tablearray[i])
            jtid::String = string(tn,"_jt_id")
            addjtid::String = """alter table $tn add column $jtid serial primary key"""
            adddelflg::String = """alter table $tn add column $delflg integer"""
            setdelflg::String = """alter table $tn alter column $delflg set default 0"""
            updelflg::String = """update $tn set $delflg = 0"""
            #===
                Tips:
                    unfortunately, .execute() can handle single sql sentence at once, so far. 
                    2026/3/23
            ===#
            DBInterface.execute(conn, addjtid)
            DBInterface.execute(conn, adddelflg)
            DBInterface.execute(conn, setdelflg)
            DBInterface.execute(conn, updelflg)
        end
    catch err
        ret = false
        JLog.writetoLogfile("MyMigration.execute_migration() error: $err")
    finally
    end

    return ret
end

"""
function collect_columns_data(conn, tablename::String, type::Integer)

	collect the existing table's column data name/type

# Arguments
- `conn::MySQL.Connection`: MySQL connection 
- `tablename::String`: existing table name
- `type::Integer`: 1->return data in DataFrames
                   2->return data is only column names in array
                   3->return data is only column data type in array 
- return: Tuple(ture/false, columns data due to 'type')	
            e.g. type = 1 in case DataFrames
                    Row |  name   |  type    |
                        | String  | DataType |
                    --------------------------
                       1| jt_id   | Integer  |
                       2| address | String   |
                       .|     .   |    .     |
                       .|     .   |    .     |
"""
function collect_columns_data(conn, tablename::String, type::Integer)
    result::Bool = true
    ret = ""

    #===
        Tips:
            at least one line data is required to get column info in a table
    ===#
    selectStr::String = """
        select * from $tablename limit 1;
    """

    try
        dd = DBInterface.execute(conn, selectStr)
        df = DataFrame(columntable(dd))
        #===
            Tips:
                you may aware, this func could return each 'name' and 'type' as array data,
                but i prefer to use DataFrames to return them at once.
                if it will be conveniented to use array data for an upper function.
        ===#
        columns = names(df)
        column_type = string.(nonmissingtype.(eltype.(eachcol(df))))
        comb = Any[columns,column_type]
        ddf = DataFrame(comb, [:name,:type])

        if(type == 1)
            ret = ddf
        elseif(type == 2)
            ret = columns
        elseif(type == 3)
            ret = column_type
        end
    catch err
        @info "MyMigration.collect_columns_data() error:: $err"
        result = false
    finally
    end

    return result, ret
end
"""
function revert_migration(conn, tableName::String)

	revert the migrated table to the origin

# Arguments
- `conn::MySQL.Connection`: MySQL connection 
- `tablename:String`: target table name
- return: success -> true, fail -> false	
"""
function revert_migration(conn, tableName::String)
    delflg::String = "jetelina_delete_flg"
    jtid::String = string(tableName,"_jt_id")
    ret::Bool = true

    deljtid::String = """alter table $tableName drop column $jtid"""
    deldelflg::String = """alter table $tableName drop column $delflg"""

    try
        #===
            Tips:
                unfortunately, .execute() can handle single sql sentence at once, so far. 
        ===#
        DBInterface.execute(conn, deljtid)
        DBInterface.execute(conn, deldelflg)
    catch err
        ret = false
        JLog.writetoLogfile("MyMigration.revert_migration() error: $err")
    finally
    end

    return ret
end


#=======
    manipuration functions for dummy table for test&check
========#
"""
function createDummyTable(conn, type::String)

    create a dummy table for testing
"""
function createDummyTable(conn, type::String)
    result::Bool = true
    tablename::String = "mig_dum"
    column_str::String = ""

    if type == "simple"
        column_str = """
            small smallint,
            name varchar(256)
        """
    else
        column_str = """
            small smallint,
            intg integer,
            big bigint,
            decim decimal,
            num float,
            rea double,
            name varchar(256),
            day date,
            timezone time,
            jsonstr json,
            booleanstr boolean
        """
    end

    createStr::String = """
    	create table if not exists $tablename(
    		$column_str   
    	);
    """

    try
        DBInterface.execute(conn, createStr)
    catch err
        @info "MyMigration.createDummyTable() error:: $err"
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
        DBInterface.execute(conn, dropStr)
    catch err
        @info "MyMigration.dropDummyTable() error:: $err"
        result = false
    finally
    end

    if result
        @info "success to delete $tablename"
    end

    return result
end

function dumdatainsert(conn, type::String)
    result::Bool = true
    tablename::String = "mig_dum"
    column_str::String = ""
    value_str::String = ""

    if type == "simple"
        column_str = """
            small,name
        """
        value_str = """
            1,'Greg'
        """
    else
        column_str = """
            small,intg,big,decim,num,rea,name,day,timezone,jsonstr,booleanstr
        """
        value_str = """
            1,20,100,0.11,1.1,1.001,'keiji','1962-05-25',now(),'{"json":"json data"}',true
        """
    end

    insertStr::String = """
    	insert into $tablename ( $column_str
            ) 
            values(
                $value_str
    	    );
    """

    try
        DBInterface.execute(conn, insertStr)
    catch err
        @info "MyMigration.dumdatainsert() error:: $err"
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
        df = DataFrame(columntable(DBInterface.execute(conn, selectStr)))
        @info string(colname," -> ", df)
    catch err
        @info "MyMigration.selectDummyTable() error:: $err"
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
        dd = DBInterface.execute(conn, selectStr)
#        df = DataFrame(columntable(DBInterface.execute(conn, selectStr)))
        df = DataFrame(columntable(dd))
        columns = names(df)
        @info column_type = nonmissingtype.(eltype.(eachcol(df)))
        @info LibPQ.column_types(dd)
    catch err
        @info "MyMigration.columntypeofDummyTable() error:: $err"
        result = false
    finally
    end

    if result
        @info "success to columntypeofDummyTable $tablename"
    end

    return result
end
end