--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-MC/Geddon.lua)

local mod, CL = BigWigs:NewBoss("Baron Geddon", 409, 1524)
if not mod then return end
mod:RegisterEnableMob(12056)
mod:SetEncounterID(668)

--------------------------------------------------------------------------------
-- Locals
--

local igniteList = {}

--------------------------------------------------------------------------------
-- Initialization
--

local bombMarker = mod:AddMarkerOption(false, "player", 8, 20475, 8)
function mod:GetOptions()
	return {
		{20475, "SAY", "SAY_COUNTDOWN"}, -- Living Bomb
		bombMarker,
		19695, -- Inferno
		19659, -- Ignite Mana
		20478, -- Armageddon
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "LivingBomb", 20475)
	self:Log("SPELL_AURA_REMOVED", "LivingBombRemoved", 20475)
	self:Log("SPELL_CAST_SUCCESS", "LivingBombCast", 20475)
	self:Log("SPELL_CAST_SUCCESS", "Inferno", 19695)
	self:Log("SPELL_CAST_SUCCESS", "IgniteManaCast", 19659)
	self:Log("SPELL_AURA_APPLIED", "IgniteMana", 19659)
	self:Log("SPELL_CAST_SUCCESS", "Armageddon", 20478)
end

function mod:OnEngage()
	igniteList = {}
	self:CDBar(20475, 11)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:LivingBomb(args)
	self:TargetMessage(20475, "red", args.destName)
	self:TargetBar(20475, 8, args.destName)
	self:CustomIcon(bombMarker, args.destName, 8)
	if self:Me(args.destGUID) then
		self:PlaySound(20475, "warning") -- DBM: run out
		self:Say(20475)
		self:SayCountdown(20475, 8)
	end
end

function mod:LivingBombRemoved(args)
	self:StopBar(20475, args.destName)
	self:CustomIcon(bombMarker, args.destName)
	if self:Me(args.destGUID) then
		self:CancelSayCountdown(20475)
	end
end

function mod:LivingBombCast()
	self:CDBar(20475, 13.3)
end

function mod:Inferno(args)
	self:Message(19695, "orange")
	if self:Melee() then
		self:PlaySound(19695, "alarm") -- DBM: run away (melee)
	end
	self:Bar(19695, 8, CL.other:format(args.spellName, CL.active))
	self:CDBar(19695, 21)
end

function mod:IgniteManaCast(args)
	if self:Hostile(args.sourceFlags) then
		self:CDBar(19659, 27)
	end
end

function mod:IgniteMana(args)
	if self:Player(args.destFlags) and self:Dispeller("magic") then
		igniteList[#igniteList + 1] = args.destName
		self:TargetsMessage(19659, "yellow", igniteList)
	end
end

function mod:Armageddon(args)
	self:Message(20478, "orange")
	self:CastBar(20478, 8)
end
