--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("Watchkeeper Gargolmar", {543, 2849}, 527)
if not mod then return end
mod:RegisterEnableMob(
	17306, -- Watchkeeper Gargolmar
	17309 -- Hellfire Watcher
)
--mod:SetEncounterID(1893) -- no boss frames
mod:SetEncounterID(1893) -- 3.3.5: encounter emulation, there is no ENCOUNTER_START (the retail module has no boss frames to engage by)
--mod:SetRespawnTime(0) -- resets, doesn't respawn

--------------------------------------------------------------------------------
-- Initialization
--

if mod:Classic() then
	function mod:GetOptions()
		return {
			{36814, "TANK_HEALER"}, -- Mortal Wound
			34645, -- Surge (3.3.5: DBM Sirus)
			22857, -- Retaliation (3.3.5: DBM Sirus)
			12039, -- Heal
			8362, -- Renew
			14032, -- Shadow Word: Pain
		}, {
			[36814] = "general",
			[12039] = -5053, -- Hellfire Watcher
		}
	end
else -- Retail, 11.0.5 or later
	function mod:GetOptions()
		return {
			{36814, "TANK_HEALER"}, -- Mortal Wound
			12039, -- Heal
			8362, -- Renew
			11639, -- Shadow Word: Pain
		}, {
			[36814] = "general",
			[12039] = -5053, -- Hellfire Watcher
		}
	end
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "MortalWound", 36814, 30641) -- Heroic, Normal
	self:Log("SPELL_AURA_APPLIED_DOSE", "MortalWound", 36814, 30641) -- Heroic, Normal

	self:Log("SPELL_CAST_START", "Heal", 12039)
	self:Log("SPELL_CAST_START", "Renew", 8362)
	self:Log("SPELL_AURA_APPLIED", "RenewApplied", 8362)
	if self:Classic() then
		-- 14032 was removed in 11.0.5
		self:Log("SPELL_AURA_APPLIED", "ShadowWordPain", 14032)
	else -- Retail
		self:Log("SPELL_AURA_APPLIED", "ShadowWordPain", 11639)
	end

	self:Log("SPELL_CAST_SUCCESS", "Surge", 34645) -- 3.3.5: DBM Sirus
	self:Log("SPELL_CAST_SUCCESS", "Retaliation", 22857) -- 3.3.5: DBM Sirus
	self:Death("Win", 17306)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:MortalWound(args)
	self:StackMessage(36814, "purple", args.destName, args.amount, 1)
	if not self:Retail() then
		self:CDBar(36814, 10) -- 3.3.5: DBM Sirus
	end
end

function mod:Surge() -- 3.3.5: DBM Sirus
	self:CDBar(34645, 7)
end

function mod:Retaliation(args) -- 3.3.5: DBM Sirus, stop attacking in melee
	if self:Melee() then
		self:Message(22857, "red")
		self:PlaySound(22857, "warning")
		self:Bar(22857, 17, CL.other:format(args.spellName, CL.active))
	end
end

-- There are 2 Hellfire Watchers on pull, so throttling everything
do
	local prev = 0
	function mod:Heal(args)
		local t = args.time
		if t - prev > 1 then
			prev = t
			self:MessageOld(args.spellId, "red", self:Interrupter() and "warning", CL.casting:format(args.spellName))
		end
	end
end

do
	local prev = 0
	function mod:Renew(args)
		local t = args.time
		if t - prev > 1 then
			prev = t
			self:MessageOld(args.spellId, "yellow", self:Interrupter() and "warning", CL.casting:format(args.spellName))
		end
	end
end

do
	local prev, prevGUID = 0, nil
	function mod:RenewApplied(args)
		if not self:Dispeller("magic", true) then return end

		local t = args.time
		local isANewPairOfCasts = t - prev > 1
		if isANewPairOfCasts or (prevGUID ~= args.destGUID) then
			prev = t
			self:TargetMessageOld(args.spellId, args.destName, "yellow")
			if isANewPairOfCasts then
				self:PlaySound(args.spellId, "alarm") -- don't play 2 sounds if 2 different targets get Renew at the same time
			end
		end
		prevGUID = args.destGUID
	end
end

function mod:ShadowWordPain(args)
	if self:Me(args.destGUID) or self:Dispeller("magic") then
		self:TargetMessageOld(args.spellId, args.destName, "orange")
	end
end
