return {
    Type = Isaac.GetPlayerTypeByName("Kakyoin"),
    Type2 = Isaac.GetPlayerTypeByName("Kakyoin", true),
    DamageMult = 6/7,
    Damage = 0,
    Speed = 0.15,
    Range = -8.75,
    Costume1 = Isaac.GetCostumeIdByPath("gfx/kakyoin/characters/costume.anm2"),
    Costume2 = Isaac.GetCostumeIdByPath("gfx/kakyoin/characters/costume_alt.anm2"),
    Tainted = {
        DamageMult = 6/7,
        Damage = 0.5,
        Speed = 0.15,
        Range = -8.75,
    },
}
