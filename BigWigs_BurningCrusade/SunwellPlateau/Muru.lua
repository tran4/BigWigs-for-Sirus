--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Sunwell/M'uru.lua), draft by tools/dbm2bw
-- Won by the death of Entropius (DBM EndCombat). DBM has only Russian texts here: the English defaults are the Russian texts.

local mod, CL = BigWigs:NewBoss("M'uru", 580, 1595)
if not mod then return end
mod:RegisterEnableMob(25741, 25840) -- M'uru, Entropius
mod:SetEncounterID(728)
mod:SetWinMobs(25840)

--------------------------------------------------------------------------------
-- Locals
--

local humanCount, voidCount = 1, 1

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	-- DBM: no English texts
	human = "Адды-гуманоиды (%d)",
	void = "Часовой Бездны (%d)",
	void_soon = "Часовой Бездны через 5",
	darkness_dispel = "Мрак - РАССЕЙТЕ ЧЕРЕПА!",
	darkness_soon = "Скоро Мрак",
	fiend = "Появился череп - рассейте",
	black_hole = "Черная дыра - РАССЕЙТЕ ЧЕРЕПА!",
	entropius = "Энтропий",
})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"stages",
		"adds",
		45996, -- Darkness
		46268, -- Dark Fiend
		46282, -- Black Hole
		46238, -- Singularity
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "Darkness", 45996)
	self:Log("SPELL_CAST_SUCCESS", "Transform", 46177)
	self:Log("SPELL_SUMMON", "DarkFiend", 46268)
	self:Log("SPELL_SUMMON", "BlackHole", 46282)
end

function mod:OnEngage()
	self:SetStage(1)
	humanCount, voidCount = 1, 1
	self:Bar("adds", 15, L.human:format(1), 27778)
	self:Bar("adds", 36.5, L.void:format(1), 46087)
	self:DelayedMessage("adds", 31.5, "yellow", L.void_soon, 46087) -- DBM: tanks
	self:Bar(45996, 45)
	self:DelayedMessage(45996, 42, "yellow", L.darkness_soon) -- DBM: melee and tanks
	self.humanTimer = self:ScheduleTimer("HumanSpawn", 15)
	self.voidTimer = self:ScheduleTimer("VoidSpawn", 36.5)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:HumanSpawn()
	self:Message("adds", "cyan", L.human:format(humanCount), 27778)
	humanCount = humanCount + 1
	self:Bar("adds", 60, L.human:format(humanCount), 27778)
	self.humanTimer = self:ScheduleTimer("HumanSpawn", 60)
end

function mod:VoidSpawn()
	self:Message("adds", "orange", L.void:format(voidCount), 46087)
	voidCount = voidCount + 1
	self:Bar("adds", 30, L.void:format(voidCount), 46087)
	self:DelayedMessage("adds", 25, "yellow", L.void_soon, 46087)
	self.voidTimer = self:ScheduleTimer("VoidSpawn", 30)
end

function mod:Darkness(args)
	if self:MobId(args.destGUID) == 25741 then
		self:Message(45996, "red", L.darkness_dispel)
		self:PlaySound(45996, "alarm")
		self:Bar(45996, 45)
		self:Bar(45996, 20, CL.other:format(args.spellName, CL.active))
		self:DelayedMessage(45996, 40, "yellow", L.darkness_soon)
	end
end

function mod:Transform()
	self:StopBar(45996)
	self:StopBar(L.human:format(humanCount))
	self:StopBar(L.void:format(voidCount))
	self:CancelDelayedMessage(L.void_soon)
	self:CancelDelayedMessage(L.darkness_soon)
	self:CancelTimer(self.humanTimer)
	self:CancelTimer(self.voidTimer)
	self:Bar("stages", 10, L.entropius, 46087)
	self:ScheduleTimer("Stage2", 10)
end

function mod:Stage2()
	self:SetStage(2)
	self:Message("stages", "cyan", CL.stage:format(2), false)
	self:PlaySound("stages", "long")
	self:CDBar(46282, 17)
end

function mod:DarkFiend()
	self:Message(46268, "orange", L.fiend)
end

function mod:BlackHole()
	self:Message(46282, "red", L.black_hole)
	self:PlaySound(46282, "alarm")
	self:CDBar(46282, 15)
	self:Bar(46238, 3.2)
end
