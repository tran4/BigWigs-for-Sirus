--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Serpentshrine/Leotheras.lua, heroic mode with custom spells), draft by tools/dbm2bw
-- Not ported: the Incinerate absorb and boss power frames, announcing the targets to the raid chat.

local mod, CL = BigWigs:NewBoss("Leotheras the Blind", 548, 1569)
if not mod then return end
mod:RegisterEnableMob(21215)
mod:SetEncounterID(625)

--------------------------------------------------------------------------------
-- Locals
--

local demonTargets, incinerateTargets = {}, {}
local warnedSoon = false

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	demon_trigger = "Be gone, trifling elf%.%s*I am in control now!", -- pattern (DBM en)
	stage2_trigger = "No... no! What have you done? I am the master! Do you hear me? I am... aaggh! Can't... contain him.",

	forms = "Forms",
	forms_desc = "Show timers for the demon and the normal form",
	forms_icon = "spell_shadow_metamorphosis",
	demon_form = "Форма демона", -- DBM: no English text
	normal_form = "Обычная форма", -- DBM: no English text
})

--------------------------------------------------------------------------------
-- Initialization
--

local demonMarker = mod:AddMarkerOption(true, "player", 8, 37676, 8, 7, 6, 5)
local incinerateMarker = mod:AddMarkerOption(true, "player", 7, 310514, 7, 6, 5, 4)
local brandMarker = mod:AddMarkerOption(true, "player", 8, 310496, 8)
function mod:GetOptions()
	return {
		"stages",
		"berserk",
		"forms",
		37640, -- Whirlwind
		37676, -- Insidious Whisper
		demonMarker,
		-- heroic
		{310480, "TANK"},
		{310502, "TANK"},
		310521, -- Flash
		{310496, "SAY"}, -- Brand
		brandMarker,
		310514, -- Incinerate
		incinerateMarker,
		310481, -- Charge
		310484, -- Metamorphosis
		310478, -- Onslaught
		310516, -- Gaze
		310510, -- run
		310508, -- Annihilation
		310503, -- soak
		310487, -- Seal
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "Whirlwind", 37640)
	self:Log("SPELL_CAST_START", "InsidiousWhisperCast", 37676)
	self:Log("SPELL_AURA_APPLIED", "InsidiousWhisper", 37676)
	self:Log("SPELL_AURA_REMOVED", "InsidiousWhisperRemoved", 37676)
	self:Log("SPELL_AURA_APPLIED", "TankStacks", 310480, 310502)
	self:Log("SPELL_AURA_APPLIED_DOSE", "TankStacks", 310480, 310502)
	self:Log("SPELL_AURA_APPLIED", "Flash", 310521)
	self:Log("SPELL_AURA_APPLIED_DOSE", "Flash", 310521)
	self:Log("SPELL_AURA_APPLIED", "Brand", 310496, 310497)
	self:Log("SPELL_AURA_APPLIED", "Incinerate", 310514)
	self:Log("SPELL_AURA_REMOVED", "IncinerateRemoved", 310514)
	self:Log("SPELL_CAST_START", "IncinerateCast", 310514)
	self:Log("SPELL_CAST_SUCCESS", "Charge", 310481)
	self:Log("SPELL_CAST_SUCCESS", "Metamorphosis", 310484)
	self:Log("SPELL_CAST_SUCCESS", "Onslaught", 310478)
	self:Log("SPELL_CAST_SUCCESS", "Gaze", 310516)
	self:Log("SPELL_CAST_START", "Run", 310510)
	self:Log("SPELL_CAST_START", "Annihilation", 310508)
	self:Log("SPELL_CAST_START", "Soak", 310503, 310487)
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
	self:RegisterEvent("UNIT_HEALTH")
end

function mod:OnEngage()
	self:SetStage(1)
	demonTargets, incinerateTargets = {}, {}
	warnedSoon = false
	if self:Difficulty() ~= 6 then
		self:Berserk(360)
		self:Bar("forms", 60, L.demon_form, "spell_shadow_metamorphosis")
		self:CDBar(37640, 18)
	end
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if not self:IsEngaged() then return end
	if msg:find(L.demon_trigger) then
		self:StopBar(L.demon_form)
		self:StopBar(37640)
		self:ScheduleTimer("Bar", 60, "forms", 45, L.demon_form, "spell_shadow_metamorphosis")
		self:ScheduleTimer("CDBar", 60, 37640, 19)
		self:Bar("forms", 60, L.normal_form, "inv_weapon_shortblade_07")
	elseif msg:find(L.stage2_trigger, nil, true) then
		self:StopBar(L.demon_form)
		self:StopBar(L.normal_form)
		self:CDBar(37640, 22.5)
	end
end

-- 3.3.5: DBM checks the creature id 2121 here (never true), 21215 is meant
function mod:UNIT_HEALTH(_, unit)
	if not self:IsEngaged() or self:GetStage() ~= 1 or self:MobId(self:UnitGUID(unit)) ~= 21215 then return end
	local hp = self:GetHealth(unit)
	local soon, stage2 = 27, 25
	if self:Difficulty() == 6 then soon, stage2 = 37, 35 end
	if not warnedSoon and hp <= soon then
		warnedSoon = true
		self:Message("stages", "cyan", CL.soon:format(CL.stage:format(2)), false)
	elseif warnedSoon and hp <= stage2 then
		self:SetStage(2)
		self:Message("stages", "cyan", CL.stage:format(2), false)
		self:PlaySound("stages", "long")
	end
end

function mod:Whirlwind(args)
	self:Message(37640, "red")
	self:CastBar(37640, 12)
	self:ScheduleTimer("CDBar", 12, 37640, 19)
end

function mod:InsidiousWhisperCast()
	self:Bar(37676, 32.5)
end

function mod:AnnounceDemons()
	self:TargetsMessage(37676, "orange", demonTargets, #demonTargets)
	for i = 1, #demonTargets do
		self:CustomIcon(demonMarker, demonTargets[i], 9 - i) -- 8, 7, 6, 5
	end
	demonTargets = {}
end

function mod:InsidiousWhisper(args)
	demonTargets[#demonTargets + 1] = args.destName
	if self:Me(args.destGUID) then
		self:PlaySound(37676, "warning")
	end
	self:CancelTimer(self.demonTimer)
	self.demonTimer = self:ScheduleTimer("AnnounceDemons", 0.1)
end

function mod:InsidiousWhisperRemoved(args)
	self:CustomIcon(demonMarker, args.destName)
end

function mod:TankStacks(args)
	self:StackMessage(args.spellId, "purple", args.destName, args.amount or 1, 5)
	self:TargetBar(args.spellId, 40, args.destName)
end

function mod:Flash(args)
	if (args.amount or 1) > 3 then
		self:StackMessage(310521, "purple", args.destName, args.amount, 5)
		self:TargetBar(310521, 60, args.destName)
	end
end

function mod:Brand(args)
	self:TargetMessage(310496, "red", args.destName)
	self:CustomIcon(brandMarker, args.destName, 8)
	self:ScheduleTimer("CustomIcon", 30, brandMarker, args.destName)
	self:TargetBar(310496, 30, args.destName)
	if self:Me(args.destGUID) then
		self:PlaySound(310496, "warning")
		self:Say(310496)
	end
end

function mod:IncinerateCast(args)
	self:Message(310514, "orange", CL.casting:format(args.spellName))
	if self:Healer() then
		self:PlaySound(310514, "alert") -- DBM: switch (healers)
	end
	self:CastBar(310514, 2)
end

function mod:Incinerate(args)
	incinerateTargets[#incinerateTargets + 1] = args.destName
	self:CustomIcon(incinerateMarker, args.destName, 8 - #incinerateTargets) -- 7, 6, 5, 4
	if self:Me(args.destGUID) then
		self:PersonalMessage(310514)
	end
	if #incinerateTargets >= 4 then
		self:TargetsMessage(310514, "yellow", incinerateTargets, #incinerateTargets)
		incinerateTargets = {}
	end
end

function mod:IncinerateRemoved(args)
	self:CustomIcon(incinerateMarker, args.destName)
end

function mod:Charge(args)
	self:TargetMessage(310481, "orange", args.destName)
	self:CastBar(310481, 3)
	if self:Me(args.destGUID) then
		self:PlaySound(310481, "warning")
	end
end

function mod:Metamorphosis(args)
	self:Message(310484, "cyan")
	self:CastBar(310484, 3)
end

function mod:Onslaught(args)
	self:TargetMessage(310478, "orange", args.destName)
	self:CastBar(310478, 3)
end

function mod:Gaze(args)
	self:Message(310516, "red")
	self:PlaySound(310516, "alarm")
	self:CastBar(310516, 5)
end

function mod:Run(args)
	self:Message(310510, "red")
	self:PlaySound(310510, "runaway")
end

function mod:Annihilation(args)
	self:Message(310508, "red")
	self:PlaySound(310508, "alarm")
	self:CastBar(310508, 10)
end

function mod:Soak(args)
	self:Message(args.spellId, "yellow")
	self:PlaySound(args.spellId, "info")
end
