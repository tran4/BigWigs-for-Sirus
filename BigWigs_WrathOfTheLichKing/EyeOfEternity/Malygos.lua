--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-EyeOfEternity/Malygos.lua), draft by tools/dbm2bw
-- In stage 3 the players ride drakes: the auras and the boss target are the drakes, the pet GUIDs of the group tell
-- the players (DBM). The Power Spark is seen as the boss1 cast or the DBM emote.

local mod, CL = BigWigs:NewBoss("Malygos", 616, 1617)
if not mod then return end
mod:RegisterEnableMob(28859)
mod:SetEncounterID(1094)
mod:SetEmulationWipeDelay(45) -- DBM SetWipeTime(45)

--------------------------------------------------------------------------------
-- Locals
--

local drakeOwners = {}
local surgeTargets = {}
local prevSpark = 0

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	engage_trigger = "My patience has reached its limit. I will be rid of you!",
	stage2_trigger = "I had hoped to end your lives quickly", -- DBM: the start of the yell
	breath_trigger = "You will not succeed while I draw breath!",
	stage3_trigger = "Now your benefactors make their", -- DBM: the start of the yell
	spark_trigger = "A Power Spark forms from a nearby rift!",
	surge_trigger = "%s fixes his eyes on you!", -- raw emote text
})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"stages",
		"berserk",
		56140, -- Power Spark
		56105, -- Vortex
		56505, -- Deep Breath
		{57430, "SAY"}, -- Static Field
		60936, -- Surge of Power
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "SurgeOfPower", 60936, 57407)
	self:Log("SPELL_CAST_START", "DeepBreath", 56505)
	self:Log("SPELL_CAST_START", "StaticField", 57430)
	self:Log("SPELL_CAST_SUCCESS", "Vortex", 56105)
	self:Log("SPELL_CAST_SUCCESS", "StaticField", 57430)
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
	self:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE")
	self:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", nil, "boss1")
end

function mod:OnEngage()
	self:SetStage(1)
	drakeOwners, surgeTargets = {}, {}
	prevSpark = 0
	self:Bar(56105, 40)
	self:Berserk(615)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:BuildDrakeOwners()
	drakeOwners = {}
	for unit in self:IterateGroup() do
		local pet = UnitGUID(unit .. "pet")
		if pet then drakeOwners[pet] = self:UnitName(unit) end
	end
end

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if msg:find(L.engage_trigger, nil, true) then
		if not self:IsEngaged() then self:Engage() end -- DBM StartCombat on the yell
	elseif not self:IsEngaged() then
		return
	elseif msg:sub(1, L.stage2_trigger:len()) == L.stage2_trigger then
		self:SetStage(2)
		self:StopBar(56140)
		self:StopBar(56105)
		self:CancelDelayedMessage(CL.soon:format(self:SpellName(56105)))
		self:Message("stages", "cyan", CL.stage:format(2), false)
		self:PlaySound("stages", "long")
		self:Bar("stages", 22, CL.intermission, "achievement_bg_returnxflags_def_wsg")
		self:CDBar(56505, 92)
	elseif msg:find(L.breath_trigger, nil, true) then
		self:Message(56505, "orange", CL.soon:format(self:SpellName(56505)))
	elseif msg:sub(1, L.stage3_trigger:len()) == L.stage3_trigger then
		self:SetStage(3)
		self:Message("stages", "cyan", CL.stage:format(3), false)
		self:PlaySound("stages", "long")
		self:ScheduleTimer("BuildDrakeOwners", 6)
		self:StopBar(56505)
	end
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(_, msg)
	if msg:find(L.surge_trigger, nil, true) then -- only the target sees it
		self:PersonalMessage(60936)
		self:PlaySound(60936, "warning")
	elseif msg:find(L.spark_trigger, nil, true) then
		self:Spark()
	end
end

function mod:Spark()
	if GetTime() - prevSpark > 5 then
		prevSpark = GetTime()
		self:Message(56140, "yellow")
		self:Bar(56140, 30)
	end
end

function mod:UNIT_SPELLCAST_SUCCEEDED(_, _, _, _, spellName)
	if spellName == self:SpellName(56140) then
		self:Spark()
	end
end

function mod:AnnounceSurge()
	self:TargetsMessage(60936, "red", surgeTargets, #surgeTargets)
	surgeTargets = {}
end

function mod:SurgeOfPower(args)
	local target = drakeOwners[args.destGUID]
	if not target then return end
	surgeTargets[#surgeTargets + 1] = target
	self:CancelTimer(self.surgeTimer)
	if #surgeTargets >= 3 then
		self:AnnounceSurge()
	else
		self.surgeTimer = self:ScheduleTimer("AnnounceSurge", 0.5)
	end
	if target == self:UnitName("player") then
		self:PlaySound(60936, "alarm") -- DBM: defensive
	end
end

function mod:DeepBreath(args)
	self:Message(56505, "red")
	self:PlaySound(56505, "warning")
	self:Bar(56505, 8, CL.other:format(args.spellName, CL.active))
	self:CDBar(56505, 59)
end

do
	local function fieldTarget(self, name, guid)
		local target = drakeOwners[guid] or name
		if target == self:UnitName("player") then
			self:PersonalMessage(57430)
			self:PlaySound(57430, "runaway")
			self:Say(57430)
		else
			local unit = self:UnitTokenFromGUID(guid)
			if unit and self:UnitWithinRange(unit, 13) then
				self:Message(57430, "orange", CL.near:format(self:SpellName(57430)))
				self:PlaySound(57430, "runaway")
			else
				self:TargetMessage(57430, "orange", target)
			end
		end
	end
	local prev = 0
	function mod:StaticField(args)
		if args.time - prev < 2 then return end -- DBM handles the start and the success
		prev = args.time
		self:GetUnitTarget(fieldTarget, 0.1, args.sourceGUID)
		self:CDBar(57430, 12.5)
	end
end

function mod:Vortex(args)
	self:Bar(56105, 60)
	self:DelayedMessage(56105, 54, "yellow", CL.soon:format(args.spellName))
	self:Message(56105, "orange")
	self:CastBar(56105, 11)
	local left = self:BarTimeLeft(56140)
	if left > 0 and left < 11 then
		self:Bar(56140, {18, 30})
	end
end
