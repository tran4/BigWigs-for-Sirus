--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("Vazruden", 543, 529)
if not mod then return end
mod:RegisterEnableMob(17537, 17536, 17307) -- Vazruden, Nazan <Vazruden's Mount> (unused?), Vazruden the Herald (Flying prior to engage, converts into Nazan on engage)
--mod:SetEncounterID(1892) -- no boss frames
mod:SetEncounterID(1892) -- 3.3.5: encounter emulation, there is no ENCOUNTER_START (the retail module has no boss frames to engage by)
--mod:SetRespawnTime(34) -- since his wipe-yell

-- ENCOUNTER_END issues:
-- - fires it 2 seconds before he respawns after a wipe instead of doing that when he actually despawns;
-- - fires it 9 seconds after being defeated.

--------------------------------------------------------------------------------
-- Locals
--

local deaths = 0

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	nazan_emote = "Назан спускается с небес.", -- 3.3.5: DBM Sirus (DBM: no English text)
})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"stages",
		22686, -- Bellowing Roar (3.3.5: from DBM Sirus)
		36921, -- Fireball (3.3.5: from DBM Sirus)
	}
end

function mod:OnBossEnable()
	self:RegisterEvent("RAID_BOSS_EMOTE")
	self:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE") -- 3.3.5: there is no RAID_BOSS_EMOTE
	self:Log("SPELL_CAST_START", "BellowingRoar", 22686) -- 3.3.5: from DBM Sirus
	self:Log("SPELL_CAST_SUCCESS", "Fireball", 36921) -- 3.3.5: from DBM Sirus
	self:RegisterEvent("ENCOUNTER_START")
	self:RegisterEvent("ENCOUNTER_END")
	self:Death("Deaths", 17537, 17307) -- Vazruden, Nazan
end

function mod:OnEngage()
	deaths = 0
	self:RegisterEvent("PLAYER_REGEN_ENABLED", "CheckForWipe")
	self:RegisterEvent("UNIT_HEALTH")
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:RAID_BOSS_EMOTE(_, _, source) -- Stage 2
	-- Vazruden is the target of this BOSS_EMOTE, but his EJ name is "Vazruden the Herald", so checking against self.displayName won't work.
	if source == self:SpellName(-5072) then -- Nazan
		self:Message("stages", "cyan", CL.stage:format(2), false)
		self:PlaySound("stages", "info")
	end
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(_, msg) -- 3.3.5: DBM Sirus, Nazan descends (stage 2)
	if msg:find(L.nazan_emote, nil, true) then
		self:Message("stages", "cyan", CL.stage:format(2), false)
		self:PlaySound("stages", "info")
		self:CDBar(36921, 12)
		self:CDBar(22686, 5)
	end
end

function mod:BellowingRoar(args) -- 3.3.5: from DBM Sirus
	self:Message(22686, "orange", CL.casting:format(args.spellName))
	if self:Interrupter() then
		self:PlaySound(22686, "alert")
	end
	self:CDBar(22686, 21)
end

function mod:Fireball() -- 3.3.5: from DBM Sirus
	self:CDBar(36921, 12)
end

function mod:ENCOUNTER_START(_, encounterId)
	if encounterId == 1892 then
		self:Engage()
	end
end

function mod:ENCOUNTER_END(_, encounterId, _, _, _, status)
	if encounterId == 1892 then
		if status == 0 then
			-- Delay slightly to avoid re-registering ENCOUNTER_END as part of :Reboot() during this ENCOUNTER_END dispatch
			self:SimpleTimer(function() self:Wipe() end, 1)
		elseif self:Retail() then -- No CLEU to count deaths
			self:Win()
		end
	end
end

function mod:Deaths()
	deaths = deaths + 1
	if deaths == 2 then
		self:Win()
	end
end

function mod:UNIT_HEALTH(event, unit)
	if self:MobId(self:UnitGUID(unit)) == 17537 then -- Vazruden
		local hp = self:GetHealth(unit)
		if hp < 46 then
			self:UnregisterEvent(event)
			if hp > 40 then
				self:Message("stages", "cyan", CL.soon:format(CL.stage:format(2)), false)
			end
		end
	end
end
