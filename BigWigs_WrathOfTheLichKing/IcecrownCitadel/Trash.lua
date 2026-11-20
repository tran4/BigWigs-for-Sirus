--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Icecrown/Trash.lua), draft by tools/dbm2bw

local mod, CL = BigWigs:NewBoss("Icecrown Citadel Trash", 631)
if not mod then return end
mod.displayName = CL.trash
mod:SetTrashModule(true)
mod:RegisterEnableMob(
	37007, -- Deathbound Ward
	37038, -- Vengeful Fleshreaper
	37025, -- Stinky
	37217 -- Precious
)

--------------------------------------------------------------------------------
-- Locals
--

local deathPlagueList = {}
local prevDeathPlague = 0
local deathPlagueIcon = 1
local bloodMirrorList = {}
local prevBloodMirror = 0
local prevZombies = 0
local prevBlade = 0
local professorEventStarted = false

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	warder_trigger1 = "Who... goes there...?",
	warder_trigger2 = "I... awaken!",
	warder_trigger3 = "The master's sanctum has been disturbed!",
	fleshreaper_trigger1 = "Quickly! We'll ambush them from behind!",
	fleshreaper_trigger2 = "You... cannot escape us!",
	fleshreaper_trigger3 = "The living... here?!",
	gauntlet_trigger = "You must not approach the Frost Queen. Quickly, stop them!",

	trap_warder = "Trap Activated! - Deathbound Ward released",
	trap_warder_desc = "Show special warning for Deathbound Ward trap activation",
	trap_fleshreaper = "Trap Activated! - Vengeful Fleshreapers incoming",
	trap_fleshreaper_desc = "Show special warning for Vengeful Fleshreapers trap activation",
	gauntlet = "Sindragosa gauntlet started!",
	gauntlet_desc = "Show special warning for Sindragosa gauntlet event",
})

--------------------------------------------------------------------------------
-- Initialization
--

local darkReckoningMarker = mod:AddMarkerOption(true, "player", 8, 69483, 8)
local deathPlagueMarker = mod:AddMarkerOption(true, "player", 1, 72865, 1, 2, 3, 4, 5, 6, 7, 8)
local bloodMirrorMarker = mod:AddMarkerOption(false, "player", 2, 70451, 2)
local spearMarker = mod:AddMarkerOption(true, "player", 7, 71443, 7)
function mod:GetOptions()
	return {
		-- The Lower Spire
		"trap_warder",
		71022, -- Disrupting Shout
		69483, -- Dark Reckoning
		darkReckoningMarker,
		72865, -- Death Plague
		deathPlagueMarker,
		spearMarker,
		-- The Plagueworks
		"trap_fleshreaper",
		"warmup",
		71159, -- Zombies
		{71127, "TANK_HEALER"}, -- Mortal Wound
		71123, -- Decimate
		71088, -- Blight Bomb
		-- The Crimson Hall
		{70451, "TANK_HEALER"}, -- Blood Mirror
		bloodMirrorMarker,
		{70432, "TANK_HEALER"}, -- Blood Sap
		{70645, "OFF"}, -- Chains of Shadow
		-- Frostwing Halls
		"gauntlet",
		70305, -- Blade
		{71785, "OFF"}, -- Conflagration
		{71298, "OFF"}, -- Banish
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "DisruptingShout", 71022)
	self:Log("SPELL_AURA_APPLIED", "DarkReckoning", 69483)
	self:Log("SPELL_AURA_APPLIED", "DeathPlague", 72865)
	self:Log("SPELL_AURA_APPLIED", "Spear", 71443)
	self:Log("SPELL_SUMMON", "Zombies", 71159)
	self:Log("SPELL_AURA_APPLIED", "MortalWound", 71127)
	self:Log("SPELL_AURA_APPLIED_DOSE", "MortalWound", 71127)
	self:Log("SPELL_CAST_START", "Decimate", 71123)
	self:Log("SPELL_CAST_START", "BlightBomb", 71088)
	self:Log("SPELL_AURA_APPLIED", "InsectSwarm", 70475)
	self:Log("SPELL_AURA_APPLIED", "BloodMirror", 70451)
	self:Log("SPELL_AURA_REMOVED", "BloodMirrorRemoved", 70451)
	self:Log("SPELL_AURA_APPLIED", "BloodSap", 70432)
	self:Log("SPELL_AURA_REMOVED", "BloodSapRemoved", 70432)
	self:Log("SPELL_AURA_APPLIED", "ChainsOfShadow", 70645)
	self:Log("SPELL_AURA_REMOVED", "ChainsOfShadowRemoved", 70645)
	self:Log("SPELL_AURA_APPLIED", "Conflagration", 71785)
	self:Log("SPELL_AURA_REMOVED", "ConflagrationRemoved", 71785)
	self:Log("SPELL_AURA_APPLIED", "Banish", 71298)
	self:Log("SPELL_AURA_REMOVED", "BanishRemoved", 71298)
	self:Log("SPELL_DAMAGE", "BladeDamage", 70305)
	self:Log("SPELL_MISSED", "BladeDamage", 70305)
	self:Death("StinkyDeath", 37025)
	self:Death("PreciousDeath", 37217)
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:CHAT_MSG_MONSTER_YELL(_, msg)
	if msg == L.warder_trigger1 or msg == L.warder_trigger2 or msg == L.warder_trigger3 then
		self:Message("trap_warder", "red", L.trap_warder, false)
		self:PlaySound("trap_warder", "warning")
	elseif msg == L.fleshreaper_trigger1 or msg == L.fleshreaper_trigger2 or msg == L.fleshreaper_trigger3 then
		self:Message("trap_fleshreaper", "red", L.trap_fleshreaper, false)
		self:PlaySound("trap_fleshreaper", "warning")
	elseif msg == L.gauntlet_trigger then
		self:Message("gauntlet", "red", L.gauntlet, false)
		self:PlaySound("gauntlet", "warning")
	end
end

-- The Lower Spire

function mod:DisruptingShout(args)
	self:Message(71022, "red", CL.casting:format(args.spellName))
	self:PlaySound(71022, "warning")
	self:CastBar(71022, 3)
end

function mod:DarkReckoning(args)
	self:TargetMessage(69483, "orange", args.destName)
	self:TargetBar(69483, 8, args.destName)
	if self:Me(args.destGUID) then
		self:PlaySound(69483, "warning") -- move away
	end
	self:CustomIcon(darkReckoningMarker, args.destName, 8)
	self:ScheduleTimer("CustomIcon", 8, darkReckoningMarker, args.destName)
end

function mod:DeathPlague(args)
	if args.time - prevDeathPlague > 3 then
		deathPlagueList = {}
		deathPlagueIcon = 1
	end
	prevDeathPlague = args.time
	deathPlagueList[#deathPlagueList + 1] = args.destName
	self:TargetsMessage(72865, "red", deathPlagueList, nil, nil, nil, 0.3)
	self:TargetBar(72865, 15, args.destName)
	if self:Me(args.destGUID) then
		self:PlaySound(72865, "warning")
	end
	if deathPlagueIcon <= 8 then
		self:CustomIcon(deathPlagueMarker, args.destName, deathPlagueIcon)
		deathPlagueIcon = deathPlagueIcon + 1
	end
end

function mod:Spear(args) -- Val'kyr Herald
	self:CustomIcon(spearMarker, args.destName, 7)
end

-- The Plagueworks

function mod:Zombies(args)
	if args.time - prevZombies > 5 then
		prevZombies = args.time
		self:Message(71159, "yellow")
		self:Bar(71159, 20)
	end
end

function mod:MortalWound(args)
	local amount = args.amount or 1
	self:TargetBar(71127, 15, args.destName)
	if amount % 2 == 0 then
		self:StackMessage(71127, "purple", args.destName, amount, 6)
		if self:Me(args.destGUID) and amount > 5 then
			self:PlaySound(71127, "alarm")
		end
	end
end

function mod:Decimate(args)
	self:Message(71123, "red")
	self:PlaySound(71123, "alert")
	self:CancelDelayedMessage(CL.soon:format(args.spellName)) -- the first one might be off
	self:DelayedMessage(71123, 28, "orange", CL.soon:format(args.spellName))
	self:Bar(71123, 33)
end

function mod:StinkyDeath()
	self:CancelDelayedMessage(CL.soon:format(self:SpellName(71123)))
	self:StopBar(71123)
end

function mod:PreciousDeath()
	self:StopBar(71159)
	self:CancelDelayedMessage(CL.soon:format(self:SpellName(71123)))
	self:StopBar(71123)
end

function mod:BlightBomb(args)
	self:Message(71088, "orange")
	self:PlaySound(71088, "alert")
	self:CastBar(71088, 5)
end

function mod:InsectSwarm(args) -- the Professor's event before Festergut and Rotface
	if not professorEventStarted then
		professorEventStarted = true
		self:Bar("warmup", 59, CL.active, 70475)
	end
end

-- The Crimson Hall

function mod:BloodMirror(args)
	if not self:Player(args.destFlags) then return end
	if args.time - prevBloodMirror > 3 then
		bloodMirrorList = {}
	end
	prevBloodMirror = args.time
	bloodMirrorList[#bloodMirrorList + 1] = args.destName
	self:TargetsMessage(70451, "yellow", bloodMirrorList, nil, nil, nil, 0.3)
	self:TargetBar(70451, 30, args.destName)
	self:CustomIcon(bloodMirrorMarker, args.destName, 2)
end

function mod:BloodMirrorRemoved(args)
	self:StopBar(70451, args.destName)
	self:CustomIcon(bloodMirrorMarker, args.destName)
end

function mod:BloodSap(args)
	self:TargetMessage(70432, "orange", args.destName)
	self:TargetBar(70432, 8, args.destName)
end

function mod:BloodSapRemoved(args)
	self:StopBar(70432, args.destName)
end

function mod:ChainsOfShadow(args)
	if self:Player(args.destFlags) then
		self:TargetMessage(70645, "yellow", args.destName)
		self:TargetBar(70645, 10, args.destName)
	end
end

function mod:ChainsOfShadowRemoved(args)
	self:StopBar(70645, args.destName)
end

-- Frostwing Halls

function mod:Conflagration(args)
	self:TargetMessage(71785, "red", args.destName)
	self:TargetBar(71785, 10, args.destName)
end

function mod:ConflagrationRemoved(args)
	self:StopBar(71785, args.destName)
end

function mod:Banish(args)
	self:TargetMessage(71298, "yellow", args.destName)
	self:TargetBar(71298, 6, args.destName)
end

function mod:BanishRemoved(args)
	self:StopBar(71298, args.destName)
end

function mod:BladeDamage(args)
	if self:Me(args.destGUID) and args.time - prevBlade > 2.5 then
		prevBlade = args.time
		self:PersonalMessage(70305, "underyou")
		self:PlaySound(70305, "underyou")
	end
end
