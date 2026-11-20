--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-ZulAman/Jan'alai.lua), draft by tools/dbm2bw

local mod, CL = BigWigs:NewBoss("Jan'alai", 568, 188)
if not mod then return end
mod:RegisterEnableMob(23578)
mod:SetEncounterID(1191)

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	engage_trigger = "Духи ветра станут вашей погибелью!", -- DBM: no English text
	bombs_trigger = "I burn ya now!",
	hatchers_trigger = "Where ma hatcha? Get to work on dem eggs!",

	hatchers = "Смотрители кладки", -- DBM: no English text
	hatchers_desc = "Отсчет времени до прихода смотрителей", -- DBM: no English text
	hatchers_icon = 26297,
	bombs = "Бомбы", -- DBM: no English text
	bombs_desc = "Отсчет времени до начала установки бомб и до взрыва", -- DBM: no English text
	bombs_icon = 31961,
})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"berserk",
		"hatchers",
		"bombs",
		43140, -- Flame Breath
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "FlameBreath", 43140)
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
end

function mod:OnEngage()
	self:Bar("hatchers", 15, L.hatchers, L.hatchers_icon)
	self:Bar("bombs", 40, L.bombs, L.bombs_icon)
	self:CDBar(43140, 12)
	self:Berserk(360)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if msg:find(L.engage_trigger, nil, true) then
		if not self:IsEngaged() then self:Engage() end -- DBM RegisterCombat("yell")
	elseif msg == L.bombs_trigger then
		self:Message("bombs", "red", L.bombs, L.bombs_icon)
		self:Bar("bombs", 11, CL.explosion, 66313)
		self:Bar("bombs", 50, L.bombs, L.bombs_icon)
	elseif msg == L.hatchers_trigger then
		self:Message("hatchers", "cyan", L.hatchers, L.hatchers_icon)
		self:Bar("hatchers", 145, L.hatchers, L.hatchers_icon)
	end
end

function mod:FlameBreath()
	self:CDBar(43140, 12)
end
