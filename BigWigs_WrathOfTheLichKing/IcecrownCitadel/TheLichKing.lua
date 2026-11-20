--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Icecrown/TheFrozenThrone/LichKing.lua), draft by tools/dbm2bw
-- Not ported: the Val'kyr targets frame, arrows, removing immunities, raid chat announces.

local mod, CL = BigWigs:NewBoss("The Lich King", 631, 1636)
if not mod then return end
mod:RegisterEnableMob(36597)
mod:SetEncounterID(856)

--------------------------------------------------------------------------------
-- Locals
--

local intermission = false
local ragingSpiritCount = 0
local stage2Warned, stage3Warned = false, false
local prevValkyr = 0
local valkyrIcon = 2
local grabbed = {} -- [unit] = true
local valkyrsToMark = {} -- [guid] = true, marking by target events
local valkyrLowWarned = {} -- [guid] = true
local spheres = {} -- [guid] = true
local shriekers = {} -- 3.3.5: [guid] = true, the living Raging Spirits that used Soul Shriek (DBM: a bar per spirit)
local prevWinter, prevDefileDamage, prevRestoreSoul = 0, 0, 0

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	warmup_trigger = "So the Light's vaunted justice has finally arrived? Shall I lay down Frostmourne and throw myself at your mercy, Fordring?",

	roleplay = "Roleplay",
	valkyr_grabbed = "%s has been grabbed!",
	valkyr_you = "You have been grabbed",
	valkyr_low = "Valkyr below 55%",
	plague_jump = "Necrotic Plague jumped to %s",
})
mod:SetChatEnableTriggers(L.warmup_trigger) -- 3.3.5: enable the module on the warmup yell/emote (no target yet)

--------------------------------------------------------------------------------
-- Initialization
--

local plagueMarker = mod:AddMarkerOption(true, "player", 5, 70337, 5)
local trapMarker = mod:AddMarkerOption(true, "player", 8, 73539, 8)
local defileMarker = mod:AddMarkerOption(true, "player", 8, 72762, 8)
local valkyrMarker = mod:AddMarkerOption(true, "npc", 2, 71844, 2, 3, 4)
local harvestMarker = mod:AddMarkerOption(false, "player", 6, 68980, 6)
local ragingSpiritMarker = mod:AddMarkerOption(false, "player", 7, 69200, 7)
function mod:GetOptions()
	return {
		"warmup",
		"stages",
		"berserk",
		-- Stage One
		70372, -- Shambling Horror
		70358, -- Drudge Ghouls
		{72143, "TANK"}, -- Enrage
		{28747, "OFF"}, -- Frenzy
		70337, -- Necrotic Plague
		plagueMarker,
		70541, -- Infest
		{73539, "SAY"}, -- Shadow Trap
		trapMarker,
		-- Stage Two
		71844, -- Val'kyr Shadowguard
		valkyrMarker,
		{72762, "SAY"}, -- Defile
		defileMarker,
		{69409, "TANK_HEALER"}, -- Soul Reaper
		-- Stage Three
		70498, -- Vile Spirits
		68980, -- Harvest Soul
		harvestMarker,
		73654, -- Harvest Souls
		73650, -- Restore Soul
		-- Intermission
		68981, -- Remorseless Winter
		{72133, "PROXIMITY"}, -- Pain and Suffering
		69200, -- Raging Spirit
		ragingSpiritMarker,
		69242, -- Soul Shriek
		69103, -- Ice Sphere
		72262, -- Quake
		72350, -- Fury of Frostmourne
	}, {
		[70372] = CL.stage:format(1),
		[71844] = CL.stage:format(2),
		[70498] = CL.stage:format(3),
		[68981] = CL.intermission,
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "RemorselessWinter", 68981, 74270, 74271, 74272, 72259, 74273, 74274, 74275)
	self:Log("SPELL_DAMAGE", "RemorselessWinterDamage", 68983, 73791, 73792, 73793)
	self:Log("SPELL_MISSED", "RemorselessWinterDamage", 68983, 73791, 73792, 73793)
	self:Log("SPELL_CAST_START", "Quake", 72262)
	self:Log("SPELL_CAST_START", "ShamblingHorror", 70372)
	self:Log("SPELL_CAST_START", "DrudgeGhouls", 70358)
	self:Log("SPELL_CAST_START", "Enrage", 72143, 72146, 72147, 72148)
	self:Log("SPELL_AURA_APPLIED", "Frenzy", 28747)
	self:Log("SPELL_CAST_START", "VileSpirits", 70498)
	self:Log("SPELL_CAST_START", "Infest", 70541, 73779, 73780, 73781)
	self:Log("SPELL_CAST_START", "Defile", 72762)
	self:Log("SPELL_AURA_APPLIED", "DefileDamage", 72754, 73708, 73709, 73710)
	self:Log("SPELL_CAST_START", "ShadowTrap", 73539)
	self:Log("SPELL_CAST_START", "RestoreSoul", 73650)
	self:Log("SPELL_AURA_APPLIED", "RestoreSoulApplied", 73650)
	self:Log("SPELL_CAST_START", "FuryOfFrostmourne", 72350)
	self:Log("SPELL_CAST_START", "SoulShriek", 69242, 73800, 73801, 73802)
	self:Death("RagingSpiritDeath", 36701) -- 3.3.5: DBM cancels the Soul Shriek timer on the spirit's death
	self:Log("SPELL_CAST_SUCCESS", "NecroticPlague", 70337, 73912, 73913, 73914)
	self:Log("SPELL_AURA_APPLIED", "NecroticPlagueJump", 70338, 73785, 73786, 73787)
	self:Log("SPELL_DISPEL", "NecroticPlagueDispelled", 70337, 73912, 73913, 73914, 70338, 73785, 73786, 73787)
	self:Log("SPELL_CAST_SUCCESS", "SoulReaper", 69409, 73797, 73798, 73799)
	self:Log("SPELL_CAST_SUCCESS", "RagingSpirit", 69200)
	self:Log("SPELL_CAST_SUCCESS", "HarvestSoul", 68980, 74325, 74326, 74327)
	self:Log("SPELL_CAST_SUCCESS", "HarvestSouls", 73654, 74295, 74296, 74297)
	self:Log("SPELL_SUMMON", "SummonValkyr", 69037)
	self:RegisterUnitEvent("UNIT_HEALTH", nil, "target", "focus")
	self:RegisterEvent("UNIT_TARGET")
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
end

function mod:OnEngage()
	shriekers = {}
	intermission = false
	ragingSpiritCount = 0
	stage2Warned, stage3Warned = false, false
	valkyrLowWarned = {}
	spheres = {}
	self:StopBar(CL.active)
	self:SetStage(1)
	self:SetEmulationWipeDelay(3)
	-- 15 minutes on the x1 realm, 17 elsewhere (DBM Sirus)
	self:Berserk(BigWigsLoader.Compat.GetRealmNumber() == 1 and 900 or 1020)
	self:DelayedMessage(70372, 15, "yellow", CL.soon:format(self:SpellName(70372)))
	self:Bar(70372, 20)
	self:Bar(70358, 10)
	if self:Heroic() then
		self:Bar(73539, 15.5)
		self:Bar(70337, 30)
	else
		self:Bar(70337, 27)
	end
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if msg:find(L.warmup_trigger, nil, true) then
		self:Bar("warmup", 55, CL.active, "inv_misc_pocketwatch_01")
	end
end

function mod:StopStageBars()
	self:CancelDelayedMessage(CL.soon:format(self:SpellName(70372)))
	self:CancelDelayedMessage(CL.soon:format(self:SpellName(72762)))
	self:StopBar(70372)
	self:StopBar(70358)
	self:StopBar(71844)
	self:StopBar(70541)
	self:StopBar(70337)
	self:StopBar(73539)
	self:StopBar(72762)
	self:StopBar(69409)
end

function mod:NewStage(stage)
	self:SetStage(stage)
	self:Message("stages", "cyan", CL.stage:format(stage), false)
	self:PlaySound("stages", "long")
	if stage == 2 then
		self:CDBar(71844, 18.5)
		self:Bar(69409, 40)
		self:Bar(72762, 37.5)
		self:Bar(70541, 14)
		self:DelayedMessage(72762, 33, "orange", CL.soon:format(self:SpellName(72762)))
	else
		self:Bar(70498, 17)
		self:Bar(69409, 37.5)
		self:Bar(72762, 33.5)
		self:Bar(68980, 14)
		self:DelayedMessage(72762, 30, "orange", CL.soon:format(self:SpellName(72762)))
	end
end

-- Intermission

function mod:RemorselessWinter(args)
	intermission = true
	ragingSpiritCount = 1
	self:Message(68981, "orange")
	self:PlaySound(68981, "long")
	self:Bar(72262, 62.5) -- the intermission ends with Quake
	self:Bar(69200, 6, CL.count:format(self:SpellName(69200), ragingSpiritCount))
	self:StopStageBars()
	self:OpenProximity(72133, 8)
end

function mod:RemorselessWinterDamage(args)
	if self:Me(args.destGUID) and args.time - prevWinter > 2 then
		prevWinter = args.time
		self:PersonalMessage(68981, "underyou")
		self:PlaySound(68981, "underyou")
	end
end

function mod:Quake(args)
	intermission = false
	self:Message(72262, "red")
	self:PlaySound(72262, "alarm")
	self:StopBar(CL.count:format(self:SpellName(69200), ragingSpiritCount))
	ragingSpiritCount = 0
	self:CloseProximity(72133)
	self:NewStage(self:GetStage() + 1)
end

function mod:RagingSpirit(args)
	self:StopBar(CL.count:format(args.spellName, ragingSpiritCount))
	ragingSpiritCount = ragingSpiritCount + 1
	self:CDBar(69242, 20)
	if self:Me(args.destGUID) then
		self:PersonalMessage(69200)
		self:PlaySound(69200, "warning")
	else
		self:TargetMessage(69200, "yellow", args.destName)
	end
	self:CDBar(69200, self:GetStage() == 1 and 20 or 17, CL.count:format(args.spellName, ragingSpiritCount))
	self:CustomIcon(ragingSpiritMarker, args.destName, 7)
	self:ScheduleTimer("CustomIcon", 5, ragingSpiritMarker, args.destName)
end

function mod:SoulShriek(args)
	shriekers[args.sourceGUID] = true
	self:CDBar(69242, 12)
end

function mod:RagingSpiritDeath(args)
	-- 3.3.5: one bar for all spirits (DBM: a bar per spirit), it stayed at 0 after the last spirit died
	shriekers[args.destGUID] = nil
	if not next(shriekers) then
		self:StopBar(69242)
	end
end

function mod:UNIT_TARGET(_, unit)
	if not intermission then return end
	local target = unit .. "target"
	local guid = self:UnitGUID(target)
	if guid and not spheres[guid] and self:MobId(guid) == 36633 then -- Ice Sphere
		local name = self:UnitName(target .. "target")
		if name then
			spheres[guid] = true
			if name == self:UnitName("player") then
				self:PersonalMessage(69103)
				self:PlaySound(69103, "alarm")
			else
				self:TargetMessage(69103, "yellow", name)
			end
		end
	end
end

-- Stage One

function mod:ShamblingHorror(args)
	self:Message(70372, "yellow")
	self:DelayedMessage(70372, 55, "yellow", CL.soon:format(args.spellName))
	self:Bar(70372, 60)
end

function mod:DrudgeGhouls(args)
	self:Message(70358, "yellow")
	self:Bar(70358, 30)
end

function mod:Enrage(args)
	self:Message(72143, "orange", CL.other:format(args.spellName, args.sourceName))
	if self:Tank() then
		self:PlaySound(72143, "alarm")
	end
	self:CDBar(72143, 20)
end

function mod:Frenzy(args)
	self:Message(28747, "red")
end

function mod:NecroticPlague(args) -- no SPELL_AURA_APPLIED for the cast
	self:TargetMessage(70337, "orange", args.destName)
	self:Bar(70337, 30)
	self:TargetBar(70337, 5, args.destName) -- cleanse before the first tick
	if self:Me(args.destGUID) then
		self:PlaySound(70337, "warning")
	end
	self:CustomIcon(plagueMarker, args.destName, 5)
	self:ScheduleTimer("CustomIcon", 5, plagueMarker, args.destName)
end

function mod:NecroticPlagueJump(args)
	-- 3.3.5: DBM detects the jumps with UNIT_AURA, check in game that this event fires
	self:Message(70337, "orange", L.plague_jump:format(self:ColorName(args.destName)))
	self:TargetBar(70337, 5, args.destName)
	if self:Me(args.destGUID) and not self:Tank() then
		self:PlaySound(70337, "warning")
	end
	self:CustomIcon(plagueMarker, args.destName, 5)
end

function mod:NecroticPlagueDispelled(args)
	self:CustomIcon(plagueMarker, args.destName)
end

function mod:Infest(args)
	self:Message(70541, "orange")
	if self:Healer() then
		self:PlaySound(70541, "alert")
	end
	self:Bar(70541, 22.5)
end

do
	local function printTrap(self, name, guid)
		self:TargetMessage(73539, "red", name)
		self:CustomIcon(trapMarker, name, 8)
		self:ScheduleTimer("CustomIcon", 4, trapMarker, name)
		if self:Me(guid) then
			self:PlaySound(73539, "warning")
			self:Say(73539)
		else
			local unit = self:UnitTokenFromGUID(guid)
			if unit and CheckInteractDistance(unit, 2) then
				self:PlaySound(73539, "alarm")
			end
		end
	end
	function mod:ShadowTrap(args)
		self:GetUnitTarget(printTrap, 0.4, args.sourceGUID)
		self:Bar(73539, 15.5)
	end
end

-- Stage Two

function mod:MarkValkyrs(_, unit, guid)
	if valkyrsToMark[guid] == nil and self:MobId(guid) == 36609 and valkyrIcon <= 4 then -- Val'kyr Shadowguard
		valkyrsToMark[guid] = true
		self:CustomIcon(valkyrMarker, unit, valkyrIcon)
		valkyrIcon = valkyrIcon + 1
	end
end

function mod:ScanGrabbed(startTime)
	for unit in self:IterateGroup() do
		if UnitInVehicle(unit) and not grabbed[unit] then
			grabbed[unit] = true
			local name = self:UnitName(unit)
			if UnitIsUnit(unit, "player") then
				self:Message(71844, "blue", L.valkyr_you)
				self:PlaySound(71844, "warning")
			else
				self:Message(71844, "orange", L.valkyr_grabbed:format(self:ColorName(name)))
			end
		end
	end
	if GetTime() - startTime < 10 then -- scan for 10 seconds
		self:ScheduleTimer("ScanGrabbed", 0.5, startTime)
	end
end

function mod:SummonValkyr(args)
	local t = GetTime()
	if t - prevValkyr > 15 then -- 3 summons at once on 25 player
		prevValkyr = t
		grabbed = {}
		valkyrIcon = 2
		valkyrsToMark = {}
		self:Message(71844, "orange")
		self:CDBar(71844, 45)
		self:ScanGrabbed(t)
		if self:GetOption(valkyrMarker) then
			self:RegisterTargetEvents("MarkValkyrs")
		end
	end
end

do
	local function printDefile(self, name, guid)
		self:TargetMessage(72762, "red", name)
		self:CustomIcon(defileMarker, name, 8)
		self:ScheduleTimer("CustomIcon", 4, defileMarker, name)
		if self:Me(guid) then
			self:PlaySound(72762, "warning") -- run out
			self:Say(72762)
		else
			local unit = self:UnitTokenFromGUID(guid)
			if unit and CheckInteractDistance(unit, 2) then
				self:Message(72762, "orange", CL.near:format(self:SpellName(72762)))
				self:PlaySound(72762, "alarm")
			end
		end
	end
	function mod:Defile(args)
		self:GetUnitTarget(printDefile, 0.1, args.sourceGUID)
		self:DelayedMessage(72762, 27, "orange", CL.soon:format(args.spellName))
		self:Bar(72762, 32.5)
	end
end

function mod:DefileDamage(args)
	if self:Me(args.destGUID) and args.time - prevDefileDamage > 2 then
		prevDefileDamage = args.time
		self:PersonalMessage(72762, "underyou")
		self:PlaySound(72762, "underyou")
	end
end

function mod:SoulReaper(args)
	self:TargetMessage(69409, "purple", args.destName)
	self:TargetBar(69409, 5.1, args.destName)
	self:Bar(69409, 30.5)
	if self:Me(args.destGUID) then
		self:PlaySound(69409, "alarm") -- defensive
	elseif self:Tank() then
		self:PlaySound(69409, "warning") -- taunt
	end
end

-- Stage Three

function mod:VileSpirits(args)
	self:Message(70498, "yellow")
	self:Bar(70498, 30.5)
end

function mod:HarvestSoul(args)
	self:TargetBar(68980, 6, args.destName)
	self:Bar(68980, 75)
	if self:Me(args.destGUID) then
		self:PersonalMessage(68980)
		self:PlaySound(68980, "warning")
	else
		self:TargetMessage(68980, "yellow", args.destName)
	end
	self:CustomIcon(harvestMarker, args.destName, 6)
	self:ScheduleTimer("CustomIcon", 5, harvestMarker, args.destName)
end

function mod:HarvestSouls(args) -- heroic, the whole raid goes into Frostmourne
	self:Message(73654, "red")
	self:PlaySound(73654, "long")
	self:Bar(68980, 107)
	self:StopBar(70498)
	self:StopBar(69409)
	self:StopBar(72762)
	self:CancelDelayedMessage(CL.soon:format(self:SpellName(72762)))
	-- 3.3.5: keep the module while players outside are dead (DBM SetWipeTime(50))
	self:SetEmulationWipeDelay(50)
	self:ScheduleTimer("SetEmulationWipeDelay", 50, 3)
end

function mod:RestoreSoul(args)
	self:Message(73650, "yellow", CL.casting:format(args.spellName))
	self:CastBar(73650, 40)
end

function mod:RestoreSoulApplied(args)
	if args.time - prevRestoreSoul > 3 then
		prevRestoreSoul = args.time
		self:Bar(68980, 60)
		self:Bar(70498, 10)
	end
end

function mod:FuryOfFrostmourne(args)
	-- the raid dies and the fight ends after the roleplay
	self:SetEmulationWipeDelay(190) -- DBM SetWipeTime(190)
	self:Message(72350, "red")
	self:StopStageBars()
	self:StopBar(68980)
	self:StopBar(70498)
	self:StopBerserk(self:SpellName(26662)) -- the Berserk bar text
	local t = (self:Difficulty() == 6 or BigWigsLoader.Compat.GetRealmNumber() ~= 4) and 162 or 97
	self:Bar(72350, t, L.roleplay)
end

-- Health

function mod:UNIT_HEALTH(_, unit)
	local guid = self:UnitGUID(unit)
	local mobId = self:MobId(guid)
	if mobId == 36609 and self:Heroic() and not valkyrLowWarned[guid] and self:GetHealth(unit) <= 55 then -- Val'kyr Shadowguard
		valkyrLowWarned[guid] = true
		self:Message(71844, "red", L.valkyr_low)
		self:PlaySound(71844, "alarm") -- stop attacking
	elseif mobId == 36597 then
		local hp = self:GetHealth(unit)
		local stage = self:GetStage()
		if stage == 1 and not stage2Warned and hp <= 73 then
			stage2Warned = true
			self:Message("stages", "cyan", CL.soon:format(CL.stage:format(2)), false)
		elseif stage == 2 and not stage3Warned and hp <= 43 then
			stage3Warned = true
			self:Message("stages", "cyan", CL.soon:format(CL.stage:format(3)), false)
		end
	end
end
