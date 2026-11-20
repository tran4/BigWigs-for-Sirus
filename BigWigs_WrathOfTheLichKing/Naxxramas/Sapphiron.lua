--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Naxx/FrostwyrmLair/Sapphiron.lua), draft by tools/dbm2bw
-- The air phase is found like DBM: a group member targets Sapphiron in combat and he has no target.

local mod, CL = BigWigs:NewBoss("Sapphiron", 533, 1614)
if not mod then return end
mod:RegisterEnableMob(15989)
mod:SetEncounterID(1119)

--------------------------------------------------------------------------------
-- Locals
--

local noTargetTime = 0
local warnedLowHp = false
local isFlying = false
local prevBlizzard = 0

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	breath_trigger = "%s takes a deep breath.", -- DBM: msg == L.EmoteBreath (the raw emote text)

	air = "Air phase",
	air_desc = "Show warnings and timers for the air and ground phases",
	air_icon = "misc_arrowlup",
	air_soon = "Air phase in 10 seconds",
	air_now = "Air phase",
	landed = "Sapphiron landed",
	landing = "Landing",

	low_hp = "Sapphiron can't fly!",
	low_hp_desc = "Special warning for 10% execute phase (cancel air phase)",
	low_hp_icon = "misc_arrowdown",
})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"berserk",
		"air",
		"low_hp",
		28542, -- Life Drain
		{28522, "SAY"}, -- Icebolt
		28524, -- Frost Breath
		28547, -- Chill
		"proximity",
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_SUCCESS", "LifeDrain", 28542, 55665)
	self:Log("SPELL_AURA_APPLIED", "Icebolt", 28522)
	self:Log("SPELL_AURA_APPLIED", "Chill", 55699, 28547)
	self:RegisterEvent("CHAT_MSG_MONSTER_EMOTE", "BreathEmote")
	self:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE", "BreathEmote") -- DBM: used to be a normal emote
end

function mod:OnEngage()
	noTargetTime = 0
	warnedLowHp = false
	isFlying = false
	prevBlizzard = 0
	self:DelayedMessage(28542, 6.5, "yellow", CL.soon:format(self:SpellName(28542)))
	self:CDBar(28542, 12)
	self:DelayedMessage("air", 38.5, "yellow", L.air_soon, L.air_icon)
	self:Bar("air", 48.5, L.air, L.air_icon)
	self:Berserk(900)
	self:ScheduleTimer("OpenProximity", 46, "proximity", 12)
	self.scanTimer = self:ScheduleRepeatingTimer("ScanAir", 0.2)
end

function mod:OnBossDisable()
	self:CancelTimer(self.scanTimer)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:ScanAir()
	local foundBoss, target
	for unit in self:IterateGroup() do
		local unitTarget = unit .. "target"
		if self:MobId(UnitGUID(unitTarget)) == 15989 and UnitAffectingCombat(unitTarget) then
			target = UnitName(unitTarget .. "target")
			foundBoss = true
			if not warnedLowHp and UnitHealth(unitTarget) / UnitHealthMax(unitTarget) < 0.1 then -- DBM: UNIT_HEALTH boss1
				warnedLowHp = true
				self:Message("low_hp", "red", L.low_hp, L.low_hp_icon)
				self:PlaySound("low_hp", "info")
				self:StopBar(L.air)
				self:CancelDelayedMessage(L.air_soon)
			end
			break
		end
	end
	if foundBoss and not target then
		noTargetTime = noTargetTime + 0.2
	elseif foundBoss then
		noTargetTime = 0
	end
	if noTargetTime > 0.5 and not isFlying then
		noTargetTime = 0
		isFlying = true
		self:SimpleTimer(function() isFlying = false end, 60)
		self:StopBar(28542)
		self:StopBar(L.air)
		self:Message("air", "orange", L.air_now, L.air_icon)
		self:PlaySound("air", "long")
		self:Bar("air", 28.5, L.landing, "misc_arrowdown")
	end
end

function mod:BreathEmote(_, msg)
	if msg:find(L.breath_trigger, nil, true) then
		self:CastBar(28524, 8)
		self:Bar("air", 14, L.landing, "misc_arrowdown")
		self:ScheduleTimer("Landing", 14.5)
		self:Message(28524, "red")
		self:PlaySound(28524, "warning")
	end
end

function mod:Landing()
	self:Message("air", "cyan", L.landed, "misc_arrowdown")
	self:DelayedMessage(28542, 5, "yellow", CL.soon:format(self:SpellName(28542)))
	self:CDBar(28542, 10.5)
	if not warnedLowHp then
		self:DelayedMessage("air", 56, "yellow", L.air_soon, L.air_icon)
		self:Bar("air", 66, L.air, L.air_icon)
	end
	self:CloseProximity("proximity")
	self:ScheduleTimer("OpenProximity", 65, "proximity", 12)
end

do
	local playerList = {}
	local prev = 0
	function mod:Icebolt(args)
		if args.time - prev > 0.5 then
			prev = args.time
			playerList = {}
		end
		playerList[#playerList + 1] = args.destName
		self:TargetsMessage(28522, "orange", playerList, nil, nil, nil, 0.5)
		if self:Me(args.destGUID) then
			self:Say(28522)
		end
	end
end

function mod:LifeDrain(args)
	self:Message(28542, "yellow")
	self:DelayedMessage(28542, 18.5, "yellow", CL.soon:format(self:SpellName(28542)))
	self:CDBar(28542, 24)
end

function mod:Chill(args)
	if self:Me(args.destGUID) and args.time - prevBlizzard > 1 then
		prevBlizzard = args.time
		self:PersonalMessage(28547, "underyou")
		self:PlaySound(28547, "underyou")
	end
end
