--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Naxx/PlagueQuarter/Loatheb.lua), draft by tools/dbm2bw
-- Not ported: the Corrupted Mind info frame and the raid warnings for damaging the spores.

local mod, CL = BigWigs:NewBoss("Loatheb", 533, 1606)
if not mod then return end
mod:RegisterEnableMob(16011)
mod:SetEncounterID(1115)

--------------------------------------------------------------------------------
-- Locals
--

local sporeCount = 0
local sporeTimer = 36
local doomCount = 0

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	heal_soon = "Healing possible in 3 seconds",
	heal_now = "Heal now",
})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		32329, -- Summon Spore
		29204, -- Inevitable Doom
		30281, -- Remove Curse
		55593, -- Necrotic Aura
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_SUCCESS", "SummonSpore", 29234)
	self:Log("SPELL_CAST_SUCCESS", "InevitableDoom", 29204, 55052)
	self:Log("SPELL_CAST_SUCCESS", "RemoveCurse", 30281)
	self:Log("SPELL_CAST_SUCCESS", "NecroticAura", 55593)
	self:Log("SPELL_AURA_APPLIED", "CorruptedMind", 29185, 29194, 29196, 29198)
	self:Log("SPELL_AURA_REMOVED", "CorruptedMindRemoved", 29185, 29194, 29196, 29198)
end

function mod:OnEngage()
	sporeCount = 0
	doomCount = 0
	sporeTimer = self:Difficulty() == 4 and 15 or 36 -- 25 / 10 player
	self:Bar(32329, sporeTimer, CL.count:format(self:SpellName(32329), 1))
	self:DelayedMessage(32329, sporeTimer - 5, "yellow", CL.soon:format(self:SpellName(32329)))
	self:Bar(29204, 90, CL.count:format(self:SpellName(29204), 1))
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:SummonSpore()
	sporeCount = sporeCount + 1
	local spore = self:SpellName(32329)
	self:StopBar(CL.count:format(spore, sporeCount))
	self:Message(32329, "yellow", CL.count:format(spore, sporeCount))
	self:Bar(32329, sporeTimer, CL.count:format(spore, sporeCount + 1))
	self:DelayedMessage(32329, sporeTimer - 5, "yellow", CL.soon:format(spore))
end

function mod:InevitableDoom()
	doomCount = doomCount + 1
	local timer = 30
	if doomCount >= 7 then
		timer = doomCount % 2 == 0 and 17 or 12
	end
	local doom = self:SpellName(29204)
	self:StopBar(CL.count:format(doom, doomCount))
	self:Message(29204, "orange", CL.count:format(doom, doomCount))
	self:PlaySound(29204, "alarm")
	self:Bar(29204, timer, CL.count:format(doom, doomCount + 1))
end

function mod:RemoveCurse(args)
	self:Message(30281, "cyan")
end

function mod:NecroticAura()
	self:CastBar(55593, 17)
	self:DelayedMessage(55593, 14, "yellow", L.heal_soon)
	self:DelayedMessage(55593, 17, "green", L.heal_now, nil, "info")
end

local function hasCorruptedMind(self)
	return self:UnitDebuff("player", 29184) or self:UnitDebuff("player", 29195)
		or self:UnitDebuff("player", 29197) or self:UnitDebuff("player", 29199)
end

function mod:CorruptedMind(args)
	if self:Me(args.destGUID) and hasCorruptedMind(self) then
		self:DelayedMessage(55593, 55, "yellow", L.heal_soon)
	end
end

function mod:CorruptedMindRemoved(args)
	if self:Me(args.destGUID) and not hasCorruptedMind(self) then
		self:Message(55593, "green", L.heal_now)
		self:PlaySound(55593, "info")
	end
end
