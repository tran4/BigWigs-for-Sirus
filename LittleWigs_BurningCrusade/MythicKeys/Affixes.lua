--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus, not in retail LittleWigs nor in DBM Sirus: the affixes of the Sirus mythic keys (difficulty
-- 23) from the players' WeakAuras (WA: "WA на ключи - автор Раэнис х3"). Enabled in every Burning Crusade dungeon on
-- zone in like a trash module, it only warns on the mythic difficulty. The affixes found by id in the WeakAuras use
-- their ids, the volcano and the orbs are found by the Russian names of the WeakAuras (the module is quiet on other
-- client languages for them). No timers: the WeakAuras have none for these.

local mod, CL = BigWigs:NewBoss("Mythic Keystone Affixes", {543, 542, 540, 547, 546, 545, 553, 554, 552, 556, 555, 557, 558, 269, 560, 585})
if not mod then return end
mod:SetTrashModule(true)

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	-- WA: only Russian texts, the English defaults are the Russian texts
	affixes = "Аффиксы ключа",

	volcano = "Вулкан",
	volcano_desc = "Предупреждать, когда под игроком взрывается вулкан (аффикс).",
	volcano_icon = "spell_shaman_lavaburst",
	volcano_source = "Вулкан", -- WA: CLEU SPELL_CAST_START, source name
	volcano_spell = "Взрыв", -- WA: spell name

	orbs = "Сферы",
	orbs_desc = "Предупреждать, когда Взрывчатка начинает Огненный взрыв (аффикс): убейте сферу.",
	orbs_icon = "spell_fire_selfdestruct",
	orbs_source = "Взрывчатка", -- WA: CLEU SPELL_CAST_START, source name
	orbs_spell = "Огненный взрыв", -- WA: spell name
	orbs_message = "Сфера: убейте!",
})
mod.displayName = L.affixes

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		382471, -- Explosive (WA: debuff on you)
		382480, -- Entangling (WA: debuff on you)
		382477, -- Bolstering (WA: aura on you)
		382486, -- Raging (WA: aura on the mob)
		"volcano",
		"orbs",
	}
end

function mod:OnBossEnable()
	self:Log("SPELL_AURA_APPLIED", "DebuffOnYou", 382471, 382480, 382477) -- WA
	self:Log("SPELL_AURA_APPLIED_DOSE", "DebuffOnYou", 382477) -- WA
	self:Log("SPELL_AURA_APPLIED", "Raging", 382486) -- WA
	self:Log("SPELL_CAST_START", "CastStart", "*") -- WA: volcano and orbs, by the names
end

--------------------------------------------------------------------------------
-- Event Handlers
--

local function onMythic(self)
	return self:Difficulty() == 23 -- 3.3.5: Sirus mythic dungeons
end

do
	local prev = {}
	function mod:DebuffOnYou(args)
		if not onMythic(self) or not self:Me(args.destGUID) then return end
		local id = args.spellId
		if args.time - (prev[id] or 0) > 2 then
			prev[id] = args.time
			self:PersonalMessage(id)
			self:PlaySound(id, id == 382477 and "info" or "alarm")
		end
	end
end

do
	local prev = 0
	function mod:Raging(args)
		if not onMythic(self) or self:Player(args.destFlags) then return end
		if args.time - prev > 2 then
			prev = args.time
			self:Message(382486, "orange", CL.other:format(args.spellName, args.destName))
			if self:Dispeller("enrage", true) then
				self:PlaySound(382486, "alert")
			end
		end
	end
end

do
	local prevVolcano, prevOrbs = 0, 0
	function mod:CastStart(args)
		if not onMythic(self) then return end
		if args.sourceName == L.volcano_source and args.spellName == L.volcano_spell then
			if args.time - prevVolcano > 1 then
				prevVolcano = args.time
				self:Message("volcano", "red", CL.incoming:format(L.volcano), L.volcano_icon)
				self:PlaySound("volcano", "alarm")
			end
		elseif args.sourceName == L.orbs_source and args.spellName == L.orbs_spell then
			if args.time - prevOrbs > 1 then
				prevOrbs = args.time
				self:Message("orbs", "yellow", L.orbs_message, L.orbs_icon)
				self:PlaySound("orbs", "info")
			end
		end
	end
end
