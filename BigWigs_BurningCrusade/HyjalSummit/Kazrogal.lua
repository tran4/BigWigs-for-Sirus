--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Hyjal/Kazrogal.lua, Sirus version with custom spells), draft by tools/dbm2bw
-- Not ported: the Mark info frame, the Abyssal icons (DBM finds them by the Russian name), the voice of the stages.

local mod, CL = BigWigs:NewBoss("Kaz'rogal", 534, 1579)
if not mod then return end
mod:RegisterEnableMob(17888)
mod:SetEncounterID(620)

--------------------------------------------------------------------------------
-- Locals
--

local markCount, burningCount, horrorCount, abyssalCount, filthCount = 0, 0, 0, 0, 0
local onslaught = false
local prevMutilation, prevAbyssal, prevBurning, prevFilth = 0, 0, 0, 0

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	abyssals = "Падение Абиссалов", -- DBM: no English text
	onslaught_over = "Неудержимый натиск закончился, можно сбивать касты!", -- DBM: no English text
})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"stages",
		318818, -- Mark
		318825, -- Unstable Abyssals
		318824, -- Horrorflames
		{318828, "DISPEL"}, -- Burning Soul
		318822, -- Unstoppable Onslaught
		{318823, "TANK_HEALER"}, -- Infernal Strike
		{318833, "TANK_HEALER"}, -- Fatal Blow of Filth
		318834, -- Fall of Filth
		{318839, "DISPEL"}, -- Mutilation
		{318841, "TANK_HEALER"}, -- Infernal Strike (stage 3)
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "Mark", 318818)
	self:Log("SPELL_CAST_START", "Horrorflames", 318824)
	self:Log("SPELL_CAST_START", "FallOfFilth", 318834)
	self:Log("SPELL_CAST_START", "InfernalStrike", 318823, 318841) -- 3.3.5: DBM has the handler of 318841, but does not register it
	self:Log("SPELL_CAST_START", "FatalBlow", 318833)
	self:Log("SPELL_CAST_SUCCESS", "BurningSoulSuccess", 318828)
	self:Log("SPELL_CAST_SUCCESS", "MutilationSuccess", 318839)
	self:Log("SPELL_AURA_APPLIED", "MarkApplied", 318819)
	self:Log("SPELL_AURA_APPLIED", "Mutilation", 318839)
	self:Log("SPELL_AURA_APPLIED", "AbyssalDamage", 318825)
	self:Log("SPELL_AURA_APPLIED", "Onslaught", 318822)
	self:Log("SPELL_AURA_REMOVED", "OnslaughtRemoved", 318822)
	self:Log("SPELL_AURA_APPLIED", "BurningSoul", 318828)
	self:RegisterEvent("UNIT_HEALTH")
end

function mod:OnEngage()
	self:SetStage(1)
	markCount, burningCount, horrorCount, abyssalCount, filthCount = 0, 0, 0, 0, 0
	onslaught = false
	prevMutilation, prevAbyssal, prevBurning, prevFilth = 0, 0, 0, 0
	self:Bar(318824, 15, CL.count:format(self:SpellName(318824), 1))
	self:Bar(318823, 7)
	self:Bar(318828, 20, CL.count:format(self:SpellName(318828), 1))
	self:Bar(318818, 1, CL.count:format(self:SpellName(318818), 1))
	self:AbyssalsBar(60, 1)
	self.abyssalTimer = self:ScheduleTimer("Abyssals", 60)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:AbyssalsBar(time, count)
	self:Bar(318825, time, CL.count:format(L.abyssals, count))
	self:DelayedMessage(318825, time - 4, "orange", CL.soon:format(L.abyssals))
	self:DelayedMessage(318825, time - 1, "red", CL.soon:format(L.abyssals), nil, "alarm")
end

function mod:Abyssals()
	abyssalCount = abyssalCount + 1
	local time = self:GetStage() == 1 and 90 or 20
	self:AbyssalsBar(time, abyssalCount + 1)
	self.abyssalTimer = self:ScheduleTimer("Abyssals", time)
end

function mod:Mark(args)
	markCount = markCount + 1
	self:Bar(318818, 24, CL.count:format(args.spellName, markCount + 1))
end

function mod:Horrorflames(args)
	if not onslaught and self:Interrupter(args.sourceGUID) then
		self:Message(318824, "red", CL.casting:format(args.spellName))
		self:PlaySound(318824, "alert")
	end
	horrorCount = horrorCount + 1
	self:Bar(318824, 16, CL.count:format(args.spellName, horrorCount + 1))
end

function mod:FallOfFilth(args)
	if not onslaught and self:Interrupter(args.sourceGUID) then
		self:Message(318834, "red", CL.casting:format(args.spellName))
		self:PlaySound(318834, "alert")
	end
	local left = self:BarTimeLeft(CL.count:format(args.spellName, filthCount + 1))
	if left < 3 and onslaught and args.time - prevFilth > 2 then
		prevFilth = args.time
		self:Message(318834, "orange", CL.soon:format(args.spellName))
	end
	filthCount = filthCount + 1
	self:Bar(318834, 17, CL.count:format(args.spellName, filthCount + 1))
end

function mod:InfernalStrike(args)
	self:Message(args.spellId, "purple", CL.casting:format(args.spellName))
	self:Bar(args.spellId, args.spellId == 318841 and 6 or 9)
end

function mod:FatalBlow(args)
	self:Message(318833, "purple", CL.casting:format(args.spellName))
	self:Bar(318833, 17)
end

function mod:BurningSoulSuccess(args)
	burningCount = burningCount + 1
	self:Bar(318828, 20, CL.count:format(args.spellName, burningCount + 1))
end

function mod:MutilationSuccess()
	self:Bar(318839, 20)
end

function mod:MarkApplied(args)
	self:TargetMessage(318818, "yellow", args.destName)
end

function mod:Mutilation(args)
	if args.time - prevMutilation > 2 and self:Dispeller("curse", nil, 318839) then
		prevMutilation = args.time
		self:TargetMessage(318839, "orange", args.destName)
		self:PlaySound(318839, "alert")
	end
end

function mod:AbyssalDamage(args)
	if self:Me(args.destGUID) and args.time - prevAbyssal > 4 then
		prevAbyssal = args.time
		self:PersonalMessage(318825, "underyou")
		self:PlaySound(318825, "underyou")
	end
end

function mod:Onslaught(args)
	if not onslaught then
		onslaught = true
		self:Bar(318822, 25, CL.other:format(args.spellName, CL.active))
	end
end

function mod:OnslaughtRemoved(args)
	if onslaught then
		onslaught = false
		if self:Interrupter() then
			self:Message(318822, "green", L.onslaught_over)
			self:PlaySound(318822, "info")
		end
	end
end

function mod:BurningSoul(args)
	if args.time - prevBurning > 2 and self:Dispeller("magic", nil, 318828) then
		prevBurning = args.time
		self:TargetMessage(318828, "orange", args.destName)
		self:PlaySound(318828, "alert")
	end
end

function mod:UNIT_HEALTH(_, unit)
	if not self:IsEngaged() or self:MobId(self:UnitGUID(unit)) ~= 17888 then return end
	local hp, stage = self:GetHealth(unit), self:GetStage()
	if hp < 67 and stage == 1 then
		self:SetStage(2)
		self:Message("stages", "cyan", CL.stage:format(2), false)
		self:PlaySound("stages", "long")
		self:CancelTimer(self.abyssalTimer)
		self:StopBar(CL.count:format(L.abyssals, abyssalCount + 1))
		self:CancelDelayedMessage(CL.soon:format(L.abyssals))
		self:StopBar(CL.count:format(self:SpellName(318824), horrorCount + 1))
		self:StopBar(318823)
		self:StopBar(CL.count:format(self:SpellName(318818), markCount + 1))
		self:StopBar(CL.count:format(self:SpellName(318828), burningCount + 1))
		self:Bar(318839, 20)
		self:Bar(318834, 16.5, CL.count:format(self:SpellName(318834), filthCount + 1))
		self:Bar(318833, 15)
	elseif hp < 33 and stage == 2 then
		abyssalCount = 0
		self:SetStage(3)
		self:Message("stages", "cyan", CL.stage:format(3), false)
		self:PlaySound("stages", "long")
		self:StopBar(318839)
		self:StopBar(CL.count:format(self:SpellName(318834), filthCount + 1))
		self:Bar(318825, 20, CL.count:format(L.abyssals, 1))
		self.abyssalTimer = self:ScheduleTimer("Abyssals", 20)
		self:Bar(318824, 10, CL.count:format(self:SpellName(318824), horrorCount + 1))
		self:DelayedMessage(318825, 8, "orange", CL.soon:format(L.abyssals))
	end
end
