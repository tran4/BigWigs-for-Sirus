--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Ulduar/Ignis.lua), draft by tools/dbm2bw

local mod, CL = BigWigs:NewBoss("Ignis the Furnace Master", 603, 1638)
if not mod then return end
mod:RegisterEnableMob(33118)
mod:SetEncounterID(745)

--------------------------------------------------------------------------------
-- Locals
--

local flameJetsCount = 0
local prevBrittle = 0

--------------------------------------------------------------------------------
-- Initialization
--

local slagPotMarker = mod:AddMarkerOption(false, "player", 8, 63477, 8)
function mod:GetOptions()
	return {
		312727, -- Flame Jets
		312730, -- Scorch
		312731, -- Slag Pot
		slagPotMarker,
		62382, -- Brittle
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "FlameJets", 312727, 312728, 62680, 63472)
	self:Log("SPELL_CAST_SUCCESS", "Scorch", 312729, 312730, 62548, 63474)
	self:Log("SPELL_AURA_APPLIED", "SlagPot", 312732, 312731, 62717, 63477)
	self:Log("SPELL_AURA_REMOVED", "SlagPotRemoved", 312732, 312731, 62717, 63477)
	self:Log("SPELL_AURA_APPLIED", "Brittle", 62382)
end

function mod:OnEngage()
	flameJetsCount = 0
	self:CDBar(312730, 12)
	self:CDBar(312727, 29, CL.count:format(self:SpellName(312727), 1))
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:FlameJets(args)
	self:StopBar(CL.count:format(self:SpellName(312727), flameJetsCount + 1))
	flameJetsCount = flameJetsCount + 1
	self:Message(312727, "red", CL.count:format(self:SpellName(312727), flameJetsCount))
	self:PlaySound(312727, "alert") -- stop casting
	self:CastBar(312727, 2.7)
	self:CDBar(312727, 42, CL.count:format(self:SpellName(312727), flameJetsCount + 1))
end

function mod:Scorch(args)
	self:CastBar(312730, 3)
	self:CDBar(312730, 31)
end

function mod:SlagPot(args)
	self:TargetMessage(312731, "orange", args.destName)
	self:TargetBar(312731, 10, args.destName)
	self:CustomIcon(slagPotMarker, args.destName, 8)
end

function mod:SlagPotRemoved(args)
	self:CustomIcon(slagPotMarker, args.destName)
end

function mod:Brittle(args)
	if args.time - prevBrittle > 5 then
		prevBrittle = args.time
		self:Message(62382, "green")
		if self:Damager() then
			self:PlaySound(62382, "info") -- kill the construct
		end
	end
end
