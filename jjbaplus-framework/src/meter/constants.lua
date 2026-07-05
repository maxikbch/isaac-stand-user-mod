return {
    PATHS = {
        verticalLarge = "gfx/ui/ui_chargebar.anm2",
        verticalSmall = "gfx/ui/ui_chargebar_small.anm2",
        circular = "gfx/ui/chargebar.anm2",
        buttons = "gfx/ui/buttons.anm2",
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

    -- Move the entire stand meter block on screen (coop slot offsets stay in utils).
    HUD_ORIGIN = Vector(0, 0),

    -- Offsets from HUD_ORIGIN (layout between bar, head, ability slots).
    CHARGE_BAR = Vector(44, 16),
    STAND_HEAD = Vector(18, 8),
    ABILITY_COLUMN = Vector(120, 4),

    GLYPH = {
        animation = "XboxOne",
        keyboard = {
            [Keyboard.KEY_C] = 20,
            [Keyboard.KEY_LEFT_SHIFT] = 18,
        },
        controller = {
            [10] = 12, -- L3
            [13] = 13, -- R3
        },
    },
}
