--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-ChamberOfAspects/Ruby/Saviana.lua), draft by tools/dbm2bw
-- No journal id: the name is from the DBM localization.

local mod, CL = BigWigs:NewBoss("Saviana Ragefire", 724)
if not mod then return end
mod:RegisterEnableMob(39747)
mod:SetEncounterID(1148)

--------------------------------------------------------------------------------
-- Locals
--

local beaconIcon = 8

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	bossName = "Saviana Ragefire",
})
mod.displayName = L.bossName

--------------------------------------------------------------------------------
-- Initialization
--

local beaconMarker = mod:AddMarkerOption(true, "player", 8, 74453, 8, 7, 6, 5, 4)
function mod:GetOptions()
	return {
		74453, -- Flame Beacon
		beaconMarker,
		74452, -- Conflagration
		{74403, "TANK_HEALER"}, -- Flame Breath
		78722, -- Enrage
		"proximity",
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "FlameBreath", 74403, 74404)
	self:Log("SPELL_AURA_APPLIED", "Enrage", 78722)
	self:Log("SPELL_AURA_REMOVED", "EnrageRemoved", 78722)
	self:Log("SPELL_AURA_APPLIED", "FlameBeacon", 74453)
end

function mod:OnEngage()
	beaconIcon = 8
	self:Bar(74452, 32)
	self:CDBar(74403, 12)
	self:OpenProximity("proximity", 10)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:FlameBreath(args)
	self:Message(74403, "orange")
	self:CDBar(74403, 25)
end

function mod:Enrage(args)
	if self:Dispeller("enrage", true) then
		self:Message(78722, "red", CL.onboss:format(args.spellName))
		self:PlaySound(78722, "alert")
	end
	self:Bar(78722, 10, CL.other:format(args.spellName, CL.active))
end

function mod:EnrageRemoved(args)
	self:StopBar(CL.other:format(args.spellName, CL.active))
end

do
	local playerList = {}
	local prev = 0
	function mod:FlameBeacon(args)
		if args.time - prev > 1 then
			prev = args.time
			playerList = {}
			beaconIcon = 8
			self:Bar(74452, 50)
			self:Bar(74453, 5)
			self:ScheduleTimer("Bar", 5, 74452, 5, CL.other:format(self:SpellName(74456), CL.active))
		end
		playerList[#playerList + 1] = args.destName
		self:TargetsMessage(74453, "red", playerList, nil, nil, nil, 0.3)
		if self:Me(args.destGUID) then
			self:PlaySound(74453, "warning")
		end
		self:CustomIcon(beaconMarker, args.destName, beaconIcon)
		self:ScheduleTimer("CustomIcon", 11, beaconMarker, args.destName)
		beaconIcon = beaconIcon - 1
	end
end
