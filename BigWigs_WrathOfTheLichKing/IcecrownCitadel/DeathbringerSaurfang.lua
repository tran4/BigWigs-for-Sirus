--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Icecrown/TheLowerSpire/Deathbringer.lua), draft by tools/dbm2bw
-- Not ported (DBM automation): Blood Power frame, removing Divine Intervention / Hand of Protection.

local mod, CL = BigWigs:NewBoss("Deathbringer Saurfang", 631, 1628)
if not mod then return end
mod:RegisterEnableMob(37813)
mod:SetEncounterID(848)

--------------------------------------------------------------------------------
-- Locals
--

local markCount = 0
local boilingBloodList = {}
local boilingBloodIcon = 1
local prevBoilingBlood = 0
local prevBeasts = 0
local beastIcon = 8
local beastsToMark = {} -- [guid] = true
local frenzyWarned = false

local function is25(self) -- 25 player raid (normal or heroic)
	local diff = self:Difficulty()
	return diff == 4 or diff == 6
end

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	warmup_trigger_alliance = "For every Horde soldier that you killed -- for every Alliance dog that fell, the Lich King's armies grew. Even now the val'kyr work to raise your fallen as Scourge.",
	warmup_trigger_horde = "Kor'kron, move out! Champions, watch your backs. The Scourge have been...",
})
mod:SetChatEnableTriggers(L.warmup_trigger_alliance, L.warmup_trigger_horde) -- 3.3.5: enable the module on the warmup yell/emote (no target yet)

--------------------------------------------------------------------------------
-- Initialization
--

local boilingBloodMarker = mod:AddMarkerOption(false, "player", 1, 72385, 1, 2, 3)
local beastMarker = mod:AddMarkerOption(true, "npc", 8, 72173, 8, 7, 6, 5, 4)
function mod:GetOptions()
	return {
		"warmup",
		"berserk",
		{72378, "PROXIMITY"}, -- Blood Nova
		72293, -- Mark of the Fallen Champion
		{72385, "HEALER"}, -- Boiling Blood
		boilingBloodMarker,
		{72410, "TANK_HEALER"}, -- Rune of Blood
		{72737, "TANK_HEALER"}, -- Frenzy
		72173, -- Call Blood Beast
		beastMarker,
	}, {
		[72173] = CL.adds,
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "BloodNova", 73058, 72378)
	self:Log("SPELL_AURA_APPLIED", "MarkOfTheFallenChampion", 72293)
	self:Log("SPELL_AURA_APPLIED", "BoilingBlood", 72385, 72441, 72442, 72443)
	self:Log("SPELL_AURA_REMOVED", "BoilingBloodRemoved", 72385, 72441, 72442, 72443)
	self:Log("SPELL_CAST_SUCCESS", "RuneOfBlood", 72410)
	self:Log("SPELL_AURA_APPLIED", "Frenzy", 72737)
	self:Log("SPELL_SUMMON", "CallBloodBeast", 72172, 72173, 72356, 72357, 72358)
	self:RegisterUnitEvent("UNIT_HEALTH", nil, "boss1")
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
end

function mod:OnEngage()
	markCount = 0
	boilingBloodList = {}
	boilingBloodIcon = 1
	beastsToMark = {}
	frenzyWarned = false
	self:StopBar(CL.active)
	self:Berserk(self:Normal() and 480 or 360)
	local beasts = BigWigsLoader.Compat.GetRealmNumber() == 4 and 30 or 40 -- 30s on the x4 realm (DBM Sirus)
	self:Bar(72173, beasts)
	self:DelayedMessage(72173, beasts - 10, "orange", CL.soon:format(self:SpellName(72173)))
	self:Bar(72378, 20)
	self:Bar(72410, 19.5)
	self:Bar(72385, 19)
	self:OpenProximity(72378, 12)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if msg:find(L.warmup_trigger_alliance, nil, true) then
		self:Bar("warmup", 42.3, CL.active, "inv_misc_pocketwatch_01")
	elseif msg:find(L.warmup_trigger_horde, nil, true) then
		self:Bar("warmup", 79.5, CL.active, "inv_misc_pocketwatch_01")
	end
end

function mod:BloodNova(args)
	self:Message(72378, "yellow")
	self:Bar(72378, 20)
end

function mod:MarkOfTheFallenChampion(args)
	markCount = markCount + 1
	self:TargetMessage(72293, "red", args.destName, CL.count:format(args.spellName, markCount))
	self:PlaySound(72293, "alarm")
end

function mod:BoilingBlood(args)
	if args.time - prevBoilingBlood > 3 then
		boilingBloodList = {}
		boilingBloodIcon = 1
		self:Bar(72385, 15.5)
	end
	prevBoilingBlood = args.time
	boilingBloodList[#boilingBloodList + 1] = args.destName
	self:TargetsMessage(72385, "orange", boilingBloodList, is25(self) and 3 or 1, nil, nil, 0.5)
	self:CustomIcon(boilingBloodMarker, args.destName, boilingBloodIcon)
	boilingBloodIcon = boilingBloodIcon + 1
end

function mod:BoilingBloodRemoved(args)
	self:CustomIcon(boilingBloodMarker, args.destName)
end

function mod:RuneOfBlood(args)
	self:TargetMessage(72410, "purple", args.destName)
	if self:Me(args.destGUID) then
		self:PlaySound(72410, "alarm")
	elseif self:Tank() then
		self:PlaySound(72410, "warning") -- taunt
	end
	self:Bar(72410, 20)
end

function mod:Frenzy(args)
	self:Message(72737, "orange")
end

function mod:UNIT_HEALTH(event, unit)
	if not frenzyWarned and self:MobId(self:UnitGUID(unit)) == 37813 and self:GetHealth(unit) <= 33 then
		frenzyWarned = true
		self:UnregisterUnitEvent(event, unit)
		self:Message(72737, "orange", CL.soon:format(self:SpellName(72737)))
	end
end

-- Blood Beasts

function mod:MarkBeasts(_, unit, guid)
	if beastsToMark[guid] then
		beastsToMark[guid] = nil
		self:CustomIcon(beastMarker, unit, beastIcon)
		beastIcon = beastIcon - 1
		if not next(beastsToMark) then
			self:UnregisterTargetEvents()
		end
	end
end

function mod:CallBloodBeast(args)
	if args.time - prevBeasts > 5 then
		prevBeasts = args.time
		beastIcon = 8
		beastsToMark = {}
		self:Message(72173, "red")
		self:PlaySound(72173, "alert")
		self:Bar(72173, 40)
		self:DelayedMessage(72173, 30, "orange", CL.soon:format(self:SpellName(72173)))
	end
	if self:GetOption(beastMarker) and args.destGUID then
		beastsToMark[args.destGUID] = true
		self:RegisterTargetEvents("MarkBeasts")
	end
end
