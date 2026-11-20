--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Naxx/ArachnidQuarter/Maexxna.lua), draft by tools/dbm2bw
-- The Arachnophobia bar (DBM Anub'Rekhan ArachnophobiaTimer) is started by the Anub'Rekhan module on its win.

local mod, CL = BigWigs:NewBoss("Maexxna", 533, 1603)
if not mod then return end
mod:RegisterEnableMob(15952)
mod:SetEncounterID(1116)

--------------------------------------------------------------------------------
-- Locals
--

local myRealm = false -- 3.3.5: DBM Sirus has other Web Spray timers on the x1 realm
local prevWrap = 0

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	spiders = "Maexxna Spiderlings",
	spiders_desc = "Show warnings and timer for Maexxna Spiderlings",
	spiders_icon = 17332,
	spiders_soon = "Maexxna Spiderlings in 5 seconds",
	spiders_now = "Maexxna Spiderlings spawned",
	spiders_bar = "Next Maexxna Spiderlings",

	arachnophobia = "Arachnophobia",
	arachnophobia_desc = "Show timer for Arachnophobia (achievement): kill Maexxna within 20 minutes of Anub'Rekhan",
	arachnophobia_icon = 28622,
})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		{28622, "SAY"}, -- Web Wrap
		29484, -- Web Spray
		"spiders",
		"arachnophobia",
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "WebWrap", 28622)
	self:Log("SPELL_CAST_SUCCESS", "WebSpray", 29484, 54125)
end

function mod:OnEngage()
	myRealm = BigWigsLoader.Compat.GetRealmNumber() == 1
	prevWrap = 0
	self:DelayedMessage(29484, 35, "yellow", CL.soon:format(self:SpellName(29484)))
	self:CDBar(29484, 40)
	self:CDBar(28622, 20.1)
	self:Spiderlings(30)
end

function mod:OnWin()
	self:StopBar(L.arachnophobia)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:Arachnophobia() -- called by the Anub'Rekhan module on its win
	self:Bar("arachnophobia", 1200, L.arachnophobia, L.arachnophobia_icon)
end

function mod:Spiderlings(delay)
	self:DelayedMessage("spiders", delay - 5, "yellow", L.spiders_soon, L.spiders_icon)
	self:DelayedMessage("spiders", delay, "orange", L.spiders_now, L.spiders_icon, "info")
	self:Bar("spiders", delay, L.spiders_bar, L.spiders_icon)
	self:ScheduleTimer("Spiderlings", delay, 40)
end

do
	local playerList = {}
	function mod:WebWrap(args)
		if args.time - prevWrap > 3 then
			prevWrap = args.time
			playerList = {}
			self:CDBar(28622, 39.6) -- 3.3.5: DBM restarts it only for the players who are not wrapped
			if not self:Me(args.destGUID) and not self:UnitDebuff("player", 28622) then
				self:PlaySound(28622, "alert") -- DBM: switch to the wraps (ranged)
			end
		end
		playerList[#playerList + 1] = args.destName
		self:TargetsMessage(28622, "orange", playerList, nil, nil, nil, 0.5)
		if self:Me(args.destGUID) then
			self:Say(28622)
		end
	end
end

function mod:WebSpray(args)
	self:Message(29484, "red")
	self:PlaySound(29484, "long")
	self:DelayedMessage(29484, myRealm and 10 or 35, "yellow", CL.soon:format(args.spellName))
	self:CDBar(29484, myRealm and 15 or 40)
end
