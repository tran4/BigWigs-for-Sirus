--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-ZG/Jindo.lua), no journal id: the name is from the DBM locale

local mod, CL = BigWigs:NewBoss("Jin'do the Hexxer", 309)
if not mod then return end
mod:RegisterEnableMob(11380)
mod:SetEncounterID(792)

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	bossName = "Jin'do the Hexxer",
})
mod.displayName = L.bossName

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		24306, -- Delusions of Jin'do
		17172, -- Hex
		24261, -- Brain Wash
		24466, -- Banish
		24309, -- Powerful Healing Ward
		24262, -- Brain Wash Totem
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "Delusions", 24306)
	self:Log("SPELL_AURA_APPLIED", "Hex", 17172)
	self:Log("SPELL_AURA_REMOVED", "HexRemoved", 17172)
	self:Log("SPELL_AURA_APPLIED", "BrainWash", 24261)
	self:Log("SPELL_CAST_SUCCESS", "Banish", 24466)
	self:Log("SPELL_SUMMON", "HealingWard", 24309)
	self:Log("SPELL_SUMMON", "BrainWashTotem", 24262)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:Delusions(args)
	if self:Me(args.destGUID) then
		self:PersonalMessage(24306)
		self:PlaySound(24306, "warning")
	else
		self:TargetMessage(24306, "yellow", args.destName)
	end
	if self:Dispeller("curse") then -- DBM: the timer for curse removers
		self:TargetBar(24306, 20, args.destName)
	end
end

function mod:Hex(args)
	if self:Player(args.destFlags) and (self:Dispeller("magic") or self:Healer()) then -- DBM: magic removers and healers
		self:TargetMessage(17172, "orange", args.destName)
		self:TargetBar(17172, 5, args.destName)
	end
end

function mod:HexRemoved(args)
	self:StopBar(17172, args.destName)
end

function mod:BrainWash(args)
	self:TargetMessage(24261, "red", args.destName)
end

function mod:Banish(args)
	if self:Hostile(args.sourceFlags) then
		self:TargetMessage(24466, "yellow", args.destName)
	end
end

function mod:HealingWard(args)
	if not self:Player(args.destFlags) then
		self:Message(24309, "red")
		if not self:Tank() and not self:Healer() then
			self:PlaySound(24309, "alert") -- DBM: attack the totem (dps)
		end
	end
end

function mod:BrainWashTotem(args)
	self:Message(24262, "red")
	if not self:Tank() and not self:Healer() then
		self:PlaySound(24262, "alert") -- DBM: attack the totem (dps)
	end
end
