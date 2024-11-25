
function EMB.create_link(m, 𝒯, 𝒫, l::DHPipe, formulation::EMB.Formulation)

    # Generic link in which each output corresponds to the input
    @constraint(m, [t ∈ 𝒯, p ∈ link_res(l)],
        m[:link_out][l, t, p] ==
        m[:link_in][l, t, p] -
        pipelength(l) * heatlossfactor(l) * (t_supply(l) - t_ground(l))
        #m[:link_out][l, t, p] == m[:link_in][l, t, p]*HEATLOSSFACTOR
    )

    # Call of the function for limiting the capacity to the maximum installed capacity
    #if EMB.has_capacity(l::DHPipe)
    #    EMB.constraints_capacity_installed(m, l, 𝒯, modeltype)
    #end
end


"""
    ψ(pd::PinchData)

Calculate fraction of heat available for district heating at pinch point `T_cold`
"""
ψ(pd::PinchData, t) = ψ(pd.T_HOT[t], pd.T_COLD[t], pd.ΔT_min[t], pd.T_hot[t], pd.T_cold[t])

# Assuming equal mass flows
function ψ(T_HOT, T_COLD, ΔT_min, T_hot, T_cold)
    if T_hot ≤ (T_HOT - ΔT_min)
        if ((T_hot - T_cold) > (T_HOT - T_COLD)) || (T_COLD < T_cold + ΔT_min)
            zero(T_HOT)
        else
            (T_hot - T_cold) / (T_HOT - T_COLD)
        end
    else
        zero(T_HOT)
    end
end


# Allowing different mass flows
ψ2(pd::PinchData, t) = ψ2(pd.T_HOT[t], pd.T_COLD[t], pd.ΔT_min[t], pd.T_hot[t], pd.T_cold[t])
function ψ2(T_HOT, T_COLD, ΔT_min, T_hot, T_cold)
    if (T_hot > (T_HOT - ΔT_min))
        zero(T_HOT)
    elseif (T_COLD < (T_cold + ΔT_min))
        (T_HOT - (T_cold + ΔT_min)) / (T_HOT - T_COLD)
    else
        one(T_HOT)
    end
end

"""
Assuming equal mass flows    
"""
upgrade(pd::PinchData, t) =
    upgrade(pd.T_HOT[t], pd.T_COLD[t], pd.ΔT_min[t], pd.T_hot[t], pd.T_cold[t])
function upgrade(T_HOT, T_COLD, ΔT_min, T_hot, T_cold)
    if T_hot > (T_HOT - ΔT_min)
        if T_COLD < (T_cold + ΔT_min)
            (T_hot - T_HOT + ΔT_min) / (T_hot - T_cold)
        else
            (T_hot - (T_cold + T_HOT - T_COLD)) / (T_hot - T_cold)
        end
    end
    zero(T_HOT)
end

upgrade2(pd::PinchData, t) =
    upgrade2(pd.T_HOT[t], pd.T_COLD[t], pd.ΔT_min[t], pd.T_hot[t], pd.T_cold[t])
function upgrade2(T_HOT, T_COLD, ΔT_min, T_hot, T_cold)
    if (T_COLD < (T_cold + ΔT_min))
        (T_hot - T_HOT + ΔT_min) / (T_hot - T_cold)
    else
        zero(T_HOT)
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

"""
    create_node(m, n::HeatPump, 𝒯::TimeStructure, 𝒫, modeltype::EnergyModel)

Set all constraints for a `HeatPump`.
Calculates the input flows for various resources based on the COP of the HeatPump. 
The COP is based on Source and Sink temperature profiles and the carnot efficiency. 
It is also possible to inlude a lower capacity bound which the HeatPump cannot cross. This means, however, that cap_use cannot be zero either. 

# Called constraint functions
- [`constraints_data`](@ref) for all `node_data(n)`,
- [`constraints_flow_out`](@ref),
- [`constraints_capacity`](@ref),
- [`constraints_opex_fixed`](@ref),
- [`constraints_opex_var`](@ref),
- [`constraints_cap_bound`](@ref),
- [`constraints_COP_Heat`](@ref),
- [`constraints_COP_Power`](@ref),
"""
function EMB.create_node(m, n::HeatPump, 𝒯::TimeStructure, 𝒫, modeltype::EnergyModel)

    ## Use the same constraint functions as for a normal Network Node

    # Declaration of the required subsets
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)

    # Iterate through all data and set up the constraints corresponding to the data
    for data ∈ node_data(n)
        constraints_data(m, n, 𝒯, 𝒫, modeltype, data)
    end

    # Call of the function for the outlet flow from the `NetworkNode` node
    constraints_flow_out(m, n, 𝒯, modeltype)

    # Call of the function for limiting the capacity to the maximum installed capacity
    constraints_capacity(m, n, 𝒯, modeltype)

    # Call of the functions for both fixed and variable OPEX constraints introduction
    constraints_opex_fixed(m, n, 𝒯ᴵⁿᵛ, modeltype)
    constraints_opex_var(m, n, 𝒯ᴵⁿᵛ, modeltype)

    # Call the function for the minimum used capacity (lower capacity bound)
    constraints_cap_bound(m, n, 𝒯, modeltype)

    # Constraint for the COP - Heat
    constraints_COP_Heat(m, n, 𝒯, modeltype)

    # Constraint for the COP - Electricity
    constraints_COP_Power(m, n, 𝒯, modeltype)
end

"""
    create_node(m, n::ThermalEnergyStorage, 𝒯, 𝒫, modeltype::EnergyModel)

Set all constraints for a `ThermalEnergyStorage`.
Calls the constraint function constraints_level_iterate that includes the heatlossfactor in the calculation of the storage level. 
!!!Currently this Node is only available in combination with CyclicPeriods!!!

# Called constraint functions
- [`constraints_level`](@ref)
- [`constraints_data`](@ref) for all `node_data(n)`,
- [`constraints_flow_in`](@ref),
- [`constraints_flow_out`](@ref),
- [`constraints_capacity`](@ref),
- [`constraints_opex_fixed`](@ref), and
- [`constraints_opex_var`](@ref).
"""
function create_node(m, n::ThermalEnergyStorage, 𝒯, 𝒫, modeltype::EnergyModel)

    # Declaration of the required subsets.
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)

    # Mass/energy balance constraints for stored energy carrier.
    constraints_level(m, n, 𝒯, 𝒫, modeltype)

    # Iterate through all data and set up the constraints corresponding to the data
    for data ∈ node_data(n)
        constraints_data(m, n, 𝒯, 𝒫, modeltype, data)
    end

    # Call of the function for the inlet flow to and outlet flow from the `Storage` node
    constraints_flow_in(m, n, 𝒯, modeltype)
    constraints_flow_out(m, n, 𝒯, modeltype)

    # Call of the function for limiting the capacity to the maximum installed capacity
    constraints_capacity(m, n, 𝒯, modeltype)

    # Call of the functions for both fixed and variable OPEX constraints introduction
    constraints_opex_fixed(m, n, 𝒯ᴵⁿᵛ, modeltype)
    constraints_opex_var(m, n, 𝒯ᴵⁿᵛ, modeltype)
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
        upgrade(pd, t) + m[:flow_in][n, t, heat_surplus]
    )
    # Upgrade is powered by power in according to how much is used of the surplus heat in the updgraded flow out
    @constraint(m, [t ∈ 𝒯],
        m[:flow_in][n, t, power] ==
        upgrade(pd, t) * m[:flow_out][n, t, heat_available]
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
