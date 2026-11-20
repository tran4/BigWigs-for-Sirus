--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-BWL/Razorgore.lua)
-- Engaged by the pull yell (the module is enabled by targeting Razorgore) or by the fight. Won when Razorgore
-- dies in stage 2, his death in stage 1 is a wipe. DBM checks the Fireball Volley cast against the Conflagration
-- id (23023), so its warning never shows: the cast (22425) is used here. Not ported: the speed clear timer.

local mod, CL = BigWigs:NewBoss("Razorgore the Untamed", 469, 1529)
if not mod then return end
mod:RegisterEnableMob(12435)
mod:SetEncounterID(610)
mod:SetWinMobs() -- 3.3.5: won by the death in stage 2 below
mod:SetEmulationWipeDelay(180) -- DBM: SetWipeTime(180)

--------------------------------------------------------------------------------
-- Locals
--

local eggsLeft = 30
local conflagList = {}

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	engage_trigger = "Intruders have breached the hatchery! Sound the alarm! Protect the eggs at all costs!", -- DBM: ends with \r\n
	stage2_trigger = "flee as the controlling power of the orb is drained.",

	adds = "Adds spawning",
	adds_desc = "Show timer for first adds spawning",
	adds_icon = 19879,
})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"stages",
		"adds",
		19873, -- Destroy Egg
		22425, -- Fireball Volley
		23023, -- Conflagration
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "FireballVolley", 22425)
	self:Log("SPELL_CAST_SUCCESS", "Stage2Cast", 23040)
	self:Log("SPELL_CAST_SUCCESS", "DestroyEgg", 19873)
	self:Log("SPELL_AURA_APPLIED", "Conflagration", 23023)
	self:Death("RazorgoreDeath", 12435)
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
	self:RegisterEvent("CHAT_MSG_MONSTER_EMOTE")
end

function mod:OnEngage()
	self:SetStage(1)
	eggsLeft = 30
	conflagList = {}
	self:Bar("adds", 47, L.adds, L.adds_icon)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if msg:find(L.engage_trigger, nil, true) and not self:IsEngaged() then
		self:Engage()
	end
end

function mod:Stage2()
	if self:IsEngaged() and self:GetStage() < 2 then
		self:SetStage(2)
		self:StopBar(L.adds)
		self:Message("stages", "cyan", CL.stage:format(2), false)
		self:PlaySound("stages", "long")
	end
end

function mod:Stage2Cast()
	self:Stage2()
end

function mod:CHAT_MSG_MONSTER_EMOTE(_, msg)
	if msg:find(L.stage2_trigger, nil, true) then
		self:Stage2()
	end
end

function mod:DestroyEgg(args)
	eggsLeft = eggsLeft - 1
	self:Message(19873, "green", CL.count_amount:format(args.spellName, 30 - eggsLeft, 30))
end

function mod:FireballVolley(args)
	self:Message(22425, "orange", CL.casting:format(args.spellName))
end

function mod:Conflagration(args)
	if self:Player(args.destFlags) then
		conflagList[#conflagList + 1] = args.destName
		self:TargetsMessage(23023, "yellow", conflagList)
	end
end

function mod:RazorgoreDeath()
	if self:IsEngaged() and self:GetStage() == 2 then
		self:Win()
	end
end
