--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-BWL/Chromaggus.lua)
-- DBM counts your Brood Afflictions only when the affliction is the first one in the raid for 3s and lowers the
-- count on Frenzy instead of the red affliction: here every affliction on you counts. Not ported: the detection of
-- the vulnerable school by spell damage (off by default in DBM) and its info frame.

local mod, CL = BigWigs:NewBoss("Chromaggus", 469, 1535)
if not mod then return end
mod:RegisterEnableMob(14020)
mod:SetEncounterID(616)

--------------------------------------------------------------------------------
-- Locals
--

local breathCount = 0
local myAfflictions = 0
local warnedSoon = false
local afflictionMine = {}

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	breath = "Breath",
	breath_desc = "Show warning, cast and CD timers when Chromaggus casts one of his Breaths",
	breath_icon = 23316,
	breath1 = "First Breath",
	breath2 = "Second Breath",
	breath_cd = "%s CD",

	vulnerability = "Vulnerability",
	vulnerability_desc = "Show Vulnerability CD",
	vulnerability_icon = 22277,
	vulnerability_trigger = "%s flinches as its skin shimmers.",
	vulnerability_cd = "Vulnerability CD",
})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"breath",
		"vulnerability",
		23128, -- Frenzy
		"stages",
		23174, -- Chromatic Mutation
		23170, -- Brood Affliction: Bronze
		{23155, "OFF"}, -- Brood Affliction: Red
		{23169, "OFF"}, -- Brood Affliction: Green
		{23153, "OFF"}, -- Brood Affliction: Blue
		{23154, "OFF"}, -- Brood Affliction: Black
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "Breath", 23309, 23313, 23189, 23315, 23312)
	self:Log("SPELL_AURA_APPLIED", "Affliction", 23155, 23169, 23153, 23154, 23170)
	self:Log("SPELL_AURA_REMOVED", "AfflictionRemoved", 23155, 23169, 23153, 23154, 23170)
	self:Log("SPELL_AURA_APPLIED", "Frenzy", 23128)
	self:Log("SPELL_AURA_REMOVED", "FrenzyRemoved", 23128)
	self:Log("SPELL_AURA_APPLIED", "Stage2Frenzy", 23537)
	self:RegisterEvent("CHAT_MSG_MONSTER_EMOTE")
	self:RegisterEvent("UNIT_HEALTH")
end

function mod:OnEngage()
	self:SetStage(1)
	breathCount = 0
	myAfflictions = 0
	warnedSoon = false
	afflictionMine = {}
	self:Bar("breath", 30, L.breath1, L.breath_icon)
	self:Bar("breath", 60, L.breath2, L.breath_icon)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:Breath(args)
	breathCount = breathCount + 1
	if breathCount == 1 then
		self:StopBar(L.breath1)
	elseif breathCount == 2 then
		self:StopBar(L.breath2)
	end
	self:Message("breath", "orange", args.spellName, args.spellId)
	self:PlaySound("breath", "alert")
	self:CastBar("breath", 2, args.spellName, args.spellId)
	self:Bar("breath", 60, L.breath_cd:format(args.spellName), args.spellId)
end

do
	local prev = {}
	function mod:Affliction(args)
		local id = args.spellId
		if id ~= 23170 and args.time - (prev[id] or 0) > 3 then
			prev[id] = args.time
			self:Message(id, "yellow")
		end
		if self:Me(args.destGUID) then
			if id == 23170 then
				self:PersonalMessage(23170)
				self:PlaySound(23170, "warning") -- DBM: use the Hourglass Sand
			end
			if not afflictionMine[id] then
				afflictionMine[id] = true
				myAfflictions = myAfflictions + 1
				if myAfflictions >= 3 then
					self:Message(23174, "red", CL.count_amount:format(self:SpellName(23174), myAfflictions, 5))
					self:PlaySound(23174, "alarm")
				end
			end
		end
	end
end

function mod:AfflictionRemoved(args)
	if self:Me(args.destGUID) and afflictionMine[args.spellId] then
		afflictionMine[args.spellId] = nil
		myAfflictions = myAfflictions - 1
	end
end

function mod:Frenzy(args)
	if not self:Player(args.destFlags) then
		self:Message(23128, "orange", CL.onboss:format(args.spellName))
		if self:Dispeller("enrage", true) then
			self:PlaySound(23128, "alarm") -- DBM: dispel the enrage
		end
		self:Bar(23128, 8)
	end
end

function mod:FrenzyRemoved(args)
	if not self:Player(args.destFlags) then
		self:StopBar(23128)
	end
end

function mod:Stage2Frenzy(args)
	if not self:Player(args.destFlags) and self:GetStage() < 2 then
		self:SetStage(2)
		self:Message("stages", "cyan", CL.stage:format(2), false)
		self:PlaySound("stages", "long")
	end
end

function mod:CHAT_MSG_MONSTER_EMOTE(_, msg)
	if msg:find(L.vulnerability_trigger, nil, true) and self:IsEngaged() then
		self:Bar("vulnerability", 17, L.vulnerability_cd, L.vulnerability_icon)
	end
end

function mod:UNIT_HEALTH(_, unit)
	if not warnedSoon and self:IsEngaged() and self:GetStage() == 1 and self:MobId(self:UnitGUID(unit)) == 14020
		and self:GetHealth(unit) <= 25 then
		warnedSoon = true
		self:Message("stages", "cyan", CL.soon:format(CL.stage:format(2)), false)
	end
end
