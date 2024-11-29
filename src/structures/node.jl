""" 
    HeatPump

A `HeatPump` node to convert low temp heat to high(er) temp heat by utilizing en exergy driving force (e.g. electricity).

# Fields
- **`id`** is the name/identifier of the node.\n
- **`cap::TimeProfile`** is the installed heating capacity.\n
- **`cap_lower_bound`** is the lower capacity bound for flexibility, value between 0 and 1 reflecting the lowest possible relative capacity 
- **`t_source`** is the temperature profile of the heat source
- **`t_sink`** is the sink temperature of the condensator in Celsius
- **`eff_carnot`** is the Carnot Efficiency COP_real/COP_carnot
- **`input_heat`** is the resource for the low temperature heat
- **`driving_force`** is the resource of the driving force, e.g. electricity
- **`opex_var::TimeProfile`** is the variable operating expense per energy unit produced.\n
- **`opex_fixed::TimeProfile`** is the fixed operating expense.\n
- **`input::Dict{<:Resource, <:Real}`** are the input `Resource`s.\n
- **`output::Dict{<:Resource, <:Real}`** is the generated `Resource`.\n
- **`data::Vector{Data}`** is the additional data (e.g. for investments). The field \
`data` is conditional through usage of a constructor.
"""
struct HeatPump <: EMB.NetworkNode
    id::Any
    cap::TimeProfile                        # Heat Capacity
    cap_lower_bound::Union{Real,Nothing}    # Lower capacity bound for flexibility, value between 0 and 1 reflecting the lowest possible relative capacity 
    t_source::TimeProfile                   # Temperature profile of the heat source
    t_sink::TimeProfile                     # Sink temperature of the condensator in Celsius
    eff_carnot::TimeProfile                 # Carnot Efficiency COP_real/COP_carnot
    input_heat::Resource                     # Resource for the low temperature heat
    driving_force::Resource                  # Resource of the driving force, e.g. electricity
    opex_var::TimeProfile                   # Variable OPEX in EUR/MWh
    opex_fixed::TimeProfile                 # Fixed OPEX in EUR/h
    input::Dict{<:Resource,<:Real}          # Input Resource, number irrelevant: COP is calculated seperately
    output::Dict{<:Resource,<:Real}         # Output Resource (Heat), number irrelevant: COP is calculated seperately
    data::Vector{Data}                      # Optional Investment/Emission Data
end

function HeatPump(
    id::Any,
    cap::TimeProfile,
    cap_lower_bound::Union{Real,Nothing},
    t_source::TimeProfile,
    t_sink::TimeProfile,
    eff_carnot::TimeProfile,
    input_heat::Resource,
    driving_force::Resource,
    opex_var::TimeProfile,
    opex_fixed::TimeProfile,
    input::Dict{<:Resource,<:Real},
    output::Dict{<:Resource,<:Real},
)
    return HeatPump(
        id,
        cap,
        cap_lower_bound,
        t_source,
        t_sink,
        eff_carnot,
        input_heat,
        driving_force,
        opex_var,
        opex_fixed,
        input,
        output,
        Data[],
    )
end

"""
    eff_carnot(n::HeatPump, t)

Returns the Carnot efficiency of heat pump `n`.
"""
eff_carnot(n::HeatPump, t) = n.eff_carnot[t]

"""
    t_sink(n::HeatPump, t)

Returns the temperature of the heat sink for heat pump `n`.
"""
t_sink(n::HeatPump, t) = n.t_sink[t]

"""
    t_source(n::HeatPump, t) 

Returns the temperature of the heat source for heat pump `n`.
"""
t_source(n::HeatPump, t) = n.t_source[t]

"""
    cap_lower_bound(n::HeatPump)

Returns the lower capacity bound for heat pump `n`.
"""
cap_lower_bound(n::HeatPump) = n.cap_lower_bound[1]

"""
    heat_input_resource(n::HeatPump)

Returns the resource for heat input for heat pump `n`.
"""
heat_input_resource(n::HeatPump) = n.input_heat

"""
    drivingforce_resource(n::HeatPump)

Returns the resource for driving force, i.e., electricity, for heat pump `n`.
"""
drivingforce_resource(n::HeatPump) = n.driving_force

abstract type HeatExchangerAssumptions end
struct EqualMassFlows <: HeatExchangerAssumptions end
struct DifferentMassFlows <: HeatExchangerAssumptions end

abstract type AbstractHeatExchanger <: EnergyModelsBase.NetworkNode end
""" 
    HeatExchanger

A `HeatExchanger` node to convert "raw" surplus energy from other processes to "available"
energy that can be used in the District Heating network.

# Fields
- **`id`** is the name/identifier of the node.\n
- **`cap::TimeProfile`** is the installed capacity.\n
- **`opex_var::TimeProfile`** is the variable operating expense per energy unit produced.\n
- **`opex_fixed::TimeProfile`** is the fixed operating expense.\n
- **`input::Dict{<:Resource, <:Real}`** are the input `Resource`s with conversion value `Real`.\n
- **`output::Dict{<:Resource, <:Real}`** are the generated `Resource`s with conversion value `Real`.\n
- **`data::Vector{Data}`** is the additional data (e.g. for investments). The field \
`data` is conditional through usage of a constructor.
"""
struct HeatExchanger{A<:HeatExchangerAssumptions} <: AbstractHeatExchanger
    id::Any
    cap::TimeProfile
    opex_var::TimeProfile
    opex_fixed::TimeProfile
    input::Dict{<:Resource,<:Real}
    output::Dict{<:Resource,<:Real}
    data::Vector{Data}
end
# Default to different mass flows assumptions for heat exchanger
HeatExchanger(id, cap, opex_var, opex_fixed, input, output, data) =
    HeatExchanger{DifferentMassFlows}(id, cap, opex_var, opex_fixed, input, output, data)
"""
    PinchData{T}

Data for fixed temperature intervals used to calculate available energy from surplus energy source 
operating at `T_SH_hot` and `T_SH_cold`, with `ΔT_min` between surplus source and the district heating
network operating at `T_DH_hot` and `T_DH_cold`.
"""
struct PinchData{TP<:TimeProfile} <: EnergyModelsBase.Data
    T_SH_hot::TP
    T_SH_cold::TP
    ΔT_min::TP
    T_DH_hot::TP
    T_DH_cold::TP
end

""" 
    ThermalEnergyStorage

A `ThermalEnergyStorage` that functions mostly like a RefStorage with the additional option to include thermal energy losses. 
Heat losses are quantified through a heat loss factor that describes the amount of thermal energy that is lost in relation to the storage level from the previous timeperiod.
The main difference to RefStorage is that these heat losses occur independently of the storage use, i.e. unless the storage level is zero. 

# Fields
- **`id`** is the name/identifier of the node.
- **`charge::AbstractStorageParameters`** are the charging parameters of the [`Storage`](@ref) node.
  Depending on the chosen type, the charge parameters can include variable OPEX, fixed OPEX,
  and/or a capacity.
- **`level::AbstractStorageParameters`** are the level parameters of the [`Storage`](@ref) node.
  Depending on the chosen type, the charge parameters can include variable OPEX and/or fixed OPEX.
- **`stor_res::Resource`** is the stored [`Resource`](@ref).
- **`heatlossfactor::Float64`** are the relative heat losses in percent. 
- **`input::Dict{<:Resource,<:Real}`** are the input [`Resource`](@ref)s with conversion
  value `Real`.
- **`output::Dict{<:Resource,<:Real}`** are the generated [`Resource`](@ref)s with conversion
  value `Real`. Only relevant for linking and the stored [`Resource`](@ref) as the output
  value is not utilized in the calculations.
- **`data::Vector{<:Data}`** is the additional data (*e.g.*, for investments). The field `data`
  is conditional through usage of a constructor.
"""
struct ThermalEnergyStorage{T} <: Storage{T}
    id::Any
    charge::EMB.AbstractStorageParameters
    level::EMB.UnionCapacity
    stor_res::Resource
    heatlossfactor::Float64
    input::Dict{<:Resource,<:Real}
    output::Dict{<:Resource,<:Real}
    data::Vector{<:Data}
end

function ThermalEnergyStorage{T}(
    id,
    charge::EMB.AbstractStorageParameters,
    level::EMB.UnionCapacity,
    stor_res::Resource,
    heatlossfactor::Float64,
    input::Dict{<:Resource,<:Real},
    output::Dict{<:Resource,<:Real},
) where {T<:EMB.StorageBehavior}
    return ThermalEnergyStorage{T}(
        id,
        charge,
        level,
        stor_res,
        heatlossfactor,
        input,
        output,
        Data[],
    )
end

"""
    heatlossfactor(n::ThermalEnergyStorage)

Returns the heat loss factor for storage `n`.
"""
heatlossfactor(n::ThermalEnergyStorage) = n.heatlossfactor

""" 
    DirectHeatUpgrade

A `DirectHeatUpgrade` node to upgrade "raw" surplus energy from other processes to "available"
energy that can be used in the District Heating network.

# Fields
- **`id`** is the name/identifier of the node.
- **`cap::TimeProfile`** is the installed capacity.
- **`opex_var::TimeProfile`** is the variable operating expense per energy unit produced.
- **`opex_fixed::TimeProfile`** is the fixed operating expense.
- **`input::Dict{<:Resource, <:Real}`** are the input `Resource`s with conversion value `Real`. \
Valid inputs are: one `Heat` resource and one power resource.
- **`output::Dict{<:Resource, <:Real}`** are the generated `Resource`s with conversion value `Real`. \
Valid output is a single `Heat` resource
- **`data::Vector{Data}`** is the additional data. The pinch data must be included here.
"""
struct DirectHeatUpgrade{A<:HeatExchangerAssumptions} <: AbstractHeatExchanger
    id::Any
    cap::TimeProfile
    opex_var::TimeProfile
    opex_fixed::TimeProfile
    input::Dict{<:Resource,<:Real}
    output::Dict{<:Resource,<:Real}
    data::Vector{Data}
end
# Default to different mass flows assumptions for heat exchange
DirectHeatUpgrade(id, cap, opex_var, opex_fixed, input, output, data) =
    DirectHeatUpgrade{DifferentMassFlows}(
        id,
        cap,
        opex_var,
        opex_fixed,
        input,
        output,
        data,
    )
