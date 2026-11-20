
--------------------------------------------------------------------------------
-- Module declaration
--

local mod, CL = BigWigs:NewBoss("Tavarok", 557, 535)
if not mod then return end
mod:RegisterEnableMob(18343)
--mod.engageId = 1901 -- no boss frames
mod:SetEncounterID(1901) -- 3.3.5: encounter emulation, there is no ENCOUNTER_START (the retail module has no boss frames to engage by)
--mod.respawnTime = 0 -- resets, doesn't respawn

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		{32361, "ICON"}, -- Crystal Prison
		33919, -- Earthquake (3.3.5: DBM Sirus)
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "CrystalPrison", 32361)
	self:Log("SPELL_AURA_REMOVED", "CrystalPrisonRemoved", 32361)
	self:Log("SPELL_CAST_START", "Earthquake", 33919) -- 3.3.5: DBM Sirus
	self:Log("SPELL_AURA_APPLIED", "EarthquakeApplied", 33919) -- 3.3.5: DBM Sirus
	self:Death("Win", 18343)
end

function mod:OnEngage() -- 3.3.5: DBM Sirus timers
	self:CDBar(33919, 10)
	self:CDBar(32361, 17)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:CrystalPrison(args)
	self:TargetMessageOld(args.spellId, args.destName, "red")
	self:TargetBar(args.spellId, 5)
	self:PrimaryIcon(args.spellId, args.destName)
	if not self:Retail() then
		self:CDBar(32361, 17.8) -- 3.3.5: DBM Sirus
	end
end

function mod:CrystalPrisonRemoved(args)
	self:PrimaryIcon(args.spellId)
	self:StopBar(args.spellName, args.destName)
end

-- 3.3.5: DBM Sirus
function mod:Earthquake(args)
	self:Message(33919, "orange", CL.casting:format(args.spellName))
	self:PlaySound(33919, "alarm") -- DBM: stun soon
end

do
	local prev = 0
	function mod:EarthquakeApplied(args)
		if args.time - prev > 3 then
			prev = args.time
			self:CDBar(33919, 22)
		end
	end
end
