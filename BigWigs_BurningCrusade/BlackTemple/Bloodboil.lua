--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-BlackTemple/Bloodboil.lua, Sirus version with custom spells), draft by tools/dbm2bw
-- Not ported: the Filth info frame.

local mod, CL = BigWigs:NewBoss("Gurtogg Bloodboil", 564, 1586)
if not mod then return end
mod:RegisterEnableMob(22948)
mod:SetEncounterID(605)

--------------------------------------------------------------------------------
-- Locals
--

local prevBlood = 0

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		{373745, "TANK"}, -- Strike
		373748, -- Wave
		373749, -- Blood
		"proximity",
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "Strike", 373745)
	self:Log("SPELL_CAST_START", "Wave", 373748)
	self:Log("SPELL_AURA_APPLIED", "Blood", 373749)
	self:Log("SPELL_AURA_APPLIED_DOSE", "Blood", 373749)
end

function mod:OnEngage()
	prevBlood = 0
	self:CDBar(373745, 6)
	self:OpenProximity("proximity", 8)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:Strike(args)
	self:CastBar(373745, 1.5)
	self:CDBar(373745, 6)
end

function mod:Wave(args)
	self:Message(373748, "red", CL.casting:format(args.spellName))
	self:PlaySound(373748, "alarm")
	self:CastBar(373748, 3)
end

function mod:Blood(args)
	local amount = args.amount or 1
	if amount >= 2 and self:Me(args.destGUID) and args.time - prevBlood > 2 then
		prevBlood = args.time
		self:StackMessage(373749, "blue", args.destName, amount, 2)
		self:PlaySound(373749, "alarm")
	end
end
