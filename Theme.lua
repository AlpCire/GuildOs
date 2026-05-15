
local ADDON, ns = ...
local G = GuildOS
G.Theme = G.Theme or {}
local T = G.Theme

T.colors = {
    bg = {0.015, 0.030, 0.045, 0.94},
    panel = {0.020, 0.055, 0.075, 0.90},
    panel2 = {0.030, 0.080, 0.120, 0.88},
    stroke = {0.20, 0.38, 0.52, 0.75},
    strokeBright = {0.95, 0.68, 0.05, 0.95},
    blue = {0.04, 0.24, 0.48, 0.92},
    gold = {1.0, 0.78, 0.05, 1},
    text = {0.88, 0.90, 0.94, 1},
    muted = {0.55, 0.60, 0.66, 1},
    green = {0.2, 0.85, 0.35, 1},
}

local backdrop = {
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
}

function T:Initialize() end

function T:Panel(parent, name)
    local f = CreateFrame("Frame", name, parent, "BackdropTemplate")
    f:SetBackdrop(backdrop)
    f:SetBackdropColor(unpack(self.colors.panel))
    f:SetBackdropBorderColor(unpack(self.colors.stroke))
    return f
end

function T:Button(parent, text, w, h)
    local b = CreateFrame("Button", nil, parent, "BackdropTemplate")
    b:SetSize(w or 150, h or 34)
    b:SetBackdrop(backdrop)
    b:SetBackdropColor(0.025, 0.055, 0.080, 0.86)
    b:SetBackdropBorderColor(unpack(self.colors.stroke))
    b.text = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    b.text:SetPoint("CENTER")
    b.text:SetText(text or "")
    b.text:SetTextColor(0.92, 0.94, 1)
    b:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.05, 0.14, 0.24, 0.94)
        self:SetBackdropBorderColor(0.40, 0.62, 0.85, 0.95)
    end)
    b:SetScript("OnLeave", function(self)
        if self.__active then
            self:SetBackdropColor(0.04, 0.24, 0.48, 0.92)
            self:SetBackdropBorderColor(unpack(T.colors.strokeBright))
        else
            self:SetBackdropColor(0.025, 0.055, 0.080, 0.86)
            self:SetBackdropBorderColor(unpack(T.colors.stroke))
        end
    end)
    return b
end

function T:SetActive(button, active)
    if not button or not button.SetBackdropColor then return end
    button.__active = active and true or false
    if button.__active then
        button:SetBackdropColor(0.04, 0.24, 0.48, 0.92)
        button:SetBackdropBorderColor(unpack(self.colors.strokeBright))
        if button.text then button.text:SetTextColor(1, 1, 1) end
    else
        button:SetBackdropColor(0.025, 0.055, 0.080, 0.86)
        button:SetBackdropBorderColor(unpack(self.colors.stroke))
        if button.text then button.text:SetTextColor(0.92, 0.94, 1) end
    end
end

function T:Label(parent, text, size, color)
    local fs = parent:CreateFontString(nil, "OVERLAY", size and "GameFontNormalLarge" or "GameFontNormal")
    fs:SetText(text or "")
    if color then fs:SetTextColor(unpack(color)) else fs:SetTextColor(unpack(self.colors.text)) end
    return fs
end

function T:ClassColor(classFile)
    local c = classFile and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
    if c then return c.r, c.g, c.b end
    return 0.9, 0.9, 0.9
end
