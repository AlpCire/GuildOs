
local ADDON, ns = ...
local G = GuildOS
G.UI = G.UI or {}
local UI = G.UI

local sections = {
    {"resumen", "Resumen"},
    {"roster", "Roster"},
    {"chat", "Chat"},
    {"actividad", "Actividad"},
    {"eventos", "Eventos"},
    {"perfiles", "Perfiles"},
    {"comunidades", "Comunidades"},
    {"info", "Info Hermandad"},
    {"logros", "Logros"},
    {"banco", "Banco"},
    {"reclutamiento", "Reclutamiento"},
    {"ajustes", "Ajustes"},
}

local function clear(f)
    if not f then return end
    if not f.children then f.children = {} end
    for _, child in ipairs(f.children) do child:Hide(); child:SetParent(nil) end
    wipe(f.children)
end

local function add(parent, child)
    parent.children = parent.children or {}
    table.insert(parent.children, child)
    return child
end

local function dot(parent, online)
    local t = parent:CreateTexture(nil, "OVERLAY")
    t:SetTexture("Interface\\Buttons\\WHITE8x8")
    t:SetSize(10, 10)
    if online then t:SetColorTexture(0.18, 0.85, 0.38, 1) else t:SetColorTexture(0.45, 0.48, 0.50, 0.75) end
    return t
end

function UI:Initialize()
    self.current = nil
    self.rosterOffset = 0
    self.rosterPerPage = 13
    self.chatKind = "guild"
    self:CreateMain()
end

function UI:CreateMain()
    local T = G.Theme
    local f = CreateFrame("Frame", "GuildOSFrame", UIParent, "BackdropTemplate")
    self.frame = f
    f:SetSize(1700, 1100)
    f:SetPoint("CENTER")
    f:SetFrameStrata("HIGH")
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetBackdrop({ bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=1 })
    f:SetBackdropColor(0.012, 0.025, 0.037, 0.965)
    f:SetBackdropBorderColor(0.15, 0.33, 0.48, 0.85)
    f:Hide()

    local header = add(f, T:Panel(f))
    self.header = header
    header:SetPoint("TOPLEFT", 0, 0)
    header:SetPoint("TOPRIGHT", 0, 0)
    header:SetHeight(118)
    header:SetBackdropColor(0.012,0.030,0.050,0.98)

    local emblem = add(f, CreateFrame("Frame", nil, header, "BackdropTemplate"))
    emblem:SetSize(82,82)
    emblem:SetPoint("TOPLEFT", 26, -10)
    emblem:SetBackdrop({ bgFile="Interface\\Buttons\\WHITE8x8", edgeFile="Interface\\Buttons\\WHITE8x8", edgeSize=2 })
    emblem:SetBackdropColor(0.02,0.12,0.20,0.95)
    emblem:SetBackdropBorderColor(0.95,0.68,0.05,1)
    local et = emblem:CreateTexture(nil, "ARTWORK")
    et:SetAllPoints(emblem)
    et:SetTexture("Interface\\GuildFrame\\GuildLogo")
    self.emblem = et

    self.title = header:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    self.title:SetPoint("TOPLEFT", 128, -22)
    self.title:SetTextColor(1,1,1)
    self.subtitle = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.subtitle:SetPoint("TOPLEFT", self.title, "BOTTOMLEFT", 0, -4)
    self.subtitle:SetTextColor(1,0.82,0.06)

    self.memberText = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.memberText:SetPoint("TOP", header, "TOP", -55, -34)
    self.onlineText = header:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    self.onlineText:SetPoint("LEFT", self.memberText, "RIGHT", 80, 0)

    local defaultBtn = add(f, T:Button(header, "Abrir panel de hermandad por defecto", 330, 40))
    defaultBtn:SetPoint("TOPRIGHT", -120, -32)
    defaultBtn:SetScript("OnClick", function() SlashCmdList.GUILDOS("default") end)

    local close = CreateFrame("Button", nil, header, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -8, -8)
    close:SetScript("OnClick", function() f:Hide() end)

    local sidebar = add(f, T:Panel(f))
    self.sidebar = sidebar
    sidebar:SetPoint("TOPLEFT", 12, -104)
    sidebar:SetPoint("BOTTOMLEFT", 12, 48)
    sidebar:SetWidth(240)

    self.navButtons = {}
    local y = -16
    for _, s in ipairs(sections) do
        local b = add(f, T:Button(sidebar, s[2], 174, 38))
        b:SetPoint("TOP", sidebar, "TOP", 0, y)
        b:SetScript("OnClick", function() UI:SetSection(s[1]) end)
        self.navButtons[s[1]] = b
        y = y - 52
    end
    local brand = sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    brand:SetPoint("BOTTOMLEFT", 28, 64)
    brand:SetText("|cff33aaffGuildOS|r")
    local ver = sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ver:SetPoint("TOPLEFT", brand, "BOTTOMLEFT", 0, -2)
    ver:SetText("|cff9aa3ad v"..G.VERSION.."|r")

    self.content = add(f, T:Panel(f))
    self.content:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", 10, 0)
    self.content:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -560, 58)

    self.right = add(f, T:Panel(f))
    self.right:SetPoint("TOPLEFT", self.content, "TOPRIGHT", 12, 0)
    self.right:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -12, 58)
    self.right:SetWidth(500)

    self.footer = add(f, T:Panel(f))
    self.footer:SetPoint("BOTTOMLEFT", 0, 0)
    self.footer:SetPoint("BOTTOMRIGHT", 0, 0)
    self.footer:SetHeight(54)
    local foot = self.footer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    foot:SetPoint("LEFT", 28, 0)
    foot:SetText([[|cffffcc00Mensaje del día:|r "El que no arriesga, no farmea."     |cff9aa3adSe renueva en:|r 28 días]])
    self.footerText = foot

    self:BuildRightPanel()
    self:RefreshAll()
    self:SetSection("roster")
end

function UI:Toggle()
    if not self.frame then self:CreateMain() end
    if self.frame:IsShown() then self.frame:Hide() else self.frame:Show(); if G.Data then G.Data:ScheduleRefresh(0.1) end; self:RefreshAll() end
end

function UI:SetSection(key)
    if self.current == key then return end
    self.current = key
    for k, b in pairs(self.navButtons or {}) do G.Theme:SetActive(b, k == key) end
    self:RenderSection()
end

function UI:RefreshAll(reason)
    if not self.frame then return end
    local total, online = 0, 0
    if G.Data then total, online = G.Data:GetCounts() end
    self.title:SetText(G.Data and G.Data:GetGuildName() or "Hermandad")
    self.subtitle:SetText(IsInGuild and IsInGuild() and "Hermandad" or "Sin hermandad")
    self.memberText:SetText(("Miembros |cffffffff%d|r"):format(total))
    self.onlineText:SetText(("Conectados |cff33ff66%d|r"):format(online))
    local motd = (GetGuildRosterMOTD and GetGuildRosterMOTD()) or ""
    if motd and motd ~= "" and self.footerText then
        self.footerText:SetText(("|cffffcc00Mensaje del día:|r %s"):format(motd))
    end
    self:RefreshChat()
    self:RefreshActivity()
    if self.current == "roster" or reason == "roster" then self:RenderSection() end
end

function UI:BuildRightPanel()
    local T = G.Theme
    local r = self.right
    clear(r)
    local tabs = {}
    local chatTab = add(r, T:Button(r, "Chat", 140, 36)); chatTab:SetPoint("TOPLEFT", 14, -14)
    local offTab = add(r, T:Button(r, "Oficiales", 140, 36)); offTab:SetPoint("LEFT", chatTab, "RIGHT", 8, 0)
    local regTab = add(r, T:Button(r, "Registro", 140, 36)); regTab:SetPoint("LEFT", offTab, "RIGHT", 8, 0)
    tabs.guild, tabs.officer = chatTab, offTab
    chatTab:SetScript("OnClick", function() self.chatKind="guild"; self:RefreshChat(); G.Theme:SetActive(chatTab,true); G.Theme:SetActive(offTab,false) end)
    offTab:SetScript("OnClick", function() self.chatKind="officer"; self:RefreshChat(); G.Theme:SetActive(chatTab,false); G.Theme:SetActive(offTab,true) end)
    regTab:SetScript("OnClick", function() self:SetSection("actividad") end)
    G.Theme:SetActive(chatTab,true)

    local chatBox = add(r, T:Panel(r))
    self.chatBox = chatBox
    chatBox:SetPoint("TOPLEFT", 14, -58)
    chatBox:SetPoint("TOPRIGHT", -14, -58)
    chatBox:SetHeight(430)
    local title = chatBox:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 14, -12)
    title:SetText("|cff33ff66Hermandad|r")
    self.chatTitle = title

    self.chatLines = {}
    for i=1,14 do
        local fs = chatBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetPoint("TOPLEFT", 14, -38 - (i-1)*26)
        fs:SetPoint("RIGHT", -14, 0)
        fs:SetJustifyH("LEFT")
        fs:SetTextColor(0.9,0.92,0.95)
        self.chatLines[i] = fs
    end
    local edit = CreateFrame("EditBox", nil, chatBox, "InputBoxTemplate")
    self.chatEdit = edit
    edit:SetHeight(28)
    edit:SetPoint("BOTTOMLEFT", 14, 14)
    edit:SetPoint("BOTTOMRIGHT", -58, 14)
    edit:SetAutoFocus(false)
    edit:SetScript("OnEnterPressed", function(e) if G.Chat then G.Chat:Send(self.chatKind, e:GetText()) end; e:SetText(""); e:ClearFocus() end)
    local send = add(r, T:Button(chatBox, "➜", 44, 30))
    send:SetPoint("LEFT", edit, "RIGHT", 10, 0)
    send:SetScript("OnClick", function() if G.Chat then G.Chat:Send(self.chatKind, edit:GetText()) end; edit:SetText("") end)

    local act = add(r, T:Panel(r))
    self.activityBox = act
    act:SetPoint("TOPLEFT", chatBox, "BOTTOMLEFT", 0, -12)
    act:SetPoint("BOTTOMRIGHT", -14, 14)
    local at = act:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    at:SetPoint("TOPLEFT", 14, -14)
    at:SetText("Actividad reciente")
    self.activityLines = {}
    for i=1,5 do
        local fs = act:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetPoint("TOPLEFT", 18, -46 - (i-1)*38)
        fs:SetPoint("RIGHT", -16, 0)
        fs:SetJustifyH("LEFT")
        self.activityLines[i] = fs
    end
end

function UI:RefreshChat()
    if not self.chatLines then return end
    local kind = self.chatKind or "guild"
    if self.chatTitle then self.chatTitle:SetText(kind == "officer" and "|cffff9966Oficiales|r" or "|cff33ff66Hermandad|r") end
    local lines = G.Chat and G.Chat:GetLines(kind) or {}
    local start = math.max(1, #lines - #self.chatLines + 1)
    for i, fs in ipairs(self.chatLines) do
        fs:SetText(lines[start + i - 1] or "")
    end
end

function UI:RefreshActivity()
    if not self.activityLines then return end
    G:EnsureDB()
    for i, fs in ipairs(self.activityLines) do
        local a = G.db.activity[i]
        if a then
            fs:SetText(("|cffffcc00%s|r  %s"):format(date("%d/%m %H:%M", a.time or time()), a.text or ""))
        else
            fs:SetText("")
        end
    end
end

function UI:RenderSection()
    local T = G.Theme
    clear(self.content)
    if self.current == "roster" then
        self:RenderRoster()
    elseif self.current == "resumen" then
        self:RenderSummary()
    else
        self:RenderSimpleSection(self.current)
    end
end

function UI:HeaderText(parent, title, subtitle)
    local h = add(parent, parent:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge"))
    h:SetPoint("TOPLEFT", 22, -18)
    h:SetText(title)
    h:SetTextColor(1,1,1)
    local s = add(parent, parent:CreateFontString(nil, "OVERLAY", "GameFontNormal"))
    s:SetPoint("TOPLEFT", h, "BOTTOMLEFT", 0, -6)
    s:SetTextColor(0.78,0.82,0.88)
    s:SetText(subtitle or "")
    return h
end

function UI:RenderRoster()
    local c = self.content

    local tabs = {"Roster", "Notas", "Rangos", "Invitaciones"}
    self.rosterTabs = {}
    for i, name in ipairs(tabs) do
        local b = add(c, G.Theme:Button(c, name, 180, 40))
        b:SetPoint("TOPLEFT", 14 + (i - 1) * 190, -14)
        if i == 1 then
            G.Theme:SetActive(b, true)
        else
            b:SetAlpha(0.8)
        end
        self.rosterTabs[i] = b
    end

    local search = CreateFrame("EditBox", nil, c, "InputBoxTemplate")
    add(c, search)
    search:SetSize(520, 34)
    search:SetPoint("TOPLEFT", 20, -70)
    search:SetAutoFocus(false)
    search:SetText(G.Data and G.Data.search or "")
    search:SetScript("OnTextChanged", function(e)
        if G.Data then G.Data:ApplyFilter(e:GetText()) end
        UI.rosterOffset = 0
        UI:RenderRosterRows()
    end)

    local rankFilter = add(c, G.Theme:Button(c, G.Data and (G.Data.rankFilter or "Todos los rangos") or "Todos los rangos", 230, 34))
    rankFilter:SetPoint("LEFT", search, "RIGHT", 16, 0)
    rankFilter:SetScript("OnClick", function()
        if not G.Data then return end
        local ranks = G.Data:GetRanks()
        local current = G.Data.rankFilter or "Todos los rangos"
        local idx = 1
        for i, v in ipairs(ranks) do if v == current then idx = i break end end
        idx = idx + 1
        if idx > #ranks then idx = 1 end
        G.Data.rankFilter = ranks[idx]
        if rankFilter.text then rankFilter.text:SetText(ranks[idx]) end
        G.Data:ApplyFilter(search:GetText(), ranks[idx])
        UI.rosterOffset = 0
        UI:RenderRosterRows()
    end)

    local refresh = add(c, G.Theme:Button(c, "↻", 44, 34))
    refresh:SetPoint("LEFT", rankFilter, "RIGHT", 10, 0)
    refresh:SetScript("OnClick", function() if G.Data then G.Data:ScheduleRefresh(0) end end)

    local tablePanel = add(c, G.Theme:Panel(c))
    self.rosterTable = tablePanel
    tablePanel:SetPoint("TOPLEFT", 12, -112)
    tablePanel:SetPoint("BOTTOMRIGHT", -12, 64)
    tablePanel:SetBackdropColor(0.015,0.040,0.060,0.82)
    tablePanel:EnableMouseWheel(true)
    tablePanel:SetScript("OnMouseWheel", function(_, delta)
        local count = #(G.Data and G.Data.filtered or {})
        local maxOffset = math.max(0, count - (UI.rosterPerPage or 13))
        UI.rosterOffset = math.max(0, math.min(maxOffset, (UI.rosterOffset or 0) - delta))
        UI:RenderRosterRows()
    end)

    local headers = {{"Nombre",80},{"Rango",260},{"Clase",430},{"Zona",590},{"Nota",812}}
    for _, h in ipairs(headers) do
        local fs = tablePanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        fs:SetPoint("TOPLEFT", h[2], -20)
        fs:SetTextColor(1,0.78,0.05)
        fs:SetText(h[1])
    end

    self.rosterRows = {}
    for i=1,(self.rosterPerPage or 13) do
        local row = add(c, G.Theme:Panel(tablePanel))
        row:SetPoint("TOPLEFT", 0, -48 - (i-1)*52)
        row:SetPoint("RIGHT", 0, 0)
        row:SetHeight(50)
        row:SetBackdropColor(0.025,0.065,0.095,0.48)
        row.dot = dot(row, false); row.dot:SetPoint("LEFT", 24, 0)
        row.name = row:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"); row.name:SetPoint("LEFT", 70, 0); row.name:SetWidth(170); row.name:SetJustifyH("LEFT")
        row.rank = row:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"); row.rank:SetPoint("LEFT", 250, 0); row.rank:SetWidth(160); row.rank:SetJustifyH("LEFT")
        row.class = row:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"); row.class:SetPoint("LEFT", 420, 0); row.class:SetWidth(160); row.class:SetJustifyH("LEFT")
        row.zone = row:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"); row.zone:SetPoint("LEFT", 580, 0); row.zone:SetWidth(230); row.zone:SetJustifyH("LEFT")
        row.note = row:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"); row.note:SetPoint("LEFT", 820, 0); row.note:SetWidth(190); row.note:SetJustifyH("LEFT")
        self.rosterRows[i] = row
    end

    local prev = add(c, G.Theme:Button(c, "‹", 34, 28))
    prev:SetPoint("BOTTOM", c, "BOTTOM", -70, 26)
    prev:SetScript("OnClick", function()
        local per = UI.rosterPerPage or 13
        UI.rosterOffset = math.max(0, (UI.rosterOffset or 0) - per)
        UI:RenderRosterRows()
    end)

    local nextBtn = add(c, G.Theme:Button(c, "›", 34, 28))
    nextBtn:SetPoint("BOTTOM", c, "BOTTOM", 70, 26)
    nextBtn:SetScript("OnClick", function()
        local list = G.Data and G.Data.filtered or {}
        local per = UI.rosterPerPage or 13
        local maxOffset = math.max(0, #list - per)
        UI.rosterOffset = math.min(maxOffset, (UI.rosterOffset or 0) + per)
        UI:RenderRosterRows()
    end)

    local pager = add(c, c:CreateFontString(nil, "OVERLAY", "GameFontNormal"))
    self.rosterPager = pager
    pager:SetPoint("BOTTOM", c, "BOTTOM", 0, 26)
    pager:SetTextColor(0.80,0.84,0.90)

    local footer = add(c, c:CreateFontString(nil, "OVERLAY", "GameFontNormal"))
    self.rosterFooter = footer
    footer:SetPoint("BOTTOMRIGHT", -20, 26)
    footer:SetTextColor(0.70,0.74,0.80)

    self:RenderRosterRows()
end

function UI:RenderRosterRows()
    if not self.rosterRows then return end
    local list = G.Data and G.Data.filtered or {}
    local off = self.rosterOffset or 0
    local per = self.rosterPerPage or 13
    for i, row in ipairs(self.rosterRows) do
        local m = list[off+i]
        if m then
            row:Show()
            local alpha = m.online and 1 or 0.52
            row:SetAlpha(alpha)
            row.dot:SetColorTexture(m.online and 0.18 or 0.55, m.online and 0.85 or 0.58, m.online and 0.38 or 0.60, m.online and 1 or 0.75)
            local r,g,b = G.Theme:ClassColor(m.classFile)
            row.name:SetText(m.name or "-"); row.name:SetTextColor(r,g,b)
            row.rank:SetText(m.rank or "-"); row.rank:SetTextColor(0.88,0.88,0.90)
            row.class:SetText(m.class or "-"); row.class:SetTextColor(r,g,b)
            row.zone:SetText(m.zone or "-"); row.zone:SetTextColor(0.88,0.88,0.90)
            row.note:SetText(m.note or "-"); row.note:SetTextColor(0.78,0.80,0.84)
        else
            row:Hide()
        end
    end
    if self.rosterFooter then
        local startIdx = (#list == 0) and 0 or (off + 1)
        local endIdx = math.min(#list, off + per)
        self.rosterFooter:SetText(("Mostrando %d - %d de %d miembros"):format(startIdx, endIdx, #list))
        if self.rosterPager then
            local page = (#list == 0) and 1 or math.floor(off / per) + 1
            local pages = math.max(1, math.ceil(#list / per))
            self.rosterPager:SetText(("Página %d de %d"):format(page, pages))
        end
    end
end

function UI:RenderSummary()
    local c = self.content
    local stats = self:BuildGuildStats()
    self:HeaderText(c, "Resumen", "Vista unificada de estado de hermandad, actividad y composición.")

    local cards = {
        {"Miembros", tostring(stats.total)},
        {"Conectados", tostring(stats.online)},
        {"Clases", tostring((function() local n=0 for _ in pairs(stats.classes) do n=n+1 end return n end)())},
        {"Peers Sync", tostring(G.db and G.db.sync and G.db.sync.peers and (function() local n=0 for _ in pairs(G.db.sync.peers) do n=n+1 end return n end)() or 0)},
    }
    for i, card in ipairs(cards) do
        local p = add(c, G.Theme:Panel(c))
        p:SetSize(255, 100)
        p:SetPoint("TOPLEFT", 24 + (i-1)*272, -96)
        local a = p:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        a:SetPoint("TOPLEFT", 16, -18); a:SetTextColor(0.7,0.75,0.82); a:SetText(card[1])
        local b = p:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
        b:SetPoint("BOTTOMLEFT", 16, 18); b:SetTextColor(1,1,1); b:SetText(card[2])
    end

    local left = createInfoPanel(c, 24, -220, 540, 450, "Top clases")
    local classes = self:TopFromMap(stats.classes, 14)
    if #classes == 0 then classes = {"Sin datos de clases."} end
    self:RenderTextList(left, classes)

    local mid = createInfoPanel(c, 590, -220, 544, 450, "Top zonas")
    local zones = self:TopFromMap(stats.zones, 14)
    if #zones == 0 then zones = {"Sin datos de zonas."} end
    self:RenderTextList(mid, zones)

    local act = createInfoPanel(c, 24, -686, 1110, 180, "Actividad reciente")
    G:EnsureDB()
    local lines = {}
    for i=1, math.min(5, #(G.db.activity or {})) do
        local a = G.db.activity[i]
        lines[#lines+1] = string.format("|cffffcc00%s|r %s", date("%d/%m %H:%M", a.time or time()), a.text or "")
    end
    if #lines == 0 then lines = {"Sin actividad registrada."} end
    self:RenderTextList(act, lines)
end

function UI:RenderSimpleSection(key)
    self:RenderFunctionalSection(key)
end

local function createInfoPanel(parent, x, y, w, h, title)
    local panel = add(parent, G.Theme:Panel(parent))
    panel:SetPoint("TOPLEFT", x, y)
    panel:SetSize(w, h)
    local t = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    t:SetPoint("TOPLEFT", 14, -12)
    t:SetTextColor(1, 0.82, 0.06)
    t:SetText(title or "")
    return panel
end

function UI:RenderTextList(panel, lines)
    for i, line in ipairs(lines or {}) do
        local fs = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetPoint("TOPLEFT", 16, -40 - (i-1)*24)
        fs:SetPoint("RIGHT", -16, 0)
        fs:SetJustifyH("LEFT")
        fs:SetText(line)
    end
end

function UI:BuildGuildStats()
    local stats = { total=0, online=0, mobile=0, maxLevel=0, classes={}, zones={}, ranks={} }
    if not G.Data then return stats end
    for _, m in ipairs(G.Data.roster or {}) do
        stats.total = stats.total + 1
        if m.online then stats.online = stats.online + 1 end
        if m.status and m.status > 0 then stats.mobile = stats.mobile + 1 end
        if (m.level or 0) > stats.maxLevel then stats.maxLevel = m.level or 0 end
        stats.classes[m.class or "-"] = (stats.classes[m.class or "-"] or 0) + 1
        stats.zones[m.zone or "-"] = (stats.zones[m.zone or "-"] or 0) + 1
        stats.ranks[m.rank or "-"] = (stats.ranks[m.rank or "-"] or 0) + 1
    end
    return stats
end

function UI:TopFromMap(map, maxItems)
    local arr = {}
    for k, v in pairs(map or {}) do arr[#arr+1] = {k, v} end
    table.sort(arr, function(a,b) return a[2] > b[2] end)
    local out = {}
    for i=1, math.min(maxItems or 5, #arr) do
        out[#out+1] = string.format("%s: |cffffffff%d|r", arr[i][1], arr[i][2])
    end
    return out
end

function UI:RenderFunctionalSection(key)
    local c = self.content
    local stats = self:BuildGuildStats()
    if key == "chat" then
        self:HeaderText(c, "Chat", "Historial de hermandad y oficiales sincronizado con eventos reales de chat.")
        local p = createInfoPanel(c, 24, -92, 1110, 760, "Historial")
        local kind = self.chatKind or "guild"
        local lines = G.Chat and G.Chat:GetLines(kind) or {}
        local out = {}
        local start = math.max(1, #lines - 26)
        for i = start, #lines do out[#out+1] = lines[i] end
        if #out == 0 then out = {"No hay líneas todavía. Escribe en el chat de hermandad para poblar historial."} end
        self:RenderTextList(p, out)
    elseif key == "actividad" then
        self:HeaderText(c, "Actividad", "Eventos locales recientes (chat/sync/conexiones).")
        local p = createInfoPanel(c, 24, -92, 1110, 760, "Timeline")
        G:EnsureDB(); local lines = {}
        for i=1, math.min(24, #(G.db.activity or {})) do local a = G.db.activity[i]; lines[#lines+1] = string.format("|cffffcc00%s|r  %s", date("%d/%m %H:%M", a.time or time()), a.text or "") end
        if #lines == 0 then lines = {"Sin actividad registrada todavía."} end
        self:RenderTextList(p, lines)
    elseif key == "eventos" then
        self:HeaderText(c, "Eventos", "Eventos próximos de calendario (vista rápida).")
        local p = createInfoPanel(c, 24, -92, 1110, 620, "Próximos eventos")
        local lines = {}
        if C_Calendar and C_Calendar.GetNumDayEvents and C_Calendar.GetDayEvent then
            for d=0, 14 do
                local num = C_Calendar.GetNumDayEvents(0, d) or 0
                for i=1, num do
                    local ev = C_Calendar.GetDayEvent(0, d, i)
                    if ev and ev.title then lines[#lines+1] = string.format("+%dd | %s (%s)", d, ev.title, ev.calendarType or "guild") end
                end
            end
        end
        if #lines == 0 then lines = {"No hay eventos próximos visibles por API en este momento."} end
        self:RenderTextList(p, lines)
        local b = add(c, G.Theme:Button(c, "Abrir Calendario", 240, 40)); b:SetPoint("TOPLEFT", 40, -730); b:SetScript("OnClick", function() if ToggleCalendar then ToggleCalendar() end end)
    elseif key == "perfiles" then
        self:HeaderText(c, "Perfiles", "Datos del personaje actual y estado de hermandad.")
        local p = createInfoPanel(c, 24, -92, 540, 300, "Personaje")
        local lvl = UnitLevel("player") or 0
        self:RenderTextList(p, {"Nombre: "..(UnitName("player") or "?"), "Clase: "..(select(1, UnitClass("player")) or "?"), "Nivel: "..lvl, "Hermandad: "..(G.Data and G.Data:GetGuildName() or "-")})
    elseif key == "comunidades" then
        self:HeaderText(c, "Comunidades", "Acceso mejorado y directo al panel completo oficial.")
        local p = createInfoPanel(c, 24, -92, 1110, 620, "Estado")
        self:RenderTextList(p, {"La API de comunidades no permite un clon completo seguro del panel Blizzard.", "GuildOS prioriza estabilidad y usa integración oficial para navegación completa."})
        local b = add(c, G.Theme:Button(c, "Abrir Hermandad y Comunidades oficial", 360, 42)); b:SetPoint("TOPLEFT", 24, -730); b:SetScript("OnClick", function() SlashCmdList.GUILDOS("default") end)
    elseif key == "info" then
        self:HeaderText(c, "Info Hermandad", "Resumen ampliado de datos reales.")
        local p = createInfoPanel(c, 24, -92, 540, 380, "Métricas")
        local motd = (GetGuildRosterMOTD and GetGuildRosterMOTD()) or "-"
        self:RenderTextList(p, {"Nombre: "..(G.Data and G.Data:GetGuildName() or "-"), "MOTD: "..motd, "Miembros: "..stats.total, "Conectados: "..stats.online, "Desconectados: "..math.max(0, stats.total - stats.online), "Movil/Away/DND: "..stats.mobile})
    elseif key == "logros" then
        self:HeaderText(c, "Logros", "Panel rápido de logros con acceso al panel oficial.")
        local p = createInfoPanel(c, 24, -92, 1110, 520, "Resumen")
        local ap = GetTotalAchievementPoints and GetTotalAchievementPoints() or 0
        self:RenderTextList(p, {"Puntos de logro del personaje: "..ap})
        local b = add(c, G.Theme:Button(c, "Abrir panel de logros", 280, 40)); b:SetPoint("TOPLEFT", 40, -640); b:SetScript("OnClick", function() if ToggleAchievementFrame then ToggleAchievementFrame() end end)
    elseif key == "banco" then
        self:HeaderText(c, "Banco", "Estado del banco de hermandad + acceso oficial.")
        local p = createInfoPanel(c, 24, -92, 1110, 440, "Arcas")
        local money = (GetGuildBankMoney and GetGuildBankMoney()) or 0
        local gold = math.floor(money / 10000)
        local silver = math.floor((money % 10000) / 100)
        local copper = money % 100
        self:RenderTextList(p, {string.format("Oro en arcas: |cffffd100%d|r g |cffc7c7cf%d|r s |cffb87333%d|r c", gold, silver, copper)})
        local b = add(c, G.Theme:Button(c, "Abrir Banco de Hermandad", 300, 42)); b:SetPoint("TOPLEFT", 40, -560); b:SetScript("OnClick", function() if ToggleGuildBank then ToggleGuildBank() end end)
    elseif key == "reclutamiento" then
        self:HeaderText(c, "Reclutamiento", "Mensajes internos rápidos y composición actual.")
        local p = createInfoPanel(c, 24, -92, 1110, 600, "Composición y plantillas")
        local lines = self:TopFromMap(stats.classes, 14)
        if #lines == 0 then lines = {"Sin datos de roster."} end
        table.insert(lines, 1, "Usa: /gos reclutar dps | heal | tank")
        self:RenderTextList(p, lines)
    elseif key == "ajustes" then
        self:HeaderText(c, "Ajustes", "Configuración, atajos y diagnóstico.")
        local p = createInfoPanel(c, 24, -92, 1110, 700, "Estado")
        G:EnsureDB(); local lines = {"/gos replace on/off", "/gos sync", "/gos default", "/gos reclutar dps|heal|tank", "", "Replace tecla J: "..(G.db.settings and G.db.settings.replaceDefault and "ACTIVO" or "INACTIVO"), "Peers detectados:"}
        for name, peer in pairs(G.db.sync.peers or {}) do lines[#lines+1] = string.format("- %s v%s (hace %ss)", name, tostring(peer.version), time() - (peer.last or time())) end
        if #lines == 7 then lines[#lines+1] = "- Ninguno" end
        self:RenderTextList(p, lines)
    end
end
