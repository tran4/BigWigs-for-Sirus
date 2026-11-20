--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-TheEye/Trash.lua), draft by tools/dbm2bw

local mod, CL = BigWigs:NewBoss("Tempest Keep Trash", 550)
if not mod then return end
mod.displayName = CL.trash
mod:SetTrashModule(true)
mod:RegisterEnableMob(20045)

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		37135, -- Domination
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "Domination", 37135)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

do
	local playerList = {}
	local prev = 0
	function mod:Domination(args)
		if args.time - prev > 1 then
			prev = args.time
			playerList = {}
		end
		playerList[#playerList + 1] = args.destName
		self:TargetsMessage(37135, "red", playerList, nil, nil, nil, 0.1)
	end
end
