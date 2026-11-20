--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Gruul/Gruul.lua, heroic mode with custom spells), draft by tools/dbm2bw
-- DBM has only Russian texts for the heroic timers: the English defaults are the Russian texts.

local mod, CL = BigWigs:NewBoss("Gruul the Dragonkiller", 565, 1565)
if not mod then return end
mod:RegisterEnableMob(19044)
mod:SetEncounterID(650)

--------------------------------------------------------------------------------
-- Locals
--

local rockCount = 1

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	strike = "Хлопок!", -- DBM: no English text
	furnace = "Печь", -- DBM: no English text
	furnace_desc = "Отсчет времени пока печь активна и не активна", -- DBM: no English text
	furnace_icon = 305201,
	furnace_active = "Печь активна", -- DBM: no English text
	furnace_inactive = "Печь не активна", -- DBM: no English text
	burned_flesh = "Обожженная плоть (х2 урон)", -- DBM: no English text
})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		33525, -- Ground Slam
		36297, -- Reverberation
		36240, -- Cave In
		305188, -- heroic: hands
		305197, -- heroic: Hateful Strike
		305183, -- heroic: Stunning Blow
		"furnace",
		305204, -- heroic: Burned Flesh
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "GroundSlam", 33525)
	self:Log("SPELL_CAST_START", "HatefulStrike", 305197)
	self:Log("SPELL_CAST_START", "StunningBlow", 305183)
	self:Log("SPELL_CAST_SUCCESS", "Hands", 305188)
	self:Log("SPELL_CAST_SUCCESS", "CaveIn", 36240)
	self:Log("SPELL_AURA_APPLIED", "FurnaceActive", 305201)
	self:Log("SPELL_AURA_REMOVED", "FurnaceInactive", 305201)
	self:Log("SPELL_AURA_APPLIED", "BurnedFlesh", 305204)
	self:Log("SPELL_AURA_APPLIED", "Reverberation", 36297)
	self:Log("SPELL_AURA_APPLIED", "CaveInApplied", 36240)
end

function mod:OnEngage()
	rockCount = 1
	if self:Heroic() then
		self:CDBar(305188, 24)
		self:CDBar(305197, 20)
		self:CDBar(305183, 15)
	else
		self:CDBar(33525, 35)
		self:CDBar(36240, 28)
	end
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:GroundSlam(args)
	self:Message(33525, "orange")
	self:CDBar(33525, 133)
	self:CDBar(36297, 25)
	self:CDBar(36240, 30 - rockCount * 2 + 4)
	if rockCount <= 11 then rockCount = rockCount + 1 end
end

function mod:CaveIn()
	self:CDBar(36240, 30 - rockCount * 2)
	if rockCount <= 11 then rockCount = rockCount + 1 end
end

function mod:CaveInApplied(args)
	if self:Me(args.destGUID) then
		self:PersonalMessage(36240, "underyou")
		self:PlaySound(36240, "underyou")
	end
end

function mod:Reverberation()
	self:CDBar(36297, 15)
end

function mod:HatefulStrike()
	self:CDBar(305197, 6)
end

function mod:StunningBlow()
	self:CDBar(305183, 20)
end

function mod:Hands(args)
	self:Message(305188, "red")
	self:CDBar(305188, 29)
	self:Bar(305188, 7, L.strike)
end

function mod:FurnaceActive()
	self:Bar("furnace", 8, L.furnace_active, L.furnace_icon)
end

function mod:FurnaceInactive()
	self:Bar("furnace", 43, L.furnace_inactive, L.furnace_icon)
end

function mod:BurnedFlesh()
	self:Bar(305204, 20, L.burned_flesh)
end
