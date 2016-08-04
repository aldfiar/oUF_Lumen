local _, ns = ...

local lum, core, auras, cfg, m, oUF = ns.lum, ns.core, ns.auras, ns.cfg, ns.m, ns.oUF

local font = m.fonts.font
local font_big = m.fonts.font_big

local frame = "target"

-- ------------------------------------------------------------------------
-- > TARGET UNIT SPECIFIC FUNCTiONS
-- ------------------------------------------------------------------------

-- Post Health Update
local PostUpdateHealth = function(health, unit, min, max)
  if cfg.units[frame].health.gradientColored then
    local r, g, b = oUF.ColorGradient(min, max, 1,0,0, 1,1,0, unpack(core:raidColor(unit)))
    health:SetStatusBarColor(r, g, b)
  end

  -- Class colored text
  if cfg.units[frame].health.classColoredText then
    self.Name:SetTextColor(unpack(core:raidColor(unit)))
  end
end

-- Post Update Aura Icon
local PostUpdateIcon =  function(icons, unit, icon, index, offset, filter, isDebuff)
	local name, _, _, count, dtype, duration, expirationTime = UnitAura(unit, index, icon.filter)

	if duration and duration > 0 then
		icon.timeLeft = expirationTime - GetTime()

	else
		icon.timeLeft = math.huge
	end

	icon:SetScript('OnUpdate', function(self, elapsed)
		auras:AuraTimer_OnUpdate(self, elapsed)
	end)
end

-- -----------------------------------
-- > TARGET STYLE
-- -----------------------------------

local createStyle = function(self)
  self.mystyle = frame
  self.cfg = cfg.units[frame]

  lum:globalStyle(self)
  lum:setupUnitFrame(self, "main")

  -- Texts
  core:createNameString(self, font_big, cfg.fontsize + 2, "THINOUTLINE", 4, 0, "LEFT", self.cfg.width - 75)
  self:Tag(self.Name, '[lumen:level]  [lumen:name] [lumen:classification]')
  core:createHPString(self, font, cfg.fontsize, "THINOUTLINE", -4, 0, "RIGHT")
  self:Tag(self.Health.value, '[lumen:hpvalue]')
  core:createHPPercentString(self, font, cfg.fontsize, nil, -32, 0, "LEFT", "BACKGROUND")
  core:createPowerString(self, font, cfg.fontsize -4, "THINOUTLINE", 0, 0, "CENTER")

  -- Health & Power Updates
  self.Health.PostUpdate = PostUpdateHealth

  -- Buffs
  local buffs = auras:CreateAura(self, 8, 1, cfg.frames.secondary.height + 4, 2)
  buffs:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, 2)
  buffs.initialAnchor = "BOTTOMLEFT"
  buffs["growth-x"] = "RIGHT"
  buffs.PostUpdateIcon = PostUpdateIcon
  self.Buffs = buffs

  -- Debuffs
  -- local debuffs = auras:createAura(self, 4, 1, cfg.frames.secondary.height + 4)
  -- debuffs:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", 0, 6)
  -- debuffs:SetPoint('RIGHT', 2, 0)
  -- debuffs.showDebuffType = true
  -- debuffs.onlyShowPlayer = true
  -- debuffs.initialAnchor = "BOTTOMRIGHT"
  -- debuffs["growth-x"] = "LEFT"
  -- debuffs.PostUpdateIcon = PostUpdateIcon
  -- self.Debuffs = debuffs

  -- Castbar
  core:CreateCastbar(self)
end

-- -----------------------------------
-- > SPAWN UNIT
-- -----------------------------------
if cfg.units.target.show then
  oUF:RegisterStyle("lumen:"..frame, createStyle)
  oUF:SetActiveStyle("lumen:"..frame)
  oUF:Spawn(frame, "oUF_Lumen"..frame)
end
