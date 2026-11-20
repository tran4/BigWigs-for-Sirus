--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-ChamberOfAspects/Bronze/Murozond.lua), a custom Sirus raid, no journal id.
-- End of Time (313122) is the intermission: the timers of the boss are pushed back by 75s like DBM.
-- DBM has only Russian texts: the English defaults are the Russian texts. Not ported: the fear fails in the chat.

local mod, CL = BigWigs:NewBoss("Murozond", 10925)
if not mod then return end
mod:RegisterEnableMob(50612)
mod:SetEncounterID(50612) -- DBM Sirus custom encounter id

--------------------------------------------------------------------------------
-- Locals
--

local intermissionCount = 0
local warnedSoon, inIntermission = false, false

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	-- DBM: no English texts
	bossName = "Мурозонд",
	reflect_trigger1 = "Следите за своими чарами..",
	reflect_trigger2 = "То что меня не убивает.. вполне может убить вас.",
	reflect_trigger3 = "Успеете ли среагировать?..",
	intermission_soon = "Скоро Перефаза",
	end_soon = "Конец времени закончится через 5 секунд",
	run_across = "Перебегите",
	black_orb = "Лови - Черную Сферу",
	white_orb = "Лови - Белую Сферу",

	orbs = "Сферы",
	orbs_desc = "Предупреждение 'лови сферу'",
	orbs_icon = 313126,
})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"stages",
		313122, -- End of Time
		{"orbs", "OFF"},
		313116, -- Distortion Wave
		313120, -- Summoning the Timeless
		{313115, "TANK"}, -- Breath of Infinity
		313118, -- Terrifying Future
		-- heroic
		317253, -- Distortion Wave
		{317252, "TANK"}, -- Breath of Infinity
		317255, -- Terrifying Future
		317262, -- Reflect Spells
		317259, -- Time Trap
		{317258, "OFF"}, -- time (healers)
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "DistortionWave", 313116)
	self:Log("SPELL_CAST_START", "BreathOfInfinity", 313115)
	self:Log("SPELL_CAST_START", "Summoning", 313120)
	self:Log("SPELL_CAST_START", "TerrifyingFuture", 313118)
	self:Log("SPELL_CAST_START", "EndOfTime", 313122)
	self:Log("SPELL_CAST_START", "BreathOfInfinityHeroic", 317252)
	self:Log("SPELL_CAST_START", "DistortionWaveHeroic", 317253)
	self:Log("SPELL_CAST_START", "TerrifyingFutureHeroic", 317255)
	self:Log("SPELL_CAST_START", "ReflectSpells", 317262)
	self:Log("SPELL_CAST_SUCCESS", "TimeTrap", 317259)
	self:Log("SPELL_CAST_SUCCESS", "EndOfTimeSuccess", 313122)
	self:Log("SPELL_AURA_APPLIED", "EndOfTimeApplied", 313122)
	self:Log("SPELL_AURA_REMOVED", "EndOfTimeRemoved", 313122)
	self:Log("SPELL_AURA_APPLIED", "Breath", 313115, 317252)
	self:Log("SPELL_AURA_APPLIED_DOSE", "Breath", 313115, 317252)
	self:Log("SPELL_AURA_APPLIED", "Orb", 313129, 313130)
	self:Log("SPELL_AURA_APPLIED", "ReflectApplied", 317262)
	self:Log("SPELL_AURA_APPLIED", "TimeTrapDamage", 317260, 317259, 317261)
	self:Log("SPELL_AURA_APPLIED_DOSE", "TimeTrapDamage", 317260)
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
	self:RegisterEvent("UNIT_HEALTH")
end

function mod:OnEngage()
	self:SetStage(1)
	intermissionCount = 0
	warnedSoon, inIntermission = false, false
	if self:Difficulty() == 6 then -- 25 heroic
		self:Bar(313122, 180, CL.count:format(self:SpellName(313122), 1))
		self:CDBar(313120, 10)
		self:CDBar(317262, 24)
		self:CDBar(317255, 40)
		self:CDBar(317259, 30)
		self:TimeLoop()
	else
		self:CDBar(313116, 20)
		self:CDBar(313120, 35)
		self:CDBar(313115, 50)
		self:CDBar(313118, 40)
	end
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:TimeLoop() -- DBM GibVr: a 5s timer for the healers, off by default
	self:Bar(317258, 5)
	self.timeTimer = self:ScheduleTimer("TimeLoop", 5)
end

function mod:RunAcross()
	if self:GetStage() == 2 then
		self:Message(313122, "orange", L.run_across)
		self:PlaySound(313122, "info")
		self.runTimer = self:ScheduleTimer("RunAcross", 15)
	end
end

local function pushBack(self, keys)
	for i = 1, #keys do
		local left = self:BarTimeLeft(keys[i])
		if left > 0 then
			self:CDBar(keys[i], left + 75) -- DBM: Update(0, 75 + remaining)
		end
	end
end

function mod:DistortionWave() self:CDBar(313116, 40) end
function mod:BreathOfInfinity() self:CDBar(313115, 50) end
function mod:Summoning() self:CDBar(313120, 90) end
function mod:BreathOfInfinityHeroic() self:CDBar(317252, 15) end
function mod:DistortionWaveHeroic() self:CDBar(317253, 40) end
function mod:TimeTrap() self:CDBar(317259, 30) end

function mod:TerrifyingFuture(args)
	self:CDBar(313118, 40)
	if self:Melee() then
		self:Message(313118, "red")
		self:PlaySound(313118, "warning") -- DBM: look away
	end
end

function mod:TerrifyingFutureHeroic(args)
	self:CDBar(317255, 40)
	if self:Melee() then
		self:Message(317255, "red")
		self:PlaySound(317255, "warning")
	end
end

function mod:ReflectSpells(args)
	if not self:Healer() then
		self:Message(317262, "red", CL.casting:format(args.spellName))
		self:PlaySound(317262, "alarm")
	end
end

function mod:ReflectApplied(args)
	self:Bar(317262, 4, CL.other:format(args.spellName, CL.active))
end

function mod:EndOfTime(args)
	if inIntermission then return end
	inIntermission = true
	intermissionCount = intermissionCount + 1
	self:SetStage(2)
	self:CastBar(313122, 10)
	self:DelayedMessage(313122, 65, "yellow", L.end_soon)
	self:Message("stages", "cyan", CL.intermission, false)
	self:PlaySound("stages", "long")
	self:CancelTimer(self.runTimer)
	self.runTimer = self:ScheduleTimer("RunAcross", 19)
	if self:Difficulty() == 6 then
		self:Message(313122, "red", L.intermission_soon)
		self:StopBar(CL.count:format(args.spellName, intermissionCount))
		self:ScheduleTimer(pushBack, 0.1, self, {313120, 317262, 317259, 317252, 317255})
	else
		self:ScheduleTimer(pushBack, 0.1, self, {313120, 313116, 313115, 313118})
	end
end

function mod:EndOfTimeSuccess()
	self:CancelTimer(self.runTimer)
	self.runTimer = self:ScheduleTimer("RunAcross", 9)
end

function mod:EndOfTimeApplied(args)
	if self:Me(args.destGUID) then
		self:Bar(313122, 60, CL.other:format(args.spellName, CL.active))
	end
end

function mod:EndOfTimeRemoved(args)
	if self:MobId(args.destGUID) == 50612 and self:GetStage() == 2 then
		self:SetStage(1)
		inIntermission, warnedSoon = false, false
		self:CancelTimer(self.runTimer)
		self:Message("stages", "cyan", CL.stage:format(1), false)
		if self:Difficulty() == 6 then
			self:Bar(313122, 180, CL.count:format(self:SpellName(313122), intermissionCount + 1))
		end
	end
end

function mod:Breath(args)
	self:StackMessage(args.spellId, "purple", args.destName, args.amount or 1, 1)
	self:TargetBar(args.spellId, args.spellId == 317252 and 120 or 60, args.destName)
end

function mod:Orb(args)
	if self:Me(args.destGUID) then
		self:DelayedMessage("orbs", 1, "blue", args.spellId == 313129 and L.black_orb or L.white_orb, L.orbs_icon, "info")
	end
end

function mod:TimeTrapDamage(args)
	if self:Me(args.destGUID) then
		self:PersonalMessage(317259, "underyou")
		self:PlaySound(317259, "underyou")
	end
end

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if not self:IsEngaged() then return end
	if msg:find(L.reflect_trigger1, nil, true) then
		self:CDBar(317262, 23)
	elseif msg:find(L.reflect_trigger2, nil, true) then
		self:CDBar(317262, 26)
	elseif msg:find(L.reflect_trigger3, nil, true) then
		self:CDBar(317262, 27)
	end
end

function mod:UNIT_HEALTH(_, unit)
	if self:GetStage() == 1 and not warnedSoon and self:IsEngaged() and self:MobId(self:UnitGUID(unit)) == 50612
		and self:GetHealth(unit) < 99 and self:GetHealth(unit) % 25 < 3 then -- DBM: close to 75/50/25% (3.3.5: not at 100% on the pull)
		warnedSoon = true
		self:Message("stages", "cyan", L.intermission_soon, false)
	end
end
