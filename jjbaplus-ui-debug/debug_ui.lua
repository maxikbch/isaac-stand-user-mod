local STAND_ID = "ui_debug"

local PRESETS = {
    {
        name = "1 bar + skill1 (charge)",
        pools = {
            primary = { maxCharge = 80, gainOnHit = true },
        },
        skill1 = { enabled = true, skill = "test_active", requiresCharge = true, chargePool = "primary" },
        skill2 = { enabled = false },
    },
    {
        name = "2 bars + skill1+skill2 (charge)",
        pools = {
            primary = { maxCharge = 80, gainOnHit = true },
            secondary = { maxCharge = 40, gainOnHit = false },
        },
        skill1 = { enabled = true, skill = "test_active", requiresCharge = true, chargePool = "primary" },
        skill2 = { enabled = true, skill = "test_instant", requiresCharge = true, chargePool = "secondary" },
    },
    {
        name = "0 bars + skill1 (charge)",
        pools = {
            primary = { maxCharge = 80, gainOnHit = true, meter = false },
        },
        skill1 = { enabled = true, skill = "test_active", requiresCharge = true, chargePool = "primary" },
        skill2 = { enabled = false },
    },
    {
        name = "0 bars + skill1 (no charge)",
        pools = {},
        skill1 = { enabled = true, skill = "test_free", requiresCharge = false },
        skill2 = { enabled = false },
    },
    {
        name = "1 bar + skill1 charge + skill2 free",
        pools = {
            primary = { maxCharge = 80, gainOnHit = true },
        },
        skill1 = { enabled = true, skill = "test_active", requiresCharge = true, chargePool = "primary" },
        skill2 = { enabled = true, skill = "test_free", requiresCharge = false },
    },
    {
        name = "0 bars + skill1+skill2 (no charge)",
        pools = {},
        skill1 = { enabled = true, skill = "test_free", requiresCharge = false },
        skill2 = { enabled = true, skill = "test_free", requiresCharge = false },
    },
    {
        name = "1 bar + skill2 only (charge)",
        pools = {
            secondary = { maxCharge = 40, gainOnHit = false },
        },
        skill1 = { enabled = false },
        skill2 = { enabled = true, skill = "test_instant", requiresCharge = true, chargePool = "secondary" },
    },
    {
        name = "2 bars + skill1 only",
        pools = {
            primary = { maxCharge = 80, gainOnHit = true },
            secondary = { maxCharge = 40, gainOnHit = false },
        },
        skill1 = { enabled = true, skill = "test_active", requiresCharge = true, chargePool = "primary" },
        skill2 = { enabled = false },
    },
    {
        name = "Head only (no bars, no skills)",
        pools = {},
        skill1 = { enabled = false },
        skill2 = { enabled = false },
    },
}

local function copySlot(target, source)
    for key, value in pairs(source) do
        target[key] = value
    end
end

local function applyPreset(standDef, index)
    local preset = PRESETS[index]
    if not preset then
        return
    end

    standDef.chargePools = {}
    for poolId, poolDef in pairs(preset.pools) do
        standDef.chargePools[poolId] = {
            maxCharge = poolDef.maxCharge,
            gainOnHit = poolDef.gainOnHit,
            meter = poolDef.meter,
        }
    end

    copySlot(standDef.slots.skill1, preset.skill1)
    copySlot(standDef.slots.skill2, preset.skill2)
end

local function resetCharges(standState, standDef)
    standState.charges = {}
    for poolId, poolDef in pairs(standDef.chargePools or {}) do
        standState.charges[poolId] = 0
    end
    standState.skillDurations = {}
end

return function(JSF)
    local presetIndex = 1

    local function getContext(player)
        local standDef = JSF:GetStand(STAND_ID)
        if not standDef or standDef.id ~= STAND_ID then
            return nil, nil, nil
        end
        if not player:HasCollectible(standDef.discItem) then
            return nil, nil, nil
        end
        local jsfData = JSF:GetPlayerData(player)
        return standDef, jsfData.standState, jsfData
    end

    local function applyCurrentPreset(player)
        local standDef, standState = getContext(player)
        if not standDef then
            return
        end
        applyPreset(standDef, presetIndex)
        resetCharges(standState, standDef)
    end

    return {
        getPresetLabel = function()
            return string.format("[%d/%d] %s", presetIndex, #PRESETS, PRESETS[presetIndex].name)
        end,

        onPlayerInit = function(player)
            applyCurrentPreset(player)
        end,

        onInput = function(player)
            local standDef, standState = getContext(player)
            if not standDef or not standState then
                return
            end

            JSF:OnInputUpdate()
            local controllerIndex = player.ControllerIndex

            if JSF:WasButtonPressedEdge(controllerIndex, Keyboard.KEY_F7) then
                presetIndex = presetIndex % #PRESETS + 1
                applyCurrentPreset(player)
            elseif JSF:WasButtonPressedEdge(controllerIndex, Keyboard.KEY_F6) then
                presetIndex = presetIndex - 1
                if presetIndex < 1 then
                    presetIndex = #PRESETS
                end
                applyCurrentPreset(player)
            elseif JSF:WasButtonPressedEdge(controllerIndex, Keyboard.KEY_F8) then
                standState.charges = standState.charges or {}
                for poolId, poolDef in pairs(standDef.chargePools or {}) do
                    standState.charges[poolId] = math.floor((poolDef.maxCharge or 0) * 0.5)
                end
            elseif JSF:WasButtonPressedEdge(controllerIndex, Keyboard.KEY_F9) then
                standState.charges = standState.charges or {}
                for poolId, poolDef in pairs(standDef.chargePools or {}) do
                    standState.charges[poolId] = poolDef.maxCharge or 0
                end
            elseif JSF:WasButtonPressedEdge(controllerIndex, Keyboard.KEY_F10) then
                local skillId = standDef.slots.skill1.skill
                local skillDef = standDef.skills[skillId]
                if skillDef and skillDef.duration and skillDef.duration > 0 then
                    standState.skillDurations = standState.skillDurations or {}
                    standState.skillDurations[skillId] = skillDef.duration
                    if skillDef.chargePool then
                        standState.charges = standState.charges or {}
                        standState.charges[skillDef.chargePool] = 0
                    end
                end
            end
        end,

        renderHelp = function()
            local y = 72
            Isaac.RenderText("JJBA+ UI Debug", 40, y, 1, 1, 0.4, 1)
            y = y + 12
            Isaac.RenderText(PRESETS[presetIndex].name, 40, y, 1, 1, 1, 1)
            y = y + 12
            Isaac.RenderText("F6/F7: preset  F8: 50%  F9: 100%  F10: discharge", 40, y, 0.8, 0.8, 0.8, 1)
        end,
    }
end
