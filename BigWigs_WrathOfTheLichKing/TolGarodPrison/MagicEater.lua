--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-TolGarodePrison/MagicEater.lua), a custom Sirus raid boss, no journal id.
-- DBM has only the Russian name: the English default is the Russian text. The pull timers are those DBM starts when
-- the boss is targeted on entering combat. Not ported: nameplate icons.

local mod, CL = BigWigs:NewBoss("Magic Eater", 10955)
if not mod then return end
mod:RegisterEnableMob(84017)
mod:SetEncounterID(84017) -- DBM Sirus custom encounter id

--------------------------------------------------------------------------------
-- Locals
--

local icons = {}
local prevOverload = {}
local prevActivation = 0

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	bossName = "Пожиратель магии", -- DBM: no English text
})
mod.displayName = L.bossName

--------------------------------------------------------------------------------
-- Initialization
--

local darkMarker = mod:AddMarkerOption(true, "player", 8, 317662, 8, 7, 6)
local felMarker = mod:AddMarkerOption(true, "player", 8, 317666, 8, 7, 6)
function mod:GetOptions()
	return {
		317673, -- Shocking Blow
		317674, -- Howling Shadows
		317685, -- Shelling
		{317675, "TANK"}, -- Erupting Magic
		317650, -- Activation: Darkness
		317653, -- Activation: Filth
		317657, -- Flash of Darkness
		317660, -- Flash of Filth
		317662, -- Overload: Darkness
		darkMarker,
		317666, -- Overload: Filth
		felMarker,
		317641, -- Enveloping Darkness
		317645, -- Spilling Filth
		"proximity",
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "ShockingBlow", 317673, 317743)
	self:Log("SPELL_CAST_START", "HowlingShadows", 317674)
	self:Log("SPELL_CAST_START", "ShellingCast", 317685)
	self:Log("SPELL_CAST_START", "FlashOfDarkness", 317657, 317741)
	self:Log("SPELL_CAST_START", "FlashOfFilth", 317660, 317742)
	self:Log("SPELL_AURA_APPLIED", "EnvelopingDarkness", 317641)
	self:Log("SPELL_AURA_APPLIED", "SpillingFilth", 317645)
	self:Log("SPELL_AURA_APPLIED", "EruptingMagic", 317681, 317683)
	self:Log("SPELL_AURA_APPLIED", "Overload", 317662, 317666)
	self:Log("SPELL_AURA_REMOVED", "OverloadRemoved", 317662, 317666)
	self:Log("SPELL_AURA_APPLIED", "Activation", 317650, 317653)
	self:Log("SPELL_SUMMON", "Shelling", 317685)
end

function mod:OnEngage()
	icons = {[317662] = 8, [317666] = 8}
	prevOverload = {}
	prevActivation = 0
	self:CDBar(317673, 34)
	self:CDBar(317674, 39)
	self:CDBar(317685, 60)
	self:CDBar(317675, 49)
	self:CDBar(317650, 20)
	self:CDBar(317657, 32)
	self:CDBar(317660, 32)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:ShockingBlow(args)
	self:Message(317673, "orange")
	if self:Melee() then
		self:PlaySound(317673, "runaway")
	end
	self:CDBar(317673, 35)
end

function mod:HowlingShadows(args)
	self:Message(317674, "red", CL.casting:format(args.spellName))
	self:PlaySound(317674, "alarm")
	self:CDBar(317674, 39)
end

function mod:ShellingCast(args)
	self:Message(317685, "orange")
	self:CastBar(317685, 2)
end

function mod:Shelling()
	self:Message(317685, "red")
	self:PlaySound(317685, "alarm")
	self:CDBar(317685, 83)
end

function mod:FlashOfDarkness(args)
	self:Message(317657, "yellow")
	self:CDBar(317660, 32) -- DBM: the other flash comes next
end

function mod:FlashOfFilth(args)
	self:Message(317660, "yellow")
	self:CDBar(317657, 32)
end

function mod:EnvelopingDarkness(args)
	if self:Me(args.destGUID) then
		self:PersonalMessage(317641)
		self:PlaySound(317641, "alert") -- DBM: keep moving
	end
end

function mod:SpillingFilth(args)
	if self:Me(args.destGUID) then
		self:PersonalMessage(317645)
		self:PlaySound(317645, "alert") -- DBM: stop moving
	end
end

function mod:EruptingMagic(args)
	self:TargetMessage(317675, "purple", args.destName)
	self:CDBar(317675, 50)
end

function mod:Overload(args)
	local id = args.spellId
	local marker = id == 317662 and darkMarker or felMarker
	if args.time - (prevOverload[id] or 0) > 0.5 then
		prevOverload[id] = args.time
		icons[id] = 8
	end
	if (icons[id] or 8) > 5 then
		self:CustomIcon(marker, args.destName, icons[id] or 8)
		icons[id] = (icons[id] or 8) - 1
	end
	self:TargetMessage(id, "orange", args.destName)
	self:TargetBar(id, 8, args.destName)
	if self:Me(args.destGUID) then
		self:PlaySound(id, "warning")
	else
		local unit = self:UnitTokenFromGUID(args.destGUID)
		if unit and self:UnitWithinRange(unit, 20) then
			self:PlaySound(id, "info") -- DBM: move to the target
		end
	end
end

function mod:OverloadRemoved(args)
	self:CustomIcon(args.spellId == 317662 and darkMarker or felMarker, args.destName)
end

function mod:Activation(args)
	if args.time - prevActivation > 3 then
		prevActivation = args.time
		self:Message(args.spellId, "cyan")
		self:CDBar(args.spellId == 317650 and 317653 or 317650, 20)
		self:OpenProximity("proximity", 8)
	end
end
