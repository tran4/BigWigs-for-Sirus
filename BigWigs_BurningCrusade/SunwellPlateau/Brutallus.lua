--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Sunwell/Brutallus.lua), draft by tools/dbm2bw

local mod, CL = BigWigs:NewBoss("Brutallus", 580, 1592)
if not mod then return end
mod:RegisterEnableMob(24882)
mod:SetEncounterID(725)

--------------------------------------------------------------------------------
-- Locals
--

local burnIcon = 8
local prevBurn = 0

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	engage_trigger = "Ah, more lambs to the slaughter!",
})

--------------------------------------------------------------------------------
-- Initialization
--

local burnMarker = mod:AddMarkerOption(true, "player", 8, 46394, 8, 7, 6, 5, 4, 3, 2, 1)
function mod:GetOptions()
	return {
		{46394, "SAY", "PROXIMITY"}, -- Burn
		burnMarker,
		45185, -- Stomp
		45150, -- Meteor Slash
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "Burn", 46394)
	self:Log("SPELL_AURA_REMOVED", "BurnRemoved", 46394)
	self:Log("SPELL_MISSED", "BurnMissed", 46394)
	self:Log("SPELL_AURA_APPLIED", "Stomp", 45185)
	self:Log("SPELL_CAST_START", "MeteorSlash", 45150)
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
end

function mod:OnEngage()
	burnIcon = 8
	prevBurn = 0
	self:CDBar(46394, 20)
	self:CDBar(45185, 31)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if msg:find(L.engage_trigger, nil, true) and not self:IsEngaged() then
		self:Engage() -- DBM RegisterCombat("yell")
	end
end

function mod:Burn(args)
	self:TargetMessage(46394, "orange", args.destName)
	if args.time - prevBurn > 19 then
		prevBurn = args.time
		self:CDBar(46394, 20)
	end
	self:CustomIcon(burnMarker, args.destName, burnIcon)
	burnIcon = burnIcon == 1 and 8 or burnIcon - 1
	if self:Me(args.destGUID) then
		self:PlaySound(46394, "warning")
		self:Say(46394)
	end
	self:OpenProximity(46394, 4) -- DBM: range frame on the debuff
end

function mod:BurnRemoved(args)
	self:CustomIcon(burnMarker, args.destName)
end

function mod:BurnMissed(args)
	if args.time - prevBurn > 19 then
		prevBurn = args.time
		self:CDBar(46394, 20)
	end
end

function mod:Stomp(args)
	self:TargetMessage(45185, "purple", args.destName)
	if not self:Me(args.destGUID) then
		self:PlaySound(45185, "warning") -- DBM: taunt
	end
	self:CDBar(45185, 31)
end

function mod:MeteorSlash(args)
	self:Message(45150, "red")
	self:CDBar(45150, 12)
end
