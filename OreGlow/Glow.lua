local _, O = ...
local glow

function O.StopGlow()
    if glow then glow.started = nil; glow:Hide() end
end

function O.CreateGlow()
    if glow then return glow end
    glow = CreateFrame("Frame", "OreGlowScreenEdges", UIParent)
    glow:SetAllPoints(UIParent)
    glow:SetFrameStrata("FULLSCREEN")
    glow:EnableMouse(false)
    glow:EnableKeyboard(false)
    glow:Hide()
    glow.edges = {}

    local function edge(axis, firstAlpha, lastAlpha, ...)
        local texture = glow:CreateTexture(nil, "OVERLAY")
        texture:SetColorTexture(1, 1, 1, 1)
        texture:SetGradient(axis,
            CreateColor(1, 0.70, 0.12, firstAlpha),
            CreateColor(1, 0.70, 0.12, lastAlpha))
        local points = {...}
        texture:SetPoint(unpack(points[1]))
        texture:SetPoint(unpack(points[2]))
        glow.edges[#glow.edges + 1] = texture
        return texture
    end

    local left = edge("HORIZONTAL", 1, 0,
        {"TOPLEFT", glow, "TOPLEFT"}, {"BOTTOMLEFT", glow, "BOTTOMLEFT"})
    local right = edge("HORIZONTAL", 0, 1,
        {"TOPRIGHT", glow, "TOPRIGHT"}, {"BOTTOMRIGHT", glow, "BOTTOMRIGHT"})
    local top = edge("VERTICAL", 0, 0.75,
        {"TOPLEFT", glow, "TOPLEFT"}, {"TOPRIGHT", glow, "TOPRIGHT"})
    local bottom = edge("VERTICAL", 0.75, 0,
        {"BOTTOMLEFT", glow, "BOTTOMLEFT"}, {"BOTTOMRIGHT", glow, "BOTTOMRIGHT"})

    local function size()
        local width = math.max(48, math.min(140, UIParent:GetWidth() * 0.075))
        local height = math.max(40, math.min(100, UIParent:GetHeight() * 0.1))
        left:SetWidth(width); right:SetWidth(width)
        top:SetHeight(height); bottom:SetHeight(height)
    end
    size()
    glow:SetScript("OnSizeChanged", size)
    glow:SetScript("OnUpdate", function(self)
        if not self.started then return end
        local elapsed = GetTime() - self.started
        if elapsed >= self.duration then O.StopGlow(); return end
        self:SetAlpha(O.PulseAlpha(elapsed, self.duration, self.intensity))
    end)
    return glow
end

function O.Pulse()
    local frame = O.CreateGlow()
    frame.started, frame.duration, frame.intensity = GetTime(), O.db.duration, O.db.intensity
    frame:SetAlpha(0)
    frame:Show()
end
