--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-ZulAman/Nalorakk.lua), draft by tools/dbm2bw

local mod, CL = BigWigs:NewBoss("Nalorakk", 568, 187)
if not mod then return end
mod:RegisterEnableMob(23576)
mod:SetEncounterID(1190)

--------------------------------------------------------------------------------
-- Locals
--

local prevSilence = 0

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	engage_trigger = "Очень скоро вы умрете!", -- DBM: no English text
	bear_trigger = "You call on da beast, you gonna get more dan you bargain for!",
	troll_trigger = "Make way for Nalorakk!",

	forms = "Forms",
	forms_desc = "Show warnings and timers for the bear and the troll forms",
	forms_icon = 9634,
	bear = "Форма медведя", -- DBM: no English text
	troll = "Форма тролля", -- DBM: no English text
})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"berserk",
		"forms",
		42398, -- Deafening Roar
		42389, -- Mangle
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "Mangle", 42389)
	self:Log("SPELL_AURA_APPLIED", "DeafeningRoar", 42398)
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
end

function mod:OnEngage()
	prevSilence = 0
	self:DelayedMessage("forms", 40, "yellow", CL.soon:format(L.bear), 9634)
	self:Bar("forms", 45, L.bear, 9634)
	self:Berserk(600)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if msg:find(L.engage_trigger, nil, true) then
		if not self:IsEngaged() then self:Engage() end -- DBM RegisterCombat("yell")
	elseif not self:IsEngaged() then
		return
	elseif msg:find(L.bear_trigger, nil, true) then
		self:StopBar(L.bear)
		self:CancelDelayedMessage(CL.soon:format(L.bear))
		self:Message("forms", "red", L.bear, 9634)
		self:PlaySound("forms", "long")
		self:CDBar(42398, 20)
		self:Bar("forms", 30, L.troll, 26297)
		self:DelayedMessage("forms", 25, "yellow", CL.soon:format(L.troll), 26297)
	elseif msg:find(L.troll_trigger, nil, true) then
		self:StopBar(L.troll)
		self:CancelDelayedMessage(CL.soon:format(L.troll))
		self:StopBar(42398)
		self:Message("forms", "green", L.troll, 26297)
		self:Bar("forms", 45, L.bear, 9634)
		self:DelayedMessage("forms", 40, "yellow", CL.soon:format(L.bear), 9634)
	end
end

function mod:Mangle(args)
	self:TargetBar(42389, 60, args.destName)
end

function mod:DeafeningRoar(args)
	if args.time - prevSilence > 4 then
		prevSilence = args.time
		self:Message(42398, "orange")
	end
end
