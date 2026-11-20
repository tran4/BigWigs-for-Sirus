--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Ulduar/Freya_Elders.lua), draft by tools/dbm2bw
-- Freya's Elders: Elder Ironbranch, Elder Brightleaf, Elder Stonebark (DBM passive module).

local mod, CL = BigWigs:NewBoss("Ulduar Trash", 603)
if not mod then return end
mod.displayName = CL.trash
mod:SetTrashModule(true)
mod:RegisterEnableMob(
	32913, -- Elder Ironbranch
	32915, -- Elder Brightleaf
	32914 -- Elder Stonebark
)

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		{62344, "TANK"}, -- Fists of Stone
		62932, -- Ground Tremor
		{62928, "TANK_HEALER"}, -- Impale
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "FistsOfStone", 62344)
	self:Log("SPELL_CAST_START", "GroundTremor", 62325, 62932)
	self:Log("SPELL_AURA_APPLIED", "Impale", 62310, 62928)
	self:Log("SPELL_AURA_REMOVED", "ImpaleRemoved", 62310, 62928)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:FistsOfStone(args)
	self:Message(62344, "red")
	self:PlaySound(62344, "alarm") -- run
end

function mod:GroundTremor(args)
	self:Message(62932, "orange", CL.casting:format(args.spellName))
	self:PlaySound(62932, "alert") -- stop casting
end

function mod:Impale(args)
	if not self:Me(args.destGUID) then
		self:TargetMessage(62928, "purple", args.destName)
		if self:Tank() then
			self:PlaySound(62928, "warning") -- taunt
		end
	end
	self:TargetBar(62928, 5, args.destName)
end

function mod:ImpaleRemoved(args)
	self:StopBar(62928, args.destName)
end
