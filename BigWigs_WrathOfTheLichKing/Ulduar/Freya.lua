--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Ulduar/Freya.lua), draft by tools/dbm2bw
-- Not ported: the health frame of the adds.

local mod, CL = BigWigs:NewBoss("Freya", 603, 1646)
if not mod then return end
mod:RegisterEnableMob(32906)
mod:SetEncounterID(753)
mod:SetWinMobs() -- 3.3.5: won by the defeat yell (DBM RegisterKill)
mod:SetRespawnTime(20)

--------------------------------------------------------------------------------
-- Locals
--

local adds = {} -- [mobId] = true while alive (Ancient Water Spirit, Snaplasher, Storm Lasher)
local prevSimulKill = 0
local furyIcon = 8
local rootsList = {}
local prevRoots = 0
local rootsIcon = 6
local prevTremor = 0

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	defeat_trigger = "His hold on me dissipates. I can see clearly once more. Thank you, heroes.",
	spawn_trigger = "Children, assist me!",
	adds_trigger1 = "Eonar, your servant requires aid!",
	adds_trigger2 = "The swarm of the elements shall overtake you!",
	lifebinder_trigger = "begins to grow!",

	simul_kill = "Resurrection",
	simul_kill_desc = "Show timer for mob resurrection",
	simul_kill_icon = 62678,
	simul_kill_message = "First add down - Resurrection in ~12 seconds",

	-- 3.3.5: DBM Sirus has no English text for these
	lifebinder = "Дар Эонара",
	lifebinder_desc = "Смена цели - переключитесь на Дар Эонара",
	lifebinder_icon = 62568,
	lifebinder_message = "Смена цели - переключитесь на Дар Эонара",
	lifebinder_soon = "Скоро появится Дар Эонар!",
})

--------------------------------------------------------------------------------
-- Initialization
--

local furyMarker = mod:AddMarkerOption(false, "player", 8, 312881, 8, 7)
local rootsMarker = mod:AddMarkerOption(false, "player", 6, 312860, 6, 5, 4)
function mod:GetOptions()
	return {
		"stages",
		"berserk",
		62678, -- Allies of Nature
		"simul_kill",
		"lifebinder",
		{312880, "SAY"}, -- Nature's Fury
		furyMarker,
		{312860, "SAY"}, -- Iron Roots
		rootsMarker,
		312856, -- Iron Roots (cooldown)
		312842, -- Ground Tremor
		312883, -- Nature Bomb
		312888, -- Unstable Sunbeam
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "GroundTremor", 62437, 62859, 312489, 312842)
	self:Log("SPELL_CAST_SUCCESS", "NatureBomb", 312883)
	self:Log("SPELL_CAST_SUCCESS", "NaturesFury", 63571, 62589, 312527, 312880, 62566)
	self:Log("SPELL_CAST_SUCCESS", "IronRootsSuccess", 63601)
	self:Log("SPELL_AURA_APPLIED", "IronRoots", 62861, 62438, 312490, 312507, 312843, 312860)
	self:Log("SPELL_AURA_REMOVED", "IronRootsRemoved", 62861, 62438, 312490, 312507, 312843, 312860)
	self:Log("SPELL_AURA_APPLIED", "UnstableSunbeam", 62451, 62865, 312535, 312888)
	self:Log("SPELL_AURA_REMOVED", "AttunedToNatureRemoved", 62519, 312486, 312839)
	self:Death("AddDeath", 33202, 32916, 32919)
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
	self:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE")
end

function mod:OnEngage()
	adds = {}
	furyIcon = 8
	rootsIcon = 6
	rootsList = {}
	self:SetStage(1)
	self:Berserk(600)
	self:Bar(62678, 10)
	self:Bar("lifebinder", 25, L.lifebinder, L.lifebinder_icon)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if msg == L.spawn_trigger then
		self:Bar(62678, 60)
		adds[33202], adds[32916], adds[32919] = true, true, true
	elseif msg == L.adds_trigger1 or msg == L.adds_trigger2 then
		self:Bar(62678, 60)
	elseif msg:find(L.defeat_trigger, nil, true) then
		self:Win() -- DBM RegisterKill("yell")
	end
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(_, msg)
	if msg:find(L.lifebinder_trigger, nil, true) then
		self:Message("lifebinder", "green", L.lifebinder_message, L.lifebinder_icon)
		self:PlaySound("lifebinder", "info")
		self:Bar("lifebinder", 40, L.lifebinder, L.lifebinder_icon)
		self:DelayedMessage("lifebinder", 35, "yellow", L.lifebinder_soon, L.lifebinder_icon)
	end
end

function mod:AddDeath(args)
	-- the three adds of a wave have to die within ~12 seconds of each other
	local t = GetTime()
	if t - prevSimulKill > 20 then
		prevSimulKill = t
		self:Message("simul_kill", "orange", L.simul_kill_message, L.simul_kill_icon)
		self:Bar("simul_kill", 12, L.simul_kill, L.simul_kill_icon)
	end
	adds[args.mobId] = nil
	if not next(adds) then
		self:StopBar(L.simul_kill)
	end
end

function mod:GroundTremor(args)
	if args.time - prevTremor > 2.5 then
		prevTremor = args.time
		self:Message(312842, "orange", CL.casting:format(args.spellName))
		self:PlaySound(312842, "alert") -- stop casting
		self:CDBar(312842, 28)
	end
end

function mod:NatureBomb(args)
	self:CDBar(312883, 8)
end

function mod:NaturesFury(args)
	-- alternates between skull and cross
	furyIcon = furyIcon == 8 and 7 or 8
	self:CustomIcon(furyMarker, args.destName, furyIcon)
	self:ScheduleTimer("CustomIcon", 10, furyMarker, args.destName)
	if self:Me(args.destGUID) then
		self:PersonalMessage(312880)
		self:PlaySound(312880, "warning") -- run out
		self:Say(312880)
	else
		self:TargetMessage(312880, "orange", args.destName)
	end
	self:TargetBar(312880, 10, args.destName)
end

function mod:IronRootsSuccess(args)
	self:CDBar(312856, 29.6)
end

function mod:IronRoots(args)
	if args.time - prevRoots > 3 then
		rootsList = {}
	end
	prevRoots = args.time
	rootsList[#rootsList + 1] = args.destName
	self:TargetsMessage(312860, "yellow", rootsList, nil, nil, nil, 0.5)
	if self:Me(args.destGUID) then
		self:Say(312860)
	end
	rootsIcon = rootsIcon - 1
	if rootsIcon >= 4 then
		self:CustomIcon(rootsMarker, args.destName, rootsIcon + 1)
	end
end

function mod:IronRootsRemoved(args)
	self:CustomIcon(rootsMarker, args.destName)
	rootsIcon = math.min(rootsIcon + 1, 6)
end

function mod:UnstableSunbeam(args)
	if self:Me(args.destGUID) then
		self:PersonalMessage(312888, "underyou")
		self:PlaySound(312888, "underyou")
	end
end

function mod:AttunedToNatureRemoved(args)
	self:SetStage(2)
	self:Message("stages", "cyan", CL.stage:format(2), false)
	self:PlaySound("stages", "long")
	self:CDBar(312883, 31)
end
