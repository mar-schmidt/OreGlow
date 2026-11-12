local _, O = ...
local panel
local words = {
    en = {
        subtitle = "A little gold when ore is close.",
        enabled = "Enable OreGlow",
        nearby = "Alert for nearby ore",
        hover = "Alert when I hover an ore blip",
        strength = "Glow strength", duration = "Pulse duration",
        test = "Test glow", close = "Close",
        ready = "Nearby detection is ready.",
        setup = "For nearby alerts, enable Interact Key in WoW Options > Controls.",
        unavailable = "Nearby detection is unavailable on this client.",
        paused = "Alerts pause during combat, while dead or in flight.",
        limits = "Nearby alerts use the game's interaction target.\nMinimap alerts need your mouse over a real ore blip.\nMining names: English game client.",
        enabledText = "enabled", disabledText = "disabled",
        help = "/og: options | /og test | /og on | /og off | /og status | /og sv | /og en",
        welcome = "Ready. /og opens options; /og test previews the glow.",
        wrongClient = "This release supports WoW Forever (interface 16001). Detection is paused.",
        noInteract = "Nearby alerts need Interact Key enabled in WoW Options > Controls.",
    },
    sv = {
        subtitle = "Lite guld när malmen är nära.",
        enabled = "Aktivera OreGlow",
        nearby = "Varna för malm i närheten",
        hover = "Varna när jag hovrar en miningprick",
        strength = "Blinkningens styrka", duration = "Blinkningens längd",
        test = "Testa blinkningen", close = "Stäng",
        ready = "Närhetsdetekteringen är redo.",
        setup = "Aktivera Interact Key i WoW Options > Controls för närhetsvarningar.",
        unavailable = "Närhetsdetektering saknas i den här klienten.",
        paused = "Varningar pausas i strid, när du är död och under flygtaxi.",
        limits = "Närhetsvarningar använder spelets interaktionsmål.\nMinimappen kräver att du hovrar en riktig miningprick.\nMiningnamn: engelsk spelklient.",
        enabledText = "aktiverat", disabledText = "avaktiverat",
        help = "/og: inställningar | /og test | /og on | /og off | /og status | /og sv | /og en",
        welcome = "Redo. /og öppnar inställningar; /og test visar blinkningen.",
        wrongClient = "Den här versionen stöder WoW Forever (interface 16001). Detektering är pausad.",
        noInteract = "Närhetsvarningar kräver Interact Key i WoW Options > Controls.",
    },
}

function O.Text(key)
    return (words[O.db and O.db.language or "en"] or words.en)[key] or key
end

function O.Say(message) print("|cffffc34dOreGlow:|r " .. message) end

function O.RefreshOptions()
    if not panel then return end
    panel.subtitle:SetText(O.Text("subtitle"))
    for key, box in pairs(panel.checks) do
        box.Text:SetText(O.Text(key)); box:SetChecked(O.db[key])
    end
    panel.strength.Label:SetText(O.Text("strength"))
    panel.duration.Label:SetText(O.Text("duration"))
    panel.strength:SetValue(O.db.intensity * 100)
    panel.duration:SetValue(O.db.duration)
    panel.test:SetText(O.Text("test")); panel.close:SetText(O.Text("close"))
    local state = O.NearbyStatus()
    panel.status:SetText(O.Text(state))
    panel.status:SetTextColor(state == "ready" and 0.5 or 1, state == "ready" and 0.9 or 0.75, 0.4)
    panel.limits:SetText(O.Text("limits"))
    panel.paused:SetText(O.Text("paused"))
    panel.language:SetText(O.db.language == "sv" and "English" or "Svenska")
end

function O.CreateOptions()
    if panel then return panel end
    panel = CreateFrame("Frame", "OreGlowOptions", UIParent, "BasicFrameTemplateWithInset")
    panel:SetSize(440, 464)
    panel:SetPoint("CENTER")
    panel:SetFrameStrata("DIALOG")
    panel:SetMovable(true); panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", function(self) self:StartMoving() end)
    panel:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    panel.TitleText:SetText("OreGlow " .. O.version)
    UISpecialFrames[#UISpecialFrames + 1] = "OreGlowOptions"

    local function label(font, y, width)
        local text = panel:CreateFontString(nil, "OVERLAY", font)
        text:SetPoint("TOPLEFT", 22, y)
        text:SetWidth(width or 396)
        text:SetJustifyH("LEFT")
        return text
    end
    panel.subtitle = label("GameFontNormal", -40)
    panel.checks = {}
    for index, key in ipairs({"enabled", "nearby", "hover"}) do
        local box = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
        box:SetPoint("TOPLEFT", 18, -63 - (index - 1) * 30)
        box:SetScript("OnClick", function(self)
            O.db[key] = self:GetChecked() == true
            if not O.db.enabled then O.StopGlow() end
        end)
        panel.checks[key] = box
    end

    local function slider(name, y, low, high, step, key, multiplier)
        local frame = CreateFrame("Slider", name, panel, "OptionsSliderTemplate")
        frame:SetPoint("TOPLEFT", 26, y)
        frame:SetSize(275, 16)
        frame:SetMinMaxValues(low, high); frame:SetValueStep(step)
        frame:SetObeyStepOnDrag(true)
        frame.Label = _G[name .. "Text"]
        _G[name .. "Low"]:SetText(tostring(low))
        _G[name .. "High"]:SetText(tostring(high))
        frame.readout = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        frame.readout:SetPoint("LEFT", frame, "RIGHT", 18, 0)
        frame:SetScript("OnValueChanged", function(_, value)
            value = math.floor(value / step + 0.5) * step
            O.db[key] = value / multiplier
            frame.readout:SetText(key == "intensity" and string.format("%d%%", value)
                or string.format("%.1f s", value))
        end)
        return frame
    end
    panel.strength = slider("OreGlowStrength", -185, 10, 60, 1, "intensity", 100)
    panel.duration = slider("OreGlowDuration", -244, 0.5, 2, 0.1, "duration", 1)
    panel.status = label("GameFontHighlightSmall", -290)
    panel.status:SetHeight(32)
    panel.limits = label("GameFontHighlightSmall", -332)
    panel.limits:SetHeight(48)
    panel.paused = label("GameFontDisableSmall", -388)
    panel.paused:SetHeight(28)

    local function button(x, width, action)
        local frame = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        frame:SetSize(width, 25); frame:SetPoint("BOTTOMLEFT", x, 16)
        frame:SetScript("OnClick", action)
        return frame
    end
    panel.test = button(22, 150, O.Pulse)
    panel.language = button(184, 100, function()
        O.db.language = O.db.language == "sv" and "en" or "sv"
        O.RefreshOptions()
    end)
    panel.close = button(296, 120, function() panel:Hide() end)
    panel:SetScript("OnShow", O.RefreshOptions)
    O.RefreshOptions()
    panel:Hide()
    return panel
end

function O.ToggleOptions()
    local frame = O.CreateOptions()
    frame:SetShown(not frame:IsShown())
end
