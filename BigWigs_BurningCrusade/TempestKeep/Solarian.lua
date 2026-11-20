--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-TheEye/Solarian.lua, heroic mode with custom spells), draft by tools/dbm2bw
-- Not ported: marking the priests, the arrow, nameplate icons.

local mod, CL = BigWigs:NewBoss("High Astromancer Solarian", 550, 1575)
if not mod then return end
mod:RegisterEnableMob(18805)
mod:SetEncounterID(732)

--------------------------------------------------------------------------------
-- Locals
--

local ringTargets = {}

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	engage_trigger = "Тал ану-мен но син-дорай!", -- DBM: no English text
	adds_trigger = "You are hopelessly outmatched!",
	priests_trigger = "I will crush your delusions of grandeur!",

	agents = "Agents incoming",
	priests = "Priests & Solarian incoming",
})

--------------------------------------------------------------------------------
-- Initialization
--

local wrathMarker = mod:AddMarkerOption(true, "player", 8, 42783, 8)
local wrathHeroicMarker = mod:AddMarkerOption(true, "player", 8, 308548, 8)
function mod:GetOptions()
	return {
		"stages",
		"adds",
		{42783, "SAY"}, -- Wrath of the Astromancer
		wrathMarker,
		-- heroic
		{308548, "SAY"}, -- Wrath
		wrathHeroicMarker,
		308562, -- Blinding Ring
		308563, -- Blinding
		308558, -- Novices
		308544, -- beam stacks
		308585, -- Flash of the Void
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "BlindingRing", 308562)
	self:Log("SPELL_CAST_START", "Novices", 308558)
	self:Log("SPELL_CAST_START", "FlashOfTheVoid", 308585)
	self:Log("SPELL_CAST_START", "HeroicStage2", 308576)
	self:Log("SPELL_AURA_APPLIED", "WrathHeroic", 308548)
	self:Log("SPELL_AURA_APPLIED", "BeamStacks", 308544)
	self:Log("SPELL_AURA_APPLIED_DOSE", "BeamStacks", 308544)
	self:Log("SPELL_AURA_APPLIED", "Blinding", 308563)
	self:Log("SPELL_AURA_APPLIED", "Wrath", 42783)
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
	self:RegisterEvent("UNIT_HEALTH")
end

function mod:OnEngage()
	self:SetStage(1)
	ringTargets = {}
	if self:Difficulty() == 6 then -- 25 heroic
		self:CDBar(308558, 38)
		self:CDBar(308548, 43)
	else
		self:Bar("adds", 60, L.agents, 55342)
		self:DelayedMessage("adds", 52, "yellow", CL.incoming:format(CL.adds), 55342)
	end
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if msg:find(L.engage_trigger, nil, true) then
		if not self:IsEngaged() then self:Engage() end -- DBM RegisterCombat("yell")
	elseif not self:IsEngaged() then
		return
	elseif msg == L.adds_trigger then
		if self:Difficulty() == 4 then -- 25 normal
			self:Bar("adds", 15, L.priests, 47788)
			self:CDBar(42783, 21)
		end
	elseif msg == L.priests_trigger then
		self:Bar("adds", 60, L.agents, 55342)
		self:DelayedMessage("adds", 52, "yellow", CL.incoming:format(CL.adds), 55342)
	end
end

function mod:UNIT_HEALTH(_, unit)
	if not self:IsEngaged() or self:GetStage() ~= 1 or self:MobId(self:UnitGUID(unit)) ~= 18805 then return end
	local hp = self:GetHealth(unit)
	local heroic = self:Difficulty() == 6
	if (heroic and hp < 40) or (not heroic and hp < 20) then
		self:SetStage(2)
		self:StopBar(L.agents)
		self:CancelDelayedMessage(CL.incoming:format(CL.adds))
	end
end

function mod:BlindingRing(args)
	self:Message(308562, "yellow", CL.soon:format(args.spellName))
	self:CDBar(308562, 17)
end

function mod:Novices(args)
	self:Message(308558, "cyan", CL.incoming:format(CL.adds))
	self:PlaySound(308558, "info")
	self:CDBar(308558, 80)
end

function mod:FlashOfTheVoid(args)
	self:Message(308585, "red")
	self:PlaySound(308585, "warning") -- DBM: look away
	self:ScheduleTimer("CDBar", 5, 308585, 75)
end

function mod:HeroicStage2(args)
	self:SetStage(2)
	self:StopBar(308558)
	self:Message("stages", "cyan", CL.stage:format(2), false)
	self:PlaySound("stages", "long")
	self:DelayedMessage(308585, 70, "yellow", CL.soon:format(self:SpellName(308585)))
	self:CDBar(308585, 75)
end

function mod:WrathHeroic(args)
	self:CDBar(308548, 43)
	self:TargetBar(308548, 6, args.destName)
	self:CustomIcon(wrathHeroicMarker, args.destName, 8)
	self:ScheduleTimer("CustomIcon", 6, wrathHeroicMarker, args.destName)
	if self:Me(args.destGUID) then
		self:Say(308548)
	end
end

function mod:BeamStacks(args)
	if self:GetStage() == 1 and self:Me(args.destGUID) then
		self:PersonalMessage(308544)
		self:PlaySound(308544, "runaway")
	end
end

function mod:AnnounceBlinding()
	self:TargetsMessage(308563, "orange", ringTargets, #ringTargets)
	ringTargets = {}
end

function mod:Blinding(args)
	ringTargets[#ringTargets + 1] = args.destName
	self:CancelTimer(self.ringTimer)
	self.ringTimer = self:ScheduleTimer("AnnounceBlinding", 0.1)
end

function mod:Wrath(args)
	self:CDBar(42783, 21)
	self:TargetMessage(42783, "red", args.destName)
	self:TargetBar(42783, 6, args.destName)
	self:CustomIcon(wrathMarker, args.destName, 8)
	self:ScheduleTimer("CustomIcon", 6, wrathMarker, args.destName)
	if self:Me(args.destGUID) then
		self:PlaySound(42783, "runaway")
		self:Say(42783)
	end
end
