--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-VoA/Archavon.lua), draft by tools/dbm2bw

local mod, CL = BigWigs:NewBoss("Archavon the Stone Watcher", 624, 1597)
if not mod then return end
mod:RegisterEnableMob(31125)
mod:SetEncounterID(1126)

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	grab_trigger = "%%s lunges for (%S+)!", -- pattern (DBM TankSwitch)
	grab = "Archavon grabbed >%s<",
})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"berserk",
		60880, -- Stomp
		58678, -- Rock Shards
		60894, -- Crushing Leap
		53041, -- grab
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "Stomp", 58663, 60880)
	self:Log("SPELL_CAST_SUCCESS", "CrushingLeap", 58963, 60895)
	self:Log("SPELL_AURA_APPLIED", "RockShards", 58678, 58941)
	self:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE")
end

function mod:OnEngage()
	self:Berserk(300)
	self:Bar(60880, 45)
	self:DelayedMessage(60880, 40, "yellow", CL.soon:format(self:SpellName(60880)))
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:Stomp(args)
	self:Message(60880, "red")
	self:PlaySound(60880, "alarm")
	self:Bar(60880, 45)
	self:DelayedMessage(60880, 40, "yellow", CL.soon:format(self:SpellName(60880)))
end

function mod:CrushingLeap(args)
	self:Message(60894, "orange")
end

function mod:RockShards(args)
	self:TargetMessage(58678, "yellow", args.destName)
	self:TargetBar(58678, 4, args.destName)
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(_, msg, _, _, _, target)
	local name = msg:match(L.grab_trigger) or (msg:find(L.grab_trigger) and target)
	if name and self:IsEngaged() then
		self:Message(53041, "orange", L.grab:format(target or name))
	end
end
