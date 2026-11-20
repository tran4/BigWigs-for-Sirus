local L, BigWigsLoader, BigWigsAPI
do
	local _, tbl = ...
	BigWigsAPI = tbl.API
	L = BigWigsAPI:GetLocale("BigWigs")
	BigWigsLoader = tbl.loaderPublic
end

--------------------------------------------------------------------------------
-- Locals
--

local ProfileUtils = {}

--------------------------------------------------------------------------------
-- Saved Settings
--

local db
do
	local globalDefaults = {
		wordsFriendly = {},
		wordsOther = {},
	}

	local _, tbl = ...
	tbl.OnDatabaseReady(function() -- 3.3.5: saved variables aren't available until ADDON_LOADED
		db = BigWigsLoader.db:RegisterNamespace("AutoInvite", {global = globalDefaults})
	end)

	ProfileUtils.ValidateMainSettings = function()
		for k, v in next, db do
			local defaultType = type(globalDefaults[k])
			if defaultType == "nil" then
				db.global[k] = nil
			elseif type(v) ~= defaultType then
				db.global[k] = globalDefaults[k]
			end

			for entry, word in next, db.global.wordsFriendly do
				if type(entry) ~= "number" or type(word) ~= "string" or word ~= word:lower() or word == "" or word:find("^ +$") then
					db.global.wordsFriendly = {}
					break
				end
			end
			for entry, word in next, db.global.wordsOther do
				if type(entry) ~= "number" or type(word) ~= "string" or word ~= word:lower() or word == "" or word:find("^ +$") then
					db.global.wordsOther = {}
					break
				end
			end
		end
	end
end

--------------------------------------------------------------------------------
-- Widgets & Events
--

local popupFrame = CreateFrame("Frame", nil, UIParent)
do
	local Compat = BigWigsLoader.Compat
	local IsInGroup, IsInRaid = Compat.IsInGroup, Compat.IsInRaid
	local UnitIsGroupLeader, UnitIsGroupAssistant = Compat.UnitIsGroupLeader, Compat.UnitIsGroupAssistant
	local delayedInvite = {}
	local invitesBlocked = false
	local SendChatMessage = BigWigsLoader.SendChatMessage

	-- 3.3.5: no GUID based helpers, work with names
	local function IsInMyGroup(name)
		return UnitInParty(name) or UnitInRaid(name)
	end
	local function IsFriendOrGuildMember(name)
		for i = 1, GetNumFriends() do
			if GetFriendInfo(i) == name then
				return true
			end
		end
		if IsInGuild() then
			for i = 1, GetNumGuildMembers(true) do
				local guildName = GetGuildRosterInfo(i)
				if guildName == name then
					return true
				end
			end
		end
		return false
	end
	local function IsPartyFull()
		if IsInRaid() then
			return GetNumRaidMembers() >= 40
		end
		return GetNumPartyMembers() >= 4
	end

	do
		local throttle = {}
		local myName = UnitName("player")
		popupFrame:SetScript("OnEvent", function(self, event, message, sender, _, _, _, flag)
			if event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE" then
				if not IsInGroup() then
					invitesBlocked = false
					throttle = {}
					delayedInvite = {}
				end
			elseif event == "CHAT_MSG_WHISPER" then
				if IsInGroup() and not UnitIsGroupLeader("player") and not UnitIsGroupAssistant("player") then
					return -- We don't have invite permission
				end
				sender = Compat.Ambiguate(sender)
				if flag == "GM" or flag == "DEV" or sender == myName or IsInMyGroup(sender) then
					return -- Player is GM/DEV or already in our group, return
				elseif not throttle[sender] or GetTime() > throttle[sender] then
					message = message:lower()
					local dbToUse
					if IsFriendOrGuildMember(sender) then
						dbToUse = db.global.wordsFriendly
					else
						dbToUse = db.global.wordsOther
					end
					for i = 1, #dbToUse do
						if dbToUse[i] == message then
							if IsInRaid() then
								if IsPartyFull() then
									throttle[sender] = GetTime() + 10
									SendChatMessage(L.whisperToPlayerMyGroupIsFull, "WHISPER", nil, sender)
								else
									throttle[sender] = GetTime() + 2
									BigWigsLoader.Print(L.keywordDetectedInvitingPlayer:format(sender))
									InviteUnit(sender)
								end
							else
								if IsPartyFull() then
									if not invitesBlocked then
										if not next(delayedInvite) then
											popupFrame:Show()
										end
										delayedInvite[sender] = true
										throttle[sender] = GetTime() + 2
									else
										throttle[sender] = GetTime() + 5
										SendChatMessage(L.whisperToPlayerMyGroupIsFull, "WHISPER", nil, sender)
									end
								else
									throttle[sender] = GetTime() + 2
									BigWigsLoader.Print(L.keywordDetectedInvitingPlayer:format(sender))
									InviteUnit(sender)
								end
							end
						end
					end
				end
			end
		end)
	end

	popupFrame:SetFrameStrata("DIALOG")
	popupFrame:SetFrameLevel(100)
	popupFrame:SetSize(400, 110)
	popupFrame:SetPoint("CENTER")
	popupFrame:SetBackdrop({ -- 3.3.5: no DialogBorderOpaqueTemplate
		bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
		edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
		tile = true, tileSize = 32, edgeSize = 32,
		insets = {left = 11, right = 12, top = 12, bottom = 11},
	})
	popupFrame:SetBackdropColor(0, 0, 0, 1)

	local text = popupFrame:CreateFontString(nil, nil, "GameFontGreenLarge")
	text:SetSize(380, 0)
	text:SetJustifyH("CENTER")
	text:SetJustifyV("TOP")
	text:SetNonSpaceWrap(true)
	text:SetText(L.groupIsFullConvertToRaid)
	text:SetPoint("TOP", 0, -16)

	local buttonYes = CreateFrame("Button", nil, popupFrame, "UIPanelButtonTemplate")
	buttonYes:SetSize(128, 32)
	buttonYes:SetPoint("RIGHT", popupFrame, "BOTTOM", -6, 28)
	buttonYes:SetScript("OnClick", function(self)
		self:GetParent():Hide()
		invitesBlocked = false
		ConvertToRaid()
		BigWigsLoader.CTimerAfter(1.5, function() -- Hopefully long enough for the game to recognize you are now in a raid, before trying to invite others
			local timer = nil
			timer = BigWigsLoader.CTimerNewTicker(0.2, function() -- Throttle
				local playerName = next(delayedInvite)
				if not playerName then
					timer:Cancel()
					timer = nil
					delayedInvite = {}
					return
				end

				delayedInvite[playerName] = nil
				BigWigsLoader.Print(L.keywordDetectedInvitingPlayer:format(playerName))
				InviteUnit(playerName)
			end)
		end)
	end)
	buttonYes:SetText(L.yes)
	local buttonNo = CreateFrame("Button", nil, popupFrame, "UIPanelButtonTemplate")
	buttonNo:SetSize(128, 32)
	buttonNo:SetPoint("LEFT", buttonYes, "RIGHT", 12, 0)
	buttonNo:SetScript("OnClick", function(self)
		self:GetParent():Hide()
		invitesBlocked = true
		local timer = nil
		timer = BigWigsLoader.CTimerNewTicker(0.5, function() -- Throttle
			local playerName = next(delayedInvite)
			if not playerName then
				timer:Cancel()
				timer = nil
				delayedInvite = {}
				return
			end

			delayedInvite[playerName] = nil
			SendChatMessage(L.whisperToPlayerMyGroupIsFull, "WHISPER", nil, playerName)
		end)
	end)
	buttonNo:SetText(L.no)

	popupFrame:Hide()
end

--------------------------------------------------------------------------------
-- Options Table
--

local function UpdateWidgets()
	if next(db.global.wordsFriendly) or next(db.global.wordsOther) then
		popupFrame:RegisterEvent("CHAT_MSG_WHISPER")
		popupFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
		popupFrame:RegisterEvent("RAID_ROSTER_UPDATE")
	else
		popupFrame:UnregisterEvent("CHAT_MSG_WHISPER")
		popupFrame:UnregisterEvent("PARTY_MEMBERS_CHANGED")
		popupFrame:UnregisterEvent("RAID_ROSTER_UPDATE")
	end
end

BigWigsAPI.RegisterToolOptions("AutoInvite", function() return {
	type = "group",
	childGroups = "tab",
	order = 5,
	name = L.autoInviteTitle,
	args = {
		explainer = {
			type = "description",
			name = L.autoInviteDesc,
			order = 0,
			width = "full",
			fontSize = "large",
		},
		friendly = {
			name = L.guildAndFriends,
			type = "group",
			order = 1,
			args = {
				input = {
					type = "input",
					get = function() return "" end,
					set = function(_, text)
						table.insert(db.global.wordsFriendly, text)
						table.sort(db.global.wordsFriendly)
						UpdateWidgets()
					end,
					name = L.addWords,
					order = 1,
					width = "full",
					usage = L.invalidWordWarning,
					validate = function(_, text)
						local lowerCaseText = text:lower()
						if lowerCaseText ~= text or lowerCaseText == "" or lowerCaseText:find("^ +$") then
							return false
						end
						for i = 1, #db.global.wordsFriendly do
							if db.global.wordsFriendly[i] == text then
								return false
							end
						end
						return true
					end,
				},
				remove = {
					type = "select",
					name = L.removeWords,
					order = 2,
					values = function() return db.global.wordsFriendly end,
					set = function(_, value)
						table.remove(db.global.wordsFriendly, value)
						UpdateWidgets()
					end,
					width = "full",
					disabled = function() return not next(db.global.wordsFriendly) end,
				},
			},
		},
		other = {
			name = L.everyoneElse,
			type = "group",
			order = 2,
			args = {
				input = {
					type = "input",
					get = function() return "" end,
					set = function(_, text)
						table.insert(db.global.wordsOther, text)
						table.sort(db.global.wordsOther)
						UpdateWidgets()
					end,
					name = L.addWords,
					order = 1,
					width = "full",
					usage = L.invalidWordWarning,
					validate = function(_, text)
						local lowerCaseText = text:lower()
						if lowerCaseText ~= text or lowerCaseText == "" or lowerCaseText:find("^ +$") then
							return false
						end
						for i = 1, #db.global.wordsOther do
							if db.global.wordsOther[i] == text then
								return false
							end
						end
						return true
					end,
				},
				remove = {
					type = "select",
					name = L.removeWords,
					order = 2,
					values = function() return db.global.wordsOther end,
					set = function(_, value)
						table.remove(db.global.wordsOther, value)
						UpdateWidgets()
					end,
					width = "full",
					disabled = function() return not next(db.global.wordsOther) end,
				},
			},
		},
	},
} end)

--------------------------------------------------------------------------------
-- Login
--

do
	local function UpdateProfile()
		ProfileUtils.ValidateMainSettings()
		UpdateWidgets()
	end
	local loginFrame = CreateFrame("Frame")
	loginFrame:SetScript("OnEvent", function(self, event)
		self:UnregisterEvent(event)
		self:SetScript("OnEvent", nil)
		UpdateProfile()
		BigWigsLoader.RegisterMessage(loginFrame, "BigWigs_ProfileUpdate", UpdateProfile)
	end)
	loginFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
end
