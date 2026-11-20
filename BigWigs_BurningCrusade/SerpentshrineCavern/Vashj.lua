--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Serpentshrine/Vashj.lua, heroic mode with custom spells), draft by tools/dbm2bw
-- Not ported: marking the Tainted Elemental, the arrow to it, nameplate icons, announcing to the raid chat.

local mod, CL = BigWigs:NewBoss("Lady Vashj", 548, 1572)
if not mod then return end
mod:RegisterEnableMob(21212)
mod:SetEncounterID(628)

--------------------------------------------------------------------------------
-- Locals
--

local staticTargets = {}
local elementalWarned = false
local warned = {}

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	stage2_trigger = "The time is now! Leave none standing!",
	stage3_trigger = "You may want to take cover.",

	strider = "Strider",
	elemental = "Tainted Elemental",
	naga = "Naga",
	elemental_soon = "Tainted Elemental Soon",
})

--------------------------------------------------------------------------------
-- Initialization
--

local staticMarker = mod:AddMarkerOption(true, "player", 8, 310636, 8, 7)
function mod:GetOptions()
	return {
		"stages",
		"berserk",
		"adds",
		38132, -- Tainted Core
		38280, -- Static Charge
		38509, -- Shock Blast
		38316, -- Entangle
		-- heroic
		{310636, "SAY"}, -- Static Charge
		staticMarker,
		{310659, "SAY"}, -- Static Charge (stage 2)
		310635, -- Summon Elementals
		310657, -- Summon Rays
		"proximity",
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "TaintedCore", 38132)
	self:Log("SPELL_CAST_SUCCESS", "StaticChargeNormal", 38280)
	self:Log("SPELL_CAST_SUCCESS", "ShockBlast", 38509)
	self:Log("SPELL_CAST_SUCCESS", "Entangle", 38316)
	self:Log("SPELL_AURA_APPLIED", "StaticCharge", 310636, 310659)
	self:Log("SPELL_AURA_REMOVED", "StaticChargeRemoved", 310636, 310659)
	self:Log("SPELL_SUMMON", "SummonElementals", 310635)
	self:Log("SPELL_SUMMON", "SummonRays", 310657)
	self:Death("TaintedElementalDeath", 36899) -- DBM: the Tainted Elemental id from its SWING_DAMAGE check
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
	self:RegisterEvent("UNIT_HEALTH")
end

function mod:OnEngage()
	self:SetStage(1)
	staticTargets = {}
	elementalWarned = false
	warned = {}
	if self:Difficulty() == 6 then -- 25 heroic
		self:OpenProximity("proximity", 20)
		self:CDBar(310635, 10)
		self:CDBar(310636, 15)
	else
		self:Berserk(600)
	end
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if not self:IsEngaged() then return end
	if msg == L.stage2_trigger then
		self:Message("stages", "cyan", CL.stage:format(2), false)
		self:Bar("adds", 45, L.strider, "inv_misc_fish_13")
		self:Bar("adds", 45, L.elemental, "spell_nature_elementalshields")
		self:Bar("adds", 30, L.naga, "inv_misc_monsterhead_02")
		self.striderTimer = self:ScheduleTimer("NextStrider", 45)
		self.elementalTimer = self:ScheduleTimer("NextElemental", 45)
		self.nagaTimer = self:ScheduleTimer("NextNaga", 30)
		self:DelayedMessage("adds", 42, "orange", L.elemental_soon, "spell_nature_elementalshields")
	elseif msg == L.stage3_trigger then
		self:Message("stages", "cyan", CL.stage:format(3), false)
		self:StopBar(L.strider)
		self:StopBar(L.elemental)
		self:StopBar(L.naga)
		self:CancelTimer(self.striderTimer)
		self:CancelTimer(self.elementalTimer)
		self:CancelTimer(self.nagaTimer)
		self:CancelDelayedMessage(L.elemental_soon)
	end
end

function mod:NextStrider()
	self:Bar("adds", 45, L.strider, "inv_misc_fish_13")
	self.striderTimer = self:ScheduleTimer("NextStrider", 45)
end

function mod:NextNaga()
	self:Bar("adds", 30, L.naga, "inv_misc_monsterhead_02")
	self.nagaTimer = self:ScheduleTimer("NextNaga", 30)
end

function mod:NextElemental()
	self:Bar("adds", 45, L.elemental, "spell_nature_elementalshields")
	self:Bar("adds", 15, CL.other:format(L.elemental, CL.active), "spell_nature_elementalshields") -- DBM: fades timer (24991)
	self.elementalTimer = self:ScheduleTimer("NextElemental", 45)
end

function mod:TaintedElementalDeath()
	self:StopBar(CL.other:format(L.elemental, CL.active))
end

function mod:UNIT_HEALTH(_, unit)
	if not self:IsEngaged() or self:MobId(self:UnitGUID(unit)) ~= 21212 then return end
	local hp, stage = self:GetHealth(unit), self:GetStage()
	local heroic = self:Difficulty() == 6
	if stage == 1 then
		if not warned.soon2 and hp <= 72 then
			warned.soon2 = true
			self:Message("stages", "cyan", CL.soon:format(CL.stage:format(2)), false)
		end
		if not warned.stage2 and hp <= 70 then
			warned.stage2 = true
			self:SetStage(2)
			self:Message("stages", "cyan", CL.stage:format(2), false)
		end
	elseif stage == 2 then
		if heroic then
			if not warned.soon3 and hp <= 42 then
				warned.soon3 = true
				self:Message("stages", "cyan", CL.soon:format(CL.stage:format(3)), false)
			end
			if not warned.stage3 and hp <= 40 then
				warned.stage3 = true
				self:SetStage(3)
				self:Message("stages", "cyan", CL.stage:format(3), false)
				self:StopBar(310635)
			end
		elseif not warned.stage3 and hp <= 50 then
			warned.stage3 = true
			self:SetStage(3)
			self:Message("stages", "cyan", CL.stage:format(3), false)
		end
	end
end

function mod:TaintedCore(args)
	self:TargetMessage(38132, "green", args.destName)
	if self:Me(args.destGUID) then
		self:PlaySound(38132, "info")
	end
end

function mod:StaticChargeNormal(args)
	self:TargetMessage(38280, "red", args.destName)
	self:TargetBar(38280, 20, args.destName)
	if self:Me(args.destGUID) then
		self:PlaySound(38280, "runaway")
	end
end

function mod:ShockBlast(args)
	self:TargetMessage(38509, "orange", args.destName)
	self:Bar(38509, 10)
end

function mod:Entangle()
	self:Bar(38316, 32)
end

function mod:AnnounceStatic()
	self:TargetsMessage(310636, "red", staticTargets, #staticTargets)
	for i = 1, #staticTargets do
		self:CustomIcon(staticMarker, staticTargets[i], 9 - i) -- 8, 7
	end
	self:CDBar(310636, self:GetStage() == 3 and 30 or 15)
	staticTargets = {}
end

function mod:StaticCharge(args)
	if self:Me(args.destGUID) then
		self:PersonalMessage(args.spellId)
		self:PlaySound(args.spellId, "runaway")
		self:Say(args.spellId)
	elseif self:GetStage() == 1 then
		local unit = self:UnitTokenFromGUID(args.destGUID)
		if unit and CheckInteractDistance(unit, 3) then -- DBM: duel distance
			self:Message(args.spellId, "orange", CL.near:format(args.spellName))
			self:PlaySound(args.spellId, "alarm")
		end
	end
	self:TargetBar(args.spellId, 8, args.destName)
	if args.spellId == 310636 then
		staticTargets[#staticTargets + 1] = args.destName
		self:CancelTimer(self.staticTimer)
		self.staticTimer = self:ScheduleTimer("AnnounceStatic", 0.1)
	end
end

function mod:StaticChargeRemoved(args)
	self:CustomIcon(staticMarker, args.destName)
end

function mod:SummonElementals()
	if not elementalWarned then
		elementalWarned = true
		self:Message(310635, "cyan")
		self:CDBar(310635, 60)
		self:ScheduleTimer("ElementalsSoon", 45)
	end
end

function mod:ElementalsSoon()
	self:Message(310635, "yellow", CL.soon:format(self:SpellName(310635)))
	elementalWarned = false
end

function mod:SummonRays()
	self:Message(310657, "cyan")
end
