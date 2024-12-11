"""
    HeatPump <: EMB.NetworkNode

A `HeatPump` node to convert low temperature heat to high(er) temperature heat by utilizing
an exergy driving force (*e.g.*, electricity).

# Fields
- **`id`** is the name/identifier of the node.
- **`cap::TimeProfile`** is the installed heating capacity.
- **`cap_lower_bound`** is the lower capacity bound for flexibility within [0, 1] reflecting
  the lowest possible relative capacity use.
- **`t_source`** is the temperature profile of the heat source
- **`t_sink`** is the sink temperature of the condensator. The temperature must be given in
  °C.
- **`eff_carnot`** is the Carnot Efficiency COP_real/COP_carnot.
  The value must be within [0, 1].
- **`input_heat`** is the resource for the low temperature heat input.
- **`driving_force`** is the resource of the driving force, *e.g.*, electricity.
- **`opex_var::TimeProfile`** is the variable operating expense per energy unit produced.
- **`opex_fixed::TimeProfile`** is the fixed operating expense.
- **`output::Dict{<:Resource, <:Real}`** are the produced
  [`Resource`](@extref EnergyModelsBase.Resource)s with conversion value `Real`.
- **`data::Vector{<:Data}`** is the additional data (*e.g.*, for investments). The field
  `data` is conditional through usage of a constructor.
"""
struct HeatPump <: EMB.NetworkNode
    id::Any
    cap::TimeProfile
    cap_lower_bound::Union{Real,Nothing}
    t_source::TimeProfile
    t_sink::TimeProfile
    eff_carnot::TimeProfile
    input_heat::Resource
    driving_force::Resource
    opex_var::TimeProfile
    opex_fixed::TimeProfile
    output::Dict{<:Resource,<:Real}
    data::Vector{Data}
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
        output,
        Data[],
    )
end

"""
    eff_carnot(n::HeatPump)
    eff_carnot(n::HeatPump, t)

Returns the Carnot efficiency of heat pump `n` as `TimeProfile` or in operational period `t`.
"""
eff_carnot(n::HeatPump) = n.eff_carnot
eff_carnot(n::HeatPump, t) = n.eff_carnot[t]

"""
    t_sink(n::HeatPump)
    t_sink(n::HeatPump, t)

Returns the temperature of the heat sink for heat pump `n` as `TimeProfile` or in
operational period `t`.
"""
t_sink(n::HeatPump) = n.t_sink
t_sink(n::HeatPump, t) = n.t_sink[t]

"""
    t_source(n::HeatPump)
    t_source(n::HeatPump, t)

Returns the temperature of the heat source for heat pump `n` as `TimeProfile` or in
operational period `t`.
"""
t_source(n::HeatPump) = n.t_sources
t_source(n::HeatPump, t) = n.t_source[t]

"""
    cap_lower_bound(n::HeatPump)

Returns the lower capacity bound for heat pump `n`.
"""
cap_lower_bound(n::HeatPump) = n.cap_lower_bound[1]

"""
    heat_in_resource(n::HeatPump)

Returns the resource for heat input for heat pump `n`.
"""
heat_in_resource(n::HeatPump) = n.input_heat

"""
    driving_force_resource(n::HeatPump)

Returns the resource for driving force, i.e., electricity, for heat pump `n`.
"""
driving_force_resource(n::HeatPump) = n.driving_force

"""
    inputs(n::HeatPump)

Returns the input resources of a HeatPump `n`, specified *via* the fields `heat_in_resource`
and `driving_force_resource`.

If the resource `p` is specified, it returns a value of 1. This behaviour should in theory
not occur.
"""
EMB.inputs(n::HeatPump) = [heat_in_resource(n), driving_force_resource(n)]
EMB.inputs(n::HeatPump, p::Resource) = 1

abstract type HeatExchangerAssumptions end
struct EqualMassFlows <: HeatExchangerAssumptions end
struct DifferentMassFlows <: HeatExchangerAssumptions end

abstract type AbstractHeatExchanger <: EnergyModelsBase.NetworkNode end
"""
    HeatExchanger

A `HeatExchanger` node to convert "raw" surplus energy from other processes to "available"
energy that can be used in the District Heating network.

# Fields
- **`id`** is the name/identifier of the node.
- **`cap::TimeProfile`** is the installed capacity.
- **`opex_var::TimeProfile`** is the variable operating expense per energy unit produced.
- **`opex_fixed::TimeProfile`** is the fixed operating expense.
- **`input::Dict{<:Resource, <:Real}`** are the input `Resource`s with conversion value `Real`.
- **`output::Dict{<:Resource, <:Real}`** are the generated `Resource`s with conversion value `Real`.
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
    ThermalEnergyStorage{T} <: Storage{T}

A `ThermalEnergyStorage` that functions mostly like a [`RefStorage`](@extref EnergyModelsBase.RefStorage)
with the additional option to include thermal energy losses. Heat losses are quantified
through a heat loss factor that describes the amount of thermal energy that is lost in
relation to the storage level from the previous timeperiod.

The main difference to [`RefStorage`](@extref EnergyModelsBase.RefStorage) is that these heat
losses do not occur while charging or discharging, *i.e.*, they are proportional to the storage
level.

!!! warning "StorageBehavior"
    `ThermalEnergyStorage` in its current implementation only supports
    [`CyclicRepresentative`](@extref EnergyModelsBase.CyclicRepresentative) as storage behavior.
    This input is not a required input due to the utilization of an inner constructor.

# Fields
- **`id`** is the name/identifier of the node.
- **`charge::AbstractStorageParameters`** are the charging parameters of the
  `ThermalEnergyStorage` node. Depending on the chosen type, the charge parameters can
  include variable OPEX, fixed OPEX, and/or a capacity.
- **`level::AbstractStorageParameters`** are the level parameters of the `ThermalEnergyStorage`.
  Depending on the chosen type, the charge parameters can include variable OPEX and/or fixed OPEX.
- **`stor_res::Resource`** is the stored [`Resource`](@extref EnergyModelsBase.Resource).
- **`heat_loss_factor::Float64`** are the relative heat losses in percent.
- **`input::Dict{<:Resource,<:Real}`** are the input [`Resource`](@extref EnergyModelsBase.Resource)s
  with conversion value `Real`.
- **`output::Dict{<:Resource,<:Real}`** are the generated [`Resource`](@extref EnergyModelsBase.Resource)s
  with conversion value `Real`. Only relevant for linking and the stored
  [`Resource`](@extref EnergyModelsBase.Resource) as the output value is not utilized in
  the calculations.
- **`data::Vector{<:Data}`** is the additional data (*e.g.*, for investments). The field `data`
  is conditional through usage of a constructor.
"""
struct ThermalEnergyStorage{T} <: Storage{T}
    id::Any
    charge::EMB.AbstractStorageParameters
    level::EMB.UnionCapacity
    stor_res::Resource
    heat_loss_factor::Float64
    input::Dict{<:Resource,<:Real}
    output::Dict{<:Resource,<:Real}
    data::Vector{<:Data}
end

function ThermalEnergyStorage{T}(
    id,
    charge::EMB.AbstractStorageParameters,
    level::EMB.UnionCapacity,
    stor_res::Resource,
    heat_loss_factor::Float64,
    input::Dict{<:Resource,<:Real},
    output::Dict{<:Resource,<:Real},
) where {T<:EMB.StorageBehavior}
    return ThermalEnergyStorage{T}(
        id,
        charge,
        level,
        stor_res,
        heat_loss_factor,
        input,
        output,
        Data[],
    )
end

function ThermalEnergyStorage(
    id::Any,
    charge::EMB.AbstractStorageParameters,
    level::EMB.UnionCapacity,
    stor_res::Resource,
    heat_loss_factor::Float64,
    input::Dict{<:Resource,<:Real},
    output::Dict{<:Resource,<:Real},
    data::Vector{<:Data},
)
    new{CyclicRepresentative}(
        id,
        charge,
        level,
        stor_res,
        heat_loss_factor,
        input,
        output,
        data,
    )
end

"""
    heat_loss_factor(n::ThermalEnergyStorage)

Returns the heat loss factor for storage `n`.
"""
heat_loss_factor(n::ThermalEnergyStorage) = n.heat_loss_factor

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
