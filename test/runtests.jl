using TestItemRunner
using EnergyModelsHeat
using PrettyTables

# Create a flag to detect if we are running in CI
is_ci::Bool = get(ENV, "CI", "false") == "true"

# Run all package tests, but skip those requiring EnergyModelsGUI in CI.
# Make sure to run these locally before push to GitHub.
# Locally, these tests can be run with:
# julia --project=. -e 'import Pkg; Pkg.add("EnergyModelsGUI"); Pkg.instantiate(); Pkg.test()'
@run_package_tests filter = ti -> !(is_ci && (:requires_emgui ∈ ti.tags))
