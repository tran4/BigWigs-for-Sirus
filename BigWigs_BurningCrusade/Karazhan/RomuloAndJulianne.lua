--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Karazhan/RomuloAndJulianne.lua), draft by tools/dbm2bw
-- Opera event, no journal id: the name is from the DBM localization.
-- Julianne dies (stage 2), Romulo dies, both rise (stage 3, yell): won when both died within 10 seconds (like DBM).

local mod, CL = BigWigs:NewBoss("Romulo and Julianne", 532)
if not mod then return end
mod:RegisterEnableMob(17534, 17533) -- Julianne, Romulo
mod:SetEncounterID(65501)
mod:SetWinMobs()
mod:SetEmulationWipeDelay(25) -- DBM SetWipeTime(25)

--------------------------------------------------------------------------------
-- Locals
--

local julianneDied, romuloDied = 0, 0

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	bossName = "Romulo and Julianne",
	warmup_trigger = "Tonight... we explore a tale of forbidden love!",
	stage3_trigger = "Come, gentle night; and give me back my Romulo!",
	poison = "%s on >%s< (%d)",
})
mod.displayName = L.bossName

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"warmup",
		"stages",
		30878, -- Eternal Affection
		{30830, "TANK_HEALER"}, -- Poisoned Thrust
		30841, -- Daring
		30887, -- Devotion
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "EternalAffection", 30878)
	self:Log("SPELL_AURA_APPLIED", "Poison", 30822, 30830)
	self:Log("SPELL_AURA_APPLIED_DOSE", "Poison", 30822, 30830)
	self:Log("SPELL_AURA_APPLIED", "Daring", 30841)
	self:Log("SPELL_AURA_APPLIED_DOSE", "Daring", 30841)
	self:Log("SPELL_AURA_REMOVED", "DaringRemoved", 30841)
	self:Log("SPELL_AURA_APPLIED", "Devotion", 30887)
	self:Log("SPELL_AURA_APPLIED_DOSE", "Devotion", 30887)
	self:Log("SPELL_AURA_REMOVED", "DevotionRemoved", 30887)
	self:Death("JulianneDeath", 17534)
	self:Death("RomuloDeath", 17533)
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
end

function mod:OnEngage()
	self:SetStage(1)
	julianneDied, romuloDied = 0, 0
	self:StopBar(CL.active)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if msg:find(L.stage3_trigger, nil, true) then
		self:SetStage(3)
		self:Message("stages", "cyan", CL.stage:format(3), false)
		self:PlaySound("stages", "long")
	elseif msg:find(L.warmup_trigger, nil, true) then
		self:Bar("warmup", 55, CL.active, "inv_misc_pocketwatch_01")
	end
end

function mod:EternalAffection(args)
	self:Message(30878, "orange", CL.casting:format(args.spellName))
	self:CastBar(30878, 2.5)
end

function mod:Poison(args)
	self:Message(30830, "purple", L.poison:format(args.spellName, args.destName, args.amount or 1))
end

function mod:Daring(args)
	self:TargetMessage(30841, "yellow", args.destName)
	self:TargetBar(30841, 8, args.destName)
end

function mod:DaringRemoved(args)
	self:StopBar(args.spellName, args.destName)
end

function mod:Devotion(args)
	self:TargetMessage(30887, "yellow", args.destName)
	self:TargetBar(30887, 10, args.destName)
end

function mod:DevotionRemoved(args)
	self:StopBar(args.spellName, args.destName)
end

function mod:JulianneDeath()
	if self:GetStage() == 3 then
		julianneDied = GetTime()
		if GetTime() - romuloDied < 10 then self:Win() end
	elseif self:GetStage() == 1 then
		self:SetStage(2)
		self:Message("stages", "cyan", CL.stage:format(2), false)
	end
end

function mod:RomuloDeath()
	if self:GetStage() == 3 then
		romuloDied = GetTime()
		if GetTime() - julianneDied < 10 then self:Win() end
	end
end
