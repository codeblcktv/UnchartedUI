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

-- Name tag — truncated to 16 chars
oUF.Tags.Events["unchartedui:name"] = "UNIT_NAME_UPDATE"
oUF.Tags.Methods["unchartedui:name"] = function(unit)
    local name = UnitName(unit) or ""
    if #name > 16 then return name:sub(1, 14) .. ".." end
    return name
end

-- Target name + level
oUF.Tags.Events["unchartedui:targetname"] = "UNIT_NAME_UPDATE UNIT_LEVEL"
oUF
