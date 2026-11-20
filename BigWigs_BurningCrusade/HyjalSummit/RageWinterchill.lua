--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Hyjal/RageWinterchill.lua, Sirus version with custom spells), draft by tools/dbm2bw
-- Not ported: the Voltage info frame, the voice of the stages.

local mod, CL = BigWigs:NewBoss("Rage Winterchill", 534, 1577)
if not mod then return end
mod:RegisterEnableMob(17767)
mod:SetEncounterID(618)

--------------------------------------------------------------------------------
-- Locals
--

local warnedSoon = false
local prevCurse = 0

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	dont_dispel = "%s - НЕ ДИСПЕЛИТЬ!", -- DBM: no English text
})

--------------------------------------------------------------------------------
-- Initialization
--

local fingerMarker = mod:AddMarkerOption(false, "player", 7, 317801, 7)
function mod:GetOptions()
	return {
		"stages",
		317788, -- Desecration
		317801, -- Finger of Pain
		fingerMarker,
		{317807, "TANK_HEALER"}, -- Cursing Blow
		317784, -- Chains of Destinies
		301332, -- curses
		317799, -- Curse of Deception
		317793, -- Curse of Impotence
		317796, -- Curse of Fever
		317785, -- Voltage of Circuits
		317805, -- wipe
		317806, -- curses (stage 2)
		"proximity",
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "Desecration", 317788)
	self:Log("SPELL_CAST_START", "FingerOfPain", 317801)
	self:Log("SPELL_CAST_START", "CursingBlow", 317807)
	self:Log("SPELL_AURA_APPLIED", "DesecrationApplied", 317788)
	self:Log("SPELL_AURA_APPLIED", "Voltage", 317785)
	self:Log("SPELL_AURA_APPLIED_DOSE", "Voltage", 317785)
	self:Log("SPELL_AURA_APPLIED", "Curse", 317799, 317793, 317796)
	self:RegisterEvent("UNIT_HEALTH")
end

function mod:OnEngage()
	self:SetStage(1)
	warnedSoon, prevCurse = false, 0
	self:CDBar(317784, 10)
	self:Bar(317788, 60)
	self:CDBar(317801, 20)
	self:CDBar(317807, 15)
	self:DelayedMessage(317788, 55, "orange", CL.soon:format(self:SpellName(317788)), nil, "runaway")
	self:CDBar(301332, 25)
	self:OpenProximity("proximity", 6)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:Desecration(args)
	local two = self:GetStage() == 2
	self:Message(317788, "red", CL.casting:format(args.spellName))
	self:Bar(317788, two and 42 or 72)
	self:CastBar(317788, 2)
	self:ScheduleTimer("CastBar", 2, 317788, 10)
	self:DelayedMessage(317788, two and 41 or 65, "orange", CL.soon:format(args.spellName), nil, "runaway")
end

do
	local function fingerTarget(self, name)
		self:TargetMessage(317801, "yellow", name)
		self:CustomIcon(fingerMarker, name, 7)
		self:ScheduleTimer("CustomIcon", 2, fingerMarker, name)
	end
	function mod:FingerOfPain(args)
		self:GetUnitTarget(fingerTarget, 0.1, args.sourceGUID)
		self:CDBar(317801, self:GetStage() == 2 and 5 or 9)
	end
end

function mod:CursingBlow()
	self:CDBar(317807, self:GetStage() == 2 and 9 or 15)
end

function mod:DesecrationApplied(args)
	if self:Me(args.destGUID) then
		self:PersonalMessage(317788, "underyou")
		self:PlaySound(317788, "underyou")
	end
end

function mod:Voltage(args)
	if self:Me(args.destGUID) and (args.amount or 1) >= 18 then
		self:StackMessage(317785, "blue", args.destName, args.amount, 18)
		self:PlaySound(317785, "alarm")
	end
end

function mod:Curse(args)
	if args.time - prevCurse > 2 then
		prevCurse = args.time
		if args.spellId == 317799 then
			self:Message(317799, "red", L.dont_dispel:format(args.spellName))
			self:PlaySound(317799, "warning")
		elseif self:Dispeller("curse") then
			self:TargetMessage(args.spellId, "orange", args.destName)
			self:PlaySound(args.spellId, "alert")
		end
		self:CDBar(301332, 25)
	end
end

function mod:UNIT_HEALTH(_, unit)
	if not self:IsEngaged() or self:MobId(self:UnitGUID(unit)) ~= 17767 then return end
	local hp = self:GetHealth(unit)
	if hp <= 37 and not warnedSoon then
		warnedSoon = true
		self:Message("stages", "cyan", CL.soon:format(CL.stage:format(2)), false)
	end
	if hp <= 35 and self:GetStage() == 1 then
		self:SetStage(2)
		self:Message("stages", "cyan", CL.stage:format(2), false)
		self:PlaySound("stages", "long")
		self:Bar(317805, 90)
		self:StopBar(301332)
		self:CDBar(317806, 53.5)
		self:Bar(317788, 30)
		self:CDBar(317807, 10)
		self:CDBar(317801, 20)
		self:CancelDelayedMessage(CL.soon:format(self:SpellName(317788)))
		self:DelayedMessage(317788, 30, "orange", CL.soon:format(self:SpellName(317788)), nil, "runaway")
	end
end
