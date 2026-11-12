local _, O = ...
O.version = "0.1.0"
O.defaults = {
    enabled = true, nearby = true, hover = true,
    intensity = 0.28, duration = 1.1, language = "en",
}

function O.Plain(value)
    return not issecretvalue or not issecretvalue(value)
end

function O.String(value)
    if not O.Plain(value) or type(value) ~= "string" then return nil end
    if value == "" then return nil end
    return value
end

function O.Number(value)
    if not O.Plain(value) or type(value) ~= "number" then return nil end
    if value ~= value or value == math.huge or value == -math.huge then return nil end
    return value
end

function O.LoadSettings(saved)
    local settings = {}
    saved = type(saved) == "table" and saved or {}
    for key, value in pairs(O.defaults) do
        if type(saved[key]) == type(value) then settings[key] = saved[key]
        else settings[key] = value end
    end
    settings.intensity = math.max(0.1, math.min(0.6, O.Number(settings.intensity) or 0.28))
    settings.duration = math.max(0.5, math.min(2, O.Number(settings.duration) or 1.1))
    if settings.language ~= "sv" then settings.language = "en" end
    return settings
end

-- Session-only identity cache. A reload deliberately starts a new session.
-- GUIDs identify nearby objects. Minimap tooltips do not identify individual
-- nodes, so their same-name suppression is deliberately conservative.
function O.NewGate()
    local gate = {seen = {}, recent = {}, held = {}, lastPulse = -math.huge}

    function gate:Prune(now)
        local count, oldestKey, oldest = 0, nil, math.huge
        for guid, stamp in pairs(self.seen) do
            if now - stamp > 120 then self.seen[guid] = nil
            else
                count = count + 1
                if stamp < oldest then oldestKey, oldest = guid, stamp end
            end
        end
        if count >= 128 and oldestKey then self.seen[oldestKey] = nil end
        for name, entry in pairs(self.recent) do
            if now - entry.time > 20 then self.recent[name] = nil end
        end
    end

    function gate:Remember(name, source, now)
        self.lastPulse = now
        self.recent[name] = {time = now, source = source}
    end

    function gate:Nearby(guid, name, now)
        if not O.String(guid) or not O.String(name) then return false end
        local seen = self.seen[guid]
        if seen and now - seen <= 120 then self.seen[guid] = now; return false end
        self:Prune(now)
        local recent = self.recent[name]
        if recent and recent.source == "hover" and now - recent.time < 8 then
            self.seen[guid] = now
            return false
        end
        if now - self.lastPulse < 2 then return false end
        self.seen[guid] = now
        self:Remember(name, "nearby", now)
        return true
    end

    function gate:Hover(names, now)
        self:Prune(now)
        local nextHeld, candidate = {}, nil
        for _, name in ipairs(names) do
            if O.String(name) then
                nextHeld[name] = true
                local recent = self.recent[name]
                if not candidate and not self.held[name]
                    and (not recent or now - recent.time >= 20)
                    and now - self.lastPulse >= 2 then candidate = name end
            end
        end
        self.held = nextHeld
        if not candidate then return nil end
        self:Remember(candidate, "hover", now)
        return candidate
    end

    return gate
end

function O.PulseAlpha(elapsed, duration, intensity)
    if elapsed < 0 or elapsed >= duration then return 0 end
    local progress = elapsed / duration
    -- One smooth pulse, with a quicker rise and a gentle fade.
    if progress < 0.25 then return intensity * math.sin(progress * 2 * math.pi) end
    return intensity * math.cos((progress - 0.25) / 0.75 * math.pi / 2)
end

function O.CleanName(value)
    local text = O.String(value)
    if not text then return nil end
    text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    text = text:gsub("^%s+", ""):gsub("%s+$", "")
    -- The minimap may group several blips under the same label.
    text = text:gsub("%s+[xX]%d+$", ""):gsub("%s+%(%d+%)$", "")
    return text
end
