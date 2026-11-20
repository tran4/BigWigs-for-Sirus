--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-BWL/Broodlord.lua), engaged by the pull yell like DBM or by the fight

local mod, CL = BigWigs:NewBoss("Broodlord Lashlayer", 469, 1531)
if not mod then return end
mod:RegisterEnableMob(12017)
mod:SetEncounterID(612)

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	engage_trigger = "None of your kind should be here!  You've doomed only yourselves!",
})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		23331, -- Blast Wave
		18670, -- Knock Away
		{24573, "TANK_HEALER"}, -- Mortal Strike (DBM: tanks and healers only)
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_SUCCESS", "BlastWave", 23331)
	self:Log("SPELL_CAST_SUCCESS", "KnockAway", 18670)
	self:Log("SPELL_AURA_APPLIED", "MortalStrike", 24573)
	self:Log("SPELL_AURA_REMOVED", "MortalStrikeRemoved", 24573)
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if msg:find(L.engage_trigger, nil, true) and not self:IsEngaged() then
		self:Engage()
	end
end

function mod:BlastWave(args)
	if self:Hostile(args.sourceFlags) then
		self:Message(23331, "orange")
	end
end

function mod:KnockAway(args)
	self:Message(18670, "yellow")
end

function mod:MortalStrike(args)
	if self:Player(args.destFlags) then
		self:TargetMessage(24573, "purple", args.destName)
		self:TargetBar(24573, 5, args.destName)
	end
end

function mod:MortalStrikeRemoved(args)
	if self:Player(args.destFlags) then
		self:StopBar(24573, args.destName)
	end
end
