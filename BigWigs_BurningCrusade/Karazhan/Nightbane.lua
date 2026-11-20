--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Karazhan/Nightbane.lua, heroic mode with custom spells), draft by tools/dbm2bw
-- No journal id: the name is from the DBM localization. Not ported: unequipping weapons under mind control and
-- announcing the Pyromancer icons to the raid chat.

local mod, CL = BigWigs:NewBoss("Nightbane", 532)
if not mod then return end
mod:RegisterEnableMob(17225)
mod:SetEncounterID(662)

--------------------------------------------------------------------------------
-- Locals
--

local pyromancerTargets = {}
local alivePyromancers, groundPhase, conflagrationCount = 0, 0, 0
local firstPyromancers = true

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	bossName = "Nightbane",
	summon_trigger = "An ancient being awakens in the distance...",
	summon = "Nightbane incoming",
})
mod:SetChatEnableTriggers(L.summon_trigger) -- 3.3.5: enable the module on the warmup yell/emote (no target yet)
mod.displayName = L.bossName

--------------------------------------------------------------------------------
-- Initialization
--

local pyromancerMarker = mod:AddMarkerOption(true, "player", 8, 305382, 8, 7, 6)
function mod:GetOptions()
	return {
		"warmup",
		305375, -- heroic: Grieving Fire
		305377, -- heroic: Conflagration
		305380, -- heroic: Pyromancers
		305382, -- heroic: Pyromancer
		pyromancerMarker,
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "GrievingFire", 305375)
	self:Log("SPELL_CAST_START", "Conflagration", 305377)
	self:Log("SPELL_CAST_START", "AirPhase", 305386)
	self:Log("SPELL_CAST_SUCCESS", "Pyromancers", 305380)
	self:Log("SPELL_AURA_APPLIED", "Pyromancer", 305382)
	self:Log("SPELL_AURA_APPLIED", "PyromancerAlive", 305388)
	self:Log("SPELL_AURA_REMOVED", "PyromancerRemoved", 305388)
	self:RegisterEvent("CHAT_MSG_MONSTER_EMOTE")
end

function mod:OnEngage()
	self:StopBar(L.summon)
	pyromancerTargets = {}
	alivePyromancers, groundPhase, conflagrationCount = 0, 0, 0
	firstPyromancers = true
	if self:Difficulty() == 5 then -- 10 heroic
		self:CDBar(305375, 13)
		self:CDBar(305377, 30)
		self:CDBar(305380, 90)
	end
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:CHAT_MSG_MONSTER_EMOTE(_, msg)
	if msg == L.summon_trigger then
		self:Bar("warmup", 29, L.summon, "ability_mount_undeadhorse")
	end
end

function mod:GrievingFire()
	self:CDBar(305375, 13)
end

function mod:Conflagration()
	if conflagrationCount <= 1 then
		self:CDBar(305377, 30)
		conflagrationCount = conflagrationCount + 1
	else
		conflagrationCount = 0
	end
end

function mod:AirPhase()
	pyromancerTargets = {}
	firstPyromancers = true
	groundPhase, alivePyromancers, conflagrationCount = 0, 0, 0
end

function mod:Pyromancers()
	self:CDBar(305380, 90)
end

function mod:Pyromancer(args)
	if self:Me(args.destGUID) then
		self:PersonalMessage(305382)
		self:PlaySound(305382, "warning")
	end
	pyromancerTargets[#pyromancerTargets + 1] = args.destName
	if #pyromancerTargets >= 3 and firstPyromancers then
		firstPyromancers = false
		self:TargetsMessage(305382, "orange", pyromancerTargets, #pyromancerTargets)
		for i = 1, #pyromancerTargets do
			self:CustomIcon(pyromancerMarker, pyromancerTargets[i], 9 - i) -- 8, 7, 6
		end
	end
end

function mod:PyromancerAlive()
	alivePyromancers = alivePyromancers + 1
end

function mod:PyromancerRemoved()
	if groundPhase == alivePyromancers - 1 then
		self:CDBar(305375, 35)
		self:CDBar(305377, 54)
	else
		groundPhase = groundPhase + 1
	end
end
