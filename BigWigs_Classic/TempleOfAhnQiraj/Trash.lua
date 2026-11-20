--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus from DBM Sirus (DBM-AQ40/AQ40Trash.lua)
-- Not ported: the speed clear timer.

local mod, CL = BigWigs:NewBoss("Temple of Ahn'Qiraj Trash", 531)
if not mod then return end
mod.displayName = CL.trash
mod:SetTrashModule(true)

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		{22997, "SAY", "PROXIMITY"}, -- Plague
		25698, -- Explode
		26079, -- Cause Insanity
		19595, -- Shadow and Frost Reflect
		13022, -- Fire and Arcane Reflect
		26555, -- Shadow Storm
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "Plague", 22997)
	self:Log("SPELL_AURA_REMOVED", "PlagueRemoved", 22997)
	self:Log("SPELL_AURA_APPLIED", "Explode", 25698)
	self:Log("SPELL_AURA_APPLIED", "CauseInsanity", 26079)
	self:Log("SPELL_MISSED", "Reflect", "*")
	self:Log("SPELL_DAMAGE", "ShadowStorm", 26555)
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:Plague(args)
	if self:Me(args.destGUID) then
		self:PersonalMessage(22997)
		self:PlaySound(22997, "alarm") -- DBM: run out
		self:Say(22997)
		self:OpenProximity(22997, 10)
	else
		self:TargetMessage(22997, "yellow", args.destName)
	end
end

function mod:PlagueRemoved(args)
	if self:Me(args.destGUID) then
		self:CloseProximity(22997)
	end
end

function mod:Explode(args)
	self:Message(25698, "red")
	if self:Melee() then
		self:PlaySound(25698, "alarm") -- DBM: run away (melee)
	end
end

do
	local insanityList = {}
	function mod:CauseInsanity(args)
		insanityList[#insanityList + 1] = args.destName
		self:TargetsMessage(26079, "orange", insanityList, nil, nil, nil, 0.75)
	end
end

do
	local prevShadowFrost, prevFireArcane = 0, 0
	function mod:Reflect(args)
		-- 3.3.5: SPELL_MISSED has the miss type where the extra spell id would be
		if not self:Me(args.sourceGUID) or (args.extraSpellId ~= "REFLECT" and args.extraSpellId ~= "DEFLECT") then return end
		local school = args.spellSchool
		if (school == 32 or school == 16) and args.time - prevShadowFrost > 3 then
			prevShadowFrost = args.time
			self:Message(19595, "blue", CL.other:format(self:SpellName(19595), args.destName))
			self:PlaySound(19595, "alarm") -- DBM: stop attacking
		elseif (school == 4 or school == 64) and args.time - prevFireArcane > 3 then
			prevFireArcane = args.time
			self:Message(13022, "blue", CL.other:format(self:SpellName(13022), args.destName))
			self:PlaySound(13022, "alarm")
		end
	end
end

do
	local prev = 0
	function mod:ShadowStorm(args)
		if self:Me(args.destGUID) and args.time - prev > 3 then
			prev = args.time
			self:Message(26555, "blue", CL.other:format(args.spellName, args.sourceName))
			self:PlaySound(26555, "alarm") -- DBM: move to the Anubisath (find shelter)
		end
	end
end
