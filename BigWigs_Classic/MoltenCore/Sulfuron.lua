--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-MC/Sulfuron.lua)

local mod, CL = BigWigs:NewBoss("Sulfuron Harbinger", 409, 1525)
if not mod then return end
mod:RegisterEnableMob(12098)
mod:SetEncounterID(669)

--------------------------------------------------------------------------------
-- Locals
--

local handList, painList, immolateList = {}, {}, {}

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		{19779, "TANK_HEALER"}, -- Inspire (DBM: tanks and healers only)
		19775, -- Dark Mending
		{19780, "OFF"}, -- Hand of Ragnaros
		{19776, "OFF"}, -- Shadow Word: Pain
		{20294, "OFF"}, -- Immolate
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "Inspire", 19779)
	self:Log("SPELL_AURA_REMOVED", "InspireRemoved", 19779)
	self:Log("SPELL_CAST_START", "DarkMending", 19775)
	self:Log("SPELL_AURA_APPLIED", "HandOfRagnaros", 19780)
	self:Log("SPELL_AURA_APPLIED", "ShadowWordPain", 19776)
	self:Log("SPELL_AURA_APPLIED", "Immolate", 20294)
end

function mod:OnEngage()
	handList, painList, immolateList = {}, {}, {}
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:Inspire(args)
	self:TargetMessage(19779, "orange", args.destName)
	self:TargetBar(19779, 10, args.destName)
end

function mod:InspireRemoved(args)
	self:StopBar(19779, args.destName)
end

function mod:DarkMending(args)
	-- DBM: only for the healer you are targeting or focusing
	if self:Hostile(args.sourceFlags) and (self:UnitGUID("target") == args.sourceGUID or self:UnitGUID("focus") == args.sourceGUID) then
		self:Message(19775, "red", CL.casting:format(args.spellName))
		self:CastBar(19775, 2)
		if self:Interrupter() then
			self:PlaySound(19775, "alert")
		end
	end
end

function mod:HandOfRagnaros(args)
	if self:Player(args.destFlags) then
		handList[#handList + 1] = args.destName
		self:TargetsMessage(19780, "yellow", handList)
	end
end

function mod:ShadowWordPain(args)
	if self:Player(args.destFlags) then
		painList[#painList + 1] = args.destName
		self:TargetsMessage(19776, "yellow", painList)
	end
end

function mod:Immolate(args)
	if self:Player(args.destFlags) then
		immolateList[#immolateList + 1] = args.destName
		self:TargetsMessage(20294, "yellow", immolateList)
	end
end
