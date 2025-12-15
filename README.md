'Jetelina' is server-side middleware which is for managing your database and its Data Base Interface(DBI). Jetelina is an opensource program which is provided under MIT license. You can use Jetelina free and eidt it as far as keeping the license.

Jetelina can manage PostgreSQL, MySQL, redis and MongoDB so far, and you can use them at once. I mean, for example, PostgreSQL and redis run parallel on your server by managing Jetelina. All tables of each of databases are shown on Jeteina’s screen and can create DBI by selecting thier columns, i mean, you can create a SQL sentence ‘select name, address from yourtable’ sentence by selecting ‘name’ and ‘address’ columns from ‘yourtable’ table on Jetelina. This SQL sentence is to be able to accesse through JSON form. The insert/update/delete sentences are created automatically by Jetelina when you upload a CSV file that is the origin to be a table.

System requirements

-Julia = v11.7 (confirmed in Jetelina v3.1)
v12.* has not been confirmed yet
 
-RDBMS is mandatry: PostgreSQL or MySQL

　for managing users of Jeteilna and something else
 
-pg_ivm for PostgreSQL = v1.13 (comfirmed in Jetelina v3.1)

-Other DBs are options: redis, MongoDB

　depend on your usecase
 
-Linux(confirmed Ubuntu24) & Mac were comfirmed in Jetelina v3.1, Windows( should work, but not be comfirmed yet)

　no matter what os, as far as Julia works fine
