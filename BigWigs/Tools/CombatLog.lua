--------------------------------------------------------------------------------
-- 3.3.5 (Sirus): a fight log for finding what a boss module misses, like Transcriptor but only the actions of NPCs:
-- casts (start/success/channel), auras put by NPCs, summons, interrupts, NPC deaths, yells/emotes, the first hit of a
-- spell that has no cast, world state texts and what BigWigs itself did (engage/win/wipe, bars, messages).
-- Players, pets, melee swings, heals and every damage tick are left out. Saved per fight in BigWigsLogDB
-- (WTF\Account\<account>\SavedVariables\BigWigs.lua after /reload or logout). /bwlog on|off|clear.
--

local loader = BigWigsLoader
local Compat = loader.Compat
local GetCreatureID = Compat.GetCreatureID
local GetTime, format, band, date, tostring, next, type = GetTime, string.format, bit.band, date, tostring, next, type

local MAX_FIGHTS = 40 -- the oldest fights are dropped
local MAX_LINES = 4000 -- per fight
local END_DELAY = 4 -- out of combat this long ends the fight (boss phases with a short out of combat stay one fight)
local PRE_TIME = 90 -- yells/emotes this long before the pull are kept (warmup, roleplay)

local TYPE_NPC = 0x00000800
local GROUP = 0x00000007 -- COMBATLOG_OBJECT_AFFILIATION_MINE + PARTY + RAID

local db
local fight -- the current fight
local t0 = 0
local pre = {} -- {time, text} chat before the pull
local last = {} -- [key] = {time, line index, count}: merging of the same action from many mobs/targets
local seenSpell = {} -- [spellId] = true: spells cast or seen in this fight (a damage line only for unseen ones)
local endAt -- time to end the fight
local worldStates = {}

local function npcName(name, guid)
	local id = guid and GetCreatureID(guid)
	if id then return format("%s[%d]", name or "?", id), id end
	return name or "?", nil
end

local function isNPC(flags)
	return flags and band(flags, TYPE_NPC) ~= 0 and band(flags, GROUP) == 0
end

local function add(text, mergeKey, window)
	if not fight then return end
	local now = GetTime()
	if mergeKey then
		local m = last[mergeKey]
		if m and now - m.time <= (window or 1) then
			m.count = m.count + 1
			fight.lines[m.index] = m.line .. " x" .. m.count
			return
		end
	end
	if #fight.lines >= MAX_LINES then
		if not fight.truncated then
			fight.truncated = true
			fight.lines[#fight.lines + 1] = "... (log limit, the rest of the fight is not saved)"
		end
		return
	end
	local line = format("%7.2f  %s", now - t0, text)
	fight.lines[#fight.lines + 1] = line
	if mergeKey then
		last[mergeKey] = {time = now, index = #fight.lines, count = 1, line = line}
	end
end

local function inInstance()
	local inside, instanceType = IsInInstance()
	return inside and (instanceType == "party" or instanceType == "raid")
end

local function startFight()
	if fight or not db or not db.enabled or not inInstance() then return end
	local _, _, difficulty, _, maxPlayers, _, _, instanceID = loader.GetInstanceInfo()
	t0 = GetTime()
	fight = {
		date = date("%Y-%m-%d %H:%M:%S"),
		zone = GetRealZoneText(),
		instanceID = instanceID,
		difficulty = difficulty,
		players = maxPlayers,
		mobs = {}, -- [npcId] = name
		lines = {},
	}
	last, seenSpell = {}, {}
	for i = 1, #pre do
		local p = pre[i]
		if t0 - p[1] <= PRE_TIME then
			fight.lines[#fight.lines + 1] = format("%7.2f  %s", p[1] - t0, p[2])
		end
	end
	pre = {}
	db.fights[#db.fights + 1] = fight
	while #db.fights > MAX_FIGHTS do table.remove(db.fights, 1) end
end

local function endFight()
	if not fight then return end
	fight.duration = math.floor((GetTime() - t0) * 10 + 0.5) / 10
	-- a fight without any action of a mob (a fall, a duel, a critter) is not worth keeping
	if not fight.hasNPC then
		for i = #db.fights, 1, -1 do
			if db.fights[i] == fight then table.remove(db.fights, i) break end
		end
	end
	fight, endAt = nil, nil
end

local function noteMob(name, guid)
	local id = guid and GetCreatureID(guid)
	if id and fight and not fight.mobs[id] then fight.mobs[id] = name end
end

-- Combat log (3.3.5 arguments)
local cleu = {}
function cleu.SPELL_CAST_START(_, sG, sN, sF, dG, dN, _, spellId, spellName)
	if not isNPC(sF) then return end
	local src, npc = npcName(sN, sG)
	seenSpell[spellId] = true
	add(format("CAST_START    %s  %s(%s)%s", src, tostring(spellName), tostring(spellId), dN and (" -> " .. dN) or ""),
		"cs" .. tostring(npc) .. spellId, 0.5)
end
function cleu.SPELL_CAST_SUCCESS(_, sG, sN, sF, dG, dN, _, spellId, spellName)
	if not isNPC(sF) then return end
	local src, npc = npcName(sN, sG)
	seenSpell[spellId] = true
	add(format("CAST_SUCCESS  %s  %s(%s)%s", src, tostring(spellName), tostring(spellId), dN and (" -> " .. dN) or ""),
		"cc" .. tostring(npc) .. spellId, 0.5)
end
local function aura(event, label)
	return function(_, sG, sN, sF, dG, dN, dF, spellId, spellName, _, auraType, amount)
		local fromNPC = isNPC(sF)
		-- an aura put by a mob, or an aura on a mob (boss buffs, shields), or a debuff without a source (on 3.3.5 often a boss's)
		if not fromNPC and not isNPC(dF) and not (not sG and auraType == "DEBUFF") then return end
		if not fromNPC and sF and band(sF, GROUP) ~= 0 then return end -- a player's own aura on a mob
		seenSpell[spellId] = true
		local src = fromNPC and npcName(sN, sG) or "-"
		local dst = isNPC(dF) and npcName(dN, dG) or (dN or "?")
		add(format("%s %s(%s) %s  %s -> %s%s", label, tostring(spellName), tostring(spellId), tostring(auraType), src, dst,
			event == "SPELL_AURA_APPLIED_DOSE" and (" (" .. tostring(amount) .. ")") or ""),
			event .. spellId, 1.5)
	end
end
cleu.SPELL_AURA_APPLIED = aura("SPELL_AURA_APPLIED", "AURA+       ")
cleu.SPELL_AURA_APPLIED_DOSE = aura("SPELL_AURA_APPLIED_DOSE", "AURA_DOSE   ")
cleu.SPELL_AURA_REMOVED = aura("SPELL_AURA_REMOVED", "AURA-       ")
function cleu.SPELL_SUMMON(_, sG, sN, sF, dG, dN, _, spellId, spellName)
	if not isNPC(sF) then return end
	add(format("SUMMON        %s  %s(%s) -> %s", (npcName(sN, sG)), tostring(spellName), tostring(spellId), (npcName(dN, dG))),
		"su" .. spellId, 1)
end
function cleu.SPELL_INTERRUPT(_, sG, sN, sF, dG, dN, dF, spellId, spellName, _, extraId, extraName)
	if isNPC(sF) then
		add(format("INTERRUPT     %s  %s(%s) interrupts %s: %s(%s)", (npcName(sN, sG)), tostring(spellName), tostring(spellId), tostring(dN), tostring(extraName), tostring(extraId)))
	elseif isNPC(dF) then -- a mob's cast interrupted by the group: shows what can be kicked
		add(format("KICKED        %s  %s(%s)", (npcName(dN, dG)), tostring(extraName), tostring(extraId)))
	end
end
local function damage(_, sG, sN, sF, dG, dN, _, spellId, spellName)
	if not isNPC(sF) or seenSpell[spellId] then return end
	-- only spells of a mob with no cast or aura in the log: the first hit, then merged
	add(format("HIT           %s  %s(%s) -> %s", (npcName(sN, sG)), tostring(spellName), tostring(spellId), tostring(dN)),
		"hit" .. spellId, 3)
end
cleu.SPELL_DAMAGE = damage
cleu.SPELL_MISSED = damage
cleu.SPELL_PERIODIC_DAMAGE = damage
cleu.SPELL_PERIODIC_MISSED = damage
cleu.RANGE_DAMAGE = damage
function cleu.UNIT_DIED(_, _, _, _, dG, dN, dF)
	if not isNPC(dF) then return end
	add(format("DIED          %s", (npcName(dN, dG))), "died" .. tostring(GetCreatureID(dG or "")), 0.3)
end

local frame = CreateFrame("Frame")

local units = {"target", "focus", "boss1", "boss2", "boss3", "boss4"}
local unitEvents = {UNIT_SPELLCAST_START = "UCAST_START  ", UNIT_SPELLCAST_SUCCEEDED = "UCAST_SUCCESS", UNIT_SPELLCAST_CHANNEL_START = "UCHANNEL     "}
local chatEvents = {
	CHAT_MSG_MONSTER_YELL = "YELL ", CHAT_MSG_MONSTER_SAY = "SAY  ", CHAT_MSG_MONSTER_EMOTE = "EMOTE",
	CHAT_MSG_RAID_BOSS_EMOTE = "BOSS_EMOTE", CHAT_MSG_RAID_BOSS_WHISPER = "BOSS_WHISPER",
}

frame:SetScript("OnEvent", function(_, event, ...)
	if event == "COMBAT_LOG_EVENT_UNFILTERED" then
		if not fight then
			-- a mob attacked the group before the combat flag (or a fight while the player is in combat already)
			if not UnitAffectingCombat("player") then return end
			startFight()
			if not fight then return end
		end
		local _, subEvent, sG, sN, sF, dG, dN, dF = ...
		local h = cleu[subEvent]
		if h then
			if isNPC(sF) then fight.hasNPC = true noteMob(sN, sG) end
			if isNPC(dF) then noteMob(dN, dG) end
			h(select(2, ...))
		end
	elseif unitEvents[event] then
		if not fight then return end
		local unit, spellName = ...
		local matched
		for i = 1, #units do if unit == units[i] then matched = true break end end
		if not matched or UnitPlayerControlled(unit) then return end
		local guid = UnitGUID(unit)
		add(format("%s %s  %s  (%s)", unitEvents[event], (npcName(UnitName(unit), guid)), tostring(spellName), unit),
			"u" .. event .. tostring(guid) .. tostring(spellName), 1)
	elseif chatEvents[event] then
		local msg, sender = ...
		local text = format("%-12s %s: %s", chatEvents[event], tostring(sender), tostring(msg))
		if fight then
			add(text)
		elseif db and db.enabled and inInstance() then
			pre[#pre + 1] = {GetTime(), text}
			if #pre > 50 then table.remove(pre, 1) end
		end
	elseif event == "UPDATE_WORLD_STATES" then
		if not fight then return end
		for i = 1, GetNumWorldStateUI() do
			local _, state, text = GetWorldStateUIInfo(i)
			if text and text ~= "" and worldStates[i] ~= text then
				worldStates[i] = text
				add(format("WORLD_STATE   %d: %s (%s)", i, text, tostring(state)))
			end
		end
	elseif event == "PLAYER_REGEN_DISABLED" then
		endAt = nil
		startFight()
	elseif event == "PLAYER_REGEN_ENABLED" then
		if fight then endAt = GetTime() + END_DELAY end
	elseif event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
		endFight()
		pre, worldStates = {}, {}
	elseif event == "PLAYER_LOGOUT" then
		endFight()
	end
end)
frame:SetScript("OnUpdate", function()
	if endAt and GetTime() >= endAt then
		if UnitAffectingCombat("player") then endAt = nil else endFight() end
	end
end)

local function register(state)
	local list = {"COMBAT_LOG_EVENT_UNFILTERED", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "UPDATE_WORLD_STATES"}
	for e in next, unitEvents do list[#list + 1] = e end
	for e in next, chatEvents do list[#list + 1] = e end
	for i = 1, #list do
		if state then frame:RegisterEvent(list[i]) else frame:UnregisterEvent(list[i]) end
	end
end
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
frame:RegisterEvent("PLAYER_LOGOUT")
frame:RegisterEvent("ADDON_LOADED")

-- What BigWigs did, to compare with the actions of the mobs
local bw = {}
local function onBW(event, module, a, b, c)
	if not fight then return end
	local name = type(module) == "table" and (module.moduleName or module.name) or tostring(module)
	if event == "BigWigs_StartBar" then
		add(format("BW_BAR        %s  \"%s\" %s [%s]", name, tostring(b), tostring(c), tostring(a)))
	elseif event == "BigWigs_Message" then
		add(format("BW_MESSAGE    %s  \"%s\" [%s]", name, tostring(b), tostring(a)), "bwm" .. tostring(b), 0.5)
	else
		add(format("BW_%s  %s", event:gsub("^BigWigs_OnBoss", ""):upper(), name))
	end
end
for _, e in next, {"BigWigs_OnBossEngage", "BigWigs_OnBossWin", "BigWigs_OnBossWipe", "BigWigs_StartBar", "BigWigs_Message"} do
	loader.RegisterMessage(bw, e, onBW)
end

local function setEnabled(state)
	db.enabled = state and true or nil
	register(db.enabled)
	if not db.enabled then endFight() end
end

frame:HookScript("OnEvent", function(_, event, name)
	if event == "ADDON_LOADED" and name == "BigWigs" then
		frame:UnregisterEvent("ADDON_LOADED")
		if type(BigWigsLogDB) ~= "table" then BigWigsLogDB = {} end
		db = BigWigsLogDB
		if type(db.fights) ~= "table" then db.fights = {} end
		setEnabled(db.enabled)
	end
end)

local function sysprint(msg)
	print("|cFF33FF99BigWigs|r |cFFffff00log|r " .. msg)
end
SLASH_BigWigsCombatLog1 = "/bwlog"
SlashCmdList.BigWigsCombatLog = function(msg)
	msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
	if not db then return end
	if msg == "on" then
		setEnabled(true)
		sysprint("включён: бои в подземельях и рейдах пишутся в BigWigsLogDB (сохраняется после /reload или выхода)")
		if UnitAffectingCombat("player") then startFight() end
	elseif msg == "off" then
		setEnabled(false)
		sysprint("выключен")
	elseif msg == "clear" then
		endFight()
		db.fights = {}
		sysprint("все сохранённые бои удалены")
	else
		local n = #db.fights
		local lastFight = db.fights[n]
		sysprint(("%s, сохранено боёв: %d%s. Команды: /bwlog on, /bwlog off, /bwlog clear"):format(
			db.enabled and "включён" or "выключен", n,
			lastFight and (", последний: " .. tostring(lastFight.zone) .. " " .. tostring(lastFight.date)) or ""))
	end
end
