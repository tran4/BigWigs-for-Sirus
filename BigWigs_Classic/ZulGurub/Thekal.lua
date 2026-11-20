--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-ZG/Thekal.lua), no journal id: the name is from the DBM locale.
-- Won by the kill yell like DBM (RegisterKill). DBM registers SPELL_SUMMON 24813 but checks 24183 for the adds:
-- both are used here.

local mod, CL = BigWigs:NewBoss("High Priest Thekal", 309)
if not mod then return end
mod:RegisterEnableMob(14509, 11348, 11347) -- High Priest Thekal, Zealot Zath, Zealot Lor'Khan
mod:SetEncounterID(789)
mod:SetWinMobs() -- 3.3.5: won by the kill yell below

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	bossName = "High Priest Thekal",
	priest_died_trigger = "%s dies.",
	stage2_trigger = "Shirvallah, fill me with your RAGE!",
	win_trigger = "Hakkar binds me no more!  Peace at last!",

	resurrection = "Resurrection",
	resurrection_desc = "Announce first mob down, resurrection soon, show timer for priest resurrection",
	resurrection_icon = 24173,
	resurrection_message = "First add down - Resurrection in ~15 seconds",
})
mod.displayName = L.bossName

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"stages",
		"resurrection",
		24208, -- Great Heal
		21060, -- Blind
		12540, -- Gouge
		24183, -- Summon Zulian Guardians
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "GreatHeal", 24208)
	self:Log("SPELL_AURA_APPLIED", "Blind", 21060)
	self:Log("SPELL_AURA_REMOVED", "BlindRemoved", 21060)
	self:Log("SPELL_AURA_APPLIED", "Gouge", 12540)
	self:Log("SPELL_AURA_REMOVED", "GougeRemoved", 12540)
	self:Log("SPELL_SUMMON", "Adds", 24813, 24183)
	self:RegisterEvent("CHAT_MSG_MONSTER_EMOTE")
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
end

function mod:OnEngage()
	self:SetStage(1)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:GreatHeal(args)
	if self:Hostile(args.sourceFlags) and (self:UnitGUID("target") == args.sourceGUID or self:UnitGUID("focus") == args.sourceGUID) and self:Interrupter() then
		self:Message(24208, "red", CL.casting:format(args.spellName))
		self:PlaySound(24208, "alert") -- DBM: interrupt
	end
end

function mod:Blind(args)
	if self:Player(args.destFlags) then
		self:TargetMessage(21060, "yellow", args.destName)
		self:TargetBar(21060, 10, args.destName)
	end
end

function mod:BlindRemoved(args)
	self:StopBar(21060, args.destName)
end

function mod:Gouge(args)
	if self:Player(args.destFlags) then
		self:TargetMessage(12540, "yellow", args.destName)
		self:TargetBar(12540, 4, args.destName)
	end
end

function mod:GougeRemoved(args)
	self:StopBar(12540, args.destName)
end

do
	local prev = 0
	function mod:Adds(args)
		if args.time - prev > 3 then
			prev = args.time
			self:Message(24183, "orange")
		end
	end
end

do
	local prev = 0
	function mod:CHAT_MSG_MONSTER_EMOTE(_, msg)
		local t = GetTime()
		if self:IsEngaged() and msg:find(L.priest_died_trigger, nil, true) and t - prev > 20 then
			prev = t
			self:Message("resurrection", "yellow", L.resurrection_message, L.resurrection_icon)
			self:Bar("resurrection", 15, L.resurrection, L.resurrection_icon)
		end
	end
end

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if not self:IsEngaged() then return end
	if msg:find(L.win_trigger, nil, true) then
		self:Win()
	elseif msg:find(L.stage2_trigger, nil, true) and self:GetStage() < 2 then
		self:SetStage(2)
		self:Message("stages", "cyan", CL.stage:format(2), false)
		self:PlaySound("stages", "long")
		self:StopBar(L.resurrection)
	end
end
