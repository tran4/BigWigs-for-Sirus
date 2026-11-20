--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-VoA/Emalon.lua), draft by tools/dbm2bw
-- Not ported: the icon on the overcharged minion (DBM ScanForMobs), the cast bar of Lightning Nova (DBM takes the cast
-- time from the spell).

local mod, CL = BigWigs:NewBoss("Emalon the Storm Watcher", 624, 1598)
if not mod then return end
mod:RegisterEnableMob(33993)
mod:SetEncounterID(1127)

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	overcharge_explosion = "Overcharge explosion",
})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"berserk",
		65279, -- Lightning Nova
		64218, -- Overcharge
		64217, -- Overcharged (minion)
		"proximity",
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "LightningNova", 64216, 65279)
	self:Log("SPELL_HEAL", "Overcharge", 64218)
	self:Log("SPELL_AURA_APPLIED", "Overcharged", 64217)
	self:Log("SPELL_AURA_REMOVED", "OverchargedRemoved", 64217)
end

function mod:OnEngage()
	self:Bar(64218, 45)
	self:CDBar(65279, 20)
	self:Berserk(360)
	self:OpenProximity("proximity", 10)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:LightningNova(args)
	self:Message(65279, "red")
	self:PlaySound(65279, "runaway")
	self:CDBar(65279, 40)
end

function mod:Overcharge(args)
	self:Message(64218, "orange")
	self:Bar(64218, 45)
end

function mod:Overcharged(args)
	self:Bar(64217, 20, L.overcharge_explosion)
end

function mod:OverchargedRemoved(args)
	self:StopBar(L.overcharge_explosion)
end
