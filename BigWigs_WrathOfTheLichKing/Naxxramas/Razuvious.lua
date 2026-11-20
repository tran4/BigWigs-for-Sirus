--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Naxx/MilitaryQuarter/Razuvious.lua), draft by tools/dbm2bw

local mod, CL = BigWigs:NewBoss("Instructor Razuvious", 533, 1607)
if not mod then return end
mod:RegisterEnableMob(16061)
mod:SetEncounterID(1113)

--------------------------------------------------------------------------------
-- Locals
--

local tauntGUID, wallGUID = nil, nil

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	engage_trigger1 = "Show them no mercy!",
	engage_trigger2 = "The time for practice is over! Show me what you have learned!",
	engage_trigger3 = "Do as I taught you!",
	engage_trigger4 = "Sweep the leg... Do you have a problem with that?",

	shield_wall_soon = "Shield Wall ends in 5 seconds",
})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		29107, -- Disrupting Shout
		29060, -- Taunt
		29061, -- Shield Wall
		605, -- Mind Control
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_SUCCESS", "DisruptingShout", 55543, 29107)
	self:Log("SPELL_CAST_SUCCESS", "Taunt", 29060)
	self:Log("SPELL_CAST_SUCCESS", "ShieldWall", 29061)
	self:Log("SPELL_AURA_APPLIED", "MindControl", 605)
	self:Death("UnderstudyDeath", 16803)
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
end

function mod:OnEngage()
	tauntGUID, wallGUID = nil, nil
	self:Bar(29107, 16)
	self:DelayedMessage(29107, 11, "yellow", CL.soon:format(self:SpellName(29107)))
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if not self:IsEngaged() and (msg == L.engage_trigger1 or msg == L.engage_trigger2 or msg == L.engage_trigger3 or msg == L.engage_trigger4) then
		self:Engage() -- DBM RegisterCombat("combat_yell")
	end
end

function mod:DisruptingShout(args)
	self:Message(29107, "orange")
	self:PlaySound(29107, "alert")
	self:Bar(29107, 16)
	self:DelayedMessage(29107, 11, "yellow", CL.soon:format(self:SpellName(29107)))
end

function mod:Taunt(args)
	tauntGUID = args.sourceGUID -- 3.3.5: one bar for all Understudies (DBM: a bar per Understudy)
	self:CDBar(29060, 20)
end

function mod:ShieldWall(args)
	wallGUID = args.sourceGUID
	self:CDBar(29061, 20)
	self:CancelDelayedMessage(L.shield_wall_soon)
	self:DelayedMessage(29061, 15, "yellow", L.shield_wall_soon)
end

function mod:MindControl(args)
	if self:Player(args.sourceFlags) then
		self:TargetBar(605, 60, args.sourceName)
	end
end

function mod:UnderstudyDeath(args)
	if args.destGUID == tauntGUID then
		self:StopBar(29060)
	end
	if args.destGUID == wallGUID then
		self:StopBar(29061)
		self:CancelDelayedMessage(L.shield_wall_soon)
	end
end
