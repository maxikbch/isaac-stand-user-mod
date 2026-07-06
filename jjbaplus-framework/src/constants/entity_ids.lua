-- JJBA+ pack entity ID scheme:
--   variant = modTag * 100 + modVariant   (modVariant 0..99, modTag 0..40)
--   subtype = ResolveSubtype(standIndex)  (0..254 playable, -1 -> 255 debug)

return {
    DEFAULT_MOD_TAG = 13,
    MAX_MOD_TAG = 40,
    MAX_MOD_VARIANT = 99,
    MAX_VARIANT = 4095,
    MAX_STAND_INDEX = 255,
    DEBUG_STAND_INDEX = -1,
    MAX_PLAYABLE_STAND_INDEX = 254,

    KIND_STAND = "stand",
    KIND_PARTICLE = "particle",

    DEFAULT_ENTITIES = {
        stand = { type = 3, modVariant = 0 },
        particle = { type = 1000, modVariant = 1 },
    },
}
