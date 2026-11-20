--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-AQ40/ThreeBugs.lua), won when the three bugs died

local mod, CL = BigWigs:NewBoss("Silithid Royalty", 531, 1547)
if not mod then return end
mod:RegisterEnableMob(15544, 15511, 15543) -- Vem, Lord Kri, Princess Yauj
mod:SetEncounterID(710)
mod:SetWinMobs(15544, 15511, 15543)

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		26580, -- Fear
		{25812, "OFF"}, -- Toxic Volley
		25807, -- Great Heal
		25786, -- Toxic Vapors
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_SUCCESS", "Fear", 26580)
	self:Log("SPELL_CAST_SUCCESS", "ToxicVolley", 25812)
	self:Log("SPELL_CAST_START", "GreatHeal", 25807)
	self:Log("SPELL_AURA_APPLIED", "ToxicVapors", 25786, 25989)
	self:Log("SPELL_PERIODIC_DAMAGE", "ToxicVapors", 25786, 25989)
	self:Log("SPELL_PERIODIC_MISSED", "ToxicVapors", 25786, 25989)
	self:Death("YaujDeath", 15543)
end

function mod:OnEngage()
	self:CDBar(26580, 10)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

do
	local prev = 0
	function mod:Fear(args)
		if self:Hostile(args.sourceFlags) and args.time - prev > 3 then
			prev = args.time
			self:Message(26580, "orange")
			self:CDBar(26580, 20.5)
		end
	end
end

function mod:ToxicVolley(args)
	self:Message(25812, "yellow")
end

function mod:GreatHeal(args)
	if self:Hostile(args.sourceFlags) then
		self:Message(25807, "red", CL.casting:format(args.spellName))
		if (self:UnitGUID("target") == args.sourceGUID or self:UnitGUID("focus") == args.sourceGUID) and self:Interrupter() then
			self:PlaySound(25807, "alert") -- DBM: interrupt
		end
	end
end

do
	local prev = 0
	function mod:ToxicVapors(args)
		if self:Me(args.destGUID) and args.time - prev > 3 then
			prev = args.time
			self:PersonalMessage(25786, "underyou")
			self:PlaySound(25786, "underyou")
		end
	end
end

function mod:YaujDeath()
	self:StopBar(26580)
end
