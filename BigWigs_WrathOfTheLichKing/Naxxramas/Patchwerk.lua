--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Naxx/ConstructQuarter/Patchwerk.lua), draft by tools/dbm2bw
-- Not ported: posting Hateful Strike targets to the raid chat (DBM WarningHateful).

local mod, CL = BigWigs:NewBoss("Patchwerk", 533, 1610)
if not mod then return end
mod:RegisterEnableMob(16028)
mod:SetEncounterID(1118)

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	engage_trigger1 = "Patchwerk want to play!",
	engage_trigger2 = "Kel'thuzad make Patchwerk his avatar of war!",
})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"berserk",
	}
end

function mod:OnBossEnable()
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
end

function mod:OnEngage()
	self:Berserk(BigWigsLoader.Compat.GetRealmNumber() == 1 and 480 or 360) -- 3.3.5: DBM Sirus x1 realm timer
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if (msg == L.engage_trigger1 or msg == L.engage_trigger2) and not self:IsEngaged() then
		self:Engage() -- DBM RegisterCombat("combat_yell")
	end
end
