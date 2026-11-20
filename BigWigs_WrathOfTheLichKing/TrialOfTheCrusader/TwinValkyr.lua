--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Coliseum/Twins.lua), draft by tools/dbm2bw
-- Not ported: the shield absorb info frame and health bar.

local mod, CL = BigWigs:NewBoss("The Twin Val'kyr", 649, 1622)
if not mod then return end
mod:RegisterEnableMob(34497, 34496) -- Fjola Lightbane, Eydis Darkbane
mod:SetEncounterID(641)
mod:SetWinMobs(34497, 34496)

--------------------------------------------------------------------------------
-- Locals
--

local touchList = {}
local prevTouch = 0
local touchIcon = 1

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({

	special = "Next special ability",
	special_desc = "Show timer for next special ability",
	special_icon = "INV_Enchant_EssenceMagicLarge",
	special_soon = "Special ability soon",
	change_color = "Change color",
	switch_target = "Switch target",
	kick_now = "Interrupt now",
	twins_power = "Power of the Twins - More healing on %s",
})

--------------------------------------------------------------------------------
-- Initialization
--

local touchMarker = mod:AddMarkerOption(false, "player", 1, 65950, 1, 2, 3, 4)
function mod:GetOptions()
	return {
		"berserk",
		"special",
		65875, -- Twin's Pact
		65724, -- Empowered Darkness
		65748, -- Empowered Light
		65916, -- Power of the Twins
		65874, -- Shield of Darkness
		65950, -- Touch of Light
		66001, -- Touch of Darkness
		touchMarker,
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "LightVortex", 66046, 67206, 67207, 67208)
	self:Log("SPELL_CAST_START", "DarkVortex", 66058, 67182, 67183, 67184)
	self:Log("SPELL_CAST_START", "TwinsPact", 65875, 67303, 67304, 67305)
	self:Log("SPELL_CAST_START", "LightPact", 65876, 67306, 67307, 67308)
	self:Log("SPELL_INTERRUPT", "PactInterrupted", 65875, 67303, 67304, 67305, 65876, 67306, 67307, 67308)
	self:Log("SPELL_AURA_APPLIED", "EmpoweredDarkness", 65724, 67213, 67214, 67215)
	self:Log("SPELL_AURA_APPLIED", "EmpoweredLight", 65748, 67216, 67217, 67218)
	self:Log("SPELL_AURA_APPLIED", "TouchOfLight", 65950, 67296, 67297, 67298)
	self:Log("SPELL_AURA_REMOVED", "TouchRemoved", 65950, 67296, 67297, 67298, 66001, 67281, 67282, 67283)
	self:Log("SPELL_AURA_APPLIED", "TouchOfDarkness", 66001, 67281, 67282, 67283)
	self:Log("SPELL_AURA_APPLIED", "PowerOfTheTwins", 67246, 65879, 65916, 67244, 67245, 67248, 67249, 67250)
	self:Log("SPELL_AURA_REMOVED", "ShieldRemoved", 65874, 67256, 67257, 67258, 65858, 67259, 67260, 67261)
end

function mod:OnEngage()
	touchList = {}
	touchIcon = 1
	self:Bar("special", 45, L.special, L.special_icon)
	self:DelayedMessage("special", 40, "yellow", L.special_soon, L.special_icon)
	self:Berserk(self:Heroic() and 360 or 480)
end

function mod:OnWin()
	-- the Lich King breaks the floor after the victory roleplay, the Anub'arak module shows the timer
	local anub = BigWigs:GetBossModule("Anub'arak", true)
	if anub and not anub:IsEnabled() then
		anub:Enable()
	end
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:SpecialAbility(noWarning)
	if not noWarning then
		self:Message("special", "red", L.change_color, L.special_icon)
		self:PlaySound("special", "warning")
	end
	self:Bar("special", 45, L.special, L.special_icon)
	self:DelayedMessage("special", 40, "yellow", L.special_soon, L.special_icon)
end

function mod:LightVortex()
	-- change color unless you already have Light Essence
	self:SpecialAbility(UnitDebuff("player", self:SpellName(65686)))
end

function mod:DarkVortex()
	self:SpecialAbility(UnitDebuff("player", self:SpellName(65684)))
end

function mod:TwinsPact(args) -- Eydis heals
	self:CastBar(65875, 15)
	self:SpecialAbility(true)
	if self:MobId(self:UnitGUID("target")) == 34497 then -- on Fjola: switch to Eydis
		self:Message(65875, "orange", L.switch_target)
		self:PlaySound(65875, "alert")
	end
end

function mod:LightPact(args) -- Fjola heals
	self:CastBar(65875, 15)
	self:SpecialAbility(true)
	if self:MobId(self:UnitGUID("target")) == 34496 then -- on Eydis: switch to Fjola
		self:Message(65875, "orange", L.switch_target)
		self:PlaySound(65875, "alert")
	end
end

function mod:PactInterrupted()
	self:StopCastBar(65875)
end

function mod:ShieldRemoved(args)
	self:Message(65874, "red", L.kick_now)
	if self:Interrupter(args.destGUID) then
		self:PlaySound(65874, "alert")
	end
end

function mod:EmpoweredDarkness(args)
	if self:Me(args.destGUID) then
		self:PersonalMessage(65724)
	end
end

function mod:EmpoweredLight(args)
	if self:Me(args.destGUID) then
		self:PersonalMessage(65748)
	end
end

function mod:Touch(args)
	if args.time - prevTouch > 3 then
		touchList = {}
		touchIcon = 1
	end
	prevTouch = args.time
	touchList[#touchList + 1] = args.destName
	self:CustomIcon(touchMarker, args.destName, touchIcon)
	touchIcon = touchIcon + 1
end

function mod:TouchOfLight(args)
	self:Touch(args)
	self:TargetsMessage(65950, "yellow", touchList, nil, nil, nil, 0.9)
	self:TargetBar(65950, 20, args.destName)
end

function mod:TouchOfDarkness(args)
	self:Touch(args)
	self:TargetsMessage(66001, "yellow", touchList, nil, nil, nil, 0.75)
	self:TargetBar(66001, 20, args.destName)
end

function mod:TouchRemoved(args)
	self:StopBar(65950, args.destName)
	self:StopBar(66001, args.destName)
	self:CustomIcon(touchMarker, args.destName)
end

function mod:PowerOfTheTwins(args)
	-- who the empowered twin is attacking
	local unit = self:UnitTokenFromGUID(args.destGUID)
	local target = unit and self:UnitName(unit .. "target")
	if not target then return end
	if target == self:UnitName("player") then
		self:PersonalMessage(65916)
		self:PlaySound(65916, "alarm") -- defensive
	elseif self:Healer() then
		self:Message(65916, "purple", L.twins_power:format(self:ColorName(target)))
	end
end
