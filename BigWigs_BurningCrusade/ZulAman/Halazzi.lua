--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-ZulAman/Halazzi.lua), draft by tools/dbm2bw

local mod, CL = BigWigs:NewBoss("Halazzi", 568, 189)
if not mod then return end
mod:RegisterEnableMob(23577)
mod:SetEncounterID(1192)

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"berserk",
		{41254, "DISPEL"}, -- Frenzy
		{43303, "DISPEL"}, -- Flame Shock
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "Frenzy", 41254)
	self:Log("SPELL_AURA_APPLIED", "FlameShock", 43303)
end

function mod:OnEngage()
	self:Berserk(BigWigsLoader.Compat.GetRealmNumber() == 1 and 600 or 300) -- 3.3.5: DBM Sirus x1 realm timer
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:Frenzy(args)
	if self:Dispeller("enrage", true, 41254) then -- DBM: hunters
		self:Message(41254, "red", CL.onboss:format(args.spellName))
		self:PlaySound(41254, "alert")
	end
end

function mod:FlameShock(args)
	if self:Dispeller("magic", nil, 43303) then -- DBM: priests and paladins
		self:TargetMessage(43303, "orange", args.destName)
		self:PlaySound(43303, "alert")
	end
end
