
--------------------------------------------------------------------------------
-- Module declaration
--

local mod, CL = BigWigs:NewBoss("Vexallus", 585, 531)
if not mod then return end
mod:RegisterEnableMob(24744)
mod.engageId = 1898
--mod.respawnTime = 0 -- resets, doesn't respawn

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	energy_discharged = "%s discharged", -- %s = Pure Energy (npc ID = 24745)
})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		-5085, -- Pure Energy
		44335, -- Energy Feedback
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "EnergyFeedback", 44335)
	self:Log("SPELL_AURA_APPLIED_DOSE", "EnergyFeedback", 44335)
	self:Log("SPELL_AURA_REMOVED", "EnergyFeedbackRemoved", 44335)

	if self:Classic() then
		self:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", nil, "boss1") -- 3.3.5: unit events get the 3.3.5 arguments converted, boss1 comes from the target/focus
	else
		self:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", nil, "boss1")
	end
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:EnergyFeedback(args)
	self:StackMessageOld(args.spellId, args.destName, args.amount, "orange")
	self:TargetBar(args.spellId, 30, args.destName)
end

function mod:EnergyFeedbackRemoved(args)
	self:StopBar(args.spellName, args.destName)
end

do
	local prev
	function mod:UNIT_SPELLCAST_SUCCEEDED(_, _, castGUID, spellId, spellName) -- 3.3.5: compare the name, the id can be nil
		if (spellName == self:SpellName(44322) or spellName == self:SpellName(46154)) and castGUID ~= prev then -- Summon Pure Energy (normal / heroic)
			prev = castGUID
			self:MessageOld(-5085, "red", nil, L.energy_discharged:format(self:SpellName(-5085)), false)
		end
	end
end
