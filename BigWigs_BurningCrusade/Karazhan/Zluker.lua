--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Karazhan/Zluker.lua), a custom Sirus Opera event, no journal id.
-- DBM has only Russian texts: the English defaults are the Russian texts.

local mod, CL = BigWigs:NewBoss("Zluker", 532)
if not mod then return end
mod:RegisterEnableMob(10055, 100552, 100555)
mod:SetEncounterID(66301)

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	bossName = "Злюкер", -- DBM: no English text
	engage_trigger = "Вместе мы неудержимы!", -- DBM: no English text
	warmup_trigger = "Обидишь нас - получишь в дукер! Об этом наша пьеса... Злюкер!", -- DBM: no English text
})
mod.displayName = L.bossName

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"warmup",
		305535, -- magic
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "Magic", 305535)
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
end

function mod:OnEngage()
	self:StopBar(CL.active)
	self:CDBar(305535, 66)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if msg:find(L.warmup_trigger, nil, true) then
		self:Bar("warmup", 42, CL.active, "inv_misc_pocketwatch_01")
	elseif msg:find(L.engage_trigger, nil, true) and not self:IsEngaged() then
		self:Engage() -- DBM RegisterCombat("yell")
	end
end

function mod:Magic()
	self:CDBar(305535, 79)
end
