--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Sunwell/Kil'jaeden.lua), draft by tools/dbm2bw
-- DBM has only Russian texts for the orbs: the English defaults are the Russian texts.

local mod, CL = BigWigs:NewBoss("Kil'jaeden", 580, 1596)
if not mod then return end
mod:RegisterEnableMob(25315)
mod:SetEncounterID(729)

--------------------------------------------------------------------------------
-- Locals
--

local bloomTargets = {}
local bloomIcon = 8
local orbGUIDs = {}
local prevDarkOrb = 0

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	engage_trigger = "The expendable have perished. So be it! Now I shall succeed where Sargeras could not! I will bleed this wretched world and secure my place as the true master of the Burning Legion! The end has come! Let the unravelling of this world commence!",
	orb_trigger1 = "I will channel my powers into the orbs! Be ready!",
	orb_trigger2 = "I have empowered another orb! Use it quickly!",
	orb_trigger3 = "Another orb is ready! Make haste!",
	orb_trigger4 = "I have channeled all I can! The power is in your hands!",

	-- DBM: no English texts
	orbs = "Сферы",
	orbs_desc = "Предупреждения для Темных Сфер и активации Сфер Дракона",
	orbs_icon = 45109,
	dark_orbs = "Появились темные сферы",
	blue_orb = "Активировалась сфера дракона",
	blue_orb_bar = "Активация сферы дракона",
	shield = "Щит",
})

--------------------------------------------------------------------------------
-- Initialization
--

local bloomMarker = mod:AddMarkerOption(true, "player", 8, 45641, 8, 7, 6, 5, 4)
function mod:GetOptions()
	return {
		"stages",
		"orbs",
		{45641, "SAY"}, -- Fire Bloom
		bloomMarker,
		46605, -- Darkness of a Thousand Souls
		45740, -- Flame Dart
		{46589, "SAY"}, -- Shadow Spike
		45848, -- Shield of the Blue
		"proximity",
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "FireBloom", 45641)
	self:Log("SPELL_AURA_REMOVED", "FireBloomRemoved", 45641)
	self:Log("SPELL_CAST_START", "Darkness", 46605)
	self:Log("SPELL_CAST_START", "FlameDart", 45737)
	self:Log("SPELL_CAST_START", "ShadowSpikeCast", 46680)
	self:Log("SPELL_CAST_SUCCESS", "DarkOrb", 45680)
	self:Log("SPELL_CAST_SUCCESS", "ShieldOfTheBlue", 45848)
	self:Log("SPELL_CAST_SUCCESS", "SinisterReflection", 45892)
	self:Log("SPELL_CAST_SUCCESS", "ShadowSpike", 46589)
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
end

function mod:OnEngage()
	self:SetStage(1)
	bloomTargets, bloomIcon = {}, 8
	orbGUIDs, prevDarkOrb = {}, 0
	self:OpenProximity("proximity", 12)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if msg:find(L.engage_trigger, nil, true) then
		if not self:IsEngaged() then self:Engage() end -- DBM RegisterCombat("yell")
	elseif self:IsEngaged() and (msg:find(L.orb_trigger1, nil, true) or msg:find(L.orb_trigger2, nil, true)
		or msg:find(L.orb_trigger3, nil, true) or msg:find(L.orb_trigger4, nil, true)) then
		self:Message("orbs", "green", L.blue_orb, L.orbs_icon)
	end
end

function mod:AnnounceBloom()
	self:TargetsMessage(45641, "orange", bloomTargets, #bloomTargets)
	bloomTargets, bloomIcon = {}, 8
	self:CDBar(45641, 20)
end

function mod:FireBloom(args)
	bloomTargets[#bloomTargets + 1] = args.destName
	self:CancelTimer(self.bloomTimer)
	self:CustomIcon(bloomMarker, args.destName, bloomIcon)
	bloomIcon = bloomIcon - 1
	if self:Me(args.destGUID) then
		self:PlaySound(45641, "warning")
		self:Say(45641)
	end
	if #bloomTargets >= 5 then
		self:AnnounceBloom()
	else
		self.bloomTimer = self:ScheduleTimer("AnnounceBloom", 0.3)
	end
end

function mod:FireBloomRemoved(args)
	self:CustomIcon(bloomMarker, args.destName)
end

function mod:Darkness(args)
	self:Message(46605, "red", CL.other:format(args.spellName, SHIELDSLOT or L.shield))
	self:PlaySound(46605, "warning") -- DBM: find the shield
	self:CastBar(46605, 9)
	self:CDBar(46605, self:GetStage() == 4 and 25 or 45)
end

function mod:FlameDart(args)
	self:Message(45740, "orange")
	self:CDBar(45740, 20)
end

function mod:ShadowSpikeCast()
	self:CastBar(46589, 28)
end

function mod:DarkOrb(args)
	if not orbGUIDs[args.sourceGUID] then
		orbGUIDs[args.sourceGUID] = true
		if args.time - prevDarkOrb > 5 then
			prevDarkOrb = args.time
			self:Message("orbs", "red", L.dark_orbs, L.orbs_icon)
		end
	end
end

function mod:ShieldOfTheBlue(args)
	self:Message(45848, "green")
end

function mod:SinisterReflection()
	local stage = self:GetStage() + 1
	self:SetStage(stage)
	self:Message("stages", "cyan", CL.stage:format(stage), false)
	self:PlaySound("stages", "long")
	if stage == 2 then
		self:Bar("orbs", 37, L.blue_orb_bar, L.orbs_icon)
		self:CDBar(45740, 59)
		self:CDBar(46605, 77)
	elseif stage == 3 then
		self:Bar("orbs", 37, L.blue_orb_bar, L.orbs_icon)
		self:CDBar(45740, 48.7)
		self:CDBar(46605, 77)
	elseif stage == 4 then
		self:Bar("orbs", 45, L.blue_orb_bar, L.orbs_icon)
		self:CDBar(45740, 49)
		self:CDBar(46605, 58)
	end
end

function mod:ShadowSpike(args)
	if not args.destName then return end
	if self:Me(args.destGUID) then
		self:PersonalMessage(46589)
		self:PlaySound(46589, "runaway")
		self:Say(46589)
	else
		self:TargetMessage(46589, "orange", args.destName)
	end
end
