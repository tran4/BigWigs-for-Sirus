--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Naxx/MilitaryQuarter/Horsemen.lua), draft by tools/dbm2bw

local mod, CL = BigWigs:NewBoss("The Four Horsemen", 533, 1609)
if not mod then return end
mod:RegisterEnableMob(16063, 16064, 16065, 30549) -- Sir Zeliek, Thane Korth'azz, Lady Blaumeux, Baron Rivendare
mod:SetEncounterID(1121)
mod:SetWinMobs(16063, 16064, 16065, 30549) -- 3.3.5: all four must die

--------------------------------------------------------------------------------
-- Locals
--

local markCount = 0
local prevMark = {}

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	mark_soon = "Mark %d in 3 seconds",
	mark_soon_desc = "Show pre-warning for Mark",
	mark_soon_icon = 28835,
})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		{"mark_soon", "OFF"},
		28833, -- Mark of Blaumeux
		28835, -- Mark of Zeliek
		28834, -- Mark of Rivendare
		28832, -- Mark of Korth'azz
		57467, -- Meteor
		{28863, "SAY"}, -- Void Zone
		{28883, "OFF"}, -- Holy Wrath
		29061, -- Bone Barrier
		"proximity",
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "Meteor", 28884, 57467)
	self:Log("SPELL_CAST_SUCCESS", "Mark", 28832, 28833, 28834, 28835)
	self:Log("SPELL_AURA_APPLIED_DOSE", "MarkDose", 28832, 28833, 28834, 28835)
	self:Log("SPELL_CAST_SUCCESS", "VoidZone", 28863) -- 3.3.5: DBM has the handler, but does not register the event
	self:Log("SPELL_CAST_SUCCESS", "HolyWrath", 28883, 53638, 57466, 32455)
	self:Log("SPELL_AURA_APPLIED", "BoneBarrier", 29061)
	self:Log("SPELL_AURA_REMOVED", "BoneBarrierRemoved", 29061)
	self:Death("ThaneDeath", 16064)
	self:Death("BaronDeath", 30549)
	self:Death("LadyDeath", 16065)
	self:Death("ZeliekDeath", 16063)
end

function mod:OnEngage()
	markCount = 0
	prevMark = {}
	self:Bar(28833, 16)
	self:Bar(28835, 16)
	self:Bar(28834, 15)
	self:Bar(28832, 15)
	self:DelayedMessage("mark_soon", 12, "yellow", L.mark_soon:format(1), L.mark_soon_icon)
	self:CDBar(57467, 15)
	self:OpenProximity("proximity", 12)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:Meteor(args)
	self:Message(57467, "red")
	self:PlaySound(57467, "alert")
	self:CancelTimer(self.meteorTimer)
	self:MeteorCD()
end

function mod:MeteorCD() -- DBM: still a 15s timer when he skips one (usually on tank swaps)
	self:CDBar(57467, 15)
	self:CancelTimer(self.meteorTimer)
	self.meteorTimer = self:ScheduleTimer("MeteorCD", 15)
end

function mod:Mark(args)
	if args.time - (prevMark[args.spellId] or 0) > 5 then
		prevMark[args.spellId] = args.time
		markCount = markCount + 1
		self:Bar(args.spellId, 15)
		self:CancelDelayedMessage(L.mark_soon:format(markCount))
		self:DelayedMessage("mark_soon", 12, "yellow", L.mark_soon:format(markCount + 1), L.mark_soon_icon)
	end
end

function mod:MarkDose(args)
	if self:Me(args.destGUID) and (args.amount or 1) >= 4 then
		self:StackMessage(args.spellId, "blue", args.destName, args.amount, 4)
		self:PlaySound(args.spellId, "alarm")
	end
end

function mod:VoidZone(args)
	if self:Me(args.destGUID) then
		self:PersonalMessage(28863)
		self:PlaySound(28863, "warning")
		self:Say(28863)
	end
end

function mod:HolyWrath(args)
	self:TargetMessage(28883, "orange", args.destName)
	self:CDBar(28883, 13)
end

function mod:BoneBarrier(args)
	self:TargetMessage(29061, "yellow", args.destName)
	self:TargetBar(29061, 20, args.destName)
end

function mod:BoneBarrierRemoved(args)
	self:StopBar(args.spellName, args.destName)
end

function mod:ThaneDeath()
	self:StopBar(28832)
	self:StopBar(57467)
	self:CancelTimer(self.meteorTimer)
end

function mod:BaronDeath()
	self:StopBar(28834)
end

function mod:LadyDeath()
	self:StopBar(28833)
end

function mod:ZeliekDeath()
	self:StopBar(28835)
end
