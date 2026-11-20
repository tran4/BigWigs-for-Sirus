--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Icecrown/ThePlagueworks/Putricide.lua), draft by tools/dbm2bw

local mod, CL = BigWigs:NewBoss("Professor Putricide", 631, 1631)
if not mod then return end
mod:RegisterEnableMob(36678)
mod:SetEncounterID(851)

--------------------------------------------------------------------------------
-- Locals
--

local redOozeCasts = {} -- [sourceGUID] = casts
local puddleTime, gooTime, chokingTime, unboundTime = 0, 0, 0, 0
local stage2Warned, stage3Warned = false, false
local prevPuddle, prevTearGas, prevGoo = 0, 0, 0

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	-- 3.3.5: DBM Sirus has no English text for the Malleable Goo emote
	malleable_emote = "|TInterface\\Icons\\inv_misc_herb_evergreenmoss.blp:16|t %s разливает |cFF00FF00вязкую жижу!|r",
})

--------------------------------------------------------------------------------
-- Initialization
--

local greenOozeMarker = mod:AddMarkerOption(true, "player", 8, 70447, 8) -- Volatile Ooze Adhesive
local redOozeMarker = mod:AddMarkerOption(true, "player", 7, 70672, 7) -- Gaseous Bloat
local unboundPlagueMarker = mod:AddMarkerOption(true, "player", 5, 70911, 5)
function mod:GetOptions()
	return {
		"stages",
		"berserk",
		-- Stage One
		70341, -- Slime Puddle
		70351, -- Unstable Experiment
		70447, -- Volatile Ooze Adhesive
		greenOozeMarker,
		70672, -- Gaseous Bloat
		redOozeMarker,
		{70911, "SAY", "OFF"}, -- Unbound Plague
		unboundPlagueMarker,
		-- Stage Two
		71255, -- Choking Gas Bomb
		72295, -- Malleable Goo
		-- Stage Three
		{72451, "TANK_HEALER"}, -- Mutated Plague
		-- Intermission
		71617, -- Tear Gas
		72843, -- Volatile Experiment
		70352, -- Ooze Variable
		70353, -- Gas Variable
		-- Drink Me
		{70542, "OFF"}, -- Mutated Slash
		70539, -- Regurgitated Ooze
	}, {
		[70341] = CL.stage:format(1),
		[71255] = CL.stage:format(2),
		[72451] = CL.stage:format(3),
		[71617] = CL.intermission,
		[70542] = "general",
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "UnstableExperiment", 70351, 71966, 71967, 71968)
	self:Log("SPELL_CAST_START", "TearGas", 71617)
	self:Log("SPELL_CAST_START", "VolatileExperiment", 72842, 72843)
	self:Log("SPELL_CAST_START", "CreateConcoction", 72851, 72852, 71621, 72850)
	self:Log("SPELL_CAST_START", "GuzzlePotions", 73121, 73122, 73120, 71893)
	self:Log("SPELL_CAST_START", "GaseousBloatCast", 70672, 72455, 72832, 72833)
	self:Log("SPELL_CAST_SUCCESS", "SlimePuddle", 70341)
	self:Log("SPELL_CAST_SUCCESS", "ChokingGasBomb", 71255)
	self:Log("SPELL_CAST_SUCCESS", "UnboundPlagueCast", 72855, 72856, 70911)
	self:Log("SPELL_CAST_SUCCESS", "MalleableGoo", 72615, 72295, 74280, 74281)
	self:Log("SPELL_AURA_APPLIED", "VolatileOozeAdhesive", 70447, 72836, 72837, 72838)
	self:Log("SPELL_AURA_REMOVED", "VolatileOozeAdhesiveRemoved", 70447, 72836, 72837, 72838)
	self:Log("SPELL_AURA_APPLIED", "GaseousBloat", 70672, 72455, 72832, 72833)
	self:Log("SPELL_AURA_REMOVED", "GaseousBloatRemoved", 70672, 72455, 72832, 72833)
	self:Log("SPELL_AURA_APPLIED", "UnboundPlague", 72855, 72856, 70911)
	self:Log("SPELL_AURA_REMOVED", "UnboundPlagueRemoved", 72855, 72856, 70911)
	self:Log("SPELL_AURA_APPLIED", "MutatedPlague", 72451, 72463, 72671, 72672)
	self:Log("SPELL_AURA_APPLIED_DOSE", "MutatedPlague", 72451, 72463, 72671, 72672)
	self:Log("SPELL_AURA_APPLIED", "OozeVariable", 70352, 74118)
	self:Log("SPELL_AURA_APPLIED", "GasVariable", 70353, 74119)
	self:Log("SPELL_AURA_REMOVED", "TearGasRemoved", 71615)
	self:Log("SPELL_AURA_APPLIED", "MutatedSlash", 70542)
	self:Log("SPELL_AURA_APPLIED_DOSE", "MutatedSlash", 70542)
	self:Log("SPELL_AURA_REFRESH", "MutatedSlash", 70542)
	self:Log("SPELL_AURA_REMOVED", "MutatedSlashRemoved", 70542)
	self:Log("SPELL_AURA_APPLIED", "RegurgitatedOoze", 70539, 72457, 72875, 72876)
	self:Log("SPELL_AURA_REFRESH", "RegurgitatedOoze", 70539, 72457, 72875, 72876)
	self:Log("SPELL_AURA_REMOVED", "RegurgitatedOozeRemoved", 70539, 72457, 72875, 72876)
	self:RegisterUnitEvent("UNIT_HEALTH", nil, "boss1")
	self:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE")
end

function mod:OnEngage()
	local t = GetTime()
	puddleTime, gooTime, chokingTime, unboundTime = t, t, t, t
	redOozeCasts = {}
	stage2Warned, stage3Warned = false, false
	self:SetStage(1)
	self:Berserk(600)
	self:CDBar(70341, 10)
	self:Bar(70351, 30)
	self:DelayedMessage(70351, 25, "orange", CL.soon:format(self:SpellName(70351)))
	if self:Heroic() then
		self:Bar(70911, 20)
	end
end

--------------------------------------------------------------------------------
-- Event Handlers
--

local function since(t) return GetTime() - t end

function mod:SafeBar(method, key, t) -- the DBM formulas can go negative after long stages
	if t > 1 then
		self[method](self, key, t)
	end
end

function mod:StageChange()
	local stage = self:GetStage() + 1
	self:SetStage(stage)
	self:Message("stages", "cyan", CL.stage:format(stage), false)
	self:PlaySound("stages", "long")
end

function mod:StopStageBars()
	self:CancelDelayedMessage(CL.soon:format(self:SpellName(70351)))
	self:CancelDelayedMessage(CL.soon:format(self:SpellName(71255)))
	self:StopBar(70351)
	self:StopBar(72295)
	self:StopBar(70341)
	self:StopBar(71255)
	self:StopBar(70911)
end

function mod:UnstableExperiment(args)
	self:Message(70351, "orange")
	self:Bar(70351, 38) -- every 38 seconds, except after stage changes
	self:DelayedMessage(70351, 33, "orange", CL.soon:format(args.spellName))
end

function mod:TearGas(args) -- stage change on normal
	self:Message(71617, "yellow")
end

function mod:VolatileExperiment(args) -- stage change on heroic
	self:Message(72843, "red")
	self:PlaySound(72843, "long")
	self:StopStageBars()
end

function mod:CreateConcoction() -- change to stage 2
	self:StopStageBars()
	self:SafeBar("CDBar", 70341, 65 - since(puddleTime))
	self:SafeBar("Bar", 70351, (since(puddleTime) > 35 and 90 or 55) - since(puddleTime))
	if self:Heroic() then
		self:ScheduleTimer("StageChange", 35) -- the target is set 5 seconds after
		self:Bar("stages", 35, CL.stage:format(2), "achievement_bg_returnxflags_def_wsg")
		self:CDBar(72295, 45.5)
		self:Bar(71255, 57)
		self:DelayedMessage(71255, 52, "orange", CL.soon:format(self:SpellName(71255)))
		self:SafeBar("Bar", 70911, 120 - since(unboundTime))
	else
		self:Bar("stages", 9.5, CL.stage:format(2), "achievement_bg_returnxflags_def_wsg")
		self:CDBar(72295, 19)
		self:Bar(71255, 30.5)
		self:DelayedMessage(71255, 25.5, "orange", CL.soon:format(self:SpellName(71255)))
	end
end

function mod:GuzzlePotions() -- change to stage 3
	self:StopStageBars()
	self:SafeBar("CDBar", 70341, 65 - since(puddleTime))
	self:SafeBar("CDBar", 72295, 50 - since(gooTime))
	self:SafeBar("Bar", 71255, 66 - since(chokingTime))
	if 61 - since(chokingTime) > 0 then
		self:DelayedMessage(71255, 61 - since(chokingTime), "orange", CL.soon:format(self:SpellName(71255)))
	end
	local diff = self:Difficulty()
	if diff == 5 or diff == 6 then
		local t = diff == 5 and 38 or 28 -- the target is set 8 seconds after on 10 heroic
		self:ScheduleTimer("StageChange", t)
		self:Bar("stages", t, CL.stage:format(3), "achievement_bg_returnxflags_def_wsg")
		self:SafeBar("Bar", 70911, 120 - since(unboundTime))
	else
		self:Bar("stages", 12.5, CL.stage:format(3), "achievement_bg_returnxflags_def_wsg")
	end
end

function mod:TearGasRemoved(args)
	if args.time - prevTearGas > 5 then
		prevTearGas = args.time
		self:StageChange()
	end
end

function mod:GaseousBloatCast(args)
	self:CastBar(70672, 3)
	redOozeCasts[args.sourceGUID] = (redOozeCasts[args.sourceGUID] or 0) + 1
	if redOozeCasts[args.sourceGUID] > 1 then -- the red ooze changes its target
		self:Message(70672, "orange", CL.casting:format(args.spellName))
		self:PlaySound(70672, "alert")
	end
end

function mod:SlimePuddle(args)
	if args.time - prevPuddle > 5 then
		prevPuddle = args.time
		self:Message(70341, "yellow")
		self:CDBar(70341, 35)
		puddleTime = GetTime()
	end
end

function mod:ChokingGasBomb(args)
	self:Message(71255, "orange")
	if self:Melee() then
		self:PlaySound(71255, "alarm")
	end
	self:Bar(71255, 35.5)
	self:DelayedMessage(71255, 30.5, "orange", CL.soon:format(args.spellName))
	chokingTime = GetTime()
end

function mod:UnboundPlagueCast()
	self:Bar(70911, 90)
	unboundTime = GetTime()
end

function mod:MalleableGoo()
	local t = GetTime()
	if t - prevGoo > 3 then
		prevGoo = t
		self:Message(72295, "orange")
		if self:Ranged() then
			self:PlaySound(72295, "alarm")
		end
		self:CDBar(72295, 20)
		gooTime = t
	end
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(_, msg)
	if msg == L.malleable_emote then
		self:MalleableGoo()
	end
end

function mod:VolatileOozeAdhesive(args) -- Green Ooze
	if self:Me(args.destGUID) then -- still knocks back at full absorb
		self:PersonalMessage(70447)
		self:PlaySound(70447, "warning")
	else
		self:TargetMessage(70447, "green", args.destName)
		if not self:Tank() then
			self:PlaySound(70447, "info", nil, args.destName) -- help soaking
		end
	end
	self:CustomIcon(greenOozeMarker, args.destName, 8)
end

function mod:VolatileOozeAdhesiveRemoved(args)
	self:CustomIcon(greenOozeMarker, args.destName)
end

function mod:GaseousBloat(args) -- Red Ooze
	self:TargetBar(70672, 20, args.destName)
	if self:Me(args.destGUID) then
		self:PersonalMessage(70672)
		self:PlaySound(70672, "alarm") -- run
	else
		self:TargetMessage(70672, "orange", args.destName)
	end
	self:CustomIcon(redOozeMarker, args.destName, 7)
end

function mod:GaseousBloatRemoved(args)
	self:StopBar(70672, args.destName)
	self:CustomIcon(redOozeMarker, args.destName)
end

function mod:UnboundPlague(args)
	self:CustomIcon(unboundPlagueMarker, args.destName, 5)
	if self:Me(args.destGUID) then
		self:PersonalMessage(70911)
		self:PlaySound(70911, "warning")
		self:Say(70911)
		self:TargetBar(70911, 12, args.destName) -- pass it on after 12-15 seconds
	else
		self:TargetMessage(70911, "yellow", args.destName)
	end
end

function mod:UnboundPlagueRemoved(args)
	self:StopBar(70911, args.destName)
	self:CustomIcon(unboundPlagueMarker, args.destName)
end

function mod:MutatedPlague(args)
	self:StackMessage(72451, "purple", args.destName, args.amount or 1, 99)
	self:CDBar(72451, 10)
end

function mod:OozeVariable(args)
	if self:Me(args.destGUID) then
		self:PersonalMessage(70352)
		self:PlaySound(70352, "info")
	end
end

function mod:GasVariable(args)
	if self:Me(args.destGUID) then
		self:PersonalMessage(70353)
		self:PlaySound(70353, "info")
	end
end

function mod:MutatedSlash(args)
	self:TargetBar(70542, 20, args.destName)
end

function mod:MutatedSlashRemoved(args)
	self:StopBar(70542, args.destName)
end

function mod:RegurgitatedOoze(args)
	self:TargetBar(70539, 20, args.destName)
end

function mod:RegurgitatedOozeRemoved(args)
	self:StopBar(70539, args.destName)
end

function mod:UNIT_HEALTH(event, unit)
	if self:MobId(self:UnitGUID(unit)) ~= 36678 then return end
	local hp = self:GetHealth(unit)
	local stage = self:GetStage()
	if stage == 1 and not stage2Warned and hp <= 83 then
		stage2Warned = true
		self:Message("stages", "cyan", CL.soon:format(CL.stage:format(2)), false)
	elseif stage == 2 and not stage3Warned and hp <= 38 then
		stage3Warned = true
		self:Message("stages", "cyan", CL.soon:format(CL.stage:format(3)), false)
	end
end
