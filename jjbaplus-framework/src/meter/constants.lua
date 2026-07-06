return {
    PATHS = {
        verticalLarge = "gfx/ui/ui_chargebar.anm2",
        verticalSmall = "gfx/ui/ui_chargebar_small.anm2",
        circular = "gfx/ui/chargebar.anm2",
    },

    BAR_HEIGHT_LARGE = 32,
    BAR_HEIGHT_SMALL = 16,
    -- Vanilla charge bar crop (see IsaacScript renderChargeBar).
    CHARGE_BAR_FILL = {
        large = { fillHeight = 24, clipEmpty = 26 },
        small = { fillHeight = 12, clipEmpty = 13 },
    },
    CHARGE_BAR_SPACING = 18,
    ABILITY_SLOT_SPACING = 20,
    CIRCULAR_SCALE = 1,
    CIRCULAR_BG = {
        skill1 = "BgSkill1",
        skill2 = "BgSkill2",
    },

    -- Default green tint for grayscale charge sprites (vertical + circular fill).
    DEFAULT_CHARGE_COLOR = Color(0.28, 1, 0.22, 1, 0, 0, 0),
    SPRITE_COLOR_WHITE = Color(1, 1, 1, 1, 0, 0, 0),

    -- Move the entire stand meter block on screen (coop slot offsets stay in utils).
    HUD_ORIGIN = Vector(0, 0),

    -- Offsets from HUD_ORIGIN (layout between bar, head, ability slots).
    CHARGE_BAR = Vector(44, 16),
    STAND_HEAD = Vector(18, 8),
    ABILITY_COLUMN = Vector(120, 4),
}
