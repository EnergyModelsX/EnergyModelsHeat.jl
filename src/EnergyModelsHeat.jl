"""
Main module for `EnergyModelsHeat`: a framework for energy system models with thermal components.

It exports the resource ResourceHeat and structures for DH pipe, heat pump and heat exchanger.

You can find the exported types and functions below or on the pages \
*[Constraint functions](@ref man-con)* and \
*[Data functions](@ref man-data_fun)*.
"""
module EnergyModelsHeat

using EnergyModelsBase
using JuMP
using TimeStruct

const EMB = EnergyModelsBase
const EMH = EnergyModelsHeat

# Different introduced types
include(joinpath("structures", "resource.jl"))
include(joinpath("structures", "node.jl"))
include(joinpath("structures", "link.jl"))

include("model.jl")
include("constraint_functions.jl")




# Export the general classes
export ResourceHeat

# Export the different node types
export DHPipe
export HeatPump
export PinchData
export HeatExchanger

end
