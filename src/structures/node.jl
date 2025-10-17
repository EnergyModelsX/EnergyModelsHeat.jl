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
- **`data::Vector{<:ExtensionData}`** is the additional data (*e.g.*, for investments). The
  field `data` is conditional through usage of a constructor.
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
    data::Vector{<:ExtensionData}
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
t_source(n::HeatPump) = n.t_source
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
    inputs(n::HeatPump, p::Resource)

Returns the input resources of a HeatPump `n`, specified *via* the fields `heat_in_resource`
and `driving_force_resource`.

If the resource `p` is specified, it returns a value of 1. This behaviour should in theory
not occur.
"""
EMB.inputs(n::HeatPump) = [heat_in_resource(n), driving_force_resource(n)]
EMB.inputs(n::HeatPump, p::Resource) = 1

"""
    HeatExchangerAssumptions

A supertype for assumptions for a heat exchanger, such that different efficiencies can be
calculated based on the underlying assumptions.
"""
abstract type HeatExchangerAssumptions end
"""
    EqualMassFlows <: HeatExchangerAssumptions

Assume mass flows are equal in both circuits and using the same medium.
"""
struct EqualMassFlows <: HeatExchangerAssumptions end
"""
    DifferentMassFlows <: HeatExchangerAssumptions

Assume mass flows can be adjusted to optimise heat transfer.
Assume the same medium in both circuits.
"""
struct DifferentMassFlows <: HeatExchangerAssumptions end

"""
    AbstractHeatExchanger <: EnergyModelsBase.NetworkNode

A supertype for heat exchangers.
"""
abstract type AbstractHeatExchanger <: EnergyModelsBase.NetworkNode end
"""
    HeatExchanger

A `HeatExchanger` node to convert "raw" surplus energy from other processes to "available"
energy that can be used in the District Heating network.

The default heat exchanger assumes that mass flows can be different to optimize heat transfer. This
is encoded by the type parameter `HeatExchangerAssumptions`. The default value is `DifferentMassFlows`,
the alternative is to specify `EqualMassFlows` to limit heat exchange to equal mass flow in the two circuits.

# Fields
- **`id`** is the name/identifier of the node.
- **`cap::TimeProfile`** is the installed capacity.
- **`opex_var::TimeProfile`** is the variable operating expense per energy unit produced.
- **`opex_fixed::TimeProfile`** is the fixed operating expense.
- **`input::Dict{<:Resource, <:Real}`** are the input `Resource`s with conversion value `Real`.
- **`output::Dict{<:Resource, <:Real}`** are the generated `Resource`s with conversion value `Real`.
- **`data::Vector{<:ExtensionData}`** is the additional data (e.g. for investments). The
  field `data` is conditional through usage of a constructor.
- **`delta_t_min`** is the ΔT_min for the heat exchanger
"""
struct HeatExchanger{A<:HeatExchangerAssumptions,T<:Real} <: AbstractHeatExchanger
    id::Any
    cap::TimeProfile
    opex_var::TimeProfile
    opex_fixed::TimeProfile
    input::Dict{<:Resource,<:Real}
    output::Dict{<:Resource,<:Real}
    data::Vector{<:ExtensionData}
    delta_t_min::T
end
# Default to different mass flows assumptions for heat exchanger
HeatExchanger(id, cap, opex_var, opex_fixed, input, output, data, delta_t_min) =
    HeatExchanger{DifferentMassFlows,typeof(delta_t_min)}(
        id,
        cap,
        opex_var,
        opex_fixed,
        input,
        output,
        data,
        delta_t_min,
    )
"""
    PinchData{T}

Data for fixed temperature intervals used to calculate available energy from surplus energy
source operating at `T_SH_hot` and `T_SH_cold`, with `ΔT_min` between surplus source and the
district heating network operating at `T_DH_hot` and `T_DH_cold`.

This struct is used internally, and it is calculated from the supply and return temperatures
of the `ResourceHeat` going in and out of the `AbstractHeatExchanger`.
"""
struct PinchData{
    TP1<:TimeProfile,
    TP2<:TimeProfile,
    TP3<:TimeProfile,
    TP4<:TimeProfile,
    TP5<:TimeProfile,
} <: EnergyModelsBase.Data
    T_SH_hot::TP1
    T_SH_cold::TP2
    ΔT_min::TP3
    T_DH_hot::TP4
    T_DH_cold::TP5
end

"""
    AbstractThermalEnergyStor <: Storage{T}

Abstract supertype for all thermal energy storage nodes.
"""
abstract type AbstractThermalEnergyStor{T} <: Storage{T} end

"""
    ThermalEnergyStorage{T} <: Storage{T}

A `ThermalEnergyStorage` that functions mostly like a [`RefStorage`](@extref EnergyModelsBase.RefStorage)
with the additional option to include a discharge rate and thermal energy losses. Heat losses
are quantified through a heat loss factor that describes the amount of thermal energy that is
lost in relation to the storage level from the previous timeperiod.

The main difference to [`RefStorage`](@extref EnergyModelsBase.RefStorage) is that these
heat losses do not occur while charging or discharging, *i.e.*, they are proportional to the
storage level.

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
- **`discharge::AbstractStorageParameters`** are the discharging parameters of the
  `ThermalEnergyStorage` node. Depending on the chosen type, the discharge parameters can
  include variable OPEX, fixed OPEX, and/or a capacity.
  - **`stor_res::Resource`** is the stored [`Resource`](@extref EnergyModelsBase.Resource).
- **`heat_loss_factor::Float64`** are the relative heat losses in percent.
- **`input::Dict{<:Resource,<:Real}`** are the input [`Resource`](@extref EnergyModelsBase.Resource)s
  with conversion value `Real`.
- **`output::Dict{<:Resource,<:Real}`** are the generated [`Resource`](@extref EnergyModelsBase.Resource)s
  with conversion value `Real`. Only relevant for linking and the stored
  [`Resource`](@extref EnergyModelsBase.Resource) as the output value is not utilized in
  the calculations.
- **`data::Vector{<:ExtensionData}`** is the additional data (*e.g.*, for investments). The
  field `data` is conditional through usage of a constructor.
"""
struct ThermalEnergyStorage{T} <: AbstractThermalEnergyStor{T}
    id::Any
    charge::EMB.AbstractStorageParameters
    level::EMB.UnionCapacity
    discharge::EMB.AbstractStorageParameters
    stor_res::Resource
    heat_loss_factor::Float64
    input::Dict{<:Resource,<:Real}
    output::Dict{<:Resource,<:Real}
    data::Vector{<:ExtensionData}
end

function ThermalEnergyStorage{T}(
    id,
    charge::EMB.AbstractStorageParameters,
    level::EMB.UnionCapacity,
    discharge::EMB.AbstractStorageParameters,
    stor_res::Resource,
    heat_loss_factor::Float64,
    input::Dict{<:Resource,<:Real},
    output::Dict{<:Resource,<:Real},
) where {T<:EMB.StorageBehavior}
    return ThermalEnergyStorage{T}(
        id,
        charge,
        level,
        discharge,
        stor_res,
        heat_loss_factor,
        input,
        output,
        ExtensionData[],
    )
end

function ThermalEnergyStorage(
    id::Any,
    charge::EMB.AbstractStorageParameters,
    level::EMB.UnionCapacity,
    discharge::EMB.AbstractStorageParameters,
    stor_res::Resource,
    heat_loss_factor::Float64,
    input::Dict{<:Resource,<:Real},
    output::Dict{<:Resource,<:Real},
    data::Vector{<:ExtensionData},
)
    new{CyclicRepresentative}(
        id,
        charge,
        level,
        discharge,
        stor_res,
        heat_loss_factor,
        input,
        output,
        data,
    )
end

"""
    Legacy constructors for TES without discharge parameters.
"""
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
        charge,
        stor_res,
        heat_loss_factor,
        input,
        output,
        ExtensionData[],
    )
end

function ThermalEnergyStorage{T}(
    id,
    charge::EMB.AbstractStorageParameters,
    level::EMB.UnionCapacity,
    stor_res::Resource,
    heat_loss_factor::Float64,
    input::Dict{<:Resource,<:Real},
    output::Dict{<:Resource,<:Real},
    data::Vector{<:ExtensionData},
) where {T<:EMB.StorageBehavior}
    return ThermalEnergyStorage{T}(
        id,
        charge,
        level,
        charge,
        stor_res,
        heat_loss_factor,
        input,
        output,
        data,
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
    data::Vector{<:ExtensionData},
)
    new{CyclicRepresentative}(
        id,
        charge,
        level,
        charge,
        stor_res,
        heat_loss_factor,
        input,
        output,
        data,
    )
end

"""
    FixedRateTES{T} <: AbstractThermalEnergyStor{T}

A `FixedRateTES` that has the option to include thermal energy losses. In contrast to
[`ThermalEnergyStorage`](@ref), the maximum charging and discharging rates are defined as a
ratio between the (dis-)charge rate and the installed storage capacity.

!!! warning "StorageBehavior"
    `FixedRateTES` in its current implementation only supports
    [`CyclicRepresentative`](@extref EnergyModelsBase.CyclicRepresentative) as storage behavior.
    This input is not a required input due to the utilization of an inner constructor.

# Fields
- **`id`** is the name/identifier of the node.
- **`level::AbstractStorageParameters`** are the level parameters of the `FixedRateTES`.
  Depending on the chosen type, the level parameters can include variable OPEX and/or fixed OPEX.
- **`stor_res::Resource`** is the stored [`Resource`](@extref EnergyModelsBase.Resource).
- **`heat_loss_factor::Float64`** are the relative heat losses in percent.
- **`level_discharge::Float64`** is the ratio of maximum discharge rate and installed storage level.
- **`level_charge::Float64`** is the ratio of maximum charge rate and installed storage level.
- **`input::Dict{<:Resource,<:Real}`** are the input [`Resource`](@extref EnergyModelsBase.Resource)s
  with conversion value `Real`.
- **`output::Dict{<:Resource,<:Real}`** are the generated [`Resource`](@extref EnergyModelsBase.Resource)s
  with conversion value `Real`. Only relevant for linking and the stored
  [`Resource`](@extref EnergyModelsBase.Resource) as the output value is not utilized in
  the calculations.
- **`data::Vector{<:Data}`** is the additional data (*e.g.*, for investments). The field `data`
  is conditional through usage of a constructor.
"""
struct FixedRateTES{T} <: AbstractThermalEnergyStor{T}
    id::Any
    level::EMB.UnionCapacity
    stor_res::Resource
    heat_loss_factor::Float64
    level_charge::Float64
    level_discharge::Float64
    input::Dict{<:Resource,<:Real}
    output::Dict{<:Resource,<:Real}
    data::Vector{<:Data}
end

function FixedRateTES{T}(
    id,
    level::EMB.UnionCapacity,
    stor_res::Resource,
    heat_loss_factor::Float64,
    level_charge::Float64,
    level_discharge::Float64,
    input::Dict{<:Resource,<:Real},
    output::Dict{<:Resource,<:Real},
) where {T<:EMB.StorageBehavior}
    return FixedRateTES{T}(
        id,
        level,
        stor_res,
        heat_loss_factor,
        level_charge,
        level_discharge,
        input,
        output,
        Data[],
    )
end

function FixedRateTES(
    id::Any,
    level::EMB.UnionCapacity,
    stor_res::Resource,
    heat_loss_factor::Float64,
    level_charge::Float64,
    level_discharge::Float64,
    input::Dict{<:Resource,<:Real},
    output::Dict{<:Resource,<:Real},
    data::Vector{<:Data},
)
    new{CyclicRepresentative}(
        id,
        level,
        stor_res,
        heat_loss_factor,
        level_charge,
        level_discharge,
        input,
        output,
        data,
    )
end

"""
    heat_loss_factor(n::ThermalEnergyStorage)

Returns the heat loss factor for storage `n`.
"""
heat_loss_factor(n::AbstractThermalEnergyStor) = n.heat_loss_factor

"""
    level_discharge(n::FixedRateTES)

Returns the ratio of discharge rate and storage level for storage `n`.
"""
level_discharge(n::FixedRateTES) = n.level_discharge

"""
    level_charge(n::FixedRateTES)

Returns the ratio of the maximum charge rate and storage level capacity for TES `n`.
"""
level_charge(n::FixedRateTES) = n.level_charge

"""
    DirectHeatUpgrade

A `DirectHeatUpgrade` node to upgrade "raw" surplus energy from other processes to
"available" energy that can be used in the District Heating network.

The default `DirectHeatUpgrade` heat exchanger assumes that mass flows can be different to
optimize heat transfer. This is encoded by the type parameter `HeatExchangerAssumptions`.
The default value is `DifferentMassFlows`, the alternative is to specify `EqualMassFlows`
to limit heat exchange to equal mass flow in the two circuits.

# Fields
- **`id`** is the name/identifier of the node.
- **`cap::TimeProfile`** is the installed capacity.
- **`opex_var::TimeProfile`** is the variable operating expense per energy unit produced.
- **`opex_fixed::TimeProfile`** is the fixed operating expense.
- **`input::Dict{<:Resource, <:Real}`** are the input `Resource`s with conversion value `Real`.
  Valid inputs are: one `Heat` resource and one power resource.
- **`output::Dict{<:Resource, <:Real}`** are the generated `Resource`s with conversion value
  `Real`. Valid output is a single `Heat` resource
- **`data::Vector{<:ExtensionData}`** is the additional data. The pinch data must be included
  here.
- **`delta_t_min`** is the ΔT_min for the heat exchanger.
"""
struct DirectHeatUpgrade{A<:HeatExchangerAssumptions,T<:Real} <: AbstractHeatExchanger
    id::Any
    cap::TimeProfile
    opex_var::TimeProfile
    opex_fixed::TimeProfile
    input::Dict{<:Resource,<:Real}
    output::Dict{<:Resource,<:Real}
    data::Vector{<:ExtensionData}
    delta_t_min::T
end
# Default to different mass flows assumptions for heat exchange
DirectHeatUpgrade(id, cap, opex_var, opex_fixed, input, output, data, delta_t_min) =
    DirectHeatUpgrade{DifferentMassFlows,typeof(delta_t_min)}(
        id,
        cap,
        opex_var,
        opex_fixed,
        input,
        output,
        data,
        delta_t_min,
    )
