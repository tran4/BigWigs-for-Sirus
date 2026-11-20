--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-AQ40/Fankriss.lua)

local mod, CL = BigWigs:NewBoss("Fankriss the Unyielding", 531, 1545)
if not mod then return end
mod:RegisterEnableMob(15510)
mod:SetEncounterID(712)

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		25831, -- Summon Worm
		{1121, "SAY"}, -- Entangle
		{25646, "TANK"}, -- Mortal Wound (DBM: tanks only)
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_SUMMON", "SummonWorm", 518, 25832, 25831)
	self:Log("SPELL_AURA_APPLIED", "Entangle", 1121)
	self:Log("SPELL_AURA_APPLIED", "MortalWound", 25646)
	self:Log("SPELL_AURA_APPLIED_DOSE", "MortalWound", 25646)
	self:Log("SPELL_AURA_REMOVED", "MortalWoundRemoved", 25646)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:SummonWorm(args)
	self:Message(25831, "orange")
end

function mod:Entangle(args)
	self:TargetMessage(1121, "yellow", args.destName)
	if self:Me(args.destGUID) then
		self:Say(1121)
	end
end

function mod:MortalWound(args)
	local amount = args.amount or 1
	self:StackMessage(25646, "purple", args.destName, amount, 5)
	self:TargetBar(25646, 20, args.destName)
	if amount >= 5 then
		if self:Me(args.destGUID) then
			self:PlaySound(25646, "alarm")
		elseif not self:UnitDebuff("player", 25646) and not UnitIsDeadOrGhost("player") then
			self:PlaySound(25646, "warning") -- DBM: taunt
		end
	end
end

function mod:MortalWoundRemoved(args)
	self:StopBar(25646, args.destName)
end
