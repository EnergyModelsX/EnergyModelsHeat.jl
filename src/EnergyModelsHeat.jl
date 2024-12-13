"""
Main module for `EnergyModelsHeat`:
a framework for energy system models with thermal components.

It exports the resource `ResourceHeat` and structures for DH pipe, heat pump and heat exchanger.
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
include("utils.jl")

# Custom input validation
include("checks.jl")

# Export the general classes
export ResourceHeat

# Export the different node types
export DHPipe
export HeatPump
export PinchData
export HeatExchanger
export ThermalEnergyStorage

end
