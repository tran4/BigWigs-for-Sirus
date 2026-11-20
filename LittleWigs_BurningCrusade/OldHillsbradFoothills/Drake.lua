--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("Lieutenant Drake", 560, 538)
if not mod then return end
mod:RegisterEnableMob(17848)
mod.engageId = 1905
--mod.respawnTime = 0 -- does not despawn on a wipe

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	-- You there, fetch water quickly! Get these flames out before they spread to the rest of the keep! Hurry, damn you!
	warmup_trigger = "fetch water",
})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"warmup",
		{31911, "TANK_HEALER"}, -- Mortal Strike
		31910, -- Whirlwind
		33792, -- Explosive Shot (3.3.5: DBM Sirus)
	}
end

function mod:OnBossEnable()
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")

	self:Log("SPELL_AURA_APPLIED", "MortalStrike", 31911)
	self:Log("SPELL_AURA_REMOVED", "MortalStrikeRemoved", 31911)
	self:Log("SPELL_DAMAGE", "Whirlwind", 31910)
	self:Log("SPELL_MISSED", "Whirlwind", 31910)
	self:Log("SPELL_CAST_SUCCESS", "WhirlwindCast", 31909, 21910) -- 3.3.5: DBM Sirus
	self:Log("SPELL_AURA_APPLIED", "ExplosiveShot", 33792) -- 3.3.5: DBM Sirus
	self:Log("SPELL_AURA_REMOVED", "ExplosiveShotRemoved", 33792) -- 3.3.5: DBM Sirus
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if not self:IsSecret(msg) and msg:find(L.warmup_trigger, nil, true) then
		self:Warmup(3.3)
	end
end

function mod:Warmup(duration)
	self:UnregisterEvent("CHAT_MSG_MONSTER_YELL")
	self:Bar("warmup", duration, CL.active, "inv_sword_01")
end

function mod:MortalStrike(args)
	self:TargetMessageOld(args.spellId, args.destName, "orange", "warning")
	self:TargetBar(args.spellId, 5, args.destName)
end

function mod:MortalStrikeRemoved(args)
	self:StopBar(args.spellName, args.destName)
end

do
	local prev = 0
	function mod:Whirlwind(args)
		if self:Me(args.destGUID) and args.time - prev > 2 then
			prev = args.time
			self:MessageOld(args.spellId, "blue", "alarm", CL.near:format(args.spellName))
		end
	end
end

-- 3.3.5: DBM Sirus
function mod:WhirlwindCast(args)
	self:Message(31910, "red", CL.casting:format(args.spellName))
	self:PlaySound(31910, "runaway") -- DBM: just run
end

function mod:ExplosiveShot(args)
	self:TargetMessage(33792, "orange", args.destName)
	self:TargetBar(33792, 6, args.destName)
end

function mod:ExplosiveShotRemoved(args)
	self:StopBar(33792, args.destName)
end
