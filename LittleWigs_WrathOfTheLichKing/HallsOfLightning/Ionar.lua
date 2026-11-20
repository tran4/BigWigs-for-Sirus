--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("Ionar", 602, 599)
if not mod then return end
mod:RegisterEnableMob(28546)
mod:SetEncounterID(1984) -- 3.3.5: encounter emulation for the pull timers (the retail module has no encounter id)

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		{52658, "SAY"}, -- Static Overload
		52770, -- Disperse
		52780, -- Ball Lightning (3.3.5: WA: "WA на ключи - автор Раэнис х3")
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "StaticOverload", 52658)
	self:Log("SPELL_AURA_REMOVED", "StaticOverloadRemoved", 52658)
	if self:Classic() then
		-- Retail: 52658 is used in all difficulties, 59795 was removed in 11.0.5
		-- Classic: 59795 is used in Heroic, 52658 is used in Normal
		self:Log("SPELL_AURA_APPLIED", "StaticOverload", 59795)
		self:Log("SPELL_AURA_REMOVED", "StaticOverloadRemoved", 59795)
	end
	self:Log("SPELL_CAST_START", "Disperse", 52770)
	self:Log("SPELL_CAST_START", "BallLightning", 52780, 59800) -- 3.3.5: WA: "WA на ключи - автор Раэнис х3", 10s
	self:Death("Win", 28546)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:StaticOverload(args)
	self:TargetMessage(52658, "yellow", args.destName)
	self:TargetBar(52658, 10, args.destName)
	if self:Me(args.destGUID) then
		self:Say(52658, nil, nil, "Static Overload")
	end
	self:PlaySound(52658, "alarm", nil, args.destName)
end

function mod:StaticOverloadRemoved(args)
	self:StopBar(args.spellName, args.destName)
end

function mod:Disperse(args)
	self:Message(args.spellId, "cyan")
	self:PlaySound(args.spellId, "info")
end

-- 3.3.5: WA: "WA на ключи - автор Раэнис х3", the first Ball Lightning 10s after the pull yell, then every 10s
function mod:OnEngage()
	self:CDBar(52780, 10)
end

function mod:BallLightning()
	self:CDBar(52780, 10)
end
