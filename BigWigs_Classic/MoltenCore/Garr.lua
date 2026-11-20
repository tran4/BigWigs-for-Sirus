--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-MC/Garr.lua)

local mod, CL = BigWigs:NewBoss("Garr", 409, 1522)
if not mod then return end
mod:RegisterEnableMob(12057)
mod:SetEncounterID(666)

--------------------------------------------------------------------------------
-- Locals
--

local immolateList = {}

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		19492, -- Antimagic Pulse
		{15732, "OFF"}, -- Immolate
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_SUCCESS", "AntimagicPulse", 19492)
	self:Log("SPELL_AURA_APPLIED", "Immolate", 15732)
end

function mod:OnEngage()
	immolateList = {}
	self:CDBar(19492, 10)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:AntimagicPulse(args)
	self:Message(19492, "yellow")
	self:CDBar(19492, 15.7)
end

function mod:Immolate(args)
	if self:Player(args.destFlags) then
		immolateList[#immolateList + 1] = args.destName
		self:TargetsMessage(15732, "orange", immolateList, nil, nil, nil, 1)
	end
end
