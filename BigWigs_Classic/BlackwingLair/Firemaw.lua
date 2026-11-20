--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-BWL/Firemaw.lua)

local mod, CL = BigWigs:NewBoss("Firemaw", 469, 1532)
if not mod then return end
mod:RegisterEnableMob(11983)
mod:SetEncounterID(613)

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		23339, -- Wing Buffet
		22539, -- Shadow Flame
		23341, -- Flame Buffet
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "WingBuffet", 23339)
	self:Log("SPELL_CAST_START", "ShadowFlame", 22539)
	self:Log("SPELL_AURA_APPLIED_DOSE", "FlameBuffet", 23341)
end

function mod:OnEngage()
	self:CDBar(22539, 18)
	self:CDBar(23339, 30)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:WingBuffet(args)
	self:Message(23339, "yellow", CL.casting:format(args.spellName))
	self:CDBar(23339, 31)
end

function mod:ShadowFlame(args)
	self:Message(22539, "orange", CL.casting:format(args.spellName))
	self:CDBar(22539, 14) -- DBM: the timer is off by default
end

function mod:FlameBuffet(args)
	local amount = args.amount or 1
	if self:Me(args.destGUID) and amount >= 4 and amount % 2 == 0 then -- DBM: from 4 stacks, every even stack
		self:StackMessage(23341, "blue", args.destName, amount, 0)
	end
end
