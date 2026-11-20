--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Magtheridon/Magtheridon.lua, heroic mode with custom spells), draft by tools/dbm2bw
-- DBM-Magtheridon has only a Russian localization: the English defaults are the Russian texts.
-- Not ported: the Mind Exhaustion info frame and the raid chat message for a failed Seal.

local mod, CL = BigWigs:NewBoss("Magtheridon", 544, 1566)
if not mod then return end
mod:RegisterEnableMob(17257)
mod:SetEncounterID(651)

--------------------------------------------------------------------------------
-- Locals
--

local lastQuake = 0
local fakeQuake = false
local warnedSoon, warnedStage3 = false, false
local handTargets = {}

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	-- DBM: no English texts
	engage_trigger = "Я... свободен!",
	stage2_trigger = "Меня так просто не возьмешь! Пусть стены темницы содрогнутся... и падут!",
	pull_trigger_acolytes = "Сдерживающая сила |3-1(%s) начинает ослабевать!",
	pull_trigger_short = "|3-2(%s) удалось почти освободиться от пут!",
	pull = "Активация босса",
})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"warmup",
		"stages",
		"berserk",
		30616, -- Blast Nova
		30572, -- Quake
		36449, -- Debris
		305129, -- heroic: nova
		305131, -- heroic: Seal of Magtheridon
		{305134, "TANK_HEALER"}, -- heroic: Devastating Strike
		{305135, "TANK_HEALER"}, -- heroic: Shattered Armor
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "HeroicNova", 305158, 305159, 305160)
	self:Log("SPELL_CAST_START", "DevastatingStrike", 305134)
	self:Log("SPELL_CAST_START", "BlastNova", 30616)
	self:Log("SPELL_CAST_SUCCESS", "Seal", 305166)
	self:Log("SPELL_CAST_SUCCESS", "QuakeSuccess", 30572)
	self:Log("SPELL_AURA_APPLIED", "SealApplied", 305131)
	self:Log("SPELL_AURA_APPLIED", "ShatteredArmor", 305135)
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
	self:RegisterEvent("CHAT_MSG_MONSTER_EMOTE")
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
	self:RegisterEvent("UNIT_HEALTH")
end

function mod:OnEngage()
	self:SetStage(1)
	self:StopBar(L.pull)
	lastQuake, fakeQuake = 0, false
	warnedSoon, warnedStage3 = false, false
	handTargets = {}
	if self:Heroic() then
		self:CDBar(305129, 80)
		self:CDBar(305131, 15)
		self:CDBar(305134, 15)
	else
		self:Quake(30)
		self:Nova()
		self:Berserk(600)
	end
end

--------------------------------------------------------------------------------
-- Event Handlers
--

-- the emote has the declension codes of the client (|3-1(%s)): the text after the name is enough
local function emoteMatches(msg, trigger)
	return msg:find(trigger, nil, true) or msg:find(trigger:match("%)(.+)$") or trigger, nil, true)
end

function mod:CHAT_MSG_MONSTER_EMOTE(_, msg)
	local realm = BigWigsLoader.Compat.GetRealmNumber()
	if realm == 5 and emoteMatches(msg, L.pull_trigger_short) then
		self:Bar("warmup", 9, L.pull, 305131)
	elseif realm ~= 5 and emoteMatches(msg, L.pull_trigger_acolytes) then
		self:Bar("warmup", 120, L.pull, 305131)
	end
end

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if msg:find(L.engage_trigger, nil, true) then
		if not self:IsEngaged() then self:Engage() end -- DBM RegisterCombat("yell")
	elseif msg:find(L.stage2_trigger, nil, true) and self:IsEngaged() then
		if self:Normal() then
			self:Message(36449, "orange")
			self:CastBar(36449, 16)
			self:ExtendNova(13)
			self:ExtendQuake(13)
		else
			self:StopBar(305129)
		end
	end
end

-- normal: Blast Nova every 60s, Quake every 50s, each Quake delays the Nova by 7s (DBM)
function mod:Nova()
	local nova = self:SpellName(30616)
	self:CDBar(30616, 60)
	self:CancelDelayedMessage(CL.soon:format(nova))
	self:DelayedMessage(30616, 55, "yellow", CL.soon:format(nova))
	self:CancelTimer(self.novaTimer)
	self.novaTimer = self:ScheduleTimer("Nova", 60)
end

function mod:ExtendNova(extendBy)
	local left = self:BarTimeLeft(30616)
	if left <= 0 then return end
	local nova = self:SpellName(30616)
	self:CDBar(30616, left + extendBy)
	self:CancelTimer(self.novaTimer)
	self.novaTimer = self:ScheduleTimer("Nova", left + extendBy)
	if left > 5 then
		self:CancelDelayedMessage(CL.soon:format(nova))
		self:DelayedMessage(30616, left + extendBy - 5, "yellow", CL.soon:format(nova))
	end
end

function mod:Quake(timer)
	self:CDBar(30572, timer or 50)
	self:CancelTimer(self.quakeTimer)
	self.quakeTimer = self:ScheduleTimer("Quake", timer or 50)
	if GetTime() - lastQuake > 10 then
		self:ExtendNova(7)
		lastQuake = GetTime()
	end
end

function mod:ExtendQuake(extendBy)
	local left = self:BarTimeLeft(30572)
	if left <= 0 then return end
	self:CDBar(30572, left + extendBy)
	self:CancelTimer(self.quakeTimer)
	self.quakeTimer = self:ScheduleTimer("Quake", left + extendBy)
end

function mod:QuakeSuccess()
	fakeQuake = true
end

function mod:QuakeFakeDetection()
	if fakeQuake then
		fakeQuake = false
	else
		self:Message(30572, "orange")
		self:Quake()
	end
end

function mod:UNIT_SPELLCAST_SUCCEEDED(_, unit, _, _, spellName)
	if self:MobId(self:UnitGUID(unit)) == 17257 and spellName == self:SpellName(30572) then
		self:ScheduleTimer("QuakeFakeDetection", 0.1)
	end
end

function mod:BlastNova(args)
	self:Message(30616, "red", CL.casting:format(args.spellName))
	self:PlaySound(30616, "long")
	self:Nova()
end

function mod:HeroicNova(args)
	self:Message(305129, "red", CL.casting:format(self:SpellName(305129)))
	self:PlaySound(305129, "long")
	self:CDBar(305129, 80)
	self:CDBar(305134, 15)
end

do
	local function strikeTarget(self, name, guid)
		self:TargetMessage(305134, "purple", name)
		if self:Me(guid) then
			self:PlaySound(305134, "warning")
		end
	end
	function mod:DevastatingStrike(args)
		self:GetUnitTarget(strikeTarget, 0.1, args.sourceGUID)
		self:CDBar(305134, 15)
	end
end

function mod:Seal(args)
	handTargets[#handTargets + 1] = args.destName
	if #handTargets >= 3 then
		self:TargetsMessage(305131, "yellow", handTargets, #handTargets)
		handTargets = {}
	end
	self:CDBar(305131, 15)
end

function mod:SealApplied(args)
	if self:Me(args.destGUID) then
		self:PersonalMessage(305131)
		self:PlaySound(305131, "alarm")
	end
end

function mod:ShatteredArmor(args)
	self:TargetBar(305135, 30, args.destName)
end

function mod:UNIT_HEALTH(_, unit)
	if not self:IsEngaged() or self:MobId(self:UnitGUID(unit)) ~= 17257 then return end
	local hp = self:GetHealth(unit)
	local soon, stage3 = 33, 30
	if self:Heroic() then soon, stage3 = 53, 50 end
	if not warnedSoon and hp <= soon then
		warnedSoon = true
		self:Message("stages", "cyan", CL.soon:format(CL.stage:format(3)), false)
	elseif warnedSoon and not warnedStage3 and hp <= stage3 then
		warnedStage3 = true
		self:SetStage(3)
		self:Message("stages", "cyan", CL.stage:format(3), false)
		self:PlaySound("stages", "long")
	end
end
