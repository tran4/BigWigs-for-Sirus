--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Icecrown/ThePlagueworks/Rotface.lua), draft by tools/dbm2bw
-- Not ported: the DBM arrow to the Big Ooze kiter.

local mod, CL = BigWigs:NewBoss("Rotface", 631, 1630)
if not mod then return end
mod:RegisterEnableMob(36627)
mod:SetEncounterID(850)

--------------------------------------------------------------------------------
-- Locals
--

local infectionIcon = 8
local vileGasList = {}
local prevVileGas = 0
local prevOozeExplosion = 0
local prevRadiating = 0
local prevLittleOoze = 0

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	slime_pipes_trigger1 = "Good news, everyone! I've fixed the poison slime pipes!",
	slime_pipes_trigger2 = "Great news, everyone! The slime is flowing again!",

	ooze_spawn = "Little Ooze spawning",
	ooze_spawn_desc = "Show warning for Little Ooze spawning",
	ooze_spawn_icon = 69674,

	little_ooze = "Little Ooze attacking you - Run Away",
	little_ooze_desc = "Show special warning when you are attacked by Little Ooze",
	little_ooze_icon = 69674,
})

--------------------------------------------------------------------------------
-- Initialization
--

local infectionMarker = mod:AddMarkerOption(true, "player", 8, 69674, 8, 7)
function mod:GetOptions()
	return {
		69789, -- Ooze Flood
		69508, -- Slime Spray
		69674, -- Mutated Infection
		infectionMarker,
		"ooze_spawn",
		{"little_ooze", "OFF"},
		{69774, "TANK"}, -- Sticky Ooze
		69760, -- Radiating Ooze
		69558, -- Unstable Ooze
		69839, -- Unstable Ooze Explosion
		{72272, "PROXIMITY"}, -- Vile Gas
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "SlimeSpray", 69508)
	self:Log("SPELL_CAST_START", "StickyOoze", 69774)
	self:Log("SPELL_AURA_APPLIED", "StickyOozeApplied", 71208)
	self:Log("SPELL_CAST_START", "UnstableOozeExplosion", 69839)
	self:Log("SPELL_AURA_APPLIED", "RadiatingOoze", 69760)
	self:Log("SPELL_DAMAGE", "RadiatingOozeDamage", 69761, 71212, 73026, 73027)
	self:Log("SPELL_MISSED", "RadiatingOozeDamage", 69761, 71212, 73026, 73027)
	self:Log("SPELL_AURA_APPLIED", "UnstableOoze", 69558)
	self:Log("SPELL_AURA_APPLIED_DOSE", "UnstableOoze", 69558)
	self:Log("SPELL_AURA_APPLIED", "MutatedInfection", 69674, 71224, 73022, 73023)
	self:Log("SPELL_AURA_REMOVED", "MutatedInfectionRemoved", 69674, 71224, 73022, 73023)
	self:Log("SPELL_AURA_APPLIED", "VileGas", 72272, 72273)
	self:Log("SPELL_CAST_SUCCESS", "VileGasSuccess", 72272, 72273)
	self:Log("SWING_DAMAGE", "LittleOozeSwing", "*")
	self:Log("SWING_MISSED", "LittleOozeSwing", "*")
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
end

function mod:OnEngage()
	infectionIcon = 8
	vileGasList = {}
	self:Bar(69789, 9) -- DBM Sirus: 9 seconds on the pull, 25 after
	self.floodTimer = self:ScheduleTimer("OozeFlood", 25)
	self:Bar(69508, 20)
	self:Bar(72272, 29)
	self:OpenProximity(72272, 10)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:OozeFlood()
	-- DBM Sirus: a 25 second bar restarted every 20 seconds
	self:CancelTimer(self.floodTimer)
	if self:IsEngaged() then
		self:Bar(69789, 25)
		self.floodTimer = self:ScheduleTimer("OozeFlood", 20)
	end
end

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if msg:find(L.slime_pipes_trigger1, nil, true) or msg:find(L.slime_pipes_trigger2, nil, true) then
		self:OozeFlood()
	end
end

function mod:SlimeSpray(args)
	self:Message(69508, "orange")
	self:Bar(69508, 21)
end

function mod:StickyOoze(args)
	self:Message(69774, "yellow")
	self:Bar(69774, 16)
end

function mod:StickyOozeApplied(args)
	if self:Me(args.destGUID) then
		self:PersonalMessage(69774, "underyou")
		self:PlaySound(69774, "underyou")
	end
end

function mod:UnstableOozeExplosion(args)
	local t = args.time
	-- ignore a cast that may fire while an ooze is already exploding
	if t - prevOozeExplosion < 4 or t - prevOozeExplosion > 5 then
		self:CastBar(69839, 4)
		self:DelayedMessage(69839, 4, "red", nil, 69839, "alarm")
	end
	prevOozeExplosion = t
end

function mod:RadiatingOoze(args)
	self:Message(69760, "yellow")
end

function mod:RadiatingOozeDamage(args)
	if self:Me(args.destGUID) and not self:Tank() and args.time - prevRadiating > 3 then
		prevRadiating = args.time
		self:PersonalMessage(69760, "underyou")
		self:PlaySound(69760, "underyou")
	end
end

function mod:UnstableOoze(args)
	self:StackMessage(69558, "yellow", args.destName, args.amount or 1, 99)
end

function mod:MutatedInfection(args)
	self:TargetMessage(69674, "orange", args.destName)
	self:TargetBar(69674, 12, args.destName)
	if self:Me(args.destGUID) then
		self:PlaySound(69674, "warning") -- move to the tank
	end
	self:CustomIcon(infectionMarker, args.destName, infectionIcon)
	-- after ~3 minutes 2 players can have it at once, alternate between 2 icons
	infectionIcon = infectionIcon == 8 and 7 or 8
end

function mod:MutatedInfectionRemoved(args)
	self:StopBar(69674, args.destName)
	self:Message("ooze_spawn", "cyan", L.ooze_spawn, L.ooze_spawn_icon)
	self:CustomIcon(infectionMarker, args.destName)
end

function mod:VileGas(args)
	if not self:Player(args.destFlags) then return end
	if args.time - prevVileGas > 5 then
		vileGasList = {}
	end
	prevVileGas = args.time
	vileGasList[#vileGasList + 1] = args.destName
	-- it can take 2.5 seconds to travel to all targets
	self:TargetsMessage(72272, "orange", vileGasList, nil, nil, nil, 2.5)
	if self:Me(args.destGUID) then
		self:PlaySound(72272, "warning")
	end
end

function mod:VileGasSuccess()
	self:Bar(72272, 30)
end

function mod:LittleOozeSwing(args)
	if self:MobId(args.sourceGUID) == 36897 and self:Me(args.destGUID) and args.time - prevLittleOoze > 3 then -- Little Ooze
		prevLittleOoze = args.time
		self:Message("little_ooze", "blue", L.little_ooze, L.little_ooze_icon)
		self:PlaySound("little_ooze", "alarm")
	end
end
