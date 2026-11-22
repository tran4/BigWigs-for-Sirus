--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Naxx/MilitaryQuarter/Razuvious.lua), draft by tools/dbm2bw
-- Heroic casts and debuffs not in DBM, from the players' WeakAuras (WA: "Naxx", group "instruktor"): the casts by the
-- ids from the spell cache of WeakAuras (Взмах, Парирование, Сокрушительный удар, Боевой клич), Dark Bindings and Dark
-- Pact on you.

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
		372069, -- WA: "Взмах"
		372070, -- WA: "Парирование"
		372071, -- WA: "Сокрушительный удар"
		372072, -- WA: "Боевой клич"
		373475, -- Dark Bindings (WA)
		373479, -- Dark Pact (WA)
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_SUCCESS", "DisruptingShout", 55543, 29107)
	self:Log("SPELL_CAST_SUCCESS", "Taunt", 29060)
	self:Log("SPELL_CAST_SUCCESS", "ShieldWall", 29061)
	self:Log("SPELL_AURA_APPLIED", "MindControl", 605)
	self:Log("SPELL_CAST_START", "HeroicCast", 372069, 372074, 372070, 372075, 372071, 372076, 372072, 372077) -- WA
	self:Log("SPELL_AURA_APPLIED", "DarkDebuff", 373475, 373476, 373479, 373480) -- WA
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

--------------------------------------------------------------------------------
-- Heroic (WA: "Naxx", group "instruktor")
--

local heroicKey = {[372074] = 372069, [372075] = 372070, [372076] = 372071, [372077] = 372072} -- the second ids of the WA spells
function mod:HeroicCast(args)
	local key = heroicKey[args.spellId] or args.spellId
	self:Message(key, "orange", args.spellName) -- 3.3.5: no "Casting" prefix (user), the name only
end

function mod:DarkDebuff(args)
	if self:Me(args.destGUID) then
		local key = (args.spellId == 373475 or args.spellId == 373476) and 373475 or 373479
		self:PersonalMessage(key)
		self:PlaySound(key, "alarm")
	end
end
