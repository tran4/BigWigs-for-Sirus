--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Ulduar/GeneralVezax.lua), draft by tools/dbm2bw
-- Not ported: the DBM arrow away from Shadow Crash.

local mod, CL = BigWigs:NewBoss("General Vezax", 603, 1648)
if not mod then return end
mod:RegisterEnableMob(33271)
mod:SetEncounterID(755)

--------------------------------------------------------------------------------
-- Locals
--

local interruptCount = 0
local vaporsCount = 0

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	animus = "Saronite Animus spawn",
	animus_desc = "Show timer for Saronite Animus spawn (hard mode)",
	animus_icon = 63145,
})

--------------------------------------------------------------------------------
-- Initialization
--

local crashMarker = mod:AddMarkerOption(true, "player", 8, 312978, 8)
local leechMarker = mod:AddMarkerOption(true, "player", 7, 312974, 7)
function mod:GetOptions()
	return {
		"berserk",
		312977, -- Searing Flames
		{312981, "TANK"}, -- Surge of Darkness
		{312978, "SAY"}, -- Shadow Crash
		crashMarker,
		{312974, "SAY"}, -- Mark of the Faceless
		leechMarker,
		63322, -- Saronite Vapors
		"animus",
		63145, -- Saronite Animus
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "SearingFlames", 312977, 62661)
	self:Log("SPELL_INTERRUPT", "SearingFlamesInterrupted", 312977, 62661)
	self:Log("SPELL_CAST_START", "SurgeOfDarkness", 312981, 62662)
	self:Log("SPELL_AURA_APPLIED", "SurgeOfDarknessApplied", 312981, 62662)
	self:Log("SPELL_AURA_REMOVED", "SurgeOfDarknessRemoved", 312981, 62662)
	self:Log("SPELL_CAST_SUCCESS", "ShadowCrash", 312978, 62660)
	self:Log("SPELL_CAST_SUCCESS", "MarkOfTheFaceless", 312974, 63276, 312621)
	self:Log("SPELL_CAST_SUCCESS", "SaroniteAnimus", 63364)
end

function mod:OnEngage()
	interruptCount = 0
	vaporsCount = 0
	self:CDBar(312978, 9)
	self:CDBar(312974, 39)
	self:Bar(63322, 30, CL.count:format(self:SpellName(63322), 1))
	self.vaporsTimer = self:ScheduleTimer("Vapors", 30)
	self:Berserk(600)
	self:Bar("animus", 195, L.animus, L.animus_icon)
	self:CDBar(312981, 61.7)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:Vapors()
	vaporsCount = vaporsCount + 1
	self:Bar(63322, 34, CL.count:format(self:SpellName(63322), vaporsCount + 1))
	self:DelayedMessage(63322, 30, "yellow", CL.soon:format(self:SpellName(63322)))
	self.vaporsTimer = self:ScheduleTimer("Vapors", 34)
end

function mod:SearingFlames(args)
	interruptCount = interruptCount % 3 + 1 -- interrupt rotation 1-2-3
	self:Message(312977, "yellow", CL.count:format(args.spellName, interruptCount))
	if self:Interrupter(args.sourceGUID) then
		self:PlaySound(312977, "alert")
	end
	self:CastBar(312977, 2)
end

function mod:SearingFlamesInterrupted(args)
	self:StopCastBar(312977)
end

function mod:SurgeOfDarkness(args)
	local tanking = UnitDetailedThreatSituation("player", "boss1")
	if tanking then
		self:Message(312981, "purple")
		self:PlaySound(312981, "alarm") -- defensive
	end
	self:CDBar(312981, 61.7)
end

function mod:SurgeOfDarknessApplied(args)
	self:CastBar(312981, 10)
end

function mod:SurgeOfDarknessRemoved(args)
	self:StopCastBar(312981)
end

do
	local function printTarget(self, name, guid)
		self:CustomIcon(crashMarker, name, 8)
		self:ScheduleTimer("CustomIcon", 5, crashMarker, name)
		if self:Me(guid) then
			self:PersonalMessage(312978)
			self:PlaySound(312978, "warning") -- run away
			self:Say(312978)
		else
			local unit = self:UnitTokenFromGUID(guid)
			if unit and self:UnitWithinRange(unit, 11) then
				self:Message(312978, "orange", CL.near:format(self:SpellName(312978)))
				self:PlaySound(312978, "alarm")
			else
				self:TargetMessage(312978, "orange", name)
			end
		end
	end
	function mod:ShadowCrash(args)
		self:GetUnitTarget(printTarget, 0.1, args.sourceGUID)
		self:CDBar(312978, 13.5)
	end
end

function mod:MarkOfTheFaceless(args)
	self:CustomIcon(leechMarker, args.destName, 7)
	self:ScheduleTimer("CustomIcon", 10, leechMarker, args.destName)
	self:TargetBar(312974, 10, args.destName)
	self:CDBar(312974, 40)
	if self:Me(args.destGUID) then
		self:PersonalMessage(312974)
		self:PlaySound(312974, "warning") -- run out
		self:Say(312974)
	else
		self:TargetMessage(312974, "red", args.destName)
	end
end

function mod:SaroniteAnimus(args)
	self:Message(63145, "red")
	self:PlaySound(63145, "long") -- switch to the big add
	self:CancelTimer(self.vaporsTimer)
	self:StopBar(CL.count:format(self:SpellName(63322), vaporsCount + 1))
	self:CancelDelayedMessage(CL.soon:format(self:SpellName(63322)))
end
