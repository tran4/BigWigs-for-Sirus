--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-AQ40/TwinEmps.lua), won when both emperors died.
-- Not ported: the nameplate auras of the mutated bugs.

local mod, CL = BigWigs:NewBoss("The Twin Emperors", 531, 1549)
if not mod then return end
mod:RegisterEnableMob(15276, 15275) -- Emperor Vek'lor, Emperor Vek'nilash
mod:SetEncounterID(715)
mod:SetWinMobs(15276, 15275)

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"berserk",
		800, -- Twin Teleport
		{26613, "TANK_HEALER"}, -- Unbalancing Strike (DBM: tanks and healers only)
		26607, -- Blizzard
		{802, "OFF"}, -- Mutate Bug
		{804, "OFF"}, -- Explode Bug
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "Teleport", 799, 800)
	self:Log("SPELL_AURA_APPLIED", "UnbalancingStrike", 26613)
	self:Log("SPELL_AURA_APPLIED", "Blizzard", 26607)
	self:Log("SPELL_CAST_SUCCESS", "MutateBug", 802)
	self:Log("SPELL_CAST_SUCCESS", "ExplodeBug", 804)
end

function mod:OnEngage()
	self:Berserk(900)
	self:CDBar(800, 29.2)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

do
	local prev = 0
	function mod:Teleport(args)
		if args.time - prev > 5 then
			prev = args.time
			self:Message(800, "yellow")
			self:PlaySound(800, "info")
			self:CDBar(800, 29.2)
		end
	end
end

function mod:UnbalancingStrike(args)
	self:TargetMessage(26613, "purple", args.destName)
	if self:Me(args.destGUID) then
		self:PlaySound(26613, "alarm") -- DBM: defensive
	end
end

function mod:Blizzard(args)
	if self:Me(args.destGUID) and self:Hostile(args.sourceFlags) then
		self:PersonalMessage(26607, "underyou")
		self:PlaySound(26607, "underyou")
	end
end

function mod:MutateBug(args)
	self:Message(802, "yellow")
	self:CDBar(802, 11)
end

function mod:ExplodeBug()
	self:CDBar(804, 4.9)
end
