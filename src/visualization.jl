"""
    visualize_c_rates(
        charge_capacity,
        discharge_capacity,
        level_capacity,
        c_rate_points_charge,
        c_rate_points_discharge,
    )

Plot the *theoretical* maximum charge and discharge rate curves of a
[`LevelDependentRateTES`](@ref) as a function of the storage level, so the user can inspect
the (dis-)charge curves their input produces before solving a model.

The arguments mirror the corresponding fields of a [`LevelDependentRateTES`](@ref):
- **`charge_capacity`** is the installed charge rate (the curve's value at an empty storage).
- **`discharge_capacity`** is the installed discharge rate (the curve's value at a full storage).
- **`level_capacity`** is the installed storage level capacity.
- **`c_rate_points_charge`** are the one to three `[level, rate]` anchor points of the charge
  curve, in ascending storage-level order.
- **`c_rate_points_discharge`** are the one to three `[level, rate]` anchor points of the
  discharge curve, in descending storage-level order.

!!! note "Plotting extension"
    `visualize_c_rates` is provided through a package extension that is only loaded once the
    `Plots` package is available. Run `using Plots` before calling this function. Without
    `Plots` loaded, calling it raises an informative error.
"""
function visualize_c_rates end
