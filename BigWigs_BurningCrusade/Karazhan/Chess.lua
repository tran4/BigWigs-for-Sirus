--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Karazhan/Chess.lua), draft by tools/dbm2bw
-- No journal id. The enemy king depends on the faction (DBM: Warchief Blackhand for the Alliance, King Llane for
-- the Horde), both are enable mobs; DBM keeps the fight for 10 minutes without combat (SetWipeTime(600)).
-- DBM restarts the cheat timer by an emote that has no text in its localization, so the bar is only shown on the pull.

local mod, CL = BigWigs:NewBoss("Chess Event", 532)
if not mod then return end
mod:RegisterEnableMob(21752, 21684) -- Warchief Blackhand, King Llane
mod:SetEncounterID(660)
mod:SetEmulationWipeDelay(600)

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	bossName = "Chess Event",
	cheat = "Cheat",
	cheat_desc = "Show timer for the next cheat of Medivh",
	cheat_icon = 39342,
})
mod.displayName = L.bossName

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"cheat",
		37471, -- Heroism
		37472, -- Bloodlust
		30529, -- Recently In Game
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_SUCCESS", "Heroism", 37471)
	self:Log("SPELL_CAST_SUCCESS", "Bloodlust", 37472)
	self:Log("SPELL_AURA_APPLIED", "RecentlyInGame", 30529)
end

function mod:OnEngage()
	self:SetWinMobs(UnitFactionGroup("player") == "Alliance" and 21752 or 21684)
	self:Bar("cheat", 108, L.cheat, L.cheat_icon)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:Heroism(args)
	self:Bar(37471, 10, CL.other:format(args.spellName, CL.active))
end

function mod:Bloodlust(args)
	self:Bar(37472, 10, CL.other:format(args.spellName, CL.active))
end

function mod:RecentlyInGame(args)
	if self:Me(args.destGUID) then
		self:Bar(30529, 10)
	end
end
