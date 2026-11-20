--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Coliseum/AnubArak.lua), draft by tools/dbm2bw
-- Not ported: announcing Penetrating Cold icons to the raid chat, removing health buffs in stage 3.

local mod, CL = BigWigs:NewBoss("Anub'arak", 649, 1623)
if not mod then return end
mod:RegisterEnableMob(34564)
mod:SetEncounterID(645)

--------------------------------------------------------------------------------
-- Locals
--

local burrowed = false
local coldIcon = 1
local prevCold = 0
local prevShadowStrike = 0

local function is25(self) -- 25 player raid (normal or heroic)
	local diff = self:Difficulty()
	return diff == 4 or diff == 6
end

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	-- the roleplay after the Twin Val'kyr, the module is enabled by the Twin Val'kyr module
	roleplay_trigger = "A mighty blow has been dealt to the Lich King! You have proven yourselves as able bodied champions of the Argent Crusade. Together we will strike against Icecrown Citadel and destroy what remains of the Scourge! There is no challenge that we cannot face united!",
	roleplay = "Floor breaks in",
	burrow_trigger = "Auum na-l ak-k-k-k, isshhh. Rise, minions. Devour...",
	emerge_trigger = "emerges from the ground!",

	adds = "New adds",
	adds_desc = "Show timer for new adds",
	adds_icon = 45419,

	submerge = "Submerge",
	submerge_desc = "Show warning and timer for submerge",
	submerge_icon = "misc_arrowdown",
	submerge_message = "Anub'arak submerges",
	submerge_soon = "Submerge in 10 seconds",
	emerge = "Emerge",
	emerge_desc = "Show warning and timer for emerge",
	emerge_icon = "misc_arrowlup",
	emerge_message = "Anub'arak emerges",
	emerge_soon = "Emerge in 10 seconds",
})

--------------------------------------------------------------------------------
-- Initialization
--

local pursueMarker = mod:AddMarkerOption(true, "player", 8, 67574, 8)
local coldMarker = mod:AddMarkerOption(true, "player", 1, 66013, 1, 2, 3, 4, 5)
function mod:GetOptions()
	return {
		"warmup",
		"stages",
		"berserk",
		"submerge",
		"emerge",
		"adds",
		67574, -- Pursue
		pursueMarker,
		{66012, "TANK_HEALER"}, -- Freezing Slash
		66013, -- Penetrating Cold
		coldMarker,
		66134, -- Shadow Strike
		{10278, "OFF"}, -- Hand of Protection
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "Pursue", 67574)
	self:Log("SPELL_AURA_REFRESH", "Pursue", 67574)
	self:Log("SPELL_AURA_APPLIED", "PenetratingCold", 66013, 67700, 68509, 68510)
	self:Log("SPELL_AURA_REFRESH", "PenetratingCold", 66013, 67700, 68509, 68510)
	self:Log("SPELL_AURA_REMOVED", "PenetratingColdRemoved", 66013, 67700, 68509, 68510)
	self:Log("SPELL_AURA_APPLIED", "FreezingSlash", 66012)
	self:Log("SPELL_CAST_SUCCESS", "FreezingSlashSuccess", 66012)
	self:Log("SPELL_AURA_APPLIED", "HandOfProtection", 10278)
	self:Log("SPELL_AURA_REMOVED", "HandOfProtectionRemoved", 10278)
	self:Log("SPELL_CAST_START", "Swarm", 66118, 67630, 68646, 68647)
	self:Log("SPELL_CAST_START", "ShadowStrike", 66134)
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
	self:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE")
end

function mod:OnEngage()
	burrowed = false
	self:SetStage(1)
	self:StopBar(L.roleplay)
	self:Bar("adds", 10, L.adds, L.adds_icon)
	self.addsTimer = self:ScheduleTimer("Adds", 10)
	self:DelayedMessage("submerge", 70, "yellow", L.submerge_soon, L.submerge_icon)
	self:Bar("submerge", 80, L.submerge, L.submerge_icon)
	self:Berserk(self:Difficulty() == 3 and 660 or 570)
	self:CDBar(66012, 15)
	if self:Heroic() then
		self:Bar(66134, 30)
		self:DelayedMessage(66134, 25.5, "orange", CL.soon:format(self:SpellName(66134)))
		self.strikeTimer = self:ScheduleTimer("ShadowStrikeTimer", 30)
	end
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:Adds()
	-- adds every 45 seconds while Anub'arak is above ground
	if self:IsEngaged() and not burrowed then
		self:Message("adds", "orange", L.adds, L.adds_icon)
		self:Bar("adds", 45, L.adds, L.adds_icon)
		self.addsTimer = self:ScheduleTimer("Adds", 45)
	end
end

function mod:ShadowStrikeTimer()
	self:CancelTimer(self.strikeTimer)
	if self:IsEngaged() then
		self:Bar(66134, 30)
		self:DelayedMessage(66134, 25.5, "orange", CL.soon:format(self:SpellName(66134)))
		self.strikeTimer = self:ScheduleTimer("ShadowStrikeTimer", 30)
	end
end

function mod:Emerge()
	self:CancelTimer(self.emergeTimer)
	self:SetStage(1)
	burrowed = false
	self:StopBar(L.emerge)
	self:Bar("adds", 5, L.adds, L.adds_icon)
	self:CancelTimer(self.addsTimer)
	self.addsTimer = self:ScheduleTimer("Adds", 5)
	self:Message("emerge", "cyan", L.emerge_message, L.emerge_icon)
	self:PlaySound("emerge", "info")
	self:DelayedMessage("submerge", 70, "yellow", L.submerge_soon, L.submerge_icon)
	self:Bar("submerge", 80, L.submerge, L.submerge_icon)
	if self:Heroic() then
		self:ShadowStrikeTimer()
	end
end

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if msg:find(L.roleplay_trigger, nil, true) then
		self:Bar("warmup", 47.5, L.roleplay, 43827)
	elseif msg == L.burrow_trigger and self:IsEngaged() then -- DBM Sirus: the submerge emote does not always fire
		self:SetStage(2)
		burrowed = true
		self:CancelTimer(self.addsTimer)
		self:StopBar(L.adds)
		self:Message("submerge", "cyan", L.submerge_message, L.submerge_icon)
		self:PlaySound("submerge", "long")
		self:DelayedMessage("emerge", 58.5, "yellow", L.emerge_soon, L.emerge_icon)
		self:Bar("emerge", 65, L.emerge, L.emerge_icon)
		self:StopBar(66012)
		if self:Heroic() then
			self:CancelTimer(self.strikeTimer)
			self:StopBar(66134)
			self:CancelDelayedMessage(CL.soon:format(self:SpellName(66134)))
		end
		-- DBM Sirus: the emerge emote does not always fire either
		self.emergeTimer = self:ScheduleTimer("Emerge", 65)
	end
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(_, msg)
	if msg:find(L.emerge_trigger, nil, true) and self:IsEngaged() then
		self:Emerge()
	end
end

function mod:Pursue(args)
	if self:Me(args.destGUID) then
		self:PersonalMessage(67574)
		self:PlaySound(67574, "alarm") -- run, keep moving
	else
		self:TargetMessage(67574, "red", args.destName)
	end
	self:CustomIcon(pursueMarker, args.destName, 8)
	self:ScheduleTimer("CustomIcon", 15, pursueMarker, args.destName)
end

function mod:PenetratingCold(args)
	if args.time - prevCold > 3 then
		coldIcon = 1
		self:Bar(66013, 15)
	end
	prevCold = args.time
	if self:Me(args.destGUID) then
		self:PersonalMessage(66013)
		self:PlaySound(66013, "warning")
	end
	if coldIcon <= (is25(self) and 5 or 2) then
		self:CustomIcon(coldMarker, args.destName, coldIcon)
		coldIcon = coldIcon + 1
	end
end

function mod:PenetratingColdRemoved(args)
	self:CustomIcon(coldMarker, args.destName)
end

function mod:FreezingSlash(args)
	self:TargetMessage(66012, "purple", args.destName)
end

function mod:FreezingSlashSuccess()
	-- one log had no SPELL_AURA_APPLIED for a cast, so the timer starts here (DBM)
	self:CDBar(66012, 20)
end

function mod:HandOfProtection(args)
	if self:IsEngaged() then
		self:TargetMessage(10278, "green", args.destName)
		self:TargetBar(10278, 10, args.destName)
	end
end

function mod:HandOfProtectionRemoved(args)
	self:StopBar(10278, args.destName)
end

function mod:Swarm(args) -- stage 3
	self:SetStage(3)
	self:Message("stages", "cyan", CL.stage:format(3), false)
	self:PlaySound("stages", "long")
	self:CancelTimer(self.emergeTimer)
	self:CancelDelayedMessage(L.emerge_soon)
	self:CancelDelayedMessage(L.submerge_soon)
	self:StopBar(L.emerge)
	self:StopBar(L.submerge)
	if self:Normal() then -- adds keep coming on heroic
		self:CancelTimer(self.addsTimer)
		self:StopBar(L.adds)
	end
end

function mod:ShadowStrike(args)
	if self:Heroic() and args.time - prevShadowStrike > 2 then
		prevShadowStrike = args.time
		self:ShadowStrikeTimer()
		self:Message(66134, "red")
		if self:Tank() then
			self:PlaySound(66134, "alarm")
		end
	end
end
