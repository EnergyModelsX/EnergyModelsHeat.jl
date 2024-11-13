

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

	## Custom constraints for COP calculation and flexibility

	#Part Load Constraint
	@constraint(m, [t ∈ 𝒯],
		m[:cap_use][n, t] >= (m[:cap_inst][n, t] * cap_lower_bound(n))
	)

	# Constraint for the COP - Heat
	@constraint(m, [t ∈ 𝒯],
		m[:flow_in][n, t, heat_input_resource(n)] ==
		(m[:cap_use][n, t] * (1 - ((t_sink(n, t) - t_source(n, t)) / (eff_carnot(n, t) * (t_sink(n, t) + 273.15)))))
	)

	# Constraint for the COP - Electricity
	@constraint(m, [t ∈ 𝒯],
		m[:flow_in][n, t, drivingforce_resource(n)] ==
		(m[:cap_use][n, t] * (t_sink(n, t) - t_source(n, t))) / (eff_carnot(n, t) * (t_sink(n, t) + 273.15))
	)

end