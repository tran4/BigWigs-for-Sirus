--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Sunwell/EredarTwins.lua), draft by tools/dbm2bw
-- Won when both twins died. Not ported: the "near you" warnings (DBM checks 2 yards) and the target emotes that DBM
-- itself marks as not working.

local mod, CL = BigWigs:NewBoss("The Eredar Twins", 580, 1594)
if not mod then return end
mod:RegisterEnableMob(25165, 25166) -- Lady Sacrolash, Grand Warlock Alythess
mod:SetEncounterID(727)
mod:SetWinMobs(25165, 25166)

--------------------------------------------------------------------------------
-- Initialization
--

local novaMarker = mod:AddMarkerOption(false, "player", 7, 45329, 7)
local conflagMarker = mod:AddMarkerOption(false, "player", 8, 45333, 8)
function mod:GetOptions()
	return {
		"stages",
		{45329, "SAY"}, -- Shadow Nova
		novaMarker,
		45333, -- Conflagration
		conflagMarker,
		45248, -- Shadow Blades
		45256, -- Confounding Blow
		45230, -- Pyrogenics
		45347, -- Dark Touched
		{45348, "OFF"}, -- Flame Touched
		"proximity",
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "Pyrogenics", 45230)
	self:Log("SPELL_AURA_APPLIED", "Touched", 45347, 45348)
	self:Log("SPELL_AURA_APPLIED_DOSE", "Touched", 45347, 45348)
	self:Log("SPELL_DAMAGE", "ConfoundingBlow", 45256)
	self:Log("SPELL_MISSED", "ConfoundingBlowMissed", 45256)
	self:Log("SPELL_CAST_START", "ShadowBlades", 45248)
	self:Log("SPELL_CAST_START", "ShadowNova", 45329)
	self:Log("SPELL_CAST_START", "Conflagration", 45342)
	self:Death("AlythessDeath", 25166, 21566) -- 3.3.5: DBM checks 21566, the id of Alythess is 25166
end

function mod:OnEngage()
	self:SetStage(1)
	self:CDBar(45333, 18)
	self:OpenProximity("proximity", 12)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:AlythessDeath()
	self:SetStage(2)
end

function mod:Pyrogenics(args)
	if not self:Player(args.destFlags) and self:Dispeller("magic", true) then
		self:Message(45230, "orange", CL.on:format(args.spellName, args.destName))
		self:PlaySound(45230, "alert")
	end
end

function mod:Touched(args)
	local limit = args.spellId == 45347 and 8 or 5
	if self:Me(args.destGUID) and (args.amount or 1) >= limit then
		self:StackMessage(args.spellId, "blue", args.destName, args.amount, limit)
		self:PlaySound(args.spellId, "alarm")
	end
end

function mod:ConfoundingBlow(args)
	self:TargetMessage(45256, "orange", args.destName)
	self:CDBar(45256, 20)
end

function mod:ConfoundingBlowMissed()
	self:CDBar(45256, 20)
end

function mod:ShadowBlades(args)
	self:Message(45248, "orange")
	self:CDBar(45248, 11.5)
end

do
	local function novaTarget(self, name, guid)
		self:TargetMessage(45329, "red", name)
		self:CustomIcon(novaMarker, name, 7)
		self:ScheduleTimer("CustomIcon", 5, novaMarker, name)
		if self:Me(guid) then
			self:PlaySound(45329, "warning")
			self:Say(45329)
		end
	end
	function mod:ShadowNova(args)
		self:CDBar(45329, 31)
		self:GetUnitTarget(novaTarget, 0.1, args.sourceGUID)
	end
end

do
	local function conflagTarget(self, name, guid)
		self:TargetMessage(45333, "red", name)
		self:CustomIcon(conflagMarker, name, 8)
		self:ScheduleTimer("CustomIcon", 5, conflagMarker, name)
		if self:Me(guid) then
			self:PlaySound(45333, "warning")
		end
	end
	function mod:Conflagration(args)
		self:CDBar(45333, 31)
		self:GetUnitTarget(conflagTarget, 0.1, args.sourceGUID)
	end
end
