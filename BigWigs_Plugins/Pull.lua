-------------------------------------------------------------------------------
-- Module Declaration
--

local plugin, L = BigWigs:NewPlugin("Pull")
if not plugin then return end

-------------------------------------------------------------------------------
-- Locals
--

local DoCountdown -- Defined below
local isLogging = false
local pendingLogStopTimer
local function cancelLogStop()
	if pendingLogStopTimer then
		plugin:CancelTimer(pendingLogStopTimer)
		pendingLogStopTimer = nil
	end
end
local function scheduleLogStop(delay)
	cancelLogStop()
	pendingLogStopTimer = plugin:ScheduleTimer(function()
		pendingLogStopTimer = nil
		isLogging = false
		LoggingCombat(false)
	end, delay)
end
local LibSharedMedia = LibStub("LibSharedMedia-3.0")
local SOUND = LibSharedMedia.MediaType and LibSharedMedia.MediaType.SOUND or "sound"

local BWPull = CreateFrame("Button", "BWPull")
BWPull:SetSize(1, 1)
BWPull:Hide()
BWPull:SetScript("OnClick", function()
	DoCountdown(10)
end)
BWPull:SetScript("OnEvent", function(self, event)
	self:UnregisterEvent(event)
	ClearOverrideBindings(self)
	if plugin.db.profile.keybind ~= "" then
		SetOverrideBindingClick(self, true, plugin.db.profile.keybind, "BWPull")
	end
end)

-------------------------------------------------------------------------------
-- Options
--

do
	local voiceMap = {
		deDE = "deDE: Default (Female)",
		esES = "esES: Default (Female)",
		esMX = "esMX: Default (Female)",
		frFR = "frFR: Default (Female)",
		itIT = "itIT: Default (Female)",
		koKR = "koKR: Default (Female)",
		ptBR = "ptBR: Default (Female)",
		ruRU = "ruRU: Default (Female)",
		zhCN = "zhCN: Default (Female)",
		zhTW = "zhTW: Default (Female)",
	}
	plugin.defaultDB = {
		countType = "emphasized",
		countBegin = 5,
		combatLog = false,
		engageSound = "None",
		startPullSound = "BigWigs: Long",
		startPullMessage = true,
		endPullSound = "BigWigs: Alarm",
		voice = voiceMap[GetLocale()] or "English: Amy",
		keybind = "",
	}
end

do
	local function soundGet(info)
		for i, v in next, LibSharedMedia:List(SOUND) do
			if v == plugin.db.profile[info[#info]] then
				return i
			end
		end
	end
	local function soundSet(info, value)
		plugin.db.profile[info[#info]] = LibSharedMedia:List(SOUND)[value]
	end

	local function voiceSorting()
		local list = BigWigsAPI:GetCountdownList()
		local sorted = {}
		for k in next, list do
			if k ~= "none" and k ~= "simple" then
				sorted[#sorted + 1] = k
			end
		end
		table.sort(sorted, function(a, b) return list[a] < list[b] end)
		table.insert(sorted, 1, "none")
		table.insert(sorted, 2, "simple")
		return sorted
	end

	plugin.pluginOptions = {
		name = "|TInterface\\AddOns\\BigWigs\\Media\\Icons\\Menus\\Pull:20|t ".. L.pull,
		type = "group",
		childGroups = "tab",
		get = function(i) return plugin.db.profile[i[#i]] end,
		set = function(i, value) plugin.db.profile[i[#i]] = value end,
		order = 10,
		args = {
			countType = {
				type = "select",
				name = L.countdownType,
				order = 1,
				values = {
					normal = L.expiring_normal,
					emphasized = L.emphasized,
				},
			},
			countBegin = {
				name = L.countdownBegins,
				desc = L.countdownBegins_desc,
				type = "range", min = 5, max = 10, step = 1,
				order = 2,
				width = 1.5
			},
			spacer1 = {
				type = "description",
				name = "\n",
				order = 3,
				width = "full",
			},
			engageSound = {
				type = "select",
				name = L.engageSoundTitle,
				order = 4,
				get = soundGet,
				set = soundSet,
				values = LibSharedMedia:List(SOUND),
				width = 2.5,
				dialogControl = "BigWigsSharedDropdown",
				itemControl = "DDI-Sound",
			},
			spacer2 = {
				type = "description",
				name = "\n",
				order = 5,
				width = "full",
			},
			startPullSound = {
				type = "select",
				name = L.pullStartedSoundTitle,
				order = 6,
				get = soundGet,
				set = soundSet,
				values = LibSharedMedia:List(SOUND),
				width = 2.5,
				dialogControl = "BigWigsSharedDropdown",
				itemControl = "DDI-Sound",
			},
			startPullMessage = {
				type = "toggle",
				name = L.pullStartedMessageTitle,
				order = 7,
				width = "full",
			},
			endPullSound = {
				type = "select",
				name = L.pullFinishedSoundTitle,
				order = 8,
				get = soundGet,
				set = soundSet,
				values = LibSharedMedia:List(SOUND),
				width = 2.5,
				dialogControl = "BigWigsSharedDropdown",
				itemControl = "DDI-Sound",
			},
			voice = {
				name = L.countdownVoice,
				type = "select",
				values = BigWigsAPI.GetCountdownList,
				sorting = voiceSorting,
				order = 9,
				width = 2.5,
			},
			spacer3 = {
				type = "description",
				name = "\n",
				order = 10,
				width = "full",
			},
			combatLog = {
				type = "toggle",
				name = L.combatLog,
				desc = L.combatLogDesc,
				order = 11,
				width = "full",
			},
			explainer = {
				type = "description",
				name = L.pullExplainer,
				order = 12,
				width = "full",
				fontSize = "medium",
			},
			keybind = {
				type = "keybinding",
				name = L.keybinding,
				desc = L.pullKeybindingDesc,
				order = 13,
				set = function(_, key)
					plugin.db.profile.keybind = key
					if not InCombatLockdown() then
						ClearOverrideBindings(BWPull)
						if key ~= "" then
							SetOverrideBindingClick(BWPull, true, key, "BWPull")
						end
					else
						BWPull:RegisterEvent("PLAYER_REGEN_ENABLED")
					end
				end,
			},
			spacer = {
				type = "description",
				name = "\n\n",
				order = 14,
				width = "full",
				fontSize = "medium",
			},
			resetHeader = {
				type = "header",
				name = "",
				order = 15,
			},
			reset = {
				type = "execute",
				name = L.reset,
				desc = L.resetDesc,
				func = function()
					for k, v in next, plugin.defaultDB do
						plugin.db.profile[k] = v
					end
				end,
				order = 16,
			},
		},
	}
end

-------------------------------------------------------------------------------
-- Initialization
--

do
	local function updateProfile()
		local db = plugin.db.profile

		for k, v in next, db do
			local defaultType = type(plugin.defaultDB[k])
			if defaultType == "nil" then
				db[k] = nil
			elseif type(v) ~= defaultType then
				db[k] = plugin.defaultDB[k]
			end
		end

		if db.countType ~= "normal" and db.countType ~= "emphasized" then
			db.countType = plugin.defaultDB.countType
		end
		if db.countBegin < 5 or db.countBegin > 10 then
			db.countBegin = plugin.defaultDB.countBegin
		end
		local checkCount = math.floor(db.countBegin+0.5)
		if checkCount ~= db.countBegin then
			db.countBegin = checkCount
		end

		if not BigWigsAPI:HasCountdown(db.voice) then
			db.voice = plugin.defaultDB.voice
		end
		if not LibSharedMedia:IsValid(SOUND, db.engageSound) then
			db.engageSound = plugin.defaultDB.engageSound
		end
		if not LibSharedMedia:IsValid(SOUND, db.startPullSound) then
			db.startPullSound = plugin.defaultDB.startPullSound
		end
		if not LibSharedMedia:IsValid(SOUND, db.endPullSound) then
			db.endPullSound = plugin.defaultDB.endPullSound
		end

		if not InCombatLockdown() then
			ClearOverrideBindings(BWPull)
			if db.keybind ~= "" then
				SetOverrideBindingClick(BWPull, true, db.keybind, "BWPull")
			end
		else
			BWPull:RegisterEvent("PLAYER_REGEN_ENABLED")
		end
	end

	function plugin:OnPluginEnable()
		self:RegisterMessage("BigWigs_ProfileUpdate", updateProfile)
		updateProfile()

		self:RegisterMessage("BigWigs_OnBossWin")
		self:RegisterMessage("BigWigs_OnBossWipe", "BigWigs_OnBossWin")

		self:RegisterMessage("BigWigs_OnBossEngage")

		self:RegisterMessage("DBM_AddonMessage")
		self:RegisterMessage("BigWigs_PluginComm")
	end
end

function plugin:OnPluginDisable()
	cancelLogStop()
	if isLogging then
		isLogging = false
		LoggingCombat(false)
	end
end

-------------------------------------------------------------------------------
-- Event Handlers
--

local IsEncounterInProgress = BigWigsLoader.IsEncounterInProgress
local GetInstanceInfo = BigWigsLoader.GetInstanceInfo
local Compat = BigWigsLoader.Compat
local IsInGroup, IsInRaid = Compat.IsInGroup, Compat.IsInRaid
local UnitIsGroupLeader, UnitIsGroupAssistant = Compat.UnitIsGroupLeader, Compat.UnitIsGroupAssistant
local UnitGroupRolesAssigned = Compat.UnitGroupRolesAssigned

-- 3.3.5: No Blizzard countdown (C_PartyInfo.DoCountdown), pull timers are sent with the
-- DBM for Sirus protocol ("DBMv4-PT" timer\tareaID) so that DBM and BigWigs users both see them.
-- The Loader translates incoming "DBMv4-PT" messages to DBM_AddonMessage "PT".

local function IsChallengeModeActive()
	return false
end

do
	local timer, timeLeft = nil, 0
	local function printPull()
		timeLeft = timeLeft - 1
		if timeLeft == 0 then
			plugin:CancelTimer(timer)
			timer = nil
			if plugin.db.profile.countType == "emphasized" then
				plugin:SendMessage("BigWigs_StopCountdown", plugin, "pulling time") -- Remove the countdown text
			end
			local soundName = plugin.db.profile.endPullSound
			if soundName ~= "None" then
				local sound = LibSharedMedia:Fetch(SOUND, soundName, true)
				if sound then
					plugin:PlaySoundFile(sound)
				end
			end
		elseif timeLeft > 1 and IsEncounterInProgress() then -- Cancel the pull timer if we ninja pulled
			plugin:CancelTimer(timer)
			timer = nil
			timeLeft = 0
			BigWigs:Print(L.pullStoppedCombat)
			plugin:SendMessage("BigWigs_StopBar", plugin, L.pull)
			plugin:SendMessage("BigWigs_StopPull", plugin, "COMBAT")
			plugin:SendMessage("BigWigs_StopCountdown", plugin, "pulling time")
		elseif timeLeft <= plugin.db.profile.countBegin and plugin.db.profile.countType ~= "emphasized" then
			plugin:SendMessage("BigWigs_Message", plugin, nil, L.pullIn:format(timeLeft), "yellow")
		end
	end

	local zoneTable = BigWigsLoader.zoneTbl
	-- Don't fire pull timers from people in different zones...
	-- ...unless you're in a raid instance and the sender isn't, to allow raid leaders outside to send you pull timers
	local function IsSenderInOtherZone(senderAreaID)
		senderAreaID = tonumber(senderAreaID)
		if not senderAreaID or senderAreaID <= 0 then return false end -- No area sent, always allowed
		local myAreaID = Compat.GetCurrentAreaID()
		if not myAreaID or myAreaID <= 0 or myAreaID == senderAreaID then return false end
		local _, instanceType = GetInstanceInfo()
		if instanceType == "raid" and not zoneTable[Compat.GetInstanceIDFromArea(senderAreaID)] then
			return false
		end
		return true
	end

	local function IsAllowedSender(name)
		if UnitIsUnit(name, "player") then return true end
		if not IsInGroup() then return false end
		if UnitIsGroupLeader(name) or UnitIsGroupAssistant(name) then return true end
		if not IsInRaid() then return true end -- Anyone in a 5 man group
		return false
	end

	local function StopPull(self, name)
		if timer then
			if name then
				BigWigs:Print(L.pullStopped:format(name))
				self:SendMessage("BigWigs_StopPull", self, name)
			else
				BigWigs:Print(L.pullStoppedCombat)
				self:SendMessage("BigWigs_StopPull", self, "COMBAT")
			end
			self:CancelTimer(timer)
			timer = nil
			timeLeft = 0
			self:SendMessage("BigWigs_StopBar", self, L.pull)
			self:SendMessage("BigWigs_StopCountdown", self, "pulling time")
		end
	end

	function plugin:StartPull(timeSeconds, name, senderAreaID)
		timeSeconds = tonumber(timeSeconds)
		if not timeSeconds or IsEncounterInProgress() then return end -- We don't want pull timers during encounters
		name = name or "?"
		if not IsAllowedSender(name) or IsSenderInOtherZone(senderAreaID) then return end
		if timeSeconds == 0 then
			StopPull(self, name)
			return
		elseif timeSeconds < 0 or timeSeconds > 86400 or (timeSeconds > 0 and timeSeconds < 3) then
			return -- Same limits as DBM
		end

		if timer then
			self:CancelTimer(timer)
		end
		timeLeft = timeSeconds
		BigWigs:Print(L.pullStartedBy:format(name))
		timer = self:ScheduleRepeatingTimer(printPull, 1)
		if self.db.profile.combatLog then
			cancelLogStop()
			isLogging = true
			LoggingCombat(isLogging)
		end
		self:SendMessage("BigWigs_StartCountdown", self, nil, "pulling time", timeLeft, nil, self.db.profile.voice, self.db.profile.countBegin, self.db.profile.countType ~= "emphasized")
		if self.db.profile.startPullMessage then
			self:SendMessage("BigWigs_Message", self, nil, L.pullIn:format(timeLeft), "yellow")
		end
		self:SendMessage("BigWigs_StartBar", self, nil, L.pull, timeSeconds, 132337) -- 132337 = "Interface\\Icons\\ability_warrior_charge"
		self:SendMessage("BigWigs_StartPull", self, timeSeconds, name, L.pull, 132337)
		local soundName = self.db.profile.startPullSound
		if soundName ~= "None" then
			local sound = LibSharedMedia:Fetch(SOUND, soundName, true)
			if sound then
				self:PlaySoundFile(sound)
			end
		end
	end

	function plugin:DBM_AddonMessage(_, sender, prefix, seconds, senderAreaID)
		if prefix == "PT" then
			self:StartPull(seconds, sender, senderAreaID)
		end
	end

	-- Old style BigWigs pull sync, sent by other BigWigs ports
	function plugin:BigWigs_PluginComm(_, msg, seconds, sender)
		if msg == "Pull" and seconds then
			self:StartPull(seconds, sender)
		end
	end
end

--- Send a pull timer to the group (or start it locally when solo)
-- @number seconds the pull time, 0 to cancel
function DoCountdown(seconds)
	seconds = math.floor(tonumber(seconds) or 0)
	if IsInGroup() then
		local result = BigWigsLoader.SendAddonMessage("DBMv4-PT", ("%d\t%d"):format(seconds, Compat.GetCurrentAreaID()), "RAID") -- Falls back to PARTY when not in a raid
		if type(result) == "number" and result ~= 0 then
			BigWigs:Error("BigWigs: Failed to send pull timer. Error code: ".. result)
		end
		-- Our own message is echoed back to us by the server and handled through DBM_AddonMessage
	else
		plugin:StartPull(seconds, plugin:UnitName("player"))
	end
end

function plugin:BigWigs_OnBossWin()
	if isLogging and not IsChallengeModeActive() then -- Don't stop per-boss during an active Mythic+ key, only when the key itself ends
		scheduleLogStop(2) -- Delay to prevent any death events being cut out the log
	end
end

function plugin:BigWigs_OnBossEngage(_, module)
	if module and (module:GetJournalID() or module:GetAllowWin()) then
		local soundName = self.db.profile.engageSound
		if soundName ~= "None" then
			local sound = LibSharedMedia:Fetch(SOUND, soundName, true)
			if sound then
				self:PlaySoundFile(sound)
			end
		end
	end
end

-------------------------------------------------------------------------------
-- Slash Handler
--

BigWigsAPI.RegisterSlashCommand("/pull", function(input)
	if IsEncounterInProgress() then -- Doesn't make sense to allow this during encounters
		BigWigs:Print(L.encounterRestricted)
		return
	end

	if not IsInGroup() or (Compat.IsInLFGGroup() and UnitGroupRolesAssigned("player") == "TANK") or UnitIsGroupLeader("player") or UnitIsGroupAssistant("player") or (IsInGroup(1) and not IsInRaid()) then -- Solo, tank in LFG, leader, assist, anyone in 5m
		if not plugin:IsEnabled() then BigWigs:Enable() end
		if input == "" then
			DoCountdown(10) -- Allow typing /pull to start a 10 second pull timer
		else
			local seconds = tonumber(input)
			if not seconds or seconds < 0 or seconds > 86400 then BigWigs:Print(L.wrongPullFormat) return end
			if seconds ~= 0 then
				BigWigs:Print(L.sendPull)
			end
			DoCountdown(seconds)
		end
	else
		BigWigs:Print(L.requiresLeadOrAssist)
	end
end)
