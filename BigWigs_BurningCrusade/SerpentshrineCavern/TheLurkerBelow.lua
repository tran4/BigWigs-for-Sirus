--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Serpentshrine/TheLurkerBelow.lua), draft by tools/dbm2bw
-- The submerge/emerge cycle is timer based like DBM.

local mod, CL = BigWigs:NewBoss("The Lurker Below", 548, 1568)
if not mod then return end
mod:RegisterEnableMob(21217)
mod:SetEncounterID(624)

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	spout_trigger = "%s делает глубокий вдох.", -- DBM: no English text, msg == L.EmoteSpout (the raw emote text)

	submerge = "Submerge",
	submerge_desc = "Show warnings and timers for submerge and emerge",
	submerge_icon = "misc_arrowdown",
	submerged = "Submerged",
	emerged = "Emerged",
	emerge = "Emerge",
})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"submerge",
		37433, -- Spout
	}
end

function mod:OnBossEnable()
	self:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE")
end

function mod:OnEngage()
	self:Bar("submerge", 60, L.submerge, "misc_arrowdown")
	self:ScheduleTimer("Submerge", 60)
	self:CDBar(37433, 47)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:Submerge()
	self:Message("submerge", "cyan", L.submerged, "misc_arrowdown")
	self:Bar("submerge", 64, L.emerge, "misc_arrowlup")
	self:StopBar(37433)
	self:CancelTimer(self.emergeTimer)
	self.emergeTimer = self:ScheduleTimer("Emerge", 64)
end

function mod:Emerge()
	self:Message("submerge", "cyan", L.emerged, "misc_arrowlup")
	-- 3.3.5: DBM starts the 60s submerge timer here, but the next submerge is scheduled after 115s, the bar follows it
	self:Bar("submerge", 115, L.submerge, "misc_arrowdown")
	self:CDBar(37433, 45)
	self:CancelTimer(self.submergeTimer)
	self.submergeTimer = self:ScheduleTimer("Submerge", 115)
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(_, msg)
	if msg:find(L.spout_trigger, nil, true) then
		self:Message(37433, "red")
		self:PlaySound(37433, "runaway")
		self:CastBar(37433, 14)
		self:ScheduleTimer("CDBar", 14, 37433, 36)
	end
end
