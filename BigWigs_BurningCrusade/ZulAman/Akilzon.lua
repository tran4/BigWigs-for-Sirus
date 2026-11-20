--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-ZulAman/Akil'zon.lua), draft by tools/dbm2bw

local mod, CL = BigWigs:NewBoss("Akil'zon", 568, 186)
if not mod then return end
mod:RegisterEnableMob(23574)
mod:SetEncounterID(1189)

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	engage_trigger = "Я – охотник! Вы – добыча!", -- DBM: no English text
})

--------------------------------------------------------------------------------
-- Initialization
--

local stormMarker = mod:AddMarkerOption(true, "player", 1, 43648, 1)
function mod:GetOptions()
	return {
		"berserk",
		{43648, "SAY"}, -- Electrical Storm
		stormMarker,
		43621, -- Gust of Wind
		44008, -- Static Disruption
		43622, -- Static Disruption (Disrupt)
		"proximity",
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "ElectricalStorm", 43648)
	self:Log("SPELL_AURA_REMOVED", "ElectricalStormRemoved", 43648)
	self:Log("SPELL_AURA_APPLIED", "StaticDisruption", 44008)
	self:Log("SPELL_CAST_SUCCESS", "GustOfWind", 43621)
	self:Log("SPELL_CAST_SUCCESS", "StaticDisruptionSuccess", 44008)
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
end

function mod:OnEngage()
	self:DelayedMessage(43648, 50, "yellow", CL.soon:format(self:SpellName(43648)))
	self:CDBar(43648, 60)
	self:Berserk(480)
	self:CDBar(44008, 10)
	self:OpenProximity("proximity", 12)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if msg:find(L.engage_trigger, nil, true) and not self:IsEngaged() then
		self:Engage() -- DBM RegisterCombat("yell")
	end
end

function mod:ElectricalStorm(args)
	self:TargetMessage(43648, "red", args.destName)
	self:PlaySound(43648, "long")
	self:CastBar(43648, 8)
	self:DelayedMessage(43648, 50, "yellow", CL.soon:format(args.spellName))
	self:CDBar(43648, 60)
	self:CloseProximity("proximity")
	self:ScheduleTimer("OpenProximity", 10, "proximity", 12)
	self:CustomIcon(stormMarker, args.destName, 1)
	if self:Me(args.destGUID) then
		self:Say(43648)
	end
end

function mod:ElectricalStormRemoved(args)
	self:CustomIcon(stormMarker, args.destName)
	self:CDBar(43622, 11)
end

function mod:StaticDisruption(args)
	if self:Me(args.destGUID) then
		self:PersonalMessage(43622)
		self:PlaySound(43622, "runaway")
	end
end

function mod:GustOfWind(args)
	self:TargetMessage(43621, "orange", args.destName)
end

function mod:StaticDisruptionSuccess()
	self:CDBar(44008, 15)
end
