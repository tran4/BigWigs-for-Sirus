--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-TheEye/KaelThas.lua, heroic mode with custom spells), draft by tools/dbm2bw
-- Kael'thas sits on his throne until stage 4: engaged by his pull yell (DBM localization) or the fight with him,
-- the advisors don't win. Not ported: unequipping weapons under mind control, the arrows, nameplate icons, Axe icon.

local mod, CL = BigWigs:NewBoss("Kael'thas Sunstrider", 550, 1576)
if not mod then return end
mod:RegisterEnableMob(19622)
mod:SetEncounterID(733)
mod:SetWinMobs(19622)
mod:SetEmulationWipeDelay(10) -- 3.3.5: the pauses between the advisors

--------------------------------------------------------------------------------
-- Locals
--

local mcTargets, mcIcon = {}, 8
local bombTargets = {}

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	engage_trigger1 = "Energy. Power. My people are addicted to it... a dependence made manifest after the Sunwell was destroyed. Welcome... to the future. A pity you are too late to stop it. No one can stop me now! Selama ashal'anore!",
	engage_trigger2 = "Energy. Power. My people are addicted to it... a dependence made manifest after the Sunwell was destroyed. Welcome to the future. A pity you are too late to stop it. No one can stop me now! Selama ashal'anore!",
	sanguinar_trigger = "You have persevered against some of my best advisors... but none can withstand the might of the Blood Hammer. Behold, Lord Sanguinar!",
	capernian_trigger = "Capernian will see to it that your stay here is a short one.",
	telonicus_trigger = "Well done, you have proven worthy to test your skills against my master engineer, Telonicus.",
	stage2_trigger = "As you see, I have many weapons in my arsenal....",
	stage3_trigger = "Perhaps I underestimated you. It would be unfair to make you fight all four advisors at once, but... fair treatment was never shown to my people. I'm just returning the favor.",
	stage4_trigger = "Alas, sometimes one must take matters into one's own hands. Balamore shanal!",
	stage5_trigger = "I have not come this far to be stopped! The future I have planned will not be jeopardized! Now you will taste true power!!",
	gaze_trigger = "sets eyes on ([^%s]+)!", -- pattern with the target name (DBM en)

	thaladred = "Thaladred the Darkener",
	sanguinar = "Lord Sanguinar",
	capernian = "Grand Astromancer Capernian",
	telonicus = "Master Engineer Telonicus",

	gaze = "Thaladred's Gaze",
	gaze_desc = "Show warnings and timer for Thaladred's Gaze target",
	gaze_icon = "spell_fire_burningspeed",
	gaze_msg = "Gaze on >%s<",
	gaze_bar = "New Gaze target",
	kaelthas = "Отсчет появления келя", -- DBM: no English text
})

--------------------------------------------------------------------------------
-- Initialization
--

local mcMarker = mod:AddMarkerOption(true, "player", 8, 36797, 8, 7, 6, 5)
local bombMarker = mod:AddMarkerOption(true, "player", 8, 308750, 8, 7)
local explosionMarker = mod:AddMarkerOption(true, "player", 8, 308797, 8)
function mod:GetOptions()
	return {
		"stages",
		"adds",
		"gaze",
		"berserk",
		40636, -- Bellowing Roar
		37018, -- Conflagration
		37036, -- Bomb
		35941, -- Gravity Lapse
		36815, -- Shock Barrier
		36723, -- Phoenix
		36797, -- Mind Control
		mcMarker,
		36731, -- Flamestrike
		-- heroic
		{308743, "SAY"}, -- Avenger's Shield
		{308732, "TANK_HEALER"}, -- Furious Strike
		{308741, "TANK_HEALER"}, -- Justice of Shadow
		{308756, "TANK_HEALER"}, -- Sparkling Strike
		308742, -- Shadow Consecration
		{308750, "SAY"}, -- Living Bomb of Dread
		bombMarker,
		308749, -- Bomb (heroic)
		{308797, "SAY"}, -- Explosion
		explosionMarker,
		308790, -- Cataclysm
		308734, -- Axe
		"proximity",
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "GravityLapse", 35941)
	self:Log("SPELL_CAST_START", "BellowingRoar", 40636)
	self:Log("SPELL_CAST_START", "Bomb", 37036)
	self:Log("SPELL_CAST_START", "ShadowConsecration", 308742)
	self:Log("SPELL_CAST_START", "FuriousStrikeCast", 308732)
	self:Log("SPELL_CAST_START", "Cataclysm", 308790)
	self:Log("SPELL_CAST_SUCCESS", "Conflagration", 37018)
	self:Log("SPELL_CAST_SUCCESS", "Phoenix", 36723)
	self:Log("SPELL_CAST_SUCCESS", "HeroicBomb", 308749)
	self:Log("SPELL_CAST_SUCCESS", "AvengersShield", 308743)
	self:Log("SPELL_CAST_SUCCESS", "ShockBarrier", 36815)
	self:Log("SPELL_CAST_SUCCESS", "Flamestrike", 36731)
	self:Log("SPELL_CAST_SUCCESS", "Axe", 308734)
	self:Log("SPELL_AURA_APPLIED", "FuriousStrike", 308732)
	self:Log("SPELL_AURA_APPLIED_DOSE", "FuriousStrike", 308732)
	self:Log("SPELL_AURA_APPLIED", "JusticeOfShadow", 308741)
	self:Log("SPELL_AURA_APPLIED_DOSE", "JusticeOfShadow", 308741)
	self:Log("SPELL_AURA_APPLIED", "SparklingStrike", 308756)
	self:Log("SPELL_AURA_APPLIED_DOSE", "SparklingStrike", 308756)
	self:Log("SPELL_AURA_APPLIED", "LivingBomb", 308750)
	self:Log("SPELL_AURA_REMOVED", "LivingBombRemoved", 308750)
	self:Log("SPELL_AURA_APPLIED", "Explosion", 308797)
	self:Log("SPELL_AURA_APPLIED", "MindControl", 36797)
	self:Log("SPELL_AURA_REMOVED", "MindControlRemoved", 36797)
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
	self:RegisterEvent("CHAT_MSG_MONSTER_EMOTE")
end

function mod:OnEngage()
	self:SetStage(1)
	mcTargets, mcIcon = {}, 8
	bombTargets = {}
	self:Message("stages", "cyan", CL.other:format(CL.stage:format(1), CL.incoming:format(L.thaladred)), false)
	self:Bar("adds", 30, L.thaladred, "spell_nature_wispsplode")
	if self:Difficulty() == 6 then -- 25 heroic
		self:CDBar(308734, 52)
	end
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:CHAT_MSG_MONSTER_EMOTE(_, msg)
	local target = msg:match(L.gaze_trigger)
	if target then
		self:Message("gaze", "red", L.gaze_msg:format(target), L.gaze_icon)
		self:Bar("gaze", 8.5, L.gaze_bar, L.gaze_icon)
		if target == self:UnitName("player") then
			self:PlaySound("gaze", "runaway")
		end
	end
end

local function nextAdd(self, name, delay)
	self:Message("adds", "cyan", CL.incoming:format(name), "spell_nature_wispsplode")
	self:Bar("adds", delay, name, "spell_nature_wispsplode")
end

local function stage(self, n)
	self:SetStage(n)
	self:Message("stages", "cyan", CL.stage:format(n), false)
	self:PlaySound("stages", "long")
end

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if msg == L.engage_trigger1 or msg == L.engage_trigger2 then
		if not self:IsEngaged() then self:Engage() end
		return
	elseif not self:IsEngaged() then
		return
	end
	local heroic = self:Difficulty() == 6
	if msg:find(L.sanguinar_trigger, nil, true) then
		self:StopBar(L.gaze_bar)
		nextAdd(self, L.sanguinar, 12.5)
		if heroic then
			self:StopBar(308732)
			self:StopBar(308734)
			self:CDBar(308743, 34.5)
		else
			self:CDBar(40636, 33)
		end
	elseif msg:find(L.capernian_trigger, nil, true) then
		self:StopBar(40636)
		nextAdd(self, L.capernian, 7)
		if heroic then
			self:StopBar(308743)
			self:StopBar(308742)
			self:StopBar(308741)
			self:CDBar(308749, 41)
		end
		self:OpenProximity("proximity", 10)
	elseif msg:find(L.telonicus_trigger, nil, true) then
		self:CloseProximity("proximity")
		self:StopBar(37018)
		self:CancelDelayedMessage(CL.soon:format(self:SpellName(37018)))
		nextAdd(self, L.telonicus, 8.4)
		if heroic then
			self:StopBar(308749)
		else
			self:DelayedMessage(37036, 13, "yellow", CL.soon:format(self:SpellName(37036)))
			self:CDBar(37036, 18)
		end
	elseif msg:find(L.stage2_trigger, nil, true) then
		if not heroic then
			stage(self, 2)
			self:CancelDelayedMessage(CL.soon:format(self:SpellName(37036)))
			self:StopBar(37036)
			self:Bar("stages", 123, CL.stage:format(3), "spell_shadow_animatedead")
		end
	elseif msg:find(L.stage3_trigger, nil, true) then
		stage(self, 3)
		self:OpenProximity("proximity", 10)
		if heroic then
			self:Bar("stages", 210, CL.stage:format(4), 34753)
			self:CDBar(308749, 39)
			self:CDBar(308734, 28)
			self:CDBar(308743, 28)
		else
			self:Bar("stages", 180, CL.stage:format(4), 34753)
			self:CDBar(40636, 31)
			self:DelayedMessage(37036, 10, "yellow", CL.soon:format(self:SpellName(37036)))
			self:CDBar(37036, 15)
		end
	elseif msg:find(L.stage4_trigger, nil, true) then
		stage(self, 4)
		self:StopBar(CL.stage:format(4))
		self:CloseProximity("proximity")
		if not heroic then
			self:Berserk(392)
			self:StopBar(40636)
			self:StopBar(37036)
			self:StopBar(37018)
			self:CancelDelayedMessage(CL.soon:format(self:SpellName(37036)))
			self:CancelDelayedMessage(CL.soon:format(self:SpellName(37018)))
			self:CDBar(36797, 40)
			self:CDBar(36815, 60)
			self:CDBar(36723, 45)
			self:DelayedMessage(36815, 55, "yellow", CL.soon:format(self:SpellName(36815)))
			self:DelayedMessage(36723, 40, "yellow", CL.soon:format(self:SpellName(36723)))
			self:DelayedMessage(36797, 35, "yellow", CL.soon:format(self:SpellName(36797)))
		end
	elseif msg:find(L.stage5_trigger, nil, true) then
		stage(self, 5)
		if heroic then
			self:Bar("stages", 32, L.kaelthas, 2457)
			self:CDBar(308797, 82)
			self:CDBar(308790, 92)
			self:CDBar(35941, 122)
		else
			self:StopBar(36797)
			self:StopBar(36723)
			self:CancelDelayedMessage(CL.soon:format(self:SpellName(36797)))
			self:CDBar(35941, 90)
			self:CDBar(36723, 112)
			self:DelayedMessage(35941, 106, "yellow", CL.soon:format(self:SpellName(35941)))
		end
	end
end

function mod:GravityLapse(args)
	self:Message(35941, "red")
	self:PlaySound(35941, "long")
	if self:Difficulty() == 6 then
		self:Bar(35941, 63, CL.other:format(args.spellName, CL.active))
		self:CDBar(35941, 150)
	else
		self:Bar(35941, 32.5, CL.other:format(args.spellName, CL.active))
		self:CDBar(35941, 90)
		self:DelayedMessage(35941, 85, "yellow", CL.soon:format(args.spellName))
	end
end

function mod:BellowingRoar()
	self:CDBar(40636, 31)
end

function mod:Bomb(args)
	self:DelayedMessage(37036, 20, "yellow", CL.soon:format(args.spellName))
	self:CDBar(37036, 25)
end

function mod:ShadowConsecration(args)
	self:Message(308742, "orange")
	self:CDBar(308742, 17)
end

function mod:FuriousStrikeCast()
	self:CDBar(308732, 7)
end

function mod:Cataclysm(args)
	self:Message(308790, "red")
	self:PlaySound(308790, "runaway")
	self:CDBar(308790, 126)
	self:CastBar(308790, 8)
	self:OpenProximity(308790, 40)
	self:ScheduleTimer("CloseProximity", 10, 308790)
end

function mod:Conflagration(args)
	self:TargetMessage(37018, "orange", args.destName)
	self:CancelDelayedMessage(CL.soon:format(args.spellName))
	self:DelayedMessage(37018, 16, "yellow", CL.soon:format(args.spellName))
	self:CDBar(37018, 20)
end

function mod:Phoenix(args)
	local five = self:GetStage() == 5
	self:CDBar(36723, five and 80 or 55)
	self:DelayedMessage(36723, five and 75 or 55, "yellow", CL.soon:format(args.spellName))
end

function mod:HeroicBomb()
	self:CDBar(308749, 35)
end

do
	local function avengerTarget(self, name, guid)
		self:TargetMessage(308743, "red", name)
		if self:Me(guid) then
			self:PlaySound(308743, "warning")
			self:Say(308743)
		else
			local unit = self:UnitTokenFromGUID(guid)
			if unit and CheckInteractDistance(unit, 2) then -- DBM: trade distance
				self:Message(308743, "orange", CL.near:format(self:SpellName(308743)))
				self:PlaySound(308743, "alarm")
			end
		end
	end
	function mod:AvengersShield(args)
		self:CDBar(308743, 22)
		self:GetUnitTarget(avengerTarget, 0.1, args.sourceGUID)
	end
end

function mod:ShockBarrier(args)
	self:Message(36815, "orange")
	self:CDBar(36815, 70)
	self:DelayedMessage(36815, 65, "yellow", CL.soon:format(args.spellName))
end

function mod:Flamestrike()
	self:CDBar(36731, 35)
end

function mod:Axe()
	self:CDBar(308734, 22)
end

function mod:FuriousStrike(args)
	self:StackMessage(308732, "purple", args.destName, args.amount or 1, 2)
	self:TargetBar(308732, 30, args.destName)
	self:CDBar(308732, 7)
end

function mod:JusticeOfShadow(args)
	self:CDBar(308741, 9)
	self:StackMessage(308741, "purple", args.destName, args.amount or 1, 2)
	self:TargetBar(308741, 30, args.destName)
end

function mod:SparklingStrike(args)
	self:StackMessage(308756, "purple", args.destName, args.amount or 1, 2)
	self:TargetBar(308756, 15, args.destName)
	self:CDBar(308756, 6)
end

function mod:LivingBomb(args)
	bombTargets[#bombTargets + 1] = args.destName
	self:CustomIcon(bombMarker, args.destName, 9 - #bombTargets) -- 8, 7
	if self:Me(args.destGUID) then
		self:PlaySound(308750, "warning")
		self:Say(308750)
	else
		local unit = self:UnitTokenFromGUID(args.destGUID)
		if unit and CheckInteractDistance(unit, 3) then -- DBM: duel distance
			self:Message(308750, "orange", CL.near:format(args.spellName))
		end
	end
	if #bombTargets >= 2 then
		self:TargetsMessage(308750, "red", bombTargets, #bombTargets)
		bombTargets = {}
	end
end

function mod:LivingBombRemoved(args)
	self:CustomIcon(bombMarker, args.destName)
end

function mod:Explosion(args)
	self:CDBar(308797, 115)
	self:CastBar(308797, 5)
	self:TargetMessage(308797, "red", args.destName)
	self:CustomIcon(explosionMarker, args.destName, 8)
	self:ScheduleTimer("CustomIcon", 5, explosionMarker, args.destName)
	if self:Me(args.destGUID) then
		self:PlaySound(308797, "warning")
		self:Say(308797)
	end
end

function mod:MindControl(args)
	self:CDBar(36797, 70)
	self:CancelDelayedMessage(CL.soon:format(args.spellName))
	self:DelayedMessage(36797, 65, "yellow", CL.soon:format(args.spellName))
	mcTargets[#mcTargets + 1] = args.destName
	self:CustomIcon(mcMarker, args.destName, mcIcon)
	mcIcon = mcIcon > 5 and mcIcon - 1 or 8
	if #mcTargets >= 3 then
		self:TargetsMessage(36797, "red", mcTargets, #mcTargets)
		mcTargets, mcIcon = {}, 8
	end
end

function mod:MindControlRemoved(args)
	self:CustomIcon(mcMarker, args.destName)
end
