--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Coliseum/Champions.lua), draft by tools/dbm2bw

local mod, CL = BigWigs:NewBoss("Faction Champions", 649, 1621)
if not mod then return end
mod:RegisterEnableMob(
	-- Horde
	34458, 34451, 34459, 34448, 34449, 34445, 34456, 34447, 34441, 34454, 34444, 34455, 34450, 34453,
	-- Alliance
	34461, 34460, 34469, 34467, 34468, 34471, 34465, 34466, 34473, 34472, 34470, 34463, 34474, 34475
)
mod:SetEncounterID(637)
mod:SetWinMobs() -- 3.3.5: won by the victory yell (DBM RegisterKill)

--------------------------------------------------------------------------------
-- Locals
--

local prevHellfire = 0

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	alliance_victory_trigger = "GLORY TO THE ALLIANCE!",
	horde_victory_trigger = "That was just a taste of what the future brings. FOR THE HORDE!",
})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		-- Death Knight
		66017, -- Death Grip
		66020, -- Chains of Ice
		-- Paladin
		66115, -- Hand of Freedom
		{68758, "DISPEL"}, -- Hand of Freedom (dispel)
		66009, -- Hand of Protection
		66613, -- Hammer of Justice
		66008, -- Repentance
		66010, -- Divine Shield
		{66011, "DISPEL"}, -- Avenging Wrath
		-- Mage
		65802, -- Ice Block
		{65801, "OFF"}, -- Polymorph
		65793, -- Blink
		65790, -- Counterspell
		-- Warlock
		65816, -- Hellfire
		65809, -- Fear
		65820, -- Death Coil
		-- Warrior
		65947, -- Bladestorm
		65927, -- Charge
		65932, -- Retaliation
		65931, -- Intimidating Shout
		-- Shaman
		{65983, "DISPEL"}, -- Heroism
		{65980, "DISPEL"}, -- Bloodlust
		{66063, "DISPEL"}, -- Earth Shield
		66054, -- Hex
		-- Priest
		65544, -- Dispersion
		65543, -- Psychic Scream
		65545, -- Psychic Horror
		65542, -- Silence
		-- Druid
		65860, -- Barkskin
		66086, -- Tranquility
		65857, -- Entangling Roots
		{65859, "OFF"}, -- Cyclone
		-- Rogue
		66178, -- Shadowstep
		65960, -- Blind
		65961, -- Cloak of Shadows
		-- Hunter
		65871, -- Deterrence
		66207, -- Wing Clip
		65878, -- Wyvern Sting
		65880, -- Frost Trap
		65869, -- Disengage
	}, {
		[66017] = LOCALIZED_CLASS_NAMES_MALE.DEATHKNIGHT,
		[66115] = LOCALIZED_CLASS_NAMES_MALE.PALADIN,
		[65802] = LOCALIZED_CLASS_NAMES_MALE.MAGE,
		[65816] = LOCALIZED_CLASS_NAMES_MALE.WARLOCK,
		[65947] = LOCALIZED_CLASS_NAMES_MALE.WARRIOR,
		[65983] = LOCALIZED_CLASS_NAMES_MALE.SHAMAN,
		[65544] = LOCALIZED_CLASS_NAMES_MALE.PRIEST,
		[65860] = LOCALIZED_CLASS_NAMES_MALE.DRUID,
		[66178] = LOCALIZED_CLASS_NAMES_MALE.ROGUE,
		[65871] = LOCALIZED_CLASS_NAMES_MALE.HUNTER,
	}
end

function mod:OnBossEnable()
	-- Death Knight
	self:Log("SPELL_CAST_SUCCESS", "DeathGrip", 66017, 68753, 68754, 68755)
	self:Log("SPELL_CAST_SUCCESS", "ChainsOfIce", 66020)
	-- Paladin
	self:Log("SPELL_CAST_SUCCESS", "HandOfFreedom", 68758, 68757, 68756, 66115)
	self:Log("SPELL_CAST_SUCCESS", "HandOfProtection", 66009)
	self:Log("SPELL_CAST_SUCCESS", "Repentance", 66008)
	self:Log("SPELL_CAST_SUCCESS", "HammerOfJustice", 66613, 66007)
	self:Log("SPELL_CAST_SUCCESS", "AvengingWrath", 66011)
	self:Log("SPELL_AURA_APPLIED", "DivineShield", 66010)
	-- Mage
	self:Log("SPELL_AURA_APPLIED", "IceBlock", 65802)
	self:Log("SPELL_AURA_APPLIED", "Polymorph", 65801)
	self:Log("SPELL_CAST_SUCCESS", "Blink", 65793)
	self:Log("SPELL_CAST_SUCCESS", "Counterspell", 65790)
	-- Warlock
	self:Log("SPELL_CAST_SUCCESS", "Hellfire", 65816, 68145, 68146, 68147)
	self:Log("SPELL_DAMAGE", "HellfireDamage", 65817, 68142, 68143, 68144)
	self:Log("SPELL_MISSED", "HellfireDamage", 65817, 68142, 68143, 68144)
	self:Log("SPELL_AURA_APPLIED", "Fear", 65809)
	self:Log("SPELL_CAST_SUCCESS", "DeathCoil", 65820, 68141, 68139, 68140)
	-- Warrior
	self:Log("SPELL_CAST_SUCCESS", "Bladestorm", 65947)
	self:Log("SPELL_AURA_APPLIED", "Charge", 65927, 65929)
	self:Log("SPELL_CAST_SUCCESS", "Retaliation", 65932)
	self:Log("SPELL_CAST_SUCCESS", "IntimidatingShout", 65931)
	-- Shaman
	self:Log("SPELL_CAST_SUCCESS", "Heroism", 65983)
	self:Log("SPELL_CAST_SUCCESS", "Bloodlust", 65980)
	self:Log("SPELL_CAST_SUCCESS", "EarthShield", 66063)
	self:Log("SPELL_AURA_APPLIED", "Hex", 66054)
	-- Priest
	self:Log("SPELL_CAST_SUCCESS", "Dispersion", 65544)
	self:Log("SPELL_CAST_SUCCESS", "PsychicScream", 65543)
	self:Log("SPELL_CAST_SUCCESS", "PsychicHorror", 65545)
	self:Log("SPELL_CAST_SUCCESS", "Silence", 65542)
	-- Druid
	self:Log("SPELL_CAST_SUCCESS", "Barkskin", 65860)
	self:Log("SPELL_CAST_SUCCESS", "Tranquility", 66086, 67974, 67975, 67976)
	self:Log("SPELL_AURA_APPLIED", "EntanglingRoots", 65857)
	self:Log("SPELL_AURA_APPLIED", "Cyclone", 65859)
	-- Rogue
	self:Log("SPELL_CAST_SUCCESS", "Shadowstep", 66178, 68759, 68760, 68761)
	self:Log("SPELL_CAST_SUCCESS", "Blind", 65960)
	self:Log("SPELL_CAST_SUCCESS", "CloakOfShadows", 65961)
	-- Hunter
	self:Log("SPELL_AURA_APPLIED", "Deterrence", 65871)
	self:Log("SPELL_CAST_SUCCESS", "WingClip", 66207)
	self:Log("SPELL_AURA_APPLIED", "WyvernSting", 65878, 65877)
	self:Log("SPELL_CAST_SUCCESS", "FrostTrap", 65880)
	self:Log("SPELL_CAST_SUCCESS", "Disengage", 65869)

	self:Death("RogueDeath", 34472, 34454)
	self:Death("DeathKnightDeath", 34458, 34461)
	self:Death("WarriorDeath", 34475, 34453)
	self:Death("HunterDeath", 34467, 34448)
	self:Death("MageDeath", 34468, 34449)
	self:Death("HolyPaladinDeath", 34465, 34445)
	self:Death("RetributionPaladinDeath", 34471, 34456)
	self:Death("PriestDeath", 34466, 34447, 34473, 34441)
	self:Death("AllianceShamanDeath", 34463, 34470)
	self:Death("HordeShamanDeath", 34455, 34444)
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if msg:find(L.alliance_victory_trigger, nil, true) or msg:find(L.horde_victory_trigger, nil, true) then
		self:Win() -- DBM RegisterKill("yell")
	end
end

-- Death Knight

function mod:DeathGrip(args)
	if self:Player(args.destFlags) then
		self:TargetMessage(66017, "yellow", args.destName)
		self:CDBar(66017, 35)
	end
end

function mod:ChainsOfIce(args)
	if self:Player(args.destFlags) then
		self:TargetMessage(66020, "yellow", args.destName)
	end
end

function mod:DeathKnightDeath()
	self:StopBar(66017)
end

-- Paladin

function mod:HandOfFreedom(args)
	if not self:Player(args.destFlags) then
		self:TargetMessage(66115, "yellow", args.destName)
		if self:Dispeller("magic", true, 68758) then
			self:TargetMessage(68758, "orange", args.destName)
			self:PlaySound(68758, "alarm")
		end
	end
end

function mod:HandOfProtection(args)
	self:TargetMessage(66009, "orange", args.destName)
	self:PlaySound(66009, "alarm")
	self:CDBar(66009, 300)
end

function mod:Repentance(args)
	self:TargetMessage(66008, "cyan", args.destName)
	self:CDBar(66008, 60)
end

function mod:HammerOfJustice(args)
	self:TargetMessage(66613, "cyan", args.destName)
	self:CDBar(66613, 40)
end

function mod:AvengingWrath(args)
	self:Message(66011, "orange")
	if self:Dispeller("magic", true, 66011) then
		self:PlaySound(66011, "alarm")
	end
end

function mod:DivineShield(args)
	self:TargetMessage(66010, "orange", args.destName)
	self:PlaySound(66010, "alarm")
end

function mod:HolyPaladinDeath()
	self:StopBar(66613)
	self:StopBar(66009)
end

function mod:RetributionPaladinDeath()
	self:StopBar(66613)
	self:StopBar(66008)
	self:StopBar(66009)
end

-- Mage

function mod:IceBlock(args)
	self:TargetMessage(65802, "orange", args.sourceName)
	self:PlaySound(65802, "alarm")
end

function mod:Polymorph(args)
	if self:Player(args.destFlags) then
		self:TargetMessage(65801, "cyan", args.destName)
	end
end

function mod:Blink(args)
	self:Message(65793, "orange")
	self:CDBar(65793, 15)
end

function mod:Counterspell(args)
	self:TargetMessage(65790, "cyan", args.destName)
end

function mod:MageDeath()
	self:StopBar(65793)
end

-- Warlock

function mod:Hellfire(args)
	self:Message(65816, "red")
end

function mod:HellfireDamage(args)
	if self:Me(args.destGUID) and args.time - prevHellfire > 2.5 then
		prevHellfire = args.time
		self:PersonalMessage(65816, "underyou")
		self:PlaySound(65816, "underyou")
	end
end

function mod:Fear(args)
	self:TargetMessage(65809, "cyan", args.destName)
end

function mod:DeathCoil(args)
	self:TargetMessage(65820, "cyan", args.destName)
end

-- Warrior

function mod:Bladestorm(args)
	self:Message(65947, "red")
	self:PlaySound(65947, "alarm")
	self:CastBar(65947, 8)
	self:CDBar(65947, 90)
	self:DelayedMessage(65947, 85, "orange", CL.soon:format(args.spellName))
end

function mod:Charge(args)
	self:TargetMessage(65927, "yellow", args.destName)
end

function mod:Retaliation(args)
	self:Message(65932, "orange")
end

function mod:IntimidatingShout(args)
	self:Message(65931, "cyan")
end

function mod:WarriorDeath()
	self:StopBar(65947)
	self:CancelDelayedMessage(CL.soon:format(self:SpellName(65947)))
end

-- Shaman

function mod:Heroism(args)
	self:Message(65983, "orange")
	if self:Dispeller("magic", true, 65983) then
		self:PlaySound(65983, "alarm")
	end
	self:CDBar(65983, 300)
end

function mod:Bloodlust(args)
	self:Message(65980, "orange")
	if self:Dispeller("magic", true, 65980) then
		self:PlaySound(65980, "alarm")
	end
	self:CDBar(65980, 300)
end

function mod:EarthShield(args)
	self:TargetMessage(66063, "orange", args.destName)
end

function mod:Hex(args)
	self:TargetMessage(66054, "cyan", args.destName)
end

function mod:AllianceShamanDeath()
	self:StopBar(65983)
end

function mod:HordeShamanDeath()
	self:StopBar(65980)
end

-- Priest

function mod:Dispersion(args)
	self:Message(65544, "orange")
end

function mod:PsychicScream(args)
	self:Message(65543, "cyan")
end

function mod:PsychicHorror(args)
	self:TargetMessage(65545, "cyan", args.destName)
end

function mod:Silence(args)
	self:TargetMessage(65542, "cyan", args.destName)
	self:CDBar(65542, 45)
end

function mod:PriestDeath()
	self:StopBar(65542)
end

-- Druid

function mod:Barkskin(args)
	self:Message(65860, "orange")
end

function mod:Tranquility(args)
	self:Message(66086, "red", CL.casting:format(args.spellName))
	if self:Interrupter(args.sourceGUID) then
		self:PlaySound(66086, "alert")
	end
end

function mod:EntanglingRoots(args)
	self:TargetMessage(65857, "cyan", args.destName)
end

function mod:Cyclone(args)
	if self:Player(args.destFlags) then
		self:TargetMessage(65859, "cyan", args.destName)
	end
end

-- Rogue

function mod:Shadowstep(args)
	self:Message(66178, "yellow")
	self:CDBar(66178, self:Difficulty() == 6 and 20 or 30)
end

function mod:Blind(args)
	self:TargetMessage(65960, "cyan", args.destName)
	self:CDBar(65960, 120)
end

function mod:CloakOfShadows(args)
	self:Message(65961, "orange")
end

function mod:RogueDeath()
	self:StopBar(66178)
	self:StopBar(65960)
end

-- Hunter

function mod:Deterrence(args)
	self:Message(65871, "orange")
end

function mod:WingClip(args)
	self:TargetMessage(66207, "cyan", args.destName)
end

function mod:WyvernSting(args)
	self:TargetMessage(65878, "cyan", args.destName)
end

function mod:FrostTrap(args)
	self:Message(65880, "orange")
	self:CDBar(65880, 30)
end

function mod:Disengage(args)
	self:Message(65869, "orange")
	self:CDBar(65869, 30)
end

function mod:HunterDeath()
	self:StopBar(65880)
	self:StopBar(65869)
end
