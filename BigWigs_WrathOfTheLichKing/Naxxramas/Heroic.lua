--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus, not in DBM Sirus: the heroic Naxxramas of Sirus (custom spells 372xxx-373xxx) from the
-- players' WeakAuras (WA: "Naxx", groups "Deb", "Оковы", "Чумной удар", "Гнилостный удар", "Зачумление 2" and the
-- casts outside the groups). The WeakAuras do not say the boss of these, so they are in one module for the zone,
-- enabled on zone in like a trash module, active on heroic only. The spells the WeakAuras find by the name have the ids
-- of the same names in the spell cache of the players' WeakAurasOptions. The bosses with a clear group in the
-- WeakAuras have their parts in their own modules (Thaddius, Instructor Razuvious, Heigan, Noth, Grobbulus).

local mod, CL = BigWigs:NewBoss("Naxxramas Heroic", 533)
if not mod then return end
mod:SetTrashModule(true)

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	name = "Наксрамас (героик)", -- WA: no English text
})
mod.displayName = L.name

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		-- on you
		372035, -- poison (WA: "Быстродействующий яд")
		372036, -- poison (WA: "Обжигающий яд")
		372028, -- locusts (WA: "Заражение саранчой")
		373323, -- plague (WA: "Загадочная чума")
		373412, -- plague (WA: "Зачумление")
		373423, -- Impulse (WA)
		373421, -- Lightning Conductor (WA)
		372084, -- WA: "Сумеречная буря"
		372059, -- WA: "Костяной шип"
		372053, -- WA: "Ядовитые останки"
		-- on the group
		373415, -- plague (WA: "Зачумление деб")
		373307, -- mark (WA: group "Оковы")
		373319, -- WA: "Чумной удар"
		373318, -- WA: "Гнилостный удар"
		-- casts
		373322, -- WA: "Извержение желчи"
		373558, -- WA: "Вспышка Тьмы"
		372088, -- WA: "Антимагический щит"
		372089, -- WA: "Доспех с шипами"
	}
end

local onYouKey = {[372085] = 372084, [372086] = 372084, [372087] = 372084, [373521] = 372084, [372060] = 372059, [372061] = 372059, [373607] = 372059, [372054] = 372053}

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "DebuffOnYou", 372035, 372036, 372028, 373323, 373412, 373423, 373421, 372084, 372085, 372086, 372087, 373521, 372059, 372060, 372061, 373607, 372053, 372054) -- WA
	self:Log("SPELL_AURA_APPLIED_DOSE", "DebuffOnYou", 372035, 372036, 372028) -- WA: stacks ("3" in their names)
	self:Log("SPELL_AURA_APPLIED", "GroupDebuff", 373415, 373307, 373319, 373318) -- WA: shown on the group
	self:Log("SPELL_CAST_START", "Cast", 373322, 373558, 372088, 372089, 372090) -- WA
end

--------------------------------------------------------------------------------
-- Event Handlers
--

do
	local prev = {}
	function mod:DebuffOnYou(args)
		if not self:Heroic() or not self:Me(args.destGUID) then return end
		local key = onYouKey[args.spellId] or args.spellId
		if args.time - (prev[key] or 0) > 2 then
			prev[key] = args.time
			self:PersonalMessage(key)
			self:PlaySound(key, "alarm")
		end
	end
end

function mod:GroupDebuff(args)
	if not self:Heroic() then return end
	self:TargetMessage(args.spellId, "orange", args.destName)
	if self:Me(args.destGUID) then
		self:PlaySound(args.spellId, "warning")
	end
end

do
	local prev = {}
	function mod:Cast(args)
		if not self:Heroic() then return end
		local key = args.spellId == 372090 and 372089 or args.spellId
		if args.time - (prev[key] or 0) > 1 then
			prev[key] = args.time
			self:Message(key, "yellow", args.spellName) -- 3.3.5: no "Casting" prefix (user), the name only
		end
	end
end
