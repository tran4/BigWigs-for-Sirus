--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Ulduar/Algalon.lua), draft by tools/dbm2bw

local mod, CL = BigWigs:NewBoss("Algalon the Observer", 603, 1650)
if not mod then return end
mod:RegisterEnableMob(32871)
mod:SetEncounterID(757)
mod:SetWinMobs() -- 3.3.5: won by the defeat yell (DBM RegisterKill)
mod:SetEmulationWipeDelay(20) -- DBM SetWipeTime(20)

--------------------------------------------------------------------------------
-- Locals
--

local smashCount = 0
local stage2Warned, starWarned = false, false

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	defeat_trigger = "I have seen worlds bathed in the Makers' flames, their denizens fading without as much as a whimper. Entire planetary systems born and razed in the time that it takes your mortal hearts to beat once. Yet all throughout, my own heart devoid of emotion... of empathy. I. Have. Felt. Nothing. A million-million lives wasted. Had they all held within them your tenacity? Had they all loved life as you do?",
	collapsing_star_trigger = "%s begins to Summon Collapsing Stars!",
	-- 3.3.5: DBM Sirus has no English text for these
	warmup_trigger = "Ваши действия нелогичны. Все возможные исходы этой схватки просчитаны. Пантеон получит сообщение от Наблюдателя в любом случае.",
	stage2_trigger = "Узрите чудо созидания!",
	pull_check_trigger = "Алгалон подаст сигнал бедствия через (%d+) мин.",

	collapsing_star = "Next Collapsing Star",
	collapsing_star_desc = "Show timer for next Collapsing Star",
	collapsing_star_icon = 64122,
	star_low = "Collapsing Star is low",
	cosmic_smash = "Cosmic Smash - explosion in 4 seconds",
})
mod:SetChatEnableTriggers(L.warmup_trigger) -- 3.3.5: enable the module on the warmup yell/emote (no target yet)

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"warmup",
		"stages",
		"berserk",
		313034, -- Big Bang (3.3.5: for everyone, hide in a black hole; DBM Sirus: announce and cast timer for all)
		313036, -- Cosmic Smash
		{313033, "TANK"}, -- Phase Punch
		"collapsing_star",
		313039, -- Black Hole Explosion
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "BigBang", 313034, 64443, 64584)
	self:Log("SPELL_CAST_SUCCESS", "BlackHoleExplosion", 313039, 64122, 65108)
	self:Log("SPELL_CAST_SUCCESS", "CosmicSmash", 64598, 62301, 313037, 313036)
	self:Log("SPELL_AURA_APPLIED", "PhasePunch", 313033, 64412)
	self:Log("SPELL_AURA_APPLIED_DOSE", "PhasePunch", 313033, 64412)
	self:RegisterUnitEvent("UNIT_HEALTH", nil, "target", "focus")
	self:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE")
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
end

function mod:OnEngage()
	smashCount = 0
	stage2Warned, starWarned = false, false
	self:SetStage(1)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:StartTimers()
	self:Berserk(360)
	self:Bar(313034, 90.5)
	self:DelayedMessage(313034, 80, "orange", CL.soon:format(self:SpellName(313034)))
	self:CDBar(313036, 25, CL.count:format(self:SpellName(313036), smashCount + 1))
	self:Bar("collapsing_star", 15, L.collapsing_star, L.collapsing_star_icon)
end

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if msg:find(L.stage2_trigger, nil, true) then
		self:SetStage(2)
		self:StopBar(L.collapsing_star)
		self:Message("stages", "cyan", CL.stage:format(2), false)
		self:PlaySound("stages", "long")
	elseif msg:find(L.warmup_trigger, nil, true) then
		self:Bar("warmup", 26, CL.active, "inv_misc_pocketwatch_01")
		self:ScheduleTimer("StartTimers", 26)
	elseif msg:find(L.pull_check_trigger) then
		self:Bar("warmup", 8, CL.active, "inv_misc_pocketwatch_01")
		self:ScheduleTimer("StartTimers", 8)
	elseif msg:find(L.defeat_trigger, nil, true) then
		self:Win() -- DBM RegisterKill("yell")
	end
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(_, msg)
	if msg == L.collapsing_star_trigger or msg:find(L.collapsing_star_trigger) then -- DBM: "%s" is the boss
		self:Bar("collapsing_star", 15, L.collapsing_star, L.collapsing_star_icon)
	end
end

function mod:BigBang(args)
	self:Message(313034, "red")
	self:PlaySound(313034, "alarm") -- 3.3.5: everyone runs into a black hole (it was tank only)
	self:CastBar(313034, 8)
	self:Bar(313034, 90.5)
	self:DelayedMessage(313034, 80, "orange", CL.soon:format(args.spellName))
end

function mod:BlackHoleExplosion(args)
	self:Message(313039, "yellow")
	starWarned = false
end

function mod:CosmicSmash(args)
	self:StopBar(CL.count:format(self:SpellName(313036), smashCount + 1))
	smashCount = smashCount + 1
	self:Message(313036, "orange", CL.count:format(L.cosmic_smash, smashCount))
	self:PlaySound(313036, "alert")
	self:CastBar(313036, 4.5)
	self:CDBar(313036, 25, CL.count:format(self:SpellName(313036), smashCount + 1))
end

function mod:PhasePunch(args)
	local amount = args.amount or 1
	self:Bar(313033, 16)
	self:StackMessage(313033, "purple", args.destName, amount, 4)
	self:TargetBar(313033, 45, args.destName)
	if self:Me(args.destGUID) and amount >= 3 then
		self:PlaySound(313033, "alarm")
	end
end

function mod:UNIT_HEALTH(_, unit)
	local mobId = self:MobId(self:UnitGUID(unit))
	if not stage2Warned and mobId == 32871 and self:GetHealth(unit) <= 23 then
		stage2Warned = true
		self:Message("stages", "cyan", CL.soon:format(CL.stage:format(2)), false)
	elseif not starWarned and mobId == 32955 and self:GetHealth(unit) <= 10 then -- Collapsing Star
		starWarned = true
		self:Message("collapsing_star", "red", L.star_low, L.collapsing_star_icon)
		if self:Tank() then
			self:PlaySound("collapsing_star", "alert")
		end
	end
end
