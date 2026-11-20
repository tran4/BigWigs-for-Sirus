--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-AQ20/Kurinnaxx.lua)
-- DBM checks args.spellID for Mortal Wound, so its stack warnings never show: they are shown here.

local mod, CL = BigWigs:NewBoss("Kurinnaxx", 509, 1537)
if not mod then return end
mod:RegisterEnableMob(15348)
mod:SetEncounterID(718)

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		{25656, "SAY"}, -- Sand Trap
		{25646, "TANK"}, -- Mortal Wound (DBM: tanks only)
		26527, -- Frenzy
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CREATE", "SandTrap", 25648)
	self:Log("SPELL_AURA_APPLIED", "MortalWound", 25646)
	self:Log("SPELL_AURA_APPLIED_DOSE", "MortalWound", 25646)
	self:Log("SPELL_AURA_REMOVED", "MortalWoundRemoved", 25646)
	self:Log("SPELL_AURA_APPLIED", "Frenzy", 26527)
end

function mod:OnEngage()
	self:CDBar(25656, 8)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:SandTrap(args)
	self:CDBar(25656, 8)
	self:TargetMessage(25656, "yellow", args.sourceName)
	if self:Me(args.sourceGUID) then
		self:PlaySound(25656, "warning")
		self:Say(25656)
	end
end

function mod:MortalWound(args)
	local amount = args.amount or 1
	self:StackMessage(25646, "purple", args.destName, amount, 5)
	self:TargetBar(25646, 15, args.destName)
	if amount >= 5 then
		if self:Me(args.destGUID) then
			self:PlaySound(25646, "alarm")
		elseif not self:UnitDebuff("player", 25646) and not UnitIsDeadOrGhost("player") then
			self:PlaySound(25646, "warning") -- DBM: taunt
		end
	end
end

function mod:MortalWoundRemoved(args)
	self:StopBar(25646, args.destName)
end

function mod:Frenzy(args)
	if not self:Player(args.destFlags) then
		self:Message(26527, "orange", CL.onboss:format(args.spellName))
	end
end
