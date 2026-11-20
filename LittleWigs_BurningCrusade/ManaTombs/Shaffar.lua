
--------------------------------------------------------------------------------
-- Module declaration
--

local mod, CL = BigWigs:NewBoss("Nexus-Prince Shaffar", 557, 537)
if not mod then return end
mod:RegisterEnableMob(18344)
--mod.engageId = 1899 -- no boss frames, sometimes no ENCOUNTER_END on a wipe
mod:SetEncounterID(1899) -- 3.3.5: encounter emulation, there is no ENCOUNTER_START (the retail module has no boss frames to engage by)
--mod.respawnTime = 0 -- resets, doesn't respawn

--------------------------------------------------------------------------------
-- Initialization
--

local L = mod:SetDefaultLocale({
	beacon = "Маяк появится через", -- 3.3.5: DBM Sirus TimerEtherealOrb (DBM: no English text)
	beacon_desc = "Show timers for the Ethereal Beacon and the Ethereal Apprentice",
	beacon_icon = 64465,
	apprentice = "Ученик появится через", -- 3.3.5: DBM Sirus TimerEtherealSpawn (DBM: no English text)
})

function mod:GetOptions()
	return {
		32365, -- Frost Nova
		34605, -- Blink (3.3.5: DBM Sirus)
		"beacon", -- 3.3.5: DBM Sirus
		32371, -- Summon Ethereal Beacon (3.3.5: DBM Sirus)
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "FrostNova", 32365)
	self:Log("SPELL_CAST_SUCCESS", "FrostNovaCast", 32365) -- 3.3.5: DBM Sirus
	self:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", nil, "boss1") -- 3.3.5: DBM Sirus, Summon Ethereal Beacon
	self:MapSpellNames(32371)
	self:Death("Win", 18344)
end

function mod:OnEngage() -- 3.3.5: DBM Sirus timers
	self:CDBar(32365, 15)
	self:CDBar(34605, 16)
	self:BeaconLoop()
end

--------------------------------------------------------------------------------
-- Event Handlers
--

do
	local playerList = mod:NewTargetList()

	function mod:FrostNova(args)
		if not self:Player(args.destFlags) then return end -- filter out pets
		playerList[#playerList+1] = args.destName
		if #playerList == 1 then
			self:ScheduleTimer("TargetMessageOld", 0.3, args.spellId, playerList, "red", "alert", nil, nil, self:Dispeller("magic"))
		end
	end
end

-- 3.3.5: DBM Sirus
function mod:BeaconLoop()
	self:Bar("beacon", 10, L.beacon, L.beacon_icon)
	self:Bar("beacon", 10, L.apprentice, 69960)
	self:ScheduleTimer("BeaconLoop", 10)
end

function mod:FrostNovaCast()
	self:CDBar(32365, 24)
end

do
	local prev = 0
	function mod:UNIT_SPELLCAST_SUCCEEDED(_, _, _, _, spellName)
		local t = GetTime()
		if spellName == self:SpellName(32371) and t - prev > 5 then
			prev = t
			self:Message(32371, "orange")
			if not self:Healer() then
				self:PlaySound(32371, "alert") -- DBM: kill the adds
			end
		end
	end
end
