--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("Eadric the Pure", 650, 635)
if not mod then return end
mod:RegisterEnableMob(35119)
--mod.engageId = 2023 -- doesn't fire ENCOUNTER_END on a wipe, also shares it with Paletress

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	defeat_trigger = "I yield! I submit. Excellent work. May I run away now?", -- 3.3.5 (Sirus), from DBM
})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		{66935, "CASTBAR"}, -- Radiance
	}
end

function mod:OnBossEnable()
	if self:Classic() then
		self:CheckForEngage()
	else
		self:RegisterEvent("INSTANCE_ENCOUNTER_ENGAGE_UNIT", "CheckBossStatus")
	end

	self:Log("SPELL_CAST_START", "Radiance", 66935)
	self:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", nil, "boss1")
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL") -- 3.3.5: the defeat yell, the boss might not be targeted when Full Heal is cast
end

function mod:VerifyEnable(unit) -- becomes friendly after being defeated
	return UnitCanAttack("player", unit)
end

function mod:OnEngage()
	if self:Classic() then
		self:CheckForWipe()
	end
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:Radiance(args)
	self:MessageOld(args.spellId, "orange", nil, CL.casting:format(args.spellName))
	self:CastBar(args.spellId, 3)
end

do
	local prev = 0
	function mod:UNIT_SPELLCAST_SUCCEEDED(_, _, castGUID, _, spellName)
		if spellName == self:SpellName(43979) and castGUID ~= prev then -- Full Heal
			prev = castGUID
			self:Win()
		end
	end
end

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if msg == L.defeat_trigger or msg:find(L.defeat_trigger, nil, true) then
		self:Win()
	end
end
