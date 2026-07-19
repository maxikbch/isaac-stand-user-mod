--- Centralized SFX playback with per-sound volume/pitch/loop config.
--- Entries may be:
---   number  — raw SoundEffect id (legacy)
---   string  — sound name resolved via Isaac.GetSoundIdByName
---   table   — { name|id, volume?, pitch?, loop?, frameDelay? }
---   false/nil — disabled / missing

local sfx = SFXManager()
local nameCache = {}

local Audio = {}

local function resolveId(entry)
    if entry == nil or entry == false then
        return nil
    end

    if type(entry) == "number" then
        return entry > 0 and entry or nil
    end

    if type(entry) == "string" then
        local cached = nameCache[entry]
        if cached == nil then
            cached = Isaac.GetSoundIdByName(entry)
            nameCache[entry] = cached
        end
        return cached and cached > 0 and cached or nil
    end

    if type(entry) == "table" then
        if type(entry.id) == "number" and entry.id > 0 then
            return entry.id
        end
        if type(entry.name) == "string" then
            return resolveId(entry.name)
        end
    end

    return nil
end

function Audio.getId(entry)
    return resolveId(entry)
end

--- Play a configured sound. Optional overrides replace volume/pitch/loop/frameDelay.
function Audio.play(entry, overrides)
    local id = resolveId(entry)
    if not id then
        return false
    end

    overrides = overrides or {}
    local volume = overrides.volume
    local frameDelay = overrides.frameDelay
    local loop = overrides.loop
    local pitch = overrides.pitch

    if type(entry) == "table" then
        if volume == nil then
            volume = entry.volume
        end
        if frameDelay == nil then
            frameDelay = entry.frameDelay
        end
        if loop == nil then
            loop = entry.loop
        end
        if pitch == nil then
            pitch = entry.pitch
        end
    end

    sfx:Play(id, volume or 1, frameDelay or 0, loop == true, pitch or 1)
    return true
end

function Audio.isPlaying(entry)
    local id = resolveId(entry)
    return id ~= nil and sfx:IsPlaying(id)
end

function Audio.stop(entry)
    local id = resolveId(entry)
    if id then
        sfx:Stop(id)
    end
end

return Audio
