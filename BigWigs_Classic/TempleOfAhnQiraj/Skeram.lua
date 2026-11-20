--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-AQ40/Skeram.lua)
-- The images share the id of Skeram (DBM: noBossDeathKill) and vanish when he dies: a death of a Skeram wins
-- when no living Skeram is left on the targets of the group a second later.

local mod, CL = BigWigs:NewBoss("The Prophet Skeram", 531, 1543)
if not mod then return end
mod:RegisterEnableMob(15263)
mod:SetEncounterID(709)
mod:SetWinMobs() -- 3.3.5: won by the check below

--------------------------------------------------------------------------------
-- Locals
--

local mcList = {}
local mcIcon = 8
local splitCount = 0
local scanUnits = {"target", "focus", "mouseover"}
for i = 1, 40 do scanUnits[#scanUnits + 1] = "raid" .. i .. "target" end

--------------------------------------------------------------------------------
-- Initialization
--

local mcMarker = mod:AddMarkerOption(true, "player", 8, 785, 8, 7, 6, 5, 4)
function mod:GetOptions()
	return {
		785, -- True Fulfillment
		mcMarker,
		20449, -- Teleport
		747, -- Summon Images
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "TrueFulfillment", 785)
	self:Log("SPELL_AURA_REMOVED", "TrueFulfillmentRemoved", 785)
	self:Log("SPELL_CAST_SUCCESS", "Teleport", 20449, 4801, 8195)
	self:Log("SPELL_SUMMON", "SummonImages", 747)
	self:Death("SkeramDeath", 15263)
	self:RegisterEvent("UNIT_HEALTH")
end

function mod:OnEngage()
	mcList = {}
	mcIcon = 8
	splitCount = 0
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:TrueFulfillment(args)
	mcList[#mcList + 1] = args.destName
	self:CustomIcon(mcMarker, args.destName, mcIcon)
	mcIcon = mcIcon - 1
	self:TargetsMessage(785, "red", mcList, 3, nil, nil, 0.5) -- DBM: shown at 3 targets or after 0.5s
	if #mcList == 1 then
		self:Bar(785, 20, CL.other:format(args.spellName, CL.active))
		self:SimpleTimer(function() mcIcon = 8 end, 0.5)
	end
end

function mod:TrueFulfillmentRemoved(args)
	self:CustomIcon(mcMarker, args.destName)
end

do
	local prev = 0
	function mod:Teleport(args)
		if self:Hostile(args.sourceFlags) and args.time - prev > 3 then
			prev = args.time
			self:Message(20449, "yellow")
		end
	end
end

do
	local prev = 0
	function mod:SummonImages(args)
		if args.time - prev > 3 then
			prev = args.time
			self:Message(747, "orange")
			self:PlaySound(747, "info")
		end
	end
end

function mod:SkeramDeath()
	if self:IsEngaged() then
		self:ScheduleTimer("CheckWin", 1)
	end
end

function mod:CheckWin()
	if not self:IsEngaged() then return end
	for i = 1, #scanUnits do
		local unit = scanUnits[i]
		if self:MobId(self:UnitGUID(unit)) == 15263 and not UnitIsDead(unit) then return end
	end
	self:Win()
end

function mod:UNIT_HEALTH(_, unit)
	if not self:IsEngaged() or self:MobId(self:UnitGUID(unit)) ~= 15263 then return end
	local hp = self:GetHealth(unit)
	local split = hp <= 81 and hp >= 77 and 1 or hp <= 56 and hp >= 52 and 2 or hp <= 31 and hp >= 27 and 3
	if split and splitCount < split then
		splitCount = split
		self:Message(747, "orange", CL.soon:format(self:SpellName(747)))
	end
end
