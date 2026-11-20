--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-VoA/Toravon.lua), draft by tools/dbm2bw

local mod, CL = BigWigs:NewBoss("Toravon the Ice Watcher", 624, 1600)
if not mod then return end
mod:RegisterEnableMob(38433)
mod:SetEncounterID(1129)

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		72034, -- Whiteout
		72091, -- Frozen Orb
		72090, -- Freezing Ground
		{72004, "TANK_HEALER"}, -- Frostbite
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "Whiteout", 72096, 72034)
	self:Log("SPELL_CAST_START", "FrozenOrb", 72095, 72091)
	self:Log("SPELL_CAST_SUCCESS", "FreezingGround", 72104, 72090)
	self:Log("SPELL_AURA_APPLIED", "Frostbite", 72098, 72004)
	self:Log("SPELL_AURA_APPLIED_DOSE", "Frostbite", 72098, 72004)
end

function mod:OnEngage()
	self:Bar(72091, 13)
	self:Bar(72034, 25)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:Whiteout(args)
	self:Message(72034, "orange")
	self:Bar(72034, 38)
end

function mod:FrozenOrb(args)
	self:Message(72091, "red")
	self:Bar(72091, 32)
end

function mod:FreezingGround(args)
	self:Message(72090, "yellow")
end

function mod:Frostbite(args)
	self:StackMessage(72004, "purple", args.destName, args.amount or 1, 1)
	self:Bar(72004, 5)
	self:TargetBar(72004, 20, args.destName)
end
