# EnergyModelsHeat

`EnergyModelsHeat` extends [EnergyModelsX](https://github.com/EnergyModelsX) with functionality to model heat flows and district heating network with improved technical descriptions.

The following types are introduced:

1. a `Resource` [`ResourceHeat`](@ref),
2. a `Link` [`DHPipe`](@ref),
3. a `NetworkNode` [`HeatPump`](@ref),
4. a `Storage` [`ThermalEnergyStorage`](@ref) and [`BoundRateTES`](@ref),
5. a utility type [`PinchData`](@ref), and
6. a `NetworkNode` [`HeatExchanger`](@ref).

The new introduced types are also documented in the *[public library](@ref lib-pub)* as well as the corresponding pages.

## [`ResourceHeat`](@ref resources-ResourceHeat)

Heat as a resource does not possess a CO₂ intensity when used.
Instead, it has as fields both the supply and return temperatures of heat utilized in a district heating network.

## [`DHPipe`](@ref links-DHPipe)

District heating pipes are a new subtype of links.
They include a capacity and a new variable for calculating the loss of the district heating network.
While the loss is independent of the transported energy in the current implementation, it may be possible to provide a nonlinear formulation for the pipe in a later stage.

## [`HeatPump`](@ref nodes-HeatPump)

Heat pumps are utilizing a driving force for transferring heat from a lower temperature to a higher temperature.
As a consequence, it requires changes to the input flow to the heat pump.
The input flow is now dependent on the temperature profile of the source and sink heats.

## [`ThermalEnergyStorage`](@ref nodes-TES)

Thermal energy storage differs from standard storage node as they experience a constant loss dependent on the storage volume and not the charging or discharging of the storage.
This change requires direct adjustments to the storage balance that cannot be incorporated in the variable ``\texttt{stor\_level\_Δ\_op}``.
The current implementation assumes a loss independent of the operational period.
As a consequence, it is assumed that the tempreature outside of the thermal energy storage does not change in the operational periods.

## [`HeatExchanger`](@ref nodes-HeatExchanger)

A lot of process produce surplus heat as a side stream.
The utilization of the heat is however limited by the fact that heat exchangers have a minimum temperature approach as design parameter to minimize the surface area.
This is accounted for in the heat exchanger node utilizing the concepts of `ResourceHeat`.

## Manual outline

```@contents
Pages = [
    "manual/quick-start.md",
    "manual/simple-example.md",
    "manual/NEWS.md",
]
Depth = 1
```

## Description of the resources

```@contents
Pages = [
    "resources/resourceheat.md",
]
Depth = 1
```

## Description of the links

```@contents
Pages = [
    "links/dhpipe.md",
]
Depth = 1
```

## Description of the nodes

```@contents
Pages = [
    "nodes/heatpump.md",
    "nodes/thermalenergystorage.md",
    "nodes/heatexchanger.md",
]
Depth = 1
```

## How to guides

```@contents
Pages = [
    "howto/simple_conversion.md",
    "howto/contribute.md",
]
Depth = 1
```

## Library outline

```@contents
Pages = [
    "library/public.md",
    "library/internals/types-EMH.md",
    "library/internals/methods-fields.md",
    "library/internals/methods-EMH.md",
    "library/internals/methods-EMB.md",
]
Depth = 1
```

## Background

```@contents
Pages = [
    "background/background.md",
]
Depth = 1
```

## Project Funding

The development of `EnergyModelsHeat` was funded by the Norwegian Research Council in the project [ZEESA](https://www.sintef.no/en/projects/2023/zeesa-zero-emission-energy-systems-for-the-arctic/), project number [336342](https://prosjektbanken.forskningsradet.no/project/FORISS/336342), as well as the European Union’s Horizon Europe research and innovation programme in the project [iDesignRES](https://idesignres.eu/) under grant agreement [101095849](https://doi.org/10.3030/101095849).
