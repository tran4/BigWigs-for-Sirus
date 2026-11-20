--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("The Black Knight", 650, 637)
if not mod then return end
mod:RegisterEnableMob(35451)
mod.engageId = 2021
--mod.respawnTime = 0 -- resets, doesn't respawn
mod:SetEncounterEmulation(false) -- 3.3.5: he dies twice before the real kill

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	defeat_trigger = "No! I must not fail... again", -- 3.3.5 (Sirus), from DBM
})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		{-7598, "CASTBAR"}, -- Ghoul Explode
		67781, -- Desecration
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "Explode", 67729, 67886) -- normal, heroic (ids from DBM)
	self:Log("SPELL_AURA_APPLIED", "Desecration", 67781, 67876) -- normal, heroic (ids from DBM)
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
	self:CheckForEngage()
end

function mod:OnEngage()
	self:CheckForWipe()
end

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if msg == L.defeat_trigger or msg:find(L.defeat_trigger, nil, true) then
		self:Win()
	end
end

--------------------------------------------------------------------------------
-- Event Handlers
--

do
	local prev = 0
	function mod:Explode(args)
		local t = args.time
		if t - prev > 1 then -- all remaining ghouls start casting Explode simultaneously when the boss transitions to stage 3
			prev = t
			self:MessageOld(-7598, "orange", nil, CL.casting:format(self:SpellName(args.spellId)))
			self:CastBar(-7598, self:Normal() and 5 or 4, args.spellId)
		end
	end
end

function mod:Desecration(args)
	if self:Me(args.destGUID) then
		self:TargetMessageOld(args.spellId, args.destName, "blue", "alarm")
	end
end
