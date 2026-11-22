--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Ulduar/Kologarn.lua), draft by tools/dbm2bw

local mod, CL = BigWigs:NewBoss("Kologarn", 603, 1642)
if not mod then return end
mod:RegisterEnableMob(32930, 32933, 32934) -- Kologarn, Left Arm, Right Arm
mod:SetEncounterID(749)
mod:SetWinMobs(32930) -- 3.3.5: the arms respawn, the body has to die

--------------------------------------------------------------------------------
-- Locals
--

local disarmActive = false
local prevShockwave = 0
local prevEyebeamDamage = 0

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	eyebeam_whisper = "his eyes on you",

	left_arm = "Left Arm respawn",
	left_arm_desc = "Show timer for Left Arm respawn",
	left_arm_icon = "misc_arrowleft",
	right_arm = "Right Arm respawn",
	right_arm_desc = "Show timer for Right Arm respawn",
	right_arm_icon = "misc_arrowright",
	disarmed = "Timer for Disarm",
	disarmed_desc = "Show timer for Disarm achievement",
	disarmed_icon = "misc_arrowdown",
})

--------------------------------------------------------------------------------
-- Initialization
--

local gripMarker = mod:AddMarkerOption(true, "player", 8, 64292, 8)
function mod:GetOptions()
	return {
		{64003, "TANK"}, -- Overhead Smash
		312752, -- Shockwave
		{63346, "SAY"}, -- Focused Eyebeam
		{312757, "OFF"}, -- Stone Grip (3.3.5: who was gripped, off by default on request)
		gripMarker,
		{312748, "TANK"}, -- Crunch Armor
		"left_arm",
		"right_arm",
		"disarmed",
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_SUCCESS", "OverheadSmash", 64003)
	self:Log("SPELL_DAMAGE", "ShockwaveDamage", 312399, 312752, 63783, 63982)
	self:Log("SPELL_DAMAGE", "EyebeamDamage", 312412, 312765, 63346, 63976)
	self:Log("SPELL_AURA_APPLIED", "StoneGrip", 312758, 312757, 312760, 312407, 312405, 312404, 64290, 64292)
	self:Log("SPELL_AURA_APPLIED_DOSE", "StoneGrip", 312758, 312757, 312760, 312407, 312405, 312404, 64290, 64292)
	self:Log("SPELL_AURA_REMOVED", "StoneGripRemoved", 312758, 312757, 312760, 312407, 312405, 312404, 64290, 64292)
	self:Log("SPELL_AURA_APPLIED", "CrunchArmor", 312748, 312395, 64002, 63355)
	self:Log("SPELL_AURA_APPLIED_DOSE", "CrunchArmor", 312748, 312395, 64002, 63355)
	self:Death("RightArmDeath", 32934)
	self:Death("LeftArmDeath", 32933)
	self:RegisterEvent("CHAT_MSG_RAID_BOSS_WHISPER")
end

function mod:OnEngage()
	disarmActive = false
	self:CDBar(312752, 15.7)
	self:CDBar(64003, 10)
	self:CDBar(63346, 11)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:OverheadSmash(args)
	self:CDBar(64003, 20.4)
end

function mod:ShockwaveDamage(args)
	if self:Player(args.destFlags) and args.time - prevShockwave > 5 then
		prevShockwave = args.time
		self:CDBar(312752, 23)
	end
end

function mod:EyebeamDamage(args)
	self:StopBar(63346) -- 3.3.5: only the first eyebeam has a bar (DBM), it stayed at 0 until the end of the fight
	if self:Me(args.destGUID) and args.time - prevEyebeamDamage > 2 then
		prevEyebeamDamage = args.time
		self:PersonalMessage(63346, "underyou")
		self:PlaySound(63346, "underyou")
	end
end

function mod:CHAT_MSG_RAID_BOSS_WHISPER(_, msg)
	if msg:find(L.eyebeam_whisper) then -- DBM: a pattern ("%s" in the Russian text)
		self:StopBar(63346) -- 3.3.5: see EyebeamDamage
		self:PersonalMessage(63346)
		self:PlaySound(63346, "alarm") -- run, keep moving
		self:Say(63346)
	end
end

function mod:StoneGrip(args)
	self:TargetMessage(312757, "red", args.destName)
	self:CustomIcon(gripMarker, args.destName, 8)
end

function mod:StoneGripRemoved(args)
	self:CustomIcon(gripMarker, args.destName)
end

function mod:CrunchArmor(args)
	local amount = args.amount or 1
	self:StackMessage(312748, "purple", args.destName, amount, 2)
	if self:Me(args.destGUID) and amount >= 2 then
		self:PlaySound(312748, "alarm")
	end
	if self:Difficulty() == 5 then -- only 6 seconds, tracked in 10 player only
		self:TargetBar(312748, 6, args.destName)
	end
end

function mod:Disarmed()
	if not disarmActive then
		disarmActive = true
		self:Bar("disarmed", 12, L.disarmed, L.disarmed_icon)
		self:ScheduleTimer(function() disarmActive = false end, 12)
	end
end

function mod:RightArmDeath()
	self:Bar("right_arm", 48, L.right_arm, L.right_arm_icon)
	self:Disarmed()
end

function mod:LeftArmDeath()
	self:Bar("left_arm", 48, L.left_arm, L.left_arm_icon)
	self:Disarmed()
end
