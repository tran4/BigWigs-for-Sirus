--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-AQ40/Viscidus.lua)

local mod, CL = BigWigs:NewBoss("Viscidus", 531, 1548)
if not mod then return end
mod:RegisterEnableMob(15299)
mod:SetEncounterID(713)

--------------------------------------------------------------------------------
-- Locals
--

local volleyCount = 0

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	slow_trigger = "begins to slow",
	freezing_trigger = "is freezing up",
	frozen_trigger = "is frozen solid",
	crack_trigger = "begins to crack",
	shatter_trigger = "looks ready to shatter",
	explode_trigger = "Explodes.",

	freeze = "Freeze",
	freeze_desc = "Announce Freeze status",
	freeze_icon = 16350,
	freeze_message = "Freeze: %d/3",
	shatter = "Shatter",
	shatter_desc = "Announce Shatter status",
	shatter_icon = 12982,
	shatter_message = "Shatter: %d/3",
})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		25991, -- Poison Bolt Volley
		"freeze",
		"shatter",
		25989, -- Toxin
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_SUCCESS", "PoisonBoltVolley", 25991)
	self:Log("SPELL_AURA_APPLIED", "Toxin", 25989)
	self:RegisterEvent("CHAT_MSG_MONSTER_EMOTE")
end

function mod:OnEngage()
	volleyCount = 0
	self:CDBar(25991, 12.9, CL.count:format(self:SpellName(25991), 1))
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:PoisonBoltVolley(args)
	volleyCount = volleyCount + 1
	self:StopBar(CL.count:format(args.spellName, volleyCount))
	self:Message(25991, "yellow", CL.count:format(args.spellName, volleyCount))
	self:CDBar(25991, 11, CL.count:format(args.spellName, volleyCount + 1))
end

do
	local prev = 0
	function mod:Toxin(args)
		if self:Me(args.destGUID) and args.time - prev > 3 then
			prev = args.time
			self:PersonalMessage(25989, "underyou")
			self:PlaySound(25989, "underyou")
		end
	end
end

local emotes = {
	{"crack_trigger", "shatter", 1}, {"shatter_trigger", "shatter", 2}, {"explode_trigger", "shatter", 3},
	{"slow_trigger", "freeze", 1}, {"freezing_trigger", "freeze", 2}, {"frozen_trigger", "freeze", 3},
}

function mod:CHAT_MSG_MONSTER_EMOTE(_, msg)
	for i = 1, #emotes do
		local e = emotes[i]
		if msg:find(L[e[1]], nil, true) then
			self:Message(e[2], "cyan", L[e[2] .. "_message"]:format(e[3]), L[e[2] .. "_icon"])
			if e[2] == "freeze" and e[3] == 3 then
				self:PlaySound("freeze", "info")
				self:StopBar(CL.count:format(self:SpellName(25991), volleyCount + 1))
			end
			return
		end
	end
end
