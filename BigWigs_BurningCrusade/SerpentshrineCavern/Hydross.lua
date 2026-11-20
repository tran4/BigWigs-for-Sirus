--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Serpentshrine/Hydross.lua, heroic mode with custom spells), draft by tools/dbm2bw
-- Most texts of the Sirus version are only in the Russian DBM localization: the English defaults are the Russian texts.
-- Not ported: announcing the targets to the raid chat, nameplate icons.

local mod, CL = BigWigs:NewBoss("Hydross the Unstable", 548, 1567)
if not mod then return end
mod:RegisterEnableMob(21216)
mod:SetEncounterID(623)

--------------------------------------------------------------------------------
-- Locals
--

local markHydross = {[38215] = {10, 25}, [38216] = {25, 50}, [38217] = {50, 100}, [38218] = {100, 250}, [38231] = {250, 500}, [40584] = {500, 500}}
local markCorruption = {[38219] = {10, 25}, [38220] = {25, 50}, [38221] = {50, 100}, [38222] = {100, 250}, [38230] = {250, 500}, [40583] = {500, 500}}
local tombTargets, corrosionTargets = {}, {}
local tombIcon, corrosionIcon = 8, 8

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	-- DBM: no English texts
	engage_trigger = "Я не позволю вам вмешиваться!",
	poison_trigger = "Агрррхх, яд.",
	water_trigger = "Так лучше, намного лучше.",

	threat = "Сброс угрозы",
	threat_desc = "Спец. предупреждение о сбрасывании угрозы",
	threat_icon = "ability_hunter_misdirection",
	threat_msg = "Сброс угрозы - АСТАНАВИТЕСЬ!!!!",
	poison_phase = "ГРЯЗНАЯ ФАЗА, БЕГИТЕ В ЛУЖУ",
	clean_phase = "Чистая фаза",
	tank_dispel = "Диспел танка: %s",
})

--------------------------------------------------------------------------------
-- Initialization
--

local tombMarker = mod:AddMarkerOption(true, "player", 8, 309046, 8, 7, 6)
local corrosionMarker = mod:AddMarkerOption(true, "player", 8, 309065, 8, 7, 6)
function mod:GetOptions()
	return {
		"berserk",
		38215, -- Mark of Hydross
		38219, -- Mark of Corruption
		"threat",
		38235, -- Water Tomb
		38246, -- Vile Sludge
		-- heroic
		309052, -- Water volley
		309069, -- Poison volley
		309072, -- Poison phase
		309055, -- Clean phase
		{309046, "SAY"}, -- Tomb
		tombMarker,
		{309065, "SAY"}, -- Corrosion
		corrosionMarker,
		{309068, "TANK_HEALER"},
		{309051, "TANK_HEALER"},
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_SUCCESS", "MarkOfHydross", 38215, 38216, 38217, 38218, 38231, 40584)
	self:Log("SPELL_CAST_SUCCESS", "MarkOfCorruption", 38219, 38220, 38221, 38222, 38230, 40583)
	self:Log("SPELL_CAST_SUCCESS", "WaterTomb", 38235)
	self:Log("SPELL_CAST_SUCCESS", "VileSludge", 38246)
	self:Log("SPELL_CAST_SUCCESS", "CleanPhase", 309055)
	self:Log("SPELL_CAST_START", "WaterVolley", 309052)
	self:Log("SPELL_CAST_START", "PoisonVolley", 309069)
	self:Log("SPELL_CAST_START", "PoisonPhase", 309072)
	self:Log("SPELL_AURA_APPLIED", "Tomb", 309046)
	self:Log("SPELL_AURA_APPLIED_DOSE", "Tomb", 309046)
	self:Log("SPELL_AURA_REMOVED", "TombRemoved", 309046)
	self:Log("SPELL_AURA_APPLIED", "Corrosion", 309065)
	self:Log("SPELL_AURA_APPLIED_DOSE", "Corrosion", 309065)
	self:Log("SPELL_AURA_REMOVED", "CorrosionRemoved", 309065)
	self:Log("SPELL_AURA_APPLIED", "TankDebuff", 309068, 309051)
	self:Log("SPELL_AURA_APPLIED_DOSE", "TankDebuff", 309068, 309051)
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
end

function mod:OnEngage()
	self:SetStage(1)
	tombTargets, corrosionTargets = {}, {}
	tombIcon, corrosionIcon = 8, 8
	self:Berserk(600)
	if self:Difficulty() == 6 then -- 25 heroic
		self:CDBar(309052, 25)
		self:CDBar(309046, 32)
	else
		self:Bar(38215, 15, CL.other:format(self:SpellName(38215), "10%"))
	end
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if msg:find(L.engage_trigger, nil, true) then
		if not self:IsEngaged() then self:Engage() end -- DBM RegisterCombat("yell")
	elseif self:Difficulty() ~= 6 and self:IsEngaged() then
		if msg == L.poison_trigger then
			self:StopBar(CL.other:format(self:SpellName(38215), "10%"))
			self:Bar(38219, 15, CL.other:format(self:SpellName(38219), "10%"))
			self:ThreatReset()
		elseif msg == L.water_trigger then
			self:StopBar(CL.other:format(self:SpellName(38219), "10%"))
			self:Bar(38215, 15, CL.other:format(self:SpellName(38215), "10%"))
			self:ThreatReset()
		end
	end
end

function mod:ThreatReset()
	if not self:Tank() and not self:Healer() then -- DBM: "-Tank|-Healer"
		self:Message("threat", "red", L.threat_msg, L.threat_icon)
		self:PlaySound("threat", "alarm")
	end
end

function mod:MarkOfHydross(args)
	local m = markHydross[args.spellId]
	self:Message(38215, "orange", CL.other:format(args.spellName, m[1] .. "%"))
	self:Bar(38215, 15, CL.other:format(args.spellName, m[2] .. "%"))
end

function mod:MarkOfCorruption(args)
	local m = markCorruption[args.spellId]
	self:Message(38219, "green", CL.other:format(args.spellName, m[1] .. "%"))
	self:Bar(38219, 15, CL.other:format(args.spellName, m[2] .. "%"))
end

function mod:WaterTomb(args)
	self:TargetMessage(38235, "yellow", args.destName)
end

function mod:VileSludge(args)
	self:TargetMessage(38246, "yellow", args.destName)
end

function mod:WaterVolley(args)
	self:Message(309052, "orange")
	self:PlaySound(309052, "alarm")
	self:CDBar(309052, 25)
	self:CastBar(309052, 1.5)
end

function mod:PoisonVolley(args)
	self:Message(309069, "orange")
	self:PlaySound(309069, "alarm")
	self:CDBar(309069, 25)
	self:CastBar(309069, 1.5)
end

function mod:PoisonPhase(args)
	self:SetStage(2)
	self:Message(309072, "red", L.poison_phase)
	self:PlaySound(309072, "long")
	self:CastBar(309072, 25)
	self:CDBar(309065, 52)
	self:CDBar(309069, 25)
	self:StopBar(309052)
	self:StopBar(309046)
end

function mod:CleanPhase(args)
	self:SetStage(1)
	self:Message(309055, "green", L.clean_phase)
	self:PlaySound(309055, "long")
	self:CastBar(309055, 20)
	self:StopBar(309065)
	self:StopBar(309069)
	self:CDBar(309052, 25)
	self:CDBar(309046, 32)
end

-- the targets come in threes: icons 8, 7, 6 and one message (DBM)
local function newTarget(self, key, marker, targets, icon, args)
	targets[#targets + 1] = args.destName
	self:CustomIcon(marker, args.destName, icon)
	if self:Me(args.destGUID) then
		self:PersonalMessage(key)
		self:PlaySound(key, "runaway")
		self:Say(key)
	end
	self:CDBar(key, 32)
	if #targets >= 3 then
		self:TargetsMessage(key, "red", targets, #targets)
		return {}, 8
	end
	return targets, icon - 1
end

function mod:Tomb(args)
	tombTargets, tombIcon = newTarget(self, 309046, tombMarker, tombTargets, tombIcon, args)
end

function mod:TombRemoved(args)
	self:CustomIcon(tombMarker, args.destName)
end

function mod:Corrosion(args)
	corrosionTargets, corrosionIcon = newTarget(self, 309065, corrosionMarker, corrosionTargets, corrosionIcon, args)
end

function mod:CorrosionRemoved(args)
	self:CustomIcon(corrosionMarker, args.destName)
end

function mod:TankDebuff(args)
	self:TargetBar(args.spellId, 30, args.destName, L.tank_dispel:format(args.destName))
end
