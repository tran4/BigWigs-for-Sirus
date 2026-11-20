--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Karazhan/Curator.lua, heroic mode with three constructs), draft by tools/dbm2bw
-- Normal: The Curator (15691). Heroic: three constructs (99972-99974), the deactivated ones have the 305313 aura;
-- DBM checks boss1-3 for it, so does this module.

local mod, CL = BigWigs:NewBoss("The Curator", 532, 1557)
if not mod then return end
mod:RegisterEnableMob(99973, 99972, 99974, 15691)
mod:SetEncounterID(656)

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	evocation_trigger = "Your request cannot be processed.",
})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		30254, -- Evocation (normal)
		305296, -- Runes (heroic)
		305312, -- Annihilation (heroic)
		305305, -- Lightning Conductor (heroic)
		305309, -- Unstable Energy (heroic)
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_REMOVED", "DeactivationRemoved", 305313)
	self:Log("SPELL_AURA_APPLIED", "LightningConductor", 305305)
	self:Log("SPELL_AURA_APPLIED", "UnstableEnergy", 305309)
	self:Log("SPELL_AURA_REMOVED", "UnstableEnergy", 305309)
	self:Log("SPELL_CAST_START", "Runes", 305296)
	self:Log("SPELL_CAST_START", "Annihilation", 305312)
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
end

function mod:OnEngage()
	if self:Difficulty() == 5 then -- 10 heroic: all three constructs must die
		self:SetWinMobs(99972, 99973, 99974)
		self:ActiveConstructBars()
	else
		self:SetWinMobs(15691)
		self:Bar(30254, 101)
	end
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:ActiveConstructBars()
	local deactivation = self:SpellName(305313)
	for i = 1, 3 do
		if not UnitDebuff("boss" .. i, deactivation) then
			if i == 3 then
				self:CDBar(305312, 23)
				self:CDBar(305305, 11)
			elseif i == 1 then
				self:CDBar(305296, 25)
			end
		end
	end
end

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if msg == L.evocation_trigger then
		self:Message(30254, "cyan")
		self:Bar(30254, 101)
	end
end

function mod:DeactivationRemoved()
	self:ActiveConstructBars()
end

function mod:LightningConductor(args)
	self:CDBar(305305, 11)
	if self:Me(args.destGUID) then
		self:PersonalMessage(305305)
		self:PlaySound(305305, "alarm")
	end
end

function mod:UnstableEnergy(args)
	local list = {}
	for unit in self:IterateGroup() do
		if UnitDebuff(unit, args.spellName) then
			list[#list + 1] = self:UnitName(unit)
		end
	end
	if #list > 0 then
		self:Message(305309, "orange", CL.on:format(args.spellName, table.concat(list, ", ")))
	end
end

function mod:Runes(args)
	self:Message(305296, "red")
	self:PlaySound(305296, "runaway")
	self:CDBar(305296, 25)
	self:Bar(305296, 8, CL.explosion)
end

function mod:Annihilation()
	self:CDBar(305312, 23)
end
