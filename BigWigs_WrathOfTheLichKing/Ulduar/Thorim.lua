--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Ulduar/Thorim.lua), draft by tools/dbm2bw
-- Not ported: posting Lightning Charge fails to the raid chat.

local mod, CL = BigWigs:NewBoss("Thorim", 603, 1645)
if not mod then return end
mod:RegisterEnableMob(32865)
mod:SetEncounterID(752)
mod:SetWinMobs() -- 3.3.5: won by the defeat yell (DBM RegisterKill)

--------------------------------------------------------------------------------
-- Locals
--

local prevShock = 0

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	engage_trigger = "Interlopers! You mortals who dare to interfere with my sport will pay.... Wait--you...",
	stage2_trigger = "Impertinent whelps, you dare challenge me atop my pedestal? I will crush you myself!",
	defeat_trigger = "Stay your arms! I yield!",

	hardmode = "Hard mode",
	hardmode_desc = "Show timer for hard mode",
	hardmode_icon = 312898,
})

--------------------------------------------------------------------------------
-- Initialization
--

local runicMarker = mod:AddMarkerOption(false, "player", 7, 62527, 7)
function mod:GetOptions()
	return {
		"stages",
		"berserk",
		"hardmode",
		"proximity",
		312907, -- Stormhammer
		62042, -- Stormhammer (stun)
		312897, -- Lightning Charge
		{312898, "TANK"}, -- Unbalancing Strike
		{312911, "SAY"}, -- Runic Detonation
		runicMarker,
		312895, -- Chain Lightning
		62604, -- Frostbolt Volley
		62017, -- Lightning Shock
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "ChainLightningStart", 312542, 312895)
	self:Log("SPELL_CAST_SUCCESS", "ChainLightning", 312895, 312542, 300871, 64390, 64213)
	self:Log("SPELL_AURA_APPLIED", "Stormhammer", 312889, 312536)
	self:Log("SPELL_CAST_SUCCESS", "StormhammerSuccess", 62042)
	self:Log("SPELL_CAST_SUCCESS", "LightningCharge", 312897, 312896)
	self:Log("SPELL_AURA_APPLIED", "UnbalancingStrike", 312898, 312545, 62130)
	self:Log("SPELL_CAST_SUCCESS", "UnbalancingStrikeSuccess", 312898, 312545)
	self:Log("SPELL_AURA_APPLIED", "RunicDetonation", 312911, 312910, 312558, 312557, 62526, 62527)
	self:Log("SPELL_AURA_APPLIED_DOSE", "RunicDetonation", 312911, 312910, 312558, 312557, 62526, 62527)
	self:Log("SPELL_CAST_SUCCESS", "FrostboltVolley", 62604)
	self:Log("SPELL_DAMAGE", "LightningShockDamage", 62017, 312539, 312892)
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
end

function mod:OnEngage()
	self:SetStage(1)
	self:Berserk(369)
	self:Bar("hardmode", 175, L.hardmode, L.hardmode_icon)
	self:OpenProximity("proximity", 11)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if msg:find(L.engage_trigger, nil, true) then
		self:Engage() -- DBM RegisterCombat("yell")
	elseif msg:find(L.stage2_trigger, nil, true) and self:GetStage() < 2 and self:IsEngaged() then
		self:SetStage(2)
		self:Message("stages", "cyan", CL.stage:format(2), false)
		self:PlaySound("stages", "long")
		self:StopBar(L.hardmode)
		self:StopBerserk(self:SpellName(26662)) -- the Berserk bar text
		self:Berserk(300) -- the boss fight on the pedestal
	elseif msg:find(L.defeat_trigger, nil, true) then
		self:Win() -- DBM RegisterKill("yell")
	end
end

function mod:ChainLightningStart(args)
	self:Bar(312895, 13)
end

function mod:ChainLightning(args)
	self:Bar(312895, 13)
end

function mod:Stormhammer(args)
	self:TargetMessage(312907, "yellow", args.destName)
end

function mod:StormhammerSuccess(args)
	self:ScheduleTimer("CastBar", 2, 62042, 16)
end

function mod:LightningCharge(args)
	self:Message(312897, "orange")
	self:CDBar(312897, 16)
end

function mod:UnbalancingStrike(args)
	if self:Me(args.destGUID) then
		self:PlaySound(312898, "alarm") -- defensive
	elseif self:Tank() then
		self:PlaySound(312898, "warning") -- taunt
	end
	self:TargetMessage(312898, "purple", args.destName)
end

function mod:UnbalancingStrikeSuccess(args)
	local diff = self:Difficulty()
	self:CDBar(312898, (diff == 3 or diff == 5) and 22 or 15)
end

function mod:RunicDetonation(args)
	if self:Me(args.destGUID) then
		self:PersonalMessage(312911)
		self:PlaySound(312911, "warning")
		self:Say(312911)
	else
		local unit = self:UnitTokenFromGUID(args.destGUID)
		if unit and self:UnitWithinRange(unit, 10) then
			self:Message(312911, "orange", CL.near:format(self:SpellName(312911)))
			self:PlaySound(312911, "alarm")
		else
			self:TargetMessage(312911, "orange", args.destName)
		end
	end
	self:CustomIcon(runicMarker, args.destName, 7)
	self:ScheduleTimer("CustomIcon", 5, runicMarker, args.destName)
end

function mod:FrostboltVolley(args)
	self:CDBar(62604, 13)
end

function mod:LightningShockDamage(args)
	if self:Me(args.destGUID) and args.time - prevShock > 5 then
		prevShock = args.time
		self:PersonalMessage(62017, "underyou")
		self:PlaySound(62017, "underyou")
	end
end
