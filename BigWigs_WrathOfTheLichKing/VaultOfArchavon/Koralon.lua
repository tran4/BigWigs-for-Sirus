--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-VoA/Koralon.lua), draft by tools/dbm2bw

local mod, CL = BigWigs:NewBoss("Koralon the Flame Watcher", 624, 1599)
if not mod then return end
mod:RegisterEnableMob(35013)
mod:SetEncounterID(1128)

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"berserk",
		66665, -- Burning Breath
		66725, -- Meteor Fists
		{66721, "TANK_HEALER"}, -- Burning Fury
		66684, -- Flaming Cinder
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "BurningBreath", 67328, 66665)
	self:Log("SPELL_CAST_START", "MeteorFists", 66725, 68161)
	self:Log("SPELL_AURA_APPLIED", "FlamingCinder", 66684, 67332)
	self:Log("SPELL_AURA_APPLIED", "BurningFury", 66721)
	self:Log("SPELL_AURA_APPLIED_DOSE", "BurningFury", 66721)
end

function mod:OnEngage()
	self:Berserk(300)
	self:Bar(66725, 47)
	self:CDBar(66665, 12)
	self:DelayedMessage(66725, 42, "yellow", CL.soon:format(self:SpellName(66725)))
	self:Bar(66721, 20)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:BurningBreath(args)
	self:Message(66665, "orange")
	self:Bar(66665, 4.5, CL.other:format(args.spellName, CL.active))
	self:CDBar(66665, 45)
end

function mod:MeteorFists(args)
	self:Message(66725, "red")
	self:Bar(66725, 47)
	self:DelayedMessage(66725, 42, "yellow", CL.soon:format(args.spellName))
end

function mod:FlamingCinder(args)
	if self:Me(args.destGUID) then
		self:PersonalMessage(66684, "underyou")
		self:PlaySound(66684, "underyou")
	end
end

function mod:BurningFury(args)
	self:StackMessage(66721, "purple", args.destName, args.amount or 1, 1)
	self:Bar(66721, 20)
end
