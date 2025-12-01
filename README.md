Jetelina’ is server-side middleware which is for managing your databases and their DBI. Jetelina is an opensource program which is provided under MIT license. You can use it free and eidt it as far as keeping the license.

Jetelina can manage PostgreSQL, MySQL, Redis and MongoDB so far, and you can use them at once on it. I mean, for example, PostgreSQL and Redis run parallel on your server by managing jetelina. All tables of each of databases are shown on jeteina’s screen and can create dbi by selecting thier columns, i mean, you can create a sql sentence ‘select name, address from yourtable’ sentence by selecting ‘name’ and ‘address’ columns from ‘yourtable’ table on jetelina. This sql sentence is to be able to accesse through json form. The insert/update/delete sentences are created automatically by jetelina when you upload a csv file that is the origin to be a table.

System requirements
Julia >= 10.0
RDBMS is mandatry: PostgreSQL or MySQL
for managing users of jeteilna and something else
Other DBs are options: Redis, MongoDB
depend on your usecase
Linux(confirmed Ubuntu24), Win
no matter what os, as far as Julia works fine
