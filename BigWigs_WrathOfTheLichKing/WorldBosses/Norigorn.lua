--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-WorldBoss/TolGarodeNorigorn/Norigorn.lua), a custom Sirus world boss
-- in Tol'Garod (map 946), no journal id. Loaded by targeting him (X-BigWigs-LoadOn-WorldBoss in the .toc).
-- DBM has only the Russian name: the English default is the Russian text. DBM starts no timers on the pull.
-- DBM opens a range frame of 10 yards on the pull behind an option it never declares: it is the proximity option here.

local mod, CL = BigWigs:NewBoss("Norigorn", -946)
if not mod then return end
mod:RegisterEnableMob(70010)
mod:SetWorldModule(true)
mod:SetEncounterID(70010) -- DBM Sirus custom encounter id

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	bossName = "Норигорн", -- DBM: no English text
})
mod.displayName = L.bossName

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		317274, -- nets
		317267, -- spires
		{317273, "TANK_HEALER"}, -- stacks (DBM: healers and tanks only)
		317624, -- Crushing Earthquake
		317266, -- stage 2: earth
		317278, -- stage 2: creatures
		317279, -- stage 2: disruption
		317275, -- intermission: Acceptance of Nature
		"proximity",
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "Nets", 317274)
	self:Log("SPELL_CAST_START", "CrushingEarthquake", 317624)
	self:Log("SPELL_CAST_START", "AcceptanceOfNature", 317275)
	self:Log("SPELL_CAST_SUCCESS", "SwitchAbility", 317266, 317278, 317279)
	self:Log("SPELL_AURA_APPLIED", "CrushingEarthquakeApplied", 317624)
	self:Log("SPELL_AURA_APPLIED", "Stacks", 317273)
	self:Log("SPELL_SUMMON", "Spires", 317267)
end

function mod:OnEngage()
	self:OpenProximity("proximity", 10)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:Nets(args)
	self:Message(317274, "yellow", CL.casting:format(args.spellName))
	self:CastBar(317274, 2)
	self:CDBar(317274, 10)
end

function mod:CrushingEarthquake(args)
	self:Message(317624, "orange", CL.casting:format(args.spellName))
	self:CDBar(317624, 100)
end

function mod:CrushingEarthquakeApplied(args)
	if self:Me(args.destGUID) then
		self:PersonalMessage(317624)
		self:PlaySound(317624, "alarm") -- DBM: move
	end
end

local switchIds = {317266, 317278, 317279}

function mod:AcceptanceOfNature(args)
	self:Message(317275, "cyan")
	self:CastBar(317275, 62)
	for i = 1, #switchIds do
		self:StopBar(switchIds[i])
		self:CancelDelayedMessage(CL.soon:format(self:SpellName(switchIds[i])))
	end
end

function mod:SwitchAbility(args)
	self:Message(args.spellId, "red")
	if not self:Healer() then
		self:PlaySound(args.spellId, "alert") -- DBM: switch (not for healers)
	end
	self:CDBar(args.spellId, 90)
	self:DelayedMessage(args.spellId, 55, "yellow", CL.soon:format(args.spellName))
end

function mod:Stacks(args)
	self:TargetBar(317273, 30, args.destName)
end

function mod:Spires(args)
	self:CDBar(317267, 60)
end
