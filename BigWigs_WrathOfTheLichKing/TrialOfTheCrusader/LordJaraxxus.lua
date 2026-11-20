--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Coliseum/Jaraxxus.lua), draft by tools/dbm2bw
-- Not ported: the Incinerate Flesh absorb info frame and health bar.

local mod, CL = BigWigs:NewBoss("Lord Jaraxxus", 649, 1619)
if not mod then return end
mod:RegisterEnableMob(34780)
mod:SetEncounterID(633)

--------------------------------------------------------------------------------
-- Locals
--

local prevFlameDamage, prevInferno = 0, 0

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	-- 3.3.5: DBM Sirus has no English text for this yell
	warmup_trigger = "АГА! Получилось! Трепещи перед всевластным Вилфредом Непопамсом, мастером призыва! Ты покорен мне, демон!",
})
mod:SetChatEnableTriggers(L.warmup_trigger) -- 3.3.5: enable the module on the warmup yell/emote (no target yet)

--------------------------------------------------------------------------------
-- Initialization
--

local flameMarker = mod:AddMarkerOption(true, "player", 7, 66197, 7) -- Legion Flame
local fleshMarker = mod:AddMarkerOption(true, "player", 8, 66237, 8) -- Incinerate Flesh
function mod:GetOptions()
	return {
		"warmup",
		"berserk",
		66269, -- Nether Portal
		66258, -- Infernal Volcano
		66197, -- Legion Flame
		flameMarker,
		{66237, "HEALER"}, -- Incinerate Flesh
		fleshMarker,
		{67009, "DISPEL"}, -- Nether Power
		66532, -- Fel Fireball
		66334, -- Mistress' Kiss
		66496, -- Fel Inferno
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "FelFireball", 66532, 66963, 66964, 66965)
	self:Log("SPELL_AURA_APPLIED", "FelFireballApplied", 66532, 66963, 66964, 66965)
	self:Log("SPELL_CAST_SUCCESS", "NetherPower", 66228, 67106, 67107, 67108)
	self:Log("SPELL_CAST_SUCCESS", "InfernalVolcano", 67901, 67902, 67903, 66258)
	self:Log("SPELL_CAST_SUCCESS", "NetherPortal", 66269, 67898, 67899, 67900)
	self:Log("SPELL_CAST_SUCCESS", "LegionFlame", 66197, 68123, 68124, 68125)
	self:Log("SPELL_AURA_APPLIED", "LegionFlameApplied", 66197, 68123, 68124, 68125)
	self:Log("SPELL_AURA_APPLIED", "IncinerateFlesh", 67051, 67050, 67049, 66237)
	self:Log("SPELL_AURA_REMOVED", "IncinerateFleshRemoved", 67051, 67050, 67049, 66237)
	self:Log("SPELL_AURA_APPLIED", "MistressKiss", 66334, 67905, 67906, 67907)
	self:Log("SPELL_DAMAGE", "LegionFlameDamage", 66877, 67070, 67071, 67072)
	self:Log("SPELL_MISSED", "LegionFlameDamage", 66877, 67070, 67071, 67072)
	self:Log("SPELL_DAMAGE", "FelInfernoDamage", 66496, 68716, 68717, 68718)
	self:Log("SPELL_MISSED", "FelInfernoDamage", 66496, 68716, 68717, 68718)
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
end

function mod:OnEngage()
	self:StopBar(CL.active)
	self:Bar(66269, 22)
	self:DelayedMessage(66269, 17, "yellow", CL.soon:format(self:SpellName(66269)))
	self:Bar(66258, 82)
	self:DelayedMessage(66258, 77, "yellow", CL.soon:format(self:SpellName(66258)))
	self:CDBar(67009, 15)
	self:CDBar(66237, 14)
	self:CDBar(66197, 20)
	self:Berserk(600)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if msg:find(L.warmup_trigger, nil, true) then
		self:Bar("warmup", 20, CL.active, "inv_misc_pocketwatch_01")
	end
end

function mod:FelFireball(args)
	if self:Interrupter(args.sourceGUID) then
		self:Message(66532, "yellow", CL.casting:format(args.spellName))
		self:PlaySound(66532, "alert")
	end
end

function mod:FelFireballApplied(args)
	if self:Dispeller("magic", nil, 66532) then
		self:TargetMessage(66532, "yellow", args.destName)
		self:PlaySound(66532, "info")
	end
end

function mod:NetherPower(args)
	self:Message(67009, "yellow", CL.magic_buff_boss:format(self:SpellName(67009)))
	if self:Dispeller("magic", true, 67009) then
		self:PlaySound(67009, "alarm")
	end
	self:CDBar(67009, 42.5)
end

function mod:InfernalVolcano(args)
	self:Bar(66258, 120)
	self:DelayedMessage(66258, 110, "yellow", CL.soon:format(self:SpellName(66258)))
end

function mod:NetherPortal(args)
	self:Bar(66269, 120)
	self:DelayedMessage(66269, 110, "yellow", CL.soon:format(self:SpellName(66269)))
end

function mod:LegionFlame(args)
	self:TargetMessage(66197, "red", args.destName)
end

function mod:LegionFlameApplied(args)
	self:TargetBar(66197, 8, args.destName)
	self:CDBar(66197, 30)
	if self:Me(args.destGUID) then
		self:PlaySound(66197, "alarm") -- run out, keep moving
	end
	self:CustomIcon(flameMarker, args.destName, 7)
	self:ScheduleTimer("CustomIcon", 8, flameMarker, args.destName)
end

function mod:IncinerateFlesh(args)
	self:TargetBar(66237, 12, args.destName)
	self:CDBar(66237, 23)
	self:CustomIcon(fleshMarker, args.destName, 8)
	if self:Me(args.destGUID) then
		self:PersonalMessage(66237)
		self:PlaySound(66237, "warning")
	else
		self:TargetMessage(66237, "red", args.destName)
	end
end

function mod:IncinerateFleshRemoved(args)
	self:StopBar(66237, args.destName)
	self:CustomIcon(fleshMarker, args.destName)
end

function mod:MistressKiss(args)
	if self:Me(args.destGUID) then
		self:PersonalMessage(66334)
		self:PlaySound(66334, "warning") -- stop casting
	end
end

function mod:LegionFlameDamage(args)
	if self:Me(args.destGUID) and args.time - prevFlameDamage > 3 then
		prevFlameDamage = args.time
		self:PersonalMessage(66197, "underyou")
		self:PlaySound(66197, "underyou")
	end
end

function mod:FelInfernoDamage(args)
	if self:Me(args.destGUID) and args.time - prevInferno > 3 then
		prevInferno = args.time
		self:PersonalMessage(66496, "underyou")
		self:PlaySound(66496, "underyou")
	end
end
