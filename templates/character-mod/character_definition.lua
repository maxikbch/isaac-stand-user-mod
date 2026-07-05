return {
    Type = Isaac.GetPlayerTypeByName("{{CHARACTER_NAME}}"),
    Type2 = Isaac.GetPlayerTypeByName("{{CHARACTER_NAME}}", true),
    DamageMult = 6/7,
    Damage = 0,
    Speed = 0.15,
    Range = -3.75,
    Costume1 = Isaac.GetCostumeIdByPath("gfx/{{GFX_NAMESPACE}}/characters/costume.anm2"),
    Costume2 = Isaac.GetCostumeIdByPath("gfx/{{GFX_NAMESPACE}}/characters/costume_alt.anm2"),
    Tainted = {
        DamageMult = 6/7,
        Damage = 0.5,
        Speed = 0.15,
        Range = -8.75,
    },
}
