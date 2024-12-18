# [Quick Start](@id man-quick_start)

1. Install the most recent version of [Julia](https://julialang.org/downloads/)
2. Install the package [`EnergyModelsBase`](https://energymodelsx.github.io/EnergyModelsBase.jl/) and the time package [`TimeStruct`](https://sintefore.github.io/TimeStruct.jl/), by running:

   ```julia
   ] add TimeStruct
   ] add EnergyModelsBase
   ```

   These packages are required as we do not only use them internally, but also for building a model.
3. Install the package [`EnergyModelsHeat`](https://energymodelsx.github.io/EnergyModelsHeat.jl/)

   ```julia
   ] add EnergyModelsHeat
   ```

You also have to install a solver for solving the optimization problem.
In either case, you have to

1. Install [JuMP](https://github.com/jump-dev/JuMP.jl/) by running:

   ```julia
   ] add JuMP
   ```

2. Install your chosen solver, *e.g.*, *[HiGHS](https://github.com/jump-dev/HiGHS.jl)* and *[Gurobi](https://github.com/jump-dev/Gurobi.jl)*, by running:

   ```julia
   ] add HiGHS
   ] add Gurobi
   ```

You may, depending on your operating system, also have to locally install the solver in addition as explained in the corresponding README file.

!!! tip "JuMP and solver"
    While JuMP is automatically installed when you add `EnergyModelsBase`, it is still necessary to load it to optimize a model or extract the results.
    It is hence necessary to load it in each model run explicitly.

    `EnergyModelsX` models are in general agnostic towards which solver is used.
    They are hence not automatically included.
    Therefore, they require you to explicitly load the corresponding solver.
