@testitem "Pinch calculation" begin
    using TimeStruct
    const EMH = EnergyModelsHeat

    @test EMH.ψ(80, 60, 8, 80, 40) ≈ 0.7 atol = 0.01

    pd = EMH.PinchData(
        FixedProfile(80),    # PEM FC
        FixedProfile(60),
        FixedProfile(8),     # Depends on size of heat exchanger (Ask Davide?)
        FixedProfile(80),    # 80-90°C at Isfjord Radio according to schematics
        FixedProfile(40),    # ca 40°C depending on load according to schematics
    )
    T = SimpleTimes(1, 1)
    for t ∈ T
        @test EMH.ψ(pd, t) ≈ 0.7 atol = 0.01
    end
end
