--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Karazhan/PrinceMalchezaar.lua, heroic mode with custom spells), draft by tools/dbm2bw
-- Heroic stages by health (80/40/30/20/10%) like DBM. Not ported: announcing the curse targets to the raid chat.

local mod, CL = BigWigs:NewBoss("Prince Malchezaar", 532, 1563)
if not mod then return end
mod:RegisterEnableMob(15690)
mod:SetEncounterID(661)

--------------------------------------------------------------------------------
-- Locals
--

local flameCount, flameNeed4, flameLoop = 0, false, false
local flameTargets = {}

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	stage2_trigger = "Simple fools! Time is the fire in which you'll burn!",
	stage3_trigger = "How can you hope to stand against such overwhelming power?",
	infernal_trigger1 = "All realities, all dimensions are open to me!",
	infernal_trigger2 = "You face not Malchezaar alone, but the legions I command!",

	-- heroic stages, DBM has no English texts
	flame_world = "Огненные просторы",
	ice_world = "Ледяная пустошь",
	black_forest = "Черный лес",
	last_stage = "Финал",
})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"stages",
		37277, -- Summon Infernal
		30852, -- Shadow Nova
		305425, -- heroic: nova
		305433, -- heroic: flame
		305435, -- heroic: curse
		305443, -- heroic: ice spike
		305447, -- heroic: call of the dead
		{305429, "SAY"}, -- heroic: Vengeful Corruption
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "HeroicNova", 305425)
	self:Log("SPELL_CAST_START", "IceSpike", 305443)
	self:Log("SPELL_CAST_START", "CallOfTheDead", 305447)
	self:Log("SPELL_CAST_START", "ShadowNova", 30852)
	self:Log("SPELL_AURA_APPLIED", "Flame", 305433, 305434)
	self:Log("SPELL_AURA_APPLIED", "Curse", 305435)
	self:Log("SPELL_AURA_APPLIED", "Corruption", 305429)
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
	self:RegisterEvent("UNIT_HEALTH")
end

function mod:OnEngage()
	self:SetStage(1)
	flameCount, flameNeed4, flameLoop = 0, false, false
	flameTargets = {}
	if self:Difficulty() == 5 then -- 10 heroic
		self:CDBar(305435, 20)
		self:CDBar(305425, 12)
	else
		self:CDBar(37277, 45)
		self:CDBar(30852, 35)
	end
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if not self:IsEngaged() then return end
	local stage = self:GetStage()
	local infernal = msg == L.infernal_trigger1 or msg == L.infernal_trigger2
	if stage == 1 and infernal then
		self:Message(37277, "orange")
		self:CDBar(37277, 45)
	elseif stage == 2 and msg == L.stage3_trigger then
		self:SetStage(3)
		self:Message("stages", "cyan", CL.stage:format(3), false)
		self:Message(37277, "orange")
		self:CDBar(37277, 15)
		self:CDBar(30852, 30)
	elseif stage == 1 and msg == L.stage2_trigger then
		self:SetStage(2)
		self:Message("stages", "cyan", CL.stage:format(2), false)
	elseif stage == 3 and infernal then
		self:CDBar(37277, 17)
	end
end

function mod:ShadowNova()
	self:CDBar(30852, 30)
end

function mod:HeroicNova(args)
	self:Message(305425, "orange", CL.casting:format(args.spellName))
	self:CDBar(305425, 12)
end

function mod:IceSpike()
	self:CDBar(305443, 10)
end

function mod:CallOfTheDead(args)
	self:CDBar(305447, 10)
	if args.destName then
		self:TargetMessage(305447, "yellow", args.destName)
		if self:Me(args.destGUID) then
			self:PlaySound(305447, "warning")
		end
	end
end

function mod:Flame(args) -- DBM: 2 3 3 3 4 3 3 3 4, then the 3 3 3 4 loop
	if not flameLoop then
		flameLoop = true
	else
		flameCount = flameCount + 1
		if flameCount >= 3 then flameNeed4 = true end
		if flameCount >= 4 then
			flameNeed4 = false
			flameCount = 0
		end
	end
	local stage = self:GetStage()
	self:CDBar(305433, stage < 3 and (flameNeed4 and 48 or 36) or 10)
	flameTargets[#flameTargets + 1] = args.destName
	if #flameTargets >= 2 and stage < 3 then
		self:TargetsMessage(305433, "orange", flameTargets, #flameTargets)
		flameTargets = {}
	elseif stage >= 3 then
		self:TargetMessage(305433, "orange", args.destName)
		flameTargets = {}
	end
	if self:Me(args.destGUID) then
		self:PlaySound(305433, "warning")
	end
end

function mod:Curse()
	self:CDBar(305435, self:GetStage() == 2 and 30 or 20)
end

do
	local playerList = {}
	local prev = 0
	function mod:Corruption(args)
		if args.time - prev > 1 then
			prev = args.time
			playerList = {}
		end
		playerList[#playerList + 1] = args.destName
		self:TargetsMessage(305429, "red", playerList, nil, nil, nil, 0.1)
		if self:Me(args.destGUID) then
			self:Say(305429)
		end
	end
end

local function stageMessage(self, stage, name)
	self:SetStage(stage)
	self:Message("stages", "cyan", name and CL.other:format(CL.stage:format(stage), name) or CL.stage:format(stage), false)
	self:PlaySound("stages", "info")
end

function mod:UNIT_HEALTH(_, unit)
	if not self:IsEngaged() or self:MobId(self:UnitGUID(unit)) ~= 15690 then return end
	local stage, hp = self:GetStage(), self:GetHealth(unit)
	if self:Difficulty() == 5 then -- 10 heroic
		if stage == 1 and hp <= 80 then
			stageMessage(self, 2)
			self:CDBar(305433, 20)
			self:CDBar(305435, 20)
		elseif stage == 2 and hp <= 40 then
			stageMessage(self, 3, L.flame_world)
			self:StopBar(305435)
			self:StopBar(305425)
			self:CDBar(305433, 10)
		elseif stage == 3 and hp <= 30 then
			stageMessage(self, 4, L.ice_world)
			self:StopBar(305433)
			self:CDBar(305443, 10)
			self:CDBar(305435, 20)
		elseif stage == 4 and hp <= 20 then
			stageMessage(self, 5, L.black_forest)
			self:StopBar(305435)
			self:StopBar(305443)
			self:CDBar(305447, 10)
		elseif stage == 5 and hp <= 10 then
			stageMessage(self, 6, L.last_stage)
			self:StopBar(305447)
			self:CDBar(305433, 30)
		end
	else
		if stage == 1 and hp <= 60 then
			self:SetStage(2)
		elseif stage == 2 and hp <= 30 then
			self:SetStage(3)
		end
	end
end
