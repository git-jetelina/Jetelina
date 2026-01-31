module InitConfigManager
using Jetelina.JMessage

JMessage.showModuleInCompiling(@__MODULE__)

include("ConfigManager.jl")
end