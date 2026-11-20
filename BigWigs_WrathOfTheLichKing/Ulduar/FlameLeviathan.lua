--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Ulduar/FlameLeviathan.lua), draft by tools/dbm2bw

local mod, CL = BigWigs:NewBoss("Flame Leviathan", 603, 1637)
if not mod then return end
mod:RegisterEnableMob(33113)
mod:SetEncounterID(744)

--------------------------------------------------------------------------------
-- Locals
--

local prevWard = 0

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	pursue_trigger = "%%s pursues (%S+)%.",

	pursue = "Pursuing %s",
	pursue_soon = "Target change in 5 seconds",
	ward_of_life = "Ward of Life spawned",
})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		62374, -- Pursued
		62907, -- Ward of Life
		62475, -- Systems Shutdown
		312689, -- Flame Vents
		312705, -- Hodir's Fury
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_SUMMON", "WardOfLife", 62907, 312355, 312363, 312708, 312716)
	self:Log("SPELL_AURA_APPLIED", "FlameVents", 312689, 312690, 312336, 62396)
	self:Log("SPELL_AURA_REMOVED", "FlameVentsRemoved", 312690, 312689, 62396)
	self:Log("SPELL_AURA_APPLIED", "SystemsShutdown", 312339, 312692, 62475)
	self:Log("SPELL_AURA_APPLIED", "Pursued", 62374)
	self:Log("SPELL_AURA_APPLIED", "HodirsFury", 312352, 312705, 62297)
	self:RegisterEvent("CHAT_MSG_RAID_BOSS_EMOTE")
end

function mod:OnEngage()
	self:CDBar(62907, 30)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:WardOfLife(args)
	if args.time - prevWard > 5 then
		prevWard = args.time
		self:Message(62907, "orange", L.ward_of_life)
		self:PlaySound(62907, "alert")
		self:CDBar(62907, 25)
	end
end

function mod:FlameVents(args)
	self:CastBar(312689, 10)
end

function mod:FlameVentsRemoved(args)
	self:StopCastBar(312689)
end

function mod:SystemsShutdown(args)
	self:Message(62475, "green")
	self:PlaySound(62475, "long")
	self:CastBar(62475, 20)
end

do
	-- the boss pursues a vehicle, the owner is the player whose pet it is
	local function vehicleOwner(self, guid)
		for unit in self:IterateGroup() do
			if UnitGUID(unit .. "pet") == guid then
				return self:UnitName(unit)
			end
		end
	end
	local function pursued(self, name)
		self:DelayedMessage(62374, 25, "yellow", L.pursue_soon)
		self:TargetBar(62374, 30, name)
		if name == self:UnitName("player") then
			self:Message(62374, "blue", CL.you:format(self:SpellName(62374)))
			self:PlaySound(62374, "alarm") -- run away
		else
			self:Message(62374, "yellow", L.pursue:format(self:ColorName(name)))
		end
	end

	local prev = 0
	function mod:Pursued(args)
		local name = vehicleOwner(self, args.destGUID) or args.destName
		local t = GetTime()
		if name and t - prev > 2 then
			prev = t
			pursued(self, name)
		end
	end

	-- 3.3.5: DBM Sirus has the pursue emote in its locale, use it if the aura isn't in the combat log
	function mod:CHAT_MSG_RAID_BOSS_EMOTE(_, msg)
		local name = msg:match(L.pursue_trigger)
		local t = GetTime()
		if name and t - prev > 2 then
			prev = t
			pursued(self, name)
		end
	end
end

function mod:HodirsFury(args)
	self:TargetMessage(312705, "cyan", args.destName)
end
