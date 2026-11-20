--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-ZG/Gahzranka.lua), no journal id: the name is from the DBM locale

local mod, CL = BigWigs:NewBoss("Gahz'ranka", 309)
if not mod then return end
mod:RegisterEnableMob(15114)
mod:SetEncounterID(790)

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	bossName = "Gahz'ranka",
})
mod.displayName = L.bossName

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		16099, -- Frost Breath
		22421, -- Massive Geyser
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "FrostBreath", 16099)
	self:Log("SPELL_CAST_START", "MassiveGeyser", 22421)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:FrostBreath(args)
	self:Message(16099, "orange", CL.casting:format(args.spellName))
end

function mod:MassiveGeyser(args)
	self:Message(22421, "yellow", CL.casting:format(args.spellName))
end
