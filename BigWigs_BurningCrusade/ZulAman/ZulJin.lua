--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-ZulAman/Zul'jin.lua), draft by tools/dbm2bw
-- Stages by health (81/61/41/20%) and by the yells, like DBM. Not ported: the Flame Pillar target (DBM UNIT_TARGET,
-- not registered by DBM).

local mod, CL = BigWigs:NewBoss("Zul'jin", 568, 191)
if not mod then return end
mod:RegisterEnableMob(23863)
mod:SetEncounterID(1194)

--------------------------------------------------------------------------------
-- Locals
--

local bleedTargets = {}

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	engage_trigger = "У нас вечно хотят что-то отнять. Теперь мы вернем себе все. Любой, кто встанет у нас на пути, захлебнется в собственной крови! Империя Амани возрождается...ради мщения. И начнем мы...с вас!", -- DBM: no English text
	stage2_trigger = "Got me some new tricks... like me brudda bear....",
	stage3_trigger = "Dere be no hidin' from da eagle!",
	stage4_trigger = "Let me introduce you to me new bruddas: fang and claw!",
	stage5_trigger = "Ya don' have to look to da sky to see da dragonhawk!",
	bear_trigger = "Сейчас-сейчас. Выучил вот пару новых фокусов... вместе с братишкой-медведем.", -- DBM: no English text
	lynx_trigger = "Знакомьтесь, мои новые братишки: клык и коготь!", -- DBM: no English text

	-- DBM: no English texts
	bear = "медведя",
	hawk = "орла",
	lynx = "рыси",
	dragon = "драконодора",
	stage_soon = "Скоро фаза %s",
})

--------------------------------------------------------------------------------
-- Initialization
--

local throwMarker = mod:AddMarkerOption(true, "player", 7, 43093, 7)
function mod:GetOptions()
	return {
		"stages",
		"berserk",
		17207, -- Whirlwind
		43093, -- Grievous Throw
		throwMarker,
		43095, -- Creeping Paralysis
		43153, -- Lynx Rush
		43215, -- Flame Breath
		43213, -- Flame Whirl
		43216, -- Flame Pillar
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "GrievousThrow", 43093)
	self:Log("SPELL_AURA_APPLIED", "Whirlwind", 17207)
	self:Log("SPELL_AURA_APPLIED", "LynxRush", 43153)
	self:Log("SPELL_CAST_SUCCESS", "CreepingParalysis", 43095)
	self:Log("SPELL_CAST_SUCCESS", "FlameBreath", 43215)
	self:Log("SPELL_CAST_SUCCESS", "FlameWhirl", 43213)
	self:Log("SPELL_CAST_SUCCESS", "GrievousThrowSuccess", 43093)
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
	self:RegisterEvent("UNIT_HEALTH")
end

function mod:OnEngage()
	self:SetStage(1)
	bleedTargets = {}
	self:CDBar(17207, 9.5)
	self:CDBar(43093, 20)
	self:Berserk(600)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if msg:find(L.engage_trigger, nil, true) then
		if not self:IsEngaged() then self:Engage() end -- DBM RegisterCombat("yell")
		return
	elseif not self:IsEngaged() then
		return
	end
	local stage = msg:find(L.stage2_trigger, nil, true) and 2 or msg:find(L.stage3_trigger, nil, true) and 3
		or msg:find(L.stage4_trigger, nil, true) and 4 or msg:find(L.stage5_trigger, nil, true) and 5
	if stage then
		self:SetStage(stage)
		self:Message("stages", "cyan", CL.stage:format(stage), false)
		self:PlaySound("stages", "long")
		if stage == 3 then
			self:StopBar(43095)
		end
	elseif msg == L.bear_trigger then
		self:StopBar(17207)
		self:StopBar(43093)
		self:CDBar(43095, 20)
	elseif msg == L.lynx_trigger then
		self:CDBar(43153, 10)
	end
end

function mod:UNIT_HEALTH(_, unit)
	if not self:IsEngaged() or self:MobId(self:UnitGUID(unit)) ~= 23863 then return end
	local hp, stage = self:GetHealth(unit), self:GetStage()
	if stage == 1 and hp <= 81 then
		self:SetStage(2)
		self:Message("stages", "cyan", L.stage_soon:format(L.bear), false)
	elseif stage == 2 and hp <= 61 then
		self:SetStage(3)
		self:Message("stages", "cyan", L.stage_soon:format(L.hawk), false)
	elseif stage == 3 and hp <= 41 then
		self:SetStage(4)
		self:Message("stages", "cyan", L.stage_soon:format(L.lynx), false)
	elseif stage == 4 and hp <= 20 then
		self:SetStage(5)
		self:Message("stages", "cyan", L.stage_soon:format(L.dragon), false)
		self:StopBar(43153)
		self:CDBar(43216, 18)
	end
end

function mod:GrievousThrow(args)
	self:TargetMessage(43093, "orange", args.destName)
	self:CustomIcon(throwMarker, args.destName, 7)
	self:ScheduleTimer("CustomIcon", 4, throwMarker, args.destName)
end

function mod:GrievousThrowSuccess()
	self:CDBar(43093, 10)
end

function mod:Whirlwind()
	self:CDBar(17207, 17)
end

function mod:AnnounceBleeds()
	if #bleedTargets > 0 then
		self:TargetsMessage(43153, "red", bleedTargets, #bleedTargets)
	end
	bleedTargets = {}
	self.bleedTimer = nil
	self:CDBar(43153, 20)
end

function mod:LynxRush(args)
	if self:Player(args.destFlags) then
		bleedTargets[#bleedTargets + 1] = args.destName
	end
	if not self.bleedTimer then
		self.bleedTimer = self:ScheduleTimer("AnnounceBleeds", 1.5)
	end
end

function mod:CreepingParalysis(args)
	self:Message(43095, "orange")
	self:CDBar(43095, 20)
end

function mod:FlameBreath()
	self:CDBar(43215, 10)
end

function mod:FlameWhirl()
	self:CDBar(43213, 12)
end
