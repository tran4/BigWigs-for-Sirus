--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Karazhan/WizardOfOz.lua), draft by tools/dbm2bw
-- Opera event, no journal id: the name is from the DBM localization. DBM only knows The Crone (18168).

local mod, CL = BigWigs:NewBoss("The Wizard of Oz", 532)
if not mod then return end
mod:RegisterEnableMob(18168)
mod:SetEncounterID(65502)

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	bossName = "Wizard of Oz",
	engage_trigger = "Oh Tito, we simply must find a way home! The old wizard could be our only hope! Strawman, Roar, Tinhead, will you - wait... oh golly, look we have visitors!",
	roar_trigger = "I'm not afraid a' you! Do you wanna' fight? Huh, do ya'? C'mon! I'll fight ya' with both paws behind my back!",
	strawman_trigger = "Now what should I do with you? I simply can't make up my mind.",
	tinhead_trigger = "I could really use a heart. Say, can I have yours?",
	crone_trigger = "Woe to each and every one of you, my pretties!",

	bosses = "Boss spawns",
	bosses_desc = "Show warnings and timers for boss spawns",
	bosses_icon = "inv_helmet_34",
	tito = "Tito",
	roar = "Roar",
	strawman = "Strawman",
	tinhead = "Tinhead",
	crone = "The Crone",
})
mod.displayName = L.bossName

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"bosses",
		{"proximity", "OFF"}, -- DBM: range frame in phase 2 (off by default)
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "SummonTito", 31014)
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
end

function mod:OnEngage()
	self:Bar("bosses", 14.5, L.roar, "ability_druid_challangingroar")
	self:Bar("bosses", 24, L.strawman, "inv_helmet_34")
	self:Bar("bosses", 33, L.tinhead, "inv_helmet_02")
	self:Bar("bosses", 47.5, L.tito, "ability_mount_whitedirewolf")
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if msg:find(L.engage_trigger, nil, true) then
		if not self:IsEngaged() then self:Engage() end -- DBM RegisterCombat("yell")
	elseif msg == L.roar_trigger then
		self:Message("bosses", "cyan", L.roar, "ability_druid_challangingroar")
	elseif msg == L.strawman_trigger then
		self:Message("bosses", "cyan", L.strawman, "inv_helmet_34")
	elseif msg == L.tinhead_trigger then
		self:Message("bosses", "cyan", L.tinhead, "inv_helmet_02")
	elseif msg == L.crone_trigger then
		self:Message("bosses", "cyan", L.crone, false)
		self:OpenProximity("proximity", 10)
	end
end

function mod:SummonTito()
	self:DelayedMessage("bosses", 1, "cyan", L.tito, "ability_mount_whitedirewolf")
end
