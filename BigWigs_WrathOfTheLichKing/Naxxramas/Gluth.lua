--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Naxx/ConstructQuarter/Gluth.lua), draft by tools/dbm2bw

local mod, CL = BigWigs:NewBoss("Gluth", 533, 1612)
if not mod then return end
mod:RegisterEnableMob(15932)
mod:SetEncounterID(1108)

--------------------------------------------------------------------------------
-- Locals
--

local myRealm = false -- 3.3.5: DBM Sirus has other timers on the x1 realm
local prevDecimate = 0

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"berserk",
		29685, -- Terrifying Roar
		28371, -- Enrage
		28374, -- Decimate
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_SUCCESS", "TerrifyingRoar", 29685)
	self:Log("SPELL_AURA_APPLIED", "Enrage", 28371)
	self:Log("SPELL_AURA_REMOVED", "EnrageRemoved", 28371)
	self:Log("SPELL_DAMAGE", "Decimate", 28375, 54426)
end

function mod:OnEngage()
	myRealm = BigWigsLoader.Compat.GetRealmNumber() == 1
	prevDecimate = 0
	self:CDBar(29685, 19.4)
	self:Berserk(myRealm and 600 or 480)
	self:CDBar(28374, myRealm and 90 or 104)
	self:DelayedMessage(28374, myRealm and 80 or 100, "yellow", CL.soon:format(self:SpellName(28374)))
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:TerrifyingRoar(args)
	self:Message(29685, "yellow")
	self:CDBar(29685, 19.4)
end

function mod:Enrage(args)
	self:TargetMessage(28371, "orange", args.destName)
	if self:Dispeller("enrage", true) then
		self:PlaySound(28371, "alert")
	end
	self:Bar(28371, 8)
end

function mod:EnrageRemoved(args)
	self:StopBar(28371)
end

function mod:Decimate(args)
	if args.time - prevDecimate > 20 then
		prevDecimate = args.time
		self:Message(28374, "red")
		self:PlaySound(28374, "alarm")
		self:CDBar(28374, myRealm and 90 or 104)
		self:DelayedMessage(28374, 96, "yellow", CL.soon:format(self:SpellName(28374)))
	end
end
