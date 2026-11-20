--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-AQ40/Sartura.lua)

local mod, CL = BigWigs:NewBoss("Battleguard Sartura", 531, 1544)
if not mod then return end
mod:RegisterEnableMob(15516)
mod:SetEncounterID(711)

--------------------------------------------------------------------------------
-- Locals
--

local warnedSoon = false

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		26083, -- Whirlwind
		8269, -- Frenzy
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_SUCCESS", "Whirlwind", 26083)
	self:Log("SPELL_CAST_SUCCESS", "Frenzy", 8269)
	self:RegisterEvent("UNIT_HEALTH")
end

function mod:OnEngage()
	warnedSoon = false
end

--------------------------------------------------------------------------------
-- Event Handlers
--

do
	local prev = 0
	function mod:Whirlwind(args)
		if self:Hostile(args.sourceFlags) and args.time - prev > 4 then
			prev = args.time
			self:Message(26083, "orange")
		end
	end
end

function mod:Frenzy(args)
	if self:Hostile(args.sourceFlags) then
		self:Message(8269, "red")
		self:PlaySound(8269, "alarm")
	end
end

function mod:UNIT_HEALTH(_, unit)
	if not warnedSoon and self:IsEngaged() and self:MobId(self:UnitGUID(unit)) == 15516 and self:GetHealth(unit) <= 35 then
		warnedSoon = true
		self:Message(8269, "yellow", CL.soon:format(self:SpellName(8269)))
	end
end
