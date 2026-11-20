--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Karazhan/TerestianIllhoof.lua, heroic mode with custom spells), draft by tools/dbm2bw

local mod, CL = BigWigs:NewBoss("Terestian Illhoof", 532, 1560)
if not mod then return end
mod:RegisterEnableMob(15688)
mod:SetEncounterID(657)

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		30115, -- Sacrifice (normal)
		305345, -- Hand (heroic)
		305351, -- Mark (heroic)
		305367, -- Dart (heroic)
		{305360, "TANK"}, -- Seed (heroic)
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "Hand", 305345)
	self:Log("SPELL_AURA_APPLIED", "Mark", 305351)
	self:Log("SPELL_AURA_APPLIED", "Sacrifice", 30115)
	self:Log("SPELL_AURA_APPLIED", "Dart", 305367)
	self:Log("SPELL_AURA_APPLIED_DOSE", "Dart", 305367) -- 3.3.5: DBM only registers SPELL_AURA_APPLIED, the stacks come as _DOSE
	self:Log("SPELL_AURA_APPLIED", "Seed", 305360)
end

function mod:OnEngage()
	if self:Difficulty() == 5 then -- 10 heroic
		self:CDBar(305345, 15)
		self:CDBar(305351, 33)
	else
		self:CDBar(30115, 28)
	end
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:Hand(args)
	self:Message(305345, "orange", CL.casting:format(args.spellName))
	self:CDBar(305345, 15)
end

function mod:Mark(args)
	if self:MobId(args.sourceGUID) == 15688 then -- DBM: cast by the boss (sourceName == L.name)
		self:CDBar(305351, 33)
		self:TargetMessage(305351, "yellow", args.destName)
	end
	if self:Me(args.destGUID) then
		self:PlaySound(305351, "warning")
	end
end

function mod:Sacrifice(args)
	self:CDBar(30115, 42)
end

function mod:Dart(args)
	if self:Me(args.destGUID) and (args.amount or 1) >= 7 then
		self:StackMessage(305367, "blue", args.destName, args.amount, 7)
		self:PlaySound(305367, "alarm")
	end
end

function mod:Seed(args)
	if self:Me(args.destGUID) then
		self:PersonalMessage(305360)
		self:PlaySound(305360, "alert")
	end
end
