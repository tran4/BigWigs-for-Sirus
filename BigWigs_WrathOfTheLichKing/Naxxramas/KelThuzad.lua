--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Naxx/FrostwyrmLair/Kel'Thuzad.lua), draft by tools/dbm2bw
-- Kel'Thuzad sits on his throne in phase 1 (adds only): engaged by his yell (DBM RegisterCombat("combat_yell")).
-- Not ported: automatic unequipping/equipping of weapons for Chains of Kel'Thuzad.

local mod, CL = BigWigs:NewBoss("Kel'Thuzad", 533, 1615)
if not mod then return end
mod:RegisterEnableMob(15990)
mod:SetEncounterID(1114)

--------------------------------------------------------------------------------
-- Locals
--

local warnedAdds = false
local mcIcon = 1
local prevChains = 0
local frostBlastTargets = {}
local chainsTargets = {}

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	engage_trigger = "Minions, servants, soldiers of the cold dark! Obey the call of Kel'Thuzad!",

	stage2_soon = "Kel'Thuzad engages in 10 Seconds",
	adds_soon = "Guardians of Icecrown incoming soon",
})

--------------------------------------------------------------------------------
-- Initialization
--

local chainsMarker = mod:AddMarkerOption(true, "player", 1, 28410, 1, 2, 3)
local manaBombMarker = mod:AddMarkerOption(false, "player", 8, 27819, 8)
local frostBlastMarker = mod:AddMarkerOption(true, "player", 8, 27808, 8, 7, 6, 5, 4, 3, 2, 1)
function mod:GetOptions()
	return {
		"stages",
		"adds",
		{27810, "SAY"}, -- Shadow Fissure
		28410, -- Chains of Kel'Thuzad
		chainsMarker,
		{27819, "SAY"}, -- Detonate Mana
		manaBombMarker,
		27808, -- Frost Blast
		frostBlastMarker,
		"proximity",
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_SUCCESS", "ShadowFissure", 27810)
	self:Log("SPELL_CAST_SUCCESS", "ChainsSuccess", 28410)
	self:Log("SPELL_CAST_SUCCESS", "DetonateManaSuccess", 27819)
	self:Log("SPELL_CAST_SUCCESS", "FrostBlastSuccess", 27808)
	self:Log("SPELL_AURA_APPLIED", "FrostBlast", 27808)
	self:Log("SPELL_AURA_APPLIED", "DetonateMana", 27819)
	self:Log("SPELL_AURA_APPLIED", "Chains", 28410)
	self:Log("SPELL_AURA_REMOVED", "ChainsRemoved", 28410)
	self:RegisterUnitEvent("UNIT_HEALTH", nil, "boss1")
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
end

function mod:OnEngage()
	self:SetStage(1)
	warnedAdds = false
	mcIcon = 1
	prevChains = 0
	frostBlastTargets = {}
	chainsTargets = {}
	self:DelayedMessage("stages", 217, "orange", L.stage2_soon, "achievement_bg_returnxflags_def_wsg", "alarm")
	self:Bar("stages", 227, CL.stage:format(2), "achievement_bg_returnxflags_def_wsg")
	self:ScheduleTimer("StartStage2", 226)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if msg == L.engage_trigger and not self:IsEngaged() then
		self:Engage() -- DBM RegisterCombat("combat_yell")
	end
end

function mod:StartStage2()
	if self:GetStage() ~= 1 then return end
	self:SetStage(2)
	self:Message("stages", "cyan", CL.stage:format(2), "achievement_bg_returnxflags_def_wsg")
	self:PlaySound("stages", "long")
	if self:Difficulty() == 4 then -- 25 player
		self:CDBar(28410, 61)
		self:DelayedMessage(28410, 56, "yellow", CL.soon:format(self:SpellName(28410)))
	end
	self:OpenProximity("proximity", 12)
end

local function isNear(self, guid, range)
	local unit = self:UnitTokenFromGUID(guid)
	return unit and self:UnitWithinRange(unit, range)
end

function mod:ShadowFissure(args)
	self:TargetBar(27810, 5, args.destName)
	self:CDBar(27810, 14)
	if self:Me(args.destGUID) then
		self:PersonalMessage(27810)
		self:PlaySound(27810, "warning")
		self:Say(27810)
	elseif isNear(self, args.destGUID, 8) then
		self:Message(27810, "orange", CL.near:format(args.spellName))
		self:PlaySound(27810, "alarm")
	else
		self:TargetMessage(27810, "orange", args.destName)
	end
end

function mod:ChainsSuccess(args)
	self:CDBar(28410, 90)
end

function mod:DetonateManaSuccess(args)
	self:CDBar(27819, 20)
end

function mod:FrostBlastSuccess(args)
	self:CDBar(27808, 30)
end

function mod:AnnounceFrostBlast()
	self:TargetsMessage(27808, "red", frostBlastTargets, #frostBlastTargets)
	if self:Healer() then
		self:PlaySound(27808, "alert")
	end
	self:CastBar(27808, 3.5)
	for i = #frostBlastTargets, 1, -1 do
		local name = frostBlastTargets[i]
		self:CustomIcon(frostBlastMarker, name, 8 - i)
		self:ScheduleTimer("CustomIcon", 4.5, frostBlastMarker, name)
	end
	frostBlastTargets = {}
end

function mod:FrostBlast(args)
	frostBlastTargets[#frostBlastTargets + 1] = args.destName
	self:CancelTimer(self.blastTimer)
	self.blastTimer = self:ScheduleTimer("AnnounceFrostBlast", 0.5)
end

function mod:DetonateMana(args)
	self:CustomIcon(manaBombMarker, args.destName, 8)
	self:ScheduleTimer("CustomIcon", 5.5, manaBombMarker, args.destName)
	if self:Me(args.destGUID) then
		self:PersonalMessage(27819)
		self:PlaySound(27819, "warning")
		self:Say(27819)
	elseif isNear(self, args.destGUID, 12) then
		self:Message(27819, "orange", CL.near:format(args.spellName))
		self:PlaySound(27819, "alarm")
	else
		self:TargetMessage(27819, "yellow", args.destName)
	end
end

function mod:AnnounceChains()
	self:TargetsMessage(28410, "red", chainsTargets, #chainsTargets)
	chainsTargets = {}
	mcIcon = 1
end

function mod:Chains(args)
	chainsTargets[#chainsTargets + 1] = args.destName
	if args.time - prevChains > 5 then
		prevChains = args.time
		self:CastBar(28410, 20)
		self:CDBar(28410, 90)
		self:DelayedMessage(28410, 60, "yellow", CL.soon:format(args.spellName))
	end
	self:CustomIcon(chainsMarker, args.destName, mcIcon)
	mcIcon = mcIcon + 1
	self:CancelTimer(self.chainsTimer)
	if #chainsTargets >= 3 then
		self:AnnounceChains()
	else
		self.chainsTimer = self:ScheduleTimer("AnnounceChains", 1)
	end
end

function mod:ChainsRemoved(args)
	self:CustomIcon(chainsMarker, args.destName)
end

function mod:UNIT_HEALTH(event, unit)
	if not warnedAdds and self:MobId(self:UnitGUID(unit)) == 15990 and self:GetHealth(unit) <= 48 then
		warnedAdds = true
		self:Message("adds", "yellow", L.adds_soon, "inv_misc_monsterspidercarapace_01")
	end
end
