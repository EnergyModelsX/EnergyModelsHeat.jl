
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
Calculates the input flows for various resources based on the COP of the HeatPump. 
The COP is based on Source and Sink temperature profiles and the carnot efficiency. 

# Called constraint functions
- [`constraints_level`](@ref)
- [`constraints_data`](@ref) for all `node_data(n)`,
- [`constraints_flow_in`](@ref),
- [`constraints_flow_out`](@ref),
- [`constraints_capacity`](@ref),
- [`constraints_opex_fixed`](@ref), and
- [`constraints_opex_var`](@ref).
"""
function EMB.constraints_level(
    m,
    n::ThermalEnergyStorage,
    𝒯::TimeStructure,
    modeltype::EnergyModel,
)
    # Declaration of the required subsets
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)

    # Call the auxiliary function for additional constraints on the level
    EMB.constraints_level_aux(m, n::ThermalEnergyStorage, 𝒯, 𝒫, modeltype::EnergyModel)

    # Mass/energy balance constraints for stored energy carrier.
    for (t_inv_prev, t_inv) ∈ withprev(𝒯ᴵⁿᵛ)
        # Creation of the iterator and call of the iterator function -
        # The representative period is initiated with the current investment period to allow
        # dispatching on it.
        prev_pers = PreviousPeriods(t_inv_prev, nothing, nothing)
        cyclic_pers = CyclicPeriods(t_inv, t_inv)
        ts = t_inv.operational
        EMB.constraints_level_iterate(
            m,
            n::ThermalEnergyStorage,
            prev_pers,
            cyclic_pers,
            t_inv,
            ts,
            modeltype,
        )
    end
end

function EMB.constraints_level_iterate(
    m,
    n::ThermalEnergyStorage,
    prev_pers::PreviousPeriods,
    cyclic_pers::CyclicPeriods,
    per,
    _::SimpleTimes,
    modeltype::EnergyModel,
)

    # Iterate through the operational structure
    for (t_prev, t) ∈ withprev(per)
        prev_pers = PreviousPeriods(strat_per(prev_pers), rep_per(prev_pers), t_prev)

        # Extract the previous level
        prev_level = previous_level(m, n, prev_pers, cyclic_pers, modeltype)

        # Mass balance constraint in the storage
        @constraint(m,
            m[:stor_level][n, t] ==
            prev_level + m[:stor_level_Δ_op][n, t] * duration(t) -
            prev_level * heatlossfactor(n)
        )

        # Constraint for avoiding starting below 0 if the previous operational level is
        # nothing
        EMB.constraints_level_bounds(m, n, t, cyclic_pers, modeltype)
    end
end

function create_node(m, n::ThermalEnergyStorage, 𝒯, 𝒫, modeltype::EnergyModel)

    # Declaration of the required subsets.
    𝒯ᴵⁿᵛ = strategic_periods(𝒯)

    # Mass/energy balance constraints for stored energy carrier.
    EMB.constraints_level(m, n::ThermalEnergyStorage, 𝒯, 𝒫, modeltype::EnergyModel)

    # Iterate through all data and set up the constraints corresponding to the data
    for data ∈ node_data(n)
        constraints_data(m, n, 𝒯, 𝒫, modeltype, data)
    end

    # Call of the function for the inlet flow to and outlet flow from the `Storage` node
    constraints_flow_in(m, n, 𝒯, modeltype)
    constraints_flow_out(m, n, 𝒯, modeltype)

    # Call of the function for limiting the capacity to the maximum installed capacity
    #constraints_capacity(m, n, 𝒯, modeltype)

    constraints_capacity(m, n, 𝒯, modeltype)

    # Call of the functions for both fixed and variable OPEX constraints introduction
    constraints_opex_fixed(m, n, 𝒯ᴵⁿᵛ, modeltype)
    constraints_opex_var(m, n, 𝒯ᴵⁿᵛ, modeltype)
end
