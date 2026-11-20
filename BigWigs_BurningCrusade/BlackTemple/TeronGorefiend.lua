--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-BlackTemple/TeronGorefiend.lua, Sirus version with custom spells), draft by tools/dbm2bw
-- Three stages (auras): Power of the White Cold, Power of Suffering, Power of Darkness.
-- DBM has only Russian texts here: the English defaults are the Russian texts. Not ported: the info frames, pizza timers.

local mod, CL = BigWigs:NewBoss("Teron Gorefiend", 564, 1585)
if not mod then return end
mod:RegisterEnableMob(22871)
mod:SetEncounterID(604)

--------------------------------------------------------------------------------
-- Locals
--

local diseaseTargets, bloodTargets = {}, {}

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	-- DBM: no English texts
	warmup_trigger = "Я был первым. Колесо моей жизни сделало уже не один оборот. Столько времени прошло... Мне нужно столько наверстать.",
	stage2_name = "Власть Страданий",
	stage3_name = "Власть Тьмы",
	stage_bar = "Скоро Фаза: %s",
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
		{373795, "TANK"}, -- Freezing
		373796, -- Cold
		373793, -- Cold (standing in it)
		373803, -- Decapitation
		373804, -- Blood
		373801, -- Disease
		{373811, "TANK"}, -- Repose
		"proximity",
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "Stage2", 373799)
	self:Log("SPELL_CAST_START", "FreezingCast", 373795)
	self:Log("SPELL_CAST_START", "Stage3", 373807)
	self:Log("SPELL_AURA_APPLIED", "Repose", 373811)
	self:Log("SPELL_AURA_APPLIED_DOSE", "Repose", 373811)
	self:Log("SPELL_AURA_APPLIED", "Freezing", 373795)
	self:Log("SPELL_AURA_APPLIED_DOSE", "Freezing", 373795)
	self:Log("SPELL_AURA_APPLIED", "ColdApplied", 373793, 373792)
	self:Log("SPELL_AURA_APPLIED_DOSE", "ColdApplied", 373793, 373792)
	self:Log("SPELL_AURA_APPLIED", "Disease", 373801)
	self:Log("SPELL_AURA_APPLIED", "Blood", 373804)
	self:Log("SPELL_CAST_SUCCESS", "Decapitation", 373803)
	self:Log("SPELL_CAST_SUCCESS", "Cold", 373796)
	self:Log("SPELL_CAST_SUCCESS", "BloodSuccess", 373804)
	self:Log("SPELL_CAST_SUCCESS", "Stage1Cast", 373791)
	self:Log("SPELL_DAMAGE", "ColdDamage", 373793, 373792)
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
end

function mod:OnEngage()
	self:SetStage(1)
	diseaseTargets, bloodTargets = {}, {}
	self:OpenProximity("proximity", 9)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:StageBars(name)
	self:DelayedMessage("stages", 110, "yellow", CL.soon:format(name), false)
	self:Bar("stages", 120, L.stage_bar:format(name), "achievement_bg_returnxflags_def_wsg")
end

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if msg:find(L.warmup_trigger, nil, true) then
		self:Bar("warmup", 20, CL.active, "inv_misc_pocketwatch_01")
		self:CancelTimer(self.combatTimer)
		self.combatTimer = self:ScheduleTimer("CombatBars", 20)
	end
end

function mod:CombatBars()
	self:StageBars(L.stage2_name)
	self:CDBar(373796, 10)
end

function mod:Stage1Cast()
	self:StageBars(L.stage2_name)
	self:CDBar(373796, 10)
end

function mod:Stage2()
	self:SetStage(2)
	self:Message("stages", "cyan", L.stage2_name, false)
	self:PlaySound("stages", "long")
	self:DelayedMessage(373803, 10, "red", CL.soon:format(self:SpellName(373803)))
	self:CDBar(373803, 12)
	self:StopBar(373796)
	self:StopBar(373795)
	self:StageBars(L.stage3_name)
end

function mod:Stage3()
	self:SetStage(3)
	self:Message("stages", "cyan", L.stage3_name, false)
	self:PlaySound("stages", "long")
	self:CDBar(373811, 6)
	self:StopBar(373803)
	self:CancelDelayedMessage(CL.soon:format(self:SpellName(373803)))
	self:Berserk(90)
end

function mod:FreezingCast()
	self:CDBar(373795, 6)
end

function mod:Repose(args)
	self:StackMessage(373811, "purple", args.destName, args.amount or 1, 1)
end

function mod:Freezing(args)
	self:StackMessage(373795, "purple", args.destName, args.amount or 1, 1)
end

function mod:ColdApplied(args)
	if self:Me(args.destGUID) then
		self:PersonalMessage(373793, "underyou")
		self:PlaySound(373793, "underyou")
	end
end

function mod:ColdDamage(args)
	if self:Me(args.destGUID) and GetUnitSpeed("player") == 0 then -- DBM: only when standing still
		self:PersonalMessage(373793, "underyou")
	end
end

function mod:AnnounceDisease()
	self:TargetsMessage(373801, "yellow", diseaseTargets, #diseaseTargets)
	diseaseTargets = {}
end

function mod:Disease(args)
	self:CDBar(373801, 10)
	diseaseTargets[#diseaseTargets + 1] = args.destName
	self:CancelTimer(self.diseaseTimer)
	self.diseaseTimer = self:ScheduleTimer("AnnounceDisease", 0.1)
end

function mod:AnnounceBlood()
	self:TargetsMessage(373804, "orange", bloodTargets, #bloodTargets)
	bloodTargets = {}
end

function mod:Blood(args)
	bloodTargets[#bloodTargets + 1] = args.destName
	self:CancelTimer(self.bloodTimer)
	self.bloodTimer = self:ScheduleTimer("AnnounceBlood", 0.1)
	if self:Me(args.destGUID) then
		self:PlaySound(373804, "warning")
	end
end

function mod:Decapitation(args)
	self:DelayedMessage(373803, 10, "red", CL.soon:format(args.spellName))
	self:CDBar(373803, 12)
end

function mod:Cold(args)
	self:CDBar(373796, 10)
	self:CastBar(373796, 7)
	if self:Ranged() then -- DBM: SpellCaster
		self:Message(373796, "red")
		self:PlaySound(373796, "underyou")
	end
end

function mod:BloodSuccess()
	self:CDBar(373804, 15)
end
