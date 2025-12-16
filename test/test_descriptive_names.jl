if get(ENV, "CI", "false") == "true"
    # skip GUI-related imports/tests until Makie enables headless CI runs for windows
else
    @testitem "Test existence of descriptive names for EnergyModelsHeat" begin
        using EnergyModelsGUI

        # Check that no descriptive names are empty for types
        descriptive_names = create_descriptive_names()
        types_map = get_descriptive_names(EnergyModelsHeat, descriptive_names)
        @test !any(any(isempty.(values(a))) for a ∈ values(types_map))
    end

    @testitem "Test descriptive names for DHPipe model" setup = [DHPipeTestData] begin
        using EnergyModelsGUI

        descriptive_names = create_descriptive_names()
        m, _, _ = DHPipeTestData.dh_pipe_test_case()

        # Check that no descriptive names are empty for variables
        variables_map = get_descriptive_names(m, descriptive_names)
        @test !any(any(isempty.(values(a))) for a ∈ values(variables_map))
    end

    @testitem "Test descriptive names for HeatPump model" setup = [HeatPumpTestData] begin
        using EnergyModelsGUI

        descriptive_names = create_descriptive_names()
        m, _, _ = HeatPumpTestData.hp_test_case()

        # Check that no descriptive names are empty for variables
        variables_map = get_descriptive_names(m, descriptive_names)
        @test !any(any(isempty.(values(a))) for a ∈ values(variables_map))
    end

    @testitem "Test descriptive names for HeatPump model" setup = [TESTestData] begin
        using EnergyModelsGUI

        descriptive_names = create_descriptive_names()
        m, _, _ = TESTestData.tes_test_case()

        # Check that no descriptive names are empty for variables
        variables_map = get_descriptive_names(m, descriptive_names)
        @test !any(any(isempty.(values(a))) for a ∈ values(variables_map))
    end

    @testitem "Test descriptive names for HeatPump model" setup = [UpgradeTestData] begin
        using EnergyModelsBase
        using EnergyModelsGUI
        using JuMP
        using HiGHS

        descriptive_names = create_descriptive_names()
        case, model, _, _, _ = UpgradeTestData.generate_data(; equal_mass = false)
        optimizer = optimizer_with_attributes(HiGHS.Optimizer, MOI.Silent() => true)
        m = run_model(case, model, optimizer)

        # Check that no descriptive names are empty for variables
        variables_map = get_descriptive_names(m, descriptive_names)
        @test !any(any(isempty.(values(a))) for a ∈ values(variables_map))
    end
end
