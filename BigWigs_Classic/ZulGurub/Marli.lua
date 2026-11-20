--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-ZG/Marli.lua), no journal id: the name is from the DBM locale

local mod, CL = BigWigs:NewBoss("High Priestess Mar'li", 309)
if not mod then return end
mod:RegisterEnableMob(14510)
mod:SetEncounterID(786)

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	bossName = "High Priestess Mar'li",
})
mod.displayName = L.bossName

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		24083, -- Spawn of Mar'li
		24300, -- Drain Life
		24111, -- Corrosive Poison
		24109, -- Enlarge
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_SUCCESS", "Spiders", 24083)
	self:Log("SPELL_AURA_APPLIED", "DrainLife", 24300)
	self:Log("SPELL_AURA_REMOVED", "DrainLifeRemoved", 24300)
	self:Log("SPELL_AURA_APPLIED", "CorrosivePoison", 24111)
	self:Log("SPELL_AURA_REMOVED", "CorrosivePoisonRemoved", 24111)
	self:Log("SPELL_AURA_APPLIED", "Enlarge", 24109)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:Spiders(args)
	self:Message(24083, "yellow")
end

function mod:DrainLife(args)
	if self:Player(args.destFlags) and (self:Dispeller("magic") or self:Healer()) then -- DBM: magic removers and healers
		self:TargetMessage(24300, "orange", args.destName)
		self:TargetBar(24300, 7, args.destName)
	end
end

function mod:DrainLifeRemoved(args)
	self:StopBar(24300, args.destName)
end

function mod:CorrosivePoison(args)
	if self:Dispeller("poison") then -- DBM: poison removers
		self:TargetMessage(24111, "yellow", args.destName)
		self:TargetBar(24111, 30, args.destName)
	end
end

function mod:CorrosivePoisonRemoved(args)
	self:StopBar(24111, args.destName)
end

function mod:Enlarge(args)
	self:TargetMessage(24109, "red", args.destName)
	if self:Dispeller("magic", true) then
		self:PlaySound(24109, "alert") -- DBM: dispel the boss
	end
end
