"""
module: MonDataTypeList

Author: Ono keiji

Description:
	determaine data type of Redis
	but not use this yet.

functions
	getDataType(c_type::String)   determaine 'c_type' to Redis data.
"""
module MonDataTypeList

using Jetelina.JMessage

JMessage.showModuleInCompiling(@__MODULE__)

export getDataType

"""
function getDataType(c_type::String)

	determaine 'c_type' to Redis data.

# Arguments
- `c_type::String`:  data type string. ex 'Int'
"""
function getDataType(c_type::String)
	ret::String = ""

#	c_type = string(c_type)
	if startswith(c_type, "Int")
		ret = "integer"
	elseif startswith(c_type, "Float")
		ret = "double precision"
	elseif startswith(c_type, "InlineStrings.String")
		#==
			Attention: no limit in a character length by the initial uploaded csv file 
		==#
		ret = "varchar"
	elseif startswith(c_type, "String")
		ret = "varchar"
	elseif startswith(c_type, "Dates")
		ret = "Date"
	end

	return ret
end

end
