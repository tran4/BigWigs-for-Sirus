--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-AQ40/Ouro.lua)

local mod, CL = BigWigs:NewBoss("Ouro", 531, 1550)
if not mod then return end
mod:RegisterEnableMob(15517)
mod:SetEncounterID(716)

--------------------------------------------------------------------------------
-- Locals
--

local warnedSoon, berserked = false, false

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	submerge = "Submerge",
	submerge_desc = "Show warning for submerge, show timer for when submerge will be forced. Note: He can still submerge at any time what so ever if his target leaves melee range.",
	submerge_icon = "misc_arrowdown",
	submerge_bar = "Forced Submerge",
	emerge = "Emerge",
	emerge_desc = "Show warning and timer for emerge",
	emerge_icon = "misc_arrowlup",
})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"submerge",
		"emerge",
		26103, -- Sweep
		26102, -- Sand Blast
		26615, -- Berserk
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "SandBlast", 26102)
	self:Log("SPELL_CAST_START", "Sweep", 26103)
	self:Log("SPELL_CAST_SUCCESS", "Submerge", 26058)
	self:Log("SPELL_AURA_APPLIED", "Berserk", 26615)
	self:RegisterEvent("UNIT_HEALTH")
end

function mod:OnEngage()
	warnedSoon, berserked = false, false
	self:Bar(26103, 22)
	self:Bar(26102, 20)
	self:Bar("submerge", 184, L.submerge_bar, L.submerge_icon)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:SandBlast(args)
	self:Message(26102, "red")
	self:PlaySound(26102, "alarm") -- DBM: stun soon
	self:Bar(26102, 23)
end

function mod:Sweep(args)
	if self:Hostile(args.sourceFlags) then
		if self:Tank() then -- DBM: the warning for tanks only
			self:Message(26103, "purple")
		end
		self:Bar(26103, 20.5)
	end
end

function mod:Emerge()
	self:Message("emerge", "cyan", L.emerge, L.emerge_icon)
	self:PlaySound("emerge", "info")
	self:Bar(26103, 23)
	self:Bar(26102, 24)
	self:Bar("submerge", 184, L.submerge_bar, L.submerge_icon)
end

do
	local prev = 0
	function mod:Submerge(args)
		if args.time - prev > 3 and not berserked then
			prev = args.time
			self:StopBar(26102)
			self:StopBar(26103)
			self:StopBar(L.submerge_bar)
			self:Message("submerge", "cyan", L.submerge, L.submerge_icon)
			self:PlaySound("submerge", "long")
			self:Bar("emerge", 30, L.emerge, L.emerge_icon)
			self:ScheduleTimer("Emerge", 30)
		end
	end
end

function mod:Berserk(args)
	if not self:Player(args.destFlags) then
		berserked = true
		self:Message(26615, "red")
		self:StopBar(L.submerge_bar)
	end
end

function mod:UNIT_HEALTH(_, unit)
	if not warnedSoon and self:IsEngaged() and self:MobId(self:UnitGUID(unit)) == 15517 and self:GetHealth(unit) <= 23 then
		warnedSoon = true
		self:Message(26615, "yellow", CL.soon:format(self:SpellName(26615)))
	end
end
