--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-BlackTemple/ShadeOfAkama.lua, Sirus version with custom spells), draft by tools/dbm2bw
-- Won by Akama's yell (DBM RegisterKill("yell")) or Akama at 1% health (DBM EndCombat). The fight starts 12s after
-- Akama leaves his stealth (DBM combat timer), the module engages then if the combat log did not.
-- DBM has only Russian texts here: the English defaults are the Russian texts.
-- Not ported: the icons on the Ashtongue mobs, nameplate icons, the health frame, raid chat messages.

local mod, CL = BigWigs:NewBoss("Shade of Akama", 564, 1584)
if not mod then return end
mod:RegisterEnableMob(22841, 23191) -- Shade of Akama, Akama
mod:SetEncounterID(603)
mod:SetWinMobs()

--------------------------------------------------------------------------------
-- Locals
--

local defenderCount, addsCount, controlCount = 1, 1, 1
local mcTargets = {}
local prevReflect = 0

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	-- DBM: no English texts
	defeat_trigger = "Сломленные из племени Пеплоустов, ваш предводитель говорит!",
	sorcerer_trigger = "Один из Пеплоустов-чаротворцев выходит из транса и вступает в бой!",
	defenders = "Защитники: %d",
	adds = "Адды: %d",
	dps_now = "Остаточные эманации появились, можно бить Акаму!!!!",
	sorcerer_now = "За гранью спало, можно бить чаротворца!!!!",
	healed = "Не сбили Лик Тени, босс отхилился!!!!",
})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"warmup",
		"stages",
		"berserk",
		"adds",
		322728, -- Dominate Mind
		322727, -- Shadow Cleanse
		371519, -- Devastating
		322737, -- Inferno
		322739, -- Dominate
		322743, -- Beyond
		371509, -- Reflect
		374653, -- Residual Emanations
		322750, -- Face of Shadow
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "DominateMindCast", 322728)
	self:Log("SPELL_CAST_START", "ShadowCleanse", 322727)
	self:Log("SPELL_CAST_START", "Devastating", 371519)
	self:Log("SPELL_CAST_START", "Inferno", 322737)
	self:Log("SPELL_CAST_START", "DominateCast", 322739)
	self:Log("SPELL_AURA_APPLIED", "DominateMind", 322728)
	self:Log("SPELL_AURA_APPLIED", "Reflect", 371509)
	self:Log("SPELL_AURA_REMOVED", "ReflectRemoved", 371509)
	self:Log("SPELL_AURA_APPLIED", "Stage2", 322734)
	self:Log("SPELL_AURA_APPLIED", "Dominate", 322739)
	self:Log("SPELL_AURA_APPLIED", "ResidualEmanations", 374653)
	self:Log("SPELL_AURA_REMOVED", "StealthRemoved", 34189)
	self:Log("SPELL_HEAL", "FaceOfShadow", 322750)
	self:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE")
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
	self:RegisterEvent("UNIT_HEALTH")
end

function mod:OnEngage()
	self:SetStage(1)
	defenderCount, addsCount, controlCount = 1, 1, 1
	mcTargets = {}
	prevReflect = 0
	self:StopBar(CL.active)
	self:Bar("stages", 360, CL.stage:format(2), "achievement_bg_returnxflags_def_wsg")
	self:Bar(322743, 30, CL.count:format(self:SpellName(322743), 1))
	self:CDBar(322728, 30)
	self:Bar("adds", 10, L.adds:format(addsCount), 42035)
	self.addsTimer = self:ScheduleTimer("AddsLoop", 10)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:StealthRemoved(args)
	if self:MobId(args.destGUID) == 23191 and not self:IsEngaged() then -- Akama is activated
		self:Bar("warmup", 12, CL.active, "inv_misc_pocketwatch_01")
		self:ScheduleTimer("Engage", 12)
	end
end

function mod:AddsLoop()
	addsCount = addsCount + 1
	defenderCount = defenderCount + 1
	self:CDBar(371509, 12)
	self:DelayedMessage("adds", 65, "yellow", CL.soon:format(L.defenders:format(defenderCount)), 40474)
	self:Bar("adds", 70, L.defenders:format(defenderCount), 40474)
	self:DelayedMessage("adds", 35, "yellow", CL.soon:format(L.adds:format(addsCount)), 42035)
	self:Bar("adds", 40, L.adds:format(addsCount), 42035)
	self.addsTimer = self:ScheduleTimer("AddsLoop", 70)
end

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if msg:find(L.defeat_trigger, nil, true) and self:IsEngaged() then
		self:Win()
	end
end

function mod:UNIT_HEALTH(_, unit)
	if self:IsEngaged() and self:MobId(self:UnitGUID(unit)) == 23191 and self:GetHealth(unit) <= 1 then
		self:Win() -- DBM: EndCombat at Akama 1%
	end
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(_, msg)
	if msg:find(L.sorcerer_trigger, nil, true) then
		controlCount = controlCount + 1
		self:Bar(322743, 50, CL.count:format(self:SpellName(322743), controlCount + 1))
		self:Message(322743, "green", L.sorcerer_now)
		self:PlaySound(322743, "alarm")
	end
end

function mod:DominateMindCast(args)
	self:Message(322728, "orange", CL.casting:format(args.spellName))
	self:CDBar(322728, 48)
end

function mod:AnnounceMC()
	self:TargetsMessage(322728, "red", mcTargets, #mcTargets)
	mcTargets = {}
end

function mod:DominateMind(args)
	mcTargets[#mcTargets + 1] = args.destName
	self:CancelTimer(self.mcTimer)
	self.mcTimer = self:ScheduleTimer("AnnounceMC", 0.1)
end

function mod:ShadowCleanse(args)
	if self:Interrupter(args.sourceGUID) then
		self:Message(322727, "red", CL.casting:format(args.spellName))
		self:PlaySound(322727, "alert")
	end
	self:CDBar(322727, 13.5)
end

function mod:Devastating(args)
	if self:Interrupter(args.sourceGUID) then
		self:Message(371519, "red", CL.casting:format(args.spellName))
		self:PlaySound(371519, "alert")
	end
end

function mod:Inferno(args)
	self:CastBar(322737, 3.5)
	self:DelayedMessage(322737, 3, "orange", args.spellName)
	self:CDBar(322737, 18)
end

function mod:DominateCast(args)
	self:Message(322739, "orange", CL.casting:format(args.spellName))
	self:CDBar(322739, 27)
end

function mod:Dominate(args)
	self:TargetMessage(322739, "red", args.destName)
end

function mod:Reflect(args)
	if args.time - prevReflect > 8 then
		prevReflect = args.time
		self:Message(371509, "orange", CL.onboss:format(args.spellName))
		self:Bar(371509, 3, CL.other:format(args.spellName, CL.active))
	end
end

function mod:ReflectRemoved()
	self:CDBar(371509, 12)
end

function mod:Stage2()
	if self:GetStage() == 2 then return end
	self:SetStage(2)
	self:Message("stages", "cyan", CL.stage:format(2), false)
	self:PlaySound("stages", "long")
	self:CDBar(322737, 15)
	self:CDBar(322739, 31)
	self:Berserk(360)
end

function mod:ResidualEmanations(args)
	self:Message(374653, "green", L.dps_now)
	self:PlaySound(374653, "long")
	self:Bar(374653, 10, CL.other:format(args.spellName, CL.active))
end

function mod:FaceOfShadow()
	self:Message(322750, "red", L.healed)
	self:PlaySound(322750, "alarm")
end
