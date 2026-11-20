--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Gruul/Maulgar.lua, heroic mode with custom spells), draft by tools/dbm2bw
-- DBM only knows High King Maulgar (18831), his death wins. Not ported: announcing the active council member to the chat.

local mod, CL = BigWigs:NewBoss("High King Maulgar", 565, 1564)
if not mod then return end
mod:RegisterEnableMob(18831)
mod:SetEncounterID(649)

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		33238, -- Whirlwind
		16508, -- Intimidating Roar
		305216, -- heroic: Might (active council member)
		33054, -- Spell Shield
		305221, -- heroic: interrupt
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "Whirlwind", 33238)
	self:Log("SPELL_CAST_SUCCESS", "IntimidatingRoar", 16508)
	self:Log("SPELL_AURA_APPLIED", "Might", 305216)
	self:Log("SPELL_AURA_APPLIED", "SpellShield", 305247, 33054)
	self:Log("SPELL_CAST_START", "Interrupt", 305221)
end

function mod:OnEngage()
	if self:Difficulty() == 6 then -- 25 heroic
		self:CDBar(305216, 5)
	end
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:Whirlwind(args)
	self:CDBar(33238, 55)
	self:Bar(33238, 15, CL.other:format(args.spellName, CL.active))
	if self:Melee() then
		self:Message(33238, "red")
		self:PlaySound(33238, "runaway")
	end
end

function mod:IntimidatingRoar()
	self:CDBar(16508, 16)
end

function mod:Might(args)
	self:CDBar(305216, 65)
	self:Message(305216, "cyan", CL.other:format(args.destName, CL.active))
	self:TargetBar(305216, 60, args.destName)
end

function mod:SpellShield(args)
	if self:Dispeller("magic", true) then
		self:Message(33054, "orange", CL.onboss:format(args.spellName))
		self:PlaySound(33054, "alert")
	end
end

function mod:Interrupt(args)
	if not self:Melee() then -- DBM: "-Melee"
		self:Message(305221, "red", CL.casting:format(args.spellName))
		self:PlaySound(305221, "alert")
	end
end
