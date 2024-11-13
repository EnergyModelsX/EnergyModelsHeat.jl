"""
    create_link(m, 𝒯, 𝒫, l::Link, formulation::Formulation)

Set the constraints for a simple `Link` (input = output). Can serve as fallback option for
all unspecified subtypes of `Link`.

All links with capacity, as indicated through the function [`has_capacity`](@ref) call
furthermore the function [`constraints_capacity_installed`](@ref) for limiting the capacity
to the installed capacity.
"""
function create_link(m, 𝒯, 𝒫, l::Link, modeltype::EnergyModel, formulation::Formulation)

    # Generic link in which each output corresponds to the input
    @constraint(m, [t ∈ 𝒯, p ∈ link_res(l)],
        m[:link_out][l, t, p] == m[:link_in][l, t, p]-pipelength(l)*heatlossfactor(l)*(t_supply(l)-t_ground(l))
    )
    
    # Call of the function for limiting the capacity to the maximum installed capacity
    if has_capacity(l)
        constraints_capacity_installed(m, l, 𝒯, modeltype)
    end
end

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
struct HeatExchanger <: EnergyModelsBase.NetworkNode
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
        (T_HOT - T_COLD + ΔT_min) / (T_hot - T_cold)
    else
        (T_HOT - T_cold + ΔT_min) / (T_hot - T_cold)
    end
end

# function EnergyModelsBase.constraints_data(m, n, 𝒯, 𝒫, modeltype, data::PinchData)

# end

pinch_data(n::HeatExchanger) =
    only(filter(data -> typeof(data) <: PinchData, node_data(n)))

function EnergyModelsBase.constraints_flow_out(
    m,
    n::HeatExchanger,
    𝒯::TimeStructure,
    modeltype::EnergyModel,
)
    # Declaration of the required subsets, excluding CO2, if specified
    # 𝒫ᵒᵘᵗ = res_not(outputs(n), co2_instance(modeltype))

    pd = pinch_data(n)

    # TODO: Check that input/output are correct heat products
    heat_surplus = only(inputs(n))
    heat_available = only(outputs(n))

    # Available heat output is a fraction `ψ` of heat input
    @constraint(m, [t ∈ 𝒯],
        m[:flow_out][n, t, heat_available] == ψ(pd, t) * m[:flow_in][n, t, heat_surplus]
    )
end
