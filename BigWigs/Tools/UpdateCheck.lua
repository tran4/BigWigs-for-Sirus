--------------------------------------------------------------------------------
-- 3.3.5 (Sirus): tells the player that a newer version of the Sirus port is out. An addon can't reach the internet,
-- so the versions are compared with the guild and the group: on login and on joining a group the addon sends its
-- version, the players with an older one get told once per session where to download the new one. The retail
-- version check of BigWigs can't do it: everyone has the same retail number (427).
-- PORT_VERSION goes up by one with every release pushed to GitHub (also "-sirusN" in the .toc versions).
--

local PORT_VERSION = 2
local PREFIX = "BWSirus"
local URL = "github.com/tran4/BigWigs-for-Sirus"

local warned = false
local lastReply = {} -- [sender] = time, no whisper storm
local lastGroupSend = 0

local function notify(version)
	if warned then return end
	warned = true
	local text = GetLocale() == "ruRU"
		and ("|cFF33FF99BigWigs|r: вышла новая версия порта для Sirus (|cFFFFD100%d|r, у вас %d). Скачать: |cFF33CCFF%s|r")
		or ("|cFF33FF99BigWigs|r: a new version of the Sirus port is out (|cFFFFD100%d|r, you have %d). Download: |cFF33CCFF%s|r")
	print(text:format(version, PORT_VERSION, URL))
end

local function send(channel, target)
	SendAddonMessage(PREFIX, "V^" .. PORT_VERSION, channel, target)
end

local function sendGroup()
	local now = GetTime()
	if now - lastGroupSend < 30 then return end
	if GetNumRaidMembers() > 0 then
		lastGroupSend = now
		send("RAID")
	elseif GetNumPartyMembers() > 0 then
		lastGroupSend = now
		send("PARTY")
	end
end

local frame = CreateFrame("Frame")
local loginAt
frame:SetScript("OnEvent", function(_, event, prefix, msg, channel, sender)
	if event == "CHAT_MSG_ADDON" then
		if prefix ~= PREFIX or sender == UnitName("player") then return end
		local version = tonumber((msg or ""):match("^V%^(%d+)$"))
		if not version then return end
		if version > PORT_VERSION then
			notify(version)
		elseif version < PORT_VERSION and channel ~= "WHISPER" then
			-- they have an older version: answer them alone so they get told too
			local now = GetTime()
			if not lastReply[sender] or now - lastReply[sender] > 300 then
				lastReply[sender] = now
				send("WHISPER", sender)
			end
		end
	elseif event == "PLAYER_LOGIN" then
		loginAt = GetTime() + 15 -- the guild roster isn't ready at once
	elseif event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE" then
		sendGroup()
	end
end)
frame:SetScript("OnUpdate", function()
	if loginAt and GetTime() >= loginAt then
		loginAt = nil
		if IsInGuild() then send("GUILD") end
		sendGroup()
	end
end)
frame:RegisterEvent("CHAT_MSG_ADDON")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PARTY_MEMBERS_CHANGED")
frame:RegisterEvent("RAID_ROSTER_UPDATE")
