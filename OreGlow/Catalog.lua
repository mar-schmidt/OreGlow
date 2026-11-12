local _, O = ...

-- Exact English client labels, not substring matching. A player called
-- "Copper" or a quest referring to ore must never trigger a pulse.
-- This first release targets enUS/enGB game text; UI may be English or Swedish.
local names = {
    "Poor Copper Vein", "Copper Vein", "Tin Vein", "Silver Vein",
    "Iron Deposit", "Gold Vein", "Mithril Deposit", "Truesilver Deposit",
    "Small Thorium Vein", "Rich Thorium Vein",
    "Ooze Covered Silver Vein", "Ooze Covered Gold Vein",
    "Ooze Covered Mithril Deposit", "Ooze Covered Truesilver Deposit",
    "Ooze Covered Thorium Vein", "Ooze Covered Rich Thorium Vein",
    "Dark Iron Deposit", "Small Obsidian Chunk", "Large Obsidian Chunk",
}
local known = {}
for _, name in ipairs(names) do known[name] = true end

function O.OreName(value)
    local name = O.CleanName(value)
    return name and known[name] and name or nil
end

function O.TooltipOres(data)
    if not O.Plain(data) or type(data) ~= "table" then return {} end
    local lines = data.lines
    if not O.Plain(lines) or type(lines) ~= "table" then return {} end
    local found, used = {}, {}
    for index = 1, math.min(#lines, 16) do
        local line = lines[index]
        if O.Plain(line) and type(line) == "table" then
            local name = O.OreName(line.leftText)
            if name and not used[name] then found[#found + 1], used[name] = name, true end
        end
    end
    return found
end
