
local ADDON, ns = ...
local G = GuildOS
G.Sync = G.Sync or {}
local S = G.Sync
S.peerTTL = 900

function S:Initialize()
    G:EnsureDB()
    self.prefix = G.ADDON_PREFIX
    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
        pcall(C_ChatInfo.RegisterAddonMessagePrefix, self.prefix)
    end
    self.frame = CreateFrame("Frame")
    self.frame:RegisterEvent("CHAT_MSG_ADDON")
    self.frame:SetScript("OnEvent", function(_, _, prefix, msg, channel, sender)
        if prefix ~= S.prefix then return end
        S:OnMessage(msg, channel, sender)
    end)
    C_Timer.After(3, function() S:Ping() end)
    C_Timer.NewTicker(60, function() S:CleanupPeers() end)
end

function S:Send(msg)
    if not IsInGuild or not IsInGuild() then return end
    if C_ChatInfo and C_ChatInfo.SendAddonMessage then
        pcall(C_ChatInfo.SendAddonMessage, self.prefix, msg, "GUILD")
    end
end

function S:Ping()
    self:Send("PING:"..G.VERSION)
end


function S:CleanupPeers()
    G:EnsureDB()
    local now = time()
    for name, p in pairs(G.db.sync.peers or {}) do
        if type(p) ~= "table" or (p.last and (now - p.last) > self.peerTTL) then
            G.db.sync.peers[name] = nil
        end
    end
end

function S:OnMessage(msg, channel, sender)
    G:EnsureDB()
    sender = Ambiguate(sender or "?", "none")
    local cmd, payload = strsplit(":", msg or "", 2)
    if cmd == "PING" then
        G.db.sync.peers[sender] = { version = payload or "?", last = time() }
        self:Send("PONG:"..G.VERSION)
    elseif cmd == "PONG" then
        G.db.sync.peers[sender] = { version = payload or "?", last = time() }
    end
    if G.UI and G.UI.current == "ajustes" then G.UI:RenderSection() end
end
