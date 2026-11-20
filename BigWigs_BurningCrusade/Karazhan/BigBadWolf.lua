--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Karazhan/BigBadWolf.lua), draft by tools/dbm2bw
-- Opera event, no journal id: the name is from the DBM localization.

local mod, CL = BigWigs:NewBoss("The Big Bad Wolf", 532)
if not mod then return end
mod:RegisterEnableMob(17521)
mod:SetEncounterID(655)

--------------------------------------------------------------------------------
-- Locals
--

local prevFear = 0

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	bossName = "The Big Bad Wolf",
	engage_trigger = "The better to own you with!",
})
mod.displayName = L.bossName

--------------------------------------------------------------------------------
-- Initialization
--

local hoodMarker = mod:AddMarkerOption(true, "player", 8, 30753, 8)
function mod:GetOptions()
	return {
		30753, -- Red Riding Hood
		hoodMarker,
		30752, -- Terrifying Howl
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "RedRidingHood", 30753)
	self:Log("SPELL_AURA_APPLIED", "TerrifyingHowl", 30752)
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
end

function mod:OnEngage()
	prevFear = 0
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if msg:find(L.engage_trigger, nil, true) and not self:IsEngaged() then
		self:Engage() -- DBM RegisterCombat("yell")
	end
end

function mod:RedRidingHood(args)
	self:TargetMessage(30753, "red", args.destName)
	if self:Me(args.destGUID) then
		self:PlaySound(30753, "warning")
	end
	self:TargetBar(30753, 20, args.destName)
	self:Bar(30753, 30)
	self:CancelDelayedMessage(CL.soon:format(args.spellName))
	self:DelayedMessage(30753, 25, "yellow", CL.soon:format(args.spellName))
	-- DBM marks the wolf's target, the wolf chases the Red Riding Hood
	self:CustomIcon(hoodMarker, args.destName, 8)
	self:ScheduleTimer("CustomIcon", 20, hoodMarker, args.destName)
end

function mod:TerrifyingHowl(args)
	if args.time - prevFear > 2 then
		prevFear = args.time
		self:Message(30752, "orange")
		self:CancelDelayedMessage(CL.soon:format(args.spellName))
		self:DelayedMessage(30752, 19, "yellow", CL.soon:format(args.spellName))
		self:Bar(30752, 24)
	end
end
