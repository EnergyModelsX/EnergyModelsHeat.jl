struct Heat{T} <: EnergyModelsBase.Resource
    id::Any
    T_supply::T
    T_return::T
    co2_int::T
end
Heat(id, T_supply, T_return) = Heat(id, T_supply, T_return, zero(T_return))
isheat(r) = false
isheat(r::Heat) = true

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
- **`input::Dict{<:Resource, <:Real}`** are the input `Resource`s with conversion value `Real`. \
Here: a `Heat` resource.
- **`output::Dict{<:Resource, <:Real}`** are the generated `Resource`s with conversion value `Real`. \
Here: a `Heat` resource.
- **`data::Vector{Data}`** is the additional data. The pinch data must be included here.
"""
struct HeatExchanger <: AbstractHeatExchanger
    id::Any
    cap::TimeProfile
    opex_var::TimeProfile
    opex_fixed::TimeProfile
    input::Dict{<:Resource,<:Real}
    output::Dict{<:Resource,<:Real}
    data::Vector{Data}
end

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
struct DirectHeatUpgrade <: AbstractHeatExchanger
    id::Any
    cap::TimeProfile
    opex_var::TimeProfile
    opex_fixed::TimeProfile
    input::Dict{<:Resource,<:Real}
    output::Dict{<:Resource,<:Real}
    data::Vector{Data}
end

"""
    PinchData{T}

Data for fixed temperature intervals used to calculate available energy from surplus energy source 
operating at `T_HOT` and `T_COLD`, with `ΔT_min` between surplus source and the district heating
network operating at `T_hot` and `T_cold`.
"""
struct PinchData{TP<:TimeProfile} <: EnergyModelsBase.Data
    T_HOT::TP
    T_COLD::TP
    ΔT_min::TP
    T_hot::TP
    T_cold::TP
end

"""
    ψ(pd::PinchData)

Calculate fraction of heat available for district heating at pinch point `T_cold`
"""
ψ(pd::PinchData, t) = ψ(pd.T_HOT[t], pd.T_COLD[t], pd.ΔT_min[t], pd.T_hot[t], pd.T_cold[t])

function ψ(T_HOT, T_COLD, ΔT_min, T_hot, T_cold)
    if (T_COLD - ΔT_min) ≥ T_cold
        (T_HOT - T_COLD - ΔT_min) / (T_hot - T_cold)
    else
        (T_HOT - T_cold - ΔT_min) / (T_hot - T_cold)
    end
end

"""
    
"""
upgrade(pd::PinchData, t) =
    upgrade(pd.T_HOT[t], pd.T_COLD[t], pd.ΔT_min[t], pd.T_hot[t], pd.T_cold[t])
function upgrade(T_HOT, T_COLD, ΔT_min, T_hot, T_cold)
    if T_hot > (T_HOT - ΔT_min)
        if T_COLD < (T_cold + ΔT_min)
            (T_hot - T_HOT + ΔT_min) / (T_HOT - T_COLD)
        else
            (T_hot - T_HOT + ΔT_min) / (T_HOT - ΔT_min - T_cold)
        end
    else
        0.0
    end
end

pinch_data(n::AbstractHeatExchanger) =
    only(filter(data -> typeof(data) <: PinchData, node_data(n)))

function EnergyModelsBase.constraints_flow_out(
    m,
    n::HeatExchanger,
    𝒯::TimeStructure,
    modeltype::EnergyModel,
)
    pd = pinch_data(n)
    heat_surplus = only(inputs(n))
    heat_available = only(outputs(n))

    # Available heat output is a fraction `ψ` of heat input
    @constraint(m, [t ∈ 𝒯],
        m[:flow_out][n, t, heat_available] == ψ(pd, t) * m[:flow_in][n, t, heat_surplus]
    )
end

upgrade_fraction(pd, t) = upgrade(pd, t) / (upgrade(pd, t) + ψ(pd, t))

function EnergyModelsBase.constraints_flow_out(
    m,
    n::DirectHeatUpgrade,
    𝒯::TimeStructure,
    modeltype::EnergyModel,
)
    pd = pinch_data(n)
    # Only allow two inputs, one heat and one other (power)
    power = only(filter(!isheat, inputs(n)))
    heat_surplus = only(filter(isheat, inputs(n)))
    # Only allow one output, must be heat
    heat_available = only(filter(isheat, outputs(n)))

    # usable_fraction(pd, t) = EMH.ψ(pd, t) / (EMH.upgrade(pd, t) + ψ(pd, t))

    # Available heat output is a fraction `ψ` of heat input and the upgrade
    @constraint(m, [t ∈ 𝒯],
        m[:flow_out][n, t, heat_available] ≤
        (ψ(pd, t) + upgrade(pd, t)) * m[:flow_in][n, t, heat_surplus]
    )
    # Upgrade is powered by power in according to how much is used of the surplus heat in the updgraded flow out
    @constraint(m, [t ∈ 𝒯],
        m[:flow_in][n, t, power] ==
        upgrade_fraction(pd, t) * m[:flow_out][n, t, heat_available]
    )
end

function EnergyModelsBase.constraints_flow_in(
    m,
    n::DirectHeatUpgrade,
    𝒯::TimeStructure,
    modeltype::EnergyModel,
)
    # Define capacity by power in
    power = only(filter(!isheat, inputs(n)))

    # Constraint for the individual input stream connections
    @constraint(m, [t ∈ 𝒯],
        m[:flow_in][n, t, power] == m[:cap_use][n, t] * inputs(n, power)
    )
end
