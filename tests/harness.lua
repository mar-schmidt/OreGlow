local H = {}
function H.New()
    local env = setmetatable({}, {__index = _G})
    env._G = env
    local state = {now = 0, frames = {}, messages = {}, calls = {}, cvar = "3",
        hover = false, combat = false, dead = false, taxi = false, interface = 16001}
    local function count(name) state.calls[name] = (state.calls[name] or 0) + 1 end
    local methods = {}
    function methods:SetScript(name, fn) self.scripts[name] = fn end
    function methods:GetScript(name) return self.scripts[name] end
    function methods:RegisterEvent(event) self.events[event] = true; return true end
    function methods:SetPoint(...) self.points[#self.points + 1] = {...} end
    function methods:SetAllPoints(frame) self.allPoints = frame end
    function methods:SetSize(w, h) self.width, self.height = w, h end
    function methods:SetWidth(w) self.width = w end
    function methods:SetHeight(h) self.height = h end
    function methods:GetWidth() return self.width or 1920 end
    function methods:GetHeight() return self.height or 1080 end
    function methods:SetAlpha(alpha) self.alpha = alpha end
    function methods:Show()
        local wasShown = self.shown
        self.shown = true
        if not wasShown and self.scripts.OnShow then self.scripts.OnShow(self) end
    end
    function methods:Hide() self.shown = false end
    function methods:IsShown() return self.shown end
    function methods:SetShown(on) if on then self:Show() else self:Hide() end end
    function methods:SetText(text) self.text = text end
    function methods:SetChecked(on) self.checked = on end
    function methods:GetChecked() return self.checked end
    function methods:SetColorTexture(...) self.color = {...} end
    function methods:SetGradient(axis, first, last) self.gradient = {axis, first, last} end
    function methods:EnableMouse(on) self.mouseEnabled = on end
    function methods:EnableKeyboard(on) self.keyboardEnabled = on end
    function methods:SetFrameStrata(strata) self.strata = strata end
    function methods:SetValue(value)
        local changed = self.value ~= value
        self.value = value
        if changed and self.scripts.OnValueChanged then self.scripts.OnValueChanged(self, value) end
    end
    local function noOp() end
    for _, name in ipairs({"SetMovable", "RegisterForDrag", "StartMoving", "StopMovingOrSizing",
        "SetJustifyH", "SetTextColor", "SetMinMaxValues", "SetValueStep", "SetObeyStepOnDrag"}) do
        methods[name] = noOp
    end
    local newFrame
    newFrame = function(kind, name, parent, template)
        local frame = setmetatable({kind = kind, name = name, parent = parent,
            template = template, scripts = {}, events = {}, points = {}, shown = true}, {__index = methods})
        state.frames[#state.frames + 1] = frame
        if name then env[name] = frame end
        if template == "BasicFrameTemplateWithInset" then frame.TitleText = newFrame("FontString") end
        if template == "UICheckButtonTemplate" then frame.Text = newFrame("FontString") end
        if template == "OptionsSliderTemplate" then
            for _, suffix in ipairs({"Text", "Low", "High"}) do env[name .. suffix] = newFrame("FontString") end
        end
        return frame
    end
    function methods:CreateTexture() return newFrame("Texture", nil, self) end
    function methods:CreateFontString() return newFrame("FontString", nil, self) end
    env.CreateFrame = newFrame
    env.UIParent = newFrame("Frame", "UIParent")
    env.UISpecialFrames, env.SlashCmdList = {}, {}
    env.CreateColor = function(...) return {...} end
    env.GetTime = function() return state.now end
    env.issecretvalue = function(v) return type(v) == "table" and rawget(v, "secret") == true end
    env.GetBuildInfo = function() return "1.60.1", "70888", "Nov 10 2026", state.interface end
    env.GetLocale = function() return "enUS" end
    env.UnitGUID = function(unit) count("guid"); assert(unit == "softinteract"); return state.guid end
    env.UnitName = function(unit) count("name"); assert(unit == "softinteract"); return state.name end
    env.InCombatLockdown = function() return state.combat end
    env.UnitIsDeadOrGhost = function() return state.dead end
    env.UnitOnTaxi = function() return state.taxi end
    env.C_CVar = {GetCVar = function(name) assert(name == "SoftTargetInteract"); return state.cvar end}
    env.Minimap = {IsMouseOver = function() return state.hover end}
    env.C_TooltipInfo = {GetMinimapMouseover = function() count("tooltip"); return state.tooltip end}
    env.print = function(message) state.messages[#state.messages + 1] = message end
    local O = {}
    for _, name in ipairs({"Core", "Catalog", "Glow", "Options", "Main"}) do
        local chunk = assert(loadfile("OreGlow/" .. name .. ".lua"))
        setfenv(chunk, env)
        chunk("OreGlow", O)
    end
    function state:Event(event, ...)
        for _, frame in ipairs(self.frames) do
            if frame.events[event] and frame.scripts.OnEvent then frame.scripts.OnEvent(frame, event, ...) end
        end
    end
    function state:Tick(elapsed)
        self.now = self.now + elapsed
        for _, frame in ipairs(self.frames) do
            if frame.shown and frame.scripts.OnUpdate then frame.scripts.OnUpdate(frame, elapsed) end
        end
    end
    function state:Ore(guid, name) self.guid, self.name = guid, name or "Copper Vein" end
    state:Event("ADDON_LOADED", "OreGlow")
    return O, state, env
end
return H
