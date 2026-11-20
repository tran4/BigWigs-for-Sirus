--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-BWL/Ebonroc.lua)

local mod, CL = BigWigs:NewBoss("Ebonroc", 469, 1533)
if not mod then return end
mod:RegisterEnableMob(14601)
mod:SetEncounterID(614)

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		23339, -- Wing Buffet
		22539, -- Shadow Flame
		{23340, "TANK_HEALER"}, -- Shadow of Ebonroc (DBM: tanks and healers only)
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "WingBuffet", 23339)
	self:Log("SPELL_CAST_START", "ShadowFlame", 22539)
	self:Log("SPELL_AURA_APPLIED", "ShadowOfEbonroc", 23340)
	self:Log("SPELL_AURA_REMOVED", "ShadowOfEbonrocRemoved", 23340)
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

function mod:ShadowOfEbonroc(args)
	self:TargetMessage(23340, "purple", args.destName)
	self:TargetBar(23340, 8, args.destName)
	if self:Me(args.destGUID) then
		self:PlaySound(23340, "alarm")
	elseif self:Tank() then
		self:PlaySound(23340, "warning") -- DBM: taunt
	end
end

function mod:ShadowOfEbonrocRemoved(args)
	self:StopBar(23340, args.destName)
end
