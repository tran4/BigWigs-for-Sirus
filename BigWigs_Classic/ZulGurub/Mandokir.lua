--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-ZG/Bloodlord.lua), no journal id: the name is from the DBM locale.
-- Won when Mandokir and Ohgan died (DBM creature ids).

local mod, CL = BigWigs:NewBoss("Bloodlord Mandokir", 309)
if not mod then return end
mod:RegisterEnableMob(11382, 14988) -- Bloodlord Mandokir, Ohgan
mod:SetEncounterID(787)
mod:SetWinMobs(11382, 14988)

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	bossName = "Bloodlord Mandokir",
	gaze_trigger = "I'm watching you",
})
mod.displayName = L.bossName

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		24314, -- Threatening Gaze
		{24318, "TANK_HEALER"}, -- Frenzy (DBM: tanks and healers only)
		{16856, "TANK_HEALER"}, -- Mortal Strike (DBM: tanks and healers only)
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "ThreateningGaze", 24314)
	self:Log("SPELL_AURA_APPLIED", "Frenzy", 24318)
	self:Log("SPELL_AURA_APPLIED", "MortalStrike", 16856)
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
end

--------------------------------------------------------------------------------
-- Event Handlers
--

do
	local prev = {}
	function mod:GazeWarning(name)
		local t = GetTime()
		if t - (prev[name] or 0) <= 3 then return end
		prev[name] = t
		if self:UnitName("player") == name then
			self:PersonalMessage(24314)
			self:PlaySound(24314, "warning") -- DBM: stop casting
		else
			self:TargetMessage(24314, "red", name)
		end
	end
end

function mod:ThreateningGaze(args)
	self:TargetBar(24314, 6, args.destName)
	self:GazeWarning(args.destName)
end

function mod:CHAT_MSG_MONSTER_YELL(_, msg, _, _, _, target)
	if msg:find(L.gaze_trigger, nil, true) and target and self:IsEngaged() then
		self:GazeWarning(target)
	end
end

function mod:Frenzy(args)
	if not self:Player(args.destFlags) then
		self:Message(24318, "orange", CL.other:format(args.spellName, args.destName))
	end
end

function mod:MortalStrike(args)
	if self:Player(args.destFlags) then
		self:TargetMessage(16856, "purple", args.destName)
		self:TargetBar(16856, 5, args.destName)
	end
end
