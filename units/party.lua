local A, ns = ...

local lum, core, cfg, m, oUF = ns.lum, ns.core, ns.cfg, ns.m, ns.oUF
local auras, debuffs = ns.auras, ns.debuffs

local font = m.fonts.font
local font_big = m.fonts.font_big

local frame = "party"

-- ------------------------------------------------------------------------
-- > PARTY UNIT SPECIFIC FUNCTiONS
-- ------------------------------------------------------------------------

-- Post Health Update
local PostUpdateHealth = function(health, unit, min, max)
  local self = health.__owner
  local dead, disconnnected, ghost = UnitIsDead(unit), not UnitIsConnected(unit), UnitIsGhost(unit)
  local perc = math.floor(min / max * 100 + 0.5)

  -- Inverted colors
  if cfg.units[frame].health.invertedColors or cfg.units[frame].showPortraits then
    health:SetStatusBarColor(unpack(cfg.colors.inverted))
    health.bg:SetVertexColor(unpack(core:raidColor(unit)))
    health.bg:SetAlpha(1)
  end

  -- Use gradient colored health
  if cfg.units[frame].health.gradientColored then
    local color = CreateColor(oUF.ColorGradient(min, max, 1, 0, 0, 1, 1, 0, .5, .9, 0))
    health:SetStatusBarColor(color:GetRGB())
  end

  -- Show health value as the missing value
  health.value:SetText("-" .. core:shortNumber(max - min))

  if disconnnected or dead or ghost then
    self.HPborder:Hide()
    health.bg:SetVertexColor(.25, .25, .25)
    health.value:Hide()
  else -- Player alive and kicking!
    health.value:Show()
    if (min == max) then -- It has max health
      health.value:Hide()
      self.HPborder:Hide()
    else
      health.value:Show()
      if perc < 35 then -- Show warning health border
        self.HPborder:Show()
      else
        self.HPborder:Hide()
      end
    end
  end
end

-- PostUpdate Power
local PostUpdatePower = function(power, unit, min, max)
  local dead, disconnnected, ghost = UnitIsDead(unit), not UnitIsConnected(unit), UnitIsGhost(unit)

  if disconnnected or dead or ghost then
    power:SetValue(max)
    if (dead) then
      power:SetStatusBarColor(1, 0, 0, .7)
    elseif (disconnnected) then
      power:SetStatusBarColor(.85, 1, 0, .7)
    elseif (ghost) then
      power:SetStatusBarColor(1, 1, 1, .7)
    end
  else
    power:SetValue(min)
    if (unit == "vehicle") then
      power:SetStatusBarColor(143 / 255, 194 / 255, 32 / 255)
    end
  end
end

-- Post Update Aura Icon
local PostUpdateIcon = function(element, unit, icon, index)
  local name, _, count, _, duration, expirationTime = UnitAura(unit, index, icon.filter)

  if duration and duration > 0 then
    icon.timeLeft = expirationTime - GetTime()
  else
    icon.timeLeft = math.huge
  end

  icon:SetScript(
    "OnUpdate",
    function(self, elapsed)
      auras:AuraTimer_OnUpdate(self, elapsed)
    end
  )
end

-- Filter Debuffs
local PartyDebuffsFilter = function(icons, unit, icon, name)
  if name then
    if debuffs.list[frame][name] or duration == 0 then -- Ignore debuffs in the party list
      return false
    end
  end
  return true
end

local PostUpdatePortrait = function(element, unit)
  element:SetModelAlpha(0.1)
  element:SetDesaturation(1)
end

-- local PartyUpdate = function(self)
--   print(core:isPlayerHealer())
-- end

-- -----------------------------------
-- > TARGET STYLE
-- -----------------------------------

local createStyle = function(self)
  self.mystyle = frame
  self.cfg = cfg.units[frame]

  lum:globalStyle(self, "secondary")

  -- Texts
  core:createHPString(self, font, cfg.fontsize - 2, "THINOUTLINE", 4, 0, "LEFT")

  core:createPartyNameString(self, font_big, cfg.fontsize)
  if self.cfg.health.classColoredText then
    self:Tag(self.Name, "[lumen:role] [raidcolor][lumen:name]")
  else
    self:Tag(self.Name, "[lumen:partystatus] [lumen:name]")
  end

  self.classText = core:createFontstring(self.Health, font_big, cfg.fontsize, "THINOUTLINE")
  self.classText:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -4, 5)
  self.classText:SetJustifyH("RIGHT")
  self:Tag(self.classText, "[lumen:level] [raidcolor][class]")

  -- Role and Leader text
  self.roleText = core:createFontstring(self.Health, font_big, cfg.fontsize - 2, "THINOUTLINE")
  self.roleText:SetPoint("BOTTOM", self, "TOP", 0, -4)
  self.roleText:SetJustifyH("CENTER")
  self:Tag(self.roleText, "|cff666666" .. "[leaderlong]" .. "|r [lumen:role]")

  -- Health & Power Updates
  self.Health.PostUpdate = PostUpdateHealth
  self.Power.PostUpdate = PostUpdatePower

  -- Portrait
  if self.cfg.showPortraits then
    local Portrait = CreateFrame("PlayerModel", nil, self.Health)
    Portrait:SetFrameLevel(self.Health:GetFrameLevel())
    Portrait:SetAllPoints(self.Health)
    Portrait.PostUpdate = PostUpdatePortrait
    self.Portrait = Portrait
  end

  -- Defuffs
  local debuffs = auras:CreateAura(self, 12, 2, self.cfg.height / 2 + 2, 3)
  debuffs:SetPoint("TOPRIGHT", self, "TOPLEFT", -6, 2)
  debuffs.initialAnchor = "TOPRIGHT"
  debuffs["growth-x"] = "LEFT"
  debuffs["growth-y"] = "DOWN"
  debuffs.showDebuffType = true
  debuffs.CustomFilter = PartyDebuffsFilter
  debuffs.PostUpdateIcon = PostUpdateIcon
  self.Debuffs = debuffs

  -- Ready Check Icon
  local ReadyCheck = self:CreateTexture()
  ReadyCheck:SetPoint("LEFT", self, "RIGHT", 8, 0)
  ReadyCheck:SetSize(20, 20)
  ReadyCheck.finishedTimer = 10
  ReadyCheck.fadeTimer = 2
  self.ReadyCheckIndicator = ReadyCheck

  -- Heal Prediction
  CreateHealPrediction(self)

  -- Health warning border
  core:CreateHPBorder(self)

  -- Threat warning border
  core:CreateThreatBorder(self)

  self.Range = cfg.frames.range

  -- self:RegisterEvent("PLAYER_TALENT_UPDATE", PartyUpdate, true)
  -- self:RegisterEvent("CHARACTER_POINTS_CHANGED", PartyUpdate, true)
  -- self:RegisterEvent("PLAYER_ROLES_ASSIGNED", PartyUpdate, true)
  -- self:RegisterEvent("GROUP_ROSTER_UPDATE", PartyUpdate, true)
  -- self:RegisterEvent("GROUP_FORMED", PartyUpdate, true)
  -- self:RegisterEvent("GROUP_JOINED", PartyUpdate, true)
end

-- -----------------------------------
-- > SPAWN UNIT
-- -----------------------------------
if cfg.units[frame].show then
  oUF:RegisterStyle(A .. frame:gsub("^%l", string.upper), createStyle)
  oUF:SetActiveStyle(A .. frame:gsub("^%l", string.upper))

  local party =
    oUF:SpawnHeader(
    -- "oUF_LumenParty",
    -- nil,
    -- "solo",
    -- "showSolo", -- debug
    "oUF_LumenParty",
    nil,
    "party",
    "showParty",
    true,
    "showRaid",
    false,
    "showPlayer",
    true,
    "yOffset",
    -24,
    "groupBy",
    "ASSIGNEDROLE",
    "groupingOrder",
    "TANK,HEALER,DAMAGER",
    "oUF-initialConfigFunction",
    ([[
			self:SetHeight(%d)
			self:SetWidth(%d)
		]]):format(cfg.units[frame].height, cfg.units[frame].width)
  ):SetPoint(
    cfg.units[frame].pos.a1,
    cfg.units[frame].pos.af,
    cfg.units[frame].pos.a2,
    cfg.units[frame].pos.x,
    cfg.units[frame].pos.y
  )
end
