--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("Shirrak the Dead Watcher", 558, 523)
if not mod then return end
mod:RegisterEnableMob(18371)
mod:SetEncounterID(1890)
--mod:SetRespawnTime(0) -- resets, doesn't respawn

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		{-5041, "ME_ONLY_EMPHASIZE", "SAY"}, -- Focus Fire
		32264, -- Inhibit Magic (3.3.5: DBM Sirus)
		39382, -- Carnivorous Bite (3.3.5: DBM Sirus)
		32265, -- Attract Magic (3.3.5: DBM Sirus)
	}
end

function mod:OnBossEnable()
	self:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE")
	self:Log("SPELL_AURA_APPLIED", "InhibitMagic", 32264) -- 3.3.5: DBM Sirus
	self:Log("SPELL_CAST_SUCCESS", "CarnivorousBite", 39382) -- 3.3.5: DBM Sirus
	self:Log("SPELL_CAST_SUCCESS", "AttractMagic", 32265) -- 3.3.5: DBM Sirus
end

function mod:OnEngage() -- 3.3.5: DBM Sirus timers
	self:CDBar(32264, 3.3)
	self:CDBar(39382, 10)
	self:CDBar(32265, 30)
	self:CDBar(-5041, 15)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:CHAT_MSG_RAID_BOSS_EMOTE(_, _, source, _, _, target) -- Focus Fire
	if not self:IsSecret(source) and not self:IsSecret(target) and source == self.displayName then -- this is the only BOSS_EMOTE that appears during this encounter
		target = self:Ambiguate(target, "none")
		self:TargetMessage(-5041, "yellow", target)
		if not self:Retail() then
			self:CDBar(-5041, 15) -- 3.3.5: DBM Sirus
		end
		local guid = self:UnitGUID(target)
		if self:Me(guid) then
			self:Say(-5041, nil, nil, "Focus Fire")
			self:PlaySound(-5041, "warning", nil, self:UnitName("player"))
		end
	end
end

-- 3.3.5: DBM Sirus
do
	local prev = 0
	function mod:InhibitMagic(args)
		if args.time - prev > 1 then
			prev = args.time
			self:CDBar(32264, 3.3)
		end
	end
end

function mod:CarnivorousBite()
	self:CDBar(39382, 10)
end

function mod:AttractMagic(args)
	self:Message(32265, "orange")
	self:CDBar(32265, 30)
end
