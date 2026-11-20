--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Karazhan/MaidenOfVirtue.lua, heroic mode with custom spells), draft by tools/dbm2bw
-- Not ported: the shield health frame (305285).

local mod, CL = BigWigs:NewBoss("Maiden of Virtue", 532, 1555)
if not mod then return end
mod:RegisterEnableMob(16457)
mod:SetEncounterID(654)

--------------------------------------------------------------------------------
-- Locals
--

local groundCycle = true

--------------------------------------------------------------------------------
-- Initialization
--

local groundMarker = mod:AddMarkerOption(true, "player", 8, 305271, 8)
function mod:GetOptions()
	return {
		29511, -- Repentance (normal)
		305277, -- Universal Repentance (heroic)
		305271, -- Holy Ground (heroic)
		groundMarker,
		29522, -- Holy Fire
		"proximity",
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "UniversalRepentance", 305286)
	self:Log("SPELL_CAST_START", "Repentance", 29511)
	self:Log("SPELL_AURA_APPLIED", "HolyGround", 305271)
	self:Log("SPELL_AURA_APPLIED", "HolyFire", 29522)
	self:Log("SPELL_AURA_REMOVED", "HolyFireRemoved", 29522)
end

function mod:OnEngage()
	groundCycle = true
	if self:Difficulty() == 5 then -- 10 heroic
		self:CDBar(305277, 56.5)
		self:CDBar(305271, 20)
	else
		self:CDBar(29511, 45)
		self:DelayedMessage(29511, 40, "yellow", CL.soon:format(self:SpellName(29511)))
		self:OpenProximity("proximity", 10)
	end
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:UniversalRepentance(args)
	self:Message(305277, "red", CL.casting:format(args.spellName))
	self:PlaySound(305277, "long")
	self:CDBar(305277, 60)
	self:CDBar(305271, 30)
	groundCycle = true
end

function mod:Repentance(args)
	local repentance = self:SpellName(29511)
	self:CancelDelayedMessage(CL.soon:format(repentance))
	self:Message(29511, "orange")
	self:PlaySound(29511, "alarm")
	self:CastBar(29511, 12.6)
	-- 3.3.5: DBM starts the heroic 60s timer object here, the 33s normal one (pre-warning 5s before, at 28) is meant
	self:CDBar(29511, 33)
	self:DelayedMessage(29511, 28, "yellow", CL.soon:format(repentance))
end

function mod:HolyGround(args)
	if groundCycle then
		groundCycle = false
		self:CDBar(305271, 20)
	end
	if self:Me(args.destGUID) then
		self:PersonalMessage(305271)
		self:PlaySound(305271, "runaway")
	else
		self:TargetMessage(305271, "orange", args.destName)
	end
	self:CustomIcon(groundMarker, args.destName, 8)
	self:ScheduleTimer("CustomIcon", 5, groundMarker, args.destName)
end

function mod:HolyFire(args)
	self:TargetMessage(29522, "yellow", args.destName)
	self:TargetBar(29522, 12, args.destName)
end

function mod:HolyFireRemoved(args)
	self:StopBar(args.spellName, args.destName)
end
