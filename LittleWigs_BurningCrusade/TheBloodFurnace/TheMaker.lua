--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("The Maker", 542, 555)
if not mod then return end
mod:RegisterEnableMob(17381)
--mod.engageId = 1922 -- no boss frames
mod:SetEncounterID(1922) -- 3.3.5: encounter emulation, there is no ENCOUNTER_START (the retail module has no boss frames to engage by)
--mod.respawnTime = 0 -- resets, doesn't respawn

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		30923, -- Domination
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "Domination", 30923)
	self:Log("SPELL_AURA_REMOVED", "DominationRemoved", 30923)
	self:Death("Win", 17381)
end

function mod:OnEngage() -- 3.3.5: WA: "WA на ключи - автор Раэнис х3", the first Domination 15s after the pull yell
	self:CDBar(30923, 15)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:Domination(args)
	self:TargetMessage(args.spellId, "red", args.destName)
	self:TargetBar(args.spellId, 10, args.destName)
	self:CDBar(args.spellId, 30) -- 3.3.5: WA: "WA на ключи - автор Раэнис х3"
end

function mod:DominationRemoved(args)
	self:StopBar(args.spellName, args.destName)
end
