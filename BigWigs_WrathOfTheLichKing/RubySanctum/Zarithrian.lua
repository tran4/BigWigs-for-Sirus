--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-ChamberOfAspects/Ruby/Zarithrian.lua), draft by tools/dbm2bw
-- No journal id: the name is from the DBM localization. Not ported: cancelling Hand of Protection/Divine Shield.

local mod, CL = BigWigs:NewBoss("General Zarithrian", 724)
if not mod then return end
mod:RegisterEnableMob(39746)
mod:SetEncounterID(1149)

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	bossName = "General Zarithrian",
	adds_trigger = "Turn them to ash, minions!",
	new_adds = "New adds",
	adds_arrive = "Adds arrive in",
})
mod.displayName = L.bossName

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"adds",
		74384, -- Intimidating Roar
		{74367, "TANK_HEALER"}, -- Cleave Armor
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "IntimidatingRoar", 74384)
	self:Log("SPELL_AURA_APPLIED", "CleaveArmor", 74367)
	self:Log("SPELL_AURA_APPLIED_DOSE", "CleaveArmor", 74367)
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
end

function mod:OnEngage()
	self:CDBar(74384, 14)
	self:DelayedMessage(74384, 11, "yellow", CL.soon:format(self:SpellName(74384)))
	self:Bar("adds", 18, L.new_adds, 74398)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if self:IsEngaged() and msg:find(L.adds_trigger) then -- DBM: msg:match
		self:Message("adds", "cyan", L.new_adds, 74398)
		self:Bar("adds", 40, L.new_adds, 74398)
		self:Bar("adds", 10, L.adds_arrive, 74398)
	end
end

function mod:IntimidatingRoar(args)
	self:Message(74384, "red")
	self:PlaySound(74384, "alarm")
	self:DelayedMessage(74384, 27, "yellow", CL.soon:format(args.spellName))
	self:CDBar(74384, 30)
end

function mod:CleaveArmor(args)
	local amount = args.amount or 1
	self:TargetBar(74367, 30, args.destName)
	if self:Me(args.destGUID) and amount >= 2 then
		self:StackMessage(74367, "blue", args.destName, amount, 2)
		self:PlaySound(74367, "alarm")
	else
		self:StackMessage(74367, "purple", args.destName, amount, 2)
	end
end
