-- ============================================================
--  UnchartedUI — layout.lua
--  oUF layout: player, target, pet frames.
--  Get these working first before adding anything else.
--
--  Player frame: centered bottom of screen
--  Target frame: offset upper-right of player
--
--  /uui unlock  — drag frames
--  /uui lock    — lock frames
-- ============================================================

-- -------------------------------------------------------
-- Config — change these to taste
-- -------------------------------------------------------
local W          = 220   -- frame width
local H          = 36    -- frame height (health + power combined)
local HEALTH_H   = 26    -- health bar height
local POWER_H    = 6     -- power bar height
local CAST_H     = 16    -- castbar height
local CAST_GAP   = 2     -- gap between frame bottom and castbar

local PLAYER_X   = 0     -- horizontal offset from screen center
local PLAYER_Y   = 195   -- distance from bottom of screen
local TARGET_X   = 285   -- target X offset from center (puts it right of player)
local TARGET_Y   = 248   -- target Y from bottom (higher than player = upper-right)

-- Pet frame config
local PET_W      = 130   -- narrower than player
local PET_H      = 12    -- slim but visible health bar
local PET_X      = 0     -- centered under player
local PET_GAP    = 4     -- gap below castbar

local FONT       = "Fonts\\FRIZQT__.TTF"
local FONT_SIZE  = 10

-- Colours
local HEALTH_BG  = { 0.12, 0.12, 0.12 }
local POWER_BG   = { 0.08, 0.08, 0.08 }
local CAST_BG    = { 0.08, 0.08, 0.08 }
local CAST_COLOR = { 0.90, 0.82, 0.20 }  -- gold cast bar
local CAST_NC    = { 0.84, 0.22, 0.22 }  -- red = non-interruptible
local BG_COLOR   = { 0.06, 0.06, 0.08 }  -- frame backdrop
local BORDER_COL = { 0.16, 0.16, 0.18 }  -- 1px border

-- Class colours
local CLASS_COLORS = {
    WARRIOR     = { 0.78, 0.61, 0.43 },
    PALADIN     = { 0.96, 0.55, 0.73 },
    HUNTER      = { 0.67, 0.83, 0.45 },
    ROGUE       = { 1.00, 0.96, 0.41 },
    PRIEST      = { 1.00, 1.00, 1.00 },
    DEATHKNIGHT = { 0.77, 0.12, 0.23 },
    SHAMAN      = { 0.00, 0.44, 0.87 },
    MAGE        = { 0.41, 0.80, 0.94 },
    WARLOCK     = { 0.58, 0.51, 0.79 },
    MONK        = { 0.00, 1.00, 0.59 },
    DRUID       = { 1.00, 0.49, 0.04 },
    DEMONHUNTER = { 0.64, 0.19, 0.79 },
    EVOKER      = { 0.20, 0.58, 0.50 },
}

-- Power colours by power type
local POWER_COLORS = {
    [0]  = { 0.31, 0.45, 0.63 },  -- mana
    [1]  = { 0.78, 0.25, 0.25 },  -- rage
    [2]  = { 1.00, 0.65, 0.00 },  -- focus
    [3]  = { 0.90, 0.80, 0.00 },  -- energy
    [6]  = { 0.60, 0.10, 0.10 },  -- runic power
    [9]  = { 0.96, 0.55, 0.73 },  -- holy power
    [11] = { 0.00, 0.82, 0.65 },  -- maelstrom
    [13] = { 0.50, 0.10, 0.70 },  -- insanity
    [17] = { 0.20, 0.58, 0.50 },  -- essence
    [18] = { 0.78, 0.25, 0.25 },  -- fury (DH)
}

-- -------------------------------------------------------
-- Helpers
-- -------------------------------------------------------
local function GetClassColor(unit)
    local _, class = UnitClass(unit)
    if class and CLASS_COLORS[class] then
        return unpack(CLASS_COLORS[class])
    end
    return 0.5, 0.5, 0.5
end

local function GetPowerColor(unit)
    local ptype = UnitPowerType(unit)
    local c = POWER_COLORS[ptype] or POWER_COLORS[0]
    return unpack(c)
end

-- -------------------------------------------------------
-- Add a simple 1px border to a frame
-- -------------------------------------------------------
local function AddBorder(frame)
    local b = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    b:SetPoint("TOPLEFT",     frame, "TOPLEFT",     -1,  1)
    b:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT",  1, -1)
    b:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    b:SetBackdropBorderColor(BORDER_COL[1], BORDER_COL[2], BORDER_COL[3], 1)
    b:SetFrameLevel(frame:GetFrameLevel() - 1)
    return b
end

-- -------------------------------------------------------
-- Custom oUF tags
-- -------------------------------------------------------
-- Helper function to format large numbers to short values (e.g., 12500 -> 12.5k)
local function FormatShortValue(value)
    if not value then return "" end
    if value >= 1e6 then
        return string.format("%.1fm", value / 1e6)
    elseif value >= 1e3 then
        return string.format("%.1fk", value / 1e3)
    elseif type(value) == "number" or type(value) == "string" then
        return tostring(value)
    end
    return ""
end

-- Health percent tag
oUF.Tags.Events["unchartedui:hp"] = "UNIT_HEALTH UNIT_MAXHEALTH"
oUF.Tags.Methods["unchartedui:hp"] = function(unit)
    if not CurveConstants or not CurveConstants.ScaleTo100 then
        return "" 
    end
    local pct = UnitHealthPercent(unit, true, CurveConstants.ScaleTo100)
    if not pct then return "" end
    return string.format("%d%%", pct)
end

-- Power Text tag (Displays actual energy/mana formatted to Short Values like 12.5k)
oUF.Tags.Events["unchartedui:power"] = "UNIT_POWER_UPDATE UNIT_MAXPOWER"
oUF.Tags.Methods["unchartedui:power"] = function(unit)
    local currentPower = UnitPower(unit)
    if not currentPower then return "" end
    return FormatShortValue(currentPower)
end

-- Name tag — truncated to 16 chars
oUF.Tags.Events["unchartedui:name"] = "UNIT_NAME_UPDATE"
oUF.Tags.Methods["unchartedui:name"] = function(unit)
    local name = UnitName(unit) or ""
    if #name > 16 then return name:sub(1, 14) .. ".." end
    return name
end

-- Target name + level
oUF.Tags.Events["unchartedui:targetname"] = "UNIT_NAME_UPDATE UNIT_LEVEL"
oUF.Tags.Methods["unchartedui:targetname"] = function(unit)
    local name = UnitName(unit) or ""
    if #name > 14 then name = name:sub(1, 12) .. ".." end
    local level = UnitLevel(unit) or 0
    if level > 0 then
        return name .. " |cff888888" .. level .. "|r"
    end
    return name
end

-- -------------------------------------------------------
-- The main style function — called by oUF for each unit
-- -------------------------------------------------------
local function Style(self, unit)

    -- ---- Frame backdrop ----
    Mixin(self, BackdropTemplateMixin)
    self:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    self:SetBackdropColor(BG_COLOR[1], BG_COLOR[2], BG_COLOR[3], 0.9)
    self:SetBackdropBorderColor(BORDER_COL[1], BORDER_COL[2], BORDER_COL[3], 1)

    -- ---- Health bar ----
    local health = CreateFrame("StatusBar", nil, self)
    health:SetSize(W, HEALTH_H)
    health:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
    health:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
    health:SetStatusBarColor(0.22, 0.78, 0.36)

    -- Health background
    local hbg = health:CreateTexture(nil, "BACKGROUND")
    hbg:SetAllPoints(health)
    hbg:SetTexture("Interface\\Buttons\\WHITE8x8")
    hbg:SetVertexColor(HEALTH_BG[1], HEALTH_BG[2], HEALTH_BG[3], 1)

    health.PostUpdate = function(bar, unit)
        if UnitIsPlayer(unit) then
            bar:SetStatusBarColor(GetClassColor(unit))
        elseif UnitIsFriend("player", unit) then
            bar:SetStatusBarColor(0.22, 0.78, 0.36)
        else
            bar:SetStatusBarColor(0.84, 0.22, 0.22)
        end
    end

    health.frequentUpdates = true
    self.Health = health

    -- Health percent text — right side
    local hpTxt = health:CreateFontString(nil, "OVERLAY")
    hpTxt:SetFont(FONT, FONT_SIZE, "OUTLINE")
    hpTxt:SetPoint("RIGHT", health, "RIGHT", -3, 0)
    hpTxt:SetJustifyH("RIGHT")
    hpTxt:SetTextColor(1, 1, 1, 0.85)
    self:Tag(hpTxt, "[unchartedui:hp]")
    self.hpTxt = hpTxt

    -- ---- Power bar ----
    local power = CreateFrame("StatusBar", nil, self)
    power:SetSize(W, POWER_H)
    power:SetPoint("TOPLEFT", health, "BOTTOMLEFT", 0, -1)
    power:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
    power:SetStatusBarColor(GetPowerColor(unit) or 0.31, 0.45, 0.63)

    local pbg = power:CreateTexture(nil, "BACKGROUND")
    pbg:SetAllPoints(power)
    pbg:SetTexture("Interface\\Buttons\\WHITE8x8")
    pbg:SetVertexColor(POWER_BG[1], POWER_BG[2], POWER_BG[3], 1)

    power.PostUpdate = function(bar, unit, cur, max)
        bar:SetStatusBarColor(GetPowerColor(unit))
    end

    power.frequentUpdates = true
    self.Power = power

    -- Power text — right side of the power bar
    local powerTxt = power:CreateFontString(nil, "OVERLAY")
    powerTxt:SetFont(FONT, FONT_SIZE - 1, "OUTLINE")
    powerTxt:SetPoint("RIGHT", power, "RIGHT", -3, 0)
    powerTxt:SetJustifyH("RIGHT")
    powerTxt:SetTextColor(1, 1, 1, 0.9)
    self:Tag(powerTxt, "[unchartedui:power]")

    -- ---- Name text — above the frame ----
    local name = self:CreateFontString(nil, "OVERLAY")
    name:SetFont(FONT, FONT_SIZE, "")
    name:SetTextColor(0.85, 0.85, 0.85, 1)
    name:SetJustifyH("LEFT")
    name:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 2, 3)

    if unit == "player" then
        self:Tag(name, "[unchartedui:name]")
    else
        self:Tag(name, "[unchartedui:targetname]")
    end
    self.Name = name

    -- ---- Castbar — flush below the frame ----
    local cast = CreateFrame("StatusBar", nil, self)
    cast:SetSize(W, CAST_H)
    cast:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -(CAST_GAP))
    cast:SetStatusBarTexture("Interface\\Buttons\\WHITE8x8")
    cast:SetStatusBarColor(CAST_COLOR[1], CAST_COLOR[2], CAST_COLOR[3])

    local cbg = cast:CreateTexture(nil, "BACKGROUND")
    cbg:SetAllPoints(cast)
    cbg:SetTexture("Interface\\Buttons\\WHITE8x8")
    cbg:SetVertexColor(CAST_BG[1], CAST_BG[2], CAST_BG[3], 1)

    AddBorder(cast)

    -- Cast spell name
    local castName = cast:CreateFontString(nil, "OVERLAY")
    castName:SetFont(FONT, FONT_SIZE - 1, "")
    castName:SetPoint("LEFT",  cast, "LEFT",  20, 0)
    castName:SetPoint("RIGHT", cast, "RIGHT", -4, 0)
    castName:SetJustifyH("LEFT")
    castName:SetTextColor(1, 1, 1, 0.9)
    cast.Text = castName

    -- Cast time remaining
    local castTime = cast:CreateFontString(nil, "OVERLAY")
    castTime:SetFont(FONT, FONT_SIZE - 1, "")
    castTime:SetPoint("RIGHT", cast, "RIGHT", -4, 0)
    castTime:SetJustifyH("RIGHT")
    castTime:SetTextColor(0.85, 0.85, 0.85, 0.8)
    cast.Time = castTime

    -- Spell icon left of castbar
    local castIcon = cast:CreateTexture(nil, "ARTWORK")
    castIcon:SetSize(CAST_H, CAST_H)
    castIcon:SetPoint("RIGHT", cast, "LEFT", -2, 0)
    castIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    cast.Icon = castIcon

    -- Icon border
    local iconBorder = CreateFrame("Frame", nil, cast, "BackdropTemplate")
    iconBorder:SetSize(CAST_H + 2, CAST_H + 2)
    iconBorder:SetPoint("CENTER", castIcon, "CENTER", 0, 0)
    iconBorder:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8x8", edgeSize = 1 })
    iconBorder:SetBackdropBorderColor(BORDER_COL[1], BORDER_COL[2], BORDER_COL[3], 1)

    cast.PostCastStart = function(bar, unit)
        local _, _, _, _, _, _, _, notInterruptible = UnitCastingInfo(unit)
        if notInterruptible then
            bar:SetStatusBarColor(CAST_NC[1], CAST_NC[2], CAST_NC[3])
        else
            bar:SetStatusBarColor(CAST_COLOR[1], CAST_COLOR[2], CAST_COLOR[3])
        end
    end
    cast.PostChannelStart = cast.PostCastStart

    self.Castbar = cast

    -- Frame size calculation
    self:SetSize(W, HEALTH_H + 1 + POWER_H)
end

-- -------------------------------------------------------
-- Pet frame style
-- -------------------------------------------------------
local function PetStyle(self, unit)
    local TEX = [[Interface\Buttons\WHITE8x8]]

    Mixin(self, BackdropTemplateMixin)
    self:SetBackdrop({ bgFile=TEX, edgeFile=TEX, edgeSize=1 })
    self:SetBackdropColor(BG_COLOR[1], BG_COLOR[2], BG_COLOR[3], 0.9)
    self:SetBackdropBorderColor(BORDER_COL[1], BORDER_COL[2], BORDER_COL[3], 1)

    local health = CreateFrame("StatusBar", nil, self)
    health:SetSize(PET_W, PET_H)
    health:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 0)
    health:SetStatusBarTexture(TEX)
    health:SetStatusBarColor(0.67, 0.83, 0.45)

    local hbg = health:CreateTexture(nil, "BACKGROUND")
    hbg:SetAllPoints(health)
    hbg:SetTexture(TEX)
    hbg:SetVertexColor(HEALTH_BG[1], HEALTH_BG[2], HEALTH_BG[3], 1)

    health.PostUpdate = function(bar, unit)
        bar:SetStatusBarTexture(TEX)
        bar:SetStatusBarColor(0.67, 0.83, 0.45)
    end

    health.frequentUpdates = true
    self.Health = health
    self:SetSize(PET_W, PET_H)

    local name = self:CreateFontString(nil, "OVERLAY")
    name:SetFont(FONT, FONT_SIZE - 1, "")
    name:SetTextColor(0.70, 0.70, 0.70, 1)
    name:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 2)
    name:SetJustifyH("LEFT")
    self:Tag(name, "[unchartedui:name]")
    self.Name = name
end

-- -------------------------------------------------------
-- Register the style and spawn frames
-- -------------------------------------------------------
oUF:RegisterStyle("UnchartedUI", Style)
oUF:SetActiveStyle("UnchartedUI")

local player = oUF:Spawn("player", "UnchartedUI_Player")
player:SetPoint("BOTTOM", UIParent, "BOTTOM", PLAYER_X, PLAYER_Y)

local target = oUF:Spawn("target", "UnchartedUI_Target")
target:SetPoint("BOTTOMLEFT", player, "BOTTOMLEFT", TARGET_X, TARGET_Y)

oUF:RegisterStyle("UnchartedUI_Pet", PetStyle)
oUF:SetActiveStyle("UnchartedUI_Pet")
local pet = oUF:Spawn("pet", "UnchartedUI_Pet")
pet:SetPoint("TOP", player, "BOTTOM", PET_X, -(CAST_GAP + CAST_H + PET_GAP))

-- -------------------------------------------------------
-- Hide Blizzard's default unit frames (Modern Taint-Free Method)
-- -------------------------------------------------------
local hideFrame = CreateFrame("Frame")
hideFrame:RegisterEvent("PLAYER_LOGIN")
hideFrame:SetScript("OnEvent", function()
    if oUF and oUF.HideBlizzard then
        oUF:HideBlizzard("player")
        oUF:HideBlizzard("target")
        oUF:HideBlizzard("pet")
    else
        local framesToHide = { "PlayerFrame", "TargetFrame", "PetFrame" }
        for _, frameName in ipairs(framesToHide) do
            local f = _G[frameName]
            if f then
                f:UnregisterAllEvents()
                RegisterAttributeDriver(f, "state-visibility", "hide")
            end
        end
    end

    if PlayerCastingBarFrame then
        PlayerCastingBarFrame:UnregisterAllEvents()
        RegisterAttributeDriver(PlayerCastingBarFrame, "state-visibility", "hide")
        PlayerCastingBarFrame:Hide()
    end

    if TargetFrameToT then
        RegisterAttributeDriver(TargetFrameToT, "state-visibility", "hide")
        TargetFrameToT:Hide()
    end
end)

-- -------------------------------------------------------
-- Frame dragging (unlock/lock via slash commands)
-- -------------------------------------------------------
local frames = { player = player, target = target, pet = pet }
local locked = true

local function SetDraggable(frame, name, draggable)
    frame:SetMovable(draggable)
    frame:EnableMouse(draggable)
    if draggable then
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", function(f) f:StartMoving() end)
        frame:SetScript("OnDragStop",  function(f)
            f:StopMovingOrSizing()
            if not UnchartedUIDB then UnchartedUIDB = {} end
            if not UnchartedUIDB.positions then UnchartedUIDB.positions = {} end
            local p, _, rp, x, y = f:GetPoint()
            UnchartedUIDB.positions[name] = { p, rp, math.floor(x), math.floor(y) }
        end)
        if not frame.moveLabel then
            local lbl = frame:CreateFontString(nil, "OVERLAY")
            lbl:SetFont(FONT, 9, "OUTLINE")
            lbl:SetAllPoints(frame)
            lbl:SetJustifyH("CENTER")
            lbl:SetTextColor(1, 0.82, 0, 1)
            lbl:SetText(name)
            frame.moveLabel = lbl
        end
        frame.moveLabel:Show()
    else
        frame:RegisterForDrag()
        frame:SetScript("OnDragStart", nil)
        frame:SetScript("OnDragStop",  nil)
        if frame.moveLabel then frame.moveLabel:Hide() end
    end
end

local restoreFrame = CreateFrame("Frame")
restoreFrame:RegisterEvent("PLAYER_LOGIN")
restoreFrame:SetScript("OnEvent", function()
    if UnchartedUIDB and UnchartedUIDB.positions then
        for name, pos in pairs(UnchartedUIDB.positions) do
            local f = frames[name]
            if f and pos then
                f:ClearAllPoints()
                f:SetPoint(pos[1], UIParent, pos[2], pos[3], pos[4])
            end
        end
    end
end)

SLASH_UNCHARTEDUI1 = "/uui"
SlashCmdList["UNCHARTEDUI"] = function(msg)
    local cmd = msg and msg:lower():match("^%s*(.-)%s*$") or ""
    if cmd == "unlock" then
        locked = false
        for name, f in pairs(frames) do SetDraggable(f, name, true) end
        print("|cff5B9BD5UnchartedUI|r: Frames unlocked — drag to move. Type |cffFFD700/uui lock|r when done.")
    elseif cmd == "lock" then
        locked = true
        for name, f in pairs(frames) do SetDraggable(f, name, false) end
        print("|cff5B9BD5UnchartedUI|r: Frames locked.")
    elseif cmd == "reset" then
        if UnchartedUIDB then UnchartedUIDB.positions = {} end
        player:ClearAllPoints()
        player:SetPoint("BOTTOM", UIParent, "BOTTOM", PLAYER_X, PLAYER_Y)
        target:ClearAllPoints()
        target:SetPoint("BOTTOM", UIParent, "BOTTOM", TARGET_X, TARGET_Y)
        print("|cff5B9BD5UnchartedUI|r: Positions reset.")
    else
        print("|cff5B9BD5/uui unlock|r — drag frames")
        print("|cff5B9BD5/uui lock|r   — lock frames")
        print("|cff5B9BD5/uui reset|r  — reset to default positions")
    end
end
