
--------------------------------------------------------------------------------
-- Module declaration
--
-- 3.3.5: the retail module has no options ("XXX revise this module"), Arcane Discharge and Time Lapse are
-- written from DBM Sirus (DBM-Party-BC/CoT_BlackMorass/Deja.lua)

local mod, CL = BigWigs:NewBoss("Chrono Lord Deja", 269, 552)
if not mod then return end
mod:RegisterEnableMob(17879)
mod:SetEncounterID(1920) -- 3.3.5: encounter emulation, there is no ENCOUNTER_START (the retail module has no boss frames to engage by)

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		38539, -- Arcane Discharge
		31467, -- Time Lapse
	}
end

function mod:OnBossEnable()
	--self:Log("SPELL_AURA_APPLIED", "Enrage", 37605)
	--self:Log("SPELL_AURA_REMOVED", "EnrageRemoved", 37605)
	self:Log("SPELL_CAST_START", "ArcaneDischarge", 38539, 31472) -- 3.3.5: from DBM Sirus
	self:Log("SPELL_AURA_APPLIED", "TimeLapse", 31467) -- 3.3.5: from DBM Sirus

	self:Death("Win", 17879)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

--function mod:Enrage(args)
--	self:MessageOld(args.spellId, "orange")
--	self:Bar(args.spellId, 8)
--end
--
--function mod:EnrageRemoved(args)
--	self:StopBar(args.spellName)
--end

-- 3.3.5: from DBM Sirus
function mod:ArcaneDischarge(args)
	self:Message(38539, "orange", CL.casting:format(args.spellName))
end

do
	local prev = 0
	function mod:TimeLapse(args)
		if args.time - prev > 2 then
			prev = args.time
			self:TargetMessage(31467, "yellow", args.destName)
			if self:Healer() then
				self:PlaySound(31467, "alert") -- DBM: dispel now (healers)
			end
		end
	end
end
