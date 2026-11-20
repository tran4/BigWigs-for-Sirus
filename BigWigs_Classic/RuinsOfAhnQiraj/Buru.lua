--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-AQ20/Buru.lua)

local mod, CL = BigWigs:NewBoss("Buru the Gorger", 509, 1540)
if not mod then return end
mod:RegisterEnableMob(15370)
mod:SetEncounterID(721)

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	pursue_trigger = "%s sets eyes on",

	pursue = "Pursue",
	pursue_desc = "Show special warning when you are being pursued, announce pursue targets",
	pursue_icon = 12021,
	pursue_other = "Pursue on >%s<",
	pursue_you = "Pursue on you",
})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"pursue",
		{96, "TANK"}, -- Dismember (DBM: tanks only)
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "Dismember", 96)
	self:Log("SPELL_AURA_APPLIED_DOSE", "Dismember", 96)
	self:Log("SPELL_AURA_REMOVED", "DismemberRemoved", 96)
	self:RegisterEvent("CHAT_MSG_MONSTER_EMOTE")
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:CHAT_MSG_MONSTER_EMOTE(_, msg, _, _, _, target)
	if msg:find(L.pursue_trigger, nil, true) and target then
		if self:UnitName("player") == target then
			self:Message("pursue", "blue", L.pursue_you, L.pursue_icon)
			self:PlaySound("pursue", "warning") -- DBM: just run
		else
			self:Message("pursue", "yellow", L.pursue_other:format(self:ColorName(target)), L.pursue_icon)
		end
	end
end

function mod:Dismember(args)
	local amount = args.amount or 1
	self:StackMessage(96, "purple", args.destName, amount, 5)
	self:TargetBar(96, 10, args.destName)
	if amount >= 5 then
		if self:Me(args.destGUID) then
			self:PlaySound(96, "alarm")
		elseif not self:UnitDebuff("player", 96) and not UnitIsDeadOrGhost("player") then
			self:PlaySound(96, "warning") -- DBM: taunt
		end
	end
end

function mod:DismemberRemoved(args)
	self:StopBar(96, args.destName)
end
