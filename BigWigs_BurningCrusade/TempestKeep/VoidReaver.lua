--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-TheEye/VoidReaver.lua, heroic mode with custom spells), draft by tools/dbm2bw
-- Most texts of the Sirus version are only in the Russian DBM localization: the English defaults are the Russian texts.
-- Not ported: the info frame, nameplate icons, announcing to the raid chat.

local mod, CL = BigWigs:NewBoss("Void Reaver", 550, 1574)
if not mod then return end
mod:RegisterEnableMob(19516)
mod:SetEncounterID(731)

--------------------------------------------------------------------------------
-- Locals
--

local signIcon = 8
local magnetTargets = {}

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	engage_trigger = "Внимание! Вы подлежите уничтожению!", -- DBM: no English text
	low_damage = "ВНИМАНИЕ!!! ФАЗА пониженного УРОНА!!!", -- DBM: no English text
	high_damage = "ВНИМАНИЕ!!! ФАЗА ПОВЫШЕННОГО УРОНА!!!", -- DBM: no English text
})

--------------------------------------------------------------------------------
-- Initialization
--

local signMarker = mod:AddMarkerOption(true, "player", 8, 308471, 8, 7, 6, 5, 4)
function mod:GetOptions()
	return {
		"berserk",
		34162, -- Pounding
		{25778, "HEALER"}, -- Knock Away
		-- heroic
		308465, -- low damage stage
		308474, -- high damage stage
		308466, -- Arcane Orb
		308467, -- Magnetism
		{308471, "SAY"}, -- Arcane Sign
		signMarker,
		"proximity",
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_SUCCESS", "KnockAway", 25778)
	self:Log("SPELL_CAST_SUCCESS", "Pounding", 34162)
	self:Log("SPELL_AURA_APPLIED", "LowDamage", 308465)
	self:Log("SPELL_AURA_REFRESH", "LowDamage", 308465)
	self:Log("SPELL_AURA_APPLIED", "HighDamage", 308473)
	self:Log("SPELL_AURA_REFRESH", "HighDamage", 308473)
	self:Log("SPELL_AURA_APPLIED", "Sign", 308471)
	self:Log("SPELL_AURA_REFRESH", "SignRefresh", 308471)
	self:Log("SPELL_AURA_REMOVED", "SignRemoved", 308471)
	self:Log("SPELL_AURA_APPLIED", "Magnetism", 308467)
	self:Log("SPELL_AURA_REFRESH", "Magnetism", 308467)
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
	self:RegisterEvent("UNIT_HEALTH")
end

function mod:OnEngage()
	self:SetStage(1)
	signIcon = 8
	magnetTargets = {}
	if self:Difficulty() == 6 then -- 25 heroic
		self:CDBar(308465, 60)
		self:CDBar(308466, 28)
		self:OpenProximity("proximity", 15)
	else
		self:Berserk(360)
		self:CDBar(34162, 14)
		self:CDBar(25778, 20)
	end
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if msg:find(L.engage_trigger, nil, true) and not self:IsEngaged() then
		self:Engage() -- DBM RegisterCombat("yell")
	end
end

function mod:KnockAway()
	self:CDBar(25778, 20)
end

function mod:Pounding()
	self:CDBar(34162, 14)
end

function mod:LowDamage()
	self:SetStage(1)
	self:CDBar(308465, 60)
	self:CDBar(308466, 60)
	self:Message(308465, "green", L.low_damage)
end

function mod:HighDamage()
	self:SetStage(2)
	self:CDBar(308474, 60)
	self:Message(308474, "red", L.high_damage)
	self:PlaySound(308474, "alarm")
end

do
	local signTargets = {}
	local prev = 0
	function mod:Sign(args)
		if args.time - prev > 2 then
			prev = args.time
			signTargets = {}
			signIcon = 8
		end
		signTargets[#signTargets + 1] = args.destName
		self:TargetsMessage(308471, "red", signTargets, nil, nil, nil, 0.3)
		if signIcon >= 4 then
			self:CustomIcon(signMarker, args.destName, signIcon)
			signIcon = signIcon - 1
		end
		self:CDBar(308471, 16)
		if self:Me(args.destGUID) then
			self:PlaySound(308471, "runaway")
			self:Say(308471)
		end
	end
end

function mod:SignRefresh(args)
	if self:Me(args.destGUID) then
		self:PersonalMessage(308471)
		self:PlaySound(308471, "runaway")
		self:Say(308471)
	end
end

function mod:SignRemoved(args)
	self:CustomIcon(signMarker, args.destName)
end

function mod:AnnounceMagnetism()
	self:TargetsMessage(308467, "orange", magnetTargets, #magnetTargets)
	magnetTargets = {}
end

function mod:Magnetism(args)
	magnetTargets[#magnetTargets + 1] = args.destName
	if self:Me(args.destGUID) then
		self:PlaySound(308467, "runaway")
	end
	self:CDBar(308466, 30)
	self:CancelTimer(self.magnetTimer)
	self.magnetTimer = self:ScheduleTimer("AnnounceMagnetism", 0.1)
end

function mod:UNIT_HEALTH(_, unit)
	if self:Difficulty() == 6 and self:GetStage() ~= 3 and self:MobId(self:UnitGUID(unit)) == 19516 and self:GetHealth(unit) <= 50 then
		self:SetStage(3)
	end
end
