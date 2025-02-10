# Release Notes

## Unversioned

* Adjusted to [`EnergyModelsBase` v0.9.0](https://github.com/EnergyModelsX/EnergyModelsBase.jl/releases/tag/v0.9.0):
  * Increased version nubmer for EMB.
  * Model worked without adjustments.
  * Adjustments only required for simple understanding of changes.
* Included updated `DHPipe`:
  * `DHPIpe` now follow a check.
  * The arguments for `create_link` were updated.

## Version 0.1.0 (2024-12-18)

Initial version of the heat package within the [EnergyModelsX](https://github.com/EnergyModelsX) framework.

### Heat Pump

* Developed a new `HeatPump` node based on `RefNetworkNode`.
* Incorporates constraints on the input flow of a heat source and a driving force (electricity).
* The underlying COP calculation is based on given profiles for sink and source temperature as well as a Carnot efficiency.

### Thermal Energy Storage

* Developed a `ThermalEnergyStorage` node.
* Includes heat losses calculated by a given heat loss factor and the storage level of the previous time period.

### District Heating Pipe

* Developed a new type of link called `DHPipe`.
* Incorporates a constant absolute heat loss between the input and the output of the link based on district heating temperature, ground temperature, pipe lenght and heat loss factor.
* Requires a capacity and allows for investments.

### HeatExchanger nodes

* Developed a `HeatExchanger` node as parametric type.
* The node can be used in combination with `ResourceHeat` for automatic calculation of the achievable energy recovery.
