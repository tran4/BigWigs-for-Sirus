--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Karazhan/ShadeOfAran.lua, heroic mode with custom spells), draft by tools/dbm2bw
-- Not ported: the water elemental icons and the heroic special timer after the third Familiar death (DBM finds the
-- Familiar by its localized name only, there is no npc id).

local mod, CL = BigWigs:NewBoss("Shade of Aran", 532, 1559)
if not mod then return end
mod:RegisterEnableMob(16524)
mod:SetEncounterID(658)

--------------------------------------------------------------------------------
-- Locals
--

local prevElementals, prevBlizzard, prevWreath = 0, 0, 0

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	special = "Special ability CD",
	special_desc = "Show timer for special ability cooldown",
	special_icon = "inv_enchant_essencemagiclarge",
	dont_move = "Flame Wreath - Do not move!",
})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"berserk",
		"special",
		30004, -- Flame Wreath
		29973, -- Arcane Explosion
		29969, -- Blizzard
		37053, -- Summon Water Elementals
		29991, -- Chains of Ice
		305338, -- heroic: do not move
		305329, -- heroic: Winter
		305326, -- heroic: Freeze (cast)
		305328, -- heroic: Freeze
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "FlameWreath", 30004)
	self:Log("SPELL_CAST_START", "ArcaneExplosion", 29973)
	self:Log("SPELL_CAST_START", "Blizzard", 29969) -- 3.3.5: DBM has the handler, but does not register the spell
	self:Log("SPELL_CAST_START", "DontMove", 305338)
	self:Log("SPELL_CAST_START", "Winter", 305329)
	self:Log("SPELL_CAST_START", "FreezeCast", 305326)
	self:Log("SPELL_AURA_APPLIED", "ChainsOfIce", 29991)
	self:Log("SPELL_AURA_REMOVED", "ChainsOfIceRemoved", 29991)
	self:Log("SPELL_AURA_APPLIED", "FlameWreathApplied", 29946)
	self:Log("SPELL_AURA_APPLIED", "Freeze", 305328)
	self:Log("SPELL_AURA_REMOVED", "FreezeRemoved", 305328)
	self:Log("SPELL_SUMMON", "SummonElementals", 29962, 37051, 37052, 37053)
	self:Log("SPELL_PERIODIC_DAMAGE", "BlizzardDamage", 29951) -- 3.3.5: DBM has the handler, but does not register the event
end

function mod:OnEngage()
	prevElementals, prevBlizzard, prevWreath = 0, 0, 0
	if self:Difficulty() == 5 then -- 10 heroic
		self:Bar("special", 43, L.special, L.special_icon)
	else
		self:Berserk(900)
	end
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:FlameWreath(args)
	self:Message(30004, "red", CL.casting:format(args.spellName))
	self:CastBar(30004, 5)
	self:Bar("special", 30, L.special, L.special_icon)
end

function mod:FlameWreathApplied(args)
	if args.time - prevWreath > 2 then -- one bar for all targets
		prevWreath = args.time
		self:Bar(30004, 20.5, CL.other:format(self:SpellName(30004), CL.active))
	end
	if self:Me(args.destGUID) then
		self:Message(30004, "blue", L.dont_move)
		self:PlaySound(30004, "warning")
	end
end

function mod:ArcaneExplosion(args)
	self:Message(29973, "red", CL.casting:format(args.spellName))
	self:PlaySound(29973, "runaway")
	self:CastBar(29973, 10)
	self:Bar("special", 30, L.special, L.special_icon)
end

function mod:Blizzard(args)
	self:Message(29969, "orange")
	self:CastBar(29969, 3.7)
	self:ScheduleTimer("Bar", 3.7, 29969, 40, CL.other:format(args.spellName, CL.active))
	self:Bar("special", 30, L.special, L.special_icon)
end

function mod:BlizzardDamage(args)
	if self:Me(args.destGUID) and args.time - prevBlizzard > 2 then
		prevBlizzard = args.time
		self:PersonalMessage(29969, "underyou")
		self:PlaySound(29969, "underyou")
	end
end

function mod:DontMove(args)
	self:Message(305338, "red", L.dont_move)
	self:PlaySound(305338, "warning")
	self:Bar("special", 43, L.special, L.special_icon)
end

function mod:Winter(args)
	self:Message(305329, "red")
	self:PlaySound(305329, "runaway")
	self:Bar("special", 43, L.special, L.special_icon)
end

function mod:FreezeCast(args)
	if self:Me(args.destGUID) then
		self:PersonalMessage(305326)
		self:PlaySound(305326, "alarm")
	end
end

function mod:Freeze(args)
	self:TargetMessage(305328, "orange", args.destName)
	self:TargetBar(305328, 30, args.destName)
end

function mod:FreezeRemoved(args)
	self:StopBar(args.spellName, args.destName)
end

function mod:ChainsOfIce(args)
	self:TargetMessage(29991, "yellow", args.destName)
	self:TargetBar(29991, 10, args.destName)
end

function mod:ChainsOfIceRemoved(args)
	self:StopBar(args.spellName, args.destName)
end

function mod:SummonElementals(args)
	if args.time - prevElementals > 5 then
		prevElementals = args.time
		self:Message(37053, "cyan")
		self:Bar(37053, 90, CL.other:format(self:SpellName(37053), CL.active))
	end
end
