--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-ChamberOfAspects/Ruby/Baltharus.lua), draft by tools/dbm2bw
-- No journal id: the name is from the DBM localization.

local mod, CL = BigWigs:NewBoss("Baltharus the Warborn", 724)
if not mod then return end
mod:RegisterEnableMob(39751)
mod:SetEncounterID(1147)

--------------------------------------------------------------------------------
-- Locals
--

local warned = {}
local brandIcon = 8

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	bossName = "Baltharus the Warborn",
	split_soon = "Split soon",
})
mod.displayName = L.bossName

--------------------------------------------------------------------------------
-- Initialization
--

local brandMarker = mod:AddMarkerOption(false, "player", 8, 74505, 8, 7, 6, 5, 4, 3, 2, 1)
function mod:GetOptions()
	return {
		"stages",
		74509, -- Repelling Wave
		{75125, "TANK_HEALER"}, -- Blade Tempest
		74505, -- Enervating Brand
		brandMarker,
		"proximity",
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "RepellingWave", 74509)
	self:Log("SPELL_AURA_APPLIED", "BladeTempest", 75125)
	self:Log("SPELL_AURA_APPLIED", "EnervatingBrand", 74505)
	self:RegisterUnitEvent("UNIT_HEALTH", nil, "boss1")
end

function mod:OnEngage()
	warned = {}
	brandIcon = 8
	self:OpenProximity("proximity", 12)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:RepellingWave(args)
	self:Message(74509, "red")
	self:PlaySound(74509, "alarm")
	self:CastBar(74509, 4)
end

function mod:BladeTempest(args)
	self:Message(75125, "orange")
	self:Bar(75125, 4, CL.other:format(args.spellName, CL.active))
end

do
	local playerList = {}
	local prev = 0
	function mod:EnervatingBrand(args)
		if not self:IsEngaged() then return end -- DBM: only when the boss is engaged
		if args.time - prev > 0.5 then
			prev = args.time
			playerList = {}
			brandIcon = 8
		end
		playerList[#playerList + 1] = args.destName
		self:TargetsMessage(74505, "orange", playerList, nil, nil, nil, 0.5)
		if self:Me(args.destGUID) then
			self:PlaySound(74505, "warning")
			self:Bar(74505, 10, CL.you:format(args.spellName))
		end
		if brandIcon > 0 then
			self:CustomIcon(brandMarker, args.destName, brandIcon)
			self:ScheduleTimer("CustomIcon", 10, brandMarker, args.destName)
			brandIcon = brandIcon - 1
		end
	end
end

function mod:UNIT_HEALTH(_, unit)
	if self:MobId(self:UnitGUID(unit)) ~= 39751 then return end
	local hp = self:GetHealth(unit)
	local size25 = self:Difficulty() == 4 or self:Difficulty() == 6
	if size25 then
		if not warned[1] and hp <= 70 then
			warned[1] = true
			self:Message("stages", "cyan", L.split_soon, false)
		elseif not warned[3] and hp <= 37 then
			warned[3] = true
			self:Message("stages", "cyan", L.split_soon, false)
		end
	elseif not warned[2] and hp <= 54 then
		warned[2] = true
		self:Message("stages", "cyan", L.split_soon, false)
	end
end
