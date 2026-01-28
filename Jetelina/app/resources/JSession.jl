"""
module: JSession

Author: Ono keiji

Description:
	manage user session data

functions
    set(un,id) set ordered session data
	get()  get session data
	clear()  clear session data
	setDBType(d) set using data base type: postgresql/mysql/redis....
	getDBType()	get current data base type is using by a login user
"""
module JSession
using Genie, GenieSession, GenieSessionFileSession
export set, get, clear
"""
function __init__()

	this is the session initialize
"""
function __init__()
	@info "==========JSession init================"
	GenieSession.__init__()
end
"""
function set(un,id)

    set ordered session data

# Arguments
-un:String  login user name
-id:Int login user id
"""
function set(un,id)
	s = session(params())
	GenieSession.set!(s, :uname, un)
	GenieSession.set!(s, :uid, id)
end
"""
function get()

    get session data

# Arguments
-return: Tuple: (uname::String,uid::Int)
"""
function get()
	s = session(params())
	if !isnothing(s)
		return s.data[:uname], s.data[:uid]
	else
		return nothing
	end 
end
"""
function clear()

    clear session data
"""
function clear()
	s = session(params())
	s.data = Dict()
end
"""
function setDBType(d::String)

	set using data base type: postgresql/mysql/redis....
	this session is set with configuration paramete 'dbtype', but will switch order by user managing

# Arguments
-d:String: data base type postgresql/mysql/redis....
"""
function setDBType(d)
	d = replace(d,"\""=>"")
	s = session(params())
	GenieSession.set!(s, :dbtype, d)
end
"""
function getDBType()

	get current data base type is using by a login user

# Arguments
-return: String: data base type: postgresq/mysql/redis... 
"""
function getDBType()
	s = session(params())
	return s.data[:dbtype]
end

end
