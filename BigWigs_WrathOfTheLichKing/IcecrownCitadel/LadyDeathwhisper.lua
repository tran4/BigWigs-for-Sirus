--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Icecrown/TheLowerSpire/Deathwhisper.lua), draft by tools/dbm2bw
-- Not ported (DBM automation): weapon unequipping on Dominate Mind, removing druid buffs, shield health frame.

local mod, CL = BigWigs:NewBoss("Lady Deathwhisper", 631, 1625)
if not mod then return end
mod:RegisterEnableMob(36855)
mod:SetEncounterID(846)

--------------------------------------------------------------------------------
-- Locals
--

local dominateMindList = {}
local dominateMindIcon = 6
local prevDominateMind = 0
local prevDeathAndDecay = 0
local prevShade = 0
local prevShadeSwing = 0
local mobsToMark = {} -- [guid] = icon

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	-- 3.3.5: DBM Sirus has no English text for the engage yell
	engage_trigger = "Как вы смеете ступать в эти священные покои? Это место станет вашей могилой!",
	reanimated_trigger = "Arise, and exult in your pure form!",

	adds = "New Adds",
	adds_desc = "Show timer for new adds",
	adds_icon = 61131,
	adds_soon = "New adds soon",

	reanimating = "Add reviving",
	reanimating_desc = "Show warning when an add is being revived",

	shade_attack = "Vengeful Shade attacking you - Run Away",
})

--------------------------------------------------------------------------------
-- Initialization
--

local fanaticMarker = mod:AddMarkerOption(true, "npc", 8, 70900, 8) -- Deformed Fanatic
local adherentMarker = mod:AddMarkerOption(true, "npc", 7, 70901, 7) -- Empowered Adherent
local dominateMindMarker = mod:AddMarkerOption(true, "player", 6, 71289, 6, 5, 4)
function mod:GetOptions()
	return {
		"stages",
		"berserk",
		-- Adds
		"adds",
		"reanimating",
		70900, -- Dark Transformation
		fanaticMarker,
		70901, -- Dark Empowerment
		adherentMarker,
		{70674, "DISPEL"}, -- Vampiric Might
		71236, -- Dark Martyrdom
		-- Stage One
		71289, -- Dominate Mind
		dominateMindMarker,
		71001, -- Death and Decay
		-- Stage Two
		71426, -- Summon Spirit
		71237, -- Curse of Torpor
		{71204, "TANK_HEALER"}, -- Touch of Insignificance
		72007, -- Frostbolt
		72906, -- Frostbolt Volley
	}, {
		["adds"] = CL.adds,
		[71289] = CL.stage:format(1),
		[71426] = CL.stage:format(2),
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "DarkTransformation", 70900)
	self:Log("SPELL_CAST_START", "DarkEmpowerment", 70901)
	self:Log("SPELL_AURA_APPLIED", "VampiricMight", 70674)
	self:Log("SPELL_CAST_START", "DarkMartyrdom", 72499, 72500, 72497, 72496)
	self:Log("SPELL_CAST_SUCCESS", "DominateMind", 71289)
	self:Log("SPELL_AURA_APPLIED", "DeathAndDecay", 71001, 72108, 72109, 72110)
	self:Log("SPELL_AURA_REMOVED", "ManaBarrierRemoved", 70842)
	self:Log("SPELL_SUMMON", "SummonSpirit", 71426)
	self:Log("SWING_DAMAGE", "ShadeSwing", "*")
	self:Log("SPELL_AURA_APPLIED", "CurseOfTorpor", 71237)
	self:Log("SPELL_AURA_APPLIED", "TouchOfInsignificance", 71204)
	self:Log("SPELL_AURA_APPLIED_DOSE", "TouchOfInsignificance", 71204)
	self:Log("SPELL_CAST_START", "Frostbolt", 71420, 72007, 72501, 72502)
	self:Log("SPELL_INTERRUPT", "FrostboltInterrupted", 71420, 72007, 72501, 72502)
	self:Log("SPELL_AURA_APPLIED", "FrostboltVolley", 72906, 72908, 72905, 72907)
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
end

function mod:OnEngage()
	self:SetStage(1)
	dominateMindList = {}
	dominateMindIcon = 6
	mobsToMark = {}
	self:Berserk(600)
	self:Bar("adds", 5.5, L.adds, L.adds_icon)
	self:DelayedMessage("adds", 2.5, "yellow", L.adds_soon, L.adds_icon)
	self.addsTimer = self:ScheduleTimer("AddsWave", 5.5)
	if self:Difficulty() ~= 3 then -- not on 10 normal
		self:CDBar(71289, 27.5)
	end
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:AddsWave()
	-- adds every 60 seconds (45 on heroic), DBM schedules the next wave itself
	local t = self:Heroic() and 45 or 60
	self:Bar("adds", t, L.adds, L.adds_icon)
	self:DelayedMessage("adds", t - 5, "yellow", L.adds_soon, L.adds_icon)
	self.addsTimer = self:ScheduleTimer("AddsWave", t)
end

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if msg:find(L.engage_trigger, nil, true) then
		self:Engage() -- DBM RegisterCombat("yell")
	elseif msg:find(L.reanimated_trigger, nil, true) then
		self:Message("reanimating", "orange", L.reanimating, false)
	end
end

-- Adds

function mod:MarkMobs(_, unit, guid)
	local icon = mobsToMark[guid]
	if icon then
		mobsToMark[guid] = nil
		self:CustomIcon(icon == 8 and fanaticMarker or adherentMarker, unit, icon)
		if not next(mobsToMark) then
			self:UnregisterTargetEvents()
		end
	end
end

function mod:DarkTransformation(args)
	self:Message(70900, "red")
	if self:GetOption(fanaticMarker) then
		mobsToMark[args.sourceGUID] = 8
		self:RegisterTargetEvents("MarkMobs")
	end
end

function mod:DarkEmpowerment(args)
	self:Message(70901, "red")
	if self:GetOption(adherentMarker) then
		mobsToMark[args.sourceGUID] = 7
		self:RegisterTargetEvents("MarkMobs")
	end
end

function mod:VampiricMight(args)
	if not self:Player(args.destFlags) and self:Dispeller("magic", true, 70674) then
		self:TargetMessage(70674, "yellow", args.destName)
		self:PlaySound(70674, "info")
	end
end

function mod:DarkMartyrdom()
	self:Message(71236, "red")
	if self:Melee() then
		self:PlaySound(71236, "alarm")
	end
end

-- Stage One

function mod:DominateMind(args)
	if args.time - prevDominateMind > 3 then
		dominateMindList = {}
		dominateMindIcon = 6
		self:CDBar(71289, 40)
		self:Bar(71289, 12, CL.mind_control)
	end
	prevDominateMind = args.time
	dominateMindList[#dominateMindList + 1] = args.destName
	self:TargetsMessage(71289, "red", dominateMindList, self:Difficulty() == 6 and 3 or 1, nil, nil, 0.9)
	self:CustomIcon(dominateMindMarker, args.destName, dominateMindIcon)
	dominateMindIcon = dominateMindIcon - 1
end

function mod:DeathAndDecay(args)
	if self:Me(args.destGUID) then
		self:PersonalMessage(71001, "underyou")
		self:PlaySound(71001, "underyou")
	end
	if args.time - prevDeathAndDecay > 5 then
		prevDeathAndDecay = args.time
		self:Message(71001, "yellow")
	end
end

function mod:ManaBarrierRemoved()
	self:SetStage(2)
	self:Message("stages", "cyan", CL.stage:format(2), false)
	self:PlaySound("stages", "long")
	self:CDBar(71426, 12)
	self:CancelTimer(self.addsTimer)
	self:CancelDelayedMessage(L.adds_soon)
	self:StopBar(L.adds)
	if self:Heroic() then -- adds keep coming on heroic
		self:Bar("adds", 45, L.adds, L.adds_icon)
		self:DelayedMessage("adds", 40, "yellow", L.adds_soon, L.adds_icon)
		self.addsTimer = self:ScheduleTimer("AddsWave", 45)
	end
end

-- Stage Two

function mod:SummonSpirit(args)
	if args.time - prevShade > 5 then
		prevShade = args.time
		self:Message(71426, "yellow")
		self:CDBar(71426, 10)
	end
end

function mod:ShadeSwing(args)
	if self:MobId(args.sourceGUID) == 38222 and self:Me(args.destGUID) and args.time - prevShadeSwing > 2.5 then -- Vengeful Shade
		prevShadeSwing = args.time
		self:PersonalMessage(71426, false, L.shade_attack)
		self:PlaySound(71426, "warning")
	end
end

function mod:CurseOfTorpor(args)
	if self:Me(args.destGUID) then
		self:PersonalMessage(71237)
		self:PlaySound(71237, "warning")
	end
end

function mod:TouchOfInsignificance(args)
	local amount = args.amount or 1
	self:StackMessage(71204, "purple", args.destName, amount, 3)
	self:TargetBar(71204, 30, args.destName)
	if self:Me(args.destGUID) and amount >= 3 then
		self:PlaySound(71204, "alarm")
	end
end

function mod:Frostbolt(args)
	self:Message(72007, "yellow", CL.casting:format(args.spellName))
	self:CastBar(72007, 2)
	if self:Interrupter(args.sourceGUID) then
		self:PlaySound(72007, "alert")
	end
end

function mod:FrostboltInterrupted()
	self:StopCastBar(72007)
end

function mod:FrostboltVolley()
	self:CDBar(72906, 20)
end
