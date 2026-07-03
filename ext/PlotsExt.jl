"""
Package extension of `EnergyModelsHeat` providing the implementation of
[`visualize_c_rates`](@ref EnergyModelsHeat.visualize_c_rates).

The extension is only loaded once the `Plots` package is available (declared as a weak
dependency of `EnergyModelsHeat`). This keeps plotting out of the core package, consistent
with the convention in the `EnergyModelsX` ecosystem of not adding plotting dependencies to
the technology packages.
"""
module PlotsExt

using EnergyModelsHeat
using Plots

# =========================================================
# Helper functions for computing charge/discharge curves
# =========================================================

"""
    compute_charge_curve(levels, cap_charge, c_rate_points)

Return the maximum charge rate at each storage level in `levels`.

- `levels`: array of storage levels to evaluate.
- `cap_charge`: installed charge rate (curve value at an empty storage).
- `c_rate_points`: one to three `[level, rate]` pairs in ascending storage-level order.

The formulas correspond to the piecewise-linear constraints built for a
[`LevelDependentRateTES`](@ref EnergyModelsHeat.LevelDependentRateTES).
"""
function compute_charge_curve(levels, cap_charge, c_rate_points)
    if length(c_rate_points) == 1
        x1, y1 = c_rate_points[1]

        m = (y1 - cap_charge) / x1
        b = cap_charge

        return m .* levels .+ b

    elseif length(c_rate_points) == 2
        (x1, y1), (x2, y2) = c_rate_points

        # First segment
        m1 = (y1 - cap_charge) / x1
        b1 = cap_charge

        # Second segment
        m2 = (y2 - y1) / (x2 - x1)
        b2 = y2 - m2 * x2

        return [level <= x1 ? m1 * level + b1 : m2 * level + b2 for level ∈ levels]

    elseif length(c_rate_points) == 3
        (x1, y1), (x2, y2), (x3, y3) = c_rate_points

        m1 = (y1 - cap_charge) / x1
        b1 = cap_charge

        m2 = (y2 - y1) / (x2 - x1)
        b2 = y2 - m2 * x2

        m3 = (y3 - y2) / (x3 - x2)
        b3 = y3 - m3 * x3

        return [
            level <= x1 ? m1 * level + b1 :
            (level <= x2 ? m2 * level + b2 : m3 * level + b3) for level ∈ levels
        ]
    else
        error("c_rate_points_charge must contain between 1 and 3 coordinate pairs.")
    end
end

"""
    compute_discharge_curve(levels, cap_discharge, cap_level, c_rate_points)

Return the maximum discharge rate at each storage level in `levels`.

- `levels`: array of storage levels to evaluate.
- `cap_discharge`: installed discharge rate (curve value at a full storage).
- `cap_level`: installed storage level capacity.
- `c_rate_points`: one to three `[level, rate]` pairs in descending storage-level order.

The formulas correspond to the piecewise-linear constraints built for a
[`LevelDependentRateTES`](@ref EnergyModelsHeat.LevelDependentRateTES).
"""
function compute_discharge_curve(levels, cap_discharge, cap_level, c_rate_points)
    if length(c_rate_points) == 1
        x1, y1 = c_rate_points[1]

        m = (cap_discharge - y1) / (cap_level - x1)
        b = cap_discharge - m * cap_level

        return m .* levels .+ b

    elseif length(c_rate_points) == 2
        (x1, y1), (x2, y2) = c_rate_points

        # First segment (region 1)
        m1 = (cap_discharge - y1) / (cap_level - x1)
        b1 = cap_discharge - m1 * cap_level

        # Second segment (region 2)
        m2 = (y1 - y2) / (x1 - x2)
        b2 = y2 - m2 * x2

        return [level >= x1 ? m1 * level + b1 : m2 * level + b2 for level ∈ levels]

    elseif length(c_rate_points) == 3
        (x1, y1), (x2, y2), (x3, y3) = c_rate_points

        # Region 1: highest SOC (cap_level down to x1)
        m1 = (cap_discharge - y1) / (cap_level - x1)
        b1 = cap_discharge - m1 * cap_level

        # Region 2: between x1 and x2
        m2 = (y1 - y2) / (x1 - x2)
        b2 = y2 - m2 * x2

        # Region 3: between x2 and x3 (lowest SOC)
        m3 = (y2 - y3) / (x2 - x3)
        b3 = y3 - m3 * x3

        return [
            level >= x1 ? m1 * level + b1 :
            (level >= x2 ? m2 * level + b2 : m3 * level + b3) for level ∈ levels
        ]
    else
        error("c_rate_points_discharge must contain between 1 and 3 coordinate pairs.")
    end
end

function EnergyModelsHeat.visualize_c_rates(
    charge_capacity,
    discharge_capacity,
    level_capacity,
    c_rate_points_charge,
    c_rate_points_discharge,
)
    # Storage level range to evaluate
    levels = range(0, level_capacity, length = 201)

    # =========================================================
    # Compute curves
    # =========================================================

    charge_curve = compute_charge_curve(levels, charge_capacity, c_rate_points_charge)
    discharge_curve = compute_discharge_curve(
        levels,
        discharge_capacity,
        level_capacity,
        c_rate_points_discharge,
    )
    maximum_charge_curve = [-level + level_capacity for level ∈ levels]
    maximum_discharge_curve = [level for level ∈ levels]

    combined_charge = Vector{Float64}(undef, length(charge_curve))
    for i ∈ eachindex(charge_curve, maximum_charge_curve)
        combined_charge[i] = min(charge_curve[i], maximum_charge_curve[i])
    end

    combined_discharge = Vector{Float64}(undef, length(discharge_curve))
    for i ∈ eachindex(discharge_curve, maximum_discharge_curve)
        combined_discharge[i] = min(discharge_curve[i], maximum_discharge_curve[i])
    end

    # =========================================================
    # Plot
    # =========================================================

    p = plot(
        levels,
        combined_charge,
        label = "Max Charge Rate",
        xlabel = "Storage Level",
        ylabel = "Charge/Discharge Rate",
        linewidth = 2,
        ylims = (0, max(charge_capacity, discharge_capacity)),
        size = (800, 500),
    )

    plot!(levels, combined_discharge, label = "Max Discharge Rate", linewidth = 2)

    title!("C-Rate Curves (Theoretical)")

    display(p)
    @info "Theoretical c-rate curves plotted"
    return p
end

end
