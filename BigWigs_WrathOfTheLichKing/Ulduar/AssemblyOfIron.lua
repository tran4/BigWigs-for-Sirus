--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Ulduar/IronCouncil.lua), draft by tools/dbm2bw

local mod, CL = BigWigs:NewBoss("The Assembly of Iron", 603, 1641)
if not mod then return end
mod:RegisterEnableMob(32857, 32867, 32927) -- Stormcaller Brundir, Steelbreaker, Runemaster Molgeim
mod:SetEncounterID(748)
mod:SetWinMobs(32857, 32867, 32927) -- 3.3.5: DBM kills when all of them died

--------------------------------------------------------------------------------
-- Locals
--

local disruptionList = {}
local disruptionIcon = 7
local prevDisruption = 0
local brundirDead, molgeimDead = false, false

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	steelbreaker = "Steelbreaker",
	molgeim = "Runemaster Molgeim",
	brundir = "Stormcaller Brundir",
})

--------------------------------------------------------------------------------
-- Initialization
--

local overwhelmingMarker = mod:AddMarkerOption(false, "player", 8, 61888, 8)
local disruptionMarker = mod:AddMarkerOption(false, "player", 7, 312770, 7, 6, 5, 4, 3, 2, 1)
function mod:GetOptions()
	return {
		"berserk",
		312766, -- Supercharge
		-- Stormcaller Brundir
		{312780, "OFF"}, -- Chain Lightning
		312782, -- Overload
		312784, -- Lightning Whirl
		312786, -- Lightning Tendrils
		-- Steelbreaker
		{312769, "TANK_HEALER"}, -- Fusion Punch
		312772, -- Overwhelming Power
		overwhelmingMarker,
		{312770, "PROXIMITY"}, -- Static Disruption (3.3.5: proximity when Steelbreaker is alone, user's request)
		disruptionMarker,
		-- Runemaster Molgeim
		{312774, "DISPEL"}, -- Shield of Runes
		61973, -- Rune of Power
		312777, -- Rune of Death
		312778, -- Rune of Summoning
	}, {
		[312780] = L.brundir,
		[312769] = L.steelbreaker,
		[312774] = L.molgeim,
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "Supercharge", 312766, 312413, 61920)
	self:Log("SPELL_CAST_START", "ChainLightning", 312780, 312427, 63479, 61879)
	self:Log("SPELL_CAST_START", "LightningWhirl", 312783, 312430, 63483, 61915)
	self:Log("SPELL_AURA_APPLIED", "LightningWhirlApplied", 63483, 61915)
	self:Log("SPELL_CAST_SUCCESS", "Overload", 312781, 312428, 61869, 63481)
	self:Log("SPELL_AURA_APPLIED", "LightningTendrils", 312786, 312785, 312432, 312433, 63486, 61887)
	self:Log("SPELL_CAST_START", "FusionPunch", 312769, 312416, 61903, 63493)
	self:Log("SPELL_AURA_APPLIED", "FusionPunchApplied", 312769, 312416, 61903, 63493)
	self:Log("SPELL_AURA_APPLIED", "OverwhelmingPower", 312771, 312772, 312418, 312419, 64637, 61888)
	self:Log("SPELL_CAST_START", "StaticDisruption", 312770, 312417, 63495, 61912, 63494)
	self:Log("SPELL_AURA_APPLIED", "StaticDisruptionApplied", 312770, 312417, 63495, 61912, 63494)
	self:Log("SPELL_CAST_START", "ShieldOfRunes", 312775, 312774, 312421, 62274, 63489)
	self:Log("SPELL_AURA_APPLIED", "ShieldOfRunesApplied", 312775, 312774, 312421, 62274, 63489)
	self:Log("SPELL_CAST_START", "RuneOfSummoning", 312779, 312778, 312425, 312426, 62273)
	self:Log("SPELL_CAST_START", "RuneOfPower", 61973, 64321, 61974)
	self:Log("SPELL_CAST_SUCCESS", "RuneOfDeath", 312777, 312424, 63490, 62269)
	self:Log("SPELL_AURA_APPLIED", "RuneOfDeathApplied", 312424, 312777, 62269, 63490)
	self:Death("BrundirDeath", 32857)
	self:Death("MolgeimDeath", 32927) -- 3.3.5: stop his bars (Rune of Power stayed on the screen)
end

function mod:OnEngage()
	disruptionList = {}
	disruptionIcon = 7
	brundirDead, molgeimDead = false, false
	self:Berserk(900)
	self:CDBar(61973, 21)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:Supercharge(args)
	self:Message(312766, "orange")
end

-- Stormcaller Brundir

function mod:ChainLightning(args)
	self:Message(312780, "yellow")
end

function mod:LightningWhirl(args)
	self:CastBar(312784, 5)
end

function mod:LightningWhirlApplied(args)
	self:CastBar(312784, 5)
	if self:Interrupter(args.destGUID) then
		self:Message(312784, "yellow", CL.casting:format(self:SpellName(312784)))
		self:PlaySound(312784, "alert")
	end
end

function mod:Overload(args)
	self:CastBar(312782, 6)
	-- DBM: only when Brundir is targeted (an option there to always warn)
	if self:MobId(self:UnitGUID("target")) == 32857 then
		self:Message(312782, "red")
		self:PlaySound(312782, "alarm") -- run
	end
end

function mod:LightningTendrils(args)
	self:Message(312786, "red")
	self:PlaySound(312786, "alarm") -- run
	self:CastBar(312786, 27)
end

local function steelbreakerAlone(self)
	-- 3.3.5: only Steelbreaker left, spread out for Static Disruption (user's request; 10 yards, no range in DBM Sirus)
	if brundirDead and molgeimDead then
		self:OpenProximity(312770, 10)
	end
end

function mod:BrundirDeath()
	brundirDead = true
	if not molgeimDead then -- 3.3.5: Molgeim's bars only while he lives
		self:CDBar(61973, 25)
		self:Bar(312777, 25)
		self:CastBar(312774, 27)
	end
	steelbreakerAlone(self)
end

function mod:MolgeimDeath()
	molgeimDead = true
	self:StopBar(61973) -- Rune of Power
	self:StopBar(312777) -- Rune of Death
	self:StopCastBar(312774) -- Shield of Runes
	steelbreakerAlone(self)
end

-- Steelbreaker

function mod:FusionPunch(args)
	self:Message(312769, "purple")
	self:CastBar(312769, 3)
end

function mod:FusionPunchApplied(args)
	self:TargetBar(312769, 4, args.destName)
end

function mod:OverwhelmingPower(args)
	local t = self:Difficulty() == 5 and 60 or 35 -- until the meltdown
	self:TargetMessage(312772, "orange", args.destName)
	self:TargetBar(312772, t, args.destName)
	self:CustomIcon(overwhelmingMarker, args.destName, 8)
	self:ScheduleTimer("CustomIcon", t, overwhelmingMarker, args.destName)
end

function mod:StaticDisruption(args)
	self:Bar(312770, 32)
end

function mod:StaticDisruptionApplied(args)
	if args.time - prevDisruption > 2 then
		disruptionList = {}
		disruptionIcon = 7
	end
	prevDisruption = args.time
	disruptionList[#disruptionList + 1] = args.destName
	self:TargetsMessage(312770, "yellow", disruptionList, nil, nil, nil, 0.3)
	if disruptionIcon > 0 then
		self:CustomIcon(disruptionMarker, args.destName, disruptionIcon)
		self:ScheduleTimer("CustomIcon", 20, disruptionMarker, args.destName)
		disruptionIcon = disruptionIcon - 1
	end
end

-- Runemaster Molgeim

function mod:ShieldOfRunes(args)
	self:Message(312774, "yellow")
end

function mod:ShieldOfRunesApplied(args)
	if not self:Player(args.destFlags) then
		self:CastBar(312774, 15)
		if self:Dispeller("magic", true, 312774) then
			self:TargetMessage(312774, "orange", args.destName)
			self:PlaySound(312774, "alarm")
		end
	end
end

function mod:RuneOfSummoning(args)
	self:Message(312778, "orange")
end

function mod:RuneOfPower(args)
	self:Message(61973, "yellow")
	self:CDBar(61973, 35)
end

function mod:RuneOfDeath(args)
	self:Message(312777, "orange")
	self:Bar(312777, 35)
end

function mod:RuneOfDeathApplied(args)
	if self:Me(args.destGUID) then
		self:PersonalMessage(312777, "underyou")
		self:PlaySound(312777, "underyou")
	end
end
