--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Icecrown/TheCrimsonHall/Lanathel.lua), draft by tools/dbm2bw
-- Not ported: the Essence of the Blood Queen info frame.

local mod, CL = BigWigs:NewBoss("Blood-Queen Lana'thel", 631, 1633)
if not mod then return end
mod:RegisterEnableMob(37955)
mod:SetEncounterID(853)

--------------------------------------------------------------------------------
-- Locals
--

local pactList = {}
local pactIcon = 6
local prevPact = 0
local prevSwarmDamage = 0

local function is10(self)
	local diff = self:Difficulty()
	return diff == 3 or diff == 5
end

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	swarming_shadows_trigger = "Shadows amass and swarm around (%S+)!",
	frenzy_say = "I'm hungry!",
})

--------------------------------------------------------------------------------
-- Initialization
--

local pactMarker = mod:AddMarkerOption(true, "player", 6, 71340, 6, 5, 4)
local mirrorMarker = mod:AddMarkerOption(false, "player", 7, 71510, 7)
local shadowsMarker = mod:AddMarkerOption(true, "player", 8, 71266, 8)
function mod:GetOptions()
	return {
		"berserk",
		"proximity",
		70946, -- Vampiric Bite
		{70867, "ME_ONLY"}, -- Essence of the Blood Queen
		{70877, "SAY"}, -- Frenzied Bloodthirst
		70923, -- Uncontrollable Frenzy
		71340, -- Pact of the Darkfallen
		pactMarker,
		{71510, "TANK_HEALER"}, -- Blood Mirror
		mirrorMarker,
		71266, -- Swarming Shadows
		shadowsMarker,
		71772, -- Bloodbolt Whirl
		73070, -- Incite Terror
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "PactOfTheDarkfallen", 71340)
	self:Log("SPELL_AURA_REMOVED", "PactOfTheDarkfallenRemoved", 71340)
	self:Log("SPELL_AURA_APPLIED", "BloodMirror", 71510, 70838)
	self:Log("SPELL_AURA_REMOVED", "BloodMirrorRemoved", 71510, 70838)
	self:Log("SPELL_AURA_APPLIED", "Bloodthirst", 70877, 71474)
	self:Log("SPELL_AURA_REMOVED", "BloodthirstRemoved", 70877, 71474)
	self:Log("SPELL_AURA_APPLIED", "Essence", 70867, 70879, 71473, 71525, 71530, 71531, 71532, 71533)
	self:Log("SPELL_AURA_APPLIED", "UncontrollableFrenzy", 70923)
	self:Log("SPELL_AURA_APPLIED", "BloodboltWhirl", 71772)
	self:Log("SPELL_CAST_SUCCESS", "InciteTerror", 73070)
	self:Log("SPELL_DAMAGE", "VampiricBite", 71726, 71727, 71728, 71729)
	self:Log("SPELL_MISSED", "VampiricBite", 71726, 71727, 71728, 71729)
	self:Log("SPELL_DAMAGE", "SwarmingShadowsDamage", 71277, 72638, 72639, 72640, 72637)
	self:Log("SPELL_MISSED", "SwarmingShadowsDamage", 71277, 72638, 72639, 72640, 72637)
	self:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE")
end

function mod:OnEngage()
	pactList = {}
	pactIcon = 6
	self:Berserk(330)
	self:Bar(70946, 15)
	self:Bar(71340, 15)
	self:DelayedMessage(71340, 10, "red", CL.soon:format(self:SpellName(71340)))
	self:Bar(71266, 30.5)
	self:DelayedMessage(71266, 25.5, "orange", CL.soon:format(self:SpellName(71266)))
	self:OpenProximity("proximity", 8)
	local terror = is10(self) and 124 or 127
	self:Bar(73070, terror)
	self:DelayedMessage(73070, terror - 5, "yellow", CL.soon:format(self:SpellName(73070)))
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:PactOfTheDarkfallen(args)
	if args.time - prevPact > 3 then
		pactList = {}
		pactIcon = 6
		self:Bar(71340, 30)
		self:DelayedMessage(71340, 25, "red", CL.soon:format(args.spellName))
	end
	prevPact = args.time
	pactList[#pactList + 1] = args.destName
	self:TargetsMessage(71340, "red", pactList, 3)
	if self:Me(args.destGUID) then
		self:PlaySound(71340, "warning") -- gather
	end
	-- the debuff lasts until the players meet, if they still have it after 28 seconds they are probably dead
	self:CustomIcon(pactMarker, args.destName, pactIcon)
	pactIcon = pactIcon - 1
end

function mod:PactOfTheDarkfallenRemoved(args)
	self:CustomIcon(pactMarker, args.destName)
end

function mod:BloodMirror(args)
	self:TargetMessage(71510, "yellow", args.destName)
	self:CustomIcon(mirrorMarker, args.destName, 7)
end

function mod:BloodMirrorRemoved(args)
	self:CustomIcon(mirrorMarker, args.destName)
end

function mod:Bloodthirst(args)
	if self:Me(args.destGUID) then
		self:PersonalMessage(70877)
		self:PlaySound(70877, "alarm")
		self:Say(70877, L.frenzy_say, true)
		self:TargetBar(70877, is10(self) and 15 or 10, args.destName)
	end
end

function mod:BloodthirstRemoved(args)
	if self:Me(args.destGUID) then
		self:StopBar(70877, args.destName)
	end
end

function mod:Essence(args)
	if self:Me(args.destGUID) then
		local t = is10(self) and 75 or 60
		self:PersonalMessage(70867)
		self:PlaySound(70867, "info")
		self:TargetBar(70867, t, args.destName)
		self:DelayedMessage(70877, t - 5, "orange", CL.soon:format(self:SpellName(70877)))
	end
end

function mod:UncontrollableFrenzy(args)
	self:TargetMessage(70923, "red", args.destName)
	if not self:Healer() then
		self:PlaySound(70923, "warning")
	end
end

function mod:BloodboltWhirl(args)
	self:Message(71772, "orange")
	self:PlaySound(71772, "alarm") -- spread
	self:CastBar(71772, 6)
end

function mod:InciteTerror(args)
	self:Message(73070, "red")
	self:PlaySound(73070, "long")
	self:CastBar(73070, 4)
	-- resets Swarming Shadows, Pact comes 5 seconds earlier
	self:Bar(71266, 30.5)
	self:DelayedMessage(71266, 25.5, "orange", CL.soon:format(self:SpellName(71266)))
	self:Bar(71340, 25)
	self:DelayedMessage(71340, 20, "red", CL.soon:format(self:SpellName(71340)))
	local terror = is10(self) and 120 or 100
	self:Bar(73070, terror)
	self:DelayedMessage(73070, terror - 5, "yellow", CL.soon:format(args.spellName))
end

function mod:VampiricBite(args)
	if self:MobId(args.sourceGUID) == 37955 then -- the first bite only, hers
		self:TargetMessage(70946, "yellow", args.destName)
	end
end

function mod:SwarmingShadowsDamage(args)
	if self:Me(args.destGUID) and args.time - prevSwarmDamage > 2.5 then
		prevSwarmDamage = args.time
		self:PersonalMessage(71266, "underyou")
		self:PlaySound(71266, "underyou")
	end
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(_, msg, _, _, _, target)
	if target and msg:match(L.swarming_shadows_trigger) then
		self:Bar(71266, 30.5)
		self:DelayedMessage(71266, 25.5, "orange", CL.soon:format(self:SpellName(71266)))
		if target == self:UnitName("player") then
			self:PersonalMessage(71266)
			self:PlaySound(71266, "alarm") -- run out, keep moving
		else
			self:TargetMessage(71266, "orange", target)
		end
		self:CustomIcon(shadowsMarker, target, 8)
		self:ScheduleTimer("CustomIcon", 6, shadowsMarker, target)
	end
end
