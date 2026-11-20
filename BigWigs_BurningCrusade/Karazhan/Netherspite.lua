--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Karazhan/Netherspite.lua, heroic mode with custom spells), draft by tools/dbm2bw

local mod, CL = BigWigs:NewBoss("Netherspite", 532, 1561)
if not mod then return end
mod:RegisterEnableMob(15689)
mod:SetEncounterID(659)

--------------------------------------------------------------------------------
-- Locals
--

local breathCount = 0
local voidCount = 0
local prevVoid, prevWither = 0, 0
local gatesTargets = {}

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	banish_trigger = "%s goes into a nether-fed rage!", -- DBM: msg == L.X (the raw emote text)
	portal_trigger = "%s cries out in withdrawal, opening gates to the nether.",

	portal_soon = "Portal Phase in 5",
	banish_soon = "Banish Phase in 5",
	portal_phase = "Portal Phase",
	banish_phase = "Banish Phase",

	-- heroic, DBM has no English texts
	gates = "Зеленые лучи",
	ghost_phase = "Призрачная фаза",
	repentance = "Возмездие",
	portals = "Появление порталов",
	normal_phase = "Обычная фаза",
})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"stages",
		"berserk",
		38523, -- Netherbreath
		30533, -- Void Zone
		305403, -- heroic: gates
		305407, -- heroic: breath
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "Netherbreath", 38523)
	self:Log("SPELL_CAST_START", "HeroicBreath", 305407)
	self:Log("SPELL_CAST_SUCCESS", "VoidZone", 37014, 37063)
	self:Log("SPELL_AURA_APPLIED", "Gates", 305402, 305403, 305404)
	self:Log("SPELL_AURA_APPLIED", "GhostPhase", 305408, 305409)
	self:Log("SPELL_PERIODIC_DAMAGE", "VoidZoneDamage", 30533)
	self:Log("SPELL_DAMAGE", "WitherDamage", 28865)
	self:Log("SPELL_SUMMON", "VoidZoneSummon", 37063)
	self:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE")
end

function mod:OnEngage()
	breathCount, voidCount = 0, 0
	prevVoid, prevWither = 0, 0
	gatesTargets = {}
	if self:Difficulty() == 5 then -- 10 heroic
		self:Bar(305403, 13, L.gates)
		self:Bar("stages", 75, L.ghost_phase, 305408)
	else
		self:Bar(30533, 15)
		self:Berserk(540)
		self:Bar("stages", 60, L.portal_phase, "spell_arcane_portalironforge")
		self:DelayedMessage("stages", 55, "yellow", L.banish_soon, "spell_shadow_cripple")
	end
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:CHAT_MSG_RAID_BOSS_EMOTE(_, msg)
	if msg:find(L.banish_trigger, nil, true) then
		self:StopBar(L.portal_phase)
		self:Message("stages", "cyan", L.banish_phase, "spell_shadow_cripple")
		self:Bar("stages", 30, L.banish_phase, "spell_shadow_cripple")
		self:DelayedMessage("stages", 26, "yellow", L.portal_soon, "spell_arcane_portalironforge")
	elseif msg:find(L.portal_trigger, nil, true) then
		self:Bar(30533, 15)
		self:StopBar(L.banish_phase)
		self:Message("stages", "cyan", L.portal_phase, "spell_arcane_portalironforge")
		self:Bar("stages", 60, L.portal_phase, "spell_arcane_portalironforge")
		self:DelayedMessage("stages", 56.5, "yellow", L.banish_soon, "spell_shadow_cripple")
	end
end

function mod:Netherbreath(args)
	self:Message(38523, "orange", CL.casting:format(args.spellName))
	self:CastBar(38523, 2.5)
end

function mod:HeroicBreath()
	if breathCount < 4 then
		self:CDBar(305407, 13)
		breathCount = breathCount + 1
	else
		breathCount = 0
	end
end

function mod:VoidZone()
	self:Message(30533, "yellow")
end

function mod:VoidZoneSummon()
	self:Bar(30533, 15)
	voidCount = voidCount + 1
	if voidCount >= 3 then
		self:StopBar(30533)
		voidCount = 0
	end
end

function mod:VoidZoneDamage(args)
	if self:Me(args.destGUID) and args.time - prevVoid > 2 then
		prevVoid = args.time
		self:PersonalMessage(30533, "underyou")
		self:PlaySound(30533, "underyou")
	end
end

function mod:WitherDamage(args)
	if self:Me(args.destGUID) and args.time - prevWither > 3 then
		prevWither = args.time
		self:PersonalMessage(30533, "underyou")
		self:PlaySound(30533, "underyou")
	end
end

function mod:Gates(args)
	if self:Me(args.destGUID) then
		self:PersonalMessage(305403)
		self:PlaySound(305403, "alarm")
	end
	gatesTargets[#gatesTargets + 1] = args.destName
	if #gatesTargets >= 3 then
		self:Message(305403, "yellow", CL.on:format(self:SpellName(305403), table.concat(gatesTargets, ", ")))
		gatesTargets = {}
	end
end

function mod:GhostPhase()
	self:Message("stages", "cyan", L.ghost_phase, 305408)
	self:Bar("stages", 30, L.repentance, 305408)
	self:Bar("stages", 15, L.portals, 33404)
	self:Bar("stages", 60, L.normal_phase, 23684)
	self:ScheduleTimer("Bar", 60, 305403, 13, L.gates)
	self:ScheduleTimer("Bar", 60, "stages", 75, L.ghost_phase, 305408)
end
