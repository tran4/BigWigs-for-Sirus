--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-MC/Ragnaros.lua)
-- The summoning roleplay timer needs the module to be enabled: the Majordomo Executus victory enables it,
-- or targeting Ragnaros. Not ported: the speed clear timer.

local mod, CL = BigWigs:NewBoss("Ragnaros Classic", 409, 1528)
if not mod then return end
mod:RegisterEnableMob(11502)
mod:SetEncounterID(672)

--------------------------------------------------------------------------------
-- Locals
--

local sonsLeft = 0
local emerged = true
local deadSons = {}

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	submerge_trigger = "COME FORTH, MY SERVANTS! DEFEND YOUR MASTER!",
	pull_trigger = "Impudent whelps! You've rushed headlong to your own deaths! See now, the master stirs!", -- DBM: ends with \r\n

	submerge = "Submerge",
	submerge_desc = "Show warning and timer for submerge",
	submerge_icon = "misc_arrowdown",
	emerge = "Emerge",
	emerge_desc = "Show warning and timer for emerge",
	emerge_icon = "misc_arrowlup",
})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"warmup",
		20566, -- Wrath of Ragnaros
		"submerge",
		"emerge",
		"proximity",
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "SummonRagnaros", 19774)
	self:Log("SPELL_CAST_SUCCESS", "DomoDeath", 19773)
	self:Log("SPELL_CAST_SUCCESS", "WrathOfRagnaros", 20566)
	self:Death("SonDeath", 12143) -- Son of Flame
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
end

function mod:OnEngage()
	sonsLeft = 0
	emerged = true
	deadSons = {}
	self:CDBar(20566, 26.7)
	self:Bar("submerge", 180, L.submerge, L.submerge_icon)
	if not self:Melee() then -- DBM: range frame for non-melee
		self:OpenProximity("proximity", 18)
	end
end

--------------------------------------------------------------------------------
-- Event Handlers
--

do
	local prev = 0
	function mod:Warmup()
		local t = GetTime()
		if t - prev > 5 then
			prev = t
			self:Bar("warmup", 78, CL.active, "inv_misc_pocketwatch_01")
		end
	end
end

function mod:SummonRagnaros()
	self:Warmup()
end

function mod:DomoDeath()
	-- DBM: the time between the death of Majordomo and Ragnaros becoming attackable is always 10s
	if self:BarTimeLeft(CL.active) > 0 then
		self:Bar("warmup", 10, CL.active, "inv_misc_pocketwatch_01")
	end
end

function mod:WrathOfRagnaros(args)
	self:Message(20566, "orange")
	self:CDBar(20566, 25)
end

function mod:Emerged()
	emerged = true
	self:CancelTimer(self.emergeTimer)
	self:StopBar(L.emerge)
	self:Message("emerge", "cyan", L.emerge, L.emerge_icon)
	self:PlaySound("emerge", "info")
	self:CDBar(20566, 26.7)
	self:Bar("submerge", 180, L.submerge, L.submerge_icon)
end

function mod:SonDeath(args)
	if not self:IsEngaged() or deadSons[args.destGUID] then return end
	deadSons[args.destGUID] = true
	sonsLeft = sonsLeft - 1
	if not emerged and sonsLeft == 0 then -- DBM: he emerges at once when all 8 are dead
		self:Emerged()
	end
end

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if msg == L.submerge_trigger then
		if not self:IsEngaged() then return end
		emerged = false
		self:CancelTimer(self.emergeTimer)
		self:StopBar(20566)
		self:StopBar(L.submerge)
		self:Message("submerge", "cyan", L.submerge, L.submerge_icon)
		self:PlaySound("submerge", "long")
		self:Bar("emerge", 90, L.emerge, L.emerge_icon)
		self.emergeTimer = self:ScheduleTimer("Emerged", 90)
		sonsLeft = sonsLeft + 8
	elseif msg:find(L.pull_trigger, nil, true) then
		self:Warmup()
	end
end
