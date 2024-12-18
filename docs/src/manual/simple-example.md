# [Examples](@id man-exampl)

For the content of the example, see the *[examples](https://github.com/EnergyModelsX/EnergyModelsHeat.jl/tree/main/examples)* directory in the project repository.

## The package is installed with `] add`

From the Julia REPL, run

```julia
# Starts the Julia REPL
julia> using EnergyModelsHeat
# Get the path of the examples directory
julia> exdir = joinpath(pkgdir(EnergyModelsHeat), "examples")
# Include the code into the Julia REPL to run the district heating example
julia> include(joinpath(exdir, "district_heating.jl"))
```

## The code was downloaded with `git clone`

The examples can then be run from the terminal with

```shell script
/path/to/EnergyModelsHeat.jl/examples $ julia district_heating.jl
```
