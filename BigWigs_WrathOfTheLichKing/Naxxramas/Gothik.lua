--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Naxx/MilitaryQuarter/Gothik.lua), draft by tools/dbm2bw
-- Gothik stays on his balcony in phase 1 and takes no damage: the fight is also engaged by his yell (DBM localization)
-- and by the fighting Unrelenting Knights/Riders, only his death wins.

local mod, CL = BigWigs:NewBoss("Gothik the Harvester", 533, 1608)
if not mod then return end
mod:RegisterEnableMob(16060, 16125, 16126) -- Gothik, Unrelenting Deathknight, Unrelenting Rider
mod:SetEncounterID(1109)
mod:SetWinMobs(16060)

--------------------------------------------------------------------------------
-- Locals
--

local wave = 0
local waves
-- {count, unit, ..., timer = seconds to the next wave}
local wavesNormal = {
	{2, "trainee", timer = 20},
	{2, "trainee", timer = 20},
	{2, "trainee", timer = 10},
	{1, "knight", timer = 10},
	{2, "trainee", timer = 15},
	{1, "knight", timer = 5},
	{2, "trainee", timer = 20},
	{1, "knight", 2, "trainee", timer = 10},
	{1, "rider", timer = 10},
	{2, "trainee", timer = 5},
	{1, "knight", timer = 15},
	{2, "trainee", 1, "rider", timer = 10},
	{2, "knight", timer = 10},
	{2, "trainee", timer = 10},
	{1, "rider", timer = 5},
	{1, "knight", timer = 5},
	{2, "trainee", timer = 20},
	{1, "rider", 1, "knight", 2, "trainee", timer = 15},
	{2, "trainee"},
}
local waves25 = { -- DBM wavesHeroic (used for 25 players)
	{3, "trainee", timer = 20},
	{3, "trainee", timer = 20},
	{3, "trainee", timer = 10},
	{2, "knight", timer = 10},
	{3, "trainee", timer = 15},
	{2, "knight", timer = 5},
	{3, "trainee", timer = 20},
	{3, "trainee", 2, "knight", timer = 10},
	{3, "trainee", timer = 10},
	{1, "rider", timer = 5},
	{3, "trainee", timer = 15},
	{1, "rider", timer = 10},
	{2, "knight", timer = 10},
	{1, "rider", timer = 10},
	{1, "rider", 3, "trainee", timer = 5},
	{1, "knight", 3, "trainee", timer = 5},
	{1, "rider", 3, "trainee", timer = 20},
	{1, "rider", 2, "knight", 3, "trainee"},
}

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	engage_trigger = "Foolishly you have sought your own demise.",

	waves = "Waves",
	waves_desc = "Show pre-warnings and timer for the waves",
	waves_icon = 5502,
	wave_soon = "Wave %d: %s in 3 sec",
	wave_spawned = "Wave spawned",
	wave_spawned_desc = "Show warning for wave spawned",
	wave_spawned_icon = 5502,
	wave_now = "Wave %d: %s spawned",
	wave1 = "%d %s",
	wave2 = "%d %s and %d %s",
	wave3 = "%d %s, %d %s and %d %s",
	trainee = "Trainees",
	knight = "Knights",
	rider = "Riders",

	adds_down = "Riders and Knights down",
	adds_down_desc = "Show warning when an Unrelenting Rider or an Unrelenting Death Knight dies",
	adds_down_icon = 5502,
	rider_down = "Rider down",
	knight_down = "Knight down",

	gate = "Gate Opens", -- DBM: not localized
	gate_desc = "Show timer for the gate opening",
	gate_icon = 9484,
})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"stages",
		"gate",
		"waves",
		{"wave_spawned", "OFF"},
		"adds_down",
	}
end

function mod:OnBossEnable()
	self:Death("RiderDeath", 16126)
	self:Death("KnightDeath", 16125)
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
end

function mod:OnEngage()
	self:SetStage(1)
	waves = self:Difficulty() == 4 and waves25 or wavesNormal
	wave = 0
	self:Bar("gate", 155, L.gate, L.gate_icon)
	self:Bar("stages", 277, CL.stage:format(2), 27082)
	self:ScheduleTimer("StartStage2", 277)
	self:Bar("waves", 25, CL.wave:format(1), L.waves_icon)
	self:DelayedMessage("waves", 22, "yellow", L.wave_soon:format(1, self:WaveString(1)), L.waves_icon)
	self:ScheduleTimer("NextWave", 25)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if msg == L.engage_trigger and not self:IsEngaged() then
		self:Engage()
	end
end

function mod:WaveString(n)
	local info = waves and waves[n]
	if not info then return "" end
	if #info == 2 then
		return L.wave1:format(info[1], L[info[2]])
	elseif #info == 4 then
		return L.wave2:format(info[1], L[info[2]], info[3], L[info[4]])
	else
		return L.wave3:format(info[1], L[info[2]], info[3], L[info[4]], info[5], L[info[6]])
	end
end

function mod:NextWave()
	wave = wave + 1
	self:Message("wave_spawned", "cyan", L.wave_now:format(wave, self:WaveString(wave)), L.wave_spawned_icon)
	local timer = waves[wave] and waves[wave].timer
	if timer then
		self:Bar("waves", timer, CL.wave:format(wave + 1), L.waves_icon)
		self:DelayedMessage("waves", timer - 3, "yellow", L.wave_soon:format(wave + 1, self:WaveString(wave + 1)), L.waves_icon)
		self:ScheduleTimer("NextWave", timer)
	end
end

function mod:StartStage2()
	self:SetStage(2)
	self:Message("stages", "cyan", CL.stage:format(2), 27082)
	self:PlaySound("stages", "long")
end

function mod:RiderDeath()
	self:Message("adds_down", "green", L.rider_down, L.adds_down_icon)
end

function mod:KnightDeath()
	self:Message("adds_down", "green", L.knight_down, L.adds_down_icon)
end
