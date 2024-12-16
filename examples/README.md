# Running the examples

You have to add the package `EnergyModelsHeat` to your current project in order to run the example.
It is not necessary to add the other used packages, as the example is instantiating itself.
How to add packages is explained in the *[Quick start](https://energymodelsx.github.io/EnergyModelsHeat.jl/stable/manual/quick-start/)* of the documentation.

You can run from the Julia REPL the following code:

```julia
# Import EnergyModelsHeat
using EnergyModelsHeat

# Get the path of the examples directory
exdir = joinpath(pkgdir(EnergyModelsHeat), "examples")

# Include the following code into the Julia REPL to run the low temperature district heating example
include(joinpath(exdir, "district_heating.jl"))
```
