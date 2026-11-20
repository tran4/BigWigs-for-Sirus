--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Naxx/ConstructQuarter/Grobbulus.lua), draft by tools/dbm2bw

local mod, CL = BigWigs:NewBoss("Grobbulus", 533, 1611)
if not mod then return end
mod:RegisterEnableMob(15931)
mod:SetEncounterID(1111)

--------------------------------------------------------------------------------
-- Locals
--

local myRealm = false -- 3.3.5: DBM Sirus has other timers on the x1 realm
local slimeSprays = 1
local injectionIcons = {}

--------------------------------------------------------------------------------
-- Initialization
--

local injectionMarker = mod:AddMarkerOption(false, "player", 1, 28169, 1, 2, 3, 4)
function mod:GetOptions()
	return {
		"berserk",
		{28169, "SAY"}, -- Mutating Injection
		injectionMarker,
		28240, -- Poison Cloud
		54364, -- Slime Spray
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "MutatingInjection", 28169)
	self:Log("SPELL_AURA_REMOVED", "MutatingInjectionRemoved", 28169)
	self:Log("SPELL_CAST_SUCCESS", "PoisonCloud", 28240)
	self:Log("SPELL_CAST_SUCCESS", "SlimeSpray", 28157, 54364)
end

function mod:OnEngage()
	myRealm = BigWigsLoader.Compat.GetRealmNumber() == 1
	slimeSprays = 1
	injectionIcons = {}
	self:Berserk(myRealm and 600 or 720)
	self:Bar(28240, myRealm and 14 or 15)
	self:DelayedMessage(54364, 27, "yellow", CL.soon:format(self:SpellName(54364)))
	self:Bar(54364, myRealm and 20 or 32)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:MutatingInjection(args)
	self:TargetMessage(28169, "orange", args.destName)
	self:TargetBar(28169, 10, args.destName)
	if self:Me(args.destGUID) then
		self:PlaySound(28169, "warning")
		self:Say(28169)
	end
	for icon = 1, 4 do
		if not injectionIcons[icon] then
			injectionIcons[icon] = args.destName
			self:CustomIcon(injectionMarker, args.destName, icon)
			break
		end
	end
end

function mod:MutatingInjectionRemoved(args)
	self:StopBar(args.spellName, args.destName) -- DBM: cancel the timer if someone dispels it
	for icon = 1, 4 do
		if injectionIcons[icon] == args.destName then
			injectionIcons[icon] = nil
			self:CustomIcon(injectionMarker, args.destName)
		end
	end
end

function mod:PoisonCloud(args)
	self:Message(28240, "yellow")
	self:Bar(28240, 15)
end

function mod:SlimeSpray(args)
	self:Message(54364, "orange")
	slimeSprays = slimeSprays + 1
	local spray = self:SpellName(54364)
	if slimeSprays % 2 == 0 then -- DBM: every 2/4/6... spray short cd
		self:DelayedMessage(54364, myRealm and 20 or 26, "yellow", CL.soon:format(spray))
		self:Bar(54364, myRealm and 20 or 31)
	else -- every 3/5/7... spray long cd
		self:DelayedMessage(54364, myRealm and 20 or 54, "yellow", CL.soon:format(spray))
		self:Bar(54364, myRealm and 20 or 59)
	end
end
