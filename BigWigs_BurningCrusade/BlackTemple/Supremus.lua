--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-BlackTemple/Supremus.lua, Sirus version with custom spells), draft by tools/dbm2bw

local mod, CL = BigWigs:NewBoss("Supremus", 564, 1583)
if not mod then return end
mod:RegisterEnableMob(22898)
mod:SetEncounterID(602)

--------------------------------------------------------------------------------
-- Locals
--

local prevBarrage = 0

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"berserk",
		322301, -- Ignite
		322297, -- Spectral Barrage
		322292, -- Otherworldly Mark
		322294, -- Binding Strike
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "Ignite", 322301)
	self:Log("SPELL_CAST_START", "SpectralBarrage", 322297)
	self:Log("SPELL_CAST_START", "BindingStrikeCast", 322294)
	self:Log("SPELL_AURA_APPLIED", "BindingStrike", 322294)
	self:Log("SPELL_AURA_APPLIED_DOSE", "BindingStrike", 322294)
end

function mod:OnEngage()
	prevBarrage = 0
	self:Berserk(900)
	self:CDBar(322301, 16)
	self:CDBar(322297, 15)
	self:CDBar(322292, 20)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:Ignite(args)
	self:CDBar(322301, 17)
	if self:Interrupter(args.sourceGUID) then
		self:Message(322301, "red", CL.casting:format(args.spellName))
		self:PlaySound(322301, "alert")
	end
end

function mod:SpectralBarrage(args)
	if args.time - prevBarrage > 2 then
		prevBarrage = args.time
		self:CDBar(322297, 17)
		if self:Ranged() then -- DBM: SpellCaster
			self:Message(322297, "orange")
			self:PlaySound(322297, "underyou")
		end
	end
end

function mod:BindingStrikeCast(args)
	self:CDBar(322294, 19)
	self:DelayedMessage(322294, 18, "yellow", CL.soon:format(args.spellName))
end

function mod:BindingStrike(args)
	self:StackMessage(322294, "purple", args.destName, args.amount or 1, 1)
end
