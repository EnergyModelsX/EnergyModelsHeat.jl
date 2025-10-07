# [DHPipe](@id links-DHPipe)

[`DHPipe`](@ref) links model the transport of heat in the form of hot water or other fluid in heating networks.
The model the flow of energy from a source to a sink, that is we do not model a water/fluid with a given temperature and pressure.
The heat losses are calculated based on the supply temperature of the inflowing [`ResourceHeat`](@ref), together with the ground temperature, pipe length, and a heat loss coefficient.
Heat losses in the return flow are therefore ignored, following the approach from [KVALSVIK2018](@cite).
These heat losses are in general very small, and in any case much smaller than the losses in the supply pipes [DALLAROSA2011](@cite).
Losses in the return pipe can even be negative in twin pipes, as heat leaks from the supply to the return line.
Pressure losses are also excluded in the current version of the model; however, pressure losses and the required pumping power are in general very small compared to the heat supply (see, *e.g.*, [KAUKO2022](@cite)).

## [Introduced type and its fields](@id links-DHPipe-fields)

[`DHPipe`](@ref) is implemented as equivalent to an abstract type [`Link`](@extref EnergyModelsBase.Link).
Hence, it utilizes the same functions declared in `EnergyModelsBase`.

### [Standard fields](@id links-DHPipe-fields-stand)

[`DHPipe`](@ref) has the following standard fields, equivalent to a [`Direct`](@extref EnergyModelsBase.Direct) link:

- **`id`** :\
  The field `id` is only used for providing a name to the link.
- **`from::Node`** :\
  The node from which there is flow into the link.
- **`to::Node`** :\
  The node from which there is flow out of the link.
- **`formulation::Formulation`** :\
  The used formulation of links.
  If not specified, a `Linear` link is assumed.
  !!! note "Different formulations"
      The current implementation of links does not provide another formulation.
      Our aim is in a later stage to allow the user to switch fast through different formulations to increase or decrese the complexity of the model.

### [Additional fields](@id links-DHPipe-fields-new)

The following additional fields are included for [`DHPipe`](@ref) links:

- **`cap::TimeProfile`** :\
  The maximum heat transport capacity of the pipe.
  The value should be higer than the expected maximum heat demand for the load the given pipe segment is delivering heat to.
  If the link should contain investments through the application of [`EnergyModelsInvestments`](https://energymodelsx.github.io/EnergyModelsInvestments.jl/), it is important to note that you can only use `FixedProfile` or `StrategicProfile` for the capacity, but not `RepresentativeProfile` or `OperationalProfile`.
  In addition, all values have to be non-negative.
- **`pipe_length::Float64`** :\
  The pipe length.
  The unit for the pipe length is directly related to the field `pipe_loss_factor`.
  It is hence advised to utilize, *e.g.* m as length unit for both.
- **`pipe_loss_factor::Float64`** :\
  The heat loss factor from the fluid to the ground per meter pipe given in [W/(m K)], [kW/(m K)] or [MW/(m K)], depending on the applied unit for energy.
  Typical values for heat loss coefficient ($\lambda$) for the insulation in district heating pipes can be found at the website of the DH pipe manufacturer [LOGSTOR](https://www.logstor.com/district-heating/logstor-lab/lambda-values).
  The `pipe_loss_factor` applied in [`DHPipe`](@ref) is however an overall loss factor considering not just the insulation, but also the pipe geometry (see [KVALSVIK2018](@cite)).
  This loss factor is typically a factor of ten or more higher than the $\lambda$-values given in [LOGSTOR](https://www.logstor.com/district-heating/logstor-lab/lambda-values).
- **`t_ground::TimeProfile`** :\
  The ground temperature in °C.
  The gound temperature can be approximated with the ambient temperature.
- **`resource_heat::ResourceHeat`** :\
  The resource used by DHPipe, which has to be of type [`ResourceHeat`](@ref) and must be equal to a resource flowing out of a `to::Node` and into a `from::Node`.
  [`ResourceHeat`](@ref) contains the supply and (optionally) return temperature applied in the district heating network.
  The supply temperature is used in the calculation of the heat losses.

## [Mathematical description](@id links-DHPipe-math)

In the following mathematical equations, we use the name for variables and functions used in the model.
Variables are in general represented as

``\texttt{var\_example}[index_1, index_2]``

with square brackets, while functions are represented as

``func\_example(index_1, index_2)``

with paranthesis.

### [Variables](@id links-DHPipe-math-var)

#### [Standard variables](@id links-DHPipe-math-var-stand)

[`DHPipe`](@ref) utilizes standard variables from the [`Link`](@extref EnergyModelsBase.Link) type, as described on the page *[Optimization variables](@extref EnergyModelsBase man-opt_var)*.
The variables include:

- [``\texttt{link\_in}``](@extref man-opt_var-flow)
- [``\texttt{link\_out}``](@extref man-opt_var-flow)

Both variable sets only include the specified `resource_heat` as resource through new methods for [`inputs`](@ref EnergyModelsBase.inputs) and [`outputs`](@ref EnergyModelsBase.outputs).

In addition, [`DHPipe`](@ref) utilizes one of conditional variables for links:

- [``\texttt{link\_cap\_inst}``](@extref man-opt_var-cap)

#### [Additional variables](@id links-DHPipe-math-add)

It is an advantage to keep track of the heat losses in [`DHPipe`](@ref).
Hence, an additional variable is declared for heat loss through creating a new method for the function [`variables_link`](@extref EnergyModelsBase.variables_link):

- ``\texttt{dh\_pipe\_loss}[l, t]``: Heat loss in pipe segment ``l`` in operational period ``t`` with a typical unit of MW.\

It is assumed that the heat loss is constant, *i.e.*, independent of the amount of heat transported by the pipe.
Heat losses thus depend only on the pipe length, the supply and ground temperatures and the `pipe_loss_factor`, as shown by the constraint functions below.
This implies also that there is a heat loss even if there is no heat flowing through the pipe, but the water is standing still, which is the case also in practice.

It is advisable to check that the resulting relative heat loss is within an appropriate range (considering the size of the network and the supply temperature), and adjust the 'pipe_loss_factor' if needed.
Typical heat losses relative to the total heat demand are in the range 10-20 % for city-wide district heating networks, which can have a total length up to hundreds of kilometers; and 3-5 % for local DH networks, with a typical length of a few kilometers.

### [Constraints](@id links-DHPipe-math-con)

The constraint functions are called within the function [`create_link`](@ref EnergyModelsBase.create_link).
This includes both a standard constraint for [`Link`](@extref EnergyModelsBase.Link) and constraints related to the calculation of heat losses, given in the following.

The following sections omit the direct inclusion of the vector of district heating pipes.
Instead, it is implicitly assumed that the constraints are valid ``\forall l ∈ L^{DHPipe}`` for all [`DHPipe`](@ref) types if not stated differently.
In addition, all constraints are valid ``\forall t \in T`` (that is in all operational periods) or ``\forall t_{inv} \in T^{Inv}`` (that is in all strategic periods).

#### [Standard constraints](@id links-DHPipe-math-con-stand)

The applied standard constraint is `constraints_capacity_installed`:

```math
\texttt{link\_cap\_inst}[l, t] = capacity(l, t)
```

#### [Additional constraints](@id links-DHPipe-math-con-add)

All additional constraints are created within a new method for the function [`create_link`](@extref EnergyModelsBase.create_link).

The calculation of the heat losses is included through the relationship between the flow into and out from the link

```math
\texttt{flow\_out}[l, t, resource\_heat(l)] = \texttt{flow\_in}[l, t, resource\_heat(l)] - \texttt{dh\_pipe\_loss}[l, t]
```

as well as the direct loss

```math
\texttt{dh\_pipe\_loss}[l, t] = pipe\_length(l) \times pipe\_loss\_factor(l) \times (t_{supply}(l) - t_{ground}(l))
```

In addition, the heat energy flowing in to the pipe should not exceed the maximum pipe capacity, which is included through the following constraint:

```math
\texttt{flow\_in}[l, t, resource\_heat(l)] \leq \texttt{link\_cap\_inst}[l, t]
```

!!! warning "Heat loss"
    To make sure that the amount of heat flowing out of the pipe does not become negative, the heat losses occurring in the pipe should not be higher than the amount of heat entering the pipe, *i.e.*:

    ```math
    \texttt{flow\_in}[l, t, resource\_heat(l)] > \texttt{dh\_pipe\_loss}[l, t]
    ```
