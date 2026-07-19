return {
    PATHS = {
        verticalLarge = "gfx/ui/jjbaplus_ui_chargebar.anm2",
        verticalSmall = "gfx/ui/jjbaplus_ui_chargebar_small.anm2",
        circular = "gfx/ui/jjbaplus_chargebar.anm2",
    },

    BAR_HEIGHT_LARGE = 32,
    BAR_HEIGHT_SMALL = 16,
    -- Vanilla charge bar crop (see IsaacScript renderChargeBar).
    CHARGE_BAR_FILL = {
        large = { fillHeight = 24, clipEmpty = 26 },
        small = { fillHeight = 12, clipEmpty = 13 },
    },
    CHARGE_BAR_SPACING = 15,
    ABILITY_SLOT_SPACING = 14,
    -- Vanilla BarOverlay{N} animations available in vertical bar anm2 files.
    BAR_OVERLAY_DIVISIONS = { 1, 2, 3, 4, 5, 6, 8, 12 },
    CIRCULAR_SCALE = 1,
    CIRCULAR_BG = {
        skill1 = "BgSkill1",
        skill2 = "BgSkill2",
    },
    -- White flash overlay when a circular meter is ready (charge >= max).
    CIRCULAR_CHARGED_PULSE_SPEED = 0.15,
    CIRCULAR_CHARGED_PULSE_POWER = 4,
    CIRCULAR_CHARGED_PULSE_ALPHA = 0.65,

    -- Default green tint for grayscale charge sprites (vertical + circular fill).
    DEFAULT_CHARGE_COLOR = Color(0, 195/255, 13/255, 1, 0, 0, 0),
    -- Solid tint when a meter is at 100% (override per skill/pool with filledColor).
    DEFAULT_FILLED_COLOR = Color(0, 249/255, 23/255, 1, 0, 0, 0),
    SPRITE_COLOR_WHITE = Color(1, 1, 1, 1, 0, 0, 0),

    -- Move the entire stand meter block on screen (coop slot offsets stay in utils).
    HUD_ORIGIN = Vector(12, 22),

    -- Offsets from HUD_ORIGIN (layout between bar, head, ability slots).
    CHARGE_BAR = Vector(26, 9),
    STAND_HEAD = Vector(0, 0),
    ABILITY_COLUMN = Vector(38, 1),
}
