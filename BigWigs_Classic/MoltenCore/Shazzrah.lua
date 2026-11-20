--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-MC/Shazzrah.lua)

local mod, CL = BigWigs:NewBoss("Shazzrah", 409, 1523)
if not mod then return end
mod:RegisterEnableMob(12264)
mod:SetEncounterID(667)

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		19713, -- Shazzrah's Curse
		19715, -- Counterspell
		{23138, "TANK"}, -- Gate of Shazzrah (DBM: tanks only)
		{19714, "OFF"}, -- Deaden Magic
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_SUCCESS", "ShazzrahsCurse", 19713)
	self:Log("SPELL_CAST_SUCCESS", "Counterspell", 19715)
	self:Log("SPELL_CAST_SUCCESS", "Gate", 23138)
	self:Log("SPELL_AURA_APPLIED", "DeadenMagic", 19714)
	self:Log("SPELL_AURA_REMOVED", "DeadenMagicRemoved", 19714)
end

function mod:OnEngage()
	self:CDBar(19713, 6)
	self:CDBar(19715, 9.6)
	self:CDBar(23138, 30)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:ShazzrahsCurse(args)
	self:Message(19713, "red")
	self:CDBar(19713, 22)
end

function mod:Counterspell(args)
	self:Message(19715, "orange")
	self:CDBar(19715, 15)
end

function mod:Gate(args)
	self:Message(23138, "purple")
	self:PlaySound(23138, "warning") -- DBM: taunt, the threat is wiped
	self:CDBar(23138, 41.3)
end

function mod:DeadenMagic(args)
	if not self:Player(args.destFlags) then
		self:Message(19714, "yellow", CL.onboss:format(args.spellName))
		if self:Dispeller("magic", true) then
			self:PlaySound(19714, "info") -- DBM: dispel the boss
		end
		self:Bar(19714, 30)
	end
end

function mod:DeadenMagicRemoved()
	self:StopBar(19714)
end
