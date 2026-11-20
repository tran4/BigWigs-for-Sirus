--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-TolGarodePrison/Gogonash.lua), a custom Sirus raid boss, no journal id.
-- DBM has only the Russian name: the English default is the Russian text. DBM starts no timers on the pull
-- (its OnCombatStart is commented out). Not ported: the health frame, announcing the targets to the chat.

local mod, CL = BigWigs:NewBoss("Gogonash", 10955)
if not mod then return end
mod:RegisterEnableMob(84000)
mod:SetEncounterID(84000) -- DBM Sirus custom encounter id

--------------------------------------------------------------------------------
-- Locals
--

local markIcon = 8
local markTargets = {}
local prevMark = 0

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	bossName = "Гогонаш", -- DBM: no English text
})
mod.displayName = L.bossName

--------------------------------------------------------------------------------
-- Initialization
--

local markMarker = mod:AddMarkerOption(true, "player", 8, 317544, 8, 7)
function mod:GetOptions()
	return {
		317549, -- Lightning of Filth
		317548, -- Primal Horror
		317541, -- Crushing Blow
		{317543, "TANK"}, -- Striking Blow
		{317540, "DISPEL"}, -- Endless Flame of Filth
		{317544, "SAY"}, -- Mark of Filth
		markMarker,
		{317542, "TANK"}, -- Seared Flesh
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "LightningOfFilth", 317549)
	self:Log("SPELL_CAST_START", "PrimalHorror", 317548)
	self:Log("SPELL_CAST_START", "CrushingBlow", 317541)
	self:Log("SPELL_CAST_SUCCESS", "StrikingBlow", 317543)
	self:Log("SPELL_CAST_SUCCESS", "EndlessFlame", 317540)
	self:Log("SPELL_AURA_APPLIED", "MarkOfFilth", 317544)
	self:Log("SPELL_AURA_APPLIED_DOSE", "MarkOfFilth", 317544)
	self:Log("SPELL_AURA_REMOVED", "MarkOfFilthRemoved", 317544)
	self:Log("SPELL_AURA_APPLIED_DOSE", "SearedFlesh", 317542)
end

function mod:OnEngage()
	markIcon = 8
	markTargets = {}
	prevMark = 0
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:LightningOfFilth(args)
	self:Message(317549, "orange")
	self:CastBar(317549, 1)
	self:CDBar(317549, 15)
end

function mod:PrimalHorror(args)
	self:Message(317548, "red")
	self:PlaySound(317548, "warning") -- DBM: look away
	self:CastBar(317548, 1.84)
	self:CDBar(317548, 30)
end

function mod:CrushingBlow(args)
	self:CastBar(317541, 2.5)
	self:CDBar(317541, 30)
end

function mod:StrikingBlow()
	self:CDBar(317543, 10)
end

function mod:EndlessFlame(args)
	if self:Dispeller("magic", true, 317540) then
		self:Message(317540, "orange", CL.onboss:format(args.spellName))
		self:PlaySound(317540, "alert")
	end
	self:CDBar(317540, 18.5)
end

function mod:MarkOfFilth(args)
	if args.time - prevMark > 0.5 then
		prevMark = args.time
		markTargets = {}
		markIcon = 8
	end
	markTargets[#markTargets + 1] = args.destName
	self:TargetsMessage(317544, "red", markTargets, nil, nil, nil, 0.1)
	if markIcon > 0 then
		self:CustomIcon(markMarker, args.destName, markIcon)
		markIcon = markIcon - 1
	end
	self:Bar(317544, 5, CL.other:format(args.spellName, CL.active))
	self:CDBar(317544, 19)
	if self:Me(args.destGUID) then
		self:PlaySound(317544, "runaway")
		self:Say(317544)
	end
end

function mod:MarkOfFilthRemoved(args)
	self:CustomIcon(markMarker, args.destName)
end

function mod:SearedFlesh(args)
	self:StackMessage(317542, "purple", args.destName, args.amount or 1, 1)
	self:CDBar(317542, 35)
end
