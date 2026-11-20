--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-ChamberOfAspects/Bronze/Imporus.lua), a custom Sirus raid, no journal id.
-- DBM has only Russian texts: the English defaults are the Russian texts. Not ported: the health frame.

local mod, CL = BigWigs:NewBoss("Imporus", 10925)
if not mod then return end
mod:RegisterEnableMob(50608)
mod:SetEncounterID(50608) -- DBM Sirus custom encounter id

--------------------------------------------------------------------------------
-- Locals
--

local prevPoison = 0

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	-- DBM: no English texts
	bossName = "Импорус",
	arrow_say = "Темпоральная стрела летит в меня!",
})
mod.displayName = L.bossName

--------------------------------------------------------------------------------
-- Initialization
--

local arrowMarker = mod:AddMarkerOption(false, "player", 8, 316519, 8)
function mod:GetOptions()
	return {
		"berserk",
		312199, -- poison
		316523, -- Resonance (heroic)
		316526, -- Burning Time (heroic)
		312194, -- Resonance
		312197, -- Burning Time
		{316508, "TANK"}, -- Temporal Beat
		{316519, "SAY"}, -- Temporal Arrow
		arrowMarker,
		"proximity",
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "HeroicResonance", 316523)
	self:Log("SPELL_CAST_START", "HeroicBurningTime", 316526)
	self:Log("SPELL_CAST_START", "BurningTime", 312197)
	self:Log("SPELL_CAST_START", "Resonance", 312194)
	self:Log("SPELL_AURA_APPLIED", "Poison", 312199)
	self:Log("SPELL_CAST_SUCCESS", "PoisonSuccess", 312199)
	self:Log("SPELL_AURA_APPLIED", "TemporalBeat", 316508)
	self:Log("SPELL_AURA_APPLIED_DOSE", "TemporalBeat", 316508)
	self:Log("SPELL_CAST_SUCCESS", "TemporalArrow", 316519, 316520)
end

function mod:OnEngage()
	prevPoison = 0
	self:CDBar(312199, 10)
	if self:Difficulty() == 6 then -- 25 heroic
		self:Berserk(600)
		self:CDBar(316519, 20)
		self:CDBar(316523, 50)
		self:DelayedMessage(316523, 41, "red", CL.soon:format(self:SpellName(316523)), nil, "alarm")
	else
		self:CDBar(312194, 30) -- DBM: the heroic timer object started with 30
		self:DelayedMessage(312194, 22, "red", CL.soon:format(self:SpellName(312194)), nil, "alarm")
	end
	self:OpenProximity("proximity", 8)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

local function tauntCheck(self, spellId)
	if self:Tank() and not self:UnitDebuff("player", 316508) then
		self:Message(316508, "purple", CL.casting:format(self:SpellName(spellId)))
		self:PlaySound(316508, "warning") -- DBM: taunt
	end
end

function mod:HeroicResonance(args)
	self:Message(316523, "orange")
	self:CastBar(316523, 3)
	self:CDBar(316526, 53)
	self:DelayedMessage(316526, 48, "yellow", CL.soon:format(self:SpellName(316526)), nil, "info")
end

function mod:HeroicBurningTime(args)
	self:Message(316526, "orange")
	self:CastBar(316526, 3)
	self:CDBar(316523, 53)
	self:DelayedMessage(316523, 43, "red", CL.soon:format(self:SpellName(316523)), nil, "alarm")
end

function mod:BurningTime(args)
	tauntCheck(self, 312197)
	self:Message(312197, "orange")
	self:CastBar(312197, 3)
	self:CDBar(312194, 33)
	self:DelayedMessage(312194, 25, "red", CL.soon:format(self:SpellName(312194)), nil, "alarm")
end

function mod:Resonance(args)
	tauntCheck(self, 312194)
	self:Message(312194, "orange")
	self:CastBar(312194, 3)
	self:CDBar(312197, 33)
	self:DelayedMessage(312197, 25, "yellow", CL.soon:format(self:SpellName(312197)), nil, "info")
end

function mod:Poison(args)
	if args.time - prevPoison > 3 then
		prevPoison = args.time
		self:CDBar(312199, 58)
	end
end

function mod:PoisonSuccess()
	self:CDBar(312199, 58)
end

function mod:TemporalBeat(args)
	local amount = args.amount or 1
	if amount >= 8 then
		if self:Me(args.destGUID) then
			self:StackMessage(316508, "blue", args.destName, amount, 8)
			self:PlaySound(316508, "alarm")
		elseif self:Tank() and not self:UnitDebuff("player", 316508) and not UnitIsDeadOrGhost("player") then
			self:StackMessage(316508, "purple", args.destName, amount, 8)
			self:PlaySound(316508, "warning") -- DBM: taunt
		else
			self:StackMessage(316508, "purple", args.destName, amount, 8)
		end
	end
	self:Bar(316508, 30, CL.other:format(args.spellName, CL.active))
end

do
	local function arrowTarget(self, name, guid)
		self:TargetMessage(316519, "red", name)
		self:CustomIcon(arrowMarker, name, 8)
		self:ScheduleTimer("CustomIcon", 5, arrowMarker, name)
		if self:Me(guid) then
			self:PlaySound(316519, "warning")
			self:Say(316519, L.arrow_say, true)
		end
	end
	function mod:TemporalArrow(args)
		self:CDBar(316519, 20)
		self:GetUnitTarget(arrowTarget, 0.1, args.sourceGUID)
	end
end
