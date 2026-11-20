--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Hyjal/WaveTimers.lua), draft by tools/dbm2bw
-- Waves from the world state counter, the next boss from the gossip of Jaina/Thrall (DBM). DBM sets lastWave = 6
-- after the gossip, which blocks its wave timers: here a new wave is any increase of the counter.
-- Not ported: the detailed wave composition, the Necromancer icons and the low health warning of the slime spewer.

local mod, CL = BigWigs:NewBoss("Hyjal Summit Trash", 534)
if not mod then return end
mod.displayName = CL.trash
mod:SetTrashModule(true)
mod:RegisterEnableMob(17852, 17772) -- Thrall, Lady Jaina Proudmoore (DBM UNIT_DIED ids)

--------------------------------------------------------------------------------
-- Locals
--

local lastWave = 0
local boss = 0

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	wave_check = "Current Wave = (%d+) of 8",
	wave_msg = "Wave %s/8",
	next_wave = "Next wave",
	rage_gossip = "My companions and I are with you, Lady Proudmoore.",
	anetheron_gossip = "We are ready for whatever Archimonde might send our way, Lady Proudmoore.",
	kazrogal_gossip = "I am with you, Thrall.",
	azgalor_gossip = "We have nothing to fear.",

	waves = "Waves",
	waves_desc = "Warn when a new wave is incoming, show a timer for next wave",
	waves_icon = "spell_holy_prayerofhealing",
})

--------------------------------------------------------------------------------
-- Initialization
--

local slimeMarker = mod:AddMarkerOption(false, "player", 8, 319230, 8)
function mod:GetOptions()
	return {
		"waves",
		{319502, "SAY"}, -- Brand of Horror
		{319230, "SAY"}, -- Slime
		slimeMarker,
	}
end

function mod:OnBossEnable()
	self:RegisterEvent("UPDATE_WORLD_STATES")
	self:RegisterEvent("GOSSIP_SHOW")
	self:RegisterEvent("QUEST_PROGRESS", "GOSSIP_SHOW")
	self:Log("SPELL_AURA_APPLIED", "BrandOfHorror", 319502, 319503)
	self:Log("SPELL_AURA_REMOVED", "SlimeRemoved", 319232)
	self:Death("DefenderDeath", 17852, 17772)
	self:Death("BossDeath", 17767, 17808, 17888)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:GOSSIP_SHOW()
	local mobId = self:MobId(self:UnitGUID("target"))
	if mobId ~= 17852 and mobId ~= 17772 then return end
	local selection = GetGossipOptions()
	if selection == L.rage_gossip then
		boss = 1
	elseif selection == L.anetheron_gossip then
		boss = 2
	elseif selection == L.kazrogal_gossip then
		boss = 3
	elseif selection == L.azgalor_gossip then
		boss = 4
	end
end

function mod:UPDATE_WORLD_STATES()
	local _, _, text = GetWorldStateUIInfo(4)
	if not text then return end
	local wave = tonumber(text:match(L.wave_check)) or 0
	if wave > lastWave then
		local timer = 125 -- DBM: the first trash waves
		if boss == 1 or boss == 2 then
			timer = wave == 5 and 210 or 180
		elseif boss == 3 or boss == 4 then
			timer = (wave == 2 or wave == 4) and 160 or 135
		end
		self:Message("waves", "cyan", L.wave_msg:format(wave), L.waves_icon)
		self:Bar("waves", timer, L.next_wave, L.waves_icon)
	end
	lastWave = wave
end

function mod:DefenderDeath()
	lastWave = 0
	self:StopBar(L.next_wave)
end

function mod:BossDeath(args)
	if args.mobId == 17767 then
		boss = 2
	elseif args.mobId == 17808 then
		boss = 3
	elseif args.mobId == 17888 then
		boss = 4
	end
end

function mod:BrandOfHorror(args)
	self:TargetMessage(319502, "orange", args.destName)
	if self:Me(args.destGUID) then
		self:PlaySound(319502, "runaway")
		self:Say(319502)
	end
end

do
	local function slimeTarget(self, name, guid)
		self:CustomIcon(slimeMarker, name, 8)
		self:ScheduleTimer("CustomIcon", 5, slimeMarker, name)
		if self:Me(guid) then
			self:PersonalMessage(319230)
			self:PlaySound(319230, "runaway")
			self:Say(319230)
		else
			local unit = self:UnitTokenFromGUID(guid)
			if unit and self:UnitWithinRange(unit, 10) then
				self:Message(319230, "orange", CL.near:format(self:SpellName(319230)))
				self:PlaySound(319230, "runaway")
			end
		end
	end
	function mod:SlimeRemoved(args)
		if self:MobId(args.destGUID) == 50640 then -- DBM: the target of 50640
			self:GetUnitTarget(slimeTarget, 0.1, args.destGUID)
		end
	end
end
