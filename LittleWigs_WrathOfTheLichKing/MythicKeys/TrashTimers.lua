--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus, not in retail LittleWigs nor in DBM Sirus: the cooldowns of the trash of the Sirus key
-- dungeons from the players' WeakAuras (WA: "WA на ключи - автор Раэнис х3"). Like the WeakAuras the timers start on
-- the spell name and the name of the mob casting it (one spell name has many ids), so they work on the Russian client
-- only. The option keys are spell ids of the same names from the spell cache of the players' WeakAurasOptions (for
-- the option names and icons). Enabled in the dungeons on zone in like a trash module, on every difficulty like the
-- WeakAuras.

local mod, CL = BigWigs:NewBoss("Key Trash Timers WotLK", {574, 602, 600})
if not mod then return end
mod:SetTrashModule(true)

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	-- WA: only Russian texts, the English defaults are the Russian texts
	name = "Таймеры треша (ключи)",

	protodrake = "Порабощенный протодракон", -- Utgarde Keep
	bonecrusher = "Костекрушитель из клана Укротителей драконов", -- Utgarde Keep
	steamrager = "Волдырный парозлоб", -- Halls of Lightning
	stormfury = "Загробник ярости бурь", -- Halls of Lightning
	spewer = "Гнусный изрыгатель", -- Drak'Tharon Keep
	deathknight = "Восставший рыцарь смерти Драккари", -- Drak'Tharon Keep
})
mod.displayName = L.name

--------------------------------------------------------------------------------
-- Initialization
--

-- event, spell id of the option, spell name (from the client, by the option id), mob, duration (WA)
local timers = {
	{"SPELL_CAST_SUCCESS", 8873, "protodrake", 11}, -- Flame Breath
	{"SPELL_CAST_SUCCESS", 43935, "bonecrusher", 15}, -- Knockdown Spin
	{"SPELL_CAST_SUCCESS", 52531, "steamrager", 13}, -- Steam Blast
	{"SPELL_CAST_SUCCESS", 53043, "stormfury", 16}, -- Electro Shock
	{"SPELL_CAST_SUCCESS", 49703, "spewer", 8}, -- Bile Vomit
	{"SPELL_CAST_SUCCESS", 49723, "deathknight", 7}, -- Icy Touch
}

function mod:GetOptions()
	return {
		8873, -- Flame Breath
		43935, -- Knockdown Spin
		52531, -- Steam Blast
		53043, -- Electro Shock
		49703, -- Bile Vomit
		49723, -- Icy Touch
	}
end

local byName -- [event][spell name][mob name] = timer
function mod:OnBossEnable()
	if not byName then
		byName = {}
		for i = 1, #timers do
			local t = timers[i]
			local name = self:SpellName(t[2])
			byName[t[1]] = byName[t[1]] or {}
			byName[t[1]][name] = byName[t[1]][name] or {}
			byName[t[1]][name][L[t[3]]] = t
		end
	end
	self:Log("SPELL_CAST_SUCCESS", "SpellCastSuccess", "*")
	self:Log("SPELL_CAST_START", "SpellCastStart", "*")
end

--------------------------------------------------------------------------------
-- Event Handlers
--

do
	local prev = {}
	local function start(self, list, args)
		local mobs = list and list[args.spellName]
		local t = mobs and mobs[args.sourceName]
		if not t then return end
		local id = t[2]
		if args.time - (prev[id] or 0) > 1 then
			prev[id] = args.time
			if t[5] then
				self:CastBar(id, t[4])
			else
				self:CDBar(id, t[4])
			end
		end
	end
	function mod:SpellCastSuccess(args)
		start(self, byName.SPELL_CAST_SUCCESS, args)
	end
	function mod:SpellCastStart(args)
		start(self, byName.SPELL_CAST_START, args)
	end
end
