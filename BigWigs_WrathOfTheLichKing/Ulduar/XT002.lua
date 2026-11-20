--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Ulduar/XT002.lua), draft by tools/dbm2bw

local mod, CL = BigWigs:NewBoss("XT-002 Deconstructor", 603, 1640)
if not mod then return end
mod:RegisterEnableMob(33293)
mod:SetEncounterID(747)

--------------------------------------------------------------------------------
-- Locals
--

local prevConsumption = 0

--------------------------------------------------------------------------------
-- Initialization
--

local lightBombMarker = mod:AddMarkerOption(true, "player", 7, 312941, 7)
local gravityBombMarker = mod:AddMarkerOption(true, "player", 8, 64234, 8)
function mod:GetOptions()
	return {
		"berserk",
		312939, -- Tympanic Tantrum
		{312941, "SAY", "SAY_COUNTDOWN"}, -- Searing Light
		lightBombMarker,
		{312943, "SAY", "SAY_COUNTDOWN", "PROXIMITY"}, -- Gravity Bomb
		gravityBombMarker,
		64206, -- Consumption
		312945, -- Heart of the Deconstructor
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "TympanicTantrum", 62776, 312586, 312939)
	self:Log("SPELL_AURA_APPLIED", "TympanicTantrumApplied", 62775, 312587, 312940)
	self:Log("SPELL_AURA_APPLIED", "LightBomb", 63018, 65121, 312588, 312941)
	self:Log("SPELL_AURA_REMOVED", "LightBombRemoved", 63018, 65121, 312588, 312941)
	self:Log("SPELL_AURA_APPLIED", "GravityBomb", 63024, 64234, 312590, 312943)
	self:Log("SPELL_AURA_REMOVED", "GravityBombRemoved", 63024, 64234, 312590, 312943)
	self:Log("SPELL_AURA_APPLIED", "Heart", 312945, 63849)
	self:Log("SPELL_AURA_REMOVED", "HeartRemoved", 312945, 63849)
	self:Log("SPELL_DAMAGE", "ConsumptionDamage", 64208, 64206)
	self:Log("SPELL_MISSED", "ConsumptionDamage", 64208, 64206)
end

function mod:OnEngage()
	self:Berserk(600)
	self:CDBar(312939, self:Difficulty() == 3 and 35 or 60)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:TympanicTantrum(args)
	self:Message(312939, "orange")
	self:CDBar(312939, 35)
end

do
	local prev = 0
	function mod:TympanicTantrumApplied(args)
		-- the debuff on the raid, not the buff on the boss
		if self:Player(args.destFlags) and args.time - prev > 3 then
			prev = args.time
			self:CastBar(312939, 8)
		end
	end
end

function mod:LightBomb(args)
	self:TargetMessage(312941, "orange", args.destName)
	self:TargetBar(312941, 9, args.destName)
	if self:Me(args.destGUID) then
		self:PlaySound(312941, "warning") -- run out
		self:Say(312941)
		self:SayCountdown(312941, 9)
	end
	self:CustomIcon(lightBombMarker, args.destName, 7)
end

function mod:LightBombRemoved(args)
	self:StopBar(312941, args.destName)
	self:CustomIcon(lightBombMarker, args.destName)
	if self:Me(args.destGUID) then
		self:CancelSayCountdown(312941)
	end
end

function mod:GravityBomb(args)
	self:TargetMessage(312943, "red", args.destName)
	self:TargetBar(312943, 9, args.destName)
	if self:Me(args.destGUID) then
		self:PlaySound(312943, "warning") -- run out
		self:Say(312943)
		self:SayCountdown(312943, 9)
		self:OpenProximity(312943, 30)
	end
	self:CustomIcon(gravityBombMarker, args.destName, 8)
end

function mod:GravityBombRemoved(args)
	self:StopBar(312943, args.destName)
	self:CustomIcon(gravityBombMarker, args.destName)
	if self:Me(args.destGUID) then
		self:CancelSayCountdown(312943)
		self:CloseProximity(312943)
	end
end

function mod:Heart(args)
	self:Message(312945, "green")
	self:PlaySound(312945, "long")
	self:CastBar(312945, 30)
end

function mod:HeartRemoved(args)
	self:StopCastBar(312945)
end

function mod:ConsumptionDamage(args)
	if self:Me(args.destGUID) and args.time - prevConsumption > 2.5 then
		prevConsumption = args.time
		self:PersonalMessage(64206, "underyou")
		self:PlaySound(64206, "underyou")
	end
end
