--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Naxx/ArachnidQuarter/Faerlina.lua), draft by tools/dbm2bw

local mod, CL = BigWigs:NewBoss("Grand Widow Faerlina", 533, 1602)
if not mod then return end
mod:RegisterEnableMob(15953)
mod:SetEncounterID(1110)

--------------------------------------------------------------------------------
-- Locals
--

local enraged = false
local prevEmbrace = 0

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	engage_trigger = "Kneel before me, worm!", -- DBM: not actually the pull, but often said on pull
	embrace_expire = "Widow's Embrace ends in 5 seconds",
})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		28131, -- Frenzy
		28732, -- Widow's Embrace
		54098, -- Poison Bolt Volley
		28794, -- Rain of Fire
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "Frenzy", 28798, 54100)
	self:Log("SPELL_AURA_APPLIED", "WidowsEmbrace", 28732, 54097)
	self:Log("SPELL_AURA_APPLIED", "RainOfFire", 28794, 54099)
	self:Log("SPELL_CAST_SUCCESS", "PoisonBoltVolley", 28796, 54098)
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
end

function mod:OnEngage()
	enraged = false
	prevEmbrace = 0
	self:CDBar(28131, BigWigsLoader.Compat.GetRealmNumber() == 1 and 30 or 60) -- 3.3.5: DBM Sirus x1 realm timer
	self:DelayedMessage(28131, 55, "yellow", CL.soon:format(self:SpellName(28131)))
	self:CDBar(54098, 12)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if msg == L.engage_trigger and not self:IsEngaged() then
		self:Engage() -- DBM RegisterCombat("combat_yell")
	end
end

function mod:Frenzy()
	enraged = true
	self:Message(28131, "red")
	if self:Tank() then -- DBM: special warning for the tank
		self:PlaySound(28131, "warning")
	end
end

function mod:WidowsEmbrace(args)
	if self:MobId(args.destGUID) == 15953 and args.time - prevEmbrace > 5 then
		prevEmbrace = args.time
		local embrace = self:SpellName(28732)
		self:CancelDelayedMessage(L.embrace_expire)
		self:CancelDelayedMessage(CL.removed:format(embrace))
		self:CancelDelayedMessage(CL.soon:format(self:SpellName(28131)))
		self:StopBar(28131)
		if enraged then
			self:CDBar(28131, 60)
			self:DelayedMessage(28131, 45, "yellow", CL.soon:format(self:SpellName(28131)))
		end
		self:CastBar(28732, 30)
		self:Message(28732, "green")
		self:DelayedMessage(28732, 25, "orange", L.embrace_expire)
		self:DelayedMessage(28732, 30, "yellow", CL.removed:format(embrace))
		enraged = false
	end
end

function mod:RainOfFire(args)
	if self:Me(args.destGUID) then
		self:PersonalMessage(28794, "underyou")
		self:PlaySound(28794, "underyou")
	end
end

function mod:PoisonBoltVolley()
	self:CDBar(54098, 10)
end
