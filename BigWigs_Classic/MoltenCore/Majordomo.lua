--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-MC/Majordomo.lua)
-- Majordomo Executus does not die, he submits when his guards are dead: the encounter is won when every
-- Flamewaker Healer (11663) and Flamewaker Elite (11664) seen in the fight has died. The victory enables the
-- Ragnaros module for the summoning roleplay.

local mod, CL = BigWigs:NewBoss("Majordomo Executus", 409, 1527)
if not mod then return end
mod:RegisterEnableMob(12018, 11663, 11664)
mod:SetEncounterID(671)
mod:SetWinMobs() -- 3.3.5: won by the guards' deaths below

--------------------------------------------------------------------------------
-- Locals
--

local guards = {}
local guardIds = {[11663] = true, [11664] = true}

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	shield = "Next Shield",
	shield_desc = "Show timer for next Damage/Reflect Shield",
	shield_icon = 20619,
})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		20534, -- Teleport
		"shield",
		20619, -- Magic Reflection
		21075, -- Damage Shield
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_SUCCESS", "Teleport", 20534)
	self:Log("SPELL_CAST_SUCCESS", "MagicReflection", 20619)
	self:Log("SPELL_CAST_SUCCESS", "DamageShield", 21075)
	-- 3.3.5: remember the guards that fight the group
	self:Log("SWING_DAMAGE", "GuardSeen", "*")
	self:Log("SWING_MISSED", "GuardSeen", "*")
	self:Log("SPELL_DAMAGE", "GuardSeen", "*")
	self:Log("SPELL_MISSED", "GuardSeen", "*")
	self:Log("RANGE_DAMAGE", "GuardSeen", "*")
	self:Death("GuardDeath", 11663, 11664)
end

function mod:OnEngage()
	guards = {}
	self:CDBar(20534, 19.4)
	self:Bar("shield", 27.8, L.shield, L.shield_icon)
end

function mod:OnWin()
	local ragnaros = BigWigs:GetBossModule("Ragnaros Classic", true)
	if ragnaros and not ragnaros:IsEnabled() then
		ragnaros:Enable()
	end
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:Teleport(args)
	self:TargetMessage(20534, "yellow", args.destName)
	self:CDBar(20534, 25)
end

function mod:MagicReflection(args)
	self:Message(20619, "red")
	if self:Ranged() and not self:Healer() then
		self:PlaySound(20619, "warning") -- DBM: stop attacking (caster dps)
	end
	self:Bar(20619, 10, CL.other:format(args.spellName, CL.active))
	self:Bar("shield", 30.3, L.shield, L.shield_icon)
end

function mod:DamageShield(args)
	self:Message(21075, "orange")
	self:Bar(21075, 10, CL.other:format(args.spellName, CL.active))
	self:Bar("shield", 30.3, L.shield, L.shield_icon)
end

function mod:GuardSeen(args)
	if not self:IsEngaged() then return end
	if guardIds[self:MobId(args.sourceGUID)] then
		if guards[args.sourceGUID] == nil then guards[args.sourceGUID] = true end
	elseif guardIds[self:MobId(args.destGUID)] then
		if guards[args.destGUID] == nil then guards[args.destGUID] = true end
	end
end

function mod:GuardDeath(args)
	if not self:IsEngaged() then return end
	guards[args.destGUID] = false
	for _, alive in next, guards do
		if alive then return end
	end
	self:Win()
end
