--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Hyjal/Azgalor.lua, Sirus version with custom spells), draft by tools/dbm2bw
-- DBM has only Russian texts here: the English defaults are the Russian texts. Not ported: nameplate icons.

local mod, CL = BigWigs:NewBoss("Azgalor", 534, 1580)
if not mod then return end
mod:RegisterEnableMob(17842)
mod:SetEncounterID(621)

--------------------------------------------------------------------------------
-- Locals
--

local totemCount, markCount, totemKills = 0, 0, 0
local flameIcon = 3

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	-- DBM: no English texts
	flame = "Пламя",
	downpour_msg = "%s - к Тотему!",
	cover_msg = "Покров Охраны на тотеме!",
	mark_msg = "Метка Рока - беги к Траллу, чтобы не умереть!",
})

--------------------------------------------------------------------------------
-- Initialization
--

local flameMarker = mod:AddMarkerOption(true, "player", 3, 320374, 3, 2)
local markMarker = mod:AddMarkerOption(true, "player", 8, 319029, 8)
function mod:GetOptions()
	return {
		"stages",
		319021, -- Infernal Downpour
		{320374, "SAY"}, -- Flame of Filth
		flameMarker,
		{319029, "SAY"}, -- Mark of Doom
		markMarker,
		319010, -- Protection Cover
		319006, -- Thrall's totem
		319026, -- Enhanced Glaive of Defilement
		319012, -- Guardian of the Spirit
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "InfernalDownpour", 319021)
	self:Log("SPELL_CAST_START", "MarkCast", 319024)
	self:Log("SPELL_CAST_SUCCESS", "FlameSuccess", 320374)
	self:Log("SPELL_CAST_SUCCESS", "ProtectionCover", 319010)
	self:Log("SPELL_CAST_SUCCESS", "MarkSuccess", 319029)
	self:Log("SPELL_INSTAKILL", "TotemKilled", 319023)
	self:Log("SPELL_AURA_APPLIED", "Flame", 320374)
	self:Log("SPELL_AURA_REMOVED", "FlameRemoved", 320374)
	self:Log("SPELL_AURA_APPLIED", "MarkOfDoom", 319029)
	self:Log("SPELL_AURA_REMOVED", "MarkOfDoomRemoved", 319029)
	self:Log("SPELL_AURA_APPLIED", "ThrallTotem", 319006)
	self:Log("SPELL_AURA_REMOVED", "ThrallTotemRemoved", 319006)
	self:Log("SPELL_AURA_REMOVED", "GlaiveRemoved", 319026)
	self:Log("SPELL_HEAL", "GuardianOfTheSpirit", 319012)
end

function mod:OnEngage()
	self:SetStage(1)
	totemCount, markCount, totemKills = 0, 0, 0
	flameIcon = 3
	self:Bar(319021, 30, CL.count:format(self:SpellName(319021), 1))
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:InfernalDownpour(args)
	totemCount = totemCount + 1
	self:Message(319021, "red", L.downpour_msg:format(args.spellName))
	self:PlaySound(319021, "alarm")
	self:CastBar(319021, 5)
	self:Bar(319021, 40, CL.count:format(args.spellName, totemCount + 1))
end

function mod:MarkCast()
	self:Bar(319029, 30, CL.count:format(self:SpellName(319029), markCount + 1))
end

function mod:FlameSuccess()
	self:Bar(320374, 5, L.flame)
end

function mod:ProtectionCover(args)
	self:Bar(319010, 10)
end

function mod:MarkSuccess(args)
	markCount = markCount + 1
	self:Bar(319029, 40, CL.count:format(args.spellName, markCount + 1))
end

function mod:TotemKilled()
	totemKills = totemKills + 1
	if totemKills == 4 then
		self:SetStage(2)
		self:Message("stages", "cyan", CL.stage:format(2), false)
		self:PlaySound("stages", "long")
		self:StopBar(CL.count:format(self:SpellName(319021), totemCount + 1))
	end
end

function mod:Flame(args)
	self:TargetMessage(320374, "orange", args.destName)
	if self:Me(args.destGUID) then
		self:PlaySound(320374, "warning")
		self:Say(320374, L.flame)
		self:Bar(320374, 10, CL.you:format(args.spellName))
	end
	self:CustomIcon(flameMarker, args.destName, flameIcon)
	self:ScheduleTimer("CustomIcon", 10, flameMarker, args.destName)
	flameIcon = flameIcon - 1
	if flameIcon < 2 then flameIcon = 3 end
end

function mod:FlameRemoved(args)
	self:CustomIcon(flameMarker, args.destName)
end

function mod:MarkOfDoom(args)
	self:CustomIcon(markMarker, args.destName, 8)
	self:TargetMessage(319029, "red", args.destName)
	self:TargetBar(319029, 30, args.destName)
	if self:Me(args.destGUID) then
		self:Message(319029, "blue", L.mark_msg)
		self:PlaySound(319029, "warning")
		self:Say(319029)
	end
end

function mod:MarkOfDoomRemoved(args)
	self:CustomIcon(markMarker, args.destName)
	if markCount == 1 then -- DBM: MarkCount == (1 or 3 or 5 or 7 or 9), that is 1
		self:TargetBar(319012, 60, args.destName)
	end
end

function mod:ThrallTotem(args)
	self:Message(319006, "green", L.cover_msg)
	self:PlaySound(319006, "info")
end

function mod:ThrallTotemRemoved(args)
	self:Message(319006, "green", L.cover_msg)
end

function mod:GlaiveRemoved()
	self:Bar(319026, 10)
end

function mod:GuardianOfTheSpirit(args)
	self:TargetBar(319012, 60, args.destName)
end
