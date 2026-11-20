--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Ulduar/Hodir.lua), draft by tools/dbm2bw

local mod, CL = BigWigs:NewBoss("Hodir", 603, 1644)
if not mod then return end
mod:RegisterEnableMob(32845, 32926)
mod:SetEncounterID(751)
mod:SetWinMobs() -- 3.3.5: won by the defeat yell (DBM RegisterKill)

--------------------------------------------------------------------------------
-- Locals
--

local cloudIcon = 8
local prevBitingCold = 0

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	defeat_trigger = "I... I am released from his grasp... at last.",
})

--------------------------------------------------------------------------------
-- Initialization
--

local cloudMarker = mod:AddMarkerOption(true, "player", 8, 65123, 8, 7)
function mod:GetOptions()
	return {
		"berserk",
		312818, -- Flash Freeze
		{63512, "TANK_HEALER"}, -- Frozen Blows
		{65123, "SAY", "SAY_COUNTDOWN"}, -- Storm Cloud
		cloudMarker,
		312819, -- Biting Cold
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "FlashFreeze", 312818, 312465, 61968)
	self:Log("SPELL_AURA_APPLIED", "FrozenBlows", 312817, 312816, 312464, 312463, 62478, 63512)
	self:Log("SPELL_AURA_APPLIED", "StormCloud", 312831, 312478, 65123, 65133)
	self:Log("SPELL_AURA_REMOVED", "StormCloudRemoved", 312831, 312478, 65123, 65133)
	self:Log("SPELL_DAMAGE", "BitingColdDamage", 62038, 62188, 312466, 312819)
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
end

function mod:OnEngage()
	cloudIcon = 8
	self:Berserk(475)
	self:CDBar(312818, 60)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if msg:find(L.defeat_trigger, nil, true) then
		self:Win() -- DBM RegisterKill("yell")
	end
end

function mod:FlashFreeze(args)
	self:Message(312818, "red")
	self:PlaySound(312818, "long") -- find shelter
	self:CastBar(312818, 9)
	self:CDBar(312818, 60)
end

function mod:FrozenBlows(args)
	self:Message(63512, "purple")
	self:CastBar(63512, 20)
end

function mod:StormCloud(args)
	if self:Me(args.destGUID) then
		self:PersonalMessage(65123)
		self:PlaySound(65123, "warning") -- share it
		self:Say(65123)
	else
		self:TargetMessage(65123, "green", args.destName)
	end
	self:CustomIcon(cloudMarker, args.destName, cloudIcon)
	-- two players can have it on 25 player, alternate between 2 icons
	cloudIcon = cloudIcon == 8 and 7 or 8
end

function mod:StormCloudRemoved(args)
	self:CustomIcon(cloudMarker, args.destName)
end

function mod:BitingColdDamage(args)
	if self:Me(args.destGUID) and args.time - prevBitingCold > 4 then
		prevBitingCold = args.time
		self:PersonalMessage(312819, "underyou")
		self:PlaySound(312819, "underyou") -- keep moving
	end
end
