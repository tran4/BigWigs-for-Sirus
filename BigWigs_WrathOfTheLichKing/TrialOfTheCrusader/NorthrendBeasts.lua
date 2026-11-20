--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Coliseum/NorthrendBeasts.lua), draft by tools/dbm2bw
-- Not ported: the DBM arrow and the minimap ping for Icehowl's charge.

local mod, CL = BigWigs:NewBoss("The Northrend Beasts", 649, 1618)
if not mod then return end
mod:RegisterEnableMob(34796, 35144, 34799, 34797) -- Gormok, Acidmaw, Dreadscale, Icehowl
mod:SetEncounterID(629)
mod:SetWinMobs(34797) -- 3.3.5: won when Icehowl dies (the beasts come one after another)
mod:SetEmulationWipeDelay(20) -- the next beast arrives a few seconds after the previous one died

--------------------------------------------------------------------------------
-- Locals
--

local dreadscaleActive = true -- Dreadscale is the mobile worm first
local acidmawDead, dreadscaleDead = false, false
local toxinList, bileList = {}, {}
local prevToxin, prevBile = 0, 0
local bileIcon = 1
local prevFireBomb, prevSlimePool = 0, 0

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	warmup_trigger = "Hailing from the deepest, darkest caverns of the Storm Peaks, Gormok the Impaler! Battle on, heroes!",
	stage2_trigger = "Steel yourselves, heroes, for the twin terrors, Acidmaw and Dreadscale, enter the arena!",
	stage3_trigger = "The air itself freezes with the introduction of our next combatant, Icehowl! Kill or be killed, champions!",
	charge_trigger = "^%%s glares at (%S+) and lets out",

	gormok = "Gormok the Impaler",
	acidmaw = "Acidmaw",
	dreadscale = "Dreadscale",
	icehowl = "Icehowl",

	next_boss = "Next boss",
	next_boss_desc = "Show timer for next boss spawn",
	next_boss_icon = 2457,

	snobold = "Snobold Vassal spawned on %s",
	snobold_desc = "Show warning for Snobold Vassal spawns",
	snobold_icon = 66636,

	submerge = "Submerge",
	submerge_desc = "Show timer for submerge",
	submerge_icon = "misc_arrowdown",
	emerge = "Emerge",
	emerge_desc = "Show timer for emerge",
	emerge_icon = "misc_arrowlup",
})
mod:SetChatEnableTriggers(L.warmup_trigger) -- 3.3.5: enable the module on the warmup yell/emote (no target yet)

--------------------------------------------------------------------------------
-- Initialization
--

local chargeMarker = mod:AddMarkerOption(true, "player", 8, 52311, 8)
local bileMarker = mod:AddMarkerOption(false, "player", 1, 66869, 1, 2, 3, 4, 5, 6, 7, 8)
function mod:GetOptions()
	return {
		"warmup",
		"stages",
		"next_boss",
		"berserk",
		"proximity",
		-- Gormok the Impaler
		{66331, "TANK_HEALER"}, -- Impale
		66330, -- Staggering Stomp
		{66317, "OFF"}, -- Fire Bomb
		"snobold",
		{66636, "TANK_HEALER"}, -- Rising Anger
		-- Acidmaw and Dreadscale
		"submerge",
		"emerge",
		66794, -- Sweep
		66883, -- Slime Pool
		{66819, "TANK"}, -- Acidic Spew
		{66820, "TANK"}, -- Molten Spew
		66901, -- Paralytic Spray
		66823, -- Paralytic Toxin
		66902, -- Burning Spray
		66869, -- Burning Bile
		bileMarker,
		66824, -- Paralytic Bite
		66879, -- Burning Bite
		68335, -- Enrage
		-- Icehowl
		52311, -- Charge
		chargeMarker,
		66683, -- Massive Crash
		66758, -- Staggered Daze
		{66689, "TANK_HEALER"}, -- Arctic Breath
		{67657, "DISPEL"}, -- Frothing Rage
	}, {
		[66331] = L.gormok,
		["submerge"] = L.acidmaw .. ", " .. L.dreadscale,
		[52311] = L.icehowl,
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "Impale", 67477, 66331, 67478, 67479)
	self:Log("SPELL_AURA_APPLIED_DOSE", "ImpaleDose", 67477, 66331, 67478, 67479)
	self:Log("SPELL_CAST_START", "StaggeringStomp", 66330, 67647, 67648, 67649)
	self:Log("SPELL_CAST_START", "FireBomb", 66313)
	self:Log("SPELL_DAMAGE", "FireBombDamage", 66320, 67472, 67473, 67475, 66317)
	self:Log("SPELL_MISSED", "FireBombDamage", 66320, 67472, 67473, 67475, 66317)
	self:Log("SPELL_AURA_APPLIED", "RisingAnger", 66636)
	self:Log("SPELL_AURA_APPLIED_DOSE", "RisingAngerDose", 66636)
	self:Log("SPELL_CAST_START", "Sweep", 66794, 67644, 67645, 67646)
	self:Log("SPELL_CAST_SUCCESS", "SlimePool", 67641, 66883, 67642, 67643)
	self:Log("SPELL_DAMAGE", "SlimePoolDamage", 66881, 67638, 67639, 67640)
	self:Log("SPELL_MISSED", "SlimePoolDamage", 66881, 67638, 67639, 67640)
	self:Log("SPELL_CAST_START", "MoltenSpew", 66821)
	self:Log("SPELL_CAST_START", "AcidicSpew", 66818)
	self:Log("SPELL_CAST_START", "ParalyticSpray", 66901, 67615, 67616, 67617)
	self:Log("SPELL_CAST_START", "BurningSpray", 66902, 67627, 67628, 67629)
	self:Log("SPELL_CAST_SUCCESS", "ParalyticBite", 66824, 67612, 67613, 67614)
	self:Log("SPELL_CAST_SUCCESS", "BurningBite", 66879, 67624, 67625, 67626)
	self:Log("SPELL_AURA_APPLIED", "ParalyticToxin", 66823, 67618, 67619, 67620)
	self:Log("SPELL_AURA_APPLIED", "BurningBile", 66869)
	self:Log("SPELL_AURA_REMOVED", "BurningBileRemoved", 66869)
	self:Log("SPELL_AURA_APPLIED", "Enrage", 68335)
	self:Log("SPELL_CAST_START", "ArcticBreath", 66689, 67650, 67651, 67652)
	self:Log("SPELL_AURA_APPLIED", "FrothingRage", 67657, 66759, 67658, 67659)
	self:Log("SPELL_AURA_APPLIED", "StaggeredDaze", 66758)
	self:Death("GormokDeath", 34796)
	self:Death("AcidmawDeath", 35144)
	self:Death("DreadscaleDeath", 34799)
	self:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE")
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
end

function mod:OnEngage()
	dreadscaleActive = true
	acidmawDead, dreadscaleDead = false, false
	toxinList, bileList = {}, {}
	bileIcon = 1
	self:SetStage(1)
	self:StopBar(CL.active)
	self:DelayedMessage(66330, 14, "orange", CL.soon:format(self:SpellName(66330)), nil, "alert")
	if self:Heroic() then
		self:Bar("next_boss", 152, L.next_boss, L.next_boss_icon)
		self:ScheduleTimer("Bar", 147, "next_boss", 190, L.next_boss, L.next_boss_icon)
		self:Bar(66636, 18)
	else
		self:Bar(66636, 27)
	end
	self:Bar(66330, 15)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if msg:find(L.warmup_trigger, nil, true) then
		self:Bar("warmup", 16.5, CL.active, "inv_misc_pocketwatch_01")
	elseif msg:find(L.stage2_trigger, nil, true) then
		self:SetStage(2)
		self:Message("stages", "cyan", CL.stage:format(2), false)
		self:Bar("warmup", 11, CL.active, "inv_misc_pocketwatch_01")
		self.wormTimer = self:ScheduleTimer("WormsEmerge", 13.5)
		self:OpenProximity("proximity", 10)
	elseif msg:find(L.stage3_trigger, nil, true) then
		self:SetStage(3)
		self:Message("stages", "cyan", CL.stage:format(3), false)
		if self:Heroic() then
			self:Berserk(223)
		end
		self:CancelTimer(self.wormTimer)
		self:Bar("warmup", 5, CL.active, "inv_misc_pocketwatch_01")
		self:CDBar(66683, 51)
		self:StopBar(L.next_boss)
		self:StopBar(L.submerge)
		self:StopBar(L.emerge)
		self:CloseProximity("proximity")
	end
end

-- Gormok the Impaler

function mod:Impale(args)
	self:Bar(66331, 10)
	self:StackMessage(66331, "purple", args.destName, 1, 3)
end

function mod:ImpaleDose(args)
	local amount = args.amount or 1
	self:Bar(66331, 10)
	if amount >= 3 or (amount >= 2 and self:Heroic()) then
		self:StackMessage(66331, "purple", args.destName, amount, 2)
		if self:Me(args.destGUID) then
			self:PlaySound(66331, "alarm")
		end
	end
end

function mod:StaggeringStomp(args)
	-- 13.5 seconds on the x5 realm (DBM Sirus)
	self:Bar(66330, BigWigsLoader.Compat.GetRealmNumber() == 5 and 13.5 or 15)
	self:DelayedMessage(66330, 19, "orange", CL.soon:format(args.spellName), nil, "alert") -- ~1.5 seconds before the next
end

function mod:FireBomb(args)
	self:Message(66317, "orange")
end

function mod:FireBombDamage(args)
	if self:Me(args.destGUID) and args.time - prevFireBomb > 2 then
		prevFireBomb = args.time
		self:PersonalMessage(66317, "underyou")
		self:PlaySound(66317, "underyou")
	end
end

function mod:RisingAnger(args)
	self:Message("snobold", "orange", L.snobold:format(self:ColorName(args.destName)), L.snobold_icon)
	self:Bar(66636, 20.5)
end

function mod:RisingAngerDose(args)
	local amount = args.amount or 1
	self:Message("snobold", "orange", L.snobold:format(self:ColorName(args.destName)), L.snobold_icon)
	if amount < 3 then
		self:Bar(66636, 20.5)
	else
		self:StackMessage(66636, "purple", args.destName, amount, 3)
		self:PlaySound(66636, "alarm")
	end
end

function mod:GormokDeath()
	self:CancelDelayedMessage(CL.soon:format(self:SpellName(66330)))
	self:StopBar(66330)
	self:StopBar(66331)
	self:StopBar(66636)
end

-- Acidmaw and Dreadscale

function mod:StopWormBars()
	self:StopBar(66794)
	self:StopBar(66883)
	self:StopBar(66820)
	self:StopBar(66901)
	self:StopBar(66879)
	self:StopBar(66819)
	self:StopBar(66902)
	self:StopBar(66824)
end

function mod:WormsEmerge()
	self:Bar("submerge", 45, L.submerge, L.submerge_icon)
	if not acidmawDead then
		if dreadscaleActive then -- Acidmaw is stationary
			self:CDBar(66794, 22)
			self:CDBar(66901, 18)
		else
			self:CDBar(66883, 14)
			self:CDBar(66824, 5)
			self:CDBar(66819, 10)
		end
	end
	if not dreadscaleDead then
		if dreadscaleActive then -- Dreadscale is mobile
			self:CDBar(66883, 15)
			self:CDBar(66820, 26)
			self:CDBar(66879, 5)
		else
			self:CDBar(66794, 16)
			self:CDBar(66902, 17)
		end
	end
	self.wormTimer = self:ScheduleTimer("WormsSubmerge", 45)
end

function mod:WormsSubmerge()
	self:Bar("emerge", 10, L.emerge, L.emerge_icon)
	self:StopWormBars()
	dreadscaleActive = not dreadscaleActive
	self.wormTimer = self:ScheduleTimer("WormsEmerge", 6)
end

function mod:Sweep()
	self:CDBar(66794, 21)
end

function mod:SlimePool(args)
	self:Message(66883, "yellow")
	self:CDBar(66883, 12)
end

function mod:SlimePoolDamage(args)
	if self:Me(args.destGUID) and args.time - prevSlimePool > 2 then
		prevSlimePool = args.time
		self:PersonalMessage(66883, "underyou")
		self:PlaySound(66883, "underyou")
	end
end

function mod:MoltenSpew()
	self:CDBar(66820, 21)
end

function mod:AcidicSpew()
	self:CDBar(66819, 21)
end

function mod:ParalyticSpray()
	self:CDBar(66901, 21)
end

function mod:BurningSpray()
	bileIcon = 1
	self:CDBar(66902, 21)
end

function mod:ParalyticBite()
	self:CDBar(66824, 25)
end

function mod:BurningBite()
	self:CDBar(66879, 15)
end

function mod:ParalyticToxin(args)
	if args.time - prevToxin > 2 then
		toxinList = {}
	end
	prevToxin = args.time
	toxinList[#toxinList + 1] = args.destName
	self:TargetsMessage(66823, "yellow", toxinList, nil, nil, nil, 0.3)
	if self:Me(args.destGUID) then
		self:PlaySound(66823, "warning") -- move to a Burning Bile
	end
end

function mod:BurningBile(args)
	if args.time - prevBile > 2 then
		bileList = {}
	end
	prevBile = args.time
	bileList[#bileList + 1] = args.destName
	self:TargetsMessage(66869, "orange", bileList, nil, nil, nil, 0.3)
	if self:Me(args.destGUID) then
		self:PlaySound(66869, "warning")
	end
	if bileIcon < 9 then
		self:CustomIcon(bileMarker, args.destName, bileIcon)
		bileIcon = bileIcon + 1
	end
end

function mod:BurningBileRemoved(args)
	self:CustomIcon(bileMarker, args.destName)
end

function mod:Enrage(args)
	self:Message(68335, "red")
end

function mod:AcidmawDeath()
	acidmawDead = true
	self:StopBar(66901)
	self:StopBar(66824)
	self:StopBar(66819)
	self:StopBar(dreadscaleActive and 66794 or 66883)
	if dreadscaleDead then
		self:StopBar(L.next_boss)
	end
end

function mod:DreadscaleDeath()
	dreadscaleDead = true
	self:StopBar(66902)
	self:StopBar(66879)
	self:StopBar(66820)
	self:StopBar(dreadscaleActive and 66883 or 66794)
	if acidmawDead then
		self:StopBar(L.next_boss)
	end
end

-- Icehowl

function mod:ArcticBreath(args)
	self:Message(66689, "orange")
	self:CastBar(66689, 5)
end

function mod:FrothingRage(args)
	self:Message(67657, "red")
	if self:Dispeller("enrage", true, 67657) then
		self:PlaySound(67657, "alarm")
	end
end

function mod:StaggeredDaze(args)
	self:Bar(66758, 15)
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(_, msg, _, _, _, target)
	if target and msg:match(L.charge_trigger) then
		self:CDBar(66683, 59)
		if target == self:UnitName("player") then
			self:PersonalMessage(52311)
			self:PlaySound(52311, "alarm") -- run
		else
			self:TargetMessage(52311, "red", target)
			local unit = self:UnitTokenFromGUID(self:UnitGUID(target))
			if unit and CheckInteractDistance(unit, 2) then
				self:PlaySound(52311, "alarm")
			end
		end
		self:CustomIcon(chargeMarker, target, 8)
		self:ScheduleTimer("CustomIcon", 5, chargeMarker, target)
	end
end
