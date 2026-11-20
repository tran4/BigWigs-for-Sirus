--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-AQ20/Rajaxx.lua)
-- DBM listens to the waves and the abilities of the wave captains in the whole zone: the trash module keeps this
-- module enabled. The Russian localization of DBM has the first wave under the key Wave1 instead of Wave12.

local mod, CL = BigWigs:NewBoss("General Rajaxx", 509, 1538)
if not mod then return end
mod:RegisterEnableMob(15341)
mod:SetEncounterID(719)

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	wave12_trigger = "They come now. Try not to get yourself killed, young blood.",
	wave12alt_trigger = "Remember, Rajaxx, when I said I'd kill you last?",
	wave3_trigger = "The time of our retribution is at hand! Let darkness reign in the hearts of our enemies!",
	wave4_trigger = "No longer will we wait behind barred doors and walls of stone! No longer will our vengeance be denied! The dragons themselves will tremble before our wrath!",
	wave5_trigger = "Fear is for the enemy! Fear and death!",
	wave6_trigger = "Staghelm will whimper and beg for his life, just as his whelp of a son did! One thousand years of injustice will end this day!",
	wave7_trigger = "Fandral! Your time has come! Go and hide in the Emerald Dream and pray we never find you!",
	wave8_trigger = "Impudent fool! I will kill you myself!",

	waves = "Waves",
	waves_desc = "Show announce for next incoming wave",
	waves_icon = "spell_holy_prayerofhealing",
	wave = "Wave %s",
})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"waves",
		{25471, "SAY"}, -- Attack Order
		26550, -- Lightning Cloud
		25599, -- Thundercrash
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "AttackOrder", 25471)
	self:Log("SPELL_CAST_SUCCESS", "LightningCloud", 26550)
	self:Log("SPELL_CAST_SUCCESS", "Thundercrash", 25599)
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
end

--------------------------------------------------------------------------------
-- Event Handlers
--

local waves = {
	{"wave12_trigger", "1, 2"}, {"wave12alt_trigger", "1, 2"}, {"wave3_trigger", 3}, {"wave4_trigger", 4},
	{"wave5_trigger", 5}, {"wave6_trigger", 6}, {"wave7_trigger", 7}, {"wave8_trigger", 8},
}

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	for i = 1, #waves do
		if msg:find(L[waves[i][1]], nil, true) then
			self:Message("waves", "cyan", L.wave:format(waves[i][2]), L.waves_icon)
			self:PlaySound("waves", "info")
			return
		end
	end
end

function mod:AttackOrder(args)
	self:TargetMessage(25471, "red", args.destName)
	self:TargetBar(25471, 10, args.destName)
	if self:Me(args.destGUID) then
		self:PlaySound(25471, "warning")
		self:Say(25471)
	end
end

function mod:LightningCloud(args)
	self:Message(26550, "orange")
	self:Bar(26550, 15, CL.other:format(args.spellName, CL.active))
end

function mod:Thundercrash(args)
	self:Message(25599, "yellow")
end
