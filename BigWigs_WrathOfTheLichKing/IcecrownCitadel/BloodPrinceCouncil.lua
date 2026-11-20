--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Icecrown/TheCrimsonHall/BPCouncil.lua), draft by tools/dbm2bw
-- Not ported: the DBM arrow away from Shock Vortex, the skull on the empowered prince, the Shadow Prison metronome.

local mod, CL = BigWigs:NewBoss("Blood Prince Council", 631, 1632)
if not mod then return end
mod:RegisterEnableMob(37970, 37972, 37973) -- Valanar, Keleseth, Taldaram
mod:SetEncounterID(852)
mod:SetWinMobs(37970, 37972, 37973) -- 3.3.5: DBM kills when all of them died

--------------------------------------------------------------------------------
-- Locals
--

local prevSparks = 0
local bombIcon = 7
local bombsMarked = {} -- [guid] = true

local function is10(self)
	local diff = self:Difficulty()
	return diff == 3 or diff == 5
end

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	warmup_trigger = "Foolish mortals. You thought us defeated so easily? The San'layn are the Lich King's immortal soldiers! Now you shall face their might combined!",
	empowered_flames_trigger = "Empowered Flames speed toward (%S+)!",

	keleseth = "Prince Keleseth",
	taldaram = "Prince Taldaram",
	valanar = "Prince Valanar",

	switch = "Target switch",
	switch_desc = "Show warning and timer to switch targets",
	switch_icon = 70952,
	switch_message = "Switch target to: %s",
	switch_soon = "Target switch soon",
})
mod:SetChatEnableTriggers(L.warmup_trigger) -- 3.3.5: enable the module on the warmup yell/emote (no target yet)

--------------------------------------------------------------------------------
-- Initialization
--

local flamesMarker = mod:AddMarkerOption(true, "player", 1, 72040, 1) -- Empowered Flames
local bombMarker = mod:AddMarkerOption(true, "npc", 7, 72053, 7, 6, 5) -- Kinetic Bomb
function mod:GetOptions()
	return {
		"warmup",
		"berserk",
		"switch",
		"proximity",
		{72999, "ME_ONLY"}, -- Shadow Prison
		72053, -- Kinetic Bomb
		bombMarker,
		-- Prince Valanar
		{72037, "SAY"}, -- Shock Vortex
		72039, -- Empowered Shock Vortex
		-- Prince Taldaram
		71718, -- Conjure Flames
		{72040, "SAY"}, -- Conjure Empowered Flames
		flamesMarker,
		71807, -- Glittering Sparks
		-- Prince Keleseth
		{71943, "OFF"}, -- Dark Nucleus
	}, {
		[72037] = L.valanar,
		[71718] = L.taldaram,
		[71943] = L.keleseth,
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "InvocationValanar", 70952)
	self:Log("SPELL_AURA_APPLIED", "InvocationKeleseth", 70981)
	self:Log("SPELL_AURA_APPLIED", "InvocationTaldaram", 70982)
	self:Log("SPELL_CAST_START", "ShockVortex", 72037)
	self:Log("SPELL_CAST_START", "EmpoweredShockVortex", 72039, 73037, 73038, 73039)
	self:Log("SPELL_CAST_START", "ConjureFlames", 71718)
	self:Log("SPELL_CAST_START", "ConjureEmpoweredFlames", 72040)
	self:Log("SPELL_AURA_APPLIED", "ShadowPrison", 72999)
	self:Log("SPELL_AURA_APPLIED_DOSE", "ShadowPrison", 72999)
	self:Log("SPELL_AURA_APPLIED", "GlitteringSparks", 71807, 72796, 72797, 72798)
	self:Log("SPELL_SUMMON", "DarkNucleus", 71943)
	self:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE")
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
	self:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", nil, "boss1", "boss2", "boss3")
end

function mod:OnEngage()
	bombIcon = 7
	self:StopBar(CL.active)
	self:Berserk(600)
	self:DelayedMessage("switch", 42, "cyan", L.switch_soon, L.switch_icon)
	self:Bar("switch", 47, L.switch, L.switch_icon)
	self:CDBar(72039, 15)
	self:CDBar(72053, 20)
	self:OpenProximity("proximity", 12)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if msg:find(L.warmup_trigger, nil, true) then
		self:Bar("warmup", 22, CL.active, "inv_misc_pocketwatch_01") -- roleplay for the first pull
	end
end

function mod:TargetSwitch(name)
	self:Message("switch", "cyan", L.switch_message:format(name), L.switch_icon)
	self:PlaySound("switch", "info")
	self:DelayedMessage("switch", 42, "cyan", L.switch_soon, L.switch_icon)
	self:Bar("switch", 47, L.switch, L.switch_icon)
end

function mod:InvocationValanar()
	if not self:IsEngaged() then return end
	self:TargetSwitch(L.valanar)
	if self:BarTimeLeft(72039) == 0 then -- don't overwrite the first vortex
		local left = self:BarTimeLeft(72037)
		self:CDBar(72039, left > 0 and left or 20)
	end
	self:StopBar(72037)
	self:CancelTimer(self.proximityTimer)
	self:OpenProximity("proximity", 12)
end

function mod:CloseVortexProximity()
	self:CloseProximity("proximity")
end

function mod:InvocationOther(name)
	if not self:IsEngaged() then return end
	self:TargetSwitch(name)
	if self:BarTimeLeft(72037) == 0 then
		local left = self:BarTimeLeft(72039)
		self:CDBar(72037, left > 0 and left or 20)
		self:StopBar(72039)
	end
	-- delayed in case Valanar got a last second vortex off
	self.proximityTimer = self:ScheduleTimer("CloseVortexProximity", 4.5)
end

function mod:InvocationKeleseth()
	self:InvocationOther(L.keleseth)
end

function mod:InvocationTaldaram()
	self:InvocationOther(L.taldaram)
end

do
	local function printTarget(self, name, guid)
		if self:Me(guid) then
			self:PersonalMessage(72037)
			self:PlaySound(72037, "warning")
			self:Say(72037)
		else
			local unit = self:UnitTokenFromGUID(guid)
			if unit and CheckInteractDistance(unit, 2) then
				self:Message(72037, "orange", CL.near:format(self:SpellName(72037)))
				self:PlaySound(72037, "alarm")
			else
				self:TargetMessage(72037, "yellow", name)
			end
		end
	end
	function mod:ShockVortex(args)
		self:CDBar(72037, 20)
		self:GetUnitTarget(printTarget, 0.4, args.sourceGUID)
	end
end

function mod:EmpoweredShockVortex(args)
	self:Message(72039, "red")
	self:PlaySound(72039, "alarm") -- spread
	self:CDBar(72039, 30)
end

function mod:ConjureFlames(args)
	self:Message(71718, "yellow", CL.casting:format(args.spellName))
	self:CDBar(71718, 20)
end

function mod:ConjureEmpoweredFlames(args)
	self:Message(72040, "orange", CL.casting:format(args.spellName))
	self:CDBar(71718, 20)
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(_, msg, _, _, _, target)
	if target and msg:match(L.empowered_flames_trigger) then
		if target == self:UnitName("player") then
			self:PersonalMessage(72040)
			self:PlaySound(72040, "alarm")
			self:Say(72040)
		else
			self:TargetMessage(72040, "orange", target)
		end
		self:CustomIcon(flamesMarker, target, 1)
		self:ScheduleTimer("CustomIcon", 10, flamesMarker, target)
	end
end

function mod:ShadowPrison(args)
	if self:Me(args.destGUID) then
		local amount = args.amount or 1
		self:TargetBar(72999, 10, args.destName)
		if amount >= 10 then
			self:StackMessage(72999, "blue", args.destName, amount, 10)
			self:PlaySound(72999, "alarm")
		end
	end
end

function mod:GlitteringSparks(args)
	if not self:Player(args.destFlags) then return end
	if args.time - prevSparks > 3 then
		self:CDBar(71807, 20)
	end
	prevSparks = args.time
	-- 3.3.5: no message with the list of the targets, it hits most of the raid (user's request), only the bar
end

function mod:DarkNucleus(args)
	self:Message(71943, "cyan")
	self:CDBar(71943, 10)
end

-- Kinetic Bomb

function mod:MarkBombs(_, unit, guid)
	if self:MobId(guid) == 38454 and not bombsMarked[guid] then -- Kinetic Bomb
		bombsMarked[guid] = true
		self:CustomIcon(bombMarker, unit, bombIcon)
		bombIcon = bombIcon - 1
		if bombIcon < 5 then bombIcon = 7 end
	end
end

do
	local prev = nil
	function mod:UNIT_SPELLCAST_SUCCEEDED(_, _, castGUID, _, spellName)
		if spellName == self:SpellName(72080) and castGUID ~= prev then -- Kinetic Bomb
			prev = castGUID
			self:Message(72053, "orange")
			if self:Ranged() then
				self:PlaySound(72053, "info")
			end
			self:CDBar(72053, is10(self) and 27 or 18)
			if self:GetOption(bombMarker) then
				self:RegisterTargetEvents("MarkBombs")
			end
		end
	end
end
