local addonName, O = ...
local driver = CreateFrame("Frame")
local gate, accumulator = O.NewGate(), 0
O.diagnostics = {pulses = 0, failures = {}, nearbyEvent = false}

local function call(name, fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, value = pcall(fn, ...)
    if not ok then
        O.diagnostics.failures[name] = true
        return nil
    end
    if not O.Plain(value) then return nil end
    return value
end

function O.SupportedClient()
    local _, _, _, interface = GetBuildInfo()
    interface = O.Number(interface)
    return interface ~= nil and interface >= 16000 and interface < 17000
end

function O.NearbyStatus()
    if not O.SupportedClient() or type(UnitGUID) ~= "function" or type(UnitName) ~= "function" then
        return "unavailable"
    end
    local get = C_CVar and C_CVar.GetCVar or GetCVar
    local value = O.String(call("SoftTargetInteract", get, "SoftTargetInteract"))
    if value ~= "2" and value ~= "3" then return "setup" end
    return "ready"
end

function O.CanDetect()
    if not O.db or not O.db.enabled or not O.SupportedClient() then return false end
    -- No attempt to obtain identities while the client restricts them.
    if call("combat", InCombatLockdown) ~= false then return false end
    if call("dead", UnitIsDeadOrGhost, "player") ~= false then return false end
    if call("taxi", UnitOnTaxi, "player") ~= false then return false end
    return true
end

local function pulse(name, source)
    O.diagnostics.pulses = O.diagnostics.pulses + 1
    O.diagnostics.lastName, O.diagnostics.lastSource = name, source
    O.Pulse()
end

function O.Poll()
    if not O.CanDetect() then gate.held = {}; return end
    local now = GetTime()
    if O.db.nearby then
        local guid = O.String(call("UnitGUID", UnitGUID, "softinteract"))
        -- A live GameObject GUID is required: a nearby NPC/player, a remembered
        -- spawn location or a matching item name never qualifies.
        if guid and guid:match("^GameObject%-") then
            local name = O.OreName(call("UnitName", UnitName, "softinteract"))
            if name and gate:Nearby(guid, name, now) then pulse(name, "nearby") end
        end
    end
    local names = {}
    -- Read only the real cursor's minimap tooltip. Never move/resize the map,
    -- point a soft cursor, enumerate blips, or inspect pixels.
    if O.db.hover and Minimap and type(Minimap.IsMouseOver) == "function"
        and call("minimap hover", Minimap.IsMouseOver, Minimap) == true then
        local read = C_TooltipInfo and C_TooltipInfo.GetMinimapMouseover
        names = O.TooltipOres(call("minimap tooltip", read))
    end
    local name = gate:Hover(names, now)
    if name then pulse(name, "hover") end
end

function O.Status()
    local version, build, _, interface = GetBuildInfo()
    local failed = {}
    for name in pairs(O.diagnostics.failures) do failed[#failed + 1] = name end
    table.sort(failed)
    O.Say("v" .. O.version .. " | " .. tostring(version) .. "." .. tostring(build)
        .. " | interface " .. tostring(interface) .. " | " .. GetLocale())
    O.Say(O.db.enabled and O.Text("enabledText") or O.Text("disabledText"))
    O.Say(O.Text(O.NearbyStatus()))
    O.Say("Nearby event: " .. tostring(O.diagnostics.nearbyEvent)
        .. " | Pulses: " .. O.diagnostics.pulses
        .. " | Last: " .. (O.diagnostics.lastName or "-")
        .. " (" .. (O.diagnostics.lastSource or "-") .. ")")
    if #failed > 0 then O.Say("Unavailable API calls: " .. table.concat(failed, ", ")) end
end

function O.Command(message)
    local command = (message or ""):lower():match("^%s*(.-)%s*$")
    if command == "" or command == "options" then O.ToggleOptions()
    elseif command == "test" then O.Pulse()
    elseif command == "on" or command == "off" then
        O.db.enabled = command == "on"
        if not O.db.enabled then O.StopGlow() end
        O.Say(O.Text(O.db.enabled and "enabledText" or "disabledText"))
        O.RefreshOptions()
    elseif command == "status" or command == "diag" then O.Status()
    elseif command == "sv" or command == "en" then
        O.db.language = command; O.RefreshOptions(); O.Say(O.Text("welcome"))
    else O.Say(O.Text("help")) end
end

local function register(event)
    local ok, accepted = pcall(driver.RegisterEvent, driver, event)
    if not ok or accepted == false then
        O.diagnostics.failures[event] = true
        return false
    end
    return true
end

driver:SetScript("OnEvent", function(_, event, name)
    if event == "ADDON_LOADED" then
        if name ~= addonName then return end
        O.db = O.LoadSettings(OreGlowDB)
        OreGlowDB = O.db
        O.CreateGlow()
        SlashCmdList.OREGLOW = O.Command
        SLASH_OREGLOW1, SLASH_OREGLOW2 = "/og", "/oreglow"
        register("PLAYER_ENTERING_WORLD")
        register("PLAYER_REGEN_DISABLED")
        register("PLAYER_REGEN_ENABLED")
        register("CVAR_UPDATE")
        O.diagnostics.nearbyEvent = register("PLAYER_SOFT_INTERACT_CHANGED")
        O.Say(O.Text("welcome"))
        if not O.SupportedClient() then O.Say(O.Text("wrongClient"))
        elseif O.NearbyStatus() == "setup" then O.Say(O.Text("noInteract")) end
    elseif event == "PLAYER_ENTERING_WORLD" then
        gate = O.NewGate(); O.StopGlow()
    elseif event == "PLAYER_REGEN_DISABLED" then
        O.StopGlow(); gate.held = {}
    elseif event == "CVAR_UPDATE" then
        O.RefreshOptions()
    end
    -- The regular 0.25 s update observes soft-target changes after the
    -- synchronous event has completed. Event GUID payloads are never used.
end)
driver:SetScript("OnUpdate", function(_, elapsed)
    if not O.db then return end
    accumulator = accumulator + elapsed
    if accumulator < 0.25 then return end
    accumulator = 0
    O.Poll()
end)
register("ADDON_LOADED")
