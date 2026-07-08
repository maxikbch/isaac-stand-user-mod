local debug = require("src/debug")
local settings = require("settings")

local EVENTS = {
    "skill_activate",
    "skill_deactivate",
    "stand_disc_swapped",
    "global_time_frozen",
}

local function describePayload(eventName, payload)
    if eventName == "skill_activate" or eventName == "skill_deactivate" then
        return string.format(
            "%s skill=%s stand=%s",
            eventName,
            tostring(payload and payload.skillId),
            tostring(payload and payload.standDef and payload.standDef.id)
        )
    end
    if eventName == "stand_disc_swapped" then
        return string.format(
            "%s stand=%s oldDisc=%s newDisc=%s",
            eventName,
            tostring(payload and payload.newStandId),
            tostring(payload and payload.oldDisc),
            tostring(payload and payload.newDisc)
        )
    end
    if eventName == "global_time_frozen" then
        return string.format(
            "%s active=%s stand=%s",
            eventName,
            tostring(payload and payload.active),
            tostring(payload and payload.standDef and payload.standDef.id)
        )
    end
    return tostring(eventName)
end

return function(jsf)
    if not jsf.Events then
        return
    end

    for _, eventName in ipairs(EVENTS) do
        jsf.Events.subscribe(eventName, function(payload)
            if settings.DebugOverlay then
                debug:Log(describePayload(eventName, payload))
            end
        end)
    end
end
