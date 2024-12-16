
# [HeatPump](@id nodes-HeatPump)

The [`HeatPump`](@ref) node models a technology that converts low-temperature heat into higher-temperature heat using an exergy driving force.
The most common form of exergy driving force is electricity, but the same node could be used to model heat-driven heat pumps, where the exergy input comes in the form of high temperature heat.
For simplicity, the term "electricity" is used to represent the exergy driving force in the following.
The [`HeatPump`](@ref) node supports dynamic coefficients of performance (COP) based on the source and sink temperatures and Carnot efficiency.
The Carnot efficiency describes the ratio of the theoretical maximum achievable COP (Carnot COP), which is based solely on the temperature lift between the source and sink temperature, and the actual COP.
This allows for a straightforward calculation of the relation between heat and electricity input.
While the Carnot efficiency in practice depends on several factors beyond the source and sink temperatures and is typically not constant across all operating conditions, it is provided here as an exogenous parameter by the user in the form of a `TimeProfile`.
The user can analyze the sink and source temperature profiles and can predetermine a theoretical Carnot efficiency profile based on that.
A lower capacity bound can be defined, restricting how much the heat pump can be regulated down.

## [Introduced type and its fields](@id nodes-HeatPump-fields)

The [`HeatPump`](@ref) is a subtype of the [`NetworkNode`](@extref EnergyModelsBase.NetworkNode). It uses the same functions as `NetworkNode` in `EnergyModelsBase`.

### [Standard fields](@id nodes-HeatPump-fields-stand)

- **`id`**:\
  The field `id` is only used for providing a name to the node.
  This is similar to the approach utilized in `EnergyModelsBase`.

- **`cap::TimeProfile`**:\
  Specifies the installed heating capacity, that is the heat the heat pump can deliver.\
  If the node should contain investments through the application of [`EnergyModelsInvestments`](https://energymodelsx.github.io/EnergyModelsInvestments.jl/stable/), it is important to note that you can only use `FixedProfile` or `StrategicProfile` for the capacity, but not `RepresentativeProfile` or `OperationalProfile`.\
  In addition, all values have to be non-negative.

- **`opex_var::TimeProfile`**:\
  The variable operational expenses are based on the capacity utilization through the variable [`:cap_use`](@extref EnergyModelsBase man-opt_var-cap).
  Hence, it is directly related to the specified `output` ratios.
  The variable operating expenses can be provided as `OperationalProfile` as well.

- **`opex_fixed::TimeProfile`**:\
  The fixed operating expenses are relative to the installed capacity (through the field `cap`) and the chosen duration of a strategic period as outlined on *[Utilize `TimeStruct`](@extref EnergyModelsBase how_to-utilize_TS)*.\
  It is important to note that you can only use `FixedProfile` or `StrategicProfile` for the fixed OPEX, but not `RepresentativeProfile` or `OperationalProfile`.
  In addition, all values have to be non-negative.

- **`output::Dict{<:Resource, <:Real}`**:\
  The field `output` includes the output [`Resource`](@extref EnergyModelsBase.Resource)s with their corresponding conversion factors as dictionaries.
  In the case of a heat pump, `output` should always include the *heat* resource used within the energy system.
  The value of the *heat* resource is in general 1.
  It is also possible to include other resources which are produced with a given correlation with the heat.\
  All values have to be non-negative.

- **`data::Vector{Data}`**:\
  An entry for providing additional data to the model.
  In the current version, it is only relevant for additional investment data when [`EnergyModelsInvestments`](https://energymodelsx.github.io/EnergyModelsInvestments.jl/) is used or for additional emission data through [`EmissionsProcess`](@extref EnergyModelsBase.EmissionsProcess).
  The latter would correspond to uncaptured CO₂ that should be included in the analyses.
  !!! note
      The field `data` is not required as we include a constructor when the value is excluded.

### [New fields](@id nodes-HeatPump-fields-new)

- **`cap_lower_bound::Real`**:\
  The lower bound for the capacity is the minimum operating point of the `HeatPump`.
  It can be included for limiting the flexibility of the heat pump.

  !!! warning "Lower capacity bound"
      The current implementation requires that the heat pump operates in all operational periods if `cap_lower_bound > 0`.

- **`t_source::TimeProfile`**:\
  The source temperature is the temperature of the source in °C.
  This temperature represents the temperature at which the heat pump absorbs heat, *e.g.*, the air temperature.
  The used heat is given by the field `input_heat`.

- **`t_sink::TimeProfile`**:\
  The sink temperature is the temperature at which the heat pump delivers heat in °C.
  It is directly related to the temperature of the `output` resource corresponding to heat.

- **`eff_carnot::TimeProfile`**:\
  The Carnot efficiency is the ratio bnbetween the real and the Carnot COP, and hence, the relation between the maximum theoretical efficiency and the real efficiency of the heat pump.
  The effective Carnot efficiency depends on the specific heat pump model as well as its operational conditions.

  !!! info "Usage dependent efficiencies"
      The capacity use cannot be included as an influencing factor on the Carnot efficiency as it is implemented as an optimization variable.
      This would then result in a bilinear term of a piecewise linear representation and a continuous variable.
      However, the user can utilize the known temperature lifts to adjust the Carnot efficiency profile according to the technical specifications of the heat pump.

- **`input_heat::Resource`**:\
  The heat input resource corresponds to the lower temperature heat reservoir from which heat is transfered to a higher temperature.
  In most approaches, the input_heat is corresponding to the surrounding (*e.g.*, the air), but it can also correspond to a lower temperature water stream.

- **`driving_force:Resource`**:\
  The driving force resource provides the energy for transfering the heat from the lower temperature (given by `t_source`) to the higher temperature (given by `t_sink`).
  The driving force is in general electricity.

### [Mathematical description](@id nodes-HeatPump-math)

In the following mathematical equations, we use the name for variables and functions used in the model.
Variables are in general represented as

``\texttt{var\_example}[index_1, index_2]``

with square brackets, while functions are represented as

``func\_example(index_1, index_2)``

with paranthesis.

#### [Variables](@id nodes-HeatPump-math-var)

The [`HeatPump`](@ref) node uses standard `NetworkNode` variables, as described on the page *[Optimization variables](@extref EnergyModelsBase man-opt_var)*.
The variables include:

- [``\texttt{opex\_var}``](@extref EnergyModelsBase man-opt_var-opex)
- [``\texttt{opex\_fixed}``](@extref EnergyModelsBase man-opt_var-opex)
- [``\texttt{cap\_use}``](@extref EnergyModelsBase man-opt_var-cap)
- [``\texttt{cap\_inst}``](@extref EnergyModelsBase man-opt_var-cap)
- [``\texttt{flow\_in}``](@extref EnergyModelsBase man-opt_var-flow)
- [``\texttt{flow\_out}``](@extref EnergyModelsBase man-opt_var-flow)

#### [Constraints](@id nodes-HeatPump-math-con)

The following sections omit the direct inclusion of the vector of heat pump nodes.
Instead, it is implicitly assumed that the constraints are valid ``\forall n ∈ N^{HeatPump}`` for all [`HeatPump`](@ref) types if not stated differently.
In addition, all constraints are valid ``\forall t \in T`` (that is in all operational periods) or ``\forall t_{inv} \in T^{Inv}`` (that is in all strategic periods).

##### [Standard constraints](@id nodes-HeatPump-math-con-stand)

Heat pump nodes utilize in general the standard constraints described on *[Constraint functions](@extref EnergyModelsBase man-con)* for `NetworkNode`s.
These standard constraints are:

- `constraints_capacity_installed`:

  ```math
  \texttt{cap\_inst}[n, t] = capacity(n, t)
  ```

  !!! tip "Using investments"
      The function `constraints_capacity_installed` is also used in [`EnergyModelsInvestments`](https://energymodelsx.github.io/EnergyModelsInvestments.jl/) to incorporate the potential for investment.
      Nodes with investments are then no longer constrained by the parameter capacity.

- `constraints_flow_out`:

  ```math
  \texttt{flow\_out}[n, t, p] =
  outputs(n, p) \times \texttt{cap\_use}[n, t]
  \qquad \forall p \in outputs(n) \setminus \{\text{CO}_2\}
  ```

- `constraints_opex_fixed`:

  ```math
  \texttt{opex\_fixed}[n, t_{inv}] = opex\_fixed(n, t_{inv}) \times \texttt{cap\_inst}[n, first(t_{inv})]
  ```

  !!! tip "Why do we use `first()`"
      The variable ``\texttt{cap\_inst}`` is declared over all operational periods (see the section on *[Capacity variables](@extref EnergyModelsBase man-opt_var-cap)* for further explanations).
      Hence, we use the function ``first(t_{inv})`` to retrieve the installed capacity in the first operational period of a given strategic period ``t_{inv}`` in the function `constraints_opex_fixed`.

- `constraints_opex_var`:

  ```math
  \texttt{opex\_var}[n, t_{inv}] = \sum_{t \in t_{inv}} opex\_var(n, t) \times \texttt{cap\_use}[n, t] \times scale\_op\_sp(t_{inv}, t)
  ```

  !!! tip "The function `scale_op_sp`"
      The function [``scale\_op\_sp(t_{inv}, t)``](@extref EnergyModelsBase.scale_op_sp) calculates the scaling factor between operational and strategic periods.
      It also takes into account potential operational scenarios and their probability as well as representative periods.

The `constraints_capacity` function is extended by implementing the lower capacity bound to limit the lowest possible capacity use:

```math
\texttt{cap\_use}[n, t] \geq cap\_lower\_bound(n) \times \texttt{cap\_inst}[n, t]
```

The original constraints limiting the capacity to the installed capacity:

```math
\texttt{cap\_use}[n, t] \leq \texttt{cap\_inst}[n, t]
```

and calling the subfunction `constraints_capacity_installed` to provide bounds for the variable ``\texttt{cap\_inst}[n, t]`` are still called within the function.

The input flow constraint for a [`HeatPump`](@ref) node is calculated differently to a [`NetworkNode`](@extref EnergyModelsBase.NetworkNode) as the relationship between `heat_in_resource` and `driving_force_resource` is reflecting the COP of the heat pump.
Since the input resources are specified via the fields `heat_in_resource` and `driving_force_resource`, and the conversion factors are calculated seperately, the field `inputs` is not required. 
The determination of conversion factors is achieved by extending the `constraints_flow_in` function, separating the calculation for the input flow of heat source and driving force.
All temperatures are specified in degree Celsius, so the values must be converted into Kelvin by adding 273.15 °C.

Given a heat resource ``p_{heat} = heat\_in\_resource(n)``, we can calculate the heat input as:

```math
\begin{aligned}
\texttt{flow\_in}&[n, t, p_{heat}] =
  \texttt{cap\_use}[n, t] \times  \\ &
  \left( 1 - \frac{t\_sink(n, t) - t\_source(n, t)}{eff\_carnot(n,t) \times (t\_sink(n, t) + 273.15)} \right)
\end{aligned}
```

The input for the ``p_{df} = driving\_force\_resource(n)``

```math
\begin{aligned}
\texttt{flow\_in}&[n, t, p_{df}] =
  \texttt{cap\_use}[n, t] \times \\ &
  \frac{t\_sink(n, t) - t\_source(n, t)}{eff\_carnot(n,t) \times (t\_sink(n, t) + 273.15)}
\end{aligned}
```

##### [Additional constraints](@id nodes-HeatPump-math-con-add)

[`HeatPump`](@ref) nodes do not add additional constraint functions or constraints in the `create_node` function.
