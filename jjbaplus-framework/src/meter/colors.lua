local Constants = require("src/meter/constants")

local function pick(skillDef, poolDef, key)
    if skillDef and skillDef[key] ~= nil then
        return skillDef[key]
    end
    if poolDef and poolDef[key] ~= nil then
        return poolDef[key]
    end
    return nil
end

--- Resolve meter tint. When full: filledColor if set, else DEFAULT_FILLED_COLOR.
local function resolve(skillDef, poolDef, charge, maxCharge)
    local isFull = maxCharge and maxCharge > 0 and charge and charge >= maxCharge
    if isFull then
        return pick(skillDef, poolDef, "filledColor") or Constants.DEFAULT_FILLED_COLOR
    end

    return pick(skillDef, poolDef, "fillColor") or Constants.DEFAULT_CHARGE_COLOR
end

return {
    resolve = resolve,
}
