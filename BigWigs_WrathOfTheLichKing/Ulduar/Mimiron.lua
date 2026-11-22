--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Ulduar/Mimiron.lua), draft by tools/dbm2bw
-- Not ported: switching the loot method, the health frame.

local mod, CL = BigWigs:NewBoss("Mimiron", 603, 1647)
if not mod then return end
mod:RegisterEnableMob(33670, 33651, 33432) -- Aerial Command Unit, VX-001, Leviathan Mk II
mod:SetEncounterID(754)
mod:SetWinMobs() -- 3.3.5: won by the defeat yell (DBM RegisterKill)
mod:SetEmulationWipeDelay(45) -- the machines are rebuilt between the stages (up to 41 seconds)

--------------------------------------------------------------------------------
-- Locals
--

local hardmode = false
local prevStage = 0
local napalmList = {}
local prevNapalm = 0
local napalmIcon = 7
local spinUpTime = 0

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	engage_trigger = "We haven't much time, friends! You're going to help me test out my latest and greatest creation. Now, before you change your minds, remember that you kind of owe it to me after the mess you made with the XT-002.",
	hardmode_trigger = "Self-destruct sequence initiated.",
	hardmode_trigger2 = "Self-destruct sequence initiated.", -- WA: "Ульда" (Flames Timer Mimiron), the first flames 4s after it
	stage2_trigger = "WONDERFUL! Positively marvelous results! Hull integrity at 98.9 percent! Barely a dent! Moving right along.",
	stage3_trigger = "Thank you, friends! Your efforts have yielded some fantastic data! Now, where did I put-- oh, there it is!",
	stage4_trigger = "Preliminary testing phase complete. Now comes the true test!",
	defeat_trigger = "It would appear that I've made a slight miscalculation. I allowed my mind to be corrupted by the fiend in the prison. overriding my primary directive. All systems seem to be functional now. Clear.",
	loot_pattern = "([^%s]+).*Hitem:(%d+)",

	leviathan = "Leviathan Mk II",
	vx001 = "VX-001",
	aerial = "Aerial Command Unit",

	hardmode = "Hard mode - Self-destruct",
	hardmode_desc = "Show timer for hard mode",
	hardmode_icon = 312812,
	magnetic_core = "%s has Magnetic Core",
	magnetic_core_desc = "Announce Magnetic Core looters",
	magnetic_core_icon = 64444,
	bomb_bot = "Bomb Bot spawned",
})
mod:SetChatEnableTriggers(L.engage_trigger, L.hardmode_trigger, L.hardmode_trigger2) -- 3.3.5: enable on these yells (no target yet)

--------------------------------------------------------------------------------
-- Initialization
--

local napalmMarker = mod:AddMarkerOption(false, "player", 7, 65026, 7, 6, 5, 4, 3, 2, 1)
local plasmaMarker = mod:AddMarkerOption(false, "player", 8, 64529, 8)
function mod:GetOptions()
	return {
		"stages",
		"berserk",
		"hardmode",
		"proximity",
		-- Leviathan Mk II
		{312790, "TANK_HEALER"}, -- Plasma Blast
		plasmaMarker,
		312792, -- Shock Blast
		312789, -- Proximity Mine
		{312788, "HEALER"}, -- Napalm Shell
		napalmMarker,
		-- VX-001
		312794, -- Spinning Up
		63274, -- Laser Barrage
		64402, -- Rocket Strike
		-- Aerial Command Unit
		63811, -- Bomb Bot
		"magnetic_core",
		-- Hard mode
		312803, -- Flames
		312793, -- Flame Suppressant
		64623, -- Frost Bomb
	}, {
		[312790] = L.leviathan,
		[312794] = L.vx001,
		[63811] = L.aerial,
		[312803] = CL.hard,
	}
end

function mod:OnBossEnable()
	hardmode = false -- 3.3.5: reset on the wipe too (the module reboots), see the hard mode yells
	self:Log("SPELL_CAST_START", "ShockBlast", 63631, 312439, 312792)
	self:Log("SPELL_CAST_START", "PlasmaBlast", 64529, 62997, 312437, 312790)
	self:Log("SPELL_AURA_APPLIED", "PlasmaBlastApplied", 64529, 62997, 312437, 312790)
	self:Log("SPELL_CAST_START", "FlameSuppressant", 64570, 312434, 312787)
	self:Log("SPELL_CAST_SUCCESS", "FlameSuppressantSuccess", 65192, 312440, 312793)
	self:Log("SPELL_CAST_START", "FrostBomb", 64623)
	self:Log("SPELL_CAST_SUCCESS", "ProximityMines", 63027, 63667, 63016, 312789)
	self:Log("SPELL_AURA_APPLIED", "NapalmShell", 63666, 65026, 312347, 312435, 312700, 312788)
	self:Log("SPELL_AURA_REMOVED", "NapalmShellRemoved", 63666, 65026, 312347, 312435, 312700, 312788)
	self:Log("SPELL_CAST_SUCCESS", "SpinningUp", 63414, 312794, 312441)
	self:Log("SPELL_AURA_APPLIED", "RocketStrike", 63041, 64402, 64064, 63681, 63036, 65034)
	self:Log("SPELL_CAST_SUCCESS", "RocketStrike", 63041, 64402, 64064, 63681, 63036, 65034)
	self:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", nil, "boss1", "boss2", "boss3", "boss4")
	self:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP", nil, "boss1", "boss2", "boss3", "boss4")
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
	self:RegisterEvent("CHAT_MSG_LOOT")
end

function mod:OnEngage()
	hardmode = false
	prevStage = GetTime()
	napalmList = {}
	napalmIcon = 7
	self:SetStage(1)
	self:Berserk(900)
	self:CDBar(312790, 30)
	self:CDBar(312792, 28)
	self:Bar(312789, 12.5)
	self.mineTimer = self:ScheduleTimer("Mines", 12.5)
	self:OpenProximity("proximity", 6)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:Mines() -- every 38 seconds in stage 1 and 4
	local stage = self:GetStage()
	if stage == 1 or stage == 4 then
		self:Bar(312789, 38)
		self.mineTimer = self:ScheduleTimer("Mines", 38)
	end
end

function mod:Flames() -- hard mode
	self.flamesStarted = true -- 3.3.5: the first flames came, the second hard mode yell doesn't move them any more
	self:Bar(312803, 28)
	self:DelayedMessage(312803, 18, "yellow", CL.soon:format(self:SpellName(312803)))
	self.flamesTimer = self:ScheduleTimer("Flames", 28)
end

function mod:BombBots() -- every 15 seconds in stage 3
	if self:GetStage() == 3 then
		self:Message(63811, "orange", L.bomb_bot)
		self:CDBar(63811, 15)
		self.bombTimer = self:ScheduleTimer("BombBots", 15)
	end
end

function mod:NextStage()
	-- DBM Sirus uses the yells and the ClearAllDebuffs cast, only the first one of them counts
	local t = GetTime()
	if t - prevStage < 10 then return end
	prevStage = t
	local stage = self:GetStage() + 1
	self:SetStage(stage)
	self:Message("stages", "cyan", CL.stage:format(stage), false)
	self:PlaySound("stages", "long")
	if stage == 2 then
		self:StopBar(312792)
		self:StopBar(312789)
		self:StopBar(312793)
		self:StopBar(312790)
		self:CancelTimer(self.mineTimer)
		self:CloseProximity("proximity")
		self:Bar("stages", 41, CL.stage:format(2), "achievement_bg_returnxflags_def_wsg")
		self:CDBar(64402, 63)
		self:Bar(63274, 78)
		if hardmode then
			self:Bar(64623, 94)
		end
	elseif stage == 3 then
		self:StopCastBar(63274)
		self:StopBar(63274)
		self:StopBar(64623)
		self:StopBar(64402)
		self:Bar("stages", 22, CL.stage:format(3), "achievement_bg_returnxflags_def_wsg")
		self:CDBar(63811, 32)
		self.bombTimer = self:ScheduleTimer("BombBots", 32)
	elseif stage == 4 then
		self:CancelTimer(self.bombTimer)
		self:StopBar(63811)
		self:Bar("stages", 27, CL.stage:format(4), "achievement_bg_returnxflags_def_wsg")
		self:Bar(312789, 34)
		self.mineTimer = self:ScheduleTimer("Mines", 34)
		if hardmode then
			self:Bar(64623, 32)
			self:Bar(312803, 28)
		end
		self:CDBar(64402, 50)
		self:Bar(63274, 59.8)
		self:Bar(312792, 81)
	end
end

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if msg:find(L.engage_trigger, nil, true) then
		self:Engage()
	elseif msg:find(L.hardmode_trigger, nil, true) or msg:find(L.hardmode_trigger2, nil, true) then
		-- DBM: the first flames 1.5s after its yell; WA "Ульда": 4s after "Отсчет времени до самоуничтожения начат." (Russian
		-- DBM has another, long yell; in the game only the WA countdown showed, user's report)
		local flamesIn = msg:find(L.hardmode_trigger, nil, true) and 1.5 or 4
		if hardmode then -- the second of the two yells: only the time to the first flames
			if not self.flamesStarted then
				self:CancelTimer(self.flamesTimer)
				self:Bar(312803, flamesIn)
				self.flamesTimer = self:ScheduleTimer("Flames", flamesIn)
			end
			return
		end
		self:Engage()
		hardmode = true
		self.flamesStarted = nil
		self:StopBerserk(self:SpellName(26662))
		self:Bar("hardmode", 610, L.hardmode, L.hardmode_icon)
		self:Bar(312803, flamesIn)
		self.flamesTimer = self:ScheduleTimer("Flames", flamesIn)
		self:CDBar(312790, 28)
		self:Bar(312793, 69)
		self:Bar(312789, 21)
		self:Bar(312792, 37)
	elseif not self:IsEngaged() then
		return
	elseif msg:find(L.stage2_trigger, nil, true) and self:GetStage() == 1 then
		self:NextStage()
	elseif msg:find(L.stage3_trigger, nil, true) and self:GetStage() == 2 then
		self:NextStage()
	elseif msg:find(L.stage4_trigger, nil, true) and self:GetStage() == 3 then
		self:NextStage()
	elseif msg:find(L.defeat_trigger, nil, true) then
		self:Win() -- DBM RegisterKill("yell")
	end
end

do
	local prev = nil
	function mod:UNIT_SPELLCAST_SUCCEEDED(_, _, castGUID, _, spellName)
		if castGUID == prev then return end
		prev = castGUID
		if spellName == self:SpellName(34098) then -- ClearAllDebuffs: a machine is done
			self:NextStage()
		elseif spellName == self:SpellName(64402) or spellName == self:SpellName(65034) then -- Rocket Strike (stage 2, 4)
			self:Message(64402, "orange")
			self:PlaySound(64402, "alarm") -- dodge
			self:CDBar(64402, 20)
		end
	end
end

function mod:UNIT_SPELLCAST_CHANNEL_STOP(_, _, _, _, spellName)
	-- the Spinning Up channel was stopped early: no Laser Barrage
	if spellName == self:SpellName(312794) and GetTime() - spinUpTime < 3.9 then
		spinUpTime = 0
		self:CancelTimer(self.laserTimer)
		self:CancelTimer(self.nextLaserTimer)
		self:StopCastBar(312794)
		self:StopCastBar(63274)
		self:StopBar(63274)
	end
end

function mod:CHAT_MSG_LOOT(_, msg)
	local player, itemId = msg:match(L.loot_pattern)
	if player and tonumber(itemId) == 46029 and self:IsEngaged() then -- Magnetic Core
		self:Message("magnetic_core", "cyan", L.magnetic_core:format(self:ColorName(player)), L.magnetic_core_icon)
	end
end

-- Leviathan Mk II

function mod:ShockBlast(args)
	self:Message(312792, "red")
	if self:Melee() then
		self:PlaySound(312792, "alarm") -- run out
	end
	self:CastBar(312792, 4)
	self:Bar(312792, 34)
end

function mod:PlasmaBlast(args)
	self:CDBar(312790, 30)
	local tanking, status = UnitDetailedThreatSituation("player", "boss1")
	if tanking or status == 3 then
		self:PlaySound(312790, "alarm") -- defensive
	end
end

function mod:PlasmaBlastApplied(args)
	self:TargetMessage(312790, "purple", args.destName)
	self:CustomIcon(plasmaMarker, args.destName, 8)
	self:ScheduleTimer("CustomIcon", 6, plasmaMarker, args.destName)
end

function mod:FlameSuppressant(args)
	self:Bar(312793, 71)
end

function mod:FlameSuppressantSuccess(args)
	self:Bar(312793, 10)
end

function mod:ProximityMines(args)
	self:Bar(312789, 12.5)
end

function mod:NapalmShell(args)
	if not self:Player(args.destFlags) then return end
	if args.time - prevNapalm > 2 then
		napalmList = {}
		napalmIcon = 7
		self:CDBar(312788, 6)
	end
	prevNapalm = args.time
	napalmList[#napalmList + 1] = args.destName
	self:TargetsMessage(312788, "yellow", napalmList, nil, nil, nil, 0.3)
	if napalmIcon > 0 then
		self:CustomIcon(napalmMarker, args.destName, napalmIcon)
		napalmIcon = napalmIcon - 1
	end
end

function mod:NapalmShellRemoved(args)
	self:CustomIcon(napalmMarker, args.destName)
end

-- VX-001

function mod:SpinningUp(args)
	spinUpTime = GetTime()
	self:CastBar(312794, 4)
	self.laserTimer = self:ScheduleTimer("CastBar", 4, 63274, 10)
	self.nextLaserTimer = self:ScheduleTimer("Bar", 19, 63274, 37) -- 4 (spin up) + 15 (laser barrage)
	self:SimpleTimer(function()
		if spinUpTime > 0 then -- DBM waits a little, the channel can be stopped right away
			self:Message(312794, "red")
			self:PlaySound(312794, "alarm") -- dodge, keep moving
		end
	end, 0.15)
end

do
	local prev = 0
	function mod:RocketStrike(args)
		if args.time - prev > 3 then
			prev = args.time
			self:CDBar(64402, 20)
		end
	end
end

-- Hard mode

function mod:FrostBomb(args)
	self:Message(64623, "orange")
	self:PlaySound(64623, "alarm") -- dodge
	self:CastBar(64623, 15)
	self:Bar(64623, 60)
end
