--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-ZG/Jeklik.lua), no journal id: the name is from the DBM locale.
-- DBM checks args.spellID on the removal of Shadow Word: Pain, so its bar is never stopped: it is here.

local mod, CL = BigWigs:NewBoss("High Priestess Jeklik", 309)
if not mod then return end
mod:RegisterEnableMob(14517)
mod:SetEncounterID(785)

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	bossName = "High Priestess Jeklik",
})
mod.displayName = L.bossName

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		23954, -- Great Heal
		23918, -- Sonic Burst
		22884, -- Psychic Scream
		23952, -- Shadow Word: Pain
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "GreatHeal", 23954)
	self:Log("SPELL_CAST_SUCCESS", "SonicBurst", 23918)
	self:Log("SPELL_CAST_SUCCESS", "PsychicScream", 22884)
	self:Log("SPELL_AURA_APPLIED", "ShadowWordPain", 23952)
	self:Log("SPELL_AURA_REMOVED", "ShadowWordPainRemoved", 23952)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:GreatHeal(args)
	if self:Hostile(args.sourceFlags) then
		self:Bar(23954, 20)
		if (self:UnitGUID("target") == args.sourceGUID or self:UnitGUID("focus") == args.sourceGUID) and self:Interrupter() then
			self:Message(23954, "red", CL.casting:format(args.spellName))
			self:PlaySound(23954, "alert") -- DBM: interrupt
		end
	end
end

function mod:SonicBurst(args)
	self:Message(23918, "orange")
	self:Bar(23918, 10, CL.other:format(args.spellName, CL.active))
end

function mod:PsychicScream(args)
	if self:Hostile(args.sourceFlags) then
		self:Message(22884, "orange")
		self:Bar(22884, 4, CL.other:format(args.spellName, CL.active))
	end
end

function mod:ShadowWordPain(args)
	if self:Player(args.destFlags) and (self:Dispeller("magic") or self:Healer()) then -- DBM: magic removers and healers
		self:TargetMessage(23952, "yellow", args.destName)
		self:TargetBar(23952, 18, args.destName)
	end
end

function mod:ShadowWordPainRemoved(args)
	self:StopBar(23952, args.destName)
end
