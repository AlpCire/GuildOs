
local ADDON, ns = ...
local G = GuildOS
G.Chat = G.Chat or {}
local C = G.Chat
C.maxLines = 120

local function colorName(name, guid)
    local class
    if guid and GetPlayerInfoByGUID then
        local _, classFile = GetPlayerInfoByGUID(guid)
        class = classFile
    end
    if not class and G.Data and G.Data.roster then
        local short = Ambiguate(name or "", "none")
        for _, m in ipairs(G.Data.roster) do
            if m.name == short or m.rawName == name then class = m.classFile break end
        end
    end
    local c = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    if c then
        local r = math.floor((c.r or 1) * 255 + 0.5)
        local g = math.floor((c.g or 1) * 255 + 0.5)
        local b = math.floor((c.b or 1) * 255 + 0.5)
        return string.format("|cff%02x%02x%02x%s|r", r, g, b, Ambiguate(name or "?", "none"))
    end
    return "|cffffffff"..(Ambiguate(name or "?", "none")).."|r"
end

local function push(kind, line)
    G:EnsureDB()
    local bucket = kind == "officer" and G.db.chat.officer or G.db.chat.guild
    table.insert(bucket, line)
    while #bucket > C.maxLines do table.remove(bucket, 1) end
end

function C:Initialize()
    self.frame = CreateFrame("Frame")
    self.frame:RegisterEvent("CHAT_MSG_GUILD")
    self.frame:RegisterEvent("CHAT_MSG_OFFICER")
    self.frame:SetScript("OnEvent", function(_, event, msg, author, lang, channel, target, flags, unknown, channelNumber, channelName, unknown2, counter, guid)
        local kind = event == "CHAT_MSG_OFFICER" and "officer" or "guild"
        local stamp = date("%H:%M")
        local line = string.format("|cff8b96a8[%s]|r [%s]: %s", stamp, colorName(author, guid), tostring(msg or ""))
        push(kind, line)
        G:AddActivity(string.format("%s: %s", Ambiguate(author or "?", "none"), msg or ""), "chat")
        if G.UI and G.UI.RefreshChat then G.UI:RefreshChat() end
    end)
end

function C:GetLines(kind)
    G:EnsureDB()
    return kind == "officer" and G.db.chat.officer or G.db.chat.guild
end

function C:Send(kind, text)
    text = strtrim(text or "")
    if text == "" then return end
    if kind == "officer" then
        SendChatMessage(text, "OFFICER")
    else
        SendChatMessage(text, "GUILD")
    end
end
