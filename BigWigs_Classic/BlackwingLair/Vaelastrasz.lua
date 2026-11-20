--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-BWL/Vaelastrasz.lua)
-- The roleplay timer needs the module to be enabled (targeting Vaelastrasz to talk to him does it).

local mod, CL = BigWigs:NewBoss("Vaelastrasz the Corrupt", 469, 1530)
if not mod then return end
mod:RegisterEnableMob(13020)
mod:SetEncounterID(611)

--------------------------------------------------------------------------------
-- Locals
--

local adrenalineIcon = 8

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	warmup_trigger = "Too late, friends! Nefarius' corruption has taken hold...I cannot...control myself.",
})
mod:SetChatEnableTriggers(L.warmup_trigger) -- 3.3.5: enable the module on the warmup yell/emote (no target yet)

--------------------------------------------------------------------------------
-- Initialization
--

local adrenalineMarker = mod:AddMarkerOption(true, "player", 8, 18173, 8, 7, 6)
function mod:GetOptions()
	return {
		"warmup",
		{18173, "SAY_COUNTDOWN"}, -- Burning Adrenaline
		adrenalineMarker,
		{23461, "TANK"}, -- Flame Breath (DBM: tanks only)
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "FlameBreath", 23461)
	self:Log("SPELL_CAST_SUCCESS", "BurningAdrenalineCast", 18173)
	self:Log("SPELL_AURA_APPLIED", "BurningAdrenaline", 18173)
	self:Log("SPELL_AURA_REMOVED", "BurningAdrenalineRemoved", 18173)
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
end

function mod:OnEngage()
	adrenalineIcon = 8
	self:CDBar(18173, 15.7)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

do
	local prev = 0
	function mod:CHAT_MSG_MONSTER_YELL(_, msg)
		local t = GetTime()
		if msg:find(L.warmup_trigger, nil, true) and t - prev > 5 then
			prev = t
			self:Bar("warmup", 43, CL.active, "inv_misc_pocketwatch_01")
		end
	end
end

function mod:FlameBreath(args)
	self:Message(23461, "purple", CL.casting:format(args.spellName))
end

function mod:BurningAdrenalineCast()
	self:CDBar(18173, 15.7)
end

function mod:AdrenalineMoveAway()
	self:Message(18173, "blue", CL.spread)
	self:PlaySound(18173, "alarm") -- DBM: run out
end

function mod:BurningAdrenaline(args)
	self:TargetMessage(18173, "red", args.destName)
	self:TargetBar(18173, 20, args.destName)
	self:CustomIcon(adrenalineMarker, args.destName, adrenalineIcon)
	adrenalineIcon = adrenalineIcon == 6 and 8 or adrenalineIcon - 1
	if self:Me(args.destGUID) then
		self:PlaySound(18173, "warning")
		self:SayCountdown(18173, 20)
		self.moveAwayTimer = self:ScheduleTimer("AdrenalineMoveAway", 15)
	end
end

function mod:BurningAdrenalineRemoved(args)
	self:StopBar(18173, args.destName)
	self:CustomIcon(adrenalineMarker, args.destName)
	if self:Me(args.destGUID) then
		self:CancelTimer(self.moveAwayTimer)
		self:CancelSayCountdown(18173)
	end
end
