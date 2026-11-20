--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Sunwell/Kalecgos.lua), draft by tools/dbm2bw
-- Won by the death of Sathrovarr (DBM EndCombat). Not ported: the Spectral Realm frame, the respawn bar, the health frame.

local mod, CL = BigWigs:NewBoss("Kalecgos", 580, 1591)
if not mod then return end
mod:RegisterEnableMob(24850, 24892) -- Kalecgos, Sathrovarr the Corruptor
mod:SetEncounterID(724)
mod:SetWinMobs(24892)

--------------------------------------------------------------------------------
-- Locals
--

local portCount = 1
local prevPortal, prevBuffet = 0, 0

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	-- DBM: no English texts
	portal_msg = "Портал #%d : >%s< (Группа %d)",
	wild_magic = "Дикая магия",
	wild_magic_desc = "Показывать спец-предупреждение для Дикой Магии",
	wild_magic_icon = 44978,
	wild_magic_msg = "Дикая магия - %s!",
	heal = "+100% хила",
	haste = "+100% касттайм",
	hit = "-50% меткости",
	crit = "+100% крит урон",
	aggro = "+100% угрозы",
	mana = "-50% исп маны",
})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		46021, -- Spectral Blast
		"wild_magic",
		45029, -- Corrupting Strike
		45018, -- Arcane Buffet
		{44799, "OFF"}, -- Frost Breath
		"proximity",
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "WildMagic", 44978, 45001, 45002, 45004, 45006, 45010)
	self:Log("SPELL_AURA_APPLIED", "CorruptingStrike", 45029)
	self:Log("SPELL_AURA_APPLIED", "SpectralBlast", 46021)
	self:Log("SPELL_AURA_APPLIED", "ArcaneBuffetStacks", 45018)
	self:Log("SPELL_AURA_APPLIED_DOSE", "ArcaneBuffetStacks", 45018)
	self:Log("SPELL_CAST_START", "FrostBreath", 44799)
	self:Log("SPELL_CAST_SUCCESS", "ArcaneBuffet", 45018)
end

function mod:OnEngage()
	portCount = 1
	prevPortal, prevBuffet = 0, 0
	self:OpenProximity("proximity", 10)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

local wildMagic = {
	[44978] = {"heal", "healer"},
	[45001] = {"haste"},
	[45002] = {"hit", "melee"},
	[45004] = {"crit", "nohealer"},
	[45006] = {"aggro", "nohealer"},
	[45010] = {"mana"},
}

function mod:WildMagic(args)
	if not self:Me(args.destGUID) then return end
	local w = wildMagic[args.spellId]
	local role = w[2]
	if role == "healer" and not self:Healer() then return end
	if role == "melee" and not self:Melee() then return end
	if role == "nohealer" and self:Healer() then return end
	self:Message("wild_magic", "blue", L.wild_magic_msg:format(L[w[1]]), args.spellId)
	self:PlaySound("wild_magic", "info")
end

function mod:CorruptingStrike(args)
	if self:IsEngaged() then
		self:TargetMessage(45029, "purple", args.destName)
	end
end

function mod:SpectralBlast(args)
	if self:Me(args.destGUID) then
		self:Bar(46021, 60, CL.other:format(args.spellName, CL.active))
		self:ScheduleTimer("Bar", 60, 46021, 60, self:SpellName(44867))
	end
	if args.time - prevPortal > 20 then
		prevPortal = args.time
		local group = 0
		for i = 1, GetNumRaidMembers() do
			local name, _, subgroup = GetRaidRosterInfo(i)
			if name == args.destName then
				group = subgroup
				break
			end
		end
		self:Message(46021, "orange", L.portal_msg:format(portCount, args.destName, group))
		portCount = portCount + 1
		self:Bar(46021, 25, CL.count:format(args.spellName, portCount))
	end
end

function mod:ArcaneBuffetStacks(args)
	local amount = args.amount or 1
	if self:Me(args.destGUID) and amount >= 10 and amount % 2 == 0 then
		self:StackMessage(45018, "blue", args.destName, amount, 10)
		self:PlaySound(45018, "alarm")
	end
end

function mod:FrostBreath(args)
	self:Message(44799, "orange")
	self:CDBar(44799, 15)
end

function mod:ArcaneBuffet(args)
	if args.time - prevBuffet > 7 then
		prevBuffet = args.time
		self:CDBar(45018, 8)
	end
end
