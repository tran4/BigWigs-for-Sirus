--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Karazhan/Moroes.lua, heroic mode with custom spells), draft by tools/dbm2bw
-- The guests are enable mobs (DBM SetCreatureID), only Moroes wins.

local mod, CL = BigWigs:NewBoss("Moroes", 532, 1554)
if not mod then return end
mod:RegisterEnableMob(15687, 19875, 19874, 19872, 17007, 19876, 19873)
mod:SetEncounterID(653)
mod:SetWinMobs(15687)

--------------------------------------------------------------------------------
-- Initialization
--

local markMarker = mod:AddMarkerOption(true, "player", 8, 305470, 8)
function mod:GetOptions()
	return {
		"stages",
		"berserk",
		305472, -- Dance
		{305470, "ME_ONLY_EMPHASIZE"}, -- Death Mark
		markMarker,
		305461, -- Killing Spree
		305464, -- Pierce
		305463, -- Wound
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "Pierce", 305464)
	self:Log("SPELL_CAST_START", "Wound", 305463)
	self:Log("SPELL_CAST_START", "Dance", 305472)
	self:Log("SPELL_CAST_SUCCESS", "KillingSpree", 305460)
	self:Log("SPELL_AURA_APPLIED", "DeathMark", 305470)
end

function mod:OnEngage()
	self:SetStage(1)
	if self:Difficulty() == 5 then -- 10 heroic
		self:CDBar(305472, 20)
		self:DelayedMessage(305472, 17, "yellow", CL.soon:format(self:SpellName(305472))) -- DBM: warnDanceSoon:Show(17)
		self:Bar("stages", 180, CL.stage:format(2), "achievement_bg_returnxflags_def_wsg")
		self:ScheduleTimer("Stage2", 180)
		self:Berserk(525)
	end
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:Stage2()
	self:SetStage(2)
	self:Message("stages", "cyan", CL.stage:format(2), false)
	self:PlaySound("stages", "long")
	self:CDBar(305470, 25)
	self:CDBar(305461, 79)
	self:StopBar(305472)
	self:CancelDelayedMessage(CL.soon:format(self:SpellName(305472)))
end

-- 3.3.5: DBM shows these after a flag that is never set (vb.phase2), shown in stage 2 here
function mod:Pierce()
	if self:GetStage() == 2 then
		self:CDBar(305464, 10)
	end
end

function mod:Wound()
	if self:GetStage() == 2 then
		self:CDBar(305463, 10)
	end
end

function mod:Dance(args)
	self:Message(305472, "orange")
	self:PlaySound(305472, "alert")
	self:CDBar(305472, 20)
	self:DelayedMessage(305472, 17, "yellow", CL.soon:format(args.spellName))
end

function mod:KillingSpree()
	self:CDBar(305461, 85)
end

function mod:DeathMark(args)
	self:TargetMessage(305470, "red", args.destName)
	if self:Me(args.destGUID) then
		self:PlaySound(305470, "warning") -- DBM: run
	end
	self:TargetBar(305470, 7, args.destName)
	self:CDBar(305470, 25)
	self:CustomIcon(markMarker, args.destName, 8)
	self:ScheduleTimer("CustomIcon", 7, markMarker, args.destName)
end
