--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Karazhan/Attumen.lua, heroic mode with custom spells), draft by tools/dbm2bw
-- DBM lists Attumen 15550 and 34972 (Midnight is not in DBM): the pull is found when Attumen fights,
-- the death of either Attumen wins (the unmounted one despawns when he mounts Midnight).

local mod, CL = BigWigs:NewBoss("Attumen the Huntsman", 532, 1553)
if not mod then return end
mod:RegisterEnableMob(15550, 34972)
mod:SetEncounterID(652)
mod:SetWinMobs()

--------------------------------------------------------------------------------
-- Locals
--

local prevCurse = 0
local warnedStage2 = false
local trampleCount = 1
local trampleTimers = {[2] = 17, [3] = 16, [4] = 15, [5] = 14, [6] = 13, [7] = 13, [8] = 13}

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	mount_trigger = "Come Midnight, let's disperse this petty rabble!",
})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"stages",
		43127, -- Intangible Presence (curse)
		305251, -- Unseen Presence
		305258, -- Gallop (stage 2)
		305263, -- Gallop (stage 3)
		305259, -- Shared Suffering
		305264, -- Mighty Stomp
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "Curse", 43127, 29833)
	self:Log("SPELL_AURA_APPLIED", "AttumensPresence", 305265)
	self:Log("SPELL_AURA_REMOVED", "AttumensPresenceRemoved", 305265)
	self:Log("SPELL_CAST_START", "Gallop", 305258)
	self:Log("SPELL_CAST_START", "GallopStage3", 305263)
	self:Log("SPELL_CAST_START", "MightyStomp", 305264) -- 3.3.5: DBM has the handler, but does not register the spell
	self:Log("SPELL_CAST_START", "UnseenPresence", 305251)
	self:Log("SPELL_CAST_START", "SharedSuffering", 305259)
	self:Death("Win", 15550, 34972)
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
	self:RegisterEvent("UNIT_HEALTH")
end

function mod:OnEngage()
	self:SetStage(1)
	prevCurse = 0
	warnedStage2 = false
	trampleCount = 1
	if self:Difficulty() == 5 then -- 10 heroic
		self:CDBar(305251, 20)
		trampleCount = 2
	end
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:Curse(args)
	if args.time - prevCurse > 5 then
		prevCurse = args.time
		local curse = self:SpellName(43127)
		self:Message(43127, "yellow")
		self:CancelDelayedMessage(CL.soon:format(curse))
		if self:GetStage() == 2 then
			self:Bar(43127, 41)
			self:DelayedMessage(43127, 36, "yellow", CL.soon:format(curse))
		else
			self:Bar(43127, 31)
			self:DelayedMessage(43127, 26, "yellow", CL.soon:format(curse))
		end
	end
end

function mod:AttumensPresence() -- DBM: "something like stage 2" (heroic)
	self:SetStage(2)
	self:Message("stages", "cyan", CL.stage:format(2), false)
	self:CDBar(305258, 11)
	self:CDBar(305259, 21)
	self:StopBar(305251)
end

function mod:AttumensPresenceRemoved() -- stage 3
	self:SetStage(3)
	self:Message("stages", "cyan", CL.stage:format(3), false)
	self:PlaySound("stages", "long")
	self:CDBar(305263, 15)
	self:CDBar(305264, 20)
end

function mod:Gallop(args)
	self:Message(305258, "red")
	self:PlaySound(305258, "alarm")
	self:CDBar(305258, 11)
	self:CastBar(305258, 3)
end

function mod:GallopStage3(args)
	self:Message(305263, "red")
	self:PlaySound(305263, "alarm")
	self:CDBar(305263, 15)
	self:CastBar(305263, 3)
end

function mod:MightyStomp(args)
	self:Message(305264, "orange", CL.casting:format(args.spellName))
	if trampleCount >= 2 then
		local t = trampleTimers[trampleCount]
		if t then self:CDBar(305264, t) end
		trampleCount = trampleCount + 1
	end
end

function mod:UnseenPresence()
	self:CDBar(305251, 21)
end

function mod:SharedSuffering()
	self:CDBar(305259, 21)
end

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if msg == L.mount_trigger and self:IsEngaged() then
		self:SetStage(2)
		self:Message("stages", "cyan", CL.stage:format(2), false)
		self:CancelDelayedMessage(CL.soon:format(self:SpellName(43127)))
		self:Bar(43127, 25)
	end
end

function mod:UNIT_HEALTH(_, unit)
	if not warnedStage2 and self:MobId(self:UnitGUID(unit)) == 15550 and self:GetHealth(unit) <= 52 then
		warnedStage2 = true
		self:Message("stages", "cyan", CL.soon:format(CL.stage:format(2)), false)
	end
end
