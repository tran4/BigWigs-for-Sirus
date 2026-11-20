--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-BWL/Flamegor.lua)

local mod, CL = BigWigs:NewBoss("Flamegor", 469, 1534)
if not mod then return end
mod:RegisterEnableMob(11981)
mod:SetEncounterID(615)

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		23339, -- Wing Buffet
		22539, -- Shadow Flame
		23342, -- Frenzy
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "WingBuffet", 23339)
	self:Log("SPELL_CAST_START", "ShadowFlame", 22539)
	self:Log("SPELL_CAST_SUCCESS", "Frenzy", 23342)
	self:Log("SPELL_AURA_APPLIED", "FrenzyApplied", 23342)
	self:Log("SPELL_AURA_REMOVED", "FrenzyRemoved", 23342)
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

function mod:Frenzy(args)
	if self:Hostile(args.sourceFlags) then
		self:Message(23342, "orange")
		if self:Dispeller("enrage", true) then
			self:PlaySound(23342, "alarm") -- DBM: dispel the enrage
		end
	end
end

function mod:FrenzyApplied(args)
	self:Bar(23342, 10)
end

function mod:FrenzyRemoved()
	self:StopBar(23342)
end
