--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-MC/Magmadar.lua)

local mod, CL = BigWigs:NewBoss("Magmadar", 409, 1520)
if not mod then return end
mod:RegisterEnableMob(11982)
mod:SetEncounterID(664)

--------------------------------------------------------------------------------
-- Locals
--

local conflagList = {}

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		19408, -- Panic
		19451, -- Frenzy
		{19428, "OFF"}, -- Conflagration
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_SUCCESS", "Panic", 19408)
	self:Log("SPELL_AURA_APPLIED", "Frenzy", 19451)
	self:Log("SPELL_AURA_REMOVED", "FrenzyRemoved", 19451)
	self:Log("SPELL_AURA_APPLIED", "Conflagration", 19428)
end

function mod:OnEngage()
	conflagList = {}
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:Panic(args)
	self:Message(19408, "yellow")
	self:CDBar(19408, 30)
end

function mod:Frenzy(args)
	if not self:Player(args.destFlags) then
		self:Message(19451, "orange", CL.onboss:format(args.spellName))
		if self:Dispeller("enrage", true) then
			self:PlaySound(19451, "alarm") -- DBM: dispel the enrage
		end
		self:Bar(19451, 8)
	end
end

function mod:FrenzyRemoved(args)
	if not self:Player(args.destFlags) then
		self:StopBar(19451)
	end
end

function mod:Conflagration(args)
	if self:Player(args.destFlags) then
		conflagList[#conflagList + 1] = args.destName
		self:TargetsMessage(19428, "yellow", conflagList, nil, nil, nil, 0.5)
	end
end
