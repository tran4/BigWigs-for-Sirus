--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Serpentshrine/Fathomlord.lua, heroic mode with custom spells), draft by tools/dbm2bw
-- The Fathom-Guards (DBM health frame ids) are enable mobs, only Karathress wins.
-- Not ported: the health frame, announcing the targets to the raid chat.

local mod, CL = BigWigs:NewBoss("Fathom-Lord Karathress", 548, 1570)
if not mod then return end
mod:RegisterEnableMob(21214, 21966, 21965, 21964) -- Karathress, Sharkkis, Tidalvess, Caribdis
mod:SetEncounterID(626)
mod:SetWinMobs(21214)

--------------------------------------------------------------------------------
-- Locals
--

local guardsKilled = 0
local prevSurge = 0
local linkTargets = {}

--------------------------------------------------------------------------------
-- Initialization
--

local linkMarker = mod:AddMarkerOption(true, "player", 7, 309262, 7, 6, 5)
local arrowMarker = mod:AddMarkerOption(false, "player", 8, 309253, 8)
function mod:GetOptions()
	return {
		"stages",
		"berserk",
		38445, -- Blast Nova
		38236, -- Spitfire Totem
		38330, -- Healing Wave
		29436, -- Leeching Throw
		38306, -- Greater Poison Cleansing Totem
		38373, -- The Beast Within
		38358, -- Tidal Surge
		38441, -- Cataclysmic Bolt
		-- heroic
		{309253, "SAY"}, -- Arrow
		arrowMarker,
		309256, -- Heal
		309289, -- Earthquake
		309258, -- Eye
		309262, -- Flame Link
		linkMarker,
		309292, -- Gliding Onslaught
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "BlastNova", 38445)
	self:Log("SPELL_CAST_START", "HealingWave", 38330)
	self:Log("SPELL_CAST_START", "LeechingThrow", 29436)
	self:Log("SPELL_CAST_SUCCESS", "SpitfireTotem", 38236)
	self:Log("SPELL_CAST_SUCCESS", "CleansingTotem", 38306)
	self:Log("SPELL_CAST_SUCCESS", "BeastWithin", 38373)
	self:Log("SPELL_AURA_APPLIED", "BeastWithinApplied", 38373)
	self:Log("SPELL_CAST_SUCCESS", "TidalSurge", 38358)
	self:Log("SPELL_DAMAGE", "TidalSurgeDamage", 38358)
	self:Log("SPELL_CAST_SUCCESS", "CataclysmicBolt", 38441)
	self:Log("SPELL_CAST_START", "Arrow", 309253)
	self:Log("SPELL_CAST_START", "Heal", 309256)
	self:Log("SPELL_CAST_START", "Earthquake", 309289)
	self:Log("SPELL_CAST_SUCCESS", "Eye", 309258)
	self:Log("SPELL_CAST_SUCCESS", "FlameLink", 309262)
	self:Log("SPELL_AURA_APPLIED", "FlameLinkApplied", 309262)
	self:Log("SPELL_AURA_REMOVED", "FlameLinkRemoved", 309262)
	self:Log("SPELL_AURA_APPLIED", "GlidingOnslaught", 309292)
	self:Log("SPELL_AURA_REMOVED", "GlidingOnslaughtRemoved", 309292)
	self:Log("SPELL_AURA_REMOVED", "BarrierRemoved", 309252)
	self:Death("GuardDeath", 21966, 21965, 21964)
end

function mod:OnEngage()
	self:SetStage(1)
	guardsKilled, prevSurge = 0, 0
	linkTargets = {}
	self:Berserk(600)
	if self:Difficulty() == 6 then -- 25 heroic
		self:CDBar(309258, 16)
		self:CDBar(309262, 25)
		self:CDBar(309256, 29)
		self:CDBar(309253, 43)
	else
		self:CDBar(38373, 6.6)
		self:CDBar(38445, 26)
		self:DelayedMessage(38445, 23, "yellow", CL.soon:format(self:SpellName(38445))) -- DBM: warnNovaSoon:Show(23)
		self:CDBar(38236, 21.8)
		self:CDBar(38306, 6.7)
	end
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:BlastNova(args)
	self:Message(38445, "red")
	self:PlaySound(38445, "long")
	self:CDBar(38445, 26)
	self:DelayedMessage(38445, 23, "yellow", CL.soon:format(args.spellName))
end

function mod:HealingWave(args)
	self:Message(38330, "orange", CL.casting:format(args.spellName))
	if self:Interrupter(args.sourceGUID) then
		self:PlaySound(38330, "alert")
	end
	self:CDBar(38330, 16)
end

function mod:LeechingThrow(args)
	self:Message(29436, "yellow", CL.casting:format(args.spellName))
	self:CDBar(29436, 15)
end

function mod:SpitfireTotem(args)
	self:Message(38236, "orange")
	self:CDBar(38236, 30)
end

function mod:CleansingTotem()
	self:CDBar(38306, 15)
end

function mod:BeastWithin(args)
	self:Message(38373, "yellow", CL.casting:format(args.spellName))
	self:CDBar(38373, 30)
end

function mod:BeastWithinApplied(args)
	if self:MobId(args.destGUID) == 21214 then
		self:Message(38373, "yellow")
		self:CDBar(38373, 48)
	end
end

function mod:TidalSurge(args)
	self:Message(38358, "orange", CL.casting:format(args.spellName))
	self:CDBar(38358, 15)
end

function mod:TidalSurgeDamage(args)
	if guardsKilled == 3 and args.time - prevSurge > 4 then
		prevSurge = args.time
		self:Message(38358, "orange", CL.casting:format(args.spellName))
		self:CDBar(38358, 22)
	end
end

function mod:CataclysmicBolt(args)
	if self:GetStage() == 2 then
		self:Message(38441, "orange", CL.casting:format(args.spellName))
		self:CDBar(38441, 10)
	end
end

function mod:GuardDeath()
	if self:Difficulty() == 4 then -- 25 normal
		guardsKilled = guardsKilled + 1
		if guardsKilled == 3 then
			self:SetStage(2)
		end
	end
end

do
	local function arrowTarget(self, name, guid)
		self:TargetMessage(309253, "red", name)
		self:CustomIcon(arrowMarker, name, 8)
		self:ScheduleTimer("CustomIcon", 6, arrowMarker, name)
		if self:Me(guid) then
			self:PlaySound(309253, "warning")
			self:Say(309253)
		end
	end
	function mod:Arrow(args)
		self:GetUnitTarget(arrowTarget, 1.5, args.sourceGUID) -- DBM: the boss target after 1.5s
		self:CDBar(309253, 43)
		self:CastBar(309253, 6)
	end
end

function mod:Heal(args)
	self:Message(309256, "orange", CL.casting:format(args.spellName))
	if self:Interrupter(args.sourceGUID) then
		self:PlaySound(309256, "alert")
	end
	self:CDBar(309256, 29)
end

function mod:Earthquake(args)
	self:Message(309289, "red")
	self:PlaySound(309289, "runaway")
	self:CastBar(309289, 5)
end

function mod:Eye(args)
	if self:Melee() then self:Message(309258, "orange") end -- DBM: Melee
	self:CDBar(309258, 16)
end

function mod:FlameLink()
	self:CDBar(309262, 25)
end

function mod:FlameLinkApplied(args)
	linkTargets[#linkTargets + 1] = args.destName
	self:CustomIcon(linkMarker, args.destName, 8 - #linkTargets) -- 7, 6, 5
	if self:Me(args.destGUID) then
		self:PersonalMessage(309262)
		self:PlaySound(309262, "runaway")
	end
	if #linkTargets >= 3 then
		self:TargetsMessage(309262, "yellow", linkTargets, #linkTargets)
		linkTargets = {}
	end
end

function mod:FlameLinkRemoved(args)
	self:CustomIcon(linkMarker, args.destName)
end

function mod:GlidingOnslaught(args)
	self:CastBar(309292, 60)
end

function mod:GlidingOnslaughtRemoved()
	self:CDBar(309289, 90)
end

function mod:BarrierRemoved()
	self:SetStage(2)
	self:Message("stages", "cyan", CL.stage:format(2), false)
	self:PlaySound("stages", "long")
	self:CDBar(309289, 95)
	self:StopBar(309256)
	self:StopBar(309258)
	self:Berserk(360)
end
