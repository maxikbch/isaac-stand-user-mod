local JSF = _G.JoJoStandFramework

return JSF.Combat.behaviors.compose({
    base = JSF.Combat.behaviors.generic,
    states = {
        rush = require("kakyoin.behaviors.rush"),
        splash = require("kakyoin.behaviors.splash"),
        radio = require("kakyoin.behaviors.radio"),
    },
})
