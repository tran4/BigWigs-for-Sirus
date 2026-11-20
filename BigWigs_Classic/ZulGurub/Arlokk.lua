--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-ZG/Arlokk.lua), no journal id: the name is from the DBM locale

local mod, CL = BigWigs:NewBoss("High Priestess Arlokk", 309)
if not mod then return end
mod:RegisterEnableMob(14515)
mod:SetEncounterID(791)

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	bossName = "High Priestess Arlokk",
})
mod.displayName = L.bossName

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		24210, -- Mark of Arlokk
		24212, -- Shadow Word: Pain
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "MarkOfArlokk", 24210)
	self:Log("SPELL_AURA_APPLIED", "ShadowWordPain", 24212)
	self:Log("SPELL_AURA_REMOVED", "ShadowWordPainRemoved", 24212)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:MarkOfArlokk(args)
	self:TargetMessage(24210, "red", args.destName)
	if self:Me(args.destGUID) then
		self:PlaySound(24210, "warning")
	end
end

function mod:ShadowWordPain(args)
	if self:Player(args.destFlags) and (self:Dispeller("magic") or self:Healer()) then -- DBM: magic removers and healers
		self:TargetMessage(24212, "yellow", args.destName)
		self:TargetBar(24212, 18, args.destName)
	end
end

function mod:ShadowWordPainRemoved(args)
	self:StopBar(24212, args.destName)
end
