@testitem "DirectHeatUpgrade checks" setup = [TestData] begin
    using EnergyModelsBase
    using EnergyModelsHeat
    using TimeStruct
    global EnergyModelsBase.ASSERTS_AS_LOG = false # Throw error when check fails

    case, model, nodes, products, T = TestData.generate_upgrade_data(; equal_mass = false)
    power, heat_sur, heat_use, CO₂ = products
    for A ∈ (EnergyModelsHeat.EqualMassFlows, EnergyModelsHeat.DifferentMassFlows)
        pd = EnergyModelsHeat.PinchData(
            FixedProfile(70),
            FixedProfile(60),
            FixedProfile(20),
            FixedProfile(70),
            FixedProfile(60),
        )
        nonsensical_heat_upgrade = EnergyModelsHeat.DirectHeatUpgrade{A}(
            "heat upgrade",
            FixedProfile(1.0),
            FixedProfile(0),
            FixedProfile(0),
            Dict(heat_sur => 1, power => 1),
            Dict(heat_use => 1),
            [pd],
        )

        @test_throws "upgrade ≤ 1" EnergyModelsBase.check_node(
            nonsensical_heat_upgrade,
            T,
            model,
            true,
        )
    end
end
