--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Ulduar/Razorscale.lua), draft by tools/dbm2bw

local mod, CL = BigWigs:NewBoss("Razorscale", 603, 1639)
if not mod then return end
mod:RegisterEnableMob(33186)
mod:SetEncounterID(746)

--------------------------------------------------------------------------------
-- Locals
--

local engageTime = 0
local grounded = false
local prevFlame = 0

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	engage_trigger = "Give us a moment to prepare to build the turrets.",
	air_trigger = "Fires out! Let's rebuild those turrets!",
	ground_trigger = "Move quickly! She won't remain grounded for long!",
	stage2_trigger = "%%s grounded permanently!",

	turrets = "Turrets",
	turrets_desc = "Show warnings and timers for the harpoon turrets",
	turrets_icon = 48642,
	turret = "Turret %d",
	turrets_soon = "Last turret ready in 20 seconds",
	turrets_ready = "Last turret ready",
	grounded = "On the ground",
	grounded_desc = "Show timer for ground phase duration",
	grounded_icon = 64021,
})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"stages",
		"berserk",
		"turrets",
		"grounded",
		64021, -- Flame Breath
		{64733, "SAY"}, -- Devouring Flame
		{64771, "TANK"}, -- Fuse Armor
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "FlameBreath", 63317, 64021)
	self:Log("SPELL_CAST_START", "DevouringFlame", 63236)
	self:Log("SPELL_DAMAGE", "DevouringFlameDamage", 64733, 64704)
	self:Log("SPELL_MISSED", "DevouringFlameDamage", 64733, 64704)
	self:Log("SPELL_AURA_APPLIED", "FuseArmor", 64771)
	self:Log("SPELL_AURA_APPLIED_DOSE", "FuseArmor", 64771)
	self:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", nil, "boss1")
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
	self:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE")
end

function mod:OnEngage()
	self:SetStage(1)
	grounded = false
	engageTime = GetTime()
	self:Berserk(840)
	self:Turrets(self:Difficulty() == 3 and {53, 73} or {53, 73, 93, 113})
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:Turrets(times)
	for i = 1, 4 do self:StopBar(L.turret:format(i)) end
	for i = 1, #times do
		self:Bar("turrets", times[i], L.turret:format(i), L.turrets_icon)
	end
	local last = times[#times]
	self:DelayedMessage("turrets", last - 20, "cyan", L.turrets_soon, L.turrets_icon)
	self:DelayedMessage("turrets", last, "green", L.turrets_ready, L.turrets_icon, "info")
end

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if msg == L.engage_trigger and not self:IsEngaged() then
		self:Engage() -- DBM RegisterCombat("yell")
	elseif self:IsEngaged() and grounded and (msg == L.engage_trigger or msg == L.air_trigger) and GetTime() - engageTime > 30 then
		-- back in the air, the turrets are rebuilt (DBM Sirus)
		grounded = false
		if self:Difficulty() == 3 then
			self:Turrets({23, 43})
		else
			self:Turrets({53, 73, 95, 115})
		end
	elseif msg == L.ground_trigger then
		grounded = true
		self:Bar("grounded", 35.5, L.grounded, L.grounded_icon)
	end
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(_, msg)
	if msg:find(L.stage2_trigger) then
		self:SetStage(2)
		self:Message("stages", "cyan", CL.stage:format(2), false)
		self:PlaySound("stages", "long")
		grounded = true
		for i = 1, 4 do self:StopBar(L.turret:format(i)) end
		self:CancelDelayedMessage(L.turrets_soon)
		self:CancelDelayedMessage(L.turrets_ready)
		self:StopBar(L.grounded)
		self:CDBar(64771, 15)
	end
end

function mod:FlameBreath(args)
	self:CastBar(64021, 2.5)
	self:CDBar(64021, 21)
end

do
	local function printTarget(self, name, guid)
		if self:Me(guid) then
			self:PersonalMessage(64733)
			self:PlaySound(64733, "warning")
			self:Say(64733)
		else
			local unit = self:UnitTokenFromGUID(guid)
			if unit and CheckInteractDistance(unit, 2) then
				self:Message(64733, "orange", CL.near:format(self:SpellName(64733)))
				self:PlaySound(64733, "alarm")
			end
		end
	end
	function mod:DevouringFlame(args)
		self:GetUnitTarget(printTarget, 0.1, args.sourceGUID)
	end
end

function mod:DevouringFlameDamage(args)
	if self:Me(args.destGUID) and args.time - prevFlame > 2.5 then
		prevFlame = args.time
		self:PersonalMessage(64733, "underyou")
		self:PlaySound(64733, "underyou")
	end
end

function mod:FuseArmor(args)
	local amount = args.amount or 1
	if amount >= 2 and self:Me(args.destGUID) then
		self:StackMessage(64771, "purple", args.destName, amount, 2)
		self:PlaySound(64771, "alarm")
	elseif amount >= 2 and self:Tank() and not self:UnitIsDeadOrGhost("player") and not UnitDebuff("player", args.spellName) then
		self:StackMessage(64771, "purple", args.destName, amount, 2)
		self:PlaySound(64771, "warning") -- taunt
	else
		self:StackMessage(64771, "purple", args.destName, amount, 2)
	end
end

do
	local prev = nil
	function mod:UNIT_SPELLCAST_SUCCEEDED(_, _, castGUID, _, spellName)
		if spellName == self:SpellName(64821) and castGUID ~= prev then -- Fuse Armor
			prev = castGUID
			self:CDBar(64771, 12.1)
		end
	end
end
