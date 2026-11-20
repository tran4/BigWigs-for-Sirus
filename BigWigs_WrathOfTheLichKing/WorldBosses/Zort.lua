--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-WorldBoss/AWakingNightmare/Zort.lua), a custom Sirus boss
-- in A Waking Nightmare (map 914), no journal id. Loaded by targeting him (X-BigWigs-LoadOn-WorldBoss in the .toc).
-- DBM has only Russian texts: the English defaults are the Russian texts.
-- Stages like DBM: the Monstrous Tentacle (50715), the Face (50714) and the Lash Tentacle (50716) of Zort at 1%
-- (DBM reads them as boss3/boss2/boss4, the ids are from its comments), then all three again; the last stage has a
-- shorter Breath of Nightmares timer. Not ported: the countdown yell of every player on 308520, the chain buttons
-- and the chat announces, nameplate auras.

local mod, CL = BigWigs:NewBoss("Zort", -914)
if not mod then return end
mod:RegisterEnableMob(50702)
mod:SetWorldModule(true)
mod:SetEncounterID(50702) -- DBM Sirus custom encounter id

--------------------------------------------------------------------------------
-- Locals
--

local flameList, chainList = {}, {}
local flameIcon, chainIcon = 2, 7
local deadInStage = {}
local tentacles = {[50715] = 1, [50714] = 2, [50716] = 3} -- the stage each one ends (DBM: boss3, boss2, boss4)

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	-- DBM: no English texts
	bossName = "Зорт",
	cowardice_you = "Печать: Трусость - бей босса, держи радиус 6 метров!",
})
mod.displayName = L.bossName

--------------------------------------------------------------------------------
-- Initialization
--

local flameMarker = mod:AddMarkerOption(true, "player", 2, 307839, 2, 1)
local chainMarker = mod:AddMarkerOption(true, "player", 7, 308620, 7, 6, 5)
function mod:GetOptions()
	return {
		"stages",
		307829, -- interruptible cast
		307821, -- Squall
		{307839, "SAY", "SAY_COUNTDOWN"}, -- Flame of Nightmares
		flameMarker,
		{307861, "SAY", "SAY_COUNTDOWN"}, -- Flame of Nightmares (second)
		{308620, "ME_ONLY_EMPHASIZE"}, -- Nightmare Chain
		chainMarker,
		308520, -- chain break
		307834, -- Seal: Cowardice
		307814, -- Seal: Treachery
		308512, -- Breath of Nightmares
		307845, -- Monstrous Blow
		307833, -- Internal Bleeding
		307852, -- summon (adds)
		{307844, "TANK"}, -- Nightmare (adds, DBM: tanks only)
		"proximity",
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "Kick", 307829)
	self:Log("SPELL_INTERRUPT", "KickInterrupted", 307829)
	self:Log("SPELL_CAST_START", "Squall", 307820, 307818, 307817)
	self:Log("SPELL_CAST_START", "Summon", 307852)
	self:Log("SPELL_CAST_START", "BreathOfNightmares", 308512)
	self:Log("SPELL_CAST_START", "MonstrousBlow", 307845)
	self:Log("SPELL_CAST_START", "Nightmare", 307844)
	self:Log("SPELL_CAST_SUCCESS", "ChainBreak", 308520)
	self:Log("SPELL_CAST_SUCCESS", "Cowardice", 307834)
	self:Log("SPELL_CAST_SUCCESS", "Stage3", 318956)
	self:Log("SPELL_AURA_APPLIED", "Treachery", 307815)
	self:Log("SPELL_AURA_APPLIED_DOSE", "Treachery", 307815)
	self:Log("SPELL_AURA_APPLIED", "Flame", 307839, 307842, 307861)
	self:Log("SPELL_AURA_REMOVED", "FlameRemoved", 307839, 307861)
	self:Log("SPELL_AURA_APPLIED", "BreathApplied", 308512)
	self:Log("SPELL_AURA_APPLIED", "Chain", 308517, 308620, 308515)
	self:Log("SPELL_AURA_REMOVED", "ChainRemoved", 308516, 308517)
	self:Log("SPELL_AURA_APPLIED", "CowardiceApplied", 307834)
	self:Log("SPELL_AURA_APPLIED", "InternalBleeding", 307833)
	self:Log("SPELL_AURA_APPLIED_DOSE", "InternalBleeding", 307833)
	self:RegisterEvent("UNIT_HEALTH")
end

function mod:OnEngage()
	self:SetStage(1)
	flameList, chainList = {}, {}
	flameIcon, chainIcon = 2, 7
	deadInStage = {}
	self:CDBar(307829, 15)
	self:CDBar(307821, 20)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:NextStage()
	local stage = self:GetStage() + 1
	self:SetStage(stage)
	deadInStage = {}
	self:Message("stages", "cyan", CL.stage:format(stage), false)
	self:PlaySound("stages", "long")
end

function mod:UNIT_HEALTH(_, unit)
	if not self:IsEngaged() then return end
	local order = tentacles[self:MobId(self:UnitGUID(unit))]
	if not order or self:GetHealth(unit) > 1 then return end
	local stage = self:GetStage()
	if stage <= 3 then
		if order == stage then -- DBM: stage 1 ends on the Monstrous Tentacle, 2 on the Face, 3 on the Lash Tentacle
			self:NextStage()
		end
	elseif stage == 4 then -- DBM: all three at 1% again
		deadInStage[order] = true
		if deadInStage[1] and deadInStage[2] and deadInStage[3] then
			self:NextStage()
		end
	end
end

function mod:Kick(args)
	self:CDBar(307829, 15)
	if self:Interrupter() then -- DBM: the warning for interrupters
		self:Message(307829, "orange", CL.casting:format(args.spellName))
		self:PlaySound(307829, "alert")
	end
end

function mod:KickInterrupted(args)
	self:CDBar(307829, 15)
end

function mod:Squall(args)
	self:Message(307821, "red", args.spellName)
	self:PlaySound(307821, "alarm") -- DBM: GTFO
	self:CDBar(307821, 20)
end

do
	local prev = 0
	function mod:Summon(args)
		if args.time - prev > 2 then
			prev = args.time
			self:Message(307852, "yellow")
			self:CDBar(307852, 120)
		end
	end
end

function mod:BreathOfNightmares(args)
	self:CDBar(308512, self:GetStage() == 5 and 30 or 42)
	if self:Dispeller("disease") then
		self:Message(308512, "orange", CL.casting:format(args.spellName))
		self:PlaySound(308512, "alert") -- DBM: dispel
	end
end

do
	local prev = 0
	function mod:BreathApplied(args)
		if args.time - prev > 3 and self:Dispeller("disease") then
			prev = args.time
			self:Message(308512, "orange")
		end
	end
end

function mod:MonstrousBlow()
	self:CDBar(307845, 15)
end

do
	local prev = 0
	function mod:Nightmare(args)
		if args.time - prev > 2 then
			prev = args.time
			self:Message(307844, "purple", CL.casting:format(args.spellName))
			self:CDBar(307844, 10)
		end
	end
end

function mod:ChainBreak()
	self:CDBar(308520, 6)
end

function mod:Cowardice()
	self:CDBar(307834, 33)
end

function mod:CowardiceApplied(args)
	if self:Me(args.destGUID) then
		self:Message(307834, "blue", L.cowardice_you)
		self:PlaySound(307834, "warning")
		self:OpenProximity("proximity", 6)
	end
end

function mod:Stage3()
	self:SetStage(3)
	deadInStage = {}
	self:Message("stages", "cyan", CL.stage:format(3), false)
	self:PlaySound("stages", "long")
	self:StopBar(307834)
	self:CDBar(307852, 10)
	self:CDBar(308620, 20)
	self:CDBar(307845, 24)
end

function mod:Treachery(args)
	local amount = args.amount or 1
	if amount >= 2 and self:Me(args.destGUID) then
		self:StackMessage(307814, "blue", args.destName, amount, 2)
		self:PlaySound(307814, "alarm")
	end
end

function mod:Flame(args)
	local key = args.spellId == 307861 and 307861 or 307839
	flameList[#flameList + 1] = args.destName
	self:TargetsMessage(key, "red", flameList)
	if flameIcon > 0 then
		self:CustomIcon(flameMarker, args.destName, flameIcon)
		flameIcon = flameIcon - 1
	end
	if self:Me(args.destGUID) then
		self:PlaySound(key, "runaway")
		self:Say(key)
		local _, _, _, expires = self:UnitDebuff("player", args.spellId)
		if expires and expires > GetTime() then
			self:SayCountdown(key, expires - GetTime()) -- DBM: NewShortFadesYell, the aura duration
		end
		self:OpenProximity("proximity", key == 307861 and 20 or 12)
	end
end

function mod:FlameRemoved(args)
	flameIcon = 2
	self:CustomIcon(flameMarker, args.destName)
	if self:Me(args.destGUID) then
		self:CancelSayCountdown(args.spellId)
	end
end

function mod:Chain(args)
	chainList[#chainList + 1] = args.destName
	self:TargetsMessage(308620, "orange", chainList)
	if chainIcon > 4 then
		self:CustomIcon(chainMarker, args.destName, chainIcon)
		chainIcon = chainIcon - 1
	end
	if #chainList == 1 then
		self:CDBar(308620, 28)
		self:SimpleTimer(function() chainIcon = 7 end, 0.3)
	end
	if self:Me(args.destGUID) then
		self:PlaySound(308620, "warning")
	end
end

function mod:ChainRemoved(args)
	self:CustomIcon(chainMarker, args.destName)
end

function mod:InternalBleeding(args)
	self:CDBar(307833, 26)
	if self:Tank() or self:Healer() then -- DBM: the stack warning for tanks and healers
		self:StackMessage(307833, "purple", args.destName, args.amount or 1, 0)
	end
end
