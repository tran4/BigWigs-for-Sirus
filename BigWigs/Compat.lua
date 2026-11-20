--------------------------------------------------------------------------------
-- BigWigs for Sirus (WoW 3.3.5a) - compatibility layer
--
-- Re-implements the modern client API that BigWigs relies on, using only what
-- the 3.3.5a client offers. Nothing here is written into the global namespace
-- except the single table BigWigsCompat, so other addons are never affected.
--

local _, addonTbl = ...
local Compat = {}
addonTbl.Compat = Compat
BigWigsCompat = Compat

local type, next, select, tonumber, tostring, pairs, ipairs = type, next, select, tonumber, tostring, pairs, ipairs
local format, strsub, strbyte, strmatch, strgsub = string.format, string.sub, string.byte, string.match, string.gsub
local tinsert, tremove, twipe = table.insert, table.remove, table.wipe
local GetTime = GetTime

Compat.isSirus = true

--- Sirus realm number the way DBM Sirus computes it (DBM-Core/AddFunctions.lua GetRealmNumber):
-- "x4" / "x5" / "x3" / "x2" / "x1" in the realm name, nil if none. Some encounter timers differ between realms.
function Compat.GetRealmNumber()
	local name = GetRealmName() or GetCVar("realmName") or ""
	return strmatch(name, "x4") and 4 or strmatch(name, "x5") and 5 or strmatch(name, "x3") and 3
		or strmatch(name, "x2") and 2 or strmatch(name, "x1") and 1 or nil
end

--------------------------------------------------------------------------------
-- Error safe calling
--

do
	local geterrorhandler = geterrorhandler
	local xpcall, unpack = xpcall, unpack
	local cFunc, cArgs, cNum = nil, {}, 0
	local function caller()
		return cFunc(unpack(cArgs, 1, cNum))
	end
	local function errorHandler(err)
		return geterrorhandler()(err)
	end
	--- Call a function, sending any error to the error handler without breaking the caller.
	function Compat.SafeCall(func, ...)
		local prevFunc, prevNum = cFunc, cNum
		local prevArgs = cArgs
		cFunc, cNum = func, select("#", ...)
		cArgs = {...}
		local ok = xpcall(caller, errorHandler)
		cFunc, cNum, cArgs = prevFunc, prevNum, prevArgs
		return ok
	end
end

--------------------------------------------------------------------------------
-- Timers (C_Timer replacement)
--

do
	local SafeCall = Compat.SafeCall
	local timerFrame = CreateFrame("Frame")
	timerFrame:Hide()
	local active = {}
	local due = {}

	local timerMeta = {}
	timerMeta.__index = timerMeta
	function timerMeta:Cancel()
		self.cancelled = true
	end
	function timerMeta:IsCancelled()
		return self.cancelled and true or false
	end

	local function schedule(t)
		active[#active+1] = t
		if not timerFrame:IsShown() then
			timerFrame:Show()
		end
	end

	timerFrame:SetScript("OnUpdate", function()
		local now = GetTime()
		local n = 0
		for i = #active, 1, -1 do
			local t = active[i]
			if t.cancelled then
				tremove(active, i)
			elseif now >= t.when then
				n = n + 1
				due[n] = t
				if t.iterations then
					t.iterations = t.iterations - 1
					if t.iterations <= 0 then
						tremove(active, i)
					else
						t.when = now + t.interval
					end
				elseif t.interval and not t.iterations then -- infinite ticker
					t.when = now + t.interval
				else
					tremove(active, i)
				end
			end
		end
		for i = n, 1, -1 do -- fire in scheduling order
			local t = due[i]
			due[i] = nil
			if not t.cancelled then
				if t.passSelf then
					SafeCall(t.func, t)
				else
					SafeCall(t.func)
				end
			end
		end
		if #active == 0 then
			timerFrame:Hide()
		end
	end)

	--- C_Timer.After
	function Compat.After(delay, func)
		schedule({when = GetTime() + (delay or 0), func = func})
	end
	--- C_Timer.NewTimer
	function Compat.NewTimer(delay, func)
		local t = setmetatable({when = GetTime() + (delay or 0), func = func, passSelf = true}, timerMeta)
		schedule(t)
		return t
	end
	--- C_Timer.NewTicker
	function Compat.NewTicker(interval, func, iterations)
		local t = setmetatable({when = GetTime() + interval, interval = interval, func = func, passSelf = true}, timerMeta)
		if type(iterations) == "number" and iterations > 0 then
			t.iterations = iterations
		end
		schedule(t)
		return t
	end
end

--------------------------------------------------------------------------------
-- Lua/string helpers missing in 3.3.5
--

function Compat.strlenutf8(str)
	if type(str) ~= "string" then return 0 end
	local _, count = strgsub(str, "[^\128-\191]", "")
	return count
end

function Compat.Ambiguate(name)
	if type(name) ~= "string" then return name end
	return (strmatch(name, "^([^%-]+)") or name)
end

function Compat.UnitNameUnmodified(unit)
	return UnitName(unit)
end

function Compat.WrapTextInColorCode(text, hex)
	return "|c".. (hex or "ffffffff") .. tostring(text) .."|r"
end

do
	local colorStrCache = {}
	--- Returns the "ffrrggbb" class colour string that the modern client stores as RAID_CLASS_COLORS[class].colorStr
	function Compat.GetClassColorString(class)
		if colorStrCache[class] then return colorStrCache[class] end
		local c = (CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class]) or RAID_CLASS_COLORS[class]
		if not c then return "ffffffff" end
		local str = format("ff%02x%02x%02x", c.r * 255, c.g * 255, c.b * 255)
		colorStrCache[class] = str
		return str
	end
	--- C_ClassColor.GetClassColor replacement, returns an object with r, g, b, colorStr and WrapTextInColorCode
	local classColorObjects = {}
	function Compat.GetClassColor(class)
		if not class then return end
		local obj = classColorObjects[class]
		if not obj then
			local c = (CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class]) or RAID_CLASS_COLORS[class]
			if not c then return end
			obj = {r = c.r, g = c.g, b = c.b, colorStr = Compat.GetClassColorString(class)}
			function obj:WrapTextInColorCode(text) return Compat.WrapTextInColorCode(text, self.colorStr) end
			function obj:GetRGB() return self.r, self.g, self.b end
			function obj:GenerateHexColor() return self.colorStr end
			classColorObjects[class] = obj
		end
		return obj
	end
end

--------------------------------------------------------------------------------
-- Group
--

local GetNumRaidMembers, GetNumPartyMembers = GetNumRaidMembers, GetNumPartyMembers

function Compat.IsInRaid()
	return GetNumRaidMembers() > 0
end
function Compat.IsInGroup(category)
	if category == 2 then return false end -- LE_PARTY_CATEGORY_INSTANCE doesn't exist in 3.3.5
	return GetNumRaidMembers() > 0 or GetNumPartyMembers() > 0
end
--- Modern semantics: number of group members INCLUDING the player, 0 when solo
function Compat.GetNumGroupMembers()
	local raid = GetNumRaidMembers()
	if raid > 0 then return raid end
	local party = GetNumPartyMembers()
	if party > 0 then return party + 1 end
	return 0
end
function Compat.GetNumSubgroupMembers()
	return GetNumPartyMembers()
end

local function getRaidRank(unit)
	local name = UnitName(unit)
	if not name then return end
	for i = 1, GetNumRaidMembers() do
		local rName, rank = GetRaidRosterInfo(i)
		if rName == name then
			return rank
		end
	end
end
function Compat.UnitIsGroupLeader(unit)
	if GetNumRaidMembers() > 0 then
		return getRaidRank(unit) == 2
	elseif GetNumPartyMembers() > 0 then
		return UnitIsPartyLeader(unit) and true or false
	end
	return false
end
function Compat.UnitIsGroupAssistant(unit)
	if GetNumRaidMembers() > 0 then
		return getRaidRank(unit) == 1
	end
	return false
end

--- True when in a Dungeon Finder group (IsInGroup(LE_PARTY_CATEGORY_INSTANCE) on modern clients)
function Compat.IsInLFGGroup()
	if IsPartyLFG then
		return IsPartyLFG() and true or false
	elseif GetLFGMode then
		local mode = GetLFGMode()
		return mode == "lfgparty" or mode == "abandonedInDungeon"
	end
	return false
end

--- 3.3.5 GetRaidRosterInfo has no "role" for the modern UnitGroupRolesAssigned, use the LFG role if any
function Compat.UnitGroupRolesAssigned(unit)
	if UnitGroupRolesAssigned then
		local isTank, isHealer, isDamage = UnitGroupRolesAssigned(unit)
		if isTank == true or isTank == 1 then return "TANK"
		elseif isHealer == true or isHealer == 1 then return "HEALER"
		elseif isDamage == true or isDamage == 1 then return "DAMAGER"
		elseif type(isTank) == "string" then return isTank end -- some private server clients return the modern string
	end
	return "NONE"
end

--------------------------------------------------------------------------------
-- Units & GUIDs
--

--- C_CreatureInfo.GetCreatureID replacement.
-- 3.3.5 GUID: "0x" .. HIGH(4 hex) .. ENTRY(6 hex) .. COUNTER(6 hex), e.g. 0xF130008EAC0012AB
-- High type nibble (4th hex digit of HIGH): 3 = creature, 5 = vehicle, 4 = pet, 0 = player, 1 = gameobject
function Compat.GetCreatureID(guid)
	if type(guid) ~= "string" or #guid < 18 then return end
	local unitType = tonumber(strsub(guid, 5, 5), 16)
	if not unitType then return end
	unitType = unitType % 8
	if unitType == 3 or unitType == 5 then
		return tonumber(strsub(guid, 7, 12), 16)
	end
end

--- Returns true if the GUID belongs to a player character
function Compat.IsPlayerGUID(guid)
	if type(guid) ~= "string" or #guid < 18 then return false end
	local unitType = tonumber(strsub(guid, 5, 5), 16)
	return unitType and unitType % 8 == 0
end

do
	local unitList = {"player", "pet", "target", "focus", "mouseover", "boss1", "boss2", "boss3", "boss4", "boss5",
		"party1", "party2", "party3", "party4", "partypet1", "partypet2", "partypet3", "partypet4",
	}
	for i = 1, 40 do unitList[#unitList+1] = "raid"..i end
	for i = 1, 40 do unitList[#unitList+1] = "raidpet"..i end
	local targets = {"targettarget", "focustarget", "mouseovertarget", "boss1target", "boss2target", "boss3target", "boss4target", "boss5target",
		"party1target", "party2target", "party3target", "party4target",
	}
	for i = 1, 40 do targets[#targets+1] = "raid"..i.."target" end
	local UnitGUID = UnitGUID
	--- UnitTokenFromGUID replacement (scans all useful unit tokens)
	function Compat.UnitTokenFromGUID(guid)
		if not guid then return end
		for i = 1, #unitList do
			local unit = unitList[i]
			if UnitGUID(unit) == guid then
				return unit
			end
		end
		for i = 1, #targets do
			local unit = targets[i]
			if UnitGUID(unit) == guid then
				return unit
			end
		end
	end
end

--- UnitPosition replacement. 3.3.5 has no world coordinates, callers only use the 4th return (the instance) to check if
-- a group member is in the same instance as the player, so return a comparable "instance key" instead.
function Compat.UnitPosition(unit)
	if not unit then return end
	local myZone = GetRealZoneText()
	if UnitIsUnit(unit, "player") then
		return nil, nil, nil, myZone
	end
	if not UnitIsConnected(unit) then
		return nil, nil, nil, -1
	end
	if GetNumRaidMembers() > 0 then
		local name = UnitName(unit)
		for i = 1, GetNumRaidMembers() do
			local rName, _, _, _, _, _, zone = GetRaidRosterInfo(i)
			if rName == name then
				return nil, nil, nil, zone or -1
			end
		end
	end
	-- Party: no zone info, a visible unit is in the same instance and phase
	if UnitIsVisible(unit) then
		return nil, nil, nil, myZone
	end
	return nil, nil, nil, -1
end

--------------------------------------------------------------------------------
-- Spells
--

local GetSpellInfo = GetSpellInfo

function Compat.GetSpellName(spellId)
	if not spellId then return end
	return (GetSpellInfo(spellId))
end
function Compat.GetSpellTexture(spellId)
	if not spellId then return end
	local _, _, icon = GetSpellInfo(spellId)
	return icon
end
function Compat.GetSpellLink(spellId)
	if not spellId then return end
	local link = GetSpellLink and GetSpellLink(spellId)
	if link then return link end
	local name = GetSpellInfo(spellId)
	if name then
		return format("|cff71d5ff|Hspell:%d|h[%s]|h|r", spellId, name)
	end
end
do
	local scanTip
	function Compat.GetSpellDescription(spellId)
		if not spellId or not GetSpellInfo(spellId) then return "" end
		if not scanTip then
			scanTip = CreateFrame("GameTooltip", "BigWigsCompatScanTooltip", nil, "GameTooltipTemplate")
			scanTip:SetOwner(WorldFrame, "ANCHOR_NONE")
		end
		scanTip:ClearLines()
		scanTip:SetOwner(WorldFrame, "ANCHOR_NONE")
		scanTip:SetHyperlink("spell:"..spellId)
		local lines = scanTip:NumLines()
		if lines and lines > 1 then
			local fs = _G["BigWigsCompatScanTooltipTextLeft"..lines]
			local text = fs and fs:GetText()
			if text then return text end
		end
		return ""
	end
end
function Compat.DoesSpellExist(spellId)
	return GetSpellInfo(spellId) and true or false
end
--- C_Spell.GetSpellCooldown replacement, returns the modern info table
function Compat.GetSpellCooldown(spellId)
	local name = GetSpellInfo(spellId)
	if not name then return end
	local start, duration, enabled = GetSpellCooldown(name)
	if not start then return end
	return {startTime = start, duration = duration, isEnabled = enabled == 1, modRate = 1}
end
function Compat.IsSpellKnown(spellId, isPet)
	if not spellId then return false end
	if IsSpellKnown then
		return IsSpellKnown(spellId, isPet) and true or false
	end
	local name = GetSpellInfo(spellId)
	return name and GetSpellInfo(name) and true or false
end

--------------------------------------------------------------------------------
-- Auras (C_UnitAuras replacement)
--

do
	local UnitAura = UnitAura
	local function buildAura(unit, index, filter, ...)
		local name, rank, icon, count, debuffType, duration, expirationTime, unitCaster, isStealable, shouldConsolidate, spellId = ...
		if not name then return end
		return {
			name = name, icon = icon, applications = count or 0, charges = count or 0, dispelName = debuffType,
			duration = duration or 0, expirationTime = expirationTime or 0, sourceUnit = unitCaster,
			isStealable = isStealable and true or false, spellId = spellId, auraIndex = index,
			isHelpful = filter ~= "HARMFUL", isHarmful = filter == "HARMFUL", points = {},
		}
	end
	--- C_UnitAuras.GetAuraDataByIndex
	function Compat.GetAuraDataByIndex(unit, index, filter)
		filter = filter or "HELPFUL"
		local f = filter:find("HARMFUL") and "HARMFUL" or "HELPFUL"
		return buildAura(unit, index, f, UnitAura(unit, index, filter))
	end
	--- C_UnitAuras.GetUnitAuraBySpellID / GetPlayerAuraBySpellID
	function Compat.GetUnitAuraBySpellID(unit, spellId, filter)
		if not unit or not spellId then return end
		if filter then
			local f = filter:find("HARMFUL") and "HARMFUL" or "HELPFUL"
			for i = 1, 40 do
				local name, _, _, _, _, _, _, _, _, _, id = UnitAura(unit, i, filter)
				if not name then break end
				if id == spellId then
					return buildAura(unit, i, f, UnitAura(unit, i, filter))
				end
			end
			return
		end
		for i = 1, 40 do
			local name, _, _, _, _, _, _, _, _, _, id = UnitAura(unit, i, "HELPFUL")
			if not name then break end
			if id == spellId then
				return buildAura(unit, i, "HELPFUL", UnitAura(unit, i, "HELPFUL"))
			end
		end
		for i = 1, 40 do
			local name, _, _, _, _, _, _, _, _, _, id = UnitAura(unit, i, "HARMFUL")
			if not name then break end
			if id == spellId then
				return buildAura(unit, i, "HARMFUL", UnitAura(unit, i, "HARMFUL"))
			end
		end
	end
	function Compat.GetPlayerAuraBySpellID(spellId)
		return Compat.GetUnitAuraBySpellID("player", spellId)
	end
end

--------------------------------------------------------------------------------
-- AddOns (C_AddOns replacement)
--

do
	local GetAddOnInfo = GetAddOnInfo
	--- Modern return order: name, title, notes, loadable, reason, security, updateAvailable
	function Compat.GetAddOnInfo(index)
		local name, title, notes, enabled, loadable, reason, security = GetAddOnInfo(index)
		return name, title, notes, loadable and true or false, reason, security, false, enabled and true or false
	end
	--- Modern: 0 = disabled, 1 = enabled for some, 2 = enabled
	function Compat.GetAddOnEnableState(nameOrIndex)
		local _, _, _, enabled = GetAddOnInfo(nameOrIndex)
		return enabled and 2 or 0
	end
	function Compat.IsAddOnLoaded(index)
		return IsAddOnLoaded(index) and true or false
	end
	function Compat.LoadAddOn(index)
		local loaded, reason = LoadAddOn(index)
		return loaded and true or false, reason
	end
	function Compat.IsAddOnLoadOnDemand(index)
		return IsAddOnLoadOnDemand(index) and true or false
	end
	Compat.GetAddOnMetadata = GetAddOnMetadata
	Compat.EnableAddOn = EnableAddOn
	Compat.DisableAddOn = DisableAddOn
	Compat.GetNumAddOns = GetNumAddOns
	Compat.GetAddOnDependencies = GetAddOnDependencies
	Compat.GetAddOnOptionalDependencies = GetAddOnOptionalDependencies or function() end
	function Compat.DoesAddOnHaveLoadError() return false end
end

--------------------------------------------------------------------------------
-- Addon communication
--

do
	local SendAddonMessage = SendAddonMessage
	local channelMap = {
		INSTANCE_CHAT = "BATTLEGROUND",
	}
	--- C_ChatInfo.SendAddonMessage replacement. Returns 0 on success, 5 when not in a group.
	function Compat.SendAddonMessage(prefix, msg, channel, target)
		channel = channelMap[channel] or channel
		if (channel == "RAID" or channel == "PARTY") and not Compat.IsInGroup() then
			return 5
		end
		if channel == "RAID" and GetNumRaidMembers() == 0 then
			channel = "PARTY"
		end
		msg = msg or ""
		-- 3.3.5: prefix + message must be < 255 characters
		local maxLen = 254 - #prefix
		if #msg > maxLen then
			msg = strsub(msg, 1, maxLen)
		end
		SendAddonMessage(prefix, msg, channel, target)
		return 0
	end
	function Compat.RegisterAddonMessagePrefix() return true end
	--- C_ChatInfo.SendChatMessage replacement
	function Compat.SendChatMessage(msg, chatType, language, target)
		chatType = channelMap[chatType] or chatType
		if chatType == "RAID" and GetNumRaidMembers() == 0 then
			if GetNumPartyMembers() > 0 then
				chatType = "PARTY"
			else
				return
			end
		end
		SendChatMessage(msg, chatType, language, target)
	end
end

--------------------------------------------------------------------------------
-- Zones & instances
--

-- GetCurrentMapAreaID() on Sirus -> instance (Map.dbc) id used by BigWigs modules.
-- Area ids taken from the DBM build for Sirus (X-DBM-Mod-MapID).
Compat.areaToInstance = {
	-- Classic dungeons
	[689] = 48, -- Blackfathom Deeps
	[705] = 230, -- Blackrock Depths
	[722] = 229, -- Blackrock Spire
	[700] = 429, -- Dire Maul
	[692] = 90, -- Gnomeregan
	[751] = 349, -- Maraudon
	[681] = 389, -- Ragefire Chasm
	[761] = 129, -- Razorfen Downs
	[762] = 47, -- Razorfen Kraul
	[763] = 189, -- Scarlet Monastery
	[764] = 289, -- Scholomance
	[765] = 33, -- Shadowfang Keep
	[766] = 329, -- Stratholme
	[757] = 36, -- The Deadmines
	[691] = 34, -- The Stockade
	[688] = 109, -- The Temple of Atal'Hakkar
	[693] = 70, -- Uldaman
	[750] = 43, -- Wailing Caverns
	[687] = 209, -- Zul'Farrak
	-- Classic raids
	[697] = 409, -- Molten Core
	[756] = 469, -- Blackwing Lair
	[718] = 509, -- Ruins of Ahn'Qiraj
	[767] = 531, -- Temple of Ahn'Qiraj
	[698] = 309, -- Zul'Gurub
	-- The Burning Crusade dungeons
	[723] = 558, -- Auchenai Crypts
	[798] = 543, -- Hellfire Ramparts
	[799] = 585, -- Magisters' Terrace
	[733] = 557, -- Mana-Tombs
	[735] = 560, -- Old Hillsbrad Foothills
	[724] = 556, -- Sethekk Halls
	[725] = 555, -- Shadow Labyrinth
	[732] = 552, -- The Arcatraz
	[734] = 269, -- The Black Morass
	[726] = 542, -- The Blood Furnace
	[730] = 553, -- The Botanica
	[731] = 554, -- The Mechanar
	[711] = 540, -- The Shattered Halls
	[729] = 547, -- The Slave Pens
	[728] = 545, -- The Steamvault
	[727] = 546, -- The Underbog
	-- The Burning Crusade raids
	[797] = 564, -- Black Temple
	[848] = 564, -- Black Temple (Sirus alternative map)
	[777] = 565, -- Gruul's Lair
	[776] = 534, -- Hyjal Summit
	[864] = 534, -- Hyjal Summit (Sirus alternative map)
	[800] = 532, -- Karazhan
	[868] = 532, -- Karazhan (Sirus)
	[780] = 544, -- Magtheridon's Lair
	[781] = 548, -- Serpentshrine Cavern
	[863] = 548, -- Serpentshrine Cavern (Sirus)
	[790] = 580, -- Sunwell Plateau
	[783] = 550, -- Tempest Keep: The Eye
	[862] = 550, -- Tempest Keep: The Eye (Sirus)
	[782] = 568, -- Zul'Aman
	-- Wrath of the Lich King dungeons
	[524] = 574, -- Utgarde Keep
	[525] = 575, -- Utgarde Pinnacle
	[521] = 576, -- The Nexus
	[529] = 578, -- The Oculus
	[537] = 608, -- The Violet Hold
	[522] = 595, -- The Culling of Stratholme
	[523] = 619, -- Ahn'kahet: The Old Kingdom
	[531] = 604, -- Gundrak
	[526] = 602, -- Halls of Lightning
	[534] = 601, -- Azjol-Nerub
	[603] = 658, -- Pit of Saron
	[527] = 599, -- Halls of Stone
	[535] = 600, -- Drak'Tharon Keep
	[543] = 650, -- Trial of the Champion
	[604] = 668, -- Halls of Reflection
	[602] = 632, -- The Forge of Souls
	-- Wrath of the Lich King raids
	[605] = 631, -- Icecrown Citadel
	[536] = 533, -- Naxxramas
	[719] = 249, -- Onyxia's Lair
	[528] = 616, -- The Eye of Eternity
	[532] = 615, -- The Obsidian Sanctum
	[610] = 724, -- The Ruby Sanctum
	[544] = 649, -- Trial of the Crusader
	[530] = 603, -- Ulduar
	[533] = 624, -- Vault of Archavon
	-- Sirus custom instances (no Blizzard instance id exists, so a pseudo id of 10000 + area id is used)
	[925] = 10925, -- Bronze Sanctuary
	[955] = 10955, -- Tol'Garod Prison
}
-- Custom instances that are not in the table above still get a stable id: 10000 + area id.
Compat.CUSTOM_INSTANCE_OFFSET = 10000

-- Instance names for menus, the 3.3.5 client can't look up a zone name by id.
-- [instanceID] = {enUS, ruRU}
local instanceNames = {
	-- Classic
	[33] = {"Shadowfang Keep", "Крепость Темного Клыка"},
	[34] = {"The Stockade", "Тюрьма"},
	[36] = {"The Deadmines", "Мертвые копи"},
	[43] = {"Wailing Caverns", "Пещеры Стенаний"},
	[47] = {"Razorfen Kraul", "Лабиринты Иглошкурых"},
	[48] = {"Blackfathom Deeps", "Непроглядная Пучина"},
	[70] = {"Uldaman", "Ульдаман"},
	[90] = {"Gnomeregan", "Гномреган"},
	[109] = {"Sunken Temple", "Затонувший храм"},
	[129] = {"Razorfen Downs", "Курганы Иглошкурых"},
	[189] = {"Scarlet Monastery", "Монастырь Алого ордена"},
	[209] = {"Zul'Farrak", "Зул'Фаррак"},
	[229] = {"Blackrock Spire", "Пик Черной горы"},
	[230] = {"Blackrock Depths", "Глубины Черной горы"},
	[289] = {"Scholomance", "Некроситет"},
	[309] = {"Zul'Gurub", "Зул'Гуруб"},
	[329] = {"Stratholme", "Стратхольм"},
	[349] = {"Maraudon", "Мародон"},
	[389] = {"Ragefire Chasm", "Огненная пропасть"},
	[409] = {"Molten Core", "Огненные Недра"},
	[429] = {"Dire Maul", "Забытый город"},
	[469] = {"Blackwing Lair", "Логово Крыла Тьмы"},
	[509] = {"Ruins of Ahn'Qiraj", "Руины Ан'Киража"},
	[531] = {"Ahn'Qiraj Temple", "Храм Ан'Киража"},
	-- The Burning Crusade
	[269] = {"The Black Morass", "Черные топи"},
	[532] = {"Karazhan", "Каражан"},
	[534] = {"Hyjal Summit", "Вершина Хиджала"},
	[540] = {"The Shattered Halls", "Разрушенные залы"},
	[542] = {"The Blood Furnace", "Кузня Крови"},
	[543] = {"Hellfire Ramparts", "Бастионы Адского Пламени"},
	[544] = {"Magtheridon's Lair", "Логово Магтеридона"},
	[545] = {"The Steamvault", "Паровое подземелье"},
	[546] = {"The Underbog", "Нижетопь"},
	[547] = {"The Slave Pens", "Узилище"},
	[548] = {"Serpentshrine Cavern", "Змеиное святилище"},
	[550] = {"Tempest Keep", "Крепость Бурь"},
	[552] = {"The Arcatraz", "Аркатрац"},
	[553] = {"The Botanica", "Ботаника"},
	[554] = {"The Mechanar", "Механар"},
	[555] = {"Shadow Labyrinth", "Темный лабиринт"},
	[556] = {"Sethekk Halls", "Сетеккские залы"},
	[557] = {"Mana-Tombs", "Гробницы Маны"},
	[558] = {"Auchenai Crypts", "Аукенайские гробницы"},
	[560] = {"Old Hillsbrad Foothills", "Старые предгорья Хилсбрада"},
	[564] = {"Black Temple", "Черный храм"},
	[565] = {"Gruul's Lair", "Логово Груула"},
	[568] = {"Zul'Aman", "Зул'Аман"},
	[580] = {"Sunwell Plateau", "Плато Солнечного Колодца"},
	[585] = {"Magisters' Terrace", "Терраса Магистров"},
	-- Wrath of the Lich King
	[249] = {"Onyxia's Lair", "Логово Ониксии"},
	[533] = {"Naxxramas", "Наксрамас"},
	[574] = {"Utgarde Keep", "Крепость Утгард"},
	[575] = {"Utgarde Pinnacle", "Вершина Утгард"},
	[576] = {"The Nexus", "Нексус"},
	[578] = {"The Oculus", "Окулус"},
	[595] = {"The Culling of Stratholme", "Очищение Стратхольма"},
	[599] = {"Halls of Stone", "Чертоги Камня"},
	[600] = {"Drak'Tharon Keep", "Крепость Драк'Тарон"},
	[601] = {"Azjol-Nerub", "Азжол-Неруб"},
	[602] = {"Halls of Lightning", "Чертоги Молний"},
	[603] = {"Ulduar", "Ульдуар"},
	[604] = {"Gundrak", "Гундрак"},
	[608] = {"The Violet Hold", "Аметистовая крепость"},
	[615] = {"The Obsidian Sanctum", "Обсидиановое святилище"},
	[616] = {"The Eye of Eternity", "Око Вечности"},
	[619] = {"Ahn'kahet: The Old Kingdom", "Ан'кахет: Старое Королевство"},
	[624] = {"Vault of Archavon", "Склеп Аркавона"},
	[631] = {"Icecrown Citadel", "Цитадель Ледяной Короны"},
	[632] = {"The Forge of Souls", "Кузня Душ"},
	[649] = {"Trial of the Crusader", "Испытание крестоносца"},
	[650] = {"Trial of the Champion", "Испытание чемпиона"},
	[658] = {"Pit of Saron", "Яма Сарона"},
	[668] = {"Halls of Reflection", "Залы Отражений"},
	[724] = {"The Ruby Sanctum", "Рубиновое святилище"},
	-- Sirus
	[10925] = {"Bronze Sanctuary", "Бронзовое святилище"},
	[10955] = {"Tol'Garod Prison", "Тол'Гародская тюрьма"},
}
Compat.instanceNames = instanceNames
do
	local isRussian = GetLocale() == "ruRU"
	local learned = {} -- names seen while inside an instance, always correct for the current client
	function Compat.LearnZoneName(instanceID, name)
		if instanceID and instanceID > 0 and type(name) == "string" and name ~= "" then
			learned[instanceID] = name
		end
	end
	--- GetRealZoneText(instanceID) replacement for 3.3.5 (where GetRealZoneText takes no argument)
	function Compat.GetZoneNameByInstanceID(id)
		if not id then return GetRealZoneText() end
		if learned[id] then return learned[id] end
		local entry = instanceNames[id]
		if entry then
			return isRussian and entry[2] or entry[1]
		end
		if id > Compat.CUSTOM_INSTANCE_OFFSET then
			return format("Sirus #%d", id - Compat.CUSTOM_INSTANCE_OFFSET)
		end
		-- Unknown id (e.g. retail only content): return a non empty string so modules still register
		return tostring(id)
	end
end

--- Returns the area id of the zone the player is in (Sirus/3.3.5 GetCurrentMapAreaID)
function Compat.GetCurrentAreaID()
	if WorldMapFrame and WorldMapFrame:IsShown() then
		-- Don't move the map the user is looking at, use the cached value
		return Compat.lastAreaID or 0
	end
	SetMapToCurrentZone()
	local id = GetCurrentMapAreaID() or 0
	Compat.lastAreaID = id
	return id
end

function Compat.GetInstanceIDFromArea(areaID)
	if not areaID or areaID <= 0 then return 0 end
	return Compat.areaToInstance[areaID] or (Compat.CUSTOM_INSTANCE_OFFSET + areaID)
end

--- C_Map.GetBestMapForUnit replacement, only "player" is supported
function Compat.GetBestMapForUnit()
	return Compat.GetCurrentAreaID()
end
--- C_Map.GetMapInfo replacement, the 3.3.5 client can't look up map names by id:
-- only the world maps of the world boss modules (zone names from the DBM Sirus .toc LoadZone) are known
do
	local isRussian = GetLocale() == "ruRU"
	local mapNames = {
		[914] = {"A Waking Nightmare", "Кошмар Наяву"}, -- Zort
		[946] = {"Tol'Garod", "Тол'Гарод"}, -- Norigorn
	}
	Compat.mapNames = mapNames
	function Compat.GetMapInfo(mapID)
		local entry = mapID and mapNames[mapID]
		if entry then
			return {mapID = mapID, name = isRussian and entry[2] or entry[1]}
		end
	end
end

do
	local GetInstanceInfo = GetInstanceInfo
	--- Convert the 3.3.5 difficulty to the modern difficulty ids used by BigWigs
	-- 1 = 5 Normal, 2 = 5 Heroic, 23 = 5 Mythic (Sirus), 3 = 10 Normal, 4 = 25 Normal, 5 = 10 Heroic, 6 = 25 Heroic, 9 = 40 Player, 148 = 20 Player
	local function convertDifficulty(instanceType, difficultyIndex, difficultyName, maxPlayers, dynamicDifficulty, isDynamic)
		if instanceType == "party" then
			if difficultyIndex == 2 then return 2 end
			if difficultyIndex and difficultyIndex >= 3 then return 23 end
			return 1
		elseif instanceType == "raid" then
			local heroic
			if isDynamic then
				heroic = dynamicDifficulty == 1 or (difficultyIndex and difficultyIndex >= 3)
			else
				heroic = difficultyIndex and difficultyIndex >= 3
			end
			if maxPlayers == 40 then return 9 end
			if maxPlayers == 20 then return 148 end
			local size25 = maxPlayers == 25 or (not maxPlayers or maxPlayers == 0) and (difficultyIndex == 2 or difficultyIndex == 4)
			if heroic then
				return size25 and 6 or 5
			end
			return size25 and 4 or 3
		end
		return 0
	end
	Compat.ConvertDifficulty = convertDifficulty

	--- GetDifficultyInfo(difficultyID) replacement, returns the localized name of a modern difficulty id
	local difficultyNames = {
		[1] = DUNGEON_DIFFICULTY1, -- 5 Player
		[2] = DUNGEON_DIFFICULTY2, -- 5 Player (Heroic)
		[3] = RAID_DIFFICULTY1, -- 10 Player
		[4] = RAID_DIFFICULTY2, -- 25 Player
		[5] = RAID_DIFFICULTY3, -- 10 Player (Heroic)
		[6] = RAID_DIFFICULTY4, -- 25 Player (Heroic)
		[9] = "40", -- 40 Player
		[148] = "20", -- 20 Player
	}
	function Compat.GetDifficultyName(difficultyID)
		local name = difficultyNames[difficultyID]
		if difficultyID == 23 then
			return GetLocale() == "ruRU" and "Эпохальный" or "Mythic" -- Sirus mythic dungeons
		elseif name == "40" or name == "20" then
			return (GetLocale() == "ruRU" and "%s игроков" or "%s Player"):format(name)
		end
		return name
	end

	--- Modern GetInstanceInfo replacement:
	-- name, instanceType, difficultyID, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, instanceID, instanceGroupSize
	function Compat.GetInstanceInfo()
		local name, instanceType, difficultyIndex, difficultyName, maxPlayers, dynamicDifficulty, isDynamic = GetInstanceInfo()
		local difficultyID = convertDifficulty(instanceType, difficultyIndex, difficultyName, maxPlayers, dynamicDifficulty, isDynamic)
		local instanceID = 0
		if instanceType and instanceType ~= "none" then
			instanceID = Compat.GetInstanceIDFromArea(Compat.GetCurrentAreaID())
			Compat.LearnZoneName(instanceID, name)
		end
		return name, instanceType, difficultyID, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, instanceID, maxPlayers, difficultyIndex
	end
end

--- Encounter state emulation, 3.3.5 has no IsEncounterInProgress()
do
	local inProgress = false
	function Compat.SetEncounterInProgress(state)
		inProgress = state and true or false
	end
	local UnitAffectingCombat, UnitExists, UnitIsDead = UnitAffectingCombat, UnitExists, UnitIsDead
	--- Emulates IsEncounterInProgress(): a boss module is engaged (set by the core's encounter
	-- emulation, see BossPrototype.lua), or a living boss unit (boss1-4) is in combat.
	function Compat.IsEncounterInProgress()
		if inProgress then return true end
		for i = 1, 4 do
			local unit = "boss"..i
			if UnitExists(unit) and not UnitIsDead(unit) and UnitAffectingCombat(unit) then
				return true
			end
		end
		return false
	end
end

--------------------------------------------------------------------------------
-- Events
--

-- Modern events that simply don't exist on 3.3.5, registering them is skipped
Compat.unsupportedEvents = {
	ENCOUNTER_START = true, ENCOUNTER_END = true, BOSS_KILL = true,
	ENCOUNTER_WARNING = true, ENCOUNTER_TIMELINE_EVENT_ADDED = true, ENCOUNTER_TIMELINE_EVENT_REMOVED = true, ENCOUNTER_TIMELINE_EVENT_STATE_CHANGED = true,
	NAME_PLATE_UNIT_ADDED = true, NAME_PLATE_UNIT_REMOVED = true,
	UPDATE_UI_WIDGET = true, RAID_BOSS_WHISPER = true, RAID_BOSS_EMOTE = true,
	PLAYER_MAP_CHANGED = true, DISPLAY_EVENT_TOASTS = true, TALKINGHEAD_REQUESTED = true,
	ITEM_DATA_LOAD_RESULT = true, SPELL_DATA_LOAD_RESULT = true, CHALLENGE_MODE_START = true, CHALLENGE_MODE_COMPLETED = true,
	CHALLENGE_MODE_RESET = true, ADDON_RESTRICTION_STATE_CHANGED = true, SPELL_TEXT_UPDATE = true,
	TOOLTIP_DATA_UPDATE = true, PLAYER_SPECIALIZATION_CHANGED = true, -- UNIT_THREAT_LIST_UPDATE exists since 3.0.2
	GROUP_FORMED = true, GROUP_LEFT = true, START_PLAYER_COUNTDOWN = true, CANCEL_PLAYER_COUNTDOWN = true,
	LOADING_SCREEN_DISABLED = true, LOADING_SCREEN_ENABLED = true, UNIT_ENTERING_COMBAT = true,
	PLAYER_CHOICE_UPDATE = true, SCENARIO_CRITERIA_UPDATE = true, UNIT_SPELLCAST_EMPOWER_START = true,
	UNIT_SPELLCAST_EMPOWER_STOP = true, PLAYER_SOFT_ENEMY_CHANGED = true, PLAYER_SOFT_INTERACT_CHANGED = true,
}

-- Modern event -> 3.3.5 events that replace it, with an optional extra argument appended (the modern powerType)
Compat.eventAliases = {
	GROUP_ROSTER_UPDATE = {{"RAID_ROSTER_UPDATE"}, {"PARTY_MEMBERS_CHANGED"}},
	UNIT_HEALTH_FREQUENT = {{"UNIT_HEALTH"}},
	UNIT_POWER_UPDATE = {{"UNIT_MANA", "MANA"}, {"UNIT_RAGE", "RAGE"}, {"UNIT_ENERGY", "ENERGY"}, {"UNIT_RUNIC_POWER", "RUNIC_POWER"}, {"UNIT_FOCUS", "FOCUS"}},
	UNIT_POWER_FREQUENT = {{"UNIT_MANA", "MANA"}, {"UNIT_RAGE", "RAGE"}, {"UNIT_ENERGY", "ENERGY"}, {"UNIT_RUNIC_POWER", "RUNIC_POWER"}, {"UNIT_FOCUS", "FOCUS"}},
	UNIT_MAXPOWER = {{"UNIT_MAXMANA", "MANA"}, {"UNIT_MAXRAGE", "RAGE"}, {"UNIT_MAXENERGY", "ENERGY"}, {"UNIT_MAXRUNIC_POWER", "RUNIC_POWER"}, {"UNIT_MAXFOCUS", "FOCUS"}},
	PLAYER_SOFT_TARGET_CHANGED = {{"PLAYER_TARGET_CHANGED"}},
	-- No targetable state on 3.3.5, UNIT_FLAGS fires when e.g. UNIT_FLAG_NOT_SELECTABLE changes.
	-- It also fires for unrelated flag changes, so handlers have to compare the state themselves.
	UNIT_TARGETABLE_CHANGED = {{"UNIT_FLAGS"}},
}
-- Reverse lookup: 3.3.5 event -> list of {modernEvent, extraArg}
Compat.eventAliasTargets = {}
for modern, list in next, Compat.eventAliases do
	for i = 1, #list do
		local real, extra = list[i][1], list[i][2]
		if not Compat.eventAliasTargets[real] then Compat.eventAliasTargets[real] = {} end
		local t = Compat.eventAliasTargets[real]
		t[#t+1] = {modern, extra}
	end
end

--------------------------------------------------------------------------------
-- Widgets (methods that don't exist on 3.3.5 regions)
--

function Compat.SetColorTexture(texture, r, g, b, a)
	texture:SetTexture(r, g, b, a or 1)
end

function Compat.SetResizeBounds(frame, minW, minH, maxW, maxH)
	if minW then frame:SetMinResize(minW, minH or minW) end
	if maxW then frame:SetMaxResize(maxW, maxH or maxW) end
end

function Compat.SetShown(region, show)
	if show then region:Show() else region:Hide() end
end

--- Alpha animations in 3.3.5 only have SetChange(delta), so the region alpha is forced to "from" when the animation starts
function Compat.SetAlphaFromTo(anim, from, to)
	anim:SetChange(to - from)
	anim.bwFromAlpha = from
	if not anim.bwHooked then
		anim.bwHooked = true
		anim:SetScript("OnPlay", function(self)
			local region = self:GetRegionParent()
			if region and self.bwFromAlpha then
				region:SetAlpha(self.bwFromAlpha)
			end
		end)
	end
end

--------------------------------------------------------------------------------
-- File data ids used by the modern code -> 3.3.5 paths
--

Compat.fileIDs = {
	-- Raid target icons
	[137001] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_1",
	[137002] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_2",
	[137003] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_3",
	[137004] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_4",
	[137005] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_5",
	[137006] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_6",
	[137007] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_7",
	[137008] = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8",
	-- Buttons
	[130763] = "Interface\\Buttons\\UI-DialogBox-Button-Up",
	[130761] = "Interface\\Buttons\\UI-DialogBox-Button-Down",
	[130762] = "Interface\\Buttons\\UI-DialogBox-Button-Highlight",
	[130871] = "Interface\\Buttons\\WHITE8X8",
	[137012] = "Interface\\Tooltips\\UI-Tooltip-Border",
	[137056] = "Interface\\Tooltips\\UI-Tooltip-Background",
	[134400] = "Interface\\Icons\\INV_Misc_QuestionMark",
	-- Icons used by the plugins
	[134376] = "Interface\\Icons\\INV_Misc_PocketWatch_01",
	[134062] = "Interface\\Icons\\INV_Misc_Fork&Knife",
	[132337] = "Interface\\Icons\\Ability_Warrior_Charge",
	[236372] = "Interface\\Icons\\Achievement_BG_returnXflags_def_WSG",
	[136001] = "Interface\\Icons\\Spell_Nature_Reincarnation",
	[237538] = "Interface\\Icons\\Spell_Holy_BorrowedTime",
	[132768] = "Interface\\Icons\\Ability_Hunter_Pet_Turtle",
	[134414] = "Interface\\Icons\\INV_Misc_Rune_01",
	[136243] = "Interface\\Icons\\Trade_Engineering",
	-- Sounds
	[569200] = "Sound\\Spells\\PVPFlagTaken.wav",
	[543587] = "Sound\\Creature\\AlgalonTheObserver\\UR_Algalon_BHole01.wav",
	[553193] = "Sound\\Creature\\KilJaeden\\KILJAEDEN02.wav",
	[552035] = "Sound\\Creature\\HoodWolf\\HoodWolfTransformPlayer01.wav",
	[567397] = "Sound\\Interface\\RaidWarning.wav",
	[567474] = "Sound\\Interface\\AlarmClockWarning3.wav", -- no battleground countdown sound in 3.3.5
	[569593] = "Sound\\Interface\\LevelUp.wav",
	[566558] = "Sound\\Interface\\ReadyCheck.wav",
}

--- Convert a texture/sound reference (file data id or path) to something the 3.3.5 client can use
function Compat.File(id)
	if type(id) == "number" then
		return Compat.fileIDs[id] or "Interface\\Icons\\INV_Misc_QuestionMark"
	end
	return id
end

--- Raid target icon markup, replaces "|T13700%d:0|t"
function Compat.RaidIconMarkup(index, size)
	return format("|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_%d:%d|t", index, size or 0)
end

--- Media files that the client knows about. 3.3.5 has no C_UIFileAsset, so trust any non empty path.
function Compat.IsKnownFile(path)
	return type(path) == "string" and path ~= ""
end

--------------------------------------------------------------------------------
-- Misc
--

function Compat.GetServerTime()
	return time()
end

function Compat.IsPublicTestClient()
	return false
end

--------------------------------------------------------------------------------
-- Script-driven fade animation
-- Mimics the small part of the AnimationGroup + Alpha API that the plugins use
-- (Play/Stop/IsPlaying/SetScript/GetParent and SetStartDelay/SetDuration on the
-- fade), driven by one shared OnUpdate frame. Used for FontStrings and Textures,
-- whose animation support in 3.3.5 is unreliable.
--

do
	local active = {}
	local driver = CreateFrame("Frame")
	driver:Hide()

	local groupProto = {}
	local groupMeta = {__index = groupProto}
	local fadeProto = {}
	local fadeMeta = {__index = fadeProto}

	function fadeProto:SetStartDelay(delay) self.delay = delay or 0 end
	function fadeProto:SetDuration(duration) self.duration = duration or 0 end
	function fadeProto:GetDuration() return self.duration end

	function groupProto:GetParent() return self.region end
	function groupProto:SetScript(name, func) self.scripts[name] = func end
	function groupProto:GetScript(name) return self.scripts[name] end
	function groupProto:IsPlaying() return active[self] == true end
	function groupProto:Play()
		self.elapsed = 0
		self.region:SetAlpha(self.fade.fromAlpha)
		active[self] = true
		driver:Show()
	end
	function groupProto:Stop()
		if active[self] then
			active[self] = nil
			self.region:SetAlpha(self.fade.fromAlpha)
		end
	end

	local function Step(group, elapsed)
		local onUpdate = group.scripts.OnUpdate
		if onUpdate then
			onUpdate(group, elapsed)
			if not active[group] then return end -- Stopped by the OnUpdate script
		end
		local fade = group.fade
		group.elapsed = group.elapsed + elapsed
		local t = group.elapsed - fade.delay
		if t >= fade.duration then
			active[group] = nil
			local onFinished = group.scripts.OnFinished
			if onFinished then
				onFinished(group)
			end
			if not active[group] then -- Not restarted by the OnFinished script
				group.region:SetAlpha(fade.fromAlpha)
			end
		elseif t > 0 then
			group.region:SetAlpha(fade.fromAlpha + (fade.toAlpha - fade.fromAlpha) * (t / fade.duration))
		end
	end

	driver:SetScript("OnUpdate", function(self, elapsed)
		local any = false
		for group in next, active do
			any = true
			Step(group, elapsed)
		end
		if not any then
			self:Hide()
		end
	end)

	-- Returns group, fade
	function Compat.CreateFadeAnimation(region, fromAlpha, toAlpha)
		local fade = setmetatable({delay = 0, duration = 0, fromAlpha = fromAlpha or 1, toAlpha = toAlpha or 0}, fadeMeta)
		local group = setmetatable({region = region, scripts = {}, fade = fade, elapsed = 0}, groupMeta)
		return group, fade
	end
end
