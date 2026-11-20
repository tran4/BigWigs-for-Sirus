
--------------------------------------------------------------------------------
-- Module declaration
--

local mod, CL = BigWigs:NewBoss("Mennu the Betrayer", 547, 570)
if not mod then return end
mod:RegisterEnableMob(17941)
--mod.engageId = 1939 -- no boss frames
mod:SetEncounterID(1939) -- 3.3.5: encounter emulation, there is no ENCOUNTER_START (the retail module has no boss frames to engage by)
--mod.respawnTime = 0 -- resets, doesn't respawn

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		34980, -- Mennu's Healing Ward
		31991, -- Corrupted Nova Totem
		31985, -- Stoneskin Totem (3.3.5: DBM Sirus)
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_SUMMON", "HealingWard", 34980)
	self:Log("SPELL_SUMMON", "CorruptedNovaTotem", 31991)
	self:Log("SPELL_SUMMON", "StoneskinTotem", 31985) -- 3.3.5: DBM Sirus

	self:Death("Win", 17941)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:HealingWard(args)
	self:MessageOld(args.spellId, "orange")
end

function mod:CorruptedNovaTotem(args)
	self:MessageOld(args.spellId, "yellow")
end

function mod:StoneskinTotem(args) -- 3.3.5: DBM Sirus
	self:Message(31985, "yellow")
end
