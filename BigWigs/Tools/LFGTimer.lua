-- USE THIS CALLBACK TO SKIN THIS WINDOW! NO NEED FOR UGLY HAX! E.g.
-- local name, addon = ...
-- if BigWigsLoader then
-- 	BigWigsLoader.RegisterMessage(addon, "BigWigs_FrameCreated", function(event, frame, name) print(name.." frame created.") end)
-- end

local _, tbl = ...
local LoaderPublic = tbl.loaderPublic
local GetTime = GetTime

local db
do
	local defaults = {
		useMaster = true
	}
	tbl.OnDatabaseReady(function() -- 3.3.5: saved variables aren't available until ADDON_LOADED
		db = LoaderPublic.db:RegisterNamespace("LFGTimer", {profile = defaults})
		for k, v in next, db.profile do
			local defaultType = type(defaults[k])
			if defaultType == "nil" then
				db.profile[k] = nil
			elseif type(v) ~= defaultType then
				db.profile[k] = defaults[k]
			end
		end
	end)
end

-- 3.3.5: the ready popup is LFDDungeonReadyPopup
local readyPopup = LFDDungeonReadyPopup or LFGDungeonReadyPopup
local timerBar = CreateFrame("StatusBar", nil, readyPopup)
timerBar:SetPoint("TOP", readyPopup, "BOTTOM", 0, -5)

local tex = timerBar:CreateTexture()
tex:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
timerBar:SetStatusBarTexture(tex)
timerBar:SetSize(190, 9)
timerBar:SetStatusBarColor(1, 0.1, 0)
timerBar:SetMinMaxValues(0, 40)
timerBar:Show()

local bg = timerBar:CreateTexture(nil, "BACKGROUND")
bg:SetAllPoints(timerBar)
bg:SetTexture(0, 0, 0, 0.7)

local spark = timerBar:CreateTexture(nil, "OVERLAY")
spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
spark:SetSize(32, 32)
spark:SetBlendMode("ADD")
spark:SetPoint("LEFT", tex, "RIGHT", -15, 0)

local border = timerBar:CreateTexture(nil, "OVERLAY")
border:SetTexture("Interface\\CastingBar\\UI-CastingBar-Border")
border:SetSize(256, 64)
border:SetPoint("TOP", timerBar, 0, 28)

timerBar.text = timerBar:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
timerBar.text:SetPoint("CENTER", timerBar, "CENTER")

local prev
timerBar:SetScript("OnEvent", function()
	if not prev then
		LoaderPublic:SendMessage("BigWigs_FrameCreated", timerBar, "QueueTimer")
	end

	prev = GetTime() + 40
	-- Play in Master for those that have SFX off or very low.
	-- Using false as third arg to avoid the "only one of each sound at a time" throttle.
	-- Only play via the "Master" channel if we have sounds turned on
	if db.profile.useMaster then
		PlaySoundFile("Sound\\Interface\\ReadyCheck.wav") -- 3.3.5: PlaySoundFile always uses the master channel
	end

end)
timerBar:RegisterEvent("LFG_PROPOSAL_SHOW")

timerBar:SetScript("OnUpdate", function(f)
	if prev then
		local timeLeft = prev - GetTime()
		if timeLeft > 0 then
			f:SetValue(timeLeft)
			f.text:SetFormattedText("BigWigs: %.1f", timeLeft)
		end
	end
end)

local L = tbl.API:GetLocale("BigWigs")
tbl.API.RegisterToolOptions("LFGTimer", function() return {
	type = "group",
	name = L.lfgTimerTitle,
	order = 6,
	get = function(info)
		return db.profile[info[#info]]
	end,
	set = function(info, value)
		local key = info[#info]
		db.profile[key] = value
	end,
	args = {
		explainer = {
			type = "description",
			name = L.lfgTimerExplainer,
			order = 0,
			width = "full",
			fontSize = "large",
		},
		useMaster = {
			type = "toggle",
			name = L.lfgUseMaster,
			desc = L.lfgUseMasterDesc:format(L.sfx),
			order = 1,
			width = "full",
		},
	},
} end)
