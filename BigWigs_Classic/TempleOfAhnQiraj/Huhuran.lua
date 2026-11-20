--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-AQ40/Huhuran.lua)
-- DBM checks Acid Spit only on you, so its taunt warning never shows: the stacks of every tank are shown here.

local mod, CL = BigWigs:NewBoss("Princess Huhuran", 531, 1546)
if not mod then return end
mod:RegisterEnableMob(15509)
mod:SetEncounterID(714)

--------------------------------------------------------------------------------
-- Locals
--

local stingList = {}
local prevSting = 0
local warnedSoon = false

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		26180, -- Wyvern Sting
		26053, -- Noxious Poison
		26051, -- Frenzy
		26068, -- Berserk
		{26050, "TANK"}, -- Acid Spit (DBM: tanks only)
		"proximity",
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "WyvernSting", 26180)
	self:Log("SPELL_AURA_REMOVED", "WyvernStingRemoved", 26180)
	self:Log("SPELL_CAST_SUCCESS", "NoxiousPoison", 26053)
	self:Log("SPELL_AURA_APPLIED", "NoxiousPoisonApplied", 26053)
	self:Log("SPELL_AURA_REMOVED", "NoxiousPoisonRemoved", 26053)
	self:Log("SPELL_AURA_APPLIED", "Frenzy", 26051)
	self:Log("SPELL_AURA_APPLIED", "Berserk", 26068)
	self:Log("SPELL_AURA_APPLIED", "AcidSpit", 26050)
	self:Log("SPELL_AURA_APPLIED_DOSE", "AcidSpit", 26050)
	self:Log("SPELL_AURA_REMOVED", "AcidSpitRemoved", 26050)
	self:RegisterEvent("UNIT_HEALTH")
end

function mod:OnEngage()
	stingList = {}
	prevSting = 0
	warnedSoon = false
	self:CDBar(26051, 9.6) -- DBM: the timer is off by default
	self:CDBar(26053, 11)
	self:CDBar(26180, 20)
	if not self:Melee() then -- DBM: range frame for non-melee
		self:OpenProximity("proximity", 18)
	end
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:WyvernSting(args)
	if self:Player(args.destFlags) then
		if args.time - prevSting > 2 then
			prevSting = args.time
			self:CDBar(26180, 25)
		end
		if self:Dispeller("poison") then -- DBM: the targets for the poison removers only
			stingList[#stingList + 1] = args.destName
			self:TargetsMessage(26180, "yellow", stingList, nil, nil, nil, 1)
		end
		if self:Me(args.destGUID) then
			self:Bar(26180, 12, CL.you:format(args.spellName))
		end
	end
end

function mod:WyvernStingRemoved(args)
	if self:Me(args.destGUID) then
		self:StopBar(CL.you:format(args.spellName))
	end
end

function mod:NoxiousPoison(args)
	self:Message(26053, "orange")
	self:CDBar(26053, 11)
end

function mod:NoxiousPoisonApplied(args)
	if self:Me(args.destGUID) then
		self:Bar(26053, 8, CL.you:format(args.spellName))
	end
end

function mod:NoxiousPoisonRemoved(args)
	if self:Me(args.destGUID) then
		self:StopBar(CL.you:format(args.spellName))
	end
end

function mod:Frenzy(args)
	if not self:Player(args.destFlags) then
		self:Message(26051, "orange", CL.onboss:format(args.spellName))
		if self:Dispeller("enrage", true) then
			self:PlaySound(26051, "alarm") -- DBM: dispel the enrage
		end
		self:CDBar(26051, 11.8)
	end
end

function mod:Berserk(args)
	if not self:Player(args.destFlags) then
		self:Message(26068, "red")
		self:PlaySound(26068, "long")
		self:StopBar(26180)
		self:StopBar(26051)
		self:StopBar(26053)
	end
end

function mod:AcidSpit(args)
	local amount = args.amount or 1
	self:StackMessage(26050, "purple", args.destName, amount, 10)
	self:TargetBar(26050, 30, args.destName)
	if amount >= 10 then
		if self:Me(args.destGUID) then
			self:PlaySound(26050, "alarm")
		elseif not self:UnitDebuff("player", 26050) and not UnitIsDeadOrGhost("player") then
			self:PlaySound(26050, "warning") -- DBM: taunt
		end
	end
end

function mod:AcidSpitRemoved(args)
	self:StopBar(26050, args.destName)
end

function mod:UNIT_HEALTH(_, unit)
	if not warnedSoon and self:IsEngaged() and self:MobId(self:UnitGUID(unit)) == 15509 and self:GetHealth(unit) <= 38 then
		warnedSoon = true
		self:Message(26068, "yellow", CL.soon:format(self:SpellName(26068)))
	end
end
