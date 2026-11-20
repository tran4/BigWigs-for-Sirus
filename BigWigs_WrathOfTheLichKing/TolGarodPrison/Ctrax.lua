--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-TolGarodePrison/Ctrax.lua), a custom Sirus raid boss, no journal id.
-- DBM has only Russian texts: the English defaults are the Russian texts. Not ported: the power frame, nameplate icons.

local mod, CL = BigWigs:NewBoss("Mindeater Ctrax", 10955)
if not mod then return end
mod:RegisterEnableMob(84002)
mod:SetEncounterID(84002) -- DBM Sirus custom encounter id

--------------------------------------------------------------------------------
-- Locals
--

local curseIcon = 7
local warnedSoon = false
local prevWell, prevCurse = 0, 0

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	-- DBM: no English texts
	bossName = "Поглотитель разума Ктракс",
	immersion = "Бегите в теневой колодец!",
})
mod.displayName = L.bossName

--------------------------------------------------------------------------------
-- Initialization
--

local curseMarker = mod:AddMarkerOption(true, "player", 7, 317594, 7, 6, 5, 4)
local markMarker = mod:AddMarkerOption(true, "player", 8, 317565, 8)
function mod:GetOptions()
	return {
		"stages",
		317579, -- Escaping Darkness
		317596, -- Region of Darkness
		{317571, "HEALER"}, -- Breath of Darkness
		317604, -- Immersion
		{317594, "SAY"}, -- Ancient Curse
		curseMarker,
		317595, -- Shadow Well
		317565, -- Mark of the Faceless
		markMarker,
		317567, -- Sphere of Darkness
		317601, -- stage 2
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "EscapingDarkness", 317579)
	self:Log("SPELL_CAST_START", "RegionOfDarkness", 317596)
	self:Log("SPELL_CAST_START", "BreathOfDarkness", 317571)
	self:Log("SPELL_CAST_START", "Immersion", 317604)
	self:Log("SPELL_AURA_APPLIED", "AncientCurse", 317593, 317594, 317737, 317738)
	self:Log("SPELL_AURA_APPLIED_DOSE", "AncientCurse", 317594)
	self:Log("SPELL_AURA_REMOVED", "AncientCurseRemoved", 317593, 317594, 317737, 317738)
	self:Log("SPELL_AURA_APPLIED", "ShadowWell", 317595)
	self:Log("SPELL_AURA_APPLIED_DOSE", "ShadowWell", 317595)
	self:Log("SPELL_AURA_APPLIED", "MarkOfTheFaceless", 317565)
	self:Log("SPELL_AURA_APPLIED_DOSE", "MarkOfTheFaceless", 317565)
	self:Log("SPELL_AURA_REMOVED", "MarkOfTheFacelessRemoved", 317565)
	self:Log("SPELL_SUMMON", "SphereOfDarkness", 317567)
	self:RegisterEvent("UNIT_HEALTH")
end

function mod:OnEngage()
	self:SetStage(1)
	curseIcon = 7
	warnedSoon = false
	prevWell, prevCurse = 0, 0
	self:CDBar(317579, 35)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:EscapingDarkness(args)
	self:Message(317579, "red", CL.casting:format(args.spellName))
	self:PlaySound(317579, "alarm")
	self:CDBar(317579, 35)
end

function mod:RegionOfDarkness()
	self:CDBar(317596, 35)
end

function mod:BreathOfDarkness(args)
	self:Message(317571, "orange")
	self:CDBar(317571, 24)
end

function mod:Immersion(args)
	self:Message(317604, "red", L.immersion)
	self:PlaySound(317604, "long")
	self:CastBar(317604, 5)
end

function mod:AncientCurse(args)
	if args.time - prevCurse > 0.1 then
		prevCurse = args.time
		curseIcon = 7
	end
	if curseIcon > 0 then
		self:CustomIcon(curseMarker, args.destName, curseIcon)
		curseIcon = curseIcon - 1
	end
	self:TargetMessage(317594, "orange", args.destName)
	self:CDBar(317594, 23)
	if self:Me(args.destGUID) then
		self:TargetBar(317594, 5, args.destName)
		self:PlaySound(317594, "runaway")
		self:Say(317594)
	end
end

function mod:AncientCurseRemoved(args)
	self:CustomIcon(curseMarker, args.destName)
end

function mod:ShadowWell(args)
	if self:Me(args.destGUID) and args.time - prevWell > 3 then
		prevWell = args.time
		self:PersonalMessage(317595, "underyou")
		self:PlaySound(317595, "underyou")
	end
end

function mod:MarkOfTheFaceless(args)
	self:TargetBar(317565, 10, args.destName)
	self:CustomIcon(markMarker, args.destName, 8)
	self:ScheduleTimer("CustomIcon", 10, markMarker, args.destName)
end

function mod:MarkOfTheFacelessRemoved(args)
	self:CustomIcon(markMarker, args.destName)
end

function mod:SphereOfDarkness()
	self:Message(317567, "yellow")
end

function mod:UNIT_HEALTH(_, unit)
	if self:Difficulty() ~= 6 or self:GetStage() ~= 1 or self:MobId(self:UnitGUID(unit)) ~= 84002 then return end
	local hp = self:GetHealth(unit)
	if not warnedSoon and hp <= 53 then
		warnedSoon = true
		self:Message("stages", "cyan", CL.soon:format(CL.stage:format(2)), false)
	elseif warnedSoon and hp <= 50 then
		self:SetStage(2)
		self:Message("stages", "cyan", CL.stage:format(2), false)
		self:PlaySound("stages", "long")
		self:StopBar(317579)
		self:CDBar(317601, 8)
		self:CDBar(317596, 15)
		self:CDBar(317594, 23)
	end
end
