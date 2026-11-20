--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: Sirus custom encounter, written from DBM Sirus (DBM-Icecrown/TheFrozenThrone/Jaina.lua), draft by tools/dbm2bw
-- DBM Sirus only has Russian texts for this boss, the English defaults below are the Russian ones.
-- Not ported: nameplate icons, announcing Explosive Flame to the raid chat.

local mod, CL = BigWigs:NewBoss("Lady Jaina Proudmoore", 631)
if not mod then return end
mod:RegisterEnableMob(200000)
mod:SetEncounterID(3392) -- DBM Sirus custom encounter id

--------------------------------------------------------------------------------
-- Locals
--

local explosiveList = {}
local explosiveIcon = 8
local prevExplosive = 0
local wildFlameList = {}
local prevWildFlame = 0
local vengefulIceList = {}
local prevVengefulIce = 0
local iceMarkList = {}
local prevIceMark = 0

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	bossName = "Lady Jaina Proudmoore",
	engage_trigger = "Джайна... Зачем...",
	warmup_trigger = "Джайна? Что ты делаешь? Оставь его, это не тот Артас, которого ты знала!",

	black_ice = "Черный лед",
	ice_wrath = "Купол - бегите на край.",
	wild_flame_near = "Дикое пламя рядом - отойдите.",
	freezing = "Заморозка меток",
})
mod:SetChatEnableTriggers(L.warmup_trigger) -- 3.3.5: enable the module on the warmup yell/emote (no target yet)
mod.displayName = L.bossName

--------------------------------------------------------------------------------
-- Initialization
--

local explosiveMarker = mod:AddMarkerOption(true, "player", 8, 306487, 8, 7, 6, 5, 4, 3)
function mod:GetOptions()
	return {
		"warmup",
		"stages",
		"berserk",
		-- Stage One
		306454, -- Summon Elementals
		{306464, "PROXIMITY"}, -- Arcane Storm
		306468, -- Unstable Magic
		306455, -- stacks
		-- Stage Two
		306485, -- Rays
		306491, -- Meteor
		306495, -- Firewhirl
		306487, -- Explosive Flame
		explosiveMarker,
		306502, -- Wild Flame
		{306504, "TANK"}, -- tank stacks
		-- Stage Three
		306545, -- Ice Wrath
		306531, -- Ice Rush
		306535, -- Vengeful Ice
		306523, -- Ice Mark
	}, {
		[306454] = CL.stage:format(1),
		[306485] = CL.stage:format(2),
		[306545] = CL.stage:format(3),
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "ArcaneStorm", 306464)
	self:Log("SPELL_CAST_START", "UnstableMagic", 306468)
	self:Log("SPELL_CAST_START", "SummonElementals", 306454)
	self:Log("SPELL_CAST_START", "StageTwo", 306483)
	self:Log("SPELL_CAST_START", "Rays", 306485)
	self:Log("SPELL_CAST_START", "Meteor", 306491)
	self:Log("SPELL_CAST_START", "IceRush", 306531)
	self:Log("SPELL_CAST_START", "IceWrath", 306545)
	self:Log("SPELL_CAST_SUCCESS", "StageThree", 306516)
	self:Log("SPELL_AURA_APPLIED", "ArcaneStormApplied", 306464)
	self:Log("SPELL_AURA_REMOVED", "ArcaneStormRemoved", 306464)
	self:Log("SPELL_AURA_APPLIED", "Firewhirl", 306495)
	self:Log("SPELL_AURA_APPLIED", "ExplosiveFlame", 306487)
	self:Log("SPELL_AURA_APPLIED", "WildFlame", 306502)
	self:Log("SPELL_AURA_APPLIED", "VengefulIce", 306535)
	self:Log("SPELL_AURA_APPLIED", "IceMark", 306523, 306524)
	self:Log("SPELL_AURA_APPLIED", "Stacks", 306455)
	self:Log("SPELL_AURA_APPLIED_DOSE", "Stacks", 306455)
	self:Log("SPELL_AURA_APPLIED", "TankStacks", 306504)
	self:Log("SPELL_AURA_APPLIED_DOSE", "TankStacks", 306504)
	self:Log("SPELL_AURA_REMOVED", "IceWrathRemoved", 306549)
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
end

function mod:OnEngage()
	explosiveList, wildFlameList, vengefulIceList, iceMarkList = {}, {}, {}, {}
	explosiveIcon = 8
	self:StopBar(CL.active)
	self:SetStage(1)
	self:Berserk(1802)
	self:CDBar(306454, 27)
	self:CDBar(306464, 64)
	self:DelayedMessage(306464, 61, "yellow", CL.soon:format(self:SpellName(306464)))
	self:CDBar(306468, 26)
	self:DelayedMessage(306468, 23, "yellow", CL.soon:format(self:SpellName(306468)))
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if msg:find(L.warmup_trigger, nil, true) then
		self:Bar("warmup", 54, CL.active, "inv_misc_pocketwatch_01") -- DBM starts the timers 54 seconds later
	elseif msg:find(L.engage_trigger, nil, true) then
		self:Engage() -- DBM RegisterCombat("yell")
	end
end

-- Stage One

function mod:ArcaneStorm(args)
	self:Message(306464, "red")
	self:PlaySound(306464, "warning") -- spread
	self:OpenProximity(306464, 10)
	self:ScheduleTimer("CloseProximity", 11, 306464)
end

function mod:ArcaneStormApplied(args)
	self:CastBar(306464, 10)
	self:CDBar(306454, 11)
end

function mod:ArcaneStormRemoved(args)
	if BigWigsLoader.Compat.GetRealmNumber() == 2 then -- DBM Sirus: different on the x2 realm
		self:CDBar(306464, 62)
		self:DelayedMessage(306464, 62, "yellow", CL.soon:format(args.spellName))
	else
		self:CDBar(306464, 52)
		self:DelayedMessage(306464, 42, "yellow", CL.soon:format(args.spellName))
	end
end

function mod:UnstableMagic(args)
	self:Message(306468, "orange")
	self:PlaySound(306468, "alert")
	self:CDBar(306468, 22)
	self:DelayedMessage(306468, 21, "yellow", CL.soon:format(args.spellName))
end

function mod:SummonElementals(args)
	self:CDBar(306454, 46)
end

function mod:Stacks(args)
	self:StackMessage(306455, "yellow", args.destName, args.amount or 1, 99)
end

-- Stage Two

function mod:StageTwo(args)
	self:SetStage(2)
	self:Message("stages", "cyan", CL.stage:format(2) .. ": " .. args.spellName, false)
	self:PlaySound("stages", "long")
	self:StopBar(306464)
	self:StopBar(306468)
	self:CancelDelayedMessage(CL.soon:format(self:SpellName(306464)))
	self:CancelDelayedMessage(CL.soon:format(self:SpellName(306468)))
	self:CDBar(306485, 17)
	self:CDBar(306491, 29)
	self:CDBar(306495, 60)
	self:CastBar("stages", 10, 306483, 306483)
end

function mod:Rays(args)
	self:Message(306485, "orange")
	self:PlaySound(306485, "alert")
	self:CDBar(306485, 28)
end

function mod:Meteor(args)
	self:CDBar(306491, 35)
end

function mod:Firewhirl(args)
	self:Message(306495, "yellow")
	self:CastBar(306495, 20, 306500) -- Collapse
	self:ScheduleTimer("CDBar", 20, 306495, 65)
	-- Rays and Meteor are pushed back by 20 seconds
	for _, key in next, {306485, 306491} do
		local left = self:BarTimeLeft(key)
		self:CDBar(key, left > 0 and left + 20 or 20)
	end
end

function mod:ExplosiveFlame(args)
	if args.time - prevExplosive > 3 then
		explosiveList = {}
		explosiveIcon = 8
	end
	prevExplosive = args.time
	explosiveList[#explosiveList + 1] = args.destName
	self:TargetsMessage(306487, "red", explosiveList, 6, nil, nil, 0.1)
	if self:Me(args.destGUID) then
		self:PlaySound(306487, "alarm") -- run
	end
	self:CustomIcon(explosiveMarker, args.destName, explosiveIcon)
	explosiveIcon = explosiveIcon - 1
end

function mod:WildFlame(args)
	if self:Me(args.destGUID) then
		self:PersonalMessage(306502)
		self:PlaySound(306502, "alarm")
	else
		local unit = self:UnitTokenFromGUID(args.destGUID)
		if unit and CheckInteractDistance(unit, 3) then
			self:Message(306502, "orange", L.wild_flame_near)
			self:PlaySound(306502, "alert")
		end
	end
	if args.time - prevWildFlame > 3 then
		wildFlameList = {}
	end
	prevWildFlame = args.time
	wildFlameList[#wildFlameList + 1] = args.destName
	self:TargetsMessage(306502, "red", wildFlameList, nil, nil, nil, 0.1)
end

function mod:TankStacks(args)
	self:StackMessage(306504, "purple", args.destName, args.amount or 1, 99)
	self:TargetBar(306504, 10, args.destName)
end

-- Stage Three

function mod:StageThree(args)
	self:SetStage(3)
	self:Message("stages", "cyan", CL.stage:format(3) .. ": " .. L.black_ice, false)
	self:PlaySound("stages", "long")
	self:StopBar(306485)
	self:StopBar(306491)
	self:StopBar(306495)
	self:CDBar(306545, 135)
end

function mod:IceWrath(args)
	self:Message(306545, "red", L.ice_wrath)
	self:PlaySound(306545, "warning")
end

function mod:IceWrathRemoved(args)
	self:CDBar(306545, 180)
end

function mod:IceRush(args)
	self:Message(306531, "orange")
	if self:Melee() then
		self:PlaySound(306531, "alarm")
	end
end

function mod:VengefulIce(args)
	if args.time - prevVengefulIce > 3 then
		vengefulIceList = {}
	end
	prevVengefulIce = args.time
	vengefulIceList[#vengefulIceList + 1] = args.destName
	self:TargetsMessage(306535, "orange", vengefulIceList, 2)
	if self:Me(args.destGUID) then
		self:PlaySound(306535, "warning")
	end
end

function mod:IceMark(args)
	if args.time - prevIceMark > 3 then
		iceMarkList = {}
		self:Bar(306523, 6, L.freezing)
	end
	prevIceMark = args.time
	iceMarkList[#iceMarkList + 1] = args.destName
	self:TargetsMessage(306523, "red", iceMarkList, 6)
	if self:Me(args.destGUID) then
		self:PlaySound(306523, "alarm") -- run
	end
end
