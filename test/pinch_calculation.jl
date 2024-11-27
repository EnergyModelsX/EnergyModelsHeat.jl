@testitem "Pinch calculation" begin
    using TimeStruct
    const EMH = EnergyModelsHeat

    # Same T intervals in both circuits
    @test EMH.fraction_equal_mass(80, 60, 20, 80, 60) ≈ 0
    @test EMH.fraction_equal_mass(80, 60, 10, 80, 60) ≈ 0
    @test EMH.fraction_equal_mass(80, 60, 0, 80, 60) ≈ 1

    # Higher T in surplus heat source
    @test EMH.fraction_equal_mass(90, 60, 40, 80, 60) ≈ 0
    @test EMH.fraction_equal_mass(90, 60, 30, 80, 60) ≈ 0
    @test EMH.fraction_equal_mass(90, 60, 20, 80, 60) ≈ 0
    @test EMH.fraction_equal_mass(90, 60, 10, 80, 60) ≈ 0
    @test EMH.fraction_equal_mass(90, 60, 0, 80, 60) ≈ 2 / 3
    @test EMH.fraction_equal_mass(90, 70, 10, 80, 60) ≈ 1
    @test EMH.fraction_equal_mass(100, 70, 10, 80, 60) ≈ 2 / 3  # Equal mass flow -> loss
    @test EMH.fraction_different_mass(100, 70, 10, 80, 60) ≈ 1  # Adjusting mass flow to recover energy

    # Lower cold T in surplus heat source
    @test EMH.fraction_equal_mass(90, 50, 10, 80, 60) ≈ 0
    @test EMH.fraction_different_mass(90, 50, 10, 80, 60) ≈ 1 / 2

    # Lower cold T in district heating circuit
    @test EMH.fraction_equal_mass(90, 60, 10, 80, 50) ≈ 1
    @test EMH.fraction_different_mass(90, 60, 10, 80, 50) ≈ 1
    @test EMH.fraction_equal_mass(80, 60, 0, 80, 50) ≈ 0
    @test EMH.fraction_different_mass(80, 60, 0, 80, 50) ≈ 1 # TODO: Check this - also assumes can heat from 50->60 due to different flows?

    # Higher T in district heating supply temperature (needs upgrade)
    @test EMH.fraction_equal_mass(70, 50, 10, 80, 50) ≈ 0
    @test EMH.fraction_equal_mass(60, 40, 10, 80, 50) ≈ 0

    # Test with PinchData and TimeStruct
    pd = EMH.PinchData(
        FixedProfile(100),
        FixedProfile(70),
        FixedProfile(10),
        FixedProfile(80),
        FixedProfile(60),
    )
    T = SimpleTimes(1, 1)
    for t ∈ T
        @test EMH.fraction_equal_mass(pd, t) ≈ 2 / 3
    end
end

@testitem "Upgradeable calculation" begin
    const EMH = EnergyModelsHeat

    # Circuits at same intervals:
    @test EMH.upgradeable_equal_mass(70, 60, 0, 70, 60) ≈ 1
    @test EMH.upgradeable_different_mass(70, 60, 0, 70, 60) ≈ 1
    @test EMH.upgradeable_equal_mass(70, 60, 10, 70, 60) ≈ 0
    @test EMH.upgradeable_different_mass(70, 60, 10, 70, 60) ≈ 0
    @test EMH.upgradeable_equal_mass(70, 60, 20, 70, 60) ≈ 0
    @test EMH.upgradeable_different_mass(70, 60, 20, 70, 60) ≈ 0

    @test EMH.upgradeable_equal_mass(70, 40, 0, 70, 40) ≈ 1
    @test EMH.upgradeable_different_mass(70, 40, 0, 70, 40) ≈ 1
    @test EMH.upgradeable_equal_mass(70, 40, 10, 70, 40) ≈ 2 / 3
    @test EMH.upgradeable_different_mass(70, 40, 10, 70, 40) ≈ 2 / 3

    # Lower cold T at surplus heat source (40 < 50)
    @test EMH.upgradeable_equal_mass(70, 40, 10, 70, 50) ≈ 1 / 3
    @test EMH.upgradeable_different_mass(70, 40, 10, 70, 50) ≈ 1 / 3
    # Lower cold T at district heating (40 < 50)
    @test EMH.upgradeable_equal_mass(70, 50, 10, 70, 40) ≈ 1
    @test EMH.upgradeable_different_mass(70, 50, 10, 70, 40) ≈ 1

    # No need for upgrade when heat source less ΔT ≥ DH supply T
    @test EMH.upgradeable_equal_mass(90, 40, 5, 70, 60) ≈ 1 / 2
    @test EMH.upgradeable_different_mass(90, 40, 5, 70, 60) ≈ 1 / 2
    # T_SH_cold < (T_DH_cold + ΔT_min) : 40 < 50 + 5
    @test EMH.upgradeable_equal_mass(60, 40, 5, 70, 50) ≈ 1 / 4
    @test EMH.upgradeable_different_mass(60, 40, 5, 70, 50) ≈ 1 / 4
    # T_SH_cold == (T_DH_cold + ΔT_min) : 55 == 50 + 5
    @test EMH.upgradeable_equal_mass(60, 55, 5, 70, 50) ≈ 1
    @test EMH.upgradeable_different_mass(60, 55, 5, 70, 50) ≈ 1
    # T_SH_cold > (T_DH_cold + ΔT_min) : 
    @test EMH.upgradeable_equal_mass(60, 56, 5, 70, 50) ≈ 1
    @test EMH.upgradeable_different_mass(60, 56, 5, 70, 50) ≈ 1
end

@testitem "Upgrade calculation" begin
    const EMH = EnergyModelsHeat

    # Circuits at same intervals:
    @test EMH.upgrade_equal_mass(70, 60, 0, 70, 60) ≈ 0
    @test EMH.upgrade_different_mass(70, 60, 0, 70, 60) ≈ 0
    @test EMH.upgrade_equal_mass(70, 60, 10, 70, 60) ≈ 1
    @test EMH.upgrade_different_mass(70, 60, 10, 70, 60) ≈ 1
    @test EMH.upgrade_equal_mass(70, 60, 20, 70, 60) ≈ 2     # TODO: Consider warning or error or preferably validate input for upgrade > 1
    @test EMH.upgrade_different_mass(70, 60, 20, 70, 60) ≈ 2 # TODO: Consider warning or error or preferably validate input for upgrade > 1

    @test EMH.upgrade_equal_mass(70, 40, 0, 70, 40) ≈ 0
    @test EMH.upgrade_different_mass(70, 40, 0, 70, 40) ≈ 0
    @test EMH.upgrade_equal_mass(70, 40, 10, 70, 40) ≈ 1 / 3
    @test EMH.upgrade_different_mass(70, 40, 10, 70, 40) ≈ 1 / 3

    # Lower cold T at surplus heat source (40 < 50)
    @test EMH.upgrade_equal_mass(70, 40, 10, 70, 50) ≈ 1 / 2
    @test EMH.upgrade_different_mass(70, 40, 10, 70, 50) ≈ 1 / 2
    # Lower cold T at district heating (40 < 50)
    @test EMH.upgrade_equal_mass(70, 50, 10, 70, 40) ≈ 1 / 3
    @test EMH.upgrade_different_mass(70, 50, 10, 70, 40) ≈ 1 / 3

    # No need for upgrade when heat source less ΔT ≥ DH supply T
    @test EMH.upgrade_equal_mass(90, 40, 5, 70, 60) ≈ 0
    @test EMH.upgrade_different_mass(90, 40, 5, 70, 60) ≈ 0
    # T_SH_cold < (T_DH_cold + ΔT_min) : 40 < 50 + 5
    @test EMH.upgrade_equal_mass(60, 40, 5, 70, 50) ≈ 3 / 4
    @test EMH.upgrade_different_mass(60, 40, 5, 70, 50) ≈ 3 / 4
    # T_SH_cold == (T_DH_cold + ΔT_min) : 55 == 50 + 5
    @test EMH.upgrade_equal_mass(60, 55, 5, 70, 50) ≈ 3 / 4
    @test EMH.upgrade_different_mass(60, 55, 5, 70, 50) ≈ 3 / 4
    # T_SH_cold > (T_DH_cold + ΔT_min) : 
    @test EMH.upgrade_equal_mass(60, 56, 5, 70, 50) ≈ 4 / 5
    @test EMH.upgrade_different_mass(60, 56, 5, 70, 50) ≈ 3 / 4
end
