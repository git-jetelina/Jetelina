"""
module: JTimer

Author: Ono keiji

Description:
        This module is a tricky program.
        Because Genie does not exectute __init__() as far as not execute include().
        We wanna kick __init__() to start some timer programs.
        The 'TimerExecuter.jl' is for that, thus this JTimer only does include it.
"""
module JTimer

using Jetelina.JMessage

JMessage.showModuleInCompiling(@__MODULE__)

include("TimerExecuter.jl")
end
