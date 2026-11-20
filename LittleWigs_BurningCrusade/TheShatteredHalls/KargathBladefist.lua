
--------------------------------------------------------------------------------
-- Module declaration
--

local mod, CL = BigWigs:NewBoss("Warchief Kargath Bladefist", 540, 569)
if not mod then return end
mod:RegisterEnableMob(16808)
mod.engageId = 1938
--mod.respawnTime = 0 -- resets, doesn't respawn

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	-- 3.3.5: DBM Sirus guard waves
	guards = "Guards",
	guards_desc = "Show warning and timer for the Heathen, Reaver and Sharpshooter Guards",
	guards_icon = "Achievement_Character_Orc_Male", -- 3.3.5: DBM uses a retail fileID
	heathen = "Heathen Guard",
	reaver = "Reaver Guard",
	sharpshooter = "Sharpshooter Guard",
})

--------------------------------------------------------------------------------
-- Initialization
--

local guardSet, guardType = 0, 0

function mod:GetOptions()
	return {
		-5899, -- Blade Dance
		"guards", -- 3.3.5: DBM Sirus
	}
end

function mod:OnBossEnable()
	if self:Classic() then
		self:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", nil, "boss1") -- 3.3.5: unit events get the 3.3.5 arguments converted, boss1 comes from the target/focus
	else
		self:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", nil, "boss1")
	end
end

--------------------------------------------------------------------------------
-- Event Handlers
--

do
	local prev
	function mod:UNIT_SPELLCAST_SUCCEEDED(_, _, castGUID, spellId, spellName) -- 3.3.5: compare the name, the id can be nil
		if spellName == self:SpellName(30738) and castGUID ~= prev then -- Blade Dance Targeting
			prev = castGUID
			self:MessageOld(-5899, "yellow", "warning")
			self:CDBar(-5899, self:Retail() and 30 or 35) -- 3.3.5: DBM Sirus 35s
		end
	end
end

-- 3.3.5: DBM Sirus
local guardNames = {"heathen", "reaver", "sharpshooter"}
function mod:OnEngage()
	guardSet, guardType = 0, 0
	self:CDBar(-5899, 72)
	self:Bar("guards", 27.5, L.heathen, L.guards_icon)
	self:ScheduleTimer("GuardWave", 27.5)
end

function mod:GuardWave()
	guardSet = guardSet + 1
	guardType = guardType % 3 + 1
	self:Message("guards", "yellow", ("%s (%d-%d)"):format(L[guardNames[guardType]], guardSet, guardType), L.guards_icon)
	self:Bar("guards", 21, L[guardNames[guardType % 3 + 1]], L.guards_icon)
	self:ScheduleTimer("GuardWave", 21)
end
