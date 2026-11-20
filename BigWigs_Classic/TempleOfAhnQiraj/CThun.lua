--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-AQ40/CThun.lua), won on the death of C'Thun.
-- Not ported: the stomach info frame, the speed clear check.

local mod, CL = BigWigs:NewBoss("C'Thun", 531, 1551)
if not mod then return end
mod:RegisterEnableMob(15589, 15727) -- Eye of C'Thun, C'Thun
mod:SetEncounterID(717)
mod:SetWinMobs(15727)
mod:SetEmulationWipeDelay(25) -- DBM: SetWipeTime(25)

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	weakened_trigger = "weaken",

	eye_tentacle = "Eye Tentacle",
	eye_tentacle_desc = "Show warning and timer for next Eye Tentacle",
	eye_tentacle_icon = 126,
	claw_tentacle = "Claw Tentacle",
	claw_tentacle_desc = "Show warning and timer for next Claw Tentacle",
	claw_tentacle_icon = 26391,
	giant_eye_tentacle = "Giant Eye Tentacle",
	giant_eye_tentacle_desc = "Show warning and timer for next Giant Eye Tentacle",
	giant_eye_tentacle_icon = 126,
	giant_claw_tentacle = "Giant Claw Tentacle",
	giant_claw_tentacle_desc = "Show warning and timer for next Giant Claw Tentacle",
	giant_claw_tentacle_icon = 26391,
	weakened = "C'Thun Weaken!",
	weakened_desc = "Show special warning when boss weaken, show timer for boss weaken duration",
	weakened_icon = 28598,
	weakened_bar = "Weaken ends",
})

--------------------------------------------------------------------------------
-- Initialization
--

local eyeBeamMarker = mod:AddMarkerOption(true, "player", 1, 26134, 1)
function mod:GetOptions()
	return {
		"stages",
		26029, -- Dark Glare
		{26134, "SAY"}, -- Eye Beam
		eyeBeamMarker,
		"eye_tentacle",
		"claw_tentacle",
		"giant_eye_tentacle",
		"giant_claw_tentacle",
		"weakened",
		"proximity",
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "EyeBeam", 26134)
	self:Log("SPELL_CAST_SUCCESS", "Birth", 26586)
	self:Death("EyeDeath", 15589)
	self:RegisterEvent("CHAT_MSG_MONSTER_EMOTE")
end

function mod:OnEngage()
	self:SetStage(1)
	self:Bar("claw_tentacle", 9, L.claw_tentacle, L.claw_tentacle_icon)
	self:Bar("eye_tentacle", 45, L.eye_tentacle, L.eye_tentacle_icon)
	self:Bar(26029, 46)
	self.glareTimer = self:ScheduleTimer("DarkGlare", 46)
	self:OpenProximity("proximity", 10)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:DarkGlare()
	if not UnitIsDeadOrGhost("player") then
		self:Message(26029, "red")
		self:PlaySound(26029, "warning") -- DBM: laser, run
	end
	self:Bar(26029, 39, CL.other:format(self:SpellName(26029), CL.active))
	self:Bar(26029, 86)
	self.glareTimer = self:ScheduleTimer("DarkGlare", 86)
end

do
	local function eyeBeamTarget(self, name, guid)
		self:CustomIcon(eyeBeamMarker, name, 1)
		self:ScheduleTimer("CustomIcon", 3, eyeBeamMarker, name)
		if self:Me(guid) then
			self:PersonalMessage(26134)
			self:PlaySound(26134, "warning")
			self:Say(26134)
		end
	end
	function mod:EyeBeam(args)
		if self:Hostile(args.sourceFlags) then
			self:GetUnitTarget(eyeBeamTarget, 0.1, args.sourceGUID) -- DBM: BossTargetScanner
		end
	end
end

do
	local prev = {}
	local tentacles = {
		[15726] = "eye_tentacle", -- Eye Tentacle
		[15725] = "claw_tentacle", -- Claw Tentacle
		[15334] = "giant_eye_tentacle", -- Giant Eye Tentacle
		[15728] = "giant_claw_tentacle", -- Giant Claw Tentacle
	}
	function mod:Birth(args)
		local mobId = self:MobId(args.sourceGUID)
		local key = tentacles[mobId]
		if not key or args.time - (prev[mobId] or 0) <= 5 then return end
		prev[mobId] = args.time
		local length = key == "eye_tentacle" and (self:GetStage() == 2 and 30 or 45) or key == "claw_tentacle" and 8 or 60
		if key ~= "claw_tentacle" then -- DBM: the Claw Tentacle warning is off by default
			self:Message(key, key:find("giant", nil, true) and "orange" or "yellow", L[key], L[key .. "_icon"])
		end
		self:Bar(key, length, L[key], L[key .. "_icon"])
	end
end

function mod:EyeDeath()
	if not self:IsEngaged() then return end
	self:SetStage(2)
	self:Message("stages", "cyan", CL.stage:format(2), false)
	self:PlaySound("stages", "long")
	self:CancelTimer(self.glareTimer)
	self:StopBar(26029)
	self:StopBar(CL.other:format(self:SpellName(26029), CL.active))
	self:StopBar(L.claw_tentacle) -- DBM: the Claw Tentacle never respawns in stage 2
	self:Bar("eye_tentacle", 40.5, L.eye_tentacle, L.eye_tentacle_icon)
	self:Bar("giant_claw_tentacle", 10.5, L.giant_claw_tentacle, L.giant_claw_tentacle_icon)
	self:Bar("giant_eye_tentacle", 41.3, L.giant_eye_tentacle, L.giant_eye_tentacle_icon)
end

function mod:CHAT_MSG_MONSTER_EMOTE(_, msg)
	if msg:find(L.weakened_trigger, nil, true) and self:IsEngaged() then
		self:Message("weakened", "green", L.weakened, L.weakened_icon)
		self:PlaySound("weakened", "long") -- DBM: change target
		self:Bar("weakened", 45, L.weakened_bar, L.weakened_icon)
		self:Bar("eye_tentacle", 83, L.eye_tentacle, L.eye_tentacle_icon) -- DBM: 53+30
		self:Bar("giant_claw_tentacle", 53, L.giant_claw_tentacle, L.giant_claw_tentacle_icon)
		self:Bar("giant_eye_tentacle", 83.7, L.giant_eye_tentacle, L.giant_eye_tentacle_icon)
	end
end
