--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-BlackTemple/Najentus.lua, Sirus version with custom spells), draft by tools/dbm2bw
-- The Colossal Strikes come in series: one more strike per health threshold (85/70/55/40/25%), like DBM.
-- Not ported: the info frame, the curse timer correction marked as untested in DBM.

local mod, CL = BigWigs:NewBoss("High Warlord Naj'entus", 564, 1582)
if not mod then return end
mod:RegisterEnableMob(22887)
mod:SetEncounterID(601)

--------------------------------------------------------------------------------
-- Locals
--

local miniStage, strike, roarCount = 1, 1, 0
local stageUp = false
local thresholds = {85, 70, 55, 40, 25}
local passed = {}
local curseTargets = {}
local prevSpine = 0

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"berserk",
		321598, -- Colossal Strike
		321595, -- Tidal Roar
		{321599, "DISPEL"}, -- Water Curse
		321596, -- Piercing Spine
		"proximity",
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "ColossalStrike", 321598)
	self:Log("SPELL_CAST_START", "TidalRoar", 321595)
	self:Log("SPELL_CAST_SUCCESS", "WaterCurseSuccess", 321599)
	self:Log("SPELL_CAST_SUCCESS", "PiercingSpine", 321596)
	self:Log("SPELL_AURA_APPLIED", "WaterCurse", 321599)
	self:RegisterEvent("UNIT_HEALTH")
end

function mod:OnEngage()
	miniStage, strike, roarCount = 1, 1, 0
	stageUp = false
	passed = {}
	curseTargets = {}
	prevSpine = 0
	self:Berserk(360)
	self:CDBar(321598, 5.5, CL.count:format(self:SpellName(321598), 1))
	self:CDBar(321595, 21)
	self:CDBar(321599, 30)
	self:CDBar(321596, 19)
	self:OpenProximity("proximity", 8)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:ResetStrikes()
	strike = 1
end

function mod:ColossalStrike(args)
	if self:Melee() then
		self:Message(321598, "red", CL.count_amount:format(args.spellName, strike, miniStage))
		self:PlaySound(321598, "alarm")
	end
	if miniStage ~= strike then
		stageUp = false
		self:CDBar(321598, 3.7, CL.count:format(args.spellName, strike + 1))
		self:CancelTimer(self.strikeTimer)
		self.strikeTimer = self:ScheduleTimer("ResetStrikes", 4.5)
		strike = strike + 1
	else
		strike = 1
		stageUp = true
	end
end

function mod:TidalRoar()
	roarCount = roarCount + 1
	self:CDBar(321595, 20.5)
end

function mod:WaterCurseSuccess(args)
	self:CDBar(321599, 30)
end

function mod:PiercingSpine(args)
	if args.time - prevSpine > 3 then
		prevSpine = args.time
		self:CDBar(321596, 19)
	end
end

function mod:AnnounceCurse()
	self:TargetsMessage(321599, "orange", curseTargets, #curseTargets)
	if self:Dispeller("curse", nil, 321599) then
		self:PlaySound(321599, "alert")
	end
	curseTargets = {}
end

function mod:WaterCurse(args)
	curseTargets[#curseTargets + 1] = args.destName
	self:CancelTimer(self.curseTimer)
	self.curseTimer = self:ScheduleTimer("AnnounceCurse", 0.1)
end

function mod:UNIT_HEALTH(_, unit)
	if not stageUp or self:MobId(self:UnitGUID(unit)) ~= 22887 then return end
	local hp = self:GetHealth(unit)
	for i = 1, #thresholds do
		if not passed[i] and hp < thresholds[i] then
			passed[i] = true
			miniStage = miniStage + 1
			break
		end
	end
end
