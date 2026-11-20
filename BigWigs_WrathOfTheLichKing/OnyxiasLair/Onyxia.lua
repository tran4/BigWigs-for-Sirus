--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Onyxia/Onyxia.lua), draft by tools/dbm2bw
-- Not ported: the achievement timers and the funny sounds.

local mod, CL = BigWigs:NewBoss("Onyxia", 249, 1651)
if not mod then return end
mod:RegisterEnableMob(10184)
mod:SetEncounterID(1084)

--------------------------------------------------------------------------------
-- Locals
--

local whelpsCount = 0
local warnedStage2, warnedStage3 = false, false

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	engage_trigger = "How fortuitous. Usually, I must leave my lair in order to feed.",
	stage2_trigger = "This meaningless exertion bores me. I'll incinerate you all from above!",
	stage3_trigger = "It seems you'll need another lesson, mortals!",

	whelps = "Onyxian Whelps",
	whelps_desc = "Show warnings and timer for Onyxian Whelps",
	whelps_icon = 69004,
	whelps_soon = "Onyxian Whelps soon",
})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"stages",
		"whelps",
		{18435, "TANK"}, -- Flame Breath
		{18500, "TANK"}, -- Wing Buffet
		18584, -- Deep Breath
		68958, -- Blast Nova
		68959, -- Ignite Weapon (Onyxian Lair Guard)
		18431, -- Bellowing Roar
		{18392, "SAY"}, -- Fireball
		{19633, "OFF"}, -- Knock Away
		"proximity",
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "BlastNova", 68958)
	self:Log("SPELL_CAST_START", "DeepBreath", 17086, 18351, 18564, 18576, 18584, 18596, 18609, 18617)
	self:Log("SPELL_CAST_START", "FlameBreath", 18435, 68970)
	self:Log("SPELL_CAST_START", "IgniteWeapon", 68959)
	self:Log("SPELL_CAST_START", "BellowingRoar", 18431)
	self:Log("SPELL_CAST_START", "WingBuffet", 18500)
	self:Log("SPELL_CAST_START", "Fireball", 18392)
	self:Log("SPELL_CAST_SUCCESS", "KnockAway", 19633)
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
	self:RegisterUnitEvent("UNIT_HEALTH", nil, "boss1")
end

function mod:OnEngage()
	self:SetStage(1)
	whelpsCount = 0
	warnedStage2, warnedStage3 = false, false
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if msg == L.engage_trigger then
		if not self:IsEngaged() then self:Engage() end -- DBM StartCombat on the yell
	elseif not self:IsEngaged() then
		return
	elseif msg:find(L.stage2_trigger, nil, true) then
		self:SetStage(2)
		whelpsCount = 0
		self:Message("stages", "cyan", CL.stage:format(2), false)
		self:PlaySound("stages", "long")
		self:CDBar(18584, 77)
		self:StopBar(18435)
		self.whelpsTimer = self:ScheduleTimer("Whelps", 5)
		self:OpenProximity("proximity", 8)
	elseif msg:find(L.stage3_trigger, nil, true) then
		self:SetStage(3)
		self:Message("stages", "cyan", CL.stage:format(3), false)
		self:PlaySound("stages", "long")
		self:CancelTimer(self.whelpsTimer)
		self:StopBar(L.whelps)
		self:CancelDelayedMessage(L.whelps_soon)
		self:StopBar(18584)
		self:StopBar(68959)
		self:CloseProximity("proximity")
	end
end

function mod:Whelps()
	whelpsCount = whelpsCount + 1
	self:Bar("whelps", 105, L.whelps, 10697)
	self:DelayedMessage("whelps", 95, "yellow", L.whelps_soon, L.whelps_icon)
	self.whelpsTimer = self:ScheduleTimer("Whelps", 105)
end

function mod:UNIT_HEALTH(_, unit)
	if self:MobId(self:UnitGUID(unit)) ~= 10184 then return end
	local hp, stage = self:GetHealth(unit), self:GetStage()
	if stage == 1 and not warnedStage2 and hp <= 70 then
		warnedStage2 = true
		self:Message("stages", "cyan", CL.soon:format(CL.stage:format(2)), false)
	elseif stage == 2 and not warnedStage3 and hp <= 45 then
		warnedStage3 = true
		self:Message("stages", "cyan", CL.soon:format(CL.stage:format(3)), false)
	end
end

function mod:BlastNova(args)
	if self:Melee() then
		self:Message(68958, "red")
		self:PlaySound(68958, "runaway")
	end
end

function mod:DeepBreath(args)
	self:Message(18584, "red")
	self:PlaySound(18584, "warning")
	self:CastBar(18584, 8)
	self:CDBar(18584, 35)
end

function mod:FlameBreath()
	self:CDBar(18435, 13.3)
end

function mod:IgniteWeapon(args)
	self:Message(68959, "orange", CL.incoming:format(CL.adds))
	if not self:Healer() then
		self:PlaySound(68959, "info")
	end
	self:Bar(68959, 44.9)
end

function mod:BellowingRoar(args)
	self:Message(18431, "red")
	self:PlaySound(18431, "alarm")
end

function mod:WingBuffet(args)
	self:Message(18500, "purple")
end

do
	local function fireballTarget(self, name, guid)
		self:TargetMessage(18392, "yellow", name)
		if self:Me(guid) then
			self:Say(18392)
		end
	end
	function mod:Fireball(args)
		self:GetUnitTarget(fireballTarget, 0.15, args.sourceGUID)
	end
end

function mod:KnockAway(args)
	self:TargetMessage(19633, "yellow", args.destName)
end
