--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-TheEye/Alar.lua, heroic mode with custom spells), draft by tools/dbm2bw
-- Not ported: the icons on the phoenixes (DBM ScanForMobs), the feather arrow/icons.

local mod, CL = BigWigs:NewBoss("Al'ar", 550, 1573)
if not mod then return end
mod:RegisterEnableMob(19514)
mod:SetEncounterID(730)

--------------------------------------------------------------------------------
-- Locals
--

local warnedSoon = false

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	platform = "Next Platform",
	platform_desc = "Show timer for when Al'ar changes platforms",
	platform_icon = 46599,
})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"stages",
		"berserk",
		"platform",
		34229, -- Flame Quills
		35181, -- Dive Bomb
		35412, -- Charge
		-- heroic
		{308633, "HEALER"}, -- Animated Flame
		{308638, "HEALER"}, -- Fire Sign
		308987, -- Flamefall
		308671, -- Phoenix Scream
		308640, -- stage 2
		308663, -- Phoenix Sign: Scattering
		308664, -- Phoenix Sign: Weakness
		308665, -- Phoenix Sign: Fury
		308667, -- Phoenix Sign: Fatigue
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_HEAL", "RebirthHeal", 34342)
	self:Log("SPELL_CAST_START", "Rebirth", 34342)
	self:Log("SPELL_CAST_START", "PlatformCast", 46599)
	self:Log("SPELL_CAST_SUCCESS", "FlameQuills", 34229)
	self:Log("SPELL_CAST_SUCCESS", "DiveBomb", 35181)
	self:Log("SPELL_CAST_SUCCESS", "HeroicStage2", 308640)
	self:Log("SPELL_CAST_START", "FireSign", 308638)
	self:Log("SPELL_CAST_START", "Flamefall", 308987)
	self:Log("SPELL_CAST_START", "AnimatedFlame", 308633)
	self:Log("SPELL_CAST_START", "PhoenixScream", 308671)
	self:Log("SPELL_CAST_START", "PhoenixSign", 308663, 308664, 308665, 308667)
	self:RegisterEvent("UNIT_HEALTH")
end

function mod:OnEngage()
	self:SetStage(1)
	warnedSoon = false
	if self:Difficulty() == 6 then -- 25 heroic
		self:CDBar(308633, 70)
		self:CDBar(308638, 39)
		self:CDBar(308987, 31)
		self:Berserk(444)
	else
		self:Berserk(360)
		self:Bar("platform", 39, L.platform, L.platform_icon)
		self:CDBar(34229, 180)
		self:DelayedMessage("platform", 36, "yellow", CL.soon:format(L.platform), L.platform_icon)
		self:DelayedMessage(34229, 169, "yellow", CL.soon:format(self:SpellName(34229)))
	end
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:Platform()
	self:Bar("platform", 43, L.platform, L.platform_icon)
	self:DelayedMessage("platform", 33, "yellow", CL.soon:format(L.platform), L.platform_icon)
	self:CancelTimer(self.platformTimer)
	self.platformTimer = self:ScheduleTimer("Platform", 36) -- DBM: 43s bar, next platform after 36s
end

function mod:RebirthHeal() -- normal: stage 2
	if self:GetStage() == 2 then return end
	self:SetStage(2)
	self:Message("stages", "cyan", CL.stage:format(2), false)
	self:PlaySound("stages", "long")
	self:Berserk(480)
	self:CDBar(35181, 30)
	self:StopBar(L.platform)
end

function mod:Rebirth()
	self:StopBar(CL.cast:format(self:SpellName(34229)))
	self:StopBar(34229)
	self:StopBar(L.platform)
	self:CancelTimer(self.platformTimer)
	self:CancelDelayedMessage(CL.soon:format(L.platform))
	self:CancelDelayedMessage(CL.soon:format(self:SpellName(34229)))
	self:CDBar(35412, 20)
	self:CDBar(35181, 46)
	self:DelayedMessage(35181, 43, "yellow", CL.soon:format(self:SpellName(35181)))
end

function mod:PlatformCast()
	self:Bar("platform", 33, L.platform, L.platform_icon)
end

function mod:FlameQuills(args)
	self:Message(34229, "red")
	self:PlaySound(34229, "alarm")
	self:CastBar(34229, 10)
	self:CDBar(34229, 180)
	self:StopBar(L.platform)
	self:ScheduleTimer("Bar", 10, "platform", 43, L.platform, L.platform_icon)
	self:CancelTimer(self.platformTimer)
	self.platformTimer = self:ScheduleTimer("Platform", 46)
end

function mod:DiveBomb(args)
	self:TargetMessage(35181, "orange", args.destName)
	self:CDBar(35181, 46)
	if self:Me(args.destGUID) then
		self:PlaySound(35181, "warning")
	end
end

function mod:HeroicStage2(args)
	self:SetStage(2)
	self:CastBar(308640, 20)
	self:Message("stages", "red", CL.stage:format(2), false)
	self:PlaySound("stages", "long")
	self:Berserk(500)
end

function mod:FireSign(args)
	self:Message(308638, "orange")
	self:CDBar(308638, 39)
	self:CastBar(308638, 1)
end

function mod:Flamefall(args)
	self:Message(308987, "red")
	self:PlaySound(308987, "alarm")
	self:CDBar(308987, 31)
	self:CastBar(308987, 5)
end

function mod:AnimatedFlame(args)
	self:Message(308633, "orange")
	self:CDBar(308633, 70)
	self:CastBar(308633, 2)
end

function mod:PhoenixScream(args)
	self:Message(308671, "orange")
	self:CastBar(308671, 2)
	self:CDBar(308671, 20)
end

function mod:PhoenixSign(args)
	self:CastBar(args.spellId, 20)
end

function mod:UNIT_HEALTH(_, unit)
	if not warnedSoon and self:IsEngaged() and self:MobId(self:UnitGUID(unit)) == 19514 and self:GetHealth(unit) <= 7 then
		warnedSoon = true
		self:Message("stages", "cyan", CL.soon:format(CL.stage:format(2)), false)
	end
end
