--[[
	Visit: https://github.com/BigWigsMods/BigWigs/wiki/Custom-Bar-Styles
	for in-depth information on how to register new bar styles from 3rd party addons.
]]

do
	local L = BigWigsAPI:GetLocale("BigWigs")
	BigWigsAPI:RegisterBarStyle("Default", {
		apiVersion = 1,
		version = 1,
		--barSpacing = 1,
		--barHeight = 16,
		--fontSizeNormal = 10,
		--fontSizeEmphasized = 13,
		--fontOutline = "NONE",
		spellIndicatorsOffset = 2,
		--GetSpacing = function(bar) end,
		--ApplyStyle = function(bar) end,
		--BarStopped = function(bar) end,
		GetStyleName = function()
			return L.bigWigsBarStyleName_Default
		end,
	})
end

-- XXX The "Blizzard" (Cooldown Manager) style uses atlases and mask textures, which do not exist on 3.3.5

do
	-- !Beautycase styling, based on !Beatycase by Neal "Neave" @ WowI, texture made by Game92 "Aftermathh" @ WowI

	local textureNormal = "Interface\\AddOns\\BigWigs\\Media\\Textures\\beautycase"

	local backdropbc = {
		bgFile = "Interface\\Buttons\\WHITE8x8",
		insets = {top = 1, left = 1, bottom = 1, right = 1},
	}

	local function createBorder(self)
		local border = UIParent:CreateTexture(nil, "OVERLAY")
		border:SetParent(self)
		border:SetTexture(textureNormal)
		border:SetWidth(12)
		border:SetHeight(12)
		border:SetVertexColor(1, 1, 1)
		return border
	end

	local freeBorderSets = {}

	local function freeStyle(bar)
		bar.candyBarBackdrop:Hide()
		local borders = bar:Get("bigwigs:beautycase:borders")
		if borders then
			for i = 1, #borders do
				local border = borders[i]
				border:SetParent(UIParent)
				border:Hide()
			end
			freeBorderSets[#freeBorderSets + 1] = borders
		end
	end

	local function styleBar(bar)
		local bd = bar.candyBarBackdrop
		bd:ClearAllPoints()
		bd:SetBackdrop(backdropbc)
		bd:SetBackdropColor(.1, .1, .1, 1)
		bd:SetPoint("TOPLEFT", bar, "TOPLEFT", -1, 1)
		bd:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 1, -1)
		bd:Show()

		local borders
		if #freeBorderSets > 0 then
			borders = tremove(freeBorderSets)
			for i = 1, #borders do
				local border = borders[i]
				border:SetParent(bar.candyBarBar)
				border:ClearAllPoints()
				border:Show()
			end
		else
			borders = {}
			for i = 1, 8 do
				borders[i] = createBorder(bar.candyBarBar)
			end
		end
		for i = 1, #borders do
			local border = borders[i]
			if i == 1 then
				border:SetTexCoord(0, 1/3, 0, 1/3)
				border:SetPoint("TOPLEFT", bar, "TOPLEFT", -4, 4)
			elseif i == 2 then
				border:SetTexCoord(2/3, 1, 0, 1/3)
				border:SetPoint("TOPRIGHT", bar, "TOPRIGHT", 4, 4)
			elseif i == 3 then
				border:SetTexCoord(0, 1/3, 2/3, 1)
				border:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", -4, -3)
			elseif i == 4 then
				border:SetTexCoord(2/3, 1, 2/3, 1)
				border:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 4, -3)
			elseif i == 5 then
				border:SetTexCoord(1/3, 2/3, 0, 1/3)
				border:SetPoint("TOPLEFT", borders[1], "TOPRIGHT")
				border:SetPoint("TOPRIGHT", borders[2], "TOPLEFT")
			elseif i == 6 then
				border:SetTexCoord(1/3, 2/3, 2/3, 1)
				border:SetPoint("BOTTOMLEFT", borders[3], "BOTTOMRIGHT")
				border:SetPoint("BOTTOMRIGHT", borders[4], "BOTTOMLEFT")
			elseif i == 7 then
				border:SetTexCoord(0, 1/3, 1/3, 2/3)
				border:SetPoint("TOPLEFT", borders[1], "BOTTOMLEFT")
				border:SetPoint("BOTTOMLEFT", borders[3], "TOPLEFT")
			elseif i == 8 then
				border:SetTexCoord(2/3, 1, 1/3, 2/3)
				border:SetPoint("TOPRIGHT", borders[2], "BOTTOMRIGHT")
				border:SetPoint("BOTTOMRIGHT", borders[4], "TOPRIGHT")
			end
		end

		bar:Set("bigwigs:beautycase:borders", borders)
	end

	BigWigsAPI:RegisterBarStyle("BeautyCase", {
		apiVersion = 1,
		version = 10,
		barSpacing = 8,
		spellIndicatorsOffset = 6,
		ApplyStyle = styleBar,
		BarStopped = freeStyle,
		GetStyleName = function() return "!Beautycase" end,
	})
end

do
	-- MonoUI
	local backdropBorder = {
		bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
		edgeFile = "Interface\\ChatFrame\\ChatFrameBackground",
		tile = false, tileSize = 0, edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	}

	local function removeStyle(bar)
		bar.candyBarBackdrop:Hide()
		bar.candyBarIconFrameBackdrop:Hide()
		local height = bar:Get("bigwigs:restoreheight")
		if height then
			bar:SetHeight(height) -- Note, calling SetHeight resets all the points for the statusbar and the icon, so we don't need to do it
		end

		local statusbar = bar.candyBarBar
		local duration = bar.candyBarDuration
		duration:ClearAllPoints()
		duration:SetPoint("TOPLEFT", statusbar, "TOPLEFT", 2, 0)
		duration:SetPoint("BOTTOMRIGHT", statusbar, "BOTTOMRIGHT", -2, 0)

		local label = bar.candyBarLabel
		label:ClearAllPoints()
		label:SetPoint("TOPLEFT", statusbar, "TOPLEFT", 2, 0)
		label:SetPoint("BOTTOMRIGHT", statusbar, "BOTTOMRIGHT", -2, 0)
	end

	local function styleBar(bar)
		local barHeight = bar:GetHeight()

		bar:Set("bigwigs:restoreheight", barHeight)
		bar:SetHeight(barHeight / 2)

		bar.candyBarLabel:ClearAllPoints()
		bar.candyBarDuration:ClearAllPoints()
		local statusbar = bar.candyBarBar
		statusbar:ClearAllPoints()

		local bd = bar.candyBarBackdrop
		if bd.SetToDefaults then
			bd:SetToDefaults()
			bd:SetFrameLevel(0)
		end
		bd:ClearAllPoints()
		bd:SetBackdrop(backdropBorder)
		bd:SetBackdropColor(.1,.1,.1,1)
		bd:SetBackdropBorderColor(0,0,0,1)
		bd:SetPoint("TOPLEFT", statusbar, "TOPLEFT", -2, 2)
		bd:SetPoint("BOTTOMRIGHT", statusbar, "BOTTOMRIGHT", 2, -2)
		bd:Show()

		local reApplyIcon
		local iconFrame = bar.candyBarIconFrame
		local iconBd = bar.candyBarIconFrameBackdrop

		iconFrame:ClearAllPoints()
		iconBd:ClearAllPoints()

		if bar:GetIconPosition() == "RIGHT" then
			iconFrame:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", -2, 0)

			statusbar:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", 2, 0)
			if bar:IsIconVisible() then
				statusbar:SetPoint("TOPRIGHT", iconFrame, "LEFT", -6, 0)
			else
				statusbar:SetPoint("TOPRIGHT", iconFrame, "RIGHT", 0, 0)
			end
		else
			iconFrame:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", 2, 0)

			statusbar:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", -2, 0)
			if bar:IsIconVisible() then
				statusbar:SetPoint("TOPLEFT", iconFrame, "RIGHT", 6, 0)
			else
				statusbar:SetPoint("TOPLEFT", iconFrame, "LEFT", 0, 0)
			end
		end
		iconFrame:SetSize(barHeight, barHeight)

		iconBd:SetBackdrop(backdropBorder)
		iconBd:SetBackdropColor(.1,.1,.1,1)
		iconBd:SetBackdropBorderColor(0,0,0,1)
		iconBd:SetPoint("TOPLEFT", iconFrame, "TOPLEFT", -2, 2)
		iconBd:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", 2, -2)
		if bar:IsIconVisible() then
			iconBd:Show()
		end

		if reApplyIcon then
			iconFrame:SetTexture(reApplyIcon)
			iconFrame:SetTexCoord(0.07, 0.93, 0.07, 0.93)
		end

		bar.candyBarLabel:SetPoint("BOTTOMLEFT", statusbar, "TOPLEFT", 2, 2)
		bar.candyBarDuration:SetPoint("BOTTOMRIGHT", statusbar, "TOPRIGHT", -2, 2)
	end

	BigWigsAPI:RegisterBarStyle("MonoUI", {
		apiVersion = 1,
		version = 10,
		barHeight = 20,
		fontSizeNormal = 10,
		fontSizeEmphasized = 11,
		spellIndicatorsOffset = 2,
		GetSpacing = function(bar) return bar:GetHeight()+6 end,
		ApplyStyle = styleBar,
		BarStopped = removeStyle,
		GetStyleName = function() return "MonoUI" end,
	})
end

do
	-- NaowhUI
	local backdropBorder = {
		edgeFile = "Interface\\Buttons\\WHITE8X8",
		edgeSize = 1,
	}

	local function removeStyle(bar)
		bar.candyBarBackdrop:Hide()
		bar.candyBarIconFrameBackdrop:Hide()
		local height = bar:Get("bigwigs:restoreheight")
		if height then
			bar:SetHeight(height) -- Note, calling SetHeight resets all the points for the statusbar and the icon, so we don't need to do it
		end

		local statusbar = bar.candyBarBar
		local duration = bar.candyBarDuration
		duration:ClearAllPoints()
		duration:SetPoint("TOPLEFT", statusbar, "TOPLEFT", 2, 0)
		duration:SetPoint("BOTTOMRIGHT", statusbar, "BOTTOMRIGHT", -2, 0)

		local label = bar.candyBarLabel
		label:ClearAllPoints()
		label:SetPoint("TOPLEFT", statusbar, "TOPLEFT", 2, 0)
		label:SetPoint("BOTTOMRIGHT", statusbar, "BOTTOMRIGHT", -2, 0)
	end

	local function styleBar(bar)
		local barHeight = bar:GetHeight()

		bar:Set("bigwigs:restoreheight", barHeight)
		bar:SetHeight(barHeight / 2)

		bar.candyBarLabel:ClearAllPoints()
		bar.candyBarDuration:ClearAllPoints()
		local statusbar = bar.candyBarBar
		statusbar:ClearAllPoints()

		local bd = bar.candyBarBackdrop
		if bd.SetToDefaults then
			bd:SetToDefaults()
			bd:SetFrameLevel(0)
		end
		bd:ClearAllPoints()
		bd:SetBackdrop(backdropBorder)
		bd:SetBackdropColor(.1,.1,.1,1)
		bd:SetBackdropBorderColor(0,0,0,1)
		bd:SetPoint("TOPLEFT", statusbar, "TOPLEFT", -1, 1)
		bd:SetPoint("BOTTOMRIGHT", statusbar, "BOTTOMRIGHT", 1, -1)
		bd:Show()

		local reApplyIcon
		local iconFrame = bar.candyBarIconFrame
		local iconBd = bar.candyBarIconFrameBackdrop

		iconFrame:ClearAllPoints()
		iconBd:ClearAllPoints()

		if bar:GetIconPosition() == "RIGHT" then
			iconFrame:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", -2, 0)

			statusbar:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", 2, 0)
			if bar:IsIconVisible() then
				statusbar:SetPoint("TOPRIGHT", iconFrame, "LEFT", -4, -2)
			else
				statusbar:SetPoint("TOPRIGHT", iconFrame, "RIGHT", 0, -2)
			end
		else
			iconFrame:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", 2, 0)

			statusbar:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", -2, 0)
			if bar:IsIconVisible() then
				statusbar:SetPoint("TOPLEFT", iconFrame, "RIGHT", 4, -2)
			else
				statusbar:SetPoint("TOPLEFT", iconFrame, "LEFT", 0, -2)
			end
		end
		iconFrame:SetSize(barHeight, barHeight)

		iconBd:SetBackdrop(backdropBorder)
		iconBd:SetBackdropColor(.1,.1,.1,1)
		iconBd:SetBackdropBorderColor(0,0,0,1)
		iconBd:SetPoint("TOPLEFT", iconFrame, "TOPLEFT", -1, 1)
		iconBd:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", 1, -1)
		if bar:IsIconVisible() then
			iconBd:Show()
		end

		if reApplyIcon then
			iconFrame:SetTexture(reApplyIcon)
			iconFrame:SetTexCoord(0.07, 0.93, 0.07, 0.93)
		end

		bar.candyBarLabel:SetPoint("BOTTOMLEFT", statusbar, "TOPLEFT", 2, -7)
		bar.candyBarDuration:SetPoint("BOTTOMRIGHT", statusbar, "TOPRIGHT", -2, -7)
	end

	BigWigsAPI:RegisterBarStyle("NaowhUI", {
		apiVersion = 1,
		version = 10,
		barHeight = 20,
		texture = "NaowhGradient",
		fontName = "Naowh",
		fontSizeNormal = 14,
		fontSizeEmphasized = 14,
		spellIndicatorsOffset = 2,
		spellIndicatorsPosition = "RIGHT",
		fontOutline = "OUTLINE",
		iconPosition = "RIGHT",
		GetSpacing = function(bar) return bar:GetHeight()+4 end,
		ApplyStyle = styleBar,
		BarStopped = removeStyle,
		GetStyleName = function() return "NaowhUI" end,
	})
end

do
	-- Tukui
	local C = Tukui and Tukui[2]
	local backdrop = {
		bgFile = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\Buttons\\WHITE8X8",
		tile = false, tileSize = 0, edgeSize = 1,
	}
	local borderBackdrop = {
		edgeFile = "Interface\\Buttons\\WHITE8X8",
		edgeSize = 1,
		insets = { left = 1, right = 1, top = 1, bottom = 1 }
	}

	local function removeStyle(bar)
		local bd = bar.candyBarBackdrop
		bd:Hide()
		if bd.tukiborder then
			bd.tukiborder:Hide()
			bd.tukoborder:Hide()
		end
	end

	local function styleBar(bar)
		local bd = bar.candyBarBackdrop
		bd:ClearAllPoints()
		bd:SetBackdrop(backdrop)
		if C then
			bd:SetBackdropColor(unpack(C.Medias.BackdropColor))
			bd:SetBackdropBorderColor(unpack(C.Medias.BorderColor))
			bd:SetOutside(bar)
		else
			bd:SetBackdropColor(0.1,0.1,0.1)
			bd:SetBackdropBorderColor(0.5,0.5,0.5)
			bd:ClearAllPoints()
			bd:SetPoint("TOPLEFT", bar, "TOPLEFT", -2, 2)
			bd:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 2, -2)
		end

		if not bd.tukiborder then
			local border = CreateFrame("Frame", nil, bd)
			if C then
				border:SetInside(bd, 1, 1)
			else
				border:SetPoint("TOPLEFT", bd, "TOPLEFT", 1, -1)
				border:SetPoint("BOTTOMRIGHT", bd, "BOTTOMRIGHT", -1, 1)
			end
			border:SetBackdrop(borderBackdrop)
			border:SetBackdropBorderColor(0, 0, 0)
			bd.tukiborder = border
		else
			bd.tukiborder:Show()
		end

		if not bd.tukoborder then
			local border = CreateFrame("Frame", nil, bd)
			if C then
				border:SetOutside(bd, 1, 1)
			else
				border:SetPoint("TOPLEFT", bd, "TOPLEFT", -1, 1)
				border:SetPoint("BOTTOMRIGHT", bd, "BOTTOMRIGHT", 1, -1)
			end
			border:SetBackdrop(borderBackdrop)
			border:SetBackdropBorderColor(0, 0, 0)
			bd.tukoborder = border
		else
			bd.tukoborder:Show()
		end

		bd:Show()
	end

	BigWigsAPI:RegisterBarStyle("TukUI", {
		apiVersion = 1,
		version = 10,
		barSpacing = 7,
		spellIndicatorsOffset = 4,
		ApplyStyle = styleBar,
		BarStopped = removeStyle,
		GetStyleName = function() return "TukUI" end,
	})
end

do
	-- ElvUI
	local E = ElvUI and ElvUI[1]
	local backdropBorder = {
		bgFile = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\Buttons\\WHITE8X8",
		tile = false, tileSize = 0, edgeSize = 1,
		insets = {left = 0, right = 0, top = 0, bottom = 0}
	}

	local function removeStyle(bar)
		local bd = bar.candyBarBackdrop
		bd:Hide()
		if bd.iborder then
			bd.iborder:Hide()
			bd.oborder:Hide()
		end

		local iconBd = bar.candyBarIconFrameBackdrop
		iconBd:Hide()
		if iconBd.iborder then
			iconBd.iborder:Hide()
			iconBd.oborder:Hide()
		end
	end

	local function styleBar(bar)
		local bd = bar.candyBarBackdrop
		bd:ClearAllPoints()
		if E then
			bd:SetTemplate("Transparent")
			bd:SetOutside(bar)
			if not E.PixelMode and bd.iborder then
				bd.iborder:Show()
				bd.oborder:Show()
			end
		else
			bd:SetBackdrop(backdropBorder)
			bd:SetBackdropColor(0.06, 0.06, 0.06, 0.8)
			bd:SetBackdropBorderColor(0, 0, 0)
			bd:SetPoint("TOPLEFT", bar, "TOPLEFT", -1, 1)
			bd:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 1, -1)
		end
		bd:Show()

		local reApplyIcon
		local statusbar = bar.candyBarBar
		local iconFrame = bar.candyBarIconFrame
		local iconBd = bar.candyBarIconFrameBackdrop
		statusbar:ClearAllPoints()
		iconFrame:ClearAllPoints()
		iconBd:ClearAllPoints()

		if bar:GetIconPosition() == "RIGHT" then
			--iconFrame:SetPoint("BOTTOMLEFT", bar, "BOTTOMRIGHT", E and (E.PixelMode and 1 or 5) or 1, 0)
			iconFrame:SetPoint("TOPRIGHT", bar, "TOPRIGHT", 0, 0)
			iconFrame:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, 0)

			statusbar:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", 0, 0)
			if bar:IsIconVisible() then
				statusbar:SetPoint("TOPRIGHT", iconFrame, "TOPLEFT", -1, 0)
			else
				statusbar:SetPoint("TOPRIGHT", bar, "TOPRIGHT", 0, 0)
			end
		else
			--iconFrame:SetPoint("BOTTOMRIGHT", bar, "BOTTOMLEFT", E and (E.PixelMode and -1 or -5) or -1, 0)
			iconFrame:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
			iconFrame:SetPoint("BOTTOMLEFT", bar, "BOTTOMLEFT", 0, 0)

			statusbar:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, 0)
			if bar:IsIconVisible() then
				statusbar:SetPoint("TOPLEFT", iconFrame, "TOPRIGHT", 1, 0)
			else
				statusbar:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, 0)
			end
		end
		iconFrame:SetSize(bar:GetHeight(), bar:GetHeight())

		if E then
			iconBd:SetTemplate("Transparent")
			iconBd:SetOutside(iconFrame)
			if not E.PixelMode and iconBd.iborder then
				iconBd.iborder:Show()
				iconBd.oborder:Show()
			end
		else
			iconBd:SetBackdrop(backdropBorder)
			iconBd:SetBackdropColor(0.06, 0.06, 0.06, 0.8)
			iconBd:SetBackdropBorderColor(0, 0, 0)
			iconBd:SetPoint("TOPLEFT", iconFrame, "TOPLEFT", -1, 1)
			iconBd:SetPoint("BOTTOMRIGHT", iconFrame, "BOTTOMRIGHT", 1, -1)
		end
		if bar:IsIconVisible() then
			iconBd:Show()
		end

		if reApplyIcon then
			iconFrame:SetTexture(reApplyIcon)
			iconFrame:SetTexCoord(0.07, 0.93, 0.07, 0.93)
		end
	end

	BigWigsAPI:RegisterBarStyle("ElvUI", {
		apiVersion = 1,
		version = 10,
		barSpacing = E and (E.PixelMode and 4 or 8) or 4,
		barHeight = 20,
		spellIndicatorsOffset = 2,
		ApplyStyle = styleBar,
		BarStopped = removeStyle,
		GetStyleName = function() return "ElvUI" end,
	})
end

