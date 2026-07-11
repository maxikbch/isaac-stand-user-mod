local RoomEntities = require("src/core/room_entities")
local standChecks = require("src/core/combat/checks")
local utils = require("src/utils")
local Settings = require("src/constants/settings")
local ITEM_MODIFIERS = require("src/constants/item_modifiers")

local targeting = {}

local function allowsGrid(standDef, opts)
    opts = opts or {}
    if opts.allowGrid == false then
        return false
    end
    if Settings.TargetGridEntities == false then
        return false
    end
    local policy = standDef.targeting or {}
    return policy.grid ~= false
end

function targeting.updateIdleLockOn(player, standDef, standEntity, standData, input)
    local STATS = standDef.stats
    local closedist = (-player.TearHeight * STATS.RangeMult) + 40
    local found = false

    for _, en in ipairs(RoomEntities.Get()) do
        if standChecks:IsValidEnemy(en, player, standDef, standEntity)
            or standChecks:IsTargetable(en, player, standDef, standEntity)
        then
            local xdif = en.Position.X - player.Position.X
            local ydif = en.Position.Y - player.Position.Y
            if input.releasedir.Y ~= 0 then
                if input.releasedir.Y * ydif > 0 and math.abs(xdif) < STATS.LockonWidth then
                    if math.abs(ydif) < closedist then
                        found = true
                        standData.tgt = en
                        closedist = math.abs(ydif)
                    end
                end
            else
                if input.releasedir.X * xdif > 0 and math.abs(ydif) < STATS.LockonWidth then
                    if math.abs(xdif) < closedist then
                        found = true
                        standData.tgt = en
                        closedist = math.abs(xdif)
                    end
                end
            end
        end
    end

    if found then
        standData.alphagoal = 1
        standData.tgttimer = 10
    elseif standData.tgttimer > 0
        and (
            standChecks:IsValidEnemy(standData.tgt, player, standDef, standEntity)
            or standChecks:IsTargetable(standData.tgt, player, standDef, standEntity)
        )
    then
        standData.tgttimer = standData.tgttimer - 1
    else
        standData.tgt = nil
    end

    return found
end

function targeting.updateRushTarget(player, standDef, standEntity, standData, opts)
    opts = opts or {}
    local maxSnapDist = opts.maxSnapDist or 45

    for _, en in ipairs(RoomEntities.Get()) do
        if standChecks:IsValidEnemy(en, player, standDef, standEntity) then
            local dest = utils:AdjPos(-standData.launchdir, en)
            local diff = standEntity.Position - dest
            if diff:Length() < maxSnapDist and diff:Length() < (standEntity.Position - standData.launchto):Length() then
                standData.tgt = en
                standData.launchto = dest
            end
        end
    end

    if not standChecks:IsValidCombatTarget(standData.tgt, player, standDef, standEntity) then
        standData.tgt = nil
    end

    if not standData.tgt and allowsGrid(standDef, opts) then
        local frontGrid = standData.launchdir * 50
        local gridEntity = standChecks:IsValidGridEntity(
            standEntity.Position + frontGrid,
            player,
            standDef,
            standEntity
        )
        if gridEntity then
            standData.tgt = gridEntity
        end
    end

    if standData.tgt then
        standData.launchto = utils:AdjPos(-standData.launchdir, standData.tgt)
    else
        standData.launchto = standData.launchtgt
    end
end

function targeting.updateAttackTarget(player, standDef, standEntity, standData)
    local STATS = standDef.stats

    if standData.tgt
        and not standChecks:IsGridEntity(standData.tgt)
        and not standData.tgt:Exists()
    then
        standData.tgt = nil
    end

    if standData.punches < standData.maxpunches
        and not standChecks:IsValidCombatTarget(standData.tgt, player, standDef, standEntity)
    then
        standData.tgt = nil
        local maxdist = STATS.ExtraTargetRange + (player.MoveSpeed * STATS.ExtraTargetRangeBonus)
        if utils:hasbit(player.TearFlags, TearFlags.TEAR_HOMING) then
            maxdist = maxdist + ITEM_MODIFIERS.HomingTargetRangeBonus
        end
        for _, en in ipairs(RoomEntities.Get()) do
            if standChecks:IsValidEnemy(en, player, standDef, standEntity) then
                local dest = utils:AdjPos(-standData.launchdir, en)
                local dist = (standEntity.Position - dest):Length()
                if dist < maxdist then
                    standData.tgt = en
                    maxdist = dist
                end
            end
        end
        if not standData.tgt and allowsGrid(standDef) then
            local gridEntity = standChecks:IsValidGridEntity(
                standEntity.Position,
                player,
                standDef,
                standEntity
            )
            if gridEntity then
                standData.tgt = gridEntity
            end
        end
    end
end

function targeting.forEachVulnerableEnemy(fn)
    for _, en in ipairs(RoomEntities.Get()) do
        if en:IsVulnerableEnemy() and en.Type ~= 33 and not en:HasEntityFlags(EntityFlag.FLAG_FRIENDLY) then
            if fn(en) == false then
                return
            end
        end
    end
end

function targeting.forEachValidEnemy(player, standDef, standEntity, fn)
    for _, en in ipairs(RoomEntities.Get()) do
        if standChecks:IsValidEnemy(en, player, standDef, standEntity) then
            if fn(en) == false then
                return
            end
        end
    end
end

return targeting
