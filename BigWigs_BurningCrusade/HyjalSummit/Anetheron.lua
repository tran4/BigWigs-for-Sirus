--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Hyjal/Anetheron.lua, Sirus version with custom spells), draft by tools/dbm2bw
-- Not ported: announcing the feared players to the raid chat.

local mod, CL = BigWigs:NewBoss("Anetheron", 534, 1578)
if not mod then return end
mod:RegisterEnableMob(17808)
mod:SetEncounterID(619)

--------------------------------------------------------------------------------
-- Locals
--

local warnedInferno = false

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	fear_moved = "Фир сместился на 3 сек!", -- DBM: no English text
})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"berserk",
		317873, -- Wave of Horror
		317870, -- Inferno
		317872, -- Crimson Barrier
		317884, -- Mana Absorption
		317876, -- Finger of Death
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "Inferno", 317870)
	self:Log("SPELL_CAST_START", "CrimsonBarrier", 317872)
	self:Log("SPELL_CAST_START", "WaveOfHorror", 317873)
	self:Log("SPELL_CAST_START", "ManaAbsorption", 317884)
	self:Log("SPELL_AURA_APPLIED", "FingerOfDeath", 317876)
	self:Log("SPELL_AURA_REFRESH", "FingerOfDeath", 317876)
	self:Log("SPELL_AURA_APPLIED", "CrimsonBarrierApplied", 317872)
	self:Log("SPELL_AURA_REFRESH", "CrimsonBarrierApplied", 317872)
	self:Log("SPELL_SUMMON", "InfernoSummon", 317870)
	self:RegisterEvent("UNIT_HEALTH")
end

function mod:OnEngage()
	self:SetStage(1)
	warnedInferno = false
	self:CDBar(317873, 20)
	self:Bar(317872, 60)
	self:Berserk(600)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

do
	local function infernoTarget(self, name, guid)
		self:TargetMessage(317870, "red", name)
		if self:Me(guid) then
			self:PlaySound(317870, "warning") -- DBM: defensive (tank)
		else
			local unit = self:UnitTokenFromGUID(guid)
			if unit and self:UnitWithinRange(unit, 20) then
				self:PlaySound(317870, "runaway")
			end
		end
	end
	function mod:Inferno(args)
		local left = self:BarTimeLeft(317873)
		if left > 0 and left < 2 then
			self:Message(317873, "orange", L.fear_moved)
			self:CDBar(317873, 3)
		end
		self:CastBar(317870, 3)
		self:GetUnitTarget(infernoTarget, 0.1, args.sourceGUID)
		warnedInferno = false
	end
end

function mod:CrimsonBarrier(args)
	self:Bar(317872, 30)
	if self:Dispeller("magic", true) then
		self:Message(317872, "orange", CL.onboss:format(args.spellName))
		self:PlaySound(317872, "alert")
	end
end

function mod:CrimsonBarrierApplied(args)
	if self:Dispeller("magic", true) then
		self:Message(317872, "orange", CL.onboss:format(args.spellName))
	end
end

function mod:WaveOfHorror(args)
	self:DelayedMessage(317873, 17, "yellow", CL.soon:format(args.spellName))
	self:CDBar(317873, 20)
end

function mod:ManaAbsorption(args)
	self:Message(317884, "red", CL.casting:format(args.spellName))
	if self:Interrupter(args.sourceGUID) then
		self:PlaySound(317884, "alert")
	end
	self:Bar(317884, 20)
end

function mod:FingerOfDeath(args)
	self:TargetMessage(317876, "red", args.destName)
	self:CDBar(317876, 7)
end

function mod:InfernoSummon()
	self:Bar(317884, 20)
end

function mod:UNIT_HEALTH(_, unit)
	if not warnedInferno and self:IsEngaged() and self:MobId(self:UnitGUID(unit)) == 17808 and math.floor(self:GetHealth(unit)) % 10 == 1 then
		warnedInferno = true -- DBM: every x1% of health
		if self:Melee() then
			self:Message(317870, "orange", CL.soon:format(self:SpellName(317870)))
			self:PlaySound(317870, "alarm")
		end
	end
end
