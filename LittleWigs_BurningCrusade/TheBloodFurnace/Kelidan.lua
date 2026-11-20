--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("Keli'dan the Breaker", 542, 557)
if not mod then return end
mod:RegisterEnableMob(17377)
--mod.engageId = 1923 -- no boss frames, no ENCOUNTER_END on a wipe
mod:SetEncounterID(1923) -- 3.3.5: encounter emulation, there is no ENCOUNTER_START (the retail module has no boss frames to engage by)
--mod.respawnTime = 0 -- resets, doesn't respawn

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		{-5388, "CASTBAR"}, -- Burning Nova
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_SUCCESS", "BurningNova", 30940) -- the buff that he applies to himself before casting the spell (37371) that does the damage
	self:Death("Win", 17377)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:BurningNova(args)
	self:MessageOld(-5388, "red", nil, CL.casting:format(args.spellName))
	self:CastBar(-5388, 6)
end
