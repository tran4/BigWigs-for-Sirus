--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Naxx/ConstructQuarter/Thaddius.lua), draft by tools/dbm2bw
-- Not ported: the Polarity Shift arrows and the health frame of Stalagg/Feugen.
-- Stalagg and Feugen are fought first: their deaths do not win, the pause before Thaddius is covered by the wipe delay.
-- Heroic timers not in DBM, from the players' WeakAuras (WA: "Naxx", their triggers keep Thaddius as the source):
-- Activate Transformers (373418) 80s after the cast, Backlash (373424, 373425, 373578, 373579) 18s after the start of
-- its cast, 373308 30s after the start of its cast; Polarity Shift also by the name (the heroic id may differ).

local mod, CL = BigWigs:NewBoss("Thaddius", 533, 1613)
if not mod then return end
mod:RegisterEnableMob(15928, 15929, 15930) -- Thaddius, Stalagg, Feugen
mod:SetEncounterID(1120)
mod:SetWinMobs(15928)
mod:SetEmulationWipeDelay(15) -- 3.3.5: the coils overload and Thaddius wakes up after Stalagg and Feugen died

--------------------------------------------------------------------------------
-- Locals
--

local currentCharge = nil
local coilsDown = 0
local lastShift = 0

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	engage_trigger = "Stalagg crush you!",
	overload_trigger = "%s overloads!", -- DBM: msg == L.Emote (the raw emote text)
	overload2_trigger = "Tesla Coil overloads!",

	polarity_changed = "Polarity changed",
	polarity_changed_desc = "Show special warning when your polarity changed",
	polarity_changed_icon = 28089,
	polarity_changed_msg = "Polarity changed to %s",
	polarity_same = "Polarity did not change",
	polarity_same_desc = "Show special warning when your polarity did not change",
	polarity_same_icon = 28089,
	negative = "negative",
	positive = "positive",


})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"berserk",
		28089, -- Polarity Shift
		"polarity_changed",
		{"polarity_same", "OFF"},
		28338, -- Magnetic Pull
		373418, -- Activate Transformers (WA, heroic)
		373424, -- Backlash (WA, heroic)
		373308, -- WA, heroic
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "PolarityShift", 28089)
	self:Log("SPELL_CAST_START", "PolarityShiftByName", "*") -- WA: Polarity Shift by the name
	self:Log("SPELL_CAST_START", "Backlash", 373424, 373425, 373578, 373579) -- WA
	self:Log("SPELL_CAST_SUCCESS", "Transformers", 373418) -- WA
	self:Log("SPELL_CAST_START", "Puddle", 373308) -- WA
	self:Log("SPELL_AURA_APPLIED", "BacklashApplied", 373424, 373425, 373578, 373579) -- WA: Backlash on you
	self:RegisterUnitEvent("UNIT_AURA", nil, "player")
	self:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE")
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
end

function mod:OnEngage()
	self:SetStage(1)
	currentCharge = nil
	coilsDown = 0
	lastShift = 0
	self:TankThrow()
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if msg == L.engage_trigger and not self:IsEngaged() then
		self:Engage() -- DBM RegisterCombat("combat_yell")
	end
end

function mod:TankThrow()
	if self:GetStage() == 2 or coilsDown >= 2 then return end
	self:Bar(28338, 20.6)
	self:DelayedMessage(28338, 17.6, "yellow", CL.soon:format(self:SpellName(28338)))
	self.throwTimer = self:ScheduleTimer("TankThrow", 20.6)
end

function mod:PolarityShift(args)
	self:SetStage(2)
	self:CancelTimer(self.throwTimer)
	self:Message(28089, "red", CL.casting:format(args.spellName))
	self:PlaySound(28089, "long")
	self:CastBar(28089, 3)
	self:Bar(28089, 30)
	self:DelayedMessage(28089, 25, "yellow", CL.soon:format(args.spellName))
	lastShift = GetTime()
end

function mod:UNIT_AURA()
	local t = GetTime() - lastShift
	if self:GetStage() ~= 2 or t > 5 or t < 3 then return end
	local charge
	for i = 1, 40 do
		local name, _, icon, count = UnitDebuff("player", i)
		if not name then break end
		if icon == "Interface\\Icons\\Spell_ChargeNegative" then
			if count > 1 then return end
			charge = L.negative
		elseif icon == "Interface\\Icons\\Spell_ChargePositive" then
			if count > 1 then return end
			charge = L.positive
		end
	end
	if charge then
		lastShift = 0
		if charge == currentCharge then
			self:Message("polarity_same", "green", L.polarity_same, L.polarity_same_icon)
			self:PlaySound("polarity_same", "info")
		else
			self:Message("polarity_changed", "blue", L.polarity_changed_msg:format(charge), L.polarity_changed_icon)
			self:PlaySound("polarity_changed", "warning")
		end
		currentCharge = charge
	end
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(_, msg)
	if msg:find(L.overload_trigger, nil, true) or msg:find(L.overload2_trigger, nil, true) then
		coilsDown = coilsDown + 1
		if coilsDown == 2 then
			self:CancelTimer(self.throwTimer)
			self:StopBar(28338)
			self:CancelDelayedMessage(CL.soon:format(self:SpellName(28338)))
			self:Berserk(365)
		end
	end
end

--------------------------------------------------------------------------------
-- Heroic (WA: "Naxx")
--

function mod:PolarityShiftByName(args)
	if args.spellId ~= 28089 and args.spellName == self:SpellName(28089) then -- Polarity Shift with another id
		self:PolarityShift(args)
	end
end

function mod:Backlash(args)
	self:Message(373424, "orange", CL.casting:format(args.spellName))
	self:CDBar(373424, 18)
end

do
	local prev = 0
	function mod:Transformers(args)
		if args.time - prev > 5 then
			prev = args.time
			self:Message(373418, "yellow")
			self:PlaySound(373418, "info")
			self:CDBar(373418, 80)
		end
	end
end

function mod:Puddle(args)
	self:Message(373308, "orange", CL.casting:format(args.spellName))
	self:CDBar(373308, 30)
end

function mod:BacklashApplied(args)
	if self:Me(args.destGUID) then
		self:PersonalMessage(373424)
		self:PlaySound(373424, "alarm")
	end
end
