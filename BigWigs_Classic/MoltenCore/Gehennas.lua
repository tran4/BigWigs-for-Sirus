--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-MC/Gehennas.lua)

local mod, CL = BigWigs:NewBoss("Gehennas", 409, 1521)
if not mod then return end
mod:RegisterEnableMob(12259)
mod:SetEncounterID(665)

--------------------------------------------------------------------------------
-- Locals
--

local fistList = {}

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		19716, -- Gehennas' Curse
		19717, -- Rain of Fire
		{20277, "OFF"}, -- Fist of Ragnaros
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_SUCCESS", "GehennasCurse", 19716)
	self:Log("SPELL_CAST_SUCCESS", "RainOfFire", 19717)
	self:Log("SPELL_PERIODIC_DAMAGE", "RainOfFireDamage", 19717)
	self:Log("SPELL_PERIODIC_MISSED", "RainOfFireDamage", 19717)
	self:Log("SPELL_AURA_APPLIED", "FistOfRagnaros", 20277)
end

function mod:OnEngage()
	fistList = {}
	self:CDBar(19716, 6)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:GehennasCurse(args)
	if self:Hostile(args.sourceFlags) then
		self:Message(19716, "orange")
		self:CDBar(19716, 26.7)
	end
end

function mod:RainOfFire(args)
	if self:Hostile(args.sourceFlags) then
		self:CDBar(19717, 6) -- DBM: the message and the timer are off by default
	end
end

do
	local prev = 0
	function mod:RainOfFireDamage(args)
		if self:Me(args.destGUID) and args.time - prev > 2 then
			prev = args.time
			self:PersonalMessage(19717, "underyou")
			self:PlaySound(19717, "underyou")
		end
	end
end

function mod:FistOfRagnaros(args)
	if self:Player(args.destFlags) then
		fistList[#fistList + 1] = args.destName
		self:TargetsMessage(20277, "yellow", fistList)
		self:Bar(20277, 4)
	end
end
