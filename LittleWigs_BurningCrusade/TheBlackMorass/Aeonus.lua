
--------------------------------------------------------------------------------
-- Module declaration
--

local mod, CL = BigWigs:NewBoss("Aeonus", 269, 554)
if not mod then return end
mod:RegisterEnableMob(17881)
mod:SetEncounterID(1919) -- 3.3.5: encounter emulation, there is no ENCOUNTER_START (the retail module has no boss frames to engage by)

--------------------------------------------------------------------------------
-- Localization
--

mod:SetDefaultLocale({
	reset_trigger = "No! Damn this feeble, mortal coil!", -- XXX implement?
})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		37605, -- Enrage / Frenzy (different name on classic)
		31422, -- Time Stop (3.3.5: DBM Sirus)
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "EnrageFrenzyApplied", 37605)
	self:Log("SPELL_DISPEL", "EnrageFrenzyDispelled", "*")
	self:Log("SPELL_CAST_SUCCESS", "TimeStop", 31422) -- 3.3.5: DBM Sirus

	self:Death("Win", 17881)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:EnrageFrenzyApplied(args)
	self:Message(args.spellId, "orange")
	self:TargetBar(args.spellId, 8, args.destName)
end

function mod:EnrageFrenzyDispelled(args)
	if args.extraSpellName == self:SpellName(37605) then
		self:StopBar(args.extraSpellName, args.destName)
		self:Message(37605, "green", CL.removed_by:format(args.extraSpellName, self:ColorName(args.sourceName)))
	end
end

function mod:TimeStop(args) -- 3.3.5: DBM Sirus
	self:Message(31422, "red")
	self:Bar(31422, 4, CL.other:format(args.spellName, CL.active))
end
