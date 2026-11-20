--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-ChamberOfAspects/Ruby/Halion.lua), draft by tools/dbm2bw
-- The physical (39863) and the twilight (40142) Halion share their health: the death of either wins. Without the DBM
-- syncs only the events of your own realm are seen. Not ported: the health frame, nameplate icons.

local mod, CL = BigWigs:NewBoss("Halion", 724, 1652)
if not mod then return end
mod:RegisterEnableMob(39863, 40142)
mod:SetEncounterID(1150)
mod:SetWinMobs()

--------------------------------------------------------------------------------
-- Locals
--

local warnedStage2, warnedStage3 = false, false
local prevMeteor = 0
local meteorStrike = {[75952] = true, [75951] = true, [75950] = true, [75949] = true, [75948] = true, [75947] = true}

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	stage2_trigger = "You will find only suffering within the realm of twilight! Enter if you dare!",
	stage3_trigger = "I am the light and the darkness! Cower, mortals, before the herald of Deathwing!",
	meteor_trigger = "The heavens burn!",
	cutter_trigger = "Beware the shadow!",
	cutter_cast = "Casting Twilight Cutter: 5 sec",
})

--------------------------------------------------------------------------------
-- Initialization
--

local consumptionMarker = mod:AddMarkerOption(true, "player", 8, 74562, 8, 7)
function mod:GetOptions()
	return {
		"stages",
		"berserk",
		{74562, "SAY"}, -- Fiery Combustion
		{74792, "SAY"}, -- Soul Consumption
		consumptionMarker,
		74648, -- Meteor Strike
		{74526, "TANK_HEALER"}, -- Flame Breath
		{75954, "TANK_HEALER"}, -- Dark Breath
		77844, -- Twilight Cutter
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "DarkBreath", 74806, 75954, 75955, 75956)
	self:Log("SPELL_CAST_START", "FlameBreath", 74525, 74526, 74527, 74528)
	self:Log("SPELL_AURA_APPLIED", "SoulConsumption", 74792)
	self:Log("SPELL_AURA_REMOVED", "ConsumptionRemoved", 74792, 74562)
	self:Log("SPELL_AURA_APPLIED", "FieryCombustion", 74562)
	self:Log("SPELL_DAMAGE", "MeteorStrikeDamage", 75952, 75951, 75950, 75949, 75948, 75947)
	self:Death("Win", 39863, 40142)
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
	self:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE")
	self:RegisterEvent("UNIT_HEALTH")
end

function mod:OnEngage()
	self:SetStage(1)
	warnedStage2, warnedStage3 = false, false
	prevMeteor = 0
	self:Berserk(480)
	self:Bar(74648, 20)
	self:Bar(74562, 15)
	self:CDBar(74526, 10)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

local function consumptionCD(self)
	return self:Heroic() and 20 or 25
end

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if not self:IsEngaged() then return end
	if msg:find(L.stage2_trigger, nil, true) then
		self:SetStage(2)
		self:StopBar(74526)
		self:StopBar(74648)
		self:StopBar(74562)
		self:Message("stages", "cyan", CL.stage:format(2), false)
		self:PlaySound("stages", "long")
		self:CDBar(75954, 20)
		self:Bar(74792, 20)
		self:Bar(77844, self:Heroic() and 40 or 35)
	elseif msg:find(L.stage3_trigger, nil, true) then
		self:SetStage(3)
		self:Message("stages", "cyan", CL.stage:format(3), false)
		self:PlaySound("stages", "long")
		self:Bar(74648, 30)
		self:Bar(74562, 20)
	elseif msg:find(L.meteor_trigger, nil, true) then -- DBM: there is no combat log cast, only the yell
		self:Message(74648, "orange")
		self:CastBar(74648, 7)
		self:Bar(74648, 40)
	end
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(_, msg)
	if self:IsEngaged() and msg:find(L.cutter_trigger, nil, true) then
		local realm5 = BigWigsLoader.Compat.GetRealmNumber() == 5 -- 3.3.5: DBM Sirus x5 realm timers
		self:Message(77844, "orange", L.cutter_cast)
		self:CastBar(77844, 5)
		self:DelayedMessage(77844, 5, "red", self:SpellName(77844), nil, "alarm")
		self:ScheduleTimer("Bar", 5, 77844, realm5 and 9 or 10, CL.other:format(self:SpellName(77844), CL.active))
		self:ScheduleTimer("Bar", realm5 and 15 or 20, 77844, realm5 and 15 or 20)
	end
end

function mod:UNIT_HEALTH(_, unit)
	if not self:IsEngaged() then return end
	local mobId = self:MobId(self:UnitGUID(unit))
	if not warnedStage2 and mobId == 39863 and self:GetHealth(unit) <= 79 then
		warnedStage2 = true
		self:Message("stages", "cyan", CL.soon:format(CL.stage:format(2)), false)
	elseif not warnedStage3 and mobId == 40142 and self:GetHealth(unit) <= 54 then
		warnedStage3 = true
		self:Message("stages", "cyan", CL.soon:format(CL.stage:format(3)), false)
	end
end

function mod:DarkBreath(args)
	self:Message(75954, "orange")
	self:CDBar(75954, 19)
end

function mod:FlameBreath(args)
	self:Message(74526, "orange")
	self:CDBar(74526, 19)
end

function mod:SoulConsumption(args)
	self:TargetMessage(74792, "red", args.destName)
	self:Bar(74792, consumptionCD(self))
	self:CustomIcon(consumptionMarker, args.destName, 7)
	if self:Me(args.destGUID) then
		self:PlaySound(74792, "runaway")
		self:Say(74792)
	end
end

function mod:FieryCombustion(args)
	self:TargetMessage(74562, "red", args.destName)
	self:Bar(74562, consumptionCD(self))
	self:CustomIcon(consumptionMarker, args.destName, 8)
	if self:Me(args.destGUID) then
		self:PlaySound(74562, "runaway")
		self:Say(74562)
	end
end

function mod:ConsumptionRemoved(args)
	self:CustomIcon(consumptionMarker, args.destName)
end

-- 3.3.5: DBM keys the meteor ids by strings and compares numbers, so the warning never shows there
function mod:MeteorStrikeDamage(args)
	if meteorStrike[args.spellId] and self:Me(args.destGUID) and args.time - prevMeteor > 2 then
		prevMeteor = args.time
		self:PersonalMessage(74648, "underyou")
		self:PlaySound(74648, "underyou")
	end
end
