local subscribers = {}

local function sortByPriority(list)
    table.sort(list, function(a, b)
        return (a.priority or 0) > (b.priority or 0)
    end)
end

local function subscribe(eventName, handler, priority)
    if type(eventName) ~= "string" or type(handler) ~= "function" then
        return function() end
    end

    subscribers[eventName] = subscribers[eventName] or {}
    local entry = {
        handler = handler,
        priority = priority or 0,
    }
    subscribers[eventName][#subscribers[eventName] + 1] = entry
    sortByPriority(subscribers[eventName])

    local cancelled = false
    return function()
        if cancelled then
            return
        end
        cancelled = true
        for i, existing in ipairs(subscribers[eventName]) do
            if existing == entry then
                table.remove(subscribers[eventName], i)
                break
            end
        end
    end
end

local function emit(eventName, payload)
    local list = subscribers[eventName]
    if not list then
        return
    end

    for _, entry in ipairs(list) do
        entry.handler(payload)
    end
end

return {
    subscribe = subscribe,
    emit = emit,
}
