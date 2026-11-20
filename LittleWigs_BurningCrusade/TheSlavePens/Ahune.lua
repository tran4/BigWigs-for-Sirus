--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("Ahune", 547)
if not mod then return end
mod:RegisterEnableMob(
	40446, -- Skar'this the Summoner
	25740, -- Ahune
	25865, -- Frozen Core
	25697 -- Luma Skymother
)
mod:SetStage(1)
if mod:Retail() then
	mod:SetEncounterID(3317)
else
	-- 3.3.5: encounter emulation with the DBM Sirus custom id (DBM-WorldEvents/Ahune.lua), the shield timers are from DBM
	mod:SetEncounterID(25740)
	mod:SetWinMobs(25740)
end
mod:SetAllowWin(true)

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	ahune = "Ahune",
	warmup_trigger = "The Ice Stone has melted!",
	warmup_icon = "spell_frost_summonwaterelemental",
})
mod.displayName = L.ahune

--------------------------------------------------------------------------------
-- Initialization
--

local autotalk = mod:AddAutoTalkOption(true, "boss")
function mod:GetOptions()
	return {
		autotalk,
		"warmup",
		45954, -- Ahune's Shield
	}, nil, {
		[45954] = CL.shield, -- Ahune's Shield (Shield)
	}
end

function mod:OnBossEnable()
	self:RegisterEvent("GOSSIP_SHOW")
	self:RegisterEvent("CHAT_MSG_MONSTER_SAY")
	self:RegisterEvent("CHAT_MSG_SAY", "CHAT_MSG_MONSTER_SAY") -- 3.3.5: DBM Sirus listens to CHAT_MSG_SAY
	self:Log("SPELL_AURA_APPLIED", "AhunesShieldApplied", 45954)
	self:Log("SPELL_AURA_REMOVED", "AhunesShieldRemoved", 45954)
	self:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT", "CheckBossStatus")
	self:Death("Win", 25740)
end

function mod:OnEngage()
	self:StopBar(CL.active)
	self:SetStage(1)
	-- Ahune's Shield is cast on pull
	if not self:Retail() then
		self:Bar(45954, 95, CL.onboss:format(CL.shield)) -- 3.3.5: DBM, the first submerge after 95s
		prevShield = GetTime() -- 3.3.5: DBM ignores the shield of the pull (shared AntiSpam)
	end
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:GOSSIP_SHOW()
	if self:GetOption(autotalk) then
		if self:GetGossipID(36888) then -- Classic
			-- 36888:Disturb the stone and summon Lord Ahune.
			self:SelectGossipID(36888)
		elseif self:GetGossipID(135555) then -- Retail
			-- 135555:Disturb the stone and summon Lord Ahune.
			self:SelectGossipID(135555)
		end
	end
end

function mod:CHAT_MSG_MONSTER_SAY(event, msg)
	if not self:IsSecret(msg) and msg == L.warmup_trigger then
		self:UnregisterEvent(event)
		self:Message("warmup", "cyan", CL.spawning:format(self.displayName), L.warmup_icon)
		self:PlaySound("warmup", "info")
		self:Bar("warmup", self:Retail() and 8.1 or 10, CL.active, L.warmup_icon) -- 3.3.5: DBM 10s
	end
end

local prevShield = 0
do
	function mod:AhunesShieldApplied(args)
		-- can be double cast, ignore the second cast
		local t = GetTime() -- 3.3.5: the OnEngage time is GetTime() too
		if t - prevShield > 5 then
			prevShield = t
			self:StopBar(CL.removed:format(CL.shield))
			self:SetStage(1)
			self:Message(args.spellId, "red", CL.onboss:format(CL.shield))
			self:PlaySound(args.spellId, "long")
			self:Bar(args.spellId, self:Retail() and 95.1 or 92, CL.onboss:format(CL.shield)) -- 3.3.5: DBM 92s
		end
	end
end

function mod:AhunesShieldRemoved(args)
	self:StopBar(CL.onboss:format(CL.shield))
	self:SetStage(2)
	self:Message(args.spellId, "green", CL.removed:format(CL.shield))
	self:PlaySound(args.spellId, "info")
	self:Bar(args.spellId, self:Retail() and 40.8 or 33.5, CL.removed:format(CL.shield)) -- 3.3.5: DBM 33.5s
end
