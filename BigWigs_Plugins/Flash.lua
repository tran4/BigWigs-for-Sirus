--------------------------------------------------------------------------------
-- Module Declaration
--

local mod = BigWigs:NewPlugin("Flash")
if not mod then return end

--------------------------------------------------------------------------------
-- Locals
--

local flashFrame, pulseFrame
local flasher, pulser

-------------------------------------------------------------------------------
-- Initialization
--

do
	-- 3.3.5: animate frames (not textures) and use relative alpha changes (SetChange)
	flashFrame = CreateFrame("Frame", nil, UIParent)
	flashFrame:SetAllPoints(UIParent)
	flashFrame:SetFrameStrata("BACKGROUND")
	flashFrame:SetAlpha(0)
	local flashTexture = flashFrame:CreateTexture(nil, "BACKGROUND")
	flashTexture:SetAllPoints(flashFrame)
	flashTexture:SetTexture(0, 0, 1, 0.6)
	flashFrame:Hide()

	flasher = flashFrame:CreateAnimationGroup()
	flasher:SetScript("OnFinished", function() flashFrame:Hide() end)

	local fade1 = flasher:CreateAnimation("Alpha")
	fade1:SetDuration(0.2)
	fade1:SetChange(1)
	fade1:SetOrder(1)
	local fade2 = flasher:CreateAnimation("Alpha")
	fade2:SetDuration(0.2)
	fade2:SetChange(-1)
	fade2:SetOrder(2)
	local fade3 = flasher:CreateAnimation("Alpha")
	fade3:SetDuration(0.2)
	fade3:SetChange(1)
	fade3:SetOrder(3)
	local fade4 = flasher:CreateAnimation("Alpha")
	fade4:SetDuration(0.2)
	fade4:SetChange(-1)
	fade4:SetOrder(4)

	pulseFrame = CreateFrame("Frame", nil, UIParent)
	pulseFrame:SetPoint("CENTER", UIParent, "CENTER")
	pulseFrame:SetSize(100,100)
	pulseFrame:SetAlpha(0.5)
	local pulseTexture = pulseFrame:CreateTexture(nil, "ARTWORK")
	pulseTexture:SetAllPoints(pulseFrame)
	pulseTexture:SetTexture("Interface\\Icons\\Ability_Warrior_Charge")
	pulseTexture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	pulseFrame.texture = pulseTexture
	pulseFrame:Hide()

	pulser = pulseFrame:CreateAnimationGroup()
	pulser:SetScript("OnFinished", function() pulseFrame:Hide() end)

	local pulse1 = pulser:CreateAnimation("Scale")
	pulse1:SetDuration(0.25)
	pulse1:SetScale(2.5,2.5)
	pulse1:SetOrder(1)
	pulse1:SetEndDelay(0.4)
	local pulse2 = pulser:CreateAnimation("Scale")
	pulse2:SetDuration(0.25)
	pulse2:SetScale(0.2,0.2)
	pulse2:SetOrder(2)
end

function mod:OnPluginEnable()
	if not BigWigsLoader.isModern then
		self:RegisterMessage("BigWigs_Flash")
		self:RegisterMessage("BigWigs_Pulse")
	end
end

-------------------------------------------------------------------------------
-- Event Handlers
--

function mod:BigWigs_Flash()
	flasher:Stop()
	flashFrame:SetAlpha(0)
	flashFrame:Show()
	flasher:Play()
end

function mod:BigWigs_Pulse(_, _, _, icon)
	pulser:Stop()
	pulseFrame.texture:SetTexture(BigWigsLoader.Compat.File(icon or "Interface\\Icons\\INV_Misc_QuestionMark"))
	pulseFrame:Show()
	pulser:Play()
end

