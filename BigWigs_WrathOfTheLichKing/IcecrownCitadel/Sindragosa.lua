--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Icecrown/FrostwingHalls/Sindragosa.lua), draft by tools/dbm2bw
-- Not ported: Frost Beacon direction assignments, raid chat icon announces, the achievement check.

local mod, CL = BigWigs:NewBoss("Sindragosa", 631, 1635)
if not mod then return end
mod:RegisterEnableMob(36853)
mod:SetEncounterID(855)

--------------------------------------------------------------------------------
-- Locals
--

local beaconList = {}
local beaconIcon = 8
local prevBeacon = 0
local beaconCount = 1
local unchainedList = {}
local unchainedIcon = 7
local prevUnchained = 0
local activeBeacons = false
local stage2Warned = false

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	airphase_trigger = "Your incursion ends here! None shall survive!",
	stage2_trigger = "Now, feel my master's limitless power and despair!",
	-- Demonic, Curse of Tongues breaks the normal yell detection
	airphase_trigger_demonic = "Rikk zilthuras rikk zila Aman adare tiriosh ",
	stage2_trigger_demonic = "Zar kiel xi romathIs zilthuras revos ruk toralar ",

	airphase = "Air phase",
	airphase_desc = "Announce the air phase and show timers for the air and ground phases",
	airphase_icon = 43810,
	next_airphase = "Next air phase",
	next_groundphase = "Next ground phase",
	landing_soon = "Sindragosa landing soon",
})

--------------------------------------------------------------------------------
-- Initialization
--

local beaconMarker = mod:AddMarkerOption(true, "player", 8, 70126, 8, 7, 6, 5, 4, 3)
local unchainedMarker = mod:AddMarkerOption(true, "player", 7, 69762, 7, 6, 5, 4, 3, 2)
function mod:GetOptions()
	return {
		"stages",
		"berserk",
		-- Stage One
		"airphase",
		{69649, "TANK_HEALER"}, -- Frost Breath
		71077, -- Tail Smash
		70123, -- Blistering Cold
		70126, -- Frost Beacon
		beaconMarker,
		69762, -- Unchained Magic
		unchainedMarker,
		{70106, "ME_ONLY"}, -- Chilled to the Bone
		{69766, "ME_ONLY"}, -- Instability
		-- Stage Two
		{70127, "ME_ONLY", "OFF"}, -- Mystic Buffet
	}, {
		["airphase"] = CL.stage:format(1),
		[70127] = CL.stage:format(2),
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "FrostBreath", 69649, 71056, 71057, 71058, 73061, 73062, 73063, 73064)
	self:Log("SPELL_CAST_START", "TailSmash", 71077)
	self:Log("SPELL_CAST_SUCCESS", "IcyGrip", 70117)
	self:Log("SPELL_AURA_APPLIED", "FrostBeacon", 70126)
	self:Log("SPELL_AURA_REMOVED", "FrostBeaconRemoved", 70126)
	self:Log("SPELL_AURA_REMOVED", "IceTombRemoved", 70157)
	self:Log("SPELL_AURA_APPLIED", "UnchainedMagic", 69762)
	self:Log("SPELL_AURA_REMOVED", "UnchainedMagicRemoved", 69762)
	self:Log("SPELL_AURA_APPLIED", "ChilledToTheBone", 70106)
	self:Log("SPELL_AURA_APPLIED_DOSE", "ChilledToTheBone", 70106)
	self:Log("SPELL_AURA_REMOVED", "ChilledToTheBoneRemoved", 70106)
	self:Log("SPELL_AURA_APPLIED", "Instability", 69766)
	self:Log("SPELL_AURA_APPLIED_DOSE", "Instability", 69766)
	self:Log("SPELL_AURA_REMOVED", "InstabilityRemoved", 69766)
	self:Log("SPELL_AURA_APPLIED", "MysticBuffet", 70127, 72528, 72529, 72530)
	self:Log("SPELL_AURA_APPLIED_DOSE", "MysticBuffet", 70127, 72528, 72529, 72530)
	self:RegisterUnitEvent("UNIT_HEALTH", nil, "boss1")
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
end

function mod:OnEngage()
	beaconList = {}
	unchainedList = {}
	beaconCount = 1
	activeBeacons = false
	stage2Warned = false
	self:SetStage(1)
	self:Berserk(600)
	self:Bar("airphase", 50, L.next_airphase, L.airphase_icon)
	self:CDBar(70123, 33)
	self:CDBar(71077, 20)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if msg:find(L.airphase_trigger, nil, true) or msg:find(L.airphase_trigger_demonic, nil, true) then
		self:Message("airphase", "cyan", L.airphase, L.airphase_icon)
		self:PlaySound("airphase", "long")
		self:StopBar(69649)
		self:CDBar(69762, 55)
		self:CDBar(70123, 80) -- anywhere from 80 to 110 seconds after the air phase began
		self:Bar("airphase", 110, L.next_airphase, L.airphase_icon)
		self:Bar("airphase", 45, L.next_groundphase, L.airphase_icon)
		self:CDBar(71077, 68)
		self:DelayedMessage("airphase", 37.5, "cyan", L.landing_soon, L.airphase_icon)
		activeBeacons = true
	elseif msg:find(L.stage2_trigger, nil, true) or msg:find(L.stage2_trigger_demonic, nil, true) then
		self:SetStage(2)
		self:Message("stages", "cyan", CL.stage:format(2), false)
		self:PlaySound("stages", "long")
		beaconCount = 1
		self:Bar(70126, 7, CL.count:format(self:SpellName(70126), beaconCount))
		self:StopBar(L.next_airphase)
		self:StopBar(L.next_groundphase)
		self:CancelDelayedMessage(L.landing_soon)
		self:CDBar(70123, 35)
	end
end

function mod:UNIT_HEALTH(event, unit)
	if not stage2Warned and self:MobId(self:UnitGUID(unit)) == 36853 and self:GetHealth(unit) <= 38 then
		stage2Warned = true
		self:UnregisterUnitEvent(event, unit)
		self:Message("stages", "cyan", CL.soon:format(CL.stage:format(2)), false)
	end
end

function mod:FrostBreath(args)
	self:Message(69649, "purple")
	self:Bar(69649, 22)
end

function mod:TailSmash(args)
	self:CDBar(71077, 30)
end

function mod:IcyGrip(args) -- the grip before Blistering Cold, one extra second to run
	self:Message(70123, "red")
	self:PlaySound(70123, "alarm") -- run out
	self:CastBar(70123, 6)
	self:CDBar(70123, 67)
end

do
	local function beaconCountForDiff(self)
		local diff = self:Difficulty()
		return diff == 4 and 5 or diff == 6 and 6 or 2
	end
	function mod:FrostBeacon(args)
		if self:GetStage() == 2 then -- one beacon at a time
			beaconCount = beaconCount + 1
			self:TargetMessage(70126, "orange", args.destName, CL.count:format(args.spellName, beaconCount - 1))
			self:Bar(70126, 16, CL.count:format(args.spellName, beaconCount))
			self:CustomIcon(beaconMarker, args.destName, 8)
		else
			if args.time - prevBeacon > 3 then
				beaconList = {}
				beaconIcon = 8
			end
			prevBeacon = args.time
			beaconList[#beaconList + 1] = args.destName
			self:TargetsMessage(70126, "orange", beaconList, beaconCountForDiff(self))
			self:CustomIcon(beaconMarker, args.destName, beaconIcon)
			beaconIcon = beaconIcon - 1
		end
		if self:Me(args.destGUID) then
			self:PlaySound(70126, "warning") -- spread
		end
	end
end

function mod:FrostBeaconRemoved(args)
	activeBeacons = false
end

function mod:IceTombRemoved(args)
	self:CustomIcon(beaconMarker, args.destName)
end

function mod:UnchainedMagic(args)
	if args.time - prevUnchained > 3 then
		unchainedList = {}
		unchainedIcon = 7
		self:CDBar(69762, 30)
	end
	prevUnchained = args.time
	unchainedList[#unchainedList + 1] = args.destName
	self:TargetsMessage(69762, "yellow", unchainedList, 6)
	if self:Me(args.destGUID) then
		self:PlaySound(69762, "warning")
	end
	self:CustomIcon(unchainedMarker, args.destName, unchainedIcon)
	unchainedIcon = unchainedIcon - 1
end

function mod:UnchainedMagicRemoved(args)
	if not activeBeacons then
		self:CustomIcon(unchainedMarker, args.destName)
	end
end

local function highStacks(self, args) -- 4 stacks on heroic, 8 on normal
	return (args.amount or 1) >= (self:Heroic() and 4 or 8)
end

function mod:ChilledToTheBone(args) -- melee
	if self:Me(args.destGUID) then
		self:TargetBar(70106, 8, args.destName)
		if highStacks(self, args) then
			self:StackMessage(70106, "blue", args.destName, args.amount or 1, 4)
			self:PlaySound(70106, "alarm")
		end
	end
end

function mod:ChilledToTheBoneRemoved(args)
	if self:Me(args.destGUID) then
		self:StopBar(70106, args.destName)
	end
end

function mod:Instability(args) -- casters
	if self:Me(args.destGUID) then
		self:TargetBar(69766, 5, args.destName)
		if highStacks(self, args) then
			self:StackMessage(69766, "blue", args.destName, args.amount or 1, 4)
			self:PlaySound(69766, "alarm")
		end
	end
end

function mod:InstabilityRemoved(args)
	if self:Me(args.destGUID) then
		self:StopBar(69766, args.destName)
	end
end

function mod:MysticBuffet(args)
	if self:Me(args.destGUID) then
		local amount = args.amount or 1
		if amount >= 5 then
			self:StackMessage(70127, "blue", args.destName, amount, 5)
			self:PlaySound(70127, "alarm")
		end
	end
end
