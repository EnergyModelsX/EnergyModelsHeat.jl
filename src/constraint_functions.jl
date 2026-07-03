"""
    EMB.constraints_capacity(m, n::HeatPump, 𝒯::TimeStructure, modeltype::EnergyModel)

Method for creating the constraints on the maximum capacity of a [`HeatPump`](@ref).

It adds in the addition to the constraints of the standard method the lower bound constraints.
"""
function EMB.constraints_capacity(m, n::HeatPump, 𝒯::TimeStructure, modeltype::EnergyModel)
    #Part Load Constraint
    @constraint(m, [t ∈ 𝒯],
        m[:cap_use][n, t] >= (m[:cap_inst][n, t] * cap_lower_bound(n))
    )

    @constraint(m, [t ∈ 𝒯], m[:cap_use][n, t] <= m[:cap_inst][n, t])

    constraints_capacity_installed(m, n, 𝒯, modeltype)
end

"""
    EMB.constraints_flow_in(m, n::HeatPump, 𝒯::TimeStructure, modeltype::EnergyModel)

Method for creating the constraint on the inlet flow to a [`HeatPump`](@ref).

It is utlizing the specified temperature levels, [`heat_in_resource`](@ref) and
[`driving_force_resource`](@ref) for calculating the values.
"""
function EMB.constraints_flow_in(m, n::HeatPump, 𝒯::TimeStructure, modeltype::EnergyModel)
    # Calculate the multiplier
    mult(t) = (t_sink(n, t) - t_source(n, t)) / (eff_carnot(n, t) * (t_sink(n, t) + 273.15))

    # Constraint for the COP - Heat
    @constraint(m, [t ∈ 𝒯],
        m[:flow_in][n, t, heat_in_resource(n)] == m[:cap_use][n, t] * (1 - mult(t))
    )

    # Constraint for the COP - Electricity
    @constraint(m, [t ∈ 𝒯],
        m[:flow_in][n, t, driving_force_resource(n)] == m[:cap_use][n, t] * mult(t)
    )
end

"""
    EMB.constraints_flow_in(m, n::DirectHeatUpgrade, 𝒯::TimeStructure, modeltype::EnergyModel)

Method for creating the constraint on the inlet flow to a [`DirectHeatUpgrade`](@ref).

The constraint is only for power as the proportion of the inputs depends on the need for
upgrade computed from the temperatures of the input/output [`ResourceHeat`](@ref) and the
ΔT_min. The capacity is linked to the power consumption.
"""
function EMB.constraints_flow_in(
    m,
    n::DirectHeatUpgrade,
    𝒯::TimeStructure,
    modeltype::EnergyModel,
)
    # Define capacity by power in
    power = only(filter(!is_heat, inputs(n)))

    # Constraint for the individual input stream connections
    @constraint(m, [t ∈ 𝒯],
        m[:flow_in][n, t, power] == m[:cap_use][n, t] * inputs(n, power)
    )
end

"""
    EMB.constraints_flow_out(m, n::HeatExchanger{A,T}, 𝒯::TimeStructure, modeltype::EnergyModel)

Method for creating the constraint on the outlet flow from a [`HeatExchanger`](@ref).

The flow of available heat energy is calculated from the temperatures in the heat flows
using the function [`dh_fraction`](@ref).
"""
function EMB.constraints_flow_out(
    m,
    n::HeatExchanger{A,T},
    𝒯::TimeStructure,
    modeltype::EnergyModel,
) where {A,T}
    heat_surplus = only(inputs(n))
    heat_available = only(outputs(n))
    pd = pinch_data(n)

    # Available heat output is a fraction `dh_fraction` of heat input
    @constraint(m, [t ∈ 𝒯],
        m[:flow_out][n, t, heat_available] ==
        dh_fraction(A, pd, t) * m[:flow_in][n, t, heat_surplus]
    )
end

"""
    EMB.constraints_flow_out(m, n::DirectHeatUpgrade{A,T}, 𝒯::TimeStructure, modeltype::EnergyModel) where {A,T}

Method for creating the constraint on the outlet flow from a [`DirectHeatUpgrade`](@ref).

The flow of available heat energy is calculated from the temperatures in the heat flows
using the function [`upgradeable_fraction`](@ref), and the heat needed to upgrade to the
required temperature is calculated by the function [`dh_upgrade`](@ref).

!!! note
    The node may dump some of the ingoing heat energy, and the power needed for the upgrade
    is calculated from the resulting energy outflow.
"""
function EMB.constraints_flow_out(
    m,
    n::DirectHeatUpgrade{A,T},
    𝒯::TimeStructure,
    modeltype::EnergyModel,
) where {A,T}
    pd = pinch_data(n)
    # Only allow two inputs, one heat and one other (power)
    power = only(filter(!is_heat, inputs(n)))
    heat_surplus = only(filter(is_heat, inputs(n)))
    # Only allow one output, must be heat
    heat_available = only(filter(is_heat, outputs(n)))

    # Available heat output is a fraction of heat input and the upgrade (using extra power)
    for t ∈ 𝒯
        if dh_upgrade(A, pd, t) > 0
            @constraint(m,
                m[:flow_out][n, t, heat_available] ≤
                m[:flow_in][n, t, power] +
                upgradeable_fraction(A, pd, t) * m[:flow_in][n, t, heat_surplus]
            )
            # Upgrade is powered by power in according to how much is used of the surplus heat in the upgraded flow out
            @constraint(m,
                m[:flow_in][n, t, power] ==
                dh_upgrade(A, pd, t) * m[:flow_out][n, t, heat_available]
            )
        else
            # No need for upgrade, heat can be used directly
            @constraint(m,
                m[:flow_out][n, t, heat_available] ≤
                dh_fraction(A, pd, t) * m[:flow_in][n, t, heat_surplus]
            )
        end
    end
end

"""
    EMB.constraints_level_iterate(
        m,
        n::AbstractTES,
        prev_pers::PreviousPeriods,
        cyclic_pers::CyclicPeriods,
        per,
        _::SimpleTimes,
        modeltype::EnergyModel,
    )

In the case of a [`AbstractTES`](@ref), the lowest level iterator is adjusted as the loss
is dependent on the level at the beginning of the operational period.
"""
function EMB.constraints_level_iterate(
    m,
    n::AbstractTES,
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
            prev_level * heat_loss_factor(n) * duration(t)
        )

        # Constraint for avoiding starting below 0 if the previous operational level is
        # nothing
        EMB.constraints_level_bounds(m, n, t, cyclic_pers, modeltype)
    end
end

"""
    EMB.constraints_capacity(
        m,
        n::BoundRateTES,
        𝒯::TimeStructure,
        modeltype::EnergyModel,
    )

Method for creating the constraints on the maximum capacity of a [`BoundRateTES`](@ref)

It adjusts the constraints on the capacity of a [`BoundRateTES`](@ref) to account for the
maximum charge and discharge rates in relation to the installed storage level.
"""

function EMB.constraints_capacity(
    m,
    n::BoundRateTES,
    𝒯::TimeStructure,
    modeltype::EnergyModel,
)
    @constraint(m, [t ∈ 𝒯], m[:stor_level][n, t] ≤ m[:stor_level_inst][n, t])

    # The discharge rate is limited by the installed storage level and the level_discharge multiplier
    @constraint(
        m,
        [t ∈ 𝒯],
        m[:stor_discharge_use][n, t] ≤ m[:stor_level_inst][n, t] * level_discharge(n)
    )
    # The charge rate is limited by the installed storage level and the level_charge multiplier
    @constraint(
        m,
        [t ∈ 𝒯],
        m[:stor_charge_use][n, t] ≤ m[:stor_level_inst][n, t] * level_charge(n)
    )

    constraints_capacity_installed(m, n, 𝒯, modeltype)
end

"""
    EMB.constraints_capacity(m, n::LevelDependentRateTES, 𝒯::TimeStructure, modeltype::OperationalModel)

Method for creating the constraints on the maximum capacity of a [`LevelDependentRateTES`](@ref).

It adjusts the capacity constraints to account for state-of-charge dependent charge and
discharge limits. The limits are drawn from the c-rate anchor points on the node (one to three
per direction); the rate allowed in operational period `t` depends on the storage level at the
end of the previous operational period `t_prev`.

With a single anchor point the limit is a single line. With two or three anchor points the
curve is piecewise linear, and the binary variables `bin_region_charge`/`bin_region_discharge`
(declared in [`EMB.variables_node`](@ref)) together with a big-``M`` formulation select the
active region. Because the node is restricted to an `OperationalModel`, all slopes and
intercepts are fixed parameters, so every big-``M`` is computed tightly from the geometry (the
installed level capacity for the region-selection bounds, and the smallest lift that keeps each
inactive rate segment above the installed rate) instead of a single loose constant. This keeps
the inactive constraints non-binding without weakening the model's relaxation.

!!! warning "Only operational models are supported"
    This method only dispatches on an [`OperationalModel`](@extref EnergyModelsBase.OperationalModel).
    With an [`InvestmentModel`](@extref EnergyModelsBase.InvestmentModel) the installed storage,
    charge and discharge capacities become decision variables instead of fixed parameters. The
    slopes and intercepts of the c-rate curves then depend on those capacity variables, so the
    rate limit would multiply a capacity variable by the storage-level variable
    ``\\texttt{stor\\_level}[n, t_{prev}]``. This product of two decision variables is a
    bilinear (nonconvex quadratic) term, which the linear/mixed-integer-linear solvers used in
    this package (*e.g.*, `HiGHS`) cannot handle. A [`LevelDependentRateTES`](@ref) must
    therefore be used with an [`OperationalModel`](@extref EnergyModelsBase.OperationalModel).
"""
function EMB.constraints_capacity(
    m,
    n::LevelDependentRateTES,
    𝒯::TimeStructure,
    modeltype::OperationalModel,
)
    @constraint(m, [t ∈ 𝒯], m[:stor_level][n, t] <= m[:stor_level_inst][n, t])
    @constraint(m, [t ∈ 𝒯], m[:stor_charge_use][n, t] <= m[:stor_charge_inst][n, t])
    @constraint(m, [t ∈ 𝒯], m[:stor_discharge_use][n, t] <= m[:stor_discharge_inst][n, t])

    constraints_capacity_installed(m, n, 𝒯, modeltype)

    ### CHARGING ###

    x_1_c = c_rate_points_charge(n)[1][1]
    y_1_c = c_rate_points_charge(n)[1][2]

    if length(c_rate_points_charge(n)) == 1
        @info "Using linear C_rate gradient for charging of $n."

        for (t_prev, t) ∈ withprev(𝒯)
            if t_prev === nothing
                continue
            end

            m_charge = (y_1_c - capacity(charge(n), t)) / x_1_c
            b_charge = capacity(charge(n), t)

            @constraint(
                m,
                m[:stor_charge_use][n, t] <=
                m_charge * m[:stor_level][n, t_prev] + b_charge
            )
        end
    elseif length(c_rate_points_charge(n)) == 2
        x_2_c = c_rate_points_charge(n)[2][1]
        y_2_c = c_rate_points_charge(n)[2][2]

        @warn "Using piecewise linear C-rate gradients for charging of $n. This introduces binary variables."

        for (t_prev, t) ∈ withprev(𝒯)
            if t_prev === nothing
                continue
            end

            cap_charge = capacity(charge(n), t)
            level_cap = capacity(level(n), t_prev)
            region_bin = m[:bin_region_charge][n, t, 1]

            @constraint(
                m,
                m[:stor_level][n, t_prev] <= x_1_c + (level_cap - x_1_c) * region_bin
            )
            @constraint(m, m[:stor_level][n, t_prev] >= x_1_c - x_1_c * (1 - region_bin))

            m_1_charge = (y_1_c - cap_charge) / x_1_c
            b_1_charge = cap_charge
            m_2_charge = (y_2_c - y_1_c) / (x_2_c - x_1_c)
            b_2_charge = y_2_c - m_2_charge * x_2_c

            M_1 = max(
                0.0,
                cap_charge - min(
                    m_1_charge * x_1_c + b_1_charge,
                    m_1_charge * level_cap + b_1_charge,
                ),
            )
            M_2 = max(0.0, cap_charge - min(b_2_charge, m_2_charge * x_1_c + b_2_charge))

            @constraint(
                m,
                m[:stor_charge_use][n, t] <=
                m_1_charge * m[:stor_level][n, t_prev] + b_1_charge + region_bin * M_1
            )
            @constraint(
                m,
                m[:stor_charge_use][n, t] <=
                m_2_charge * m[:stor_level][n, t_prev] + b_2_charge +
                (1 - region_bin) * M_2
            )
        end
    elseif length(c_rate_points_charge(n)) == 3
        x_2_c = c_rate_points_charge(n)[2][1]
        y_2_c = c_rate_points_charge(n)[2][2]
        x_3_c = c_rate_points_charge(n)[3][1]
        y_3_c = c_rate_points_charge(n)[3][2]

        @warn "Using piecewise linear C-rate gradients for charging of $n. This introduces binary variables."

        for (t_prev, t) ∈ withprev(𝒯)
            if t_prev === nothing
                continue
            end

            cap_charge = capacity(charge(n), t)
            level_cap = capacity(level(n), t_prev)
            lower_split_bin = m[:bin_region_charge][n, t, 1]
            upper_split_bin = m[:bin_region_charge][n, t, 2]

            # Enforce a valid region encoding (the upper split implies the lower split)
            @constraint(m, upper_split_bin <= lower_split_bin)

            @constraint(
                m,
                m[:stor_level][n, t_prev] <= x_1_c + (level_cap - x_1_c) * lower_split_bin
            )
            @constraint(
                m,
                m[:stor_level][n, t_prev] >= x_1_c - x_1_c * (1 - lower_split_bin)
            )
            @constraint(
                m,
                m[:stor_level][n, t_prev] <= x_2_c + (level_cap - x_2_c) * upper_split_bin
            )
            @constraint(
                m,
                m[:stor_level][n, t_prev] >= x_2_c - x_2_c * (1 - upper_split_bin)
            )

            m_1_charge = (y_1_c - cap_charge) / x_1_c
            b_1_charge = cap_charge
            m_2_charge = (y_2_c - y_1_c) / (x_2_c - x_1_c)
            b_2_charge = y_2_c - m_2_charge * x_2_c
            m_3_charge = (y_3_c - y_2_c) / (x_3_c - x_2_c)
            b_3_charge = y_3_c - m_3_charge * x_3_c

            M_1 = max(
                0.0,
                cap_charge - min(
                    m_1_charge * x_1_c + b_1_charge,
                    m_1_charge * level_cap + b_1_charge,
                ),
            )
            M_2 =
                max(0.0, cap_charge - min(b_2_charge, m_2_charge * level_cap + b_2_charge))
            M_3 = max(0.0, cap_charge - min(b_3_charge, m_3_charge * x_2_c + b_3_charge))

            # Region selection:
            # - lower_split_bin = 0, upper_split_bin = 0 => region 1 (lowest SOC)
            # - lower_split_bin = 1, upper_split_bin = 0 => region 2 (middle SOC)
            # - lower_split_bin = 1, upper_split_bin = 1 => region 3 (highest SOC)
            @constraint(
                m,
                m[:stor_charge_use][n, t] <=
                m_1_charge * m[:stor_level][n, t_prev] + b_1_charge + lower_split_bin * M_1
            )
            @constraint(
                m,
                m[:stor_charge_use][n, t] <=
                m_2_charge * m[:stor_level][n, t_prev] + b_2_charge +
                (1 - lower_split_bin) * M_2 +
                upper_split_bin * M_2
            )
            @constraint(
                m,
                m[:stor_charge_use][n, t] <=
                m_3_charge * m[:stor_level][n, t_prev] + b_3_charge +
                (1 - upper_split_bin) * M_3
            )
        end
    end

    ### DISCHARGING ###

    x_1_d = c_rate_points_discharge(n)[1][1]
    y_1_d = c_rate_points_discharge(n)[1][2]

    if length(c_rate_points_discharge(n)) == 1
        @info "Using linear C_rate gradient for discharging of $n."

        for (t_prev, t) ∈ withprev(𝒯)
            if t_prev === nothing
                continue
            end

            m_discharge =
                (capacity(discharge(n), t) - y_1_d) / (capacity(level(n), t_prev) - x_1_d)
            b_discharge =
                capacity(discharge(n), t) - m_discharge * capacity(level(n), t_prev)

            @constraint(
                m,
                m[:stor_discharge_use][n, t] <=
                m_discharge * m[:stor_level][n, t_prev] + b_discharge
            )
        end
    elseif length(c_rate_points_discharge(n)) == 2
        x_2_d = c_rate_points_discharge(n)[2][1]
        y_2_d = c_rate_points_discharge(n)[2][2]

        @warn "Using piecewise linear C-rate gradients for discharging of $n. This introduces binary variables."

        for (t_prev, t) ∈ withprev(𝒯)
            if t_prev === nothing
                continue
            end

            cap_discharge = capacity(discharge(n), t)
            level_cap = capacity(level(n), t_prev)
            region_bin = m[:bin_region_discharge][n, t, 1]

            @constraint(
                m,
                m[:stor_level][n, t_prev] <= x_1_d + (level_cap - x_1_d) * region_bin
            )
            @constraint(m, m[:stor_level][n, t_prev] >= x_1_d - x_1_d * (1 - region_bin))

            m_1_discharge = (cap_discharge - y_1_d) / (level_cap - x_1_d)
            b_1_discharge = cap_discharge - m_1_discharge * level_cap
            m_2_discharge = (y_1_d - y_2_d) / (x_1_d - x_2_d)
            b_2_discharge = y_2_d - m_2_discharge * x_2_d

            M_1 = max(
                0.0,
                cap_discharge - min(b_1_discharge, m_1_discharge * x_1_d + b_1_discharge),
            )
            M_2 = max(
                0.0,
                cap_discharge - min(
                    m_2_discharge * x_1_d + b_2_discharge,
                    m_2_discharge * level_cap + b_2_discharge,
                ),
            )

            @constraint(
                m,
                m[:stor_discharge_use][n, t] <=
                m_1_discharge * m[:stor_level][n, t_prev] + b_1_discharge +
                (1 - region_bin) * M_1
            )
            @constraint(
                m,
                m[:stor_discharge_use][n, t] <=
                m_2_discharge * m[:stor_level][n, t_prev] + b_2_discharge +
                region_bin * M_2
            )
        end
    elseif length(c_rate_points_discharge(n)) == 3
        x_2_d = c_rate_points_discharge(n)[2][1]
        y_2_d = c_rate_points_discharge(n)[2][2]
        x_3_d = c_rate_points_discharge(n)[3][1]
        y_3_d = c_rate_points_discharge(n)[3][2]

        @warn "Using piecewise linear C-rate gradients for discharging of $n. This introduces binary variables."

        for (t_prev, t) ∈ withprev(𝒯)
            if t_prev === nothing
                continue
            end

            cap_discharge = capacity(discharge(n), t)
            level_cap = capacity(level(n), t_prev)
            upper_split_bin = m[:bin_region_discharge][n, t, 1]
            lower_split_bin = m[:bin_region_discharge][n, t, 2]

            # Being in the upper region implies being in the middle/upper combined region
            @constraint(m, upper_split_bin <= lower_split_bin)

            @constraint(
                m,
                m[:stor_level][n, t_prev] <= x_1_d + (level_cap - x_1_d) * upper_split_bin
            )
            @constraint(
                m,
                m[:stor_level][n, t_prev] >= x_1_d - x_1_d * (1 - upper_split_bin)
            )
            @constraint(
                m,
                m[:stor_level][n, t_prev] <= x_2_d + (level_cap - x_2_d) * lower_split_bin
            )
            @constraint(
                m,
                m[:stor_level][n, t_prev] >= x_2_d - x_2_d * (1 - lower_split_bin)
            )

            m_1_discharge = (cap_discharge - y_1_d) / (level_cap - x_1_d)
            b_1_discharge = cap_discharge - m_1_discharge * level_cap
            m_2_discharge = (y_1_d - y_2_d) / (x_1_d - x_2_d)
            b_2_discharge = y_2_d - m_2_discharge * x_2_d
            m_3_discharge = (y_2_d - y_3_d) / (x_2_d - x_3_d)
            b_3_discharge = y_3_d - m_3_discharge * x_3_d

            M_1 = max(
                0.0,
                cap_discharge - min(b_1_discharge, m_1_discharge * x_1_d + b_1_discharge),
            )
            M_2 = max(
                0.0,
                cap_discharge -
                min(b_2_discharge, m_2_discharge * level_cap + b_2_discharge),
            )
            M_3 = max(
                0.0,
                cap_discharge - min(
                    m_3_discharge * x_2_d + b_3_discharge,
                    m_3_discharge * level_cap + b_3_discharge,
                ),
            )

            # Region selection:
            # - upper_split_bin = 1, lower_split_bin = 1 => region 1 (highest SOC)
            # - upper_split_bin = 0, lower_split_bin = 1 => region 2 (middle SOC)
            # - upper_split_bin = 0, lower_split_bin = 0 => region 3 (lowest SOC)
            @constraint(
                m,
                m[:stor_discharge_use][n, t] <=
                m_1_discharge * m[:stor_level][n, t_prev] + b_1_discharge +
                (1 - upper_split_bin) * M_1
            )
            @constraint(
                m,
                m[:stor_discharge_use][n, t] <=
                m_2_discharge * m[:stor_level][n, t_prev] + b_2_discharge +
                upper_split_bin * M_2 +
                (1 - lower_split_bin) * M_2
            )
            @constraint(
                m,
                m[:stor_discharge_use][n, t] <=
                m_3_discharge * m[:stor_level][n, t_prev] + b_3_discharge +
                lower_split_bin * M_3
            )
        end
    end
end
