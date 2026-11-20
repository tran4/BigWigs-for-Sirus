--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("Omor the Unscarred", 543, 528)
if not mod then return end
mod:RegisterEnableMob(17308)
--mod.engageId = 1891 -- no boss frames
mod:SetEncounterID(1891) -- 3.3.5: encounter emulation, there is no ENCOUNTER_START (the retail module has no boss frames to engage by)
--mod.respawnTime = 0 -- resets, doesn't respawn

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		{30695, "SAY", "ICON"}, -- Treacherous Aura
		31901, -- Demonic Shield (3.3.5: WA: "WA на ключи - автор Раэнис х3")
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "TreacherousAura", 30695, 37566) -- Treacherous Aura, Bane of Treachery (heroic version)
	self:Log("SPELL_AURA_REMOVED", "TreacherousAuraRemoved", 30695, 37566)
	self:Log("SPELL_AURA_APPLIED", "DemonicShield", 31901) -- 3.3.5: WA: "WA на ключи - автор Раэнис х3", 10s
	self:Death("Win", 17308)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:TreacherousAura(args)
	if self:Me(args.destGUID) then
		self:Say(30695, nil, nil, "Treacherous Aura")
	end
	self:TargetMessageOld(30695, args.destName, "orange", nil, args.spellName)
	self:TargetBar(30695, 15, args.destName, args.spellName)
	self:PrimaryIcon(30695, args.destName)
end

function mod:TreacherousAuraRemoved(args)
	self:PrimaryIcon(30695)
	self:StopBar(args.spellName, args.destName)
end

function mod:DemonicShield(args) -- 3.3.5: WA: "WA на ключи - автор Раэнис х3"
	if self:MobId(args.destGUID) == 17308 then
		self:Message(31901, "yellow", CL.onboss:format(args.spellName))
		self:Bar(31901, 10, CL.other:format(args.spellName, CL.active))
	end
end
