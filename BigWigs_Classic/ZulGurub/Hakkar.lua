--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-ZG/Hakkar.lua), no journal id: the name is from the DBM locale.
-- The aspect timers start on the pull only in the hard mode (DBM: Hakkar has at least 1079325 health, the priests
-- are alive). DBM closes the range frame on the removal of Living Bomb (20475): Corrupted Blood is used here.

local mod, CL = BigWigs:NewBoss("Hakkar the Soulflayer", 309)
if not mod then return end
mod:RegisterEnableMob(14834)
mod:SetEncounterID(793)

--------------------------------------------------------------------------------
-- Locals
--

local scanUnits = {"target", "focus"}
for i = 1, 40 do scanUnits[#scanUnits + 1] = "raid" .. i .. "target" end
for i = 1, 4 do scanUnits[#scanUnits + 1] = "party" .. i .. "target" end

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	bossName = "Hakkar the Soulflayer",
})
mod.displayName = L.bossName

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"berserk",
		24324, -- Blood Siphon
		24327, -- Cause Insanity
		{24328, "PROXIMITY"}, -- Corrupted Blood (DBM: the yell is off by default)
		24686, -- Aspect of Mar'li
		24687, -- Aspect of Jeklik
		24688, -- Aspect of Venoxis
		24689, -- Aspect of Thekal
		24690, -- Aspect of Arlokk
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_SUCCESS", "BloodSiphon", 24324)
	self:Log("SPELL_CAST_SUCCESS", "AspectCast", 24686, 24687, 24688, 24689, 24690)
	self:Log("SPELL_AURA_APPLIED", "CauseInsanity", 24327)
	self:Log("SPELL_AURA_APPLIED", "CorruptedBlood", 24328)
	self:Log("SPELL_AURA_REMOVED", "CorruptedBloodRemoved", 24328)
	self:Log("SPELL_AURA_APPLIED", "AspectOfMarli", 24686)
	self:Log("SPELL_AURA_APPLIED", "AspectOfJeklik", 24687)
	self:Log("SPELL_AURA_APPLIED", "AspectOfThekal", 24689)
	self:Log("SPELL_AURA_REMOVED", "AspectOfThekalRemoved", 24689)
	self:Log("SPELL_AURA_APPLIED", "AspectOfArlokk", 24690)
end

local function isHardMode(self)
	for i = 1, #scanUnits do
		local unit = scanUnits[i]
		if self:MobId(self:UnitGUID(unit)) == 14834 then
			return UnitHealthMax(unit) >= 1079325
		end
	end
	return false
end

function mod:OnEngage()
	self:Berserk(585)
	self:Bar(24324, 90)
	self:DelayedMessage(24324, 80, "yellow", CL.soon:format(self:SpellName(24324)))
	if isHardMode(self) then
		self:CDBar(24686, 10)
		self:CDBar(24689, 10)
		self:CDBar(24688, 14)
		self:CDBar(24687, 21)
		self:CDBar(24690, 30)
	end
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:BloodSiphon(args)
	self:Message(24324, "orange")
	self:Bar(24324, 90)
	self:CancelDelayedMessage(CL.soon:format(args.spellName))
	self:DelayedMessage(24324, 80, "yellow", CL.soon:format(args.spellName))
end

do
	local cds = {[24686] = 16, [24687] = 23, [24688] = 16.2, [24689] = 15.8, [24690] = 30}
	function mod:AspectCast(args)
		self:CDBar(args.spellId, cds[args.spellId])
	end
end

function mod:CauseInsanity(args)
	self:TargetMessage(24327, "red", args.destName)
	self:TargetBar(24327, 10, args.destName)
	self:CDBar(24327, 20)
end

function mod:CorruptedBlood(args)
	if self:Me(args.destGUID) then
		self:PersonalMessage(24328)
		self:PlaySound(24328, "alarm") -- DBM: run out
		self:OpenProximity(24328, 10)
	else
		self:TargetMessage(24328, "yellow", args.destName)
	end
end

function mod:CorruptedBloodRemoved(args)
	if self:Me(args.destGUID) then
		self:CloseProximity(24328)
	end
end

function mod:AspectOfMarli(args)
	self:TargetMessage(24686, "orange", args.destName)
	self:TargetBar(24686, 6, args.destName)
end

function mod:AspectOfJeklik(args)
	self:TargetBar(24687, 5, args.destName) -- DBM: the timer is off by default
end

function mod:AspectOfThekal(args)
	if not self:Player(args.destFlags) then
		self:Message(24689, "orange", CL.onboss:format(args.spellName))
		if self:Dispeller("enrage", true) then
			self:PlaySound(24689, "alarm") -- DBM: dispel the enrage
		end
		self:Bar(24689, 8, CL.other:format(args.spellName, CL.active))
	end
end

function mod:AspectOfThekalRemoved(args)
	if not self:Player(args.destFlags) then
		self:StopBar(CL.other:format(args.spellName, CL.active))
	end
end

function mod:AspectOfArlokk(args)
	self:TargetMessage(24690, "red", args.destName)
	self:TargetBar(24690, 2, args.destName)
end
