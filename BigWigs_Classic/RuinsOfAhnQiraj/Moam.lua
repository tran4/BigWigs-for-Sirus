--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-AQ20/Moam.lua)

local mod, CL = BigWigs:NewBoss("Moam", 509, 1539)
if not mod then return end
mod:RegisterEnableMob(15340)
mod:SetEncounterID(720)

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		25685, -- Energize
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "Energize", 25685)
	self:Log("SPELL_AURA_REMOVED", "EnergizeRemoved", 25685)
end

function mod:OnEngage()
	self:Bar(25685, 90)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:Energize(args)
	if not self:Player(args.destFlags) then
		self:StopBar(25685)
		self:Message(25685, "orange")
		self:PlaySound(25685, "long")
		self:Bar(25685, 90, CL.other:format(args.spellName, CL.active))
	end
end

function mod:EnergizeRemoved(args)
	if not self:Player(args.destFlags) then
		self:StopBar(CL.other:format(args.spellName, CL.active))
		self:Message(25685, "cyan", CL.over:format(args.spellName))
		self:Bar(25685, 90)
	end
end
