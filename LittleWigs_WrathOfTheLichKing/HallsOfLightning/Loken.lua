
--------------------------------------------------------------------------------
-- Module declaration
--

local mod, CL = BigWigs:NewBoss("Loken", 602, 600)
if not mod then return end
mod:RegisterEnableMob(28923)
mod:SetEncounterID(1986) -- 3.3.5: encounter emulation for the pull timers (the retail module has no encounter id)

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		59835, -- Lightning Nova
		52921, -- Arc Lightning (3.3.5: WA: "WA на ключи - автор Раэнис х3")
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "LightningNova", 52960, 59835) -- normal, heroic
	self:Log("SPELL_CAST_SUCCESS", "ArcLightning", 52921, 52924) -- 3.3.5: WA: "WA на ключи - автор Раэнис х3", 15s

	self:Death("Win", 28923)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:LightningNova(args)
	self:MessageOld(59835, "orange", "alert")
	self:CastBar(59835, args.spellId == 59835 and 4 or 5) -- 3.3.5: a cast bar, the cooldown bar below has the plain text
	-- 3.3.5: the next one, 20s on the mythic keys (WA: "WA на ключи - автор Раэнис х3"), DBM Sirus 30s
	self:CDBar(59835, self:Difficulty() == 23 and 20 or 30)
end

function mod:OnEngage() -- 3.3.5: WA: "WA на ключи - автор Раэнис х3", the first Arc Lightning 15s after the pull yell
	self:CDBar(52921, 15)
end

function mod:ArcLightning() -- 3.3.5: WA: "WA на ключи - автор Раэнис х3"
	self:CDBar(52921, 15)
end
