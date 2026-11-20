--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Hyjal/Archimonde.lua, Sirus version with custom spells), draft by tools/dbm2bw
-- Not ported: nameplate icons, the voice of the stages.

local mod, CL = BigWigs:NewBoss("Archimonde", 534, 1581)
if not mod then return end
mod:RegisterEnableMob(17968)
mod:SetEncounterID(622)

--------------------------------------------------------------------------------
-- Locals
--

local legionIcon, soulIcon = 8, 5
local doomCount = 0
local soulTargets, harassTargets = {}, {}

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	run_to_water = "Беги в воду!", -- DBM: no English text
})

--------------------------------------------------------------------------------
-- Initialization
--

local legionMarker = mod:AddMarkerOption(true, "player", 8, 319907, 8, 7)
local soulMarker = mod:AddMarkerOption(true, "player", 5, 319917, 5, 4, 3, 2, 1)
function mod:GetOptions()
	return {
		"stages",
		"berserk",
		{319906, "TANK"}, -- Finger
		{319907, "SAY"}, -- Mark of the Legion
		legionMarker,
		319910, -- Flame of Doom
		319931, -- Harassment
		319917, -- Soul Abduction
		soulMarker,
		319922, -- Shadow Geyser
		319915, -- adds
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "Finger", 319906)
	self:Log("SPELL_CAST_START", "FlameOfDoom", 319910)
	self:Log("SPELL_CAST_START", "SoulAbductionCast", 319917)
	self:Log("SPELL_CAST_START", "ShadowGeyser", 319922)
	self:Log("SPELL_CAST_START", "Stage2Cast", 319920)
	self:Log("SPELL_AURA_APPLIED", "MarkOfTheLegion", 319907)
	self:Log("SPELL_AURA_REMOVED", "MarkOfTheLegionRemoved", 319907)
	self:Log("SPELL_AURA_APPLIED", "SoulAbduction", 319917)
	self:Log("SPELL_AURA_REMOVED", "SoulAbductionRemoved", 319917)
	self:Log("SPELL_AURA_APPLIED", "Harassment", 319931)
	self:RegisterEvent("UNIT_HEALTH")
end

function mod:OnEngage()
	self:SetStage(1)
	legionIcon, soulIcon = 8, 5
	doomCount = 0
	soulTargets, harassTargets = {}, {}
	self:Bar(319906, 16)
	self:CDBar(319907, 22)
	self:Bar(319915, 22)
	self:ScheduleTimer("Bar", 22, 319915, 70)
	self:CDBar(319910, 40, CL.count:format(self:SpellName(319910), 1))
	self:Bar("stages", 120, CL.stage:format(2), "achievement_bg_returnxflags_def_wsg")
	self:Berserk(600)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:Finger()
	self:Bar(319906, 8)
end

function mod:FlameOfDoom(args)
	doomCount = doomCount + 1
	self:CDBar(319910, 40, CL.count:format(args.spellName, doomCount + 1))
	self:ScheduleTimer("Bar", 2, 319931, 20)
end

function mod:SoulAbductionCast()
	self:CDBar(319917, 40)
end

function mod:ShadowGeyser(args)
	self:Message(319922, "red")
	self:PlaySound(319922, "alarm")
	self:CDBar(319922, 20)
	self:ScheduleTimer("Bar", 1, 319922, 6, CL.explosion)
end

local function stage2(self)
	if self:GetStage() ~= 1 then return end
	self:SetStage(2)
	self:StopBar(CL.count:format(self:SpellName(319910), doomCount + 1))
	self:Message("stages", "cyan", CL.stage:format(2), false)
	self:PlaySound("stages", "long")
end

function mod:Stage2Cast()
	stage2(self)
end

function mod:UNIT_HEALTH(_, unit)
	if not self:IsEngaged() or self:MobId(self:UnitGUID(unit)) ~= 17968 then return end
	local hp = self:GetHealth(unit)
	if hp < 67 then stage2(self) end
	if hp < 50 and self:GetStage() == 2 then
		self:SetStage(3)
		self:CDBar(319922, 20)
		self:Bar(319915, 120)
		self:Message("stages", "cyan", CL.stage:format(3), false)
		self:PlaySound("stages", "long")
	end
end

function mod:MarkOfTheLegion(args)
	self:TargetBar(319907, 10, args.destName)
	self:TargetMessage(319907, "orange", args.destName)
	if self:Me(args.destGUID) then
		self:PlaySound(319907, "warning")
		self:Say(319907)
	end
	self:CustomIcon(legionMarker, args.destName, legionIcon)
	legionIcon = legionIcon - 1
	if legionIcon < 7 then legionIcon = 8 end
end

function mod:MarkOfTheLegionRemoved(args)
	self:CDBar(319907, 22)
	self:CustomIcon(legionMarker, args.destName)
end

function mod:AnnounceSouls()
	self:TargetsMessage(319917, "yellow", soulTargets, #soulTargets)
	soulTargets = {}
end

function mod:SoulAbduction(args)
	soulTargets[#soulTargets + 1] = args.destName
	self:CancelTimer(self.soulTimer)
	self.soulTimer = self:ScheduleTimer("AnnounceSouls", 0.1)
	if self:Me(args.destGUID) then
		self:Message(319917, "blue", L.run_to_water)
		self:PlaySound(319917, "alarm")
	end
	self:CustomIcon(soulMarker, args.destName, soulIcon)
	soulIcon = soulIcon - 1
	if soulIcon < 1 then soulIcon = 5 end
end

function mod:SoulAbductionRemoved(args)
	self:CustomIcon(soulMarker, args.destName)
end

function mod:AnnounceHarassment()
	self:TargetsMessage(319931, "orange", harassTargets, #harassTargets)
	harassTargets = {}
end

function mod:Harassment(args)
	harassTargets[#harassTargets + 1] = args.destName
	self:CancelTimer(self.harassTimer)
	self.harassTimer = self:ScheduleTimer("AnnounceHarassment", 0.1)
	if self:Me(args.destGUID) then
		self:PlaySound(319931, "runaway")
		self:Say(319931)
	end
end
