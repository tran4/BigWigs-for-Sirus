--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Icecrown/TheLowerSpire/LordMarrowgar.lua), draft by tools/dbm2bw

local mod, CL = BigWigs:NewBoss("Lord Marrowgar", 631, 1624)
if not mod then return end
mod:RegisterEnableMob(36612)
mod:SetEncounterID(845)

--------------------------------------------------------------------------------
-- Locals
--

local impaleIcon = 8
local impaleList = {}
local prevImpale = 0
local prevColdflame = 0

--------------------------------------------------------------------------------
-- Initialization
--

local impaleMarker = mod:AddMarkerOption(true, "player", 8, 72669, 8, 7, 6, 5, 4, 3, 2, 1)
function mod:GetOptions()
	return {
		69076, -- Bone Storm
		69057, -- Bone Spike Graveyard
		72669, -- Impale
		impaleMarker,
		69146, -- Coldflame
		"berserk",
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "BoneStorm", 69076)
	self:Log("SPELL_AURA_REMOVED", "BoneStormRemoved", 69076)
	self:Log("SPELL_CAST_START", "BoneSpikeGraveyard", 69057, 70826, 72088, 72089)
	self:Log("SPELL_SUMMON", "Impale", 69062, 72669, 72670)
	self:Log("SPELL_AURA_REMOVED", "ImpaledRemoved", 69065)
	self:Log("SPELL_PERIODIC_DAMAGE", "ColdflameDamage", 69146, 70823, 70824, 70825)
	self:Log("SPELL_PERIODIC_MISSED", "ColdflameDamage", 69146, 70823, 70824, 70825)
end

function mod:OnEngage()
	impaleIcon = 8
	impaleList = {}
	self:DelayedMessage(69076, 40, "orange", CL.soon:format(self:SpellName(69076)))
	self:CDBar(69076, 45)
	self:CDBar(69057, 15)
	self:Berserk(600)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:BoneStorm(args)
	self:Message(69076, "red")
	self:PlaySound(69076, "alarm")
	self:CDBar(69076, 90)
	self:DelayedMessage(69076, 85, "orange", CL.soon:format(args.spellName))
	local diff = self:Difficulty()
	self:CastBar(69076, (self:Heroic() or diff == 4) and 30 or 20) -- ~30s on heroic and 25 normal, ~20s on 10 normal
	if not self:Heroic() then
		self:StopBar(69057) -- no Bone Spike Graveyard during Bone Storm on normal
	end
end

function mod:BoneStormRemoved()
	self:StopCastBar(69076)
	if self:Normal() then
		self:CDBar(69057, 15) -- Bone Spike Graveyard 15 seconds after Bone Storm on normal
	end
end

function mod:BoneSpikeGraveyard(args)
	self:Message(69057, "yellow", CL.casting:format(args.spellName))
	self:PlaySound(69057, "alert")
	self:CDBar(69057, 18)
end

function mod:Impale(args) -- the summon's source is the impaled player
	if args.time - prevImpale > 5 then
		impaleList = {}
	end
	prevImpale = args.time
	impaleList[#impaleList + 1] = args.sourceName
	self:TargetsMessage(72669, "orange", impaleList, nil, nil, nil, 0.3)
	self:CustomIcon(impaleMarker, args.sourceName, impaleIcon)
	impaleIcon = impaleIcon - 1
	if impaleIcon < 1 then impaleIcon = 8 end
end

function mod:ImpaledRemoved(args)
	self:CustomIcon(impaleMarker, args.destName)
end

function mod:ColdflameDamage(args)
	if self:Me(args.destGUID) and args.time - prevColdflame > 2.5 then
		prevColdflame = args.time
		self:PersonalMessage(69146, "underyou")
		self:PlaySound(69146, "underyou")
	end
end
