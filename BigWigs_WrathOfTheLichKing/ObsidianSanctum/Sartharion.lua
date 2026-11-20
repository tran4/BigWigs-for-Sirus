--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-ChamberOfAspects/Obsidian/Sartharion.lua), draft by tools/dbm2bw
-- The drakes left alive are found 5s after the pull by their Power debuffs on the group (DBM). The Shadow Fissures of
-- the drakes are in the Drakes module. Not ported: posting the fails to the raid chat, the health frame.

local mod, CL = BigWigs:NewBoss("Sartharion", 615, 1616)
if not mod then return end
mod:RegisterEnableMob(28860)
mod:SetEncounterID(1090)

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	wall_trigger = "The lava surrounding %s churns!", -- raw emote text
	portal_trigger = "%s begins to open a Twilight Portal!",
	tenebron = "Tenebron",
	shadron = "Shadron",
	vesperon = "Vesperon",

	drakes = "Drakes",
	drakes_desc = "Show timers for the arrival of the drakes and their abilities",
	drakes_icon = 61248,
	tenebron_arrives = "Tenebron arrives",
	shadron_arrives = "Shadron arrives",
	vesperon_arrives = "Vesperon arrives",
	tenebron_incoming = "Tenebron incoming",
	shadron_incoming = "Shadron incoming",
	vesperon_incoming = "Vesperon incoming",
	whelps = "Tenebron Whelps",
	whelps_soon = "Tenebron Whelps Soon",
	shadron_portal = "Shadron Portal",
	shadron_portal_soon = "Shadron Portal Soon",
	vesperon_portal = "Vesperon Portal",
	vesperon_portal2 = "Vesperon Portal 2",
	reflect_soon = "Vesperon Reflect Soon",

	portals = "Portals",
	portals_desc = "Show special warning for the portals of the drakes",
	portals_icon = 57988,
	tenebron_portal_msg = "Tenebron's portal",
	shadron_portal_msg = "Shadron's portal",
	vesperon_portal_msg = "Vesperon's portal",
	fire_wall = "Fire Wall",
})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"drakes",
		{"portals", "OFF"},
		43113, -- Flame Tsunami (Fire Wall)
		{58956, "TANK_HEALER"}, -- Flame Breath
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "FlameBreath", 56908, 58956)
	self:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE")
	self:RegisterEvent("CHAT_MSG_MONSTER_EMOTE", "CHAT_MSG_RAID_BOSS_EMOTE")
end

function mod:OnEngage()
	self:ScheduleTimer("CheckDrakes", 5)
	self:Bar(43113, 30, L.fire_wall)
	self:DelayedMessage(58956, 5, "yellow", CL.soon:format(self:SpellName(58956)))
	self:CDBar(58956, 10)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

local function groupDebuffed(self, spellId)
	for unit in self:IterateGroup() do
		if self:UnitDebuff(unit, spellId) then return true end
	end
end

function mod:CheckDrakes()
	local delay = 5
	if groupDebuffed(self, 61248) then -- Power of Tenebron
		self:Bar("drakes", 26 - delay, L.tenebron_arrives, 61248)
		self:DelayedMessage("drakes", 21 - delay, "yellow", L.tenebron_incoming, 61248)
		self:Bar("drakes", 60 - delay, L.whelps, 1022)
		self:DelayedMessage("drakes", 55 - delay, "yellow", L.whelps_soon, 1022)
	end
	if groupDebuffed(self, 58105) then -- Power of Shadron
		self:Bar("drakes", 74 - delay, L.shadron_arrives, 58105)
		self:DelayedMessage("drakes", 69 - delay, "yellow", L.shadron_incoming, 58105)
		self:Bar("drakes", 94 - delay, L.shadron_portal, 11420)
		self:DelayedMessage("drakes", 89 - delay, "yellow", L.shadron_portal_soon, 11420)
	end
	if groupDebuffed(self, 61251) then -- Power of Vesperon
		self:Bar("drakes", 119 - delay, L.vesperon_arrives, 61251)
		self:DelayedMessage("drakes", 114 - delay, "yellow", L.vesperon_incoming, 61251)
		self:Bar("drakes", 139 - delay, L.vesperon_portal, 57988)
		self:Bar("drakes", 199 - delay, L.vesperon_portal2, 57988)
		self:DelayedMessage("drakes", 134 - delay, "yellow", L.reflect_soon, 57988)
		self:DelayedMessage("drakes", 194 - delay, "yellow", L.reflect_soon, 57988)
	end
end

function mod:FlameBreath()
	self:DelayedMessage(58956, 5.5, "yellow", CL.soon:format(self:SpellName(58956)))
	self:CDBar(58956, 10.5)
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(_, msg, mob)
	if not self:IsEngaged() then return end
	if msg:find(L.wall_trigger, nil, true) then
		self:Bar(43113, 30, L.fire_wall)
		self:Message(43113, "red", L.fire_wall)
		self:PlaySound(43113, "alarm")
	elseif msg:find(L.portal_trigger, nil, true) then
		local text = mob == L.vesperon and L.vesperon_portal_msg or mob == L.tenebron and L.tenebron_portal_msg
			or mob == L.shadron and L.shadron_portal_msg
		if text then
			self:Message("portals", "cyan", text, L.portals_icon)
			self:PlaySound("portals", "info")
		end
	end
end
