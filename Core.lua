
local ADDON, ns = ...
GuildOS = GuildOS or {}
ns.GuildOS = GuildOS

GuildOS.VERSION = "0.6.0"
GuildOS.ADDON_PREFIX = "GUILDOS"

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33aaffGuildOS:|r "..tostring(msg))
end
GuildOS.Print = Print

function GuildOS:SafeCall(label, fn, ...)
    if type(fn) ~= "function" then return nil end
    local ok, a, b, c, d = pcall(fn, ...)
    if not ok then
        Print("Error en "..tostring(label)..": "..tostring(a))
        return nil
    end
    return a, b, c, d
end

function GuildOS:EnsureDB()
    GuildOS_DB = GuildOS_DB or {}
    local db = GuildOS_DB
    db.version = db.version or 5
    db.settings = db.settings or {}
    if db.settings.replaceDefault == nil then db.settings.replaceDefault = false end
    db.chat = db.chat or { guild = {}, officer = {} }
    db.activity = db.activity or {}
    db.profiles = db.profiles or {}
    db.sync = db.sync or { peers = {} }
    self.db = db
end

function GuildOS:AddActivity(text, kind)
    self:EnsureDB()
    local t = {
        time = time(),
        text = tostring(text or ""),
        kind = kind or "info",
    }
    table.insert(self.db.activity, 1, t)
    while #self.db.activity > 80 do table.remove(self.db.activity) end
    if self.UI and self.UI.RefreshActivity then self.UI:RefreshActivity() end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("GUILD_ROSTER_UPDATE")
frame:RegisterEvent("PLAYER_GUILD_UPDATE")
frame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == ADDON then
            GuildOS:EnsureDB()
        end
    elseif event == "PLAYER_LOGIN" then
        GuildOS:EnsureDB()
        if GuildOS.Theme and GuildOS.Theme.Initialize then GuildOS.Theme:Initialize() end
        if GuildOS.Data and GuildOS.Data.Initialize then GuildOS.Data:Initialize() end
        if GuildOS.Chat and GuildOS.Chat.Initialize then GuildOS.Chat:Initialize() end
        if GuildOS.Sync and GuildOS.Sync.Initialize then GuildOS.Sync:Initialize() end
        if GuildOS.UI and GuildOS.UI.Initialize then GuildOS.UI:Initialize() end
        Print("cargado. Usa /gos para abrir. /gos default abre la UI original.")
    elseif event == "GUILD_ROSTER_UPDATE" or event == "PLAYER_GUILD_UPDATE" then
        if GuildOS.Data and GuildOS.Data.ScheduleRefresh then GuildOS.Data:ScheduleRefresh() end
    end
end)

SLASH_GUILDOS1 = "/gos"
SLASH_GUILDOS2 = "/guildos"
SlashCmdList.GUILDOS = function(msg)
    msg = string.lower(strtrim(msg or ""))
    GuildOS:EnsureDB()
    if msg == "default" then
        if CommunitiesFrame then ShowUIPanel(CommunitiesFrame)
        elseif ToggleGuildFrame then ToggleGuildFrame()
        elseif C_AddOns and C_AddOns.LoadAddOn then C_AddOns.LoadAddOn("Blizzard_Communities"); if CommunitiesFrame then ShowUIPanel(CommunitiesFrame) end
        end
        return
    elseif msg == "replace on" then
        GuildOS.db.settings.replaceDefault = true
        Print("Reemplazo de tecla J activado tras reload.")
        return
    elseif msg == "replace off" then
        GuildOS.db.settings.replaceDefault = false
        Print("Reemplazo de tecla J desactivado.")
        return
    elseif msg == "sync" then
        if GuildOS.Sync then GuildOS.Sync:Ping() end
        return
    elseif msg == "help" or msg == "ayuda" then
        Print("/gos abre GuildOS. /gos default abre Hermandad y Comunidades original. /gos replace on/off. /gos sync.")
        return
    end
    if GuildOS.UI then GuildOS.UI:Toggle() end
end
