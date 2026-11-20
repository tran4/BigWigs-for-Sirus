--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Naxx/ArachnidQuarter/Anub'Rekhan.lua), draft by tools/dbm2bw
-- The Arachnophobia achievement bar (DBM ArachnophobiaTimer) is shown by the Maexxna module, enabled on the win.

local mod, CL = BigWigs:NewBoss("Anub'Rekhan", 533, 1601)
if not mod then return end
mod:RegisterEnableMob(15956)
mod:SetEncounterID(1107)

--------------------------------------------------------------------------------
-- Locals
--

local myRealm = false -- 3.3.5: DBM Sirus has other Locust Swarm timers on the x1 realm

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	engage_trigger1 = "Yes, run! It makes the blood pump faster!",
	engage_trigger2 = "Just a little taste...",
})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		28785, -- Locust Swarm
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "LocustSwarm", 28785, 54021)
	self:Log("SPELL_AURA_REMOVED", "LocustSwarmRemoved", 28785, 54021)
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
end

function mod:OnEngage()
	myRealm = BigWigsLoader.Compat.GetRealmNumber() == 1
	if self:Difficulty() == 4 then -- 25 player
		self:CDBar(28785, myRealm and 60 or 100)
		self:DelayedMessage(28785, myRealm and 60 or 90, "yellow", CL.soon:format(self:SpellName(28785)))
	else
		self:CDBar(28785, myRealm and 50 or 91)
		self:DelayedMessage(28785, myRealm and 50 or 76, "yellow", CL.soon:format(self:SpellName(28785)))
	end
end

function mod:OnWin()
	-- DBM: Arachnophobia - kill Maexxna within 20 minutes of Anub'Rekhan
	local maexxna = BigWigs:GetBossModule("Maexxna", true)
	if maexxna then
		if not maexxna:IsEnabled() then maexxna:Enable() end
		maexxna:Arachnophobia()
	end
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if (msg == L.engage_trigger1 or msg == L.engage_trigger2) and not self:IsEngaged() then
		self:Engage() -- DBM RegisterCombat("combat_yell")
	end
end

function mod:LocustSwarm()
	self:Message(28785, "orange")
	self:PlaySound(28785, "alert")
	self:StopBar(28785)
	if self:Difficulty() == 4 then
		self:CastBar(28785, myRealm and 10 or 23)
	else
		self:CastBar(28785, myRealm and 10 or 19)
	end
end

function mod:LocustSwarmRemoved(args)
	if not self:Player(args.destFlags) then -- DBM: auraType == "BUFF" (the boss)
		self:Message(28785, "cyan", CL.removed:format(args.spellName))
		self:CDBar(28785, myRealm and 45 or 90)
		self:DelayedMessage(28785, myRealm and 40 or 62, "yellow", CL.soon:format(args.spellName))
	end
end
