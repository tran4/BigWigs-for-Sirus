--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-AQ20/Ossirian.lua). Not ported: the speed clear timer.

local mod, CL = BigWigs:NewBoss("Ossirian the Unscarred", 509, 1542)
if not mod then return end
mod:RegisterEnableMob(15339)
mod:SetEncounterID(723)

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	weakness = "Weaknesses",
	weakness_desc = "Announce weaknesses, show timer for weaknesses",
	weakness_icon = "INV_Enchant_EssenceMagicLarge",
})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"weakness",
		25176, -- Strength of Ossirian
		25189, -- Enveloping Winds
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "StrengthOfOssirian", 25176)
	self:Log("SPELL_AURA_APPLIED", "EnvelopingWinds", 25189)
	self:Log("SPELL_AURA_REMOVED", "EnvelopingWindsRemoved", 25189)
	self:Log("SPELL_AURA_APPLIED", "Weakness", 25177, 25178, 25180, 25181, 25183)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:StrengthOfOssirian(args)
	self:Message(25176, "red")
end

function mod:EnvelopingWinds(args)
	self:TargetMessage(25189, "orange", args.destName)
	self:TargetBar(25189, 10, args.destName)
end

function mod:EnvelopingWindsRemoved(args)
	self:StopBar(25189, args.destName)
end

function mod:Weakness(args)
	self:Message("weakness", "green", args.spellName, args.spellId)
	self:PlaySound("weakness", "info")
	self:Bar("weakness", 45, args.spellName, args.spellId)
end
