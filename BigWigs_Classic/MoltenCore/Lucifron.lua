--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-MC/Lucifron.lua)

local mod, CL = BigWigs:NewBoss("Lucifron", 409, 1519)
if not mod then return end
mod:RegisterEnableMob(12118)
mod:SetEncounterID(663)

--------------------------------------------------------------------------------
-- Locals
--

local mcList = {}
local lastIcon = 1

--------------------------------------------------------------------------------
-- Initialization
--

local mcMarker = mod:AddMarkerOption(true, "player", 1, 20604, 1, 2)
function mod:GetOptions()
	return {
		19702, -- Impending Doom
		19703, -- Lucifron's Curse
		{20604, "SAY"}, -- Dominate Mind
		mcMarker,
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_SUCCESS", "ImpendingDoom", 19702)
	self:Log("SPELL_CAST_SUCCESS", "LucifronsCurse", 19703)
	self:Log("SPELL_CAST_START", "DominateMind", 20604)
	self:Log("SPELL_AURA_REMOVED", "DominateMindRemoved", 20604)
end

function mod:OnEngage()
	mcList = {}
	lastIcon = 1
	self:CDBar(19702, 7)
	self:CDBar(19703, 12)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:ImpendingDoom(args)
	self:Message(19702, "yellow")
	self:CDBar(19702, 20)
end

function mod:LucifronsCurse(args)
	self:Message(19703, "orange")
	self:CDBar(19703, 20.5)
end

do
	local function mcTarget(self, name, guid)
		mcList[#mcList + 1] = name
		self:TargetsMessage(20604, "red", mcList, nil, nil, nil, 1) -- DBM: CombinedShow(1)
		self:CustomIcon(mcMarker, name, lastIcon)
		lastIcon = lastIcon == 1 and 2 or 1
		if self:Me(guid) then
			self:PlaySound(20604, "warning")
			self:Say(20604)
		end
	end
	function mod:DominateMind(args)
		if self:Hostile(args.sourceFlags) then
			self:GetUnitTarget(mcTarget, 0.2, args.sourceGUID) -- DBM: BossTargetScanner
		end
	end
end

function mod:DominateMindRemoved(args)
	if self:Player(args.destFlags) then
		self:CustomIcon(mcMarker, args.destName)
	end
end
