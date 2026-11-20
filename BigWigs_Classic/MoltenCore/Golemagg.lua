--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-MC/Golemagg.lua)
-- DBM registers SPELL_CAST_SUCCESS 20553 but handles SPELL_AURA_APPLIED, so its warning never shows:
-- the cast is used here.

local mod, CL = BigWigs:NewBoss("Golemagg the Incinerator", 409, 1526)
if not mod then return end
mod:RegisterEnableMob(11988)
mod:SetEncounterID(670)

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		20553, -- DBM: warnQuake
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_SUCCESS", "Quake", 20553)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:Quake(args)
	self:Message(20553, "yellow")
end
