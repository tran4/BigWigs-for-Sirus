--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Icecrown/TheLowerSpire/GunshipBattle.lua), draft by tools/dbm2bw
-- Alliance fights High Overlord Saurfang / Orgrim's Hammer, Horde fights Muradin Bronzebeard / The Skybreaker.

local mod, CL = BigWigs:NewBoss("Icecrown Gunship Battle", 631, 1626)
if not mod then return end
mod:RegisterEnableMob(36939, 37215, 36948, 37540) -- Saurfang, Orgrim's Hammer, Muradin, The Skybreaker
mod:SetEncounterID(847)
mod:SetWinMobs() -- 3.3.5: won by the defeat yell or the victory spell, nobody dies

--------------------------------------------------------------------------------
-- Locals
--

local isAlliance = UnitFactionGroup("player") == "Alliance"
local enemyCommander = isAlliance and 36939 or 36948
local addsIcon = isAlliance and 23334 or 23336
local firstMage = false

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	warmup_trigger_alliance = "Fire up the engines! We got a meetin' with destiny, lads!",
	warmup_trigger_horde = "Rise up, sons and daughters of the Horde! Today we battle a hated enemy of the Horde! LOK'TAR OGAR!",
	adds_trigger_alliance = "Reavers, Sergeants, attack",
	adds_trigger_horde = "Marines, Sergeants, attack",
	mage_trigger_alliance = "We're taking hull damage, get a battle-mage out here to shut down those cannons!",
	mage_trigger_horde = "We're taking hull damage, get a sorcerer out here to shut down those cannons!",
	defeat_trigger_alliance = "Don't say I didn't warn ya, scoundrels! Onward, brothers and sisters!",
	defeat_trigger_horde = "The Alliance falter. Onward to the Lich King!",

	adds = "New adds",
	adds_desc = "Show timer for new adds",
	adds_icon = addsIcon,
	adds_soon = "New adds soon",
})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"warmup",
		"adds",
		69705, -- Below Zero
		{69638, "TANK_HEALER"}, -- Battle Fury
		69652, -- Bladestorm
		69651, -- Wounding Strike
		{71188, "OFF"}, -- Experienced
		{71193, "OFF"}, -- Veteran
		{71195, "OFF"}, -- Elite
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "BelowZero", 69705)
	self:Log("SPELL_AURA_REMOVED", "BelowZeroRemoved", 69705)
	self:Log("SPELL_AURA_APPLIED", "BattleFury", 72306, 69638)
	self:Log("SPELL_AURA_APPLIED_DOSE", "BattleFuryDose", 72306, 69638)
	self:Log("SPELL_AURA_APPLIED", "Bladestorm", 69652)
	self:Log("SPELL_AURA_APPLIED", "WoundingStrike", 69651)
	self:Log("SPELL_AURA_APPLIED", "Rank", 71188, 71193, 71195)
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
	self:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", nil, "boss1", "boss2")
end

function mod:OnEngage()
	firstMage = false
	self:StopBar(CL.active)
	-- first adds might come early or late
	self:Bar("adds", 15, L.adds, addsIcon)
	self:DelayedMessage("adds", 10, "yellow", L.adds_soon, addsIcon)
	self.addsTimer = self:ScheduleTimer("AddsWave", 15)
	self:Bar(69705, isAlliance and 39 or 37) -- depends on the cannon damage, corrected by the yell
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:AddsWave()
	self:CancelTimer(self.addsTimer)
	self:Bar("adds", 60, L.adds, addsIcon)
	self:DelayedMessage("adds", 55, "yellow", L.adds_soon, addsIcon)
	self.addsTimer = self:ScheduleTimer("AddsWave", 60)
end

function mod:Warmup()
	-- 3.3.5: fallback if nothing on the ships was in our combat log yet
	if not self:IsEngaged() and UnitAffectingCombat("player") then
		self:Engage()
	end
end

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if msg:find(L.warmup_trigger_alliance, nil, true) then
		self:Bar("warmup", 47.5, CL.active, "inv_misc_pocketwatch_01")
		self:ScheduleTimer("Warmup", 48.5)
	elseif msg:find(L.warmup_trigger_horde, nil, true) then
		self:Bar("warmup", 45, CL.active, "inv_misc_pocketwatch_01")
		self:ScheduleTimer("Warmup", 46)
	elseif not self:IsEngaged() then
		return
	elseif msg:find(L.adds_trigger_alliance, nil, true) or msg:find(L.adds_trigger_horde, nil, true) then
		self:AddsWave()
	elseif msg:find(L.mage_trigger_alliance, nil, true) or msg:find(L.mage_trigger_horde, nil, true) then
		-- correct the Below Zero timer, it depends on how well the cannons are used
		local alliance = msg:find(L.mage_trigger_alliance, nil, true)
		if not firstMage then
			firstMage = true
			self:Bar(69705, alliance and {5, 39} or {2.5, 37})
		else
			self:Bar(69705, alliance and {5, 35} or {2.5, 35})
		end
	elseif msg:find(L.defeat_trigger_alliance, nil, true) or msg:find(L.defeat_trigger_horde, nil, true) then
		self:Win() -- DBM RegisterKill("yell")
	end
end

function mod:UNIT_SPELLCAST_SUCCEEDED(_, _, _, _, spellName)
	if spellName == self:SpellName(72340) then -- victory
		self:Win()
	end
end

function mod:BelowZero(args)
	self:Message(69705, "red")
	self:PlaySound(69705, "alarm")
end

function mod:BelowZeroRemoved()
	self:Bar(69705, 35)
end

function mod:BattleFury(args)
	if self:MobId(args.destGUID) == enemyCommander then
		self:Bar(69638, 17) -- only a timer for the 1st stack
	end
end

function mod:BattleFuryDose(args)
	if self:MobId(args.destGUID) == enemyCommander then
		if args.amount % 5 == 0 then -- every 5 stacks
			self:StackMessage(69638, "purple", args.destName, args.amount, 99)
		end
		self:Bar(69638, 17)
	end
end

function mod:Bladestorm()
	self:Message(69652, "orange")
	if self:Melee() then
		self:PlaySound(69652, "alarm")
	end
end

function mod:WoundingStrike(args)
	self:TargetMessage(69651, "yellow", args.destName)
end

function mod:Rank(args) -- Experienced / Veteran / Elite
	if args.spellId == 71195 then
		self:TargetMessage(71195, "orange", args.destName)
	elseif args.spellId == 71193 then
		self:TargetMessage(71193, "yellow", args.destName)
	else
		self:TargetMessage(71188, "cyan", args.destName)
	end
end
