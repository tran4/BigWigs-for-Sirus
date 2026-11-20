--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-BlackTemple/Illidan.lua), draft by tools/dbm2bw

local mod, CL = BigWigs:NewBoss("Illidan Stormrage", 564, 1590)
if not mod then return end
mod:RegisterEnableMob(22917)
mod:SetEncounterID(609)

--------------------------------------------------------------------------------
-- Locals
--

local flamesDown, flameBursts = 0, 0
local warnedStage2, warnedStage4 = false, false
local prevCrash = 0

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	warmup_trigger = "Akama. Your duplicity is hardly surprising. I should have slaughtered you and your malformed brethren long ago.",
	eyebeam_trigger = "Stare into the eyes of the Betrayer!",
	demon_trigger = "Behold the power... of the demon within!",
	stage4_trigger = "Is this it, mortals? Is this all the fury you can muster?",

	forms = "Forms",
	forms_desc = "Show warnings and timers for the human and the demon phases",
	forms_icon = 40506,
	human = "Human Phase",
	demon = "Demon Phase",
	next_human = "Next Human Phase",
	next_demon = "Next Demon Phase",
})
mod:SetChatEnableTriggers(L.warmup_trigger) -- 3.3.5: enable the module on the warmup yell/emote (no target yet)

--------------------------------------------------------------------------------
-- Initialization
--

local parasiteMarker = mod:AddMarkerOption(true, "player", 8, 41917, 8)
function mod:GetOptions()
	return {
		"warmup",
		"stages",
		"berserk",
		"forms",
		{41917, "SAY_COUNTDOWN"}, -- Parasitic Shadowfiend
		parasiteMarker,
		{40904, "TANK"}, -- Draw Soul
		40018, -- Eye Blast
		40585, -- Dark Barrage
		40932, -- Agonizing Flames
		41131, -- Flame Burst
		41117, -- Summon Shadow Demons
		40683, -- Frenzy
		40695, -- Caged
		40841, -- Flame Crash
		"proximity",
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "Parasite", 41917, 41914)
	self:Log("SPELL_AURA_REMOVED", "ParasiteRemoved", 41917, 41914)
	self:Log("SPELL_AURA_APPLIED", "DarkBarrage", 40585)
	self:Log("SPELL_AURA_APPLIED", "AgonizingFlames", 40932)
	self:Log("SPELL_AURA_APPLIED", "ShadowDemon", 41083)
	self:Log("SPELL_AURA_APPLIED", "Frenzy", 40683)
	self:Log("SPELL_AURA_APPLIED", "Caged", 40695)
	self:Log("SPELL_CAST_START", "DrawSoul", 40904)
	self:Log("SPELL_CAST_START", "SummonShadowDemons", 41117)
	self:Log("SPELL_CAST_START", "ThrowGlaive", 39849)
	self:Log("SPELL_CAST_SUCCESS", "FlameBurst", 41126)
	self:Log("SPELL_CAST_SUCCESS", "ShadowPrison", 40647)
	self:Log("SPELL_DAMAGE", "FlameCrash", 40841)
	self:Log("SPELL_MISSED", "FlameCrash", 40841)
	self:Death("FlameDeath", 22997)
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
	self:RegisterEvent("UNIT_HEALTH")
end

function mod:OnEngage()
	self:SetStage(1)
	flamesDown, flameBursts = 0, 0
	warnedStage2, warnedStage4 = false, false
	prevCrash = 0
	self:StopBar(CL.active)
	self:Berserk(1500)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if msg:find(L.warmup_trigger, nil, true) then
		self:Bar("warmup", 36, CL.active, "inv_misc_pocketwatch_01")
	elseif not self:IsEngaged() then
		return
	elseif msg:find(L.eyebeam_trigger, nil, true) then
		self:Message(40018, "red")
		self:PlaySound(40018, "alarm")
	elseif msg:find(L.demon_trigger, nil, true) then
		flameBursts = 0
		self:Message("forms", "red", L.demon, 40506)
		self:PlaySound("forms", "long")
		self:Bar("forms", 74, L.next_human, 97061)
		self:CDBar(41131, 20)
		self:CDBar(41117, 34)
		self:CancelTimer(self.humanTimer)
		self.humanTimer = self:ScheduleTimer("HumanForm", 74)
	elseif msg:find(L.stage4_trigger, nil, true) then
		self:Stage4()
	end
end

function mod:HumanForm()
	self:Message("forms", "green", L.human, 97061)
	self:StopBar(41131)
	self:Bar("forms", 60, L.next_demon, 40506)
	if self:GetStage() == 4 then
		self:Bar(40683, 10, CL.other:format(self:SpellName(40683), CL.active))
	end
end

function mod:Stage4()
	if self:GetStage() >= 4 then return end
	self:SetStage(4)
	warnedStage4 = true
	self:CancelTimer(self.humanTimer)
	self:StopBar(41131)
	self:StopBar(41117)
	self:StopBar(L.next_human)
	self:StopBar(L.next_demon)
	self:Bar("stages", 30, CL.stage:format(4), "achievement_bg_returnxflags_def_wsg")
	self:DelayedMessage("stages", 30, "cyan", CL.stage:format(4), false, "long")
	self:Bar("forms", 92, L.next_demon, 40506)
end

function mod:ShadowPrison()
	self:Stage4()
end

function mod:UNIT_HEALTH(_, unit)
	if not self:IsEngaged() or self:MobId(self:UnitGUID(unit)) ~= 22917 then return end
	local hp = self:GetHealth(unit)
	if not warnedStage2 and hp <= 75 then
		warnedStage2 = true
		self:Message("stages", "cyan", CL.soon:format(CL.stage:format(2)), false)
	elseif not warnedStage4 and hp <= 35 then
		warnedStage4 = true
		self:Message("stages", "cyan", CL.soon:format(CL.stage:format(4)), false)
	end
end

function mod:ThrowGlaive()
	self:SetStage(2)
	flamesDown = 0
	warnedStage2 = true
	self:Message("stages", "cyan", CL.stage:format(2), false)
	self:PlaySound("stages", "long")
	self:CDBar(40585, 85)
end

function mod:FlameDeath()
	flamesDown = flamesDown + 1
	if flamesDown >= 2 then
		self:SetStage(3)
		self:OpenProximity("proximity", 6)
		self:StopBar(40585)
		self:Message("stages", "cyan", CL.stage:format(3), false)
		self:PlaySound("stages", "long")
		self:Bar("forms", 76, L.next_demon, 40506)
	end
end

function mod:Parasite(args)
	self:CustomIcon(parasiteMarker, args.destName, 8)
	if self:Me(args.destGUID) then
		self:PersonalMessage(41917)
		self:PlaySound(41917, "warning")
		self:SayCountdown(41917, 10)
	else
		self:TargetMessage(41917, "orange", args.destName)
	end
end

function mod:ParasiteRemoved(args)
	self:CustomIcon(parasiteMarker, args.destName)
	if self:Me(args.destGUID) then
		self:CancelSayCountdown(41917)
	end
end

function mod:DarkBarrage(args)
	self:CDBar(40585, 44)
	if self:Me(args.destGUID) then
		self:PersonalMessage(40585)
		self:PlaySound(40585, "runaway")
	else
		self:TargetMessage(40585, "orange", args.destName)
	end
end

do
	local playerList = {}
	local prev = 0
	function mod:AgonizingFlames(args)
		if args.time - prev > 1 then
			prev = args.time
			playerList = {}
		end
		playerList[#playerList + 1] = args.destName
		self:TargetsMessage(40932, "yellow", playerList, nil, nil, nil, 0.3)
	end
end

do
	local playerList = {}
	local prev = 0
	function mod:ShadowDemon(args)
		if args.time - prev > 2 then
			prev = args.time
			playerList = {}
		end
		playerList[#playerList + 1] = args.destName
		self:TargetsMessage(41117, "red", playerList, nil, nil, nil, 1)
	end
end

function mod:Frenzy(args)
	self:Message(40683, "red")
	self:Bar(40683, 10, CL.other:format(args.spellName, CL.active))
end

function mod:Caged(args)
	self:Message(40695, "green")
	self:Bar(40695, 15, CL.other:format(args.spellName, CL.active))
end

function mod:DrawSoul(args)
	self:Message(40904, "purple")
end

function mod:SummonShadowDemons(args)
	self:Message(41117, "red")
	if not self:Healer() then
		self:PlaySound(41117, "alert") -- DBM: switch (dps)
	end
end

function mod:FlameBurst(args)
	self:Message(41131, "orange")
	flameBursts = flameBursts + 1
	if flameBursts < 3 then
		self:CDBar(41131, 20)
	end
end

function mod:FlameCrash(args)
	if self:Me(args.destGUID) and args.time - prevCrash > 4 then
		prevCrash = args.time
		self:PersonalMessage(40841, "underyou")
		self:PlaySound(40841, "underyou")
	end
end
