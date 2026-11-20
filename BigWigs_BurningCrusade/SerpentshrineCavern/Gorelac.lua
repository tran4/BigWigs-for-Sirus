--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Serpentshrine/Gorelac.lua), a custom Sirus boss, no journal id.
-- DBM has only the Russian name: the English default is the Russian text.

local mod, CL = BigWigs:NewBoss("Gorelac", 548)
if not mod then return end
mod:RegisterEnableMob(121217)
mod:SetEncounterID(62901)

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	bossName = "Горе'лац", -- DBM: no English text
})
mod.displayName = L.bossName

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"berserk",
		"proximity",
		310557, -- Call Guardians
		310548, -- Strong Beat
		310549, -- Poisonous
		310566, -- Shrill Screech
		310564, -- Powerful Shot
		310560, -- Massive Shell
		310546, -- Ripping Thorn
		310547, -- Poisonous Blood
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "ShrillScreech", 310566)
	self:Log("SPELL_CAST_START", "PoisonousCast", 310549)
	self:Log("SPELL_CAST_START", "PowerfulShot", 310565, 310564)
	self:Log("SPELL_CAST_START", "CallGuardians", 310557)
	self:Log("SPELL_CAST_SUCCESS", "StrongBeatSuccess", 310548)
	self:Log("SPELL_CAST_SUCCESS", "MassiveShell", 310560, 310561, 310562, 310563)
	self:Log("SPELL_AURA_APPLIED", "RippingThorn", 310546)
	self:Log("SPELL_AURA_APPLIED_DOSE", "RippingThorn", 310546) -- 3.3.5: DBM only registers SPELL_AURA_APPLIED, the stacks come as _DOSE
	self:Log("SPELL_AURA_APPLIED", "PoisonousBlood", 310547)
	self:Log("SPELL_AURA_APPLIED_DOSE", "PoisonousBlood", 310547)
	self:Log("SPELL_AURA_APPLIED", "StrongBeat", 310548)
	self:Log("SPELL_AURA_APPLIED_DOSE", "StrongBeat", 310548)
	self:Log("SPELL_AURA_APPLIED", "Poisonous", 310549)
	self:Log("SPELL_AURA_APPLIED", "ShrillScreechApplied", 310566)
	self:Log("SPELL_AURA_REMOVED", "TankDebuffRemoved", 310548, 310549)
end

function mod:OnEngage()
	self:Berserk(750)
	self:Bar(310557, 45)
	self:OpenProximity("proximity", 6)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:ShrillScreech(args)
	self:Message(310566, "red", CL.casting:format(args.spellName))
end

function mod:ShrillScreechApplied(args)
	self:Bar(310566, 6, CL.other:format(args.spellName, CL.active))
	if self:Me(args.destGUID) then
		self:PersonalMessage(310566)
		self:PlaySound(310566, "alarm")
	end
end

function mod:PoisonousCast(args)
	self:Message(310549, "orange", CL.casting:format(args.spellName))
	self:CDBar(310549, 25)
end

function mod:PowerfulShot(args)
	if args.destName then
		self:TargetMessage(310564, "red", args.destName)
	else
		self:Message(310564, "red", CL.casting:format(args.spellName))
	end
end

function mod:CallGuardians(args)
	self:Message(310557, "cyan")
	if self:Ranged() or self:Tank() then -- DBM: switch (Ranged|Tank)
		self:PlaySound(310557, "info")
	end
	self:Bar(310557, 45)
end

function mod:StrongBeatSuccess()
	self:CDBar(310548, 25)
end

function mod:MassiveShell(args)
	self:Message(310560, "yellow")
end

function mod:RippingThorn(args)
	if self:Me(args.destGUID) and (args.amount or 1) >= 10 and self:Melee() then
		self:StackMessage(310546, "blue", args.destName, args.amount, 10)
		self:PlaySound(310546, "alarm")
	end
end

function mod:PoisonousBlood(args)
	if self:Me(args.destGUID) and (args.amount or 1) >= 10 and self:Ranged() then
		self:StackMessage(310547, "blue", args.destName, args.amount, 10)
		self:PlaySound(310547, "alarm")
	end
end

function mod:StrongBeat(args)
	self:StackMessage(310548, "purple", args.destName, args.amount or 1, 1)
	if self:Me(args.destGUID) then
		self:PlaySound(310548, "warning")
		self:TargetBar(310548, 30, args.destName)
	end
end

function mod:Poisonous(args)
	self:TargetBar(310549, 30, args.destName)
	if self:Me(args.destGUID) then
		self:PersonalMessage(310549)
		self:PlaySound(310549, "warning")
	end
end

function mod:TankDebuffRemoved(args)
	if self:Me(args.destGUID) then
		self:StopBar(args.spellName, args.destName)
	end
end
