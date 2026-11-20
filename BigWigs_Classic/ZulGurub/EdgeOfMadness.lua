--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-ZG/EdgeOfMadness.lua), no journal id: the name is from the DBM locale.
-- DBM registers only Hazza'rah (15083) and checks Chain Burn (24684) for Sleep and Vanish (24699) for Frenzy:
-- Sleep (24664) and Frenzy (8269) are used here.

local mod, CL = BigWigs:NewBoss("Edge of Madness", 309)
if not mod then return end
mod:RegisterEnableMob(15083) -- Hazza'rah
mod:SetEncounterID(788)

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	bossName = "Edge of Madness",
})
mod.displayName = L.bossName

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		24728, -- Summon Illusions
		24664, -- Sleep
		24684, -- Chain Burn
		8269, -- Frenzy
		24699, -- Vanish
		24683, -- Cloud
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_SUCCESS", "ChainBurn", 24684)
	self:Log("SPELL_CAST_SUCCESS", "Vanish", 24699)
	self:Log("SPELL_CAST_SUCCESS", "Cloud", 24683)
	self:Log("SPELL_AURA_APPLIED", "Sleep", 24664)
	self:Log("SPELL_AURA_APPLIED", "Frenzy", 8269)
	self:Log("SPELL_SUMMON", "Illusions", 24728)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:ChainBurn(args)
	self:Message(24684, "orange")
end

function mod:Vanish(args)
	if self:Hostile(args.sourceFlags) then
		self:Message(24699, "yellow")
	end
end

function mod:Cloud(args)
	self:Message(24683, "orange")
	self:Bar(24683, 15, CL.other:format(args.spellName, CL.active))
end

do
	local prev = 0
	function mod:Sleep(args)
		if self:Player(args.destFlags) and args.time - prev > 3 then
			prev = args.time
			self:Message(24664, "yellow")
			self:Bar(24664, 6, CL.other:format(args.spellName, CL.active))
		end
	end
end

function mod:Frenzy(args)
	if not self:Player(args.destFlags) then
		self:Message(8269, "red")
	end
end

function mod:Illusions(args)
	self:Message(24728, "yellow")
end
