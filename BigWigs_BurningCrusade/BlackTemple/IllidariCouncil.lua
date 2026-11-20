--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-BlackTemple/IllidariCouncil.lua), draft by tools/dbm2bw

local mod, CL = BigWigs:NewBoss("The Illidari Council", 564, 1589)
if not mod then return end
mod:RegisterEnableMob(22949, 22950, 22951, 22952) -- Gathios, Zerevor, Malande, Veras
mod:SetEncounterID(608)
mod:SetWinMobs(22949, 22950, 22951, 22952) -- 3.3.5: all four must die

--------------------------------------------------------------------------------
-- Locals
--

local prevArea = {}

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	immune = "Malande immune",
	immune_desc = "Show warning when Manalde becomes spell or melee immune",
	immune_icon = 41451,
	immune_msg = "Malande - %s immune for 15 sec",
	melee = "Melee",
	spell = "Spell",
})

--------------------------------------------------------------------------------
-- Initialization
--

local poisonMarker = mod:AddMarkerOption(true, "player", 1, 41485, 1)
function mod:GetOptions()
	return {
		"berserk",
		{41485, "HEALER"}, -- Deadly Poison
		poisonMarker,
		41476, -- Vanish
		41475, -- Reflective Shield
		41452, -- Devotion Aura
		41453, -- Resistance Aura
		41450, -- Blessing of Protection
		41451, -- Blessing of Spell Warding
		{"immune", "OFF"},
		41455, -- Circle of Healing
		41481, -- Flamestrike
		41482, -- Blizzard
		41541, -- Consecration
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "DeadlyPoison", 41485)
	self:Log("SPELL_AURA_REMOVED", "DeadlyPoisonRemoved", 41485)
	self:Log("SPELL_AURA_APPLIED", "UnderYou", 41481, 41482, 41541)
	self:Log("SPELL_AURA_APPLIED", "Vanish", 41476)
	self:Log("SPELL_AURA_REMOVED", "VanishRemoved", 41479)
	self:Log("SPELL_AURA_APPLIED", "ReflectiveShield", 41475)
	self:Log("SPELL_AURA_APPLIED", "Aura", 41452, 41453)
	self:Log("SPELL_AURA_APPLIED", "Immune", 41450, 41451)
	self:Log("SPELL_CAST_START", "CircleOfHealing", 41455)
	self:Log("SPELL_CAST_SUCCESS", "CircleOfHealingSuccess", 41455)
end

function mod:OnEngage()
	prevArea = {}
	self:Berserk(900)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:DeadlyPoison(args)
	self:TargetMessage(41485, "orange", args.destName)
	self:CustomIcon(poisonMarker, args.destName, 1)
end

function mod:DeadlyPoisonRemoved(args)
	self:CustomIcon(poisonMarker, args.destName)
end

function mod:UnderYou(args)
	if self:Me(args.destGUID) and args.time - (prevArea[args.spellId] or 0) > 3 then
		prevArea[args.spellId] = args.time
		self:PersonalMessage(args.spellId, "underyou")
		self:PlaySound(args.spellId, "underyou")
	end
end

function mod:Vanish(args)
	self:TargetMessage(41476, "yellow", args.destName)
	self:TargetBar(41476, 31, args.destName)
end

function mod:VanishRemoved()
	self:Message(41476, "green", CL.over:format(self:SpellName(41476)))
end

function mod:ReflectiveShield(args)
	self:Message(41475, "red", CL.on:format(args.spellName, args.destName))
	self:PlaySound(41475, "alarm") -- DBM: stop attacking (dps)
	self:TargetBar(41475, 20, args.destName)
end

function mod:Aura(args)
	if self:MobId(args.destGUID) == 22949 then
		self:Message(args.spellId, "orange")
		self:Bar(args.spellId, 30)
	end
end

function mod:Immune(args)
	if self:MobId(args.destGUID) == 22951 then
		self:TargetBar(args.spellId, 15, args.destName)
		self:Message("immune", "orange", L.immune_msg:format(args.spellId == 41450 and L.melee or L.spell), L.immune_icon)
	end
end

function mod:CircleOfHealing(args)
	if self:Interrupter(args.sourceGUID) then
		self:Message(41455, "red", CL.casting:format(args.spellName))
		self:PlaySound(41455, "alert")
	end
end

function mod:CircleOfHealingSuccess()
	self:CDBar(41455, 13.3)
end
