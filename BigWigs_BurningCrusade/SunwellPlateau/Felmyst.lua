--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Sunwell/Felmyst.lua), draft by tools/dbm2bw
-- DBM has only Russian texts for the phases: the English defaults are the Russian texts.

local mod, CL = BigWigs:NewBoss("Felmyst", 580, 1593)
if not mod then return end
mod:RegisterEnableMob(25038)
mod:SetEncounterID(726)

--------------------------------------------------------------------------------
-- Locals
--

local breathCount = 0
local prevEncapsulate = 0

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	-- DBM: no English texts
	air_trigger = "Я сильнее, чем когда-либо прежде!",
	breath_trigger = "%s глубоко вдыхает.",
	air = "воздушная",
	ground = "наземная",
	phase_msg = "%s фаза",
	phase_bar = "Следующая %s фаза",
})

--------------------------------------------------------------------------------
-- Initialization
--

local encapsulateMarker = mod:AddMarkerOption(true, "player", 7, 45665, 7)
local vaporMarker = mod:AddMarkerOption(true, "player", 8, 45402, 8)
function mod:GetOptions()
	return {
		"stages",
		45855, -- Gas Nova
		{45866, "TANK"}, -- Corrosion
		{45665, "SAY"}, -- Encapsulate
		encapsulateMarker,
		45402, -- Demonic Vapor
		vaporMarker,
		45717, -- Fog of Corruption
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "Corrosion", 45866)
	self:Log("SPELL_SUMMON", "DemonicVapor", 45392)
	self:Log("SPELL_CAST_START", "GasNova", 45855)
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
	self:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE")
	self:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
end

function mod:OnEngage()
	breathCount = 0
	prevEncapsulate = 0
	self:CDBar(45855, 17)
	self:Bar("stages", 60, L.phase_bar:format(L.air), 31550)
	self:CDBar(45665, 50)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:GroundPhase()
	breathCount = 0
	self:Message("stages", "cyan", L.phase_msg:format(L.ground), 31550)
	self:CDBar(45855, 17)
	self:Bar("stages", 60, L.phase_bar:format(L.air), 31550)
	self:CDBar(45665, 50)
end

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if msg:find(L.air_trigger, nil, true) and self:IsEngaged() then
		breathCount = 0
		self:Message("stages", "cyan", L.phase_msg:format(L.air), 31550)
		self:PlaySound("stages", "long")
		self:StopBar(45855)
		self:Bar(45717, 42, CL.count:format(self:SpellName(45717), 1))
		self:Bar("stages", 99, L.phase_bar:format(L.ground), 31550)
		self:ScheduleTimer("GroundPhase", 99)
	end
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(_, msg)
	if msg:find(L.breath_trigger, nil, true) and self:IsEngaged() then
		breathCount = breathCount + 1
		self:Message(45717, "red", CL.count:format(self:SpellName(45717), breathCount))
		self:PlaySound(45717, "warning")
		if breathCount < 3 then
			self:Bar(45717, 17, CL.count:format(self:SpellName(45717), breathCount + 1))
		end
	end
end

do
	local function encapsulateTarget(self, name, guid)
		self:StopBar(45665)
		self:TargetBar(45665, 7, name)
		self:CustomIcon(encapsulateMarker, name, 7)
		self:ScheduleTimer("CustomIcon", 6, encapsulateMarker, name)
		if self:Me(guid) then
			self:PersonalMessage(45665)
			self:PlaySound(45665, "warning")
			self:Say(45665)
		else
			local unit = self:UnitTokenFromGUID(guid)
			if unit and self:UnitWithinRange(unit, 21) then
				self:Message(45665, "orange", CL.near:format(self:SpellName(45665)))
				self:PlaySound(45665, "runaway")
			else
				self:TargetMessage(45665, "orange", name)
			end
		end
	end
	function mod:UNIT_SPELLCAST_SUCCEEDED(_, unit, _, _, spellName)
		if spellName == self:SpellName(45661) and GetTime() - prevEncapsulate > 2 then
			prevEncapsulate = GetTime()
			self:GetUnitTarget(encapsulateTarget, 0.1, self:UnitGUID(unit))
		end
	end
end

function mod:Corrosion(args)
	self:TargetBar(45866, 10, args.destName)
	if not self:Me(args.destGUID) then
		self:TargetMessage(45866, "purple", args.destName)
		self:PlaySound(45866, "warning") -- DBM: taunt
	end
end

function mod:DemonicVapor(args)
	self:TargetMessage(45402, "yellow", args.sourceName)
	if self:Me(args.sourceGUID) then
		self:PlaySound(45402, "warning")
	end
	self:CustomIcon(vaporMarker, args.sourceName, 8)
	self:ScheduleTimer("CustomIcon", 10, vaporMarker, args.sourceName)
end

function mod:GasNova(args)
	self:Message(45855, "orange")
	if self:Healer() then self:PlaySound(45855, "alert") end -- DBM: healers
	self:CastBar(45855, 1)
	self:CDBar(45855, 19)
end
