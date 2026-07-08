local function run(states, player, standDef, jsf, shootDir)
    local standEntity = jsf.standEntity
    if not standEntity or not standEntity:Exists() then
        return
    end

    local standData = standEntity:GetData()
    local handler = states[standData.behavior]
    if handler then
        handler(player, standDef, jsf, shootDir)
    end
end

return {
    run = run,
}
