@testitem "DirectHeatUpgrade checks" setup = [TestData] begin
    using EnergyModelsBase
    using EnergyModelsHeat
    using TimeStruct
    global EnergyModelsBase.ASSERTS_AS_LOG = false # Throw error when check fails

    case, model, nodes, products, T =
        TestData.generate_upgrade_data(70, 60, 70, 60; equal_mass = false)
    power, heat_sur, heat_use, CO₂ = products

    for A ∈ (EnergyModelsHeat.EqualMassFlows, EnergyModelsHeat.DifferentMassFlows)
        nonsensical_heat_upgrade = EnergyModelsHeat.DirectHeatUpgrade{A}(
            "heat upgrade",
            FixedProfile(1.0),
            FixedProfile(0),
            FixedProfile(0),
            Dict(heat_sur => 1, power => 1),
            Dict(heat_use => 1),
            [],
            20,
        )

        @test_throws "upgrade ≤ 1" EnergyModelsBase.check_node(
            nonsensical_heat_upgrade,
            T,
            model,
            true,
        )
    end
end
