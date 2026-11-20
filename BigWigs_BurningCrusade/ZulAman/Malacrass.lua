--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-ZulAman/Malacrass.lua), draft by tools/dbm2bw

local mod, CL = BigWigs:NewBoss("Hex Lord Malacrass", 568, 190)
if not mod then return end
mod:RegisterEnableMob(24239)
mod:SetEncounterID(1193)

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	engage_trigger = "Da shadow gonna fall on you....",

	special = "Special ability",
	special_desc = "Show timers between the special abilities of the siphoned class",
	special_icon = 43501,
	special_bar = "Спец. способность %s", -- DBM: no English text
	move_away = "%s отойдите!", -- DBM: no English text
})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		43383, -- Spirit Bolts
		43501, -- Siphon Soul
		"special",
		43548, -- Healing Wave
		43451, -- Holy Light
		43431, -- Flash Heal
		43421, -- Lifebloom
		{43439, "DISPEL"}, -- Curse
		43442, -- melee danger
		43440, -- danger under you
		43436, -- Totem
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "MeleeDanger", 43442)
	self:Log("SPELL_CAST_START", "Heal", 43548, 43451, 43431)
	self:Log("SPELL_CAST_SUCCESS", "SpiritBolts", 43383)
	self:Log("SPELL_CAST_SUCCESS", "MeleeDanger", 43429)
	self:Log("SPELL_AURA_APPLIED", "SiphonSoul", 43501)
	self:Log("SPELL_AURA_APPLIED", "Curse", 43439)
	self:Log("SPELL_AURA_APPLIED", "UnderYou", 43440, 305658)
	self:Log("SPELL_AURA_APPLIED", "Lifebloom", 43421)
	self:Log("SPELL_SUMMON", "Totem", 43436)
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
end

function mod:OnEngage()
	self:CDBar(43383, 20)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if msg:find(L.engage_trigger, nil, true) and not self:IsEngaged() then
		self:Engage() -- DBM RegisterCombat("yell")
	end
end

function mod:MeleeDanger(args)
	if self:Melee() then
		self:Message(43442, "red", L.move_away:format(args.spellName))
		self:PlaySound(43442, "runaway")
	end
end

function mod:Heal(args)
	self:Message(args.spellId, "orange", CL.casting:format(args.spellName))
	if self:Interrupter(args.sourceGUID) then
		self:PlaySound(args.spellId, "alert")
	end
end

function mod:SpiritBolts()
	self:CDBar(43383, 40)
end

function mod:SiphonSoul(args)
	local unit = self:UnitTokenFromGUID(args.destGUID)
	local class = unit and UnitClass(unit) or args.destName
	self:TargetMessage(43501, "cyan", args.destName)
	self:TargetBar(43501, 30, args.destName)
	local text = L.special_bar:format(class)
	self:Bar("special", 10, text, L.special_icon)
	self:ScheduleTimer("Bar", 8, "special", 10, text, L.special_icon)
	self:ScheduleTimer("Bar", 16, "special", 10, text, L.special_icon)
end

function mod:Curse(args)
	if self:Dispeller("curse", nil, 43439) then
		self:TargetMessage(43439, "orange", args.destName)
		self:PlaySound(43439, "alert")
	end
end

function mod:UnderYou(args)
	if self:Me(args.destGUID) then
		self:Message(43440, "blue", L.move_away:format(args.spellName))
		self:PlaySound(43440, "underyou")
	end
end

function mod:Lifebloom(args)
	if not self:Player(args.destFlags) then
		self:Message(43421, "orange", CL.on:format(args.spellName, args.destName))
		if self:Dispeller("magic", true) then
			self:PlaySound(43421, "alert")
		end
	end
end

function mod:Totem(args)
	self:Message(43436, "red")
	if not self:Healer() then
		self:PlaySound(43436, "info") -- DBM: switch (dps)
	end
end
