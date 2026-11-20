--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Naxx/PlagueQuarter/Heigan.lua), draft by tools/dbm2bw
-- DBM shows only the timers of the dance (no spell events).

local mod, CL = BigWigs:NewBoss("Heigan the Unclean", 533, 1605)
if not mod then return end
mod:RegisterEnableMob(15936)
mod:SetEncounterID(1112)

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	engage_trigger = "You are mine now.",

	teleport = "Teleport",
	teleport_desc = "Show warnings and timer for Teleport",
	teleport_icon = 46573,
	teleport_now = "Teleported",
	teleport_soon = "Teleport in %d seconds",
})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"teleport",
		30122, -- Plague Cloud
		373551, -- mark (WA, heroic)
	}
end

function mod:OnBossEnable()
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
	self:Log("SPELL_AURA_APPLIED", "HeroicMark", 373551) -- WA: "Naxx", group "Хейган"
end

function mod:HeroicMark(args) -- WA
	self:TargetMessage(373551, "red", args.destName)
	if self:Me(args.destGUID) then
		self:PlaySound(373551, "warning")
	end
end

function mod:OnEngage()
	self:BackInRoom(90)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if msg == L.engage_trigger and not self:IsEngaged() then
		self:Engage() -- DBM RegisterCombat("combat_yell")
	end
end

function mod:DancePhase()
	self:SetStage(2)
	self:Message("teleport", "orange", L.teleport_now, L.teleport_icon)
	self:PlaySound("teleport", "long")
	self:CastBar(30122, 45)
	self:DelayedMessage("teleport", 35, "yellow", L.teleport_soon:format(10), L.teleport_icon)
	self:DelayedMessage(30122, 45, "green", CL.over:format(self:SpellName(30122)))
	self:ScheduleTimer("BackInRoom", 45, 88)
end

function mod:BackInRoom(time)
	self:SetStage(1)
	self:Bar("teleport", time, L.teleport, L.teleport_icon)
	self:DelayedMessage("teleport", time - 15, "yellow", L.teleport_soon:format(15), L.teleport_icon)
	self:ScheduleTimer("DancePhase", time)
end
