"""
module: JMessage

Author: Ono keiji

Description:
	show some messages order by something.

functions
	showModuleInCompiling(m::Module)  show the module info.
"""
module JMessage

export showModuleInCompiling

"""
function showModuleInCompiling(m::Module)

	show module info.

	i was confusing about the module hierarchy in Genie.
	because it did not work in order to the document.
	this module was for understanding what was the parent module of it.

# Arguments
- `m: Module`: target module.
"""
function showModuleInCompiling(m::Module)
#	@info """$m compiling...""" parentmodule(m)
end

# for myself :)
showModuleInCompiling(@__MODULE__)
end
