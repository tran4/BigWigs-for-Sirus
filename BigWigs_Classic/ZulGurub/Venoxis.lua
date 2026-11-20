--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-ZG/Venoxis.lua), no journal id: the name is from the DBM locale

local mod, CL = BigWigs:NewBoss("High Priest Venoxis", 309)
if not mod then return end
mod:RegisterEnableMob(14507)
mod:SetEncounterID(784)

--------------------------------------------------------------------------------
-- Locals
--

local warnedSoon = false

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	bossName = "High Priest Venoxis",
})
mod.displayName = L.bossName

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"stages",
		23861, -- Poison Cloud
		23860, -- Holy Fire
		23895, -- Renew
		23865, -- Parasitic Serpent
		"proximity",
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_SUCCESS", "PoisonCloud", 23861)
	self:Log("SPELL_CAST_START", "HolyFireCast", 23860)
	self:Log("SPELL_AURA_APPLIED", "HolyFire", 23860)
	self:Log("SPELL_AURA_REMOVED", "HolyFireRemoved", 23860)
	self:Log("SPELL_AURA_APPLIED", "Renew", 23895)
	self:Log("SPELL_AURA_REMOVED", "RenewRemoved", 23895)
	self:Log("SPELL_AURA_APPLIED", "ParasiticSerpent", 23865)
	self:RegisterEvent("UNIT_HEALTH")
end

function mod:OnEngage()
	warnedSoon = false
	self:OpenProximity("proximity", 10)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:PoisonCloud(args)
	self:Message(23861, "yellow")
	self:Bar(23861, 10, CL.other:format(args.spellName, CL.active))
end

function mod:HolyFireCast(args)
	-- DBM: only for the caster you are targeting or focusing, if you can interrupt
	if self:Hostile(args.sourceFlags) and (self:UnitGUID("target") == args.sourceGUID or self:UnitGUID("focus") == args.sourceGUID) and self:Interrupter() then
		self:Message(23860, "red", CL.casting:format(args.spellName))
		self:PlaySound(23860, "alert")
	end
end

function mod:HolyFire(args)
	if self:Player(args.destFlags) and (self:Dispeller("magic") or self:Healer()) then -- DBM: magic removers and healers
		self:TargetMessage(23860, "orange", args.destName)
		self:TargetBar(23860, 8, args.destName)
	end
end

function mod:HolyFireRemoved(args)
	self:StopBar(23860, args.destName)
end

function mod:Renew(args)
	if not self:Player(args.destFlags) then
		self:Message(23895, "orange", CL.other:format(args.spellName, args.destName))
		if self:Dispeller("magic", true) then
			self:PlaySound(23895, "alert") -- DBM: dispel the boss
			self:TargetBar(23895, 15, args.destName)
		end
	end
end

function mod:RenewRemoved(args)
	self:StopBar(23895, args.destName)
end

function mod:ParasiticSerpent(args)
	self:TargetMessage(23865, "yellow", args.destName)
end

function mod:UNIT_HEALTH(_, unit)
	if not warnedSoon and self:IsEngaged() and self:MobId(self:UnitGUID(unit)) == 14507 and self:GetHealth(unit) <= 53 then
		warnedSoon = true
		self:Message("stages", "cyan", CL.soon:format(CL.stage:format(2)), false)
	end
end
