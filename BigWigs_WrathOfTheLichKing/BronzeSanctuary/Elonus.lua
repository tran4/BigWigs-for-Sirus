--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-ChamberOfAspects/Bronze/Elonus.lua), a custom Sirus raid, no journal id.
-- The replica of Elonus (50610) does not win, Elonus (50609) does. DBM has only Russian texts: the English defaults are
-- the Russian texts. Not ported: the shield and health frames, the info frame, announcing to the raid chat.

local mod, CL = BigWigs:NewBoss("Elonus", 10925)
if not mod then return end
mod:RegisterEnableMob(50609, 50610)
mod:SetEncounterID(50609) -- DBM Sirus custom encounter id
mod:SetWinMobs(50609)

--------------------------------------------------------------------------------
-- Locals
--

local returnCount, replicaCount, eraseCount = 0, 0, 0
local revIcon, eraseIcon = 6, 3
local tempTargets, revTargets, eraseTargets = {}, {}, {}
local prevReturn, prevPunishment = 0, 0
local warnedSoon = false

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	-- DBM: no English texts
	bossName = "Элонус",
	replica = "Появляется копия Элонуса Исказитель времени!!!",
	replica_soon = "Скоро появляется копия Элонуса",
})
mod.displayName = L.bossName

--------------------------------------------------------------------------------
-- Initialization
--

local tempMarker = mod:AddMarkerOption(true, "player", 5, 312206, 5)
local revMarker = mod:AddMarkerOption(true, "player", 6, 312208, 6, 5, 4, 3, 2, 1)
local eraseMarker = mod:AddMarkerOption(true, "player", 3, 312204, 3, 2, 1)
function mod:GetOptions()
	return {
		"stages",
		312211, -- Timelines (replicas)
		312214, -- Return
		312210, -- Resonant Scream
		312204, -- Power Word: Erase
		eraseMarker,
		{312206, "SAY"}, -- Temporal Cascade
		tempMarker,
		{312208, "SAY"}, -- Reverse Cascade
		revMarker,
		{317155, "TANK"}, -- Arcane Punishment
		312213, -- shield
		317165, -- Timeless Whirlwinds (heroic)
		"proximity",
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "Return", 312214)
	self:Log("SPELL_CAST_START", "Timelines", 312211)
	self:Log("SPELL_CAST_START", "ResonantScream", 312210)
	self:Log("SPELL_CAST_START", "EraseCast", 312204, 317156)
	self:Log("SPELL_AURA_APPLIED", "TemporalCascade", 312206, 317158)
	self:Log("SPELL_AURA_REFRESH", "TemporalCascade", 312206, 317158)
	self:Log("SPELL_AURA_REMOVED", "TemporalCascadeRemoved", 312206, 317158)
	self:Log("SPELL_AURA_APPLIED", "ReverseCascade", 312208, 317160, 317161, 312209)
	self:Log("SPELL_AURA_REFRESH", "ReverseCascade", 312208, 317160, 317161, 312209)
	self:Log("SPELL_AURA_REMOVED", "ReverseCascadeRemoved", 312208, 317160, 317161, 312209)
	self:Log("SPELL_AURA_APPLIED", "Erase", 312204, 317156)
	self:Log("SPELL_AURA_REMOVED", "EraseRemoved", 312204, 317156)
	self:Log("SPELL_AURA_APPLIED", "ArcanePunishment", 317155)
	self:Log("SPELL_AURA_APPLIED_DOSE", "ArcanePunishment", 317155)
	self:Log("SPELL_AURA_REFRESH", "ArcanePunishment", 317155)
	self:Log("SPELL_AURA_REMOVED", "ShieldRemoved", 312213, 317163)
	self:Log("SPELL_AURA_APPLIED", "TimelessWhirlwinds", 317165)
	self:Log("SPELL_AURA_REFRESH", "TimelessWhirlwinds", 317165)
	self:RegisterEvent("UNIT_HEALTH")
end

function mod:OnEngage()
	self:SetStage(1)
	returnCount, replicaCount, eraseCount = 0, 0, 0
	revIcon, eraseIcon = 6, 3
	tempTargets, revTargets, eraseTargets = {}, {}, {}
	prevReturn, prevPunishment = 0, 0
	warnedSoon = false
	self:CDBar(312206, 20)
	self:CDBar(312210, 12)
	self:CDBar(312204, 66, CL.count:format(self:SpellName(312204), 1))
	if self:Difficulty() == 4 then -- 25 normal
		self:CDBar(312211, 25, CL.count:format(self:SpellName(312211), 1))
		self:CDBar(312214, 30, CL.count:format(self:SpellName(312214), 1))
	end
	self:OpenProximity("proximity", 6)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:Return(args)
	if args.time - prevReturn > 3 then
		prevReturn = args.time
		returnCount = returnCount + 1
		self:CDBar(312214, 120, CL.count:format(args.spellName, returnCount + 1))
		self:Message(312214, "red", CL.casting:format(args.spellName))
		if not self:Healer() then
			self:PlaySound(312214, "alert") -- DBM: switch (dps)
		end
		self:StopBar(312210)
	end
end

function mod:Timelines(args)
	replicaCount = replicaCount + 1
	self:Message(312211, "cyan", L.replica)
	self:CDBar(312211, 120, CL.count:format(args.spellName, replicaCount + 1))
end

function mod:ResonantScream(args)
	self:CDBar(312210, 12)
	if self:Ranged() then -- DBM: SpellCaster
		self:Message(312210, "orange", CL.casting:format(args.spellName))
		self:PlaySound(312210, "alert")
	end
end

function mod:EraseCast(args)
	eraseCount = eraseCount + 1
	self:CDBar(312204, 60, CL.count:format(self:SpellName(312204), eraseCount + 1))
end

function mod:AnnounceTemporal()
	self:TargetsMessage(312206, "red", tempTargets, #tempTargets)
	tempTargets = {}
end

function mod:TemporalCascade(args)
	tempTargets[#tempTargets + 1] = args.destName
	self:CustomIcon(tempMarker, args.destName, 5)
	self:CDBar(312206, 20)
	self:TargetBar(312206, 10, args.destName)
	self:CDBar(317165, 20)
	if self:Me(args.destGUID) then
		self:PlaySound(312206, "warning")
		self:Say(312206)
	end
	self:CancelTimer(self.tempTimer)
	self.tempTimer = self:ScheduleTimer("AnnounceTemporal", 0.1)
end

function mod:TemporalCascadeRemoved(args)
	self:CustomIcon(tempMarker, args.destName)
end

function mod:AnnounceReverse()
	self:TargetsMessage(312208, "orange", revTargets, #revTargets)
	revTargets = {}
	revIcon = 6
end

function mod:ReverseCascade(args)
	revTargets[#revTargets + 1] = args.destName
	if revIcon > 0 then
		self:CustomIcon(revMarker, args.destName, revIcon)
		revIcon = revIcon - 1
	end
	self:Bar(312208, 10, CL.other:format(self:SpellName(312208), CL.active))
	if self:Me(args.destGUID) then
		self:PlaySound(312208, "runaway")
		self:Say(312208)
	end
	self:CancelTimer(self.revTimer)
	self.revTimer = self:ScheduleTimer("AnnounceReverse", 0.1)
end

function mod:ReverseCascadeRemoved(args)
	self:CustomIcon(revMarker, args.destName)
end

function mod:AnnounceErase()
	self:TargetsMessage(312204, "yellow", eraseTargets, #eraseTargets)
	eraseTargets = {}
	eraseIcon = 3
end

function mod:Erase(args)
	if self:Difficulty() == 4 then -- 25 normal
		eraseTargets[#eraseTargets + 1] = args.destName
		if eraseIcon > 0 then
			self:CustomIcon(eraseMarker, args.destName, eraseIcon)
			eraseIcon = eraseIcon - 1
		end
		self:CancelTimer(self.eraseTimer)
		self.eraseTimer = self:ScheduleTimer("AnnounceErase", 0.3)
	else
		self:TargetMessage(312204, "yellow", args.destName)
	end
end

function mod:EraseRemoved(args)
	self:CustomIcon(eraseMarker, args.destName)
end

function mod:ArcanePunishment(args)
	if not self:Tank() or args.time - prevPunishment < 2 then return end
	prevPunishment = args.time
	local amount = args.amount or 1
	if amount >= 4 then
		self:StackMessage(317155, self:Me(args.destGUID) and "blue" or "purple", args.destName, amount, 4)
		if self:Me(args.destGUID) then
			self:PlaySound(317155, "alarm")
		elseif not UnitIsDeadOrGhost("player") and not self:UnitDebuff("player", 317155) then
			self:PlaySound(317155, "warning") -- DBM: taunt
		end
	end
	self:Bar(317155, 30, CL.other:format(args.spellName, CL.active))
end

function mod:ShieldRemoved(args)
	if self:Interrupter() then
		self:Message(312214, "red", CL.removed:format(args.spellName))
		self:PlaySound(312214, "alert") -- DBM: interrupt the Return now
	end
end

function mod:TimelessWhirlwinds(args)
	if self:Me(args.destGUID) then
		self:PersonalMessage(317165, "underyou")
		self:PlaySound(317165, "underyou")
	end
end

function mod:UNIT_HEALTH(_, unit)
	if not warnedSoon and self:Difficulty() == 6 and self:MobId(self:UnitGUID(unit)) == 50609 and self:GetHealth(unit) <= 53 then
		warnedSoon = true
		self:Message("stages", "cyan", L.replica_soon, false)
		self:PlaySound("stages", "info")
	end
end
