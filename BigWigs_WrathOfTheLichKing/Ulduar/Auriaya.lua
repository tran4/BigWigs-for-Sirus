--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Ulduar/Auriaya.lua), draft by tools/dbm2bw

local mod, CL = BigWigs:NewBoss("Auriaya", 603, 1643)
if not mod then return end
mod:RegisterEnableMob(33515)
mod:SetEncounterID(750)

--------------------------------------------------------------------------------
-- Locals
--

local catLives = 9
local prevVoid = 0

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	defender = "Feral Defender activates",
	defender_desc = "Show timer for when Feral Defender is activated",
	defender_icon = 64455,
	defender_died = "Feral Defender down (%d lives remaining)",
	defender_died_one = "Feral Defender down (1 life remaining)",
})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"berserk",
		312955, -- Terrifying Screech
		312954, -- Sonic Screech
		312956, -- Guardian Swarm
		64389, -- Sentinel Blast
		"defender",
		312972, -- Feral Essence
		312971, -- Void Zone
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "SentinelBlast", 64678, 64389, 312600, 312953)
	self:Log("SPELL_CAST_START", "TerrifyingScreech", 64386, 312602, 312955)
	self:Log("SPELL_CAST_START", "SonicScreech", 64688, 64422, 312601, 312954)
	self:Log("SPELL_AURA_APPLIED", "GuardianSwarm", 64396, 312603, 312956)
	self:Log("SPELL_AURA_APPLIED", "FeralEssence", 64455, 312619, 312972)
	self:Log("SPELL_DAMAGE", "VoidZoneDamage", 64459, 64675, 312610, 312963)
	self:Log("SPELL_MISSED", "VoidZoneDamage", 64459, 64675, 312610, 312963)
	self:Death("DefenderDeath", 34035)
end

function mod:OnEngage()
	catLives = 9
	self:Berserk(600)
	self:Bar(312955, 40)
	self:Bar(312954, 60)
	self:Bar("defender", 60, L.defender, L.defender_icon)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:SentinelBlast(args)
	if self:Interrupter(args.sourceGUID) then
		self:Message(64389, "yellow", CL.casting:format(args.spellName))
		self:PlaySound(64389, "alert")
	end
end

function mod:TerrifyingScreech(args)
	self:Message(312955, "red")
	self:PlaySound(312955, "long") -- fear
	self:ScheduleTimer("Bar", 2, 312955, 35.5)
	self:DelayedMessage(312955, 34, "yellow", CL.soon:format(args.spellName))
end

function mod:SonicScreech(args)
	self:Message(312954, "orange")
	self:PlaySound(312954, "alert") -- share the damage
	self:Bar(312954, 25)
end

function mod:GuardianSwarm(args)
	self:TargetMessage(312956, "yellow", args.destName)
	self:Bar(312956, 36)
end

function mod:FeralEssence(args)
	self:Message(312972, "orange", CL.spawned:format(args.destName or self:SpellName(312972)))
	self:PlaySound(312972, "info")
end

function mod:DefenderDeath()
	catLives = catLives - 1
	if catLives > 0 then
		self:Message("defender", "green", catLives == 1 and L.defender_died_one or L.defender_died:format(catLives), L.defender_icon)
		self:Bar("defender", 30, L.defender, L.defender_icon)
	end
end

function mod:VoidZoneDamage(args)
	if self:Me(args.destGUID) and args.time - prevVoid > 3 then
		prevVoid = args.time
		self:PersonalMessage(312971, "underyou")
		self:PlaySound(312971, "underyou")
	end
end
