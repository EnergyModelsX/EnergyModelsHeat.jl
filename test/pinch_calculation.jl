@testitem "Pinch calculation" begin
    using TimeStruct
    const EMH = EnergyModelsHeat

    # Same T intervals in both circuits
    @test EMH.ψ(80, 60, 20, 80, 60) ≈ 0.0
    @test EMH.ψ(80, 60, 10, 80, 60) ≈ 0.5
    @test EMH.ψ(80, 60, 0, 80, 60) ≈ 1.0

    # Higher T in surplus heat source
    @test EMH.ψ(90, 60, 40, 80, 60) ≈ -0.5 # TODO: Should be 0?
    @test EMH.ψ(90, 60, 30, 80, 60) ≈ 0.0
    @test EMH.ψ(90, 60, 20, 80, 60) ≈ 0.5
    @test EMH.ψ(90, 60, 10, 80, 60) ≈ 1.0
    @test EMH.ψ(90, 60, 0, 80, 60) ≈ 1.5

    # Lower cold T in surplus heat source
    @test EMH.ψ(90, 50, 10, 80, 60) ≈ 1.0
    @test EMH.ψ(90, 70, 10, 80, 60) ≈ 0.5

    # Lower cold T in district heating circuit
    @test EMH.ψ(90, 60, 10, 80, 50) ≈ 2 / 3
    @test EMH.ψ(90, 60, 0, 80, 50) ≈ 1.0

    # Higher T in district heating supply temperature (needs upgrade)
    @test EMH.ψ(70, 50, 10, 80, 50) ≈ 1 / 3
    @test EMH.ψ(60, 40, 10, 80, 50) ≈ 0.0

    # Test pinch calculation 
    @test EMH.ψ(80, 60, 8, 80, 40) ≈ 0.3 atol = 0.01

    # Test with PinchData and TimeStruct
    pd = EMH.PinchData(
        FixedProfile(80),    # PEM FC
        FixedProfile(60),
        FixedProfile(8),     # Depends on size of heat exchanger (Ask Davide?)
        FixedProfile(80),    # 80-90°C at Isfjord Radio according to schematics
        FixedProfile(40),    # ca 40°C depending on load according to schematics
    )
    T = SimpleTimes(1, 1)
    for t ∈ T
        @test EMH.ψ(pd, t) ≈ 0.3 atol = 0.01
    end
end

@testitem "Upgrade calculation" begin
    const EMH = EnergyModelsHeat

    # Circuits at same intervals:
    @test EMH.upgrade(70, 60, 0, 70, 60) ≈ 0.0
    @test EMH.upgrade(70, 60, 10, 70, 60) ≈ 1.0
    @test EMH.upgrade(70, 60, 20, 70, 60) ≈ 2.0 # TODO: makes sense?

    @test EMH.upgrade(70, 40, 0, 70, 40) ≈ 0.0
    @test EMH.upgrade(70, 40, 10, 70, 40) ≈ 1 / 3

    # Lower cold T at surplus heat source (40 < 50)
    @test EMH.upgrade(70, 40, 10, 70, 50) ≈ 1 / 3
    # Lower cold T at district heating (40 < 50)
    @test EMH.upgrade(70, 50, 10, 70, 40) ≈ 0.5

    # No need for upgrade when heat source less ΔT ≥ DH supply T
    @test EMH.upgrade(90, 40, 5, 70, 60) ≈ 0
    # T_COLD < (T_cold + ΔT_min) : 40 < 50 + 5
    @test EMH.upgrade(60, 40, 5, 70, 50) ≈ 0.75
    # T_COLD == (T_cold + ΔT_min) : 55 == 50 + 5
    @test EMH.upgrade(60, 55, 5, 70, 50) ≈ 3.0
    # T_COLD > (T_cold + ΔT_min) : 
    @test EMH.upgrade(60, 56, 5, 70, 50) ≈ 3.0
end
