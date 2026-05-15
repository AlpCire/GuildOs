
local ADDON, ns = ...
local G = GuildOS
G.Data = G.Data or {}
local D = G.Data

D.roster = {}
D.filtered = {}
D.pending = false
D.trailingRequested = false

local function safe(v, fallback)
    if v == nil or v == "" then return fallback or "-" end
    return v
end

local function fullName(name)
    if not name then return "-" end
    return Ambiguate(name, "none") or name
end

function D:Initialize()
    self:ScheduleRefresh(0.5)
end

function D:ScheduleRefresh(delay)
    if self.pending then
        self.trailingRequested = true
        return
    end
    self.pending = true
    C_Timer.After(delay or 0.25, function()
        self.pending = false
        self:RefreshRoster()
        if self.trailingRequested then
            self.trailingRequested = false
            self:ScheduleRefresh(0.15)
        end
    end)
end

function D:GetGuildName()
    local n = GetGuildInfo("player")
    return n or "Sin hermandad"
end

function D:RefreshRoster()
    wipe(self.roster)
    if IsInGuild and IsInGuild() then
        if GuildRoster then pcall(GuildRoster) end
        local count = (GetNumGuildMembers and GetNumGuildMembers()) or 0
        for i = 1, count do
            local name, rankName, rankIndex, level, classDisplayName, zone, note, officerNote, online, status, classFileName, achievementPoints, achievementRank, isMobile, canSoR, repStanding, guid = GetGuildRosterInfo(i)
            if name then
                table.insert(self.roster, {
                    index = i,
                    name = fullName(name),
                    rawName = name,
                    rank = safe(rankName),
                    rankIndex = rankIndex or 999,
                    level = level or 0,
                    class = safe(classDisplayName),
                    classFile = classFileName,
                    zone = safe(zone),
                    note = safe(note, "-"),
                    online = online and true or false,
                    status = status or 0,
                    guid = guid,
                })
            end
        end
    end
    table.sort(self.roster, function(a, b)
        if a.online ~= b.online then return a.online end
        return strcmputf8i(a.name or "", b.name or "") < 0
    end)
    self:ApplyFilter()
    if G.UI and G.UI.RefreshAll then G.UI:RefreshAll("roster") end
end

function D:ApplyFilter(query)
    self.search = query or self.search or ""
    local q = string.lower(self.search)
    wipe(self.filtered)
    for _, m in ipairs(self.roster) do
        if q == "" or string.find(string.lower(m.name or ""), q, 1, true) or string.find(string.lower(m.rank or ""), q, 1, true) or string.find(string.lower(m.class or ""), q, 1, true) then
            table.insert(self.filtered, m)
        end
    end
end

function D:GetCounts()
    local total, online = #self.roster, 0
    for _, m in ipairs(self.roster) do if m.online then online = online + 1 end end
    return total, online
end
