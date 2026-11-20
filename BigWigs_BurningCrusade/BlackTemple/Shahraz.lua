--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-BlackTemple/Shahraz.lua), draft by tools/dbm2bw
-- The Prismatic Auras are only seen as UNIT_SPELLCAST_SUCCEEDED (DBM), on 3.3.5 compared by the spell name.

local mod, CL = BigWigs:NewBoss("Mother Shahraz", 564, 1588)
if not mod then return end
mod:RegisterEnableMob(22947)
mod:SetEncounterID(607)

--------------------------------------------------------------------------------
-- Locals
--

local warnedEnrage, enraged = false, false
local prevCast = {}
local auras = {40880, 40882, 40883, 40891, 40896, 40897}

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	bossName = "Mother Shahraz",

	aura = "Prismatic Aura",
	aura_desc = "Show timer for Prismatic Aura",
	aura_icon = 22599,
})

--------------------------------------------------------------------------------
-- Initialization
--

local attractionMarker = mod:AddMarkerOption(true, "player", 1, 41001, 1, 2, 3)
function mod:GetOptions()
	return {
		41001, -- Fatal Attraction
		attractionMarker,
		40823, -- Silencing Shriek
		21340, -- Enrage
		"aura",
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "FatalAttraction", 41001)
	self:Log("SPELL_AURA_REMOVED", "FatalAttractionRemoved", 41001)
	self:Log("SPELL_CAST_SUCCESS", "SilencingShriek", 40823)
	self:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE") -- 3.3.5: DBM RAID_BOSS_EMOTE
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	self:RegisterUnitEvent("UNIT_HEALTH", nil, "boss1")
end

function mod:OnEngage()
	warnedEnrage, enraged = false, false
	prevCast = {}
	self:CDBar(40823, 15.8)
	self:CDBar(41001, 24.4)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

do
	local playerList = {}
	local prev = 0
	function mod:FatalAttraction(args)
		if args.time - prev > 2 then
			prev = args.time
			playerList = {}
		end
		playerList[#playerList + 1] = args.destName
		self:TargetsMessage(41001, "red", playerList, nil, nil, nil, 1)
		self:CustomIcon(attractionMarker, args.destName, #playerList)
		if self:Me(args.destGUID) then
			self:PlaySound(41001, "runaway")
		end
	end
end

function mod:FatalAttractionRemoved(args)
	self:CustomIcon(attractionMarker, args.destName)
end

function mod:SilencingShriek(args)
	self:Message(40823, "orange")
	self:CDBar(40823, 15.8)
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(_, _, source)
	if not enraged and self:IsEngaged() and source == L.bossName then
		enraged = true
		self:Message(21340, "red")
		self:PlaySound(21340, "long")
	end
end

function mod:UNIT_HEALTH(_, unit)
	if not warnedEnrage and self:MobId(self:UnitGUID(unit)) == 22947 and self:GetHealth(unit) <= 23 then
		warnedEnrage = true
		self:Message(21340, "orange", CL.soon:format(self:SpellName(21340)))
	end
end

function mod:UNIT_SPELLCAST_SUCCEEDED(_, unit, _, _, spellName)
	if not spellName or GetTime() - (prevCast[spellName] or 0) < 3 then return end
	for i = 1, #auras do
		if spellName == self:SpellName(auras[i]) then
			prevCast[spellName] = GetTime()
			self:Bar("aura", 15, spellName, L.aura_icon)
			return
		end
	end
	if spellName == self:SpellName(40869) then -- DBM: not in the combat log, the timer always exists this way
		prevCast[spellName] = GetTime()
		self:CDBar(41001, 20.7)
	end
end
