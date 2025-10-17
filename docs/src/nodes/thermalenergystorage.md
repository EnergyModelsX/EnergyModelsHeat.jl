
# [ThermalEnergyStorage nodes](@id nodes-TES)

Thermal energy storage nodes work mostly like a [`RefStorage`](@extref EnergyModelsBase.RefStorage) with the additional option to include thermal energy losses.
Heat losses are quantified through a heat loss factor that describes the amount of thermal energy that is lost in relation to the storage level of the respective operational period.
The main difference to `RefStorage` is that these heat losses occur independently of the storage use, *i.e.*, in every operational period unless the storage level is zero.
In practice, this approach with a constant relative heat loss factor does not accurately represent heat loss mechanisms based on temperature difference between the inside and outside of the TES.
However, it is a reasonable approximation that at least reflects the dependence of the SOC on the absolute losses of the storage.
Additionally, thermal energy storage nodes allow for the definition of both charge and discharge rate. 

!!! danger "StorageBehavior for ThermalEnergyStorage"
    Thermal energy storage nodes can only utilize [`Cyclic`](@extref EnergyModelsBase.Cyclic) storage behaviors.
    When using `RepresentativePeriods`, this is furthermore reduced to[`CyclicRepresentative`](@extref EnergyModelsBase.CyclicRepresentative).
    The reason for this limitation is that we have not yet implemented heat losses over a representative period.

## [Introduced type and its fields](@id nodes-TES-fields)

[`ThermalEnergyStorage`](@ref) is similar to a [`RefStorage`](@extref EnergyModelsBase.RefStorage), with the addition of discharge rate limitations and heat losses.  
[`FixedRateTES`](@ref) serves the same fundamental purpose as [`ThermalEnergyStorage`](@ref), but its charge and discharge rates are defined relative to the installed storage capacity. This offers an advantage in an [`InvestmentModel`](@extref EnergyModelsBase.InvestmentModel), as it allows a fixed ratio between storage capacity and (dis-)charge rate to be maintained when scaling the storage size. In contrast, [`ThermalEnergyStorage`](@ref) allows the (dis-)charge capacities to be scaled independently of the storage capacity.

### [Standard fields](@id nodes-TES-fields-stand)

The standard fields are given as:

- **`id`** :\
  The field `id` is only used for providing a name to the storage.
  This is similar to the approach utilized in `EnergyModelsBase`.

- **`level::UnionCapacity`** :\
  The level parameters of the thermal energy storage node.
  The level storage parameters must include a capacity.
  Depending on the chosen type, the level parameters can include in addition variable OPEX and/or fixed OPEX.
  More information can be found on *[storage parameters](@extref EnergyModelsBase lib-pub-nodes-stor_par)*.
  !!! note "Permitted values for storage parameters in `level`"
      If the node should contain investments through the application of [`EnergyModelsInvestments`](https://energymodelsx.github.io/EnergyModelsInvestments.jl/), it is important to note that you can only use `FixedProfile` or `StrategicProfile` for the capacity, but not `RepresentativeProfile` or `OperationalProfile`.
      Similarly, you can only use `FixedProfile` or `StrategicProfile` for the fixed OPEX, but not `RepresentativeProfile` or `OperationalProfile`.
      The variable operating expenses can be provided as `OperationalProfile` as well.
      In addition, all capacity and fixed OPEX values have to be non-negative.

- **`stor_res::Resource`** :\
  The `stor_res` is the stored [`Resource`](@extref EnergyModelsBase.Resource).
  In the case of a `ThermalEnergyStorage`, this resource should be a [`ResourceHeat`](@ref).

- **`input::Dict{<:Resource,<:Real}`** and **`output::Dict{<:Resource,<:Real}`**:\
  Both fields describe the `input` and `output` [`Resource`](@extref EnergyModelsBase.Resource)s with their corresponding conversion factors as dictionaries.
  All values have to be non-negative.
  !!! info "Conversion factors"
      While the field input includes a proper conversion factor and may allow for multiple resources, the value of the `output` [`Resource`](@extref EnergyModelsBase.Resource)s is not relevant.

- **`data::Vector{<:ExtensionData}`** :\
  An entry for providing additional data to the model.
  In the current version, it is used for providing additional investment data when [`EnergyModelsInvestments`](https://energymodelsx.github.io/EnergyModelsInvestments.jl/) is used.
  !!! note
      The field `data` is not required as we include a constructor when the value is excluded.

### [Additional fields](@id nodes-TES-fields-new)

Both [`ThermalEnergyStorage`](@ref) and [`FixedRateTES`](@ref) nodes introduce an additional field for the heat loss factor:

- **`heat_loss_factor::Float64`** :\
  The heat loss factor describes the heat lost relative to the storage level.  
  It corresponds to the loss occurring between two operational periods for a given operational duration of 1 (see *[Utilize `TimeStruct`](@extref EnergyModelsBase how_to-utilize_TS)* for details).

The charging and discharging rates are specified in two different ways:  

[`ThermalEnergyStorage`](@ref) nodes use the same field for charging capacity as [`RefStorage`](@extref EnergyModelsBase.RefStorage) nodes, and extend it by adding a field for discharging:

- **`charge::AbstractStorageParameters`** and **`discharge::AbstractStorageParameters`** :\
  The charging and discharging parameters of the `ThermalEnergyStorage`.  
  Depending on the chosen type, these parameters can include variable OPEX, fixed OPEX, and/or capacity.  
  More information can be found in *[storage parameters](@extref EnergyModelsBase lib-pub-nodes-stor_par)*.
  !!! note "When not specifying a discharge rate"
      The field `discharge` is not required as we include a constructor when the value is excluded. In that case, the discharging rate is set to the same value as the charging rate.

For [`FixedRateTES`](@ref), two additional fields specify the charging and discharging rates relative to the installed storage capacity:

- **`level_charge::AbstractStorageParameters`** and **`level_discharge::AbstractStorageParameters`** :\
  The fixed charging and discharging rates of the `FixedRateTES` relative to the installed storage capacity.  
  `level_charge` = charging rate / installed storage level  \
  `level_discharge` = discharging rate / installed storage level

## [Mathematical description](@id nodes-TES-math)

In the following mathematical equations, we use the name for variables and functions used in the model.
Variables are in general represented as

``\texttt{var\_example}[index_1, index_2]``

with square brackets, while functions are represented as

``func\_example(index_1, index_2)``

with paranthesis.

### [Variables](@id nodes-TES-math-var)

The [`ThermalEnergyStorage`](@ref) utilizes all standard variables from [`RefStorage`](@extref EnergyModelsBase.RefStorage), as described on the page *[Optimization variables](@extref EnergyModelsBase man-opt_var)*:

- [``\texttt{opex\_var}``](@extref EnergyModelsBase man-opt_var-opex)
- [``\texttt{opex\_fixed}``](@extref EnergyModelsBase man-opt_var-opex)
- [``\texttt{stor\_level}``](@extref EnergyModelsBase man-opt_var-cap)
- [``\texttt{stor\_level\_inst}``](@extref EnergyModelsBase man-opt_var-cap)
- [``\texttt{stor\_charge\_use}``](@extref EnergyModelsBase man-opt_var-cap)
- [``\texttt{stor\_charge\_inst}``](@extref EnergyModelsBase man-opt_var-cap) if the `ThermalEnergyStorage` has the field `charge` with a capacity
- [``\texttt{stor\_discharge\_use}``](@extref EnergyModelsBase man-opt_var-cap)
- [``\texttt{stor\_discharge\_inst}``](@extref EnergyModelsBase man-opt_var-cap) if the `ThermalEnergyStorage` has the field `discharge` with a capacity
- [``\texttt{flow\_in}``](@extref EnergyModelsBase man-opt_var-flow)
- [``\texttt{flow\_out}``](@extref EnergyModelsBase man-opt_var-flow)
- [``\texttt{stor\_level\_Δ\_op}``](@extref EnergyModelsBase man-opt_var-cap)
- [``\texttt{stor\_level\_Δ\_rp}``](@extref EnergyModelsBase man-opt_var-cap) if the `TimeStruct` includes `RepresentativePeriods`

### [Constraints](@id nodes-TES-math-con)

[`ThermalEnergyStorage`](@ref) and [`FixedRateTES`](@ref) nodes utilize in general the standard constraints described in *[Constraint functions for `Storage` nodes](@extref EnergyModelsBase nodes-storage-math-con)*.
[`ThermalEnergyStorage`](@ref) and [`FixedRateTES`](@ref) nodes utilize the declared method for all nodes 𝒩.
 The following standard constraints are implemented for [`ThermalEnergyStorage`](@ref) and [`FixedRateTES`](@ref) nodes.

- `constraints_capacity`:

  For [`ThermalEnergyStorage`](@ref)

  ```math
  \begin{aligned}
  \texttt{stor\_level\_use}[n, t] & ≤ \texttt{stor\_level\_inst}[n, t] \\
  \texttt{stor\_charge\_use}[n, t] & ≤ \texttt{stor\_charge\_inst}[n, t] \\
  \texttt{stor\_discharge\_use}[n, t] & ≤ \texttt{stor\_discharge\_inst}[n, t]
  \end{aligned}
  ```

  For [`FixedRateTES`](@ref)

  ```math
  \begin{aligned}
  \texttt{stor\_level\_use}[n, t] & ≤ \texttt{stor\_level\_inst}[n, t] \\
  \texttt{stor\_charge\_use}[n, t] & ≤ \texttt{stor\_level\_inst}[n, t] \times level\_charge(n) \\
  \texttt{stor\_discharge\_use}[n, t] & ≤ \texttt{stor\_level\_inst}[n, t] \times level\_discharge(n) \\
  \end{aligned}
  ```

- `constraints_capacity_installed`:

  For [`ThermalEnergyStorage`](@ref)

  ```math
  \begin{aligned}
  \texttt{stor\_level\_inst}[n, t] & = capacity(level(n), t) \\
  \texttt{stor\_charge\_inst}[n, t] & = capacity(charge(n), t) \\
  \texttt{stor\_discharge\_inst}[n, t] & = capacity(discharge(n), t) 
  \end{aligned}
  ```

  For [`FixedRateTES`](@ref)

  ```math
  \begin{aligned}
  \texttt{stor\_level\_inst}[n, t] & = capacity(level(n), t)
  \end{aligned}
  ```

  !!! tip "Using investments"
      The function `constraints_capacity_installed` is also used in [`EnergyModelsInvestments`](https://energymodelsx.github.io/EnergyModelsInvestments.jl/) to incorporate the potential for investment.
      Nodes with investments are then no longer constrained by the parameter capacity.

- `constraints_flow_in`:\
  
  The auxiliary resource constraints are independent of the chosen storage behavior:

  ```math
  \texttt{flow\_in}[n, t, p] = inputs(n, p) \times \texttt{flow\_in}[n, stor\_res(n)]
  \qquad \forall p \in inputs(n) \setminus \{stor\_res(n)\}
  ```

  The stored resource constraints do not include an efficiency:

  ```math
  \texttt{flow\_in}[n, t, stor\_res(n)] = \texttt{stor\_charge\_use}[n, t]
  ```

- `constraints_flow_out`:

  ```math
  \texttt{flow\_out}[n, t, stor\_res(n)] = \texttt{stor\_discharge\_use}[n, t]
  ```

- `constraints_level`:\
  The level constraints are more complex compared to the standard constraints.
  They are explained in detail below in *[Level constraints](@extref EnergyModelsBase nodes-storage-math-con-level)*.

- `constraints_opex_fixed`:

  ```math
  \begin{aligned}
  \texttt{opex\_fixed}&[n, t_{inv}] = \\ &
    opex\_fixed(level(n), t_{inv}) \times \texttt{stor\_level\_inst}[n, first(t_{inv})] + \\ &
    opex\_fixed(charge(n), t_{inv}) \times \texttt{stor\_charge\_inst}[n, first(t_{inv})] + \\ &
    opex\_fixed(discharge(n), t_{inv}) \times \texttt{stor\_discharge\_inst}[n, first(t_{inv})]
  \end{aligned}
  ```

  !!! tip "Why do we use `first()`"
      The variables ``\texttt{stor\_level\_inst}`` are declared over all operational periods (see the section on *[Capacity variables](@extref EnergyModelsBase man-opt_var-cap)* for further explanations).
      Hence, we use the function ``first(t_{inv})`` to retrieve the installed capacities in the first operational period of a given strategic period ``t_{inv}`` in the function `constraints_opex_fixed`.

- `constraints_opex_var`:

  ```math
  \begin{aligned}
  \texttt{opex\_var}&[n, t_{inv}] = \\ \sum_{t \in t_{inv}}&
    opex\_var(level(n), t) \times \texttt{stor\_level}[n, t] \times scale\_op\_sp(t_{inv}, t) + \\ &
    opex\_var(charge(n), t) \times \texttt{stor\_charge\_use}[n, t] \times scale\_op\_sp(t_{inv}, t)
  \end{aligned}
  ```

  !!! tip "The function `scale_op_sp`"
      The function [``scale\_op\_sp(t_{inv}, t)``](@extref EnergyModelsBase.scale_op_sp) calculates the scaling factor between operational and strategic periods.
      It also takes into account potential operational scenarios and their probability as well as representative periods.

- `constraints_ext_data`:\
  This function is only called for specified data of the storage node, see above.

!!! info "Implementation of capacity and OPEX"
    The capacity constraints, both `constraints_capacity` and `constraints_capacity_installed` are only set for capacities that are included through the corresponding field and if the corresponding *[storage parameters](@extref EnergyModelsBase lib-pub-nodes-stor_par)* have a field `capacity`.
    Otherwise, they are omitted.
    The field `level` is required to have a storage parameter with capacity.

#### [Level constraints](@id nodes-TES-math-con-level)

The overall structure is outlined on *[Constraint functions](@extref EnergyModelsBase man-con-stor_level)*.
The level constraints are called through the function `constraints_level` which then calls additional functions depending on the chosen time structure (whether it includes representative periods and/or operational scenarios) and the chosen *[storage behaviour](@extref EnergyModelsBase lib-pub-nodes-stor_behav)*. Note: [`ThermalEnergyStorage`](@ref) and [`FixedRateTES`](@ref) only make changes to the `constraint_level_iterate`function when [`CyclicStrategic`](@extref EnergyModelsBase.CyclicStrategic) is chosen as storage behaviour.

The constraints introduced in `constraints_level_aux` are given by

```math
\texttt{stor\_level\_Δ\_op}[n, t] = \texttt{stor\_charge\_use}[n, t] - \texttt{stor\_discharge\_use}[n, t]
```

If the time structure includes representative periods, we calculate the change of the storage level in each representative period within the function `constraints_level_iterate`:

```math
\texttt{stor\_level\_Δ\_rp}[n, t_{rp}] = \sum_{t \in t_{rp}}
\texttt{stor\_level\_Δ\_op}[n, t] \times scale\_op\_sp(t_{rp}, t)
```

In the case of [`CyclicStrategic`](@extref EnergyModelsBase.CyclicStrategic), we add an additional constraint to the change in the function `constraints_level_rp`:

```math
\sum_{t_{rp} \in T^{rp}} \texttt{stor\_level\_Δ\_rp}[n, t_{rp}] = 0
```

while we fix the value in the case of [`CyclicRepresentative`](@extref EnergyModelsBase.CyclicRepresentative) to 0:

```math
\texttt{stor\_level\_Δ\_rp}[n, t_{rp}] = 0
```

If the time structure includes operational scenarios using [`CyclicRepresentative`](@extref EnergyModelsBase.CyclicRepresentative), we enforce that the last value in each operational scenario is the same within the function `constraints_level_scp`.

The general level constraint is eventually calculated in the function `constraints_level_iterate`:

```math
\texttt{stor\_level}[n, t] = prev\_level +
\texttt{stor\_level\_Δ\_op}[n, t] \times duration(t) -
prev\_level \times heat\_loss\_factor(n) \times duration(t)
```

in which the value ``prev\_level`` is depending on the type of the previous operational (``t_{prev}``) and strategic level (``t_{inv,prev}``) (as well as the previous representative period (``t_{rp,prev}``)).
It is calculated through the function `previous_level`.

!!! tip "Changes in ThermalEnergyStorage"
    This constraint is the only constraint adjusted by [`ThermalEnergyStorage`] nodes.
    All other functions and constraints are unchanged.

We can distinguish the following cases:

1. The first operational period (in the first representative period) in a strategic period (given by ``typeof(t_{prev}) = typeof(t_{rp, prev}) = = nothing``).
   In this situation, the previous level is dependent on the chosen storage behavior.
   In the default case of a [`Cyclic`](@extref EnergyModelsBase.Cyclic) behaviors, it is given by the last operational period of either the strategic or representative period:

   ```math
   \begin{aligned}
     prev\_level & = \texttt{stor\_level}[n, last(t_{sp})]
     prev\_level & = \texttt{stor\_level}[n, last(t_{rp})]
   \end{aligned}
   ```

   If the storage behavior is instead given by [`CyclicStrategic`](@extref EnergyModelsBase.CyclicStrategic) and the time structure includes representative periods, we calculate the previous level instead as:

   ```math
   \begin{aligned}
   t_{rp,last}  = & last(repr\_periods(t_{sp})) \\
   prev\_level = & \texttt{stor\_level}[n, first(t_{rp,last})] - \\ &
     \texttt{stor\_level\_Δ\_op}[n, first(t_{rp,last})] \times duration(first(t_{rp,last})) + \\ &
     \texttt{stor\_level\_Δ\_rp}[n, t_{rp,last}]
   \end{aligned}
   ```

   ``t_{rp,last}`` corresponds in this situation to the last representative period in the current strategic period.

   If the storage behavior is instead given by [`CyclicStrategic`](@extref EnergyModelsBase.CyclicStrategic), the previous level is set to 0:

   ```math
   prev\_level = 0
   ```

2. The first operational period in subsequent representative periods in any strategic period (given by ``typeof(t_{prev}) = nothing``).
   The previous level is again dependent on the chosen storage behavior.
   The default approach calculates it as:

   ```math
   \begin{aligned}
    prev\_level = & \texttt{stor\_level}[n, first(t_{rp,prev})] - \\ &
      \texttt{stor\_level\_Δ\_op}[n, first(t_{rp,prev})] \times duration(first(t_{rp,prev})) + \\ &
      \texttt{stor\_level\_Δ\_rp}[n, t_{rp,prev}]
   \end{aligned}
   ```

   while a [`CyclicRepresentative`](@extref EnergyModelsBase.CyclicRepresentative) storage behavior calculates it as:

   ```math
   prev\_level = \texttt{stor\_level}[n, last(t_{rp})]
   ```

   This situation only occurs in cases in which the time structure includes representative periods.

3. All other operational periods:\

   ```math
    prev\_level = \texttt{stor\_level}[n, t_{prev}]
   ```
