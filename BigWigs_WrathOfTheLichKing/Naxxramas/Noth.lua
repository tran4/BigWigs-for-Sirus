--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Naxx/PlagueQuarter/Noth.lua), draft by tools/dbm2bw

local mod, CL = BigWigs:NewBoss("Noth the Plaguebringer", 533, 1604)
if not mod then return end
mod:RegisterEnableMob(15954)
mod:SetEncounterID(1117)

--------------------------------------------------------------------------------
-- Locals
--

local teleCount = 0
local addsCount = 0
local curseCount = 0
local onBalcony = false

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	engage_trigger = "Die, trespasser!",
	adds_trigger = "summons forth Skeletal Warriors!", -- boss in the room
	adds2_trigger = "raises more skeletons!", -- boss on the balcony

	teleport = "Teleport",
	teleport_desc = "Show warnings and timers for Teleport",
	teleport_icon = 46573,
	teleport_now = "Teleported",
	teleport_soon = "Teleport in 20 seconds",
	teleport_back = "Teleport back",
})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"teleport",
		29213, -- Curse of the Plaguebringer
		29214, -- Wrath of the Plaguebringer (WA)
		29208, -- Blink
		"adds",
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_SUCCESS", "CurseOfThePlaguebringer", 29213, 54835)
	self:Log("SPELL_AURA_APPLIED", "Blink", 29208, 29209, 29210, 29211)
	self:Log("SPELL_AURA_APPLIED", "PlaguebringerOnYou", 29213, 54835, 372056, 29214, 54836, 372057) -- WA: 372056/372057 heroic (the spell cache of WeakAuras)
	self:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE")
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
	self:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", nil, "boss1")
end

function mod:OnEngage()
	teleCount, addsCount, curseCount = 0, 0, 0
	onBalcony = false
	self:Bar("adds", 7, CL.adds, 29212)
	self:CDBar(29213, 9.5)
	self:Bar("teleport", 90.8, L.teleport, L.teleport_icon)
	self:DelayedMessage("teleport", 70.8, "yellow", L.teleport_soon, L.teleport_icon)
	self:ScheduleTimer("Balcony", 90.8)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if msg == L.engage_trigger and not self:IsEngaged() then
		self:Engage() -- DBM RegisterCombat("combat_yell")
	end
end

function mod:Balcony()
	teleCount = teleCount + 1
	addsCount = 0
	onBalcony = true
	self:StopBar(29213)
	self:StopBar(CL.adds)
	self:StopBar(29208)
	local timer
	if teleCount == 1 then
		timer = 70
		self:Bar("adds", 5, CL.adds, 29212)
	elseif teleCount == 2 then
		timer = 97
		self:Bar("adds", 5, CL.adds, 29212)
	elseif teleCount == 3 then
		timer = 126
		self:Bar("adds", 5, CL.adds, 29212)
	else
		timer = 55
	end
	self:Message("teleport", "orange", L.teleport_now, L.teleport_icon)
	self:Bar("teleport", timer, L.teleport_back, L.teleport_icon)
	self:DelayedMessage("teleport", timer - 20, "yellow", L.teleport_soon, L.teleport_icon)
	-- 3.3.5: DBM sees the return by the boss1 cast, without boss1 units it may be missed - return by the timer then
	self:ScheduleTimer("TeleportReturn", timer + 2)
end

function mod:UNIT_SPELLCAST_SUCCEEDED(_, _, _, _, spellName)
	if spellName == self:SpellName(29231) then -- Teleport Return
		self:TeleportReturn()
	end
end

function mod:TeleportReturn()
	if not onBalcony then return end
	onBalcony = false
	addsCount = 0
	curseCount = 0
	self:StopBar(CL.adds)
	local timer
	if teleCount == 1 then
		timer = 109
		self:Bar("adds", 10, CL.adds, 29212)
	elseif teleCount == 2 then
		timer = 173
		self:Bar("adds", 17, CL.adds, 29212)
	elseif teleCount == 3 then
		timer = 93
	else
		timer = 35
	end
	self:StopBar(L.teleport_back)
	self:Bar("teleport", timer, L.teleport, L.teleport_icon)
	self:DelayedMessage("teleport", timer - 20, "yellow", L.teleport_soon, L.teleport_icon)
	self:Message("teleport", "orange", L.teleport_now, L.teleport_icon)
	self:PlaySound("teleport", "info")
	self:CDBar(29213, teleCount == 4 and 17 or 11)
	self:ScheduleTimer("Balcony", timer)
end

function mod:CurseOfThePlaguebringer(args)
	curseCount = curseCount + 1
	self:Message(29213, "yellow")
	if teleCount == 2 and curseCount == 2 or teleCount == 3 and curseCount == 1 then
		self:CDBar(29213, 67) -- DBM: niche cases it's 67 and not 53-55
	elseif curseCount < 2 then
		self:CDBar(29213, 53.3)
	end
end

function mod:Blink()
	self:Message(29208, "orange")
	self:CDBar(29208, 25)
	self:DelayedMessage(29208, 26, "yellow", CL.soon:format(self:SpellName(29208)))
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(_, msg)
	if not self:IsEngaged() then return end
	if msg:find(L.adds_trigger, nil, true) then -- boss in the room
		addsCount = addsCount + 1
		self:Message("adds", "red", CL.adds, 29212)
		if not self:Healer() then self:PlaySound("adds", "alert") end
		if teleCount == 0 and addsCount < 3 then -- 3 waves 30 seconds apart
			self:Bar("adds", 30, CL.adds, 29212)
		elseif teleCount == 1 and addsCount == 1 then -- DBM: 34 (then 47, never shown by DBM)
			self:Bar("adds", 33.9, CL.adds, 29212)
		elseif teleCount == 2 then -- 30, 32, 32, 30
			if addsCount == 1 or addsCount == 4 then
				self:Bar("adds", 30, CL.adds, 29212)
			elseif addsCount == 2 or addsCount == 3 then
				self:Bar("adds", 32, CL.adds, 29212)
			end
		end
	elseif msg:find(L.adds2_trigger, nil, true) then -- boss on the balcony
		addsCount = addsCount + 1
		self:Message("adds", "red", CL.adds, 29212)
		if not self:Healer() then self:PlaySound("adds", "alert") end
		-- no more adds on the 4th and later teleports, never more than 2 waves
		if teleCount < 4 and addsCount == 1 then
			if teleCount == 3 then
				self:Bar("adds", 60, CL.adds, 29212)
			elseif teleCount == 2 then
				self:Bar("adds", 46, CL.adds, 29212)
			else
				self:Bar("adds", 30, CL.adds, 29212)
			end
		end
	end
end

-- WA: "Naxx" (heroic), the curse and the wrath on you
function mod:PlaguebringerOnYou(args)
	if not self:Me(args.destGUID) then return end
	if args.spellId == 29213 or args.spellId == 54835 or args.spellId == 372056 then
		self:PersonalMessage(29213)
		self:PlaySound(29213, "alarm")
	else
		self:PersonalMessage(29214)
		self:PlaySound(29214, "warning")
	end
end
