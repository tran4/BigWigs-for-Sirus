--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-Icecrown/ThePlagueworks/Festergut.lua), draft by tools/dbm2bw
-- Not ported: announcing Gas Spore icons and the achievement to the raid chat.

local mod, CL = BigWigs:NewBoss("Festergut", 631, 1629)
if not mod then return end
mod:RegisterEnableMob(36626)
mod:SetEncounterID(849)

--------------------------------------------------------------------------------
-- Locals
--

local sporeList = {}
local sporeIcon = 8
local sporeWaves = 0
local prevSpore = 0
local vileGasList = {}
local prevVileGas = 0

local function is25(self) -- 25 player raid (normal or heroic)
	local diff = self:Difficulty()
	return diff == 4 or diff == 6
end

--------------------------------------------------------------------------------
-- Initialization
--

local sporeMarker = mod:AddMarkerOption(true, "player", 8, 69279, 8, 7, 6)
function mod:GetOptions()
	return {
		"berserk",
		{69166, "TANK"}, -- Inhaled Blight
		69195, -- Pungent Blight
		{69279, "SAY"}, -- Gas Spore
		sporeMarker,
		{69240, "SAY", "PROXIMITY"}, -- Vile Gas
		{72219, "TANK_HEALER"}, -- Gastric Bloat
		72297, -- Malleable Goo
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_CAST_START", "PungentBlight", 69195, 71219, 73031, 73032)
	self:Log("SPELL_AURA_APPLIED", "InhaledBlight", 69166, 71912)
	self:Log("SPELL_AURA_APPLIED_DOSE", "InhaledBlight", 69166, 71912)
	self:Log("SPELL_AURA_APPLIED", "GasSpore", 69279)
	self:Log("SPELL_AURA_REMOVED", "GasSporeRemoved", 69279)
	self:Log("SPELL_AURA_APPLIED", "VileGas", 69240, 71218, 73019, 73020)
	self:Log("SPELL_AURA_APPLIED", "GastricBloat", 72219, 72551, 72552, 72553)
	self:Log("SPELL_AURA_APPLIED_DOSE", "GastricBloat", 72219, 72551, 72552, 72553)
	self:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", nil, "boss1", "boss2") -- Malleable Goo comes from Professor Putricide
end

function mod:OnEngage()
	sporeList = {}
	vileGasList = {}
	sporeWaves = 0
	self:Berserk(300)
	self:Bar(69166, 34)
	self:Bar(69279, 20)
	if self:Heroic() then
		self:CDBar(72297, 13)
	end
	self:OpenProximity(69240, 8)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:PungentBlight(args)
	self:Message(69195, "red")
	self:PlaySound(69195, "long")
	self:Bar(69166, 38)
end

function mod:InhaledBlight(args)
	local amount = args.amount or 1
	self:StackMessage(69166, "yellow", args.destName, amount, 3)
	if amount >= 3 then -- no 4th Inhaled Blight, Pungent Blight is next
		self:Bar(69195, 34)
		if self:Tank() then
			self:PlaySound(69166, "warning")
		end
	else
		self:Bar(69166, 34)
	end
end

function mod:GasSpore(args)
	if args.time - prevSpore > 3 then
		-- every 40 seconds, the set after every 3rd is 10 seconds later
		sporeList = {}
		sporeIcon = 8
		sporeWaves = sporeWaves + 1
		self:Bar(69279, sporeWaves % 3 == 0 and 50 or 40)
		self:Bar(69279, 12, CL.explosion)
	end
	prevSpore = args.time
	sporeList[#sporeList + 1] = args.destName
	self:TargetsMessage(69279, "orange", sporeList, is25(self) and 3 or 2)
	if self:Me(args.destGUID) then
		self:Say(69279)
		self:PlaySound(69279, "warning")
	end
	self:CustomIcon(sporeMarker, args.destName, sporeIcon)
	sporeIcon = sporeIcon - 1
end

function mod:GasSporeRemoved(args)
	self:CustomIcon(sporeMarker, args.destName)
end

function mod:VileGas(args)
	if not self:Player(args.destFlags) then return end
	if args.time - prevVileGas > 3 then
		vileGasList = {}
	end
	prevVileGas = args.time
	vileGasList[#vileGasList + 1] = args.destName
	self:TargetsMessage(69240, "yellow", vileGasList, nil, nil, nil, 0.8)
	if self:Me(args.destGUID) then
		self:Say(69240)
		self:PlaySound(69240, "warning")
	end
end

function mod:GastricBloat(args)
	local amount = args.amount or 1
	self:StackMessage(72219, "purple", args.destName, amount, 9)
	self:CDBar(72219, 12)
	if self:Me(args.destGUID) and amount >= 9 then
		self:PlaySound(72219, "alarm")
	end
end

do
	local prev = nil
	function mod:UNIT_SPELLCAST_SUCCEEDED(_, _, castGUID, _, spellName)
		if spellName == self:SpellName(72299) and castGUID ~= prev then -- Malleable Goo Summon Trigger
			prev = castGUID
			self:Message(72297, "orange")
			self:PlaySound(72297, "alarm")
			self:CDBar(72297, self:Difficulty() == 6 and 10 or 15)
		end
	end
end
