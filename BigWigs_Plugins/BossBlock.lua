-------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5 (Sirus) port notes:
-- Talking heads, garrison/guild alerts, event toasts, quest tooltip lines and
-- sound file muting don't exist on 3.3.5, so those features were removed.
-- What's left: boss emotes, movies/cinematics, spell errors, zone text,
-- the quest tracker (WatchFrame) and the sound CVars.
--

local plugin, L = BigWigs:NewPlugin("BossBlock")
if not plugin then return end

-------------------------------------------------------------------------------
-- Database
--

plugin.defaultDB = {
	blockEmotes = true,
	blockMovies = true,
	blockSpellErrors = true,
	blockZoneChanges = true,
	blockObjectiveTracker = true,
	disableSfx = false,
	disableMusic = false,
	disableAmbience = false,
	disableErrorSpeech = false,
}
plugin.defaultGlobalDB = {
	watchedMovies = {},
	tableNeedsCopied = true,
}

--------------------------------------------------------------------------------
-- Locals
--

plugin.displayName = L.bossBlock
local loader = BigWigsLoader
local GetBestMapForUnit = loader.GetBestMapForUnit
local IsEncounterInProgress = loader.IsEncounterInProgress
local SetCVar, GetCVar = SetCVar, GetCVar
local RestoreAll
local activatedModules = {}
local modulesBlockingEmotes = {}
local bbFrame = CreateFrame("Frame")
bbFrame:Hide()

-------------------------------------------------------------------------------
-- Options
--

local function audioDisabled(cvar, key)
	return function()
		if IsEncounterInProgress() then
			return true
		elseif GetCVar(cvar) == "0" and not plugin.db.profile[key] then
			return true
		end
	end
end

plugin.pluginOptions = {
	name = "|TInterface\\AddOns\\BigWigs\\Media\\Icons\\Menus\\Block:20|t ".. L.bossBlock,
	desc = L.bossBlockDesc,
	type = "group",
	childGroups = "tab",
	order = 14,
	get = function(info)
		return plugin.db.profile[info[#info]]
	end,
	set = function(info, value)
		local entry = info[#info]
		plugin.db.profile[entry] = value
	end,
	disabled = function() return IsEncounterInProgress() end, -- Don't allow toggling during an encounter.
	args = {
		general = {
			type = "group",
			name = L.general,
			order = 1,
			args = {
				heading = {
					type = "description",
					name = L.bossBlockDesc,
					order = 0,
					width = "full",
					fontSize = "medium",
				},
				blockEmotes = {
					type = "toggle",
					name = L.blockEmotes,
					desc = L.blockEmotesDesc,
					width = "full",
					order = 1,
				},
				blockMovies = {
					type = "toggle",
					name = L.blockMovies,
					desc = L.blockMoviesDesc,
					width = "full",
					order = 2,
				},
				blockSpellErrors = {
					type = "toggle",
					name = L.blockSpellErrors,
					desc = L.blockSpellErrorsDesc,
					width = "full",
					order = 5,
				},
				blockZoneChanges = {
					type = "toggle",
					name = L.blockZoneChanges,
					desc = L.blockZoneChangesDesc,
					width = "full",
					order = 6,
				},
				blockObjectiveTracker = {
					type = "toggle",
					name = L.blockObjectiveTracker,
					desc = L.blockObjectiveTrackerDesc,
					width = "full",
					order = 8,
				},
			},
		},
		audio = {
			type = "group",
			name = L.audio,
			order = 2,
			args = {
				heading = {
					type = "description",
					name = L.bossBlockAudioDesc,
					order = 0,
					width = "full",
					fontSize = "medium",
				},
				disableMusic = {
					type = "toggle",
					name = L.disableMusic,
					desc = L.disableAudioDesc:format(L.music),
					width = "full",
					order = 1,
					disabled = audioDisabled("Sound_EnableMusic", "disableMusic"),
				},
				disableAmbience = {
					type = "toggle",
					name = L.disableAmbience,
					desc = L.disableAudioDesc:format(L.ambience),
					width = "full",
					order = 2,
					disabled = audioDisabled("Sound_EnableAmbience", "disableAmbience"),
				},
				disableErrorSpeech = {
					type = "toggle",
					name = L.disableErrorSpeech,
					desc = L.disableAudioDesc:format(L.errorSpeech),
					width = "full",
					order = 3,
					disabled = audioDisabled("Sound_EnableErrorSpeech", "disableErrorSpeech"),
				},
				disableSfx = {
					type = "toggle",
					name = L.disableSfx,
					desc = L.disableAudioDesc:format(L.sfx),
					width = "full",
					order = 4,
					disabled = audioDisabled("Sound_EnableSFX", "disableSfx"),
				},
			},
		},
	},
}

--------------------------------------------------------------------------------
-- Initialization
--

do
	local function CopyTable(settingsTable)
		local copy = {}
		for key, value in next, settingsTable do
			if type(value) == "table" then
				copy[key] = CopyTable(value)
			else
				copy[key] = value
			end
		end
		return copy
	end

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

		local globalDB = plugin.db.global
		for k, v in next, globalDB do
			local defaultType = type(plugin.defaultGlobalDB[k])
			if defaultType == "nil" then
				globalDB[k] = nil
			elseif type(v) ~= defaultType then
				if defaultType == "table" then
					globalDB[k] = CopyTable(plugin.defaultGlobalDB[k])
				else
					globalDB[k] = plugin.defaultGlobalDB[k]
				end
			end
		end
	end

	local function checkCVar(cvar, key, notify)
		if plugin.db.profile[key] then
			if GetCVar(cvar) == "0" then
				BigWigs:Print(notify)
			end
			SetCVar(cvar, "1")
		end
	end

	function plugin:OnPluginEnable()
		self:RegisterMessage("BigWigs_OnBossEngage", "OnEngage")
		self:RegisterMessage("BigWigs_OnBossEngageMidEncounter", "OnEngage")
		self:RegisterMessage("BigWigs_BlockBossEmotes", "BlockEmotes")
		self:RegisterMessage("BigWigs_AllowBossEmotes", "AllowEmotes")
		self:RegisterMessage("BigWigs_OnBossDisable")
		self:RegisterMessage("BigWigs_OnBossWipe", "BigWigs_OnBossDisable")
		self:RegisterMessage("BigWigs_ProfileUpdate", updateProfile)
		if self.db.global.tableNeedsCopied then
			self.db.global.tableNeedsCopied = false
			if type(loader.db.global.watchedMovies) == "table" then
				self.db.global.watchedMovies = CopyTable(loader.db.global.watchedMovies)
			end
			loader.db.global.watchedMovies = nil
		end
		updateProfile()

		-- Enable these CVars every time we load just in case some kind of disconnect/etc during the fight left it permanently disabled
		-- Additionally, notify the user if a CVar has been force enabled by BossBlock.
		checkCVar("Sound_EnableSFX", "disableSfx", L.userNotifySfx)
		checkCVar("Sound_EnableMusic", "disableMusic", L.userNotifyMusic)
		checkCVar("Sound_EnableAmbience", "disableAmbience", L.userNotifyAmbience)
		checkCVar("Sound_EnableErrorSpeech", "disableErrorSpeech", L.userNotifyErrorSpeech)

		self:RegisterEvent("CINEMATIC_START")
		self:RegisterEvent("PLAY_MOVIE")
	end
end

function plugin:OnPluginDisable()
	activatedModules = {}
	modulesBlockingEmotes = {}
	RestoreAll(self)
end

-------------------------------------------------------------------------------
-- Event Handlers
--

do
	local KillEvent, RestoreEvent
	do
		local unregisteredEvents = {}
		function KillEvent(frame, event)
			if not frame then return end
			-- The user might be running an addon that permanently unregisters one of these events.
			-- Let's check that before we go re-registering that event and screwing with that addon.
			if bbFrame.IsEventRegistered(frame, event) then
				bbFrame.UnregisterEvent(frame, event)
				unregisteredEvents[event] = frame
			end
		end
		function RestoreEvent(frame, event)
			if frame and unregisteredEvents[event] == frame then
				bbFrame.RegisterEvent(frame, event)
				unregisteredEvents[event] = nil
			end
		end
	end

	-- 3.3.5: the center screen boss emotes are shown by RaidBossEmoteFrame via the CHAT_MSG_ events
	local function KillEmotes()
		KillEvent(RaidBossEmoteFrame, "CHAT_MSG_RAID_BOSS_EMOTE")
		KillEvent(RaidBossEmoteFrame, "CHAT_MSG_RAID_BOSS_WHISPER")
	end
	local function RestoreEmotes()
		RestoreEvent(RaidBossEmoteFrame, "CHAT_MSG_RAID_BOSS_EMOTE")
		RestoreEvent(RaidBossEmoteFrame, "CHAT_MSG_RAID_BOSS_WHISPER")
	end

	local restoreObjectiveTracker = nil
	function plugin:OnEngage(_, module)
		if module:IsWorldModule() or module:IsTrashModule() or (not module:GetJournalID() and not module:GetAllowWin()) then return end
		if next(activatedModules) then
			activatedModules[module] = true
			return
		else
			for storedModule in next, modulesBlockingEmotes do
				self:AllowEmotes(nil, storedModule)
			end
			activatedModules[module] = true
		end

		if self.db.profile.blockEmotes then
			KillEmotes()
		end
		if self.db.profile.blockSpellErrors then
			KillEvent(UIErrorsFrame, "UI_ERROR_MESSAGE")
		end
		if self.db.profile.blockZoneChanges then
			KillEvent(ZoneTextFrame, "ZONE_CHANGED")
			KillEvent(ZoneTextFrame, "ZONE_CHANGED_INDOORS")
			KillEvent(ZoneTextFrame, "ZONE_CHANGED_NEW_AREA")
		end
		if self.db.profile.disableSfx then
			SetCVar("Sound_EnableSFX", "0")
		end
		if self.db.profile.disableMusic then
			SetCVar("Sound_EnableMusic", "0")
		end
		if self.db.profile.disableAmbience then
			SetCVar("Sound_EnableAmbience", "0")
		end
		if self.db.profile.disableErrorSpeech then
			SetCVar("Sound_EnableErrorSpeech", "0")
		end

		local frame = WatchFrame
		if type(frame) == "table" and type(frame.GetObjectType) == "function" then
			-- Never hide when tracking achievements
			local trackedAchievements = type(GetTrackedAchievements) == "function" and GetTrackedAchievements()
			if not restoreObjectiveTracker and self.db.profile.blockObjectiveTracker and not trackedAchievements and not bbFrame.IsProtected(frame) then
				restoreObjectiveTracker = bbFrame.GetParent(frame)
				if restoreObjectiveTracker then
					bbFrame.SetParent(frame, bbFrame) -- bbFrame is hidden, WatchFrame has an explicit strata so it keeps it
				end
			end
		end
	end

	function RestoreAll(self)
		-- blockEmotes
		RestoreEmotes()
		-- blockSpellErrors
		RestoreEvent(UIErrorsFrame, "UI_ERROR_MESSAGE")
		-- blockZoneChanges
		RestoreEvent(ZoneTextFrame, "ZONE_CHANGED")
		RestoreEvent(ZoneTextFrame, "ZONE_CHANGED_INDOORS")
		RestoreEvent(ZoneTextFrame, "ZONE_CHANGED_NEW_AREA")

		if self.db.profile.disableSfx then
			SetCVar("Sound_EnableSFX", "1")
		end
		if self.db.profile.disableMusic then
			SetCVar("Sound_EnableMusic", "1")
		end
		if self.db.profile.disableAmbience then
			SetCVar("Sound_EnableAmbience", "1")
		end
		if self.db.profile.disableErrorSpeech then
			SetCVar("Sound_EnableErrorSpeech", "1")
		end

		if restoreObjectiveTracker then
			bbFrame.SetParent(WatchFrame, restoreObjectiveTracker)
			restoreObjectiveTracker = nil
		end
	end

	function plugin:BlockEmotes(_, module)
		if self.db.profile.blockEmotes and (module:IsWorldModule() or module:IsTrashModule()) and not next(activatedModules) then
			if not next(modulesBlockingEmotes) then
				KillEmotes()
			end
			modulesBlockingEmotes[module] = true
		end
	end

	function plugin:AllowEmotes(_, module)
		if modulesBlockingEmotes[module] and (module:IsWorldModule() or module:IsTrashModule()) and not next(activatedModules) then
			modulesBlockingEmotes[module] = nil
			if not next(modulesBlockingEmotes) then
				RestoreEmotes()
			end
		end
	end
end

function plugin:BigWigs_OnBossDisable(_, module)
	if activatedModules[module] then
		activatedModules[module] = nil
		if not next(activatedModules) then
			activatedModules = {}
			RestoreAll(self)
		end
	else
		self:AllowEmotes(nil, module)
	end
end

do
	-- Movie blocking (only blocked after it has been watched once)
	local knownMovies = {
		[16] = true, -- Lich King death
	}

	function plugin:PLAY_MOVIE(_, id)
		if knownMovies[id] and self.db.profile.blockMovies then
			if self.db.global.watchedMovies[id] then
				BigWigs:Print(L.movieBlocked)
				MovieFrame:Hide()
			else
				self.db.global.watchedMovies[id] = true
			end
		end
	end
end

do
	-- Cinematic blocking (only blocked after it has been watched once)
	-- Keyed by negative area id (GetCurrentMapAreaID), boolean or function returning true when the cinematic should be blocked.
	-- XXX No known boss related in-game cinematics on 3.3.5 yet, add Sirus ones here when found.
	local cinematicZones = {
	}

	function plugin:CINEMATIC_START()
		if self.db.profile.blockMovies then
			local id = -(GetBestMapForUnit("player") or 0)
			local entry = cinematicZones[id]
			if entry and (entry == true or (type(entry) == "function" and entry())) then
				if self.db.global.watchedMovies[id] then
					BigWigs:Print(L.movieBlocked)
					StopCinematic()
				else
					self.db.global.watchedMovies[id] = true
				end
			end
		end
	end
end
