--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Serpentshrine/Tidewalker.lua, heroic mode with custom spells), draft by tools/dbm2bw
-- Most texts of the Sirus version are only in the Russian DBM localization: the English defaults are the Russian texts.

local mod, CL = BigWigs:NewBoss("Morogrim Tidewalker", 548, 1571)
if not mod then return end
mod:RegisterEnableMob(21213)
mod:SetEncounterID(627)

--------------------------------------------------------------------------------
-- Locals
--

local graveTargets = {}
local warnedSoon = false

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	engage_trigger = "Да поглотит вас пучина вод!", -- DBM: no English text
	murlocs_trigger = "Сильный толчок землетрясения насторожил мурлоков поблизости!", -- DBM: no English text
	graves_trigger = "%s отправляет своих врагов в водяные могилы!", -- DBM: no English text, raw emote text
	globes_trigger = "%s призывает водяные шары!", -- DBM: no English text, raw emote text

	murlocs = "Murlocs",
	murlocs_desc = "Show warnings and timer for Murlocs spawning",
	murlocs_icon = "inv_misc_monsterhead_02",
	murlocs_soon = "Murlocs Coming!",
	globes = "Глобулы", -- DBM: no English text
	globes_desc = "Объявлять о появлении глобул", -- DBM: no English text
	globes_icon = "spell_frost_summonwaterelemental",
	globes_msg = "Глобулы!", -- DBM: no English text
})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"stages",
		"berserk",
		"murlocs",
		37850, -- Watery Grave
		"globes",
		-- heroic
		{310136, "TANK"}, -- Gaze
		310144, -- Grip
		310152, -- Earthquake
		310151, -- Scream
		310140, -- Stomp
		310137, -- Mon
		310155, -- Suh
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "Earthquake", 310152)
	self:Log("SPELL_CAST_START", "Scream", 310151)
	self:Log("SPELL_CAST_SUCCESS", "Stomp", 310140)
	self:Log("SPELL_AURA_APPLIED", "Gaze", 310136)
	self:Log("SPELL_AURA_APPLIED_DOSE", "Gaze", 310136)
	self:Log("SPELL_AURA_APPLIED", "Grip", 310144)
	self:Log("SPELL_AURA_APPLIED", "Suh", 310155)
	self:Log("SPELL_AURA_APPLIED", "Mon", 310138)
	self:Log("SPELL_AURA_APPLIED", "WateryGrave", 37850, 38023, 38024, 38025, 38049)
	self:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE")
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
	self:RegisterEvent("UNIT_HEALTH")
end

function mod:OnEngage()
	self:SetStage(1)
	graveTargets = {}
	warnedSoon = false
	if self:Difficulty() == 6 then -- 25 heroic
		self:Berserk(360)
	else
		self:Berserk(480)
		self:DelayedMessage("murlocs", 37, "yellow", L.murlocs_soon, L.murlocs_icon)
		self:Bar("murlocs", 42, L.murlocs, L.murlocs_icon)
		self:CDBar(37850, 30)
	end
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if msg:find(L.engage_trigger, nil, true) and not self:IsEngaged() then
		self:Engage() -- DBM RegisterCombat("yell")
	end
end

function mod:UNIT_HEALTH(_, unit)
	if self:Difficulty() ~= 6 or self:GetStage() ~= 1 or self:MobId(self:UnitGUID(unit)) ~= 21213 then return end
	local hp = self:GetHealth(unit)
	if not warnedSoon and hp <= 52 then
		warnedSoon = true
		self:Message("stages", "cyan", CL.soon:format(CL.stage:format(2)), false)
	elseif warnedSoon and hp <= 50 then
		self:SetStage(2)
		self:Message("stages", "cyan", CL.stage:format(2), false)
		self:PlaySound("stages", "long")
		self:Berserk(360)
	end
end

function mod:Earthquake(args)
	self:Message(310152, "red")
	self:PlaySound(310152, "runaway")
	self:CastBar(310152, 8)
	self:CDBar(310152, 45)
	self:OpenProximity(310152, 8)
end

function mod:Scream(args)
	self:Message(310151, "orange", CL.casting:format(args.spellName))
	if self:Ranged() then -- DBM: SpellCaster
		self:PlaySound(310151, "alert")
	end
	self:CDBar(310151, 28)
	self:CastBar(310151, 3)
end

function mod:Stomp(args)
	self:Message(310140, "orange")
	self:CastBar(310140, 3)
	self:CDBar(310140, 20)
end

function mod:Gaze(args)
	self:StackMessage(310136, "purple", args.destName, args.amount or 1, 5)
	self:TargetBar(310136, 60, args.destName)
end

function mod:Grip(args)
	self:TargetMessage(310144, "yellow", args.destName)
	self:TargetBar(310144, 3, args.destName)
	self:CDBar(310144, 32)
end

function mod:Suh()
	self:CDBar(310155, 20)
end

function mod:Mon()
	self:Message(310137, "red")
	self:CDBar(310137, 12)
end

-- 3.3.5: DBM keys these ids by strings and compares numbers, so its list stays empty
function mod:WateryGrave(args)
	graveTargets[#graveTargets + 1] = args.destName
end

function mod:AnnounceGraves()
	if #graveTargets > 0 then
		self:TargetsMessage(37850, "orange", graveTargets, #graveTargets)
	end
	graveTargets = {}
end

function mod:CHAT_MSG_RAID_BOSS_EMOTE(_, msg)
	if msg:find(L.murlocs_trigger, nil, true) then
		self:CancelDelayedMessage(L.murlocs_soon)
		self:DelayedMessage("murlocs", 45, "yellow", L.murlocs_soon, L.murlocs_icon)
		self:Bar("murlocs", 50, L.murlocs, L.murlocs_icon)
	elseif msg:find(L.graves_trigger, nil, true) then
		self:CDBar(37850, 30)
		self:ScheduleTimer("AnnounceGraves", 0.2)
	elseif msg:find(L.globes_trigger, nil, true) then
		self:Message("globes", "cyan", L.globes_msg, L.globes_icon)
	end
end
