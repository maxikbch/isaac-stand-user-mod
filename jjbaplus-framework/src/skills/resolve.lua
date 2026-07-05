local function resolveSkillId(slotDef, player, standDef, standState)
    if not slotDef then
        return nil
    end

    local ref = slotDef.skill or slotDef.skills
    if ref == nil then
        return nil
    end

    if type(ref) == "function" then
        return ref(player, standDef, standState)
    end

    if type(ref) == "table" then
        local mode = standState.mode or "default"
        if ref[mode] then
            return ref[mode]
        end
        if ref.default then
            return ref.default
        end
        return ref[1]
    end

    return ref
end

return {
    resolveSkillId = resolveSkillId,
}
