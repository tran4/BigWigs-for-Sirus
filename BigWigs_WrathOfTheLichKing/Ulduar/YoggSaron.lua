--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Ulduar/YoggSaron.lua), draft by tools/dbm2bw
-- Not ported: Sara's and the brain's health frame, the Sanity info frame, the DBM arrow away from Malady.

local mod, CL = BigWigs:NewBoss("Yogg-Saron", 603, 1649)
if not mod then return end
mod:RegisterEnableMob(33288)
mod:SetEncounterID(756)

--------------------------------------------------------------------------------
-- Locals
--

local brainLinkList = {}
local prevBrainLink = 0
local brainLinkIcon = 2
local roarCount = 0
local guardianCount = 0
local beaconIcon = 8
local beaconsToMark = {} -- [guid] = icon
local prevFervor, prevEmpower, prevGaze, prevGazeRemoved = 0, 0, 0, 0

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	engage_trigger = "The time to strike at the head of the beast will soon be upon us! Focus your anger and hatred on his minions!",

	guardian = "Guardian %d spawned",
	crusher_tentacle = "Crusher Tentacle spawned",
	sanity = "%d Sanity remaining",
	madness_out = "Induce Madness ending - Move out",
	portal = "Brain Portal",
	portal_desc = "Show timer for next Brain Portal",
	portal_icon = 57687,
	portal_soon = "Brain Portal in 3 seconds",
})

--------------------------------------------------------------------------------
-- Initialization
--

local fervorMarker = mod:AddMarkerOption(false, "player", 7, 312989, 7)
local maladyMarker = mod:AddMarkerOption(true, "player", 8, 313029, 8)
local brainLinkMarker = mod:AddMarkerOption(true, "player", 2, 312995, 2, 1)
local beaconMarker = mod:AddMarkerOption(true, "npc", 8, 64465, 8, 7, 6, 5, 4, 3, 2, 1)
function mod:GetOptions()
	return {
		"stages",
		"berserk",
		-- Stage One
		312989, -- Sara's Fervor
		fervorMarker,
		62979, -- Summon Guardian
		314683, -- Dark Volley
		-- Stage Two
		63050, -- Sanity
		{312995, "SAY", "PROXIMITY"}, -- Brain Link
		brainLinkMarker,
		{313031, "SAY"}, -- Squeeze
		64144, -- Crusher Tentacle
		313029, -- Malady of the Mind
		maladyMarker,
		"portal",
		64775, -- Shadowy Barrier
		313003, -- Induce Madness
		313002, -- Lunatic Gaze
		-- Stage Three
		64465, -- Empowering Shadows
		beaconMarker,
		313000, -- Deafening Roar
	}, {
		[312989] = CL.stage:format(1),
		[63050] = CL.stage:format(2),
		[64465] = CL.stage:format(3),
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "InduceMadness", 312650, 313003, 64059)
	self:Log("SPELL_CAST_START", "DeafeningRoar", 313000, 64189, 312647)
	self:Log("SPELL_CAST_START", "SarasFervorCast", 312989)
	self:Log("SPELL_CAST_START", "DarkVolley", 63038, 312644, 312997, 314683)
	self:Log("SPELL_CAST_SUCCESS", "CrusherTentacle", 64144)
	self:Log("SPELL_CAST_SUCCESS", "EmpoweringShadows", 64465)
	self:Log("SPELL_CAST_SUCCESS", "LunaticGazeSuccess", 313001, 313002, 313027, 313028)
	self:Log("SPELL_SUMMON", "SummonGuardian", 62979)
	self:Log("SPELL_AURA_APPLIED", "BrainLink", 312995, 312994, 312996, 63802)
	self:Log("SPELL_AURA_REMOVED", "BrainLinkRemoved", 312995, 312994, 312996, 63802)
	self:Log("SPELL_AURA_APPLIED", "Malady", 63830, 63881, 312993, 313029)
	self:Log("SPELL_AURA_REMOVED", "MaladyRemoved", 63830, 63881, 312993, 313029)
	self:Log("SPELL_AURA_APPLIED", "Squeeze", 64126, 313031, 63138)
	self:Log("SPELL_AURA_APPLIED", "SarasFervor", 312989)
	self:Log("SPELL_AURA_REMOVED", "SarasFervorRemoved", 312989)
	self:Log("SPELL_AURA_APPLIED", "ShadowyBarrier", 63894, 64775)
	self:Log("SPELL_AURA_REMOVED", "ShadowyBarrierRemoved", 63894, 64775)
	self:Log("SPELL_AURA_APPLIED", "LunaticGaze", 313001, 313002, 313027, 313028, 64167, 64163)
	self:Log("SPELL_AURA_REMOVED", "LunaticGazeRemoved", 313001, 313002, 313027, 313028, 64167, 64163)
	self:Log("SPELL_AURA_APPLIED", "ShadowBeacon", 64465)
	self:Log("SPELL_AURA_REMOVED_DOSE", "Sanity", 63050)
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
end

function mod:OnEngage()
	brainLinkList = {}
	brainLinkIcon = 2
	roarCount = 0
	guardianCount = 0
	beaconIcon = 8
	beaconsToMark = {}
	self:SetStage(1)
	self:Berserk(900)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if msg:find(L.engage_trigger, nil, true) then
		self:Engage() -- DBM RegisterCombat("yell")
	end
end

-- Stage One

do
	local function printTarget(self, name, guid)
		if self:Me(guid) and GetTime() - prevFervor > 4 then
			prevFervor = GetTime()
			self:PersonalMessage(312989)
			self:PlaySound(312989, "warning")
		end
	end
	function mod:SarasFervorCast(args)
		self:GetUnitTarget(printTarget, 0.1, args.sourceGUID)
	end
end

function mod:SarasFervor(args)
	self:TargetMessage(312989, "orange", args.destName)
	self:TargetBar(312989, 15, args.destName)
	self:CustomIcon(fervorMarker, args.destName, 7)
	if self:Me(args.destGUID) and GetTime() - prevFervor > 4 then
		prevFervor = GetTime()
		self:PlaySound(312989, "warning")
	end
end

function mod:SarasFervorRemoved(args)
	self:StopBar(312989, args.destName)
	self:CustomIcon(fervorMarker, args.destName)
end

function mod:SummonGuardian(args)
	guardianCount = guardianCount + 1
	self:Message(62979, "yellow", L.guardian:format(guardianCount))
end

function mod:DarkVolley(args)
	if self:Interrupter(args.sourceGUID) then
		self:Message(314683, "yellow", CL.casting:format(args.spellName))
		self:PlaySound(314683, "alert")
	end
end

-- Stage Two

function mod:ShadowyBarrier(args) -- stage 2 starts
	if self:GetStage() >= 2 then return end
	self:SetStage(2)
	self:Message("stages", "cyan", CL.stage:format(2), false)
	self:PlaySound("stages", "long")
	self:CDBar(64775, 60)
	self:DelayedMessage("portal", 57, "yellow", L.portal_soon, L.portal_icon)
end

function mod:CrusherTentacle(args)
	if self:MobId(args.sourceGUID) == 33966 then
		self:Message(64144, "orange", L.crusher_tentacle)
	end
end

function mod:BrainLink(args)
	if args.time - prevBrainLink > 2 then
		brainLinkList = {}
		brainLinkIcon = 2
	end
	prevBrainLink = args.time
	brainLinkList[#brainLinkList + 1] = args.destName
	self:TargetsMessage(312995, "yellow", brainLinkList, 2, nil, nil, 0.5)
	if #brainLinkList == 1 then
		self:CDBar(312995, 25.5)
	end
	self:CustomIcon(brainLinkMarker, args.destName, brainLinkIcon)
	brainLinkIcon = brainLinkIcon - 1
	if self:Me(args.destGUID) then
		self:PlaySound(312995, "warning") -- stay together
		self:Say(312995)
		self:OpenProximity(312995, 20)
	end
end

function mod:BrainLinkRemoved(args)
	self:CustomIcon(brainLinkMarker, args.destName)
	if self:Me(args.destGUID) then
		self:CloseProximity(312995)
	end
end

function mod:Malady(args)
	self:CustomIcon(maladyMarker, args.destName, 8)
	self:ScheduleTimer("CustomIcon", 30, maladyMarker, args.destName)
end

function mod:MaladyRemoved(args)
	self:CustomIcon(maladyMarker, args.destName)
end

function mod:Squeeze(args)
	self:TargetMessage(313031, "red", args.destName)
	if self:Me(args.destGUID) then
		self:Say(313031)
	end
end

function mod:InduceMadness(args)
	self:Message(313003, "orange", CL.casting:format(args.spellName))
	self:DelayedMessage(313003, 55, "red", L.madness_out, nil, "alarm")
end

function mod:LunaticGazeSuccess(args)
	if args.time - prevGaze > 3 then
		prevGaze = args.time
		self:Bar("portal", 60, L.portal, L.portal_icon)
		self:CDBar(64775, 90)
		self:DelayedMessage("portal", 55, "yellow", L.portal_soon, L.portal_icon)
	end
end

function mod:LunaticGaze(args)
	self:CastBar(313002, 4)
	if self:GetStage() == 3 then
		self:Message(313002, "orange")
		self:PlaySound(313002, "alert")
		self:StopBar(L.portal)
		self:StopBar(64775)
		self:CancelDelayedMessage(L.portal_soon)
	end
end

function mod:LunaticGazeRemoved(args)
	if args.time - prevGazeRemoved > 3 then
		prevGazeRemoved = args.time
		self:CDBar(313002, 8.5)
	end
end

function mod:Sanity(args)
	if self:Me(args.destGUID) then
		local amount = args.amount or 1
		if amount == 50 then
			self:Message(63050, "yellow", L.sanity:format(amount))
		elseif amount == 35 or amount == 25 or amount == 15 then
			self:Message(63050, "red", L.sanity:format(amount))
			self:PlaySound(63050, "alarm")
		end
	end
end

-- Stage Three

function mod:ShadowyBarrierRemoved(args)
	-- 3.3.5: DBM syncs this, the combat log is not seen from the brain room
	if self:GetStage() >= 3 then return end
	self:SetStage(3)
	self:Message("stages", "cyan", CL.stage:format(3), false)
	self:PlaySound("stages", "long")
	self:StopBar(L.portal)
	self:StopBar(64775)
	self:CancelDelayedMessage(L.portal_soon)
	self:CancelDelayedMessage(L.madness_out)
	self:StopBar(312995)
	self:StopBar(64465)
	self:DelayedMessage(64465, 40, "orange", CL.soon:format(self:SpellName(64465)))
	self:CDBar(313000, 25, CL.count:format(self:SpellName(313000), roarCount + 1))
	self:DelayedMessage(313000, 15, "yellow", CL.soon:format(self:SpellName(313000)))
end

function mod:EmpoweringShadows(args)
	if args.time - prevEmpower > 3 then
		prevEmpower = args.time
		self:CDBar(64465, 46)
		self:CastBar(64465, 10)
		self:DelayedMessage(64465, 40, "orange", CL.soon:format(args.spellName))
	end
end

function mod:MarkBeacons(_, unit, guid)
	local icon = beaconsToMark[guid]
	if icon then
		beaconsToMark[guid] = nil
		self:CustomIcon(beaconMarker, unit, icon)
		if not next(beaconsToMark) then
			self:UnregisterTargetEvents()
		end
	end
end

function mod:ShadowBeacon(args) -- on the Immortal Guardians
	if self:GetOption(beaconMarker) then
		beaconsToMark[args.destGUID] = beaconIcon
		self:RegisterTargetEvents("MarkBeacons")
	end
	beaconIcon = beaconIcon - 1
	if beaconIcon == 0 then beaconIcon = 8 end
end

function mod:DeafeningRoar(args)
	self:StopBar(CL.count:format(args.spellName, roarCount + 1))
	roarCount = roarCount + 1
	self:Message(313000, "orange", CL.count:format(args.spellName, roarCount))
	self:PlaySound(313000, "alert") -- silence soon
	self:CastBar(313000, 2.3)
	self:CDBar(313000, 25, CL.count:format(args.spellName, roarCount + 1))
end
