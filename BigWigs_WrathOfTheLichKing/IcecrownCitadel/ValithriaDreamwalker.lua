--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Icecrown/FrostwingHalls/Valithria.lua), draft by tools/dbm2bw

local mod, CL = BigWigs:NewBoss("Valithria Dreamwalker", 631, 1634)
if not mod then return end
mod:RegisterEnableMob(36789)
mod:SetEncounterID(854)
mod:SetWinMobs() -- 3.3.5: won when she casts Dreamwalker's Rage, her death is a wipe

--------------------------------------------------------------------------------
-- Locals
--

local portalCount = 0
local skeletonTimer = 60
local abomTimer = 60
local abomCount = 0
local suppressorWave = 0
local gutSprayList = {}
local prevGutSpray = 0
local prevSuppression = 0
local prevManaVoid = 0
local skeletonsToMark = {} -- [guid] = true

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	engage_trigger = "Intruders have breached the inner sanctum. Hasten the destruction of the green dragon! Leave only bones and sinew for the reanimation!",
	portals_trigger = "I have opened a portal into the Dream. Your salvation lies within, heroes...",

	portals_open = "Portals open",
	portals_close = "Portals close",
	-- 3.3.5: the portals opening/closing apart from the Nightmare Portal cooldown (DBM: TimerPortalsOpen, WarnPortalOpen)
	portals = "Portals open/close",
	portals_desc = "Bars and messages for the opening and the closing of the portals.",
})

--------------------------------------------------------------------------------
-- Initialization
--

local skeletonMarker = mod:AddMarkerOption(true, "npc", 8, 70933, 8) -- Blazing Skeleton
function mod:GetOptions()
	return {
		"berserk",
		{72483, "OFF"}, -- Nightmare Portal (3.3.5: the cooldown bar, off by default on request)
		"portals", -- 3.3.5: portals open/close
		{70873, "ME_ONLY"}, -- Emerald Vigor
		70933, -- Summon Blazing Skeleton
		skeletonMarker,
		70922, -- Summon Gluttonous Abomination
		70935, -- Summon Suppresser
		69325, -- Lay Waste
		{70633, "TANK_HEALER"}, -- Gut Spray
		{70751, "OFF"}, -- Corrosion
		71179, -- Mana Void
		70588, -- Suppression
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "DreamwalkersRage", 71189)
	self:Log("SPELL_CAST_START", "BlazingSkeletonFireball", 70754, 71748, 72023, 72024)
	self:Log("SPELL_CAST_SUCCESS", "ManaVoid", 71179)
	self:Log("SPELL_DAMAGE", "ManaVoidDamage", 71086, 71743, 72030)
	self:Log("SPELL_MISSED", "ManaVoidDamage", 71086, 71743, 72030)
	self:Log("SPELL_CAST_SUCCESS", "Suppression", 70588)
	self:Log("SPELL_AURA_APPLIED", "GutSpray", 70633, 71283, 72025, 72026)
	self:Log("SPELL_AURA_APPLIED", "Corrosion", 70751, 71738, 72022, 72023)
	self:Log("SPELL_AURA_APPLIED_DOSE", "Corrosion", 70751, 71738, 72022, 72023)
	self:Log("SPELL_AURA_APPLIED", "LayWaste", 69325, 71730)
	self:Log("SPELL_AURA_REMOVED", "LayWasteRemoved", 69325, 71730)
	self:Log("SPELL_AURA_APPLIED", "EmeraldVigor", 70873, 71941)
	self:Log("SPELL_AURA_APPLIED_DOSE", "EmeraldVigor", 70873, 71941)
	self:Log("SPELL_AURA_REMOVED", "EmeraldVigorRemoved", 70873, 71941)
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
end

function mod:OnEngage()
	portalCount = 0
	skeletonTimer = 60
	abomTimer = 60
	abomCount = 0
	suppressorWave = 1
	gutSprayList = {}
	skeletonsToMark = {}
	if self:Heroic() then
		self:Berserk(420)
	end
	self:CDBar(72483, 46.5, CL.count:format(self:SpellName(72483), 1))
	self:DelayedMessage(72483, 41, "yellow", CL.soon:format(self:SpellName(72483)))
	self.portalTimer = self:ScheduleTimer("Portals", 46.5) -- never perfect, varies between 45 and 48 seconds
	self:Bar(70933, 30)
	self:ScheduleTimer("BlazingSkeletonTimer", 30)
	self:Bar(70922, 5, CL.count:format(self:SpellName(70922), 1))
	self:ScheduleTimer("AbominationTimer", 5)
	self:Bar(70935, 30, CL.count:format(self:SpellName(70935), 1))
	self.suppressorTimer = self:ScheduleTimer("Suppressers", 30)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:DreamwalkersRage()
	self:Win() -- DBM EndCombat
end

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if msg:find(L.engage_trigger, nil, true) then
		self:Engage()
	elseif msg:find(L.portals_trigger, nil, true) and self:IsEngaged() then
		self:Portals()
	end
end

-- Timers (DBM Sirus sequences)

function mod:Portals()
	self:CancelTimer(self.portalTimer)
	-- 3.3.5: a cooldown bar stays at 0 until stopped, the next one has another count in its text
	self:StopBar(CL.count:format(self:SpellName(72483), portalCount + 1))
	self:Message(72483, "yellow")
	self:PlaySound(72483, "info")
	self:Bar("portals", 15, L.portals_open, 72483)
	self:ScheduleTimer("PortalsOpen", 15)
	self:DelayedMessage(72483, 41, "yellow", CL.soon:format(self:SpellName(72483)))
	portalCount = portalCount + 1
	self:CDBar(72483, 46.5, CL.count:format(self:SpellName(72483), portalCount + 1))
	self.portalTimer = self:ScheduleTimer("Portals", 46.5)
end

function mod:PortalsOpen()
	self:Message("portals", "orange", L.portals_open, 72483)
	self:PlaySound("portals", "info")
	self:Bar("portals", 10, L.portals_close, 72483)
end

function mod:BlazingSkeletonTimer()
	self:Bar(70933, skeletonTimer)
	self:ScheduleTimer("BlazingSkeletonTimer", skeletonTimer)
	if skeletonTimer >= 10 then -- never below 5
		skeletonTimer = skeletonTimer - 5
	end
end

function mod:AbominationTimer()
	abomCount = abomCount + 1
	self:Bar(70922, abomTimer, CL.count:format(self:SpellName(70922), abomCount + 1))
	self:ScheduleTimer("AbominationTimer", abomTimer)
	if abomCount == 1 then
		abomTimer = abomTimer - 5 -- 60 after the first one, then 55
	elseif abomCount >= 4 and abomTimer >= 10 then
		abomTimer = abomTimer - 5 -- 5 less every time after the 3rd 55 second timer
	end
end

function mod:Suppressers()
	self:Message(70935, "orange", CL.count:format(self:SpellName(70935), suppressorWave))
	self:PlaySound(70935, "alert")
	suppressorWave = suppressorWave + 1
	local t = suppressorWave == 2 and 58 or suppressorWave == 3 and 62 or 50
	self:Bar(70935, t, CL.count:format(self:SpellName(70935), suppressorWave))
	self.suppressorTimer = self:ScheduleTimer("Suppressers", t)
end

-- Blazing Skeleton marking: its first spell is Fireball

function mod:MarkSkeleton(_, unit, guid)
	if skeletonsToMark[guid] then
		skeletonsToMark[guid] = nil
		self:CustomIcon(skeletonMarker, unit, 8)
		if not next(skeletonsToMark) then
			self:UnregisterTargetEvents()
		end
	end
end

function mod:BlazingSkeletonFireball(args)
	if self:GetOption(skeletonMarker) and not skeletonsToMark[args.sourceGUID] then
		skeletonsToMark[args.sourceGUID] = true
		self:RegisterTargetEvents("MarkSkeleton")
	end
end

-- Abilities

function mod:ManaVoid(args)
	self:Message(71179, "yellow")
end

function mod:ManaVoidDamage(args)
	if self:Me(args.destGUID) and args.time - prevManaVoid > 2 then
		prevManaVoid = args.time
		self:PersonalMessage(71179, "underyou")
		self:PlaySound(71179, "underyou")
	end
end

function mod:Suppression(args)
	if args.time - prevSuppression > 5 then
		prevSuppression = args.time
		self:Message(70588, "yellow")
	end
end

function mod:GutSpray(args)
	if not self:Player(args.destFlags) then return end
	if args.time - prevGutSpray > 3 then
		gutSprayList = {}
	end
	prevGutSpray = args.time
	gutSprayList[#gutSprayList + 1] = args.destName
	self:TargetsMessage(70633, "orange", gutSprayList, nil, nil, nil, 0.3)
	if self:Me(args.destGUID) and self:Tank() then
		self:PlaySound(70633, "alarm")
	end
end

function mod:Corrosion(args)
	if self:Player(args.destFlags) then
		self:StackMessage(70751, "yellow", args.destName, args.amount or 1, 99)
	end
end

function mod:LayWaste(args)
	self:Message(69325, "orange")
	self:PlaySound(69325, "long")
	self:CastBar(69325, 12)
end

function mod:LayWasteRemoved()
	self:StopCastBar(69325)
end

function mod:EmeraldVigor(args) -- also Twisted Nightmares, portal healers
	if self:Me(args.destGUID) then
		self:TargetBar(70873, 40, args.destName)
	end
end

function mod:EmeraldVigorRemoved(args)
	if self:Me(args.destGUID) then
		self:StopBar(70873, args.destName)
	end
end
