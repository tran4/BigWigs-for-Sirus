--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-BlackTemple/EssenceOfSouls.lua, Sirus version with custom spells), draft by tools/dbm2bw
-- The essences change after 8 spirits (23469) died, like DBM. Not ported: the info frame, the health frame.

local mod, CL = BigWigs:NewBoss("Reliquary of Souls", 564, 1587)
if not mod then return end
mod:RegisterEnableMob(22856)
mod:SetEncounterID(606)

--------------------------------------------------------------------------------
-- Locals
--

local spirits, essence = 0, 1
local feverTargets, rageTargets = {}, {}
local prevKick, prevRage, prevDeceit = 0, 0, 0

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	anger = "Essence of Anger",
	desire = "Essence of Desire",
	suffering = "Essence of Suffering",
	next_stage = "Следующая фаза", -- DBM: no English text
})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"stages",
		371985, -- Fever
		{371999, "DISPEL"}, -- Rage
		{371997, "TANK"}, -- Grip
		371989, -- Deceit
		371992, -- Devouring Thirst
		371993, -- interrupt
		371984, -- Aura of Desire
		"proximity",
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "Fever", 371985)
	self:Log("SPELL_AURA_APPLIED", "Rage", 371999)
	self:Log("SPELL_AURA_APPLIED", "Grip", 371997)
	self:Log("SPELL_AURA_APPLIED_DOSE", "Grip", 371997)
	self:Log("SPELL_AURA_APPLIED", "Deceit", 371989)
	self:Log("SPELL_AURA_APPLIED_DOSE", "Deceit", 371989)
	self:Log("SPELL_CAST_START", "Thirst", 371992)
	self:Log("SPELL_CAST_START", "Kick", 371993)
	self:Log("SPELL_CAST_SUCCESS", "AuraOfDesire", 371984)
	self:Log("SPELL_CAST_SUCCESS", "RageSuccess", 371999)
	self:Log("SPELL_CAST_SUCCESS", "ThirstSuccess", 371986)
	self:Death("SpiritDeath", 23469)
end

function mod:OnEngage()
	spirits, essence = 0, 1
	feverTargets, rageTargets = {}, {}
	prevKick, prevRage, prevDeceit = 0, 0, 0
	self:OpenProximity("proximity", 9)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:SpiritDeath()
	spirits = spirits + 1
	if spirits == 8 then
		essence = (essence % 3) + 1
		local name = essence == 1 and L.anger or essence == 2 and L.desire or L.suffering
		self:SetStage(essence)
		self:Bar("stages", 11, name, "achievement_bg_returnxflags_def_wsg")
		self:Bar("stages", 101, L.next_stage, "achievement_bg_returnxflags_def_wsg")
		self:Message("stages", "cyan", CL.soon:format(name), false)
		self:PlaySound("stages", "info")
		self:SimpleTimer(function() spirits = 0 end, 2)
	end
end

function mod:AnnounceFever()
	self:TargetsMessage(371985, "yellow", feverTargets, #feverTargets)
	feverTargets = {}
end

function mod:Fever(args)
	feverTargets[#feverTargets + 1] = args.destName
	self:CancelTimer(self.feverTimer)
	self.feverTimer = self:ScheduleTimer("AnnounceFever", 0.1)
end

function mod:AnnounceRage()
	self:TargetsMessage(371999, "orange", rageTargets, #rageTargets)
	rageTargets = {}
end

function mod:Rage(args)
	rageTargets[#rageTargets + 1] = args.destName
	self:CancelTimer(self.rageTimer)
	self.rageTimer = self:ScheduleTimer("AnnounceRage", 0.1)
end

function mod:Grip(args)
	self:StackMessage(371997, "purple", args.destName, args.amount or 1, 2)
end

function mod:Deceit(args)
	if self:Me(args.destGUID) and (args.amount or 1) >= 10 and args.time - prevDeceit > 4 then
		prevDeceit = args.time
		self:StackMessage(371989, "blue", args.destName, args.amount, 10)
		self:PlaySound(371989, "alarm")
	end
end

function mod:Thirst(args)
	self:DelayedMessage(371992, 17, "red", CL.soon:format(args.spellName), nil, "runaway")
	self:CDBar(371992, 18)
end

function mod:ThirstSuccess(args)
	self:DelayedMessage(371992, 14, "red", CL.soon:format(self:SpellName(371992)), nil, "runaway")
	self:CDBar(371992, 15)
end

function mod:Kick(args)
	if args.time - prevKick > 3 then
		prevKick = args.time
		self:CDBar(371993, 10)
		if self:Interrupter(args.sourceGUID) then
			self:Message(371993, "red", CL.casting:format(args.spellName))
			self:PlaySound(371993, "alert")
		end
	end
end

function mod:AuraOfDesire(args)
	self:CDBar(371984, 9)
	self:Message(371984, "orange")
	self:PlaySound(371984, "underyou")
end

function mod:RageSuccess(args)
	if args.time - prevRage > 3 then
		prevRage = args.time
		self:CDBar(371999, 20)
		if self:Dispeller("curse", nil, 371999) then
			self:PlaySound(371999, "alert")
		end
	end
end
