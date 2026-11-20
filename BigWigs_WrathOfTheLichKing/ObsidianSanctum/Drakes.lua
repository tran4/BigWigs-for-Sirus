--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-ChamberOfAspects/Obsidian/Shadron.lua, Tenebron.lua, Vesperon.lua)
-- The three DBM modules are the same (Shadow Fissure of the drakes): one zone module, enabled in the zone like trash,
-- so it also works for the drakes in the Sartharion fight.

local mod, CL = BigWigs:NewBoss("Obsidian Sanctum Drakes", 615)
if not mod then return end
mod.displayName = CL.trash
mod:SetTrashModule(true)
mod:RegisterEnableMob(30451, 30452, 30449) -- Shadron, Tenebron, Vesperon

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		59127, -- Shadow Fissure
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_SUCCESS", "ShadowFissure", 57579, 59127)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:ShadowFissure(args)
	self:Message(59127, "red")
	self:PlaySound(59127, "alarm")
	self:CastBar(59127, 5) -- DBM: until the Void Blast (59128)
end
