--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-AQ20/Ayamiss.lua)

local mod, CL = BigWigs:NewBoss("Ayamiss the Hunter", 509, 1541)
if not mod then return end
mod:RegisterEnableMob(15369)
mod:SetEncounterID(722)

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"stages",
		25725, -- Paralyze
		8269, -- Frenzy
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "Paralyze", 25725)
	self:Log("SPELL_AURA_REMOVED", "ParalyzeRemoved", 25725)
	self:Log("SPELL_AURA_APPLIED", "Frenzy", 8269)
	self:RegisterEvent("UNIT_HEALTH")
end

function mod:OnEngage()
	self:SetStage(1)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:Paralyze(args)
	self:TargetMessage(25725, "orange", args.destName)
	self:TargetBar(25725, 10, args.destName)
end

function mod:ParalyzeRemoved(args)
	self:StopBar(25725, args.destName)
end

function mod:Frenzy(args)
	if not self:Player(args.destFlags) then
		self:Message(8269, "red", CL.other:format(args.spellName, args.destName))
	end
end

function mod:UNIT_HEALTH(_, unit)
	if self:IsEngaged() and self:GetStage() == 1 and self:MobId(self:UnitGUID(unit)) == 15369 and self:GetHealth(unit) <= 70 then
		self:SetStage(2)
		self:Message("stages", "cyan", CL.stage:format(2), false)
		self:PlaySound("stages", "long")
	end
end
