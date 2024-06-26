using TestItemRunner
using EnergyModelsHeat

@testitem "Test EnergyModelsHeat" begin
    using TimeStruct
    const EMH = EnergyModelsHeat
    pd = EMH.PinchData(
        FixedProfile(80),    # PEM FC
        FixedProfile(60),
        FixedProfile(8),     # Depends on size of heat exchanger (Ask Davide?)
        FixedProfile(80),    # 80-90°C at Isfjord Radio according to schematics
        FixedProfile(40),    # ca 40°C depending on load according to schematics
    )
    t = SimpleTimes(1,1)
    @test EMH.ψ(pd, t) ≈ 0.7 atol = 0.01
end

@run_package_tests
