--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-BWL/Nefarian.lua)
-- Engaged by the pull yell of Lord Victor Nefarius like DBM: the module is enabled by targeting him to talk
-- (10162, not in DBM, added for 3.3.5). Won on the death of Nefarian. Not ported: the speed clear timer.

local mod, CL = BigWigs:NewBoss("Nefarian Classic", 469, 1536)
if not mod then return end
mod:RegisterEnableMob(11583, 10162) -- Nefarian, Lord Victor Nefarius
mod:SetEncounterID(617)
mod:SetWinMobs(11583)
mod:SetEmulationWipeDelay(50) -- DBM: SetWipeTime(50)

--------------------------------------------------------------------------------
-- Locals
--

local addsLeft = 42
local deadAdds = {}
local warnedSoon = false
local addIds = {[14264] = true, [14263] = true, [14261] = true, [14265] = true, [14262] = true, [14302] = true}

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	engage_trigger = "Let the games begin!",
	stage2_trigger = "Well done, my minions. The mortals' courage begins to wane! Now, let's see how they contend with the true Lord of Blackrock Spire!!!",
	stage3_trigger = "Impossible! Rise my minions!  Serve your master once more!",
	shaman_trigger = "Shamans, show me",
	paladin_trigger = "Paladins... I've heard you have many lives. Show me.",
	druid_trigger = "Druids and your silly shapeshifting. Lets see it in action!",
	priest_trigger = "Priests! If you're going to keep healing like that, we might as well make it a little more interesting!",
	warrior_trigger = "Warriors, I know you can hit harder than that! Lets see it!",
	rogue_trigger = "Rogues? Stop hiding and face me!",
	warlock_trigger = "Warlocks, you shouldn't be playing with magic you don't understand. See what happens?",
	hunter_trigger = "Hunters and your annoying pea-shooters!",
	mage_trigger = "Mages too? You should be more careful when you play with magic...",
	deathknight_trigger = "Death Knights... get over here!",

	classcall = "Class call",
	classcall_desc = "Announce class calls and show timer for class call duration",
	classcall_icon = "Spell_Shadow_Charm",
	classcall_warning = "%s call",
	classcall_you = "Class call on you!",
	classcall_ends = "%s call ends",

	adds_left = "Adds",
	adds_left_desc = "Announce kills remaining until Stage 2 is triggered",
	adds_left_icon = "inv_misc_head_dragon_black",
	adds_left_message = "%d kills remaining",
})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"stages",
		"adds_left",
		"classcall",
		22539, -- Shadow Flame
		22686, -- Bellowing Roar
		22687, -- Veil of Shadow
		22667, -- Shadow Command
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "ShadowFlame", 22539)
	self:Log("SPELL_CAST_START", "BellowingRoar", 22686)
	self:Log("SPELL_AURA_APPLIED", "VeilOfShadow", 22687)
	self:Log("SPELL_AURA_APPLIED", "ShadowCommand", 22667)
	self:Death("AddDeath", 14264, 14263, 14261, 14265, 14262, 14302) -- Red, Bronze, Blue, Black, Green, Chromatic
	self:RegisterEvent("CHAT_MSG_MONSTER_YELL")
	self:RegisterEvent("UNIT_HEALTH")
end

function mod:OnEngage()
	self:SetStage(1)
	addsLeft = 42
	deadAdds = {}
	warnedSoon = false
end

--------------------------------------------------------------------------------
-- Event Handlers
--

local classCalls = {"shaman", "paladin", "druid", "priest", "warrior", "rogue", "warlock", "hunter", "mage", "deathknight"}

function mod:ClassCall(class)
	local className = LOCALIZED_CLASS_NAMES_MALE[class] or class
	local _, myClass = UnitClass("player")
	if myClass == class then
		self:Message("classcall", "blue", L.classcall_you, L.classcall_icon)
		self:PlaySound("classcall", "warning")
	else
		self:Message("classcall", "yellow", L.classcall_warning:format(className), L.classcall_icon)
	end
	self:Bar("classcall", 30, L.classcall_ends:format(className), L.classcall_icon)
end

do
	local prev = 0
	function mod:CHAT_MSG_MONSTER_YELL(_, msg)
		if msg:find(L.engage_trigger, nil, true) then
			if not self:IsEngaged() then
				self:Engage()
			end
		elseif msg:find(L.stage2_trigger, nil, true) then
			self:SetStage(2)
			self:Message("stages", "cyan", CL.stage:format(2), false)
			self:PlaySound("stages", "long")
			self:Bar("stages", 15, CL.stage:format(2), "inv_misc_head_dragon_black")
		elseif msg:find(L.stage3_trigger, nil, true) then
			self:SetStage(3)
			self:Message("stages", "cyan", CL.stage:format(3), false)
			self:PlaySound("stages", "long")
		elseif self:IsEngaged() then
			local t = GetTime()
			for i = 1, #classCalls do
				local class = classCalls[i]
				if msg:find(L[class .. "_trigger"], nil, true) then
					if class == "deathknight" or t - prev > 5 then -- DBM: no antispam for the death knight call
						prev = t
						self:ClassCall(class:upper())
					end
					return
				end
			end
		end
	end
end

function mod:AddDeath(args)
	if not self:IsEngaged() or deadAdds[args.destGUID] then return end
	deadAdds[args.destGUID] = true
	addsLeft = addsLeft - 1
	if addsLeft >= 15 and addsLeft % 5 == 0 or addsLeft >= 1 and addsLeft % 3 == 0 then
		self:Message("adds_left", "green", L.adds_left_message:format(addsLeft), L.adds_left_icon)
	end
end

function mod:ShadowFlame(args)
	self:Message(22539, "orange", CL.casting:format(args.spellName))
end

function mod:BellowingRoar(args)
	self:Message(22686, "red", CL.casting:format(args.spellName))
	self:CDBar(22686, 26.7)
end

function mod:VeilOfShadow(args)
	if self:Dispeller("curse") then
		self:TargetMessage(22687, "yellow", args.destName)
		self:PlaySound(22687, "alert") -- DBM: dispel now
	end
end

function mod:ShadowCommand(args)
	self:TargetMessage(22667, "red", args.destName)
	self:PlaySound(22667, "alarm")
end

function mod:UNIT_HEALTH(_, unit)
	if not warnedSoon and self:IsEngaged() and self:GetStage() < 3 and self:MobId(self:UnitGUID(unit)) == 11583
		and self:GetHealth(unit) <= 25 then
		warnedSoon = true
		self:Message("stages", "cyan", CL.soon:format(CL.stage:format(3)), false)
	end
end
