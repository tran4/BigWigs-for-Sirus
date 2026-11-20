--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Serpentshrine/TrashMobs.lua), draft by tools/dbm2bw

local mod, CL = BigWigs:NewBoss("Serpentshrine Cavern Trash", 548)
if not mod then return end
mod.displayName = CL.trash
mod:SetTrashModule(true)
mod:RegisterEnableMob(21251) -- Underbog Colossus

--------------------------------------------------------------------------------
-- Locals
--

local prevSpores = 0

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		{39042, "PROXIMITY"}, -- Rampant Infection
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "RampantInfection", 39042)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:RampantInfection(args)
	self:OpenProximity(39042, 10)
	self:ScheduleTimer("CloseProximity", 30, 39042) -- 3.3.5: DBM hides the range frame on the end of combat
	if self:Me(args.destGUID) and args.time - prevSpores > 4 then
		prevSpores = args.time
		self:PersonalMessage(39042)
		self:PlaySound(39042, "runaway")
	end
end
