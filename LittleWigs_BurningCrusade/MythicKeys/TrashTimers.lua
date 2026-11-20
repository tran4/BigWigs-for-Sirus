--------------------------------------------------------------------------------
-- Module Declaration
--
-- 3.3.5: written for Sirus, not in retail LittleWigs nor in DBM Sirus: the cooldowns of the trash of the Sirus key
-- dungeons from the players' WeakAuras (WA: "WA на ключи - автор Раэнис х3"). Like the WeakAuras the timers start on
-- the spell name and the name of the mob casting it (one spell name has many ids), so they work on the Russian client
-- only. The option keys are spell ids of the same names from the spell cache of the players' WeakAurasOptions (for
-- the option names and icons). Enabled in the dungeons on zone in like a trash module, on every difficulty like the
-- WeakAuras.

local mod, CL = BigWigs:NewBoss("Key Trash Timers", {558, 542, 547, 557})
if not mod then return end
mod:SetTrashModule(true)

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	-- WA: only Russian texts, the English defaults are the Russian texts
	name = "Таймеры треша (ключи)",

	monk = "Аукенайский монах", -- Auchenai Crypts
	wrath_soul = "Гневная душа", -- Auchenai Crypts
	neophyte = "Новообращенный орк Скверны", -- The Blood Furnace
	healer = "Целительница чешуи резервуара Кривого Клыка", -- The Slave Pens
	warrior = "Воитель резервуара Кривого Клыка", -- The Slave Pens
	watcher = "Наблюдатель резервуара Кривого Клыка", -- The Slave Pens
	wonder = "Эфириал-чудесник", -- Mana-Tombs
	priest = "Эфириал-жрец", -- Mana-Tombs
	terror = "Ужасень Нексуса", -- Mana-Tombs
	fiend = "Волшебное исчадие", -- Mana-Tombs

	fiend_interrupt = "Прерывание Волшебного исчадия",
	fiend_interrupt_desc = "Таймер следующего прерывания Волшебного исчадия после того, как оно прервало заклинание (Гробницы Маны).",
	fiend_interrupt_icon = "spell_frost_iceshock",
})
mod.displayName = L.name

--------------------------------------------------------------------------------
-- Initialization
--

-- event, spell id of the option, spell name (from the client, by the option id), mob, duration (WA)
local timers = {
	{"SPELL_CAST_SUCCESS", 32849, "monk", 8}, -- Whirlwind (Auchenai Monk)
	{"SPELL_CAST_START", 5176, "wrath_soul", 4.5, true}, -- Wrath (cast bar)
	{"SPELL_CAST_SUCCESS", 4282, "neophyte", 12}, -- Stomp
	{"SPELL_CAST_SUCCESS", 15237, "healer", 12}, -- Holy Nova
	{"SPELL_CAST_SUCCESS", 15237, "priest", 12}, -- Holy Nova
	{"SPELL_CAST_SUCCESS", 19134, "warrior", 29}, -- Frightening Shout
	{"SPELL_CAST_SUCCESS", 4062, "watcher", 13}, -- Heavy Dynamite
	{"SPELL_CAST_SUCCESS", 11113, "wonder", 8}, -- Blast Wave
	{"SPELL_CAST_SUCCESS", 6789, "terror", 16}, -- Death Coil
	{"SPELL_CAST_SUCCESS", 8122, "terror", 18}, -- Psychic Scream
}

function mod:GetOptions()
	return {
		32849, -- Whirlwind
		5176, -- Wrath
		4282, -- Stomp
		15237, -- Holy Nova
		19134, -- Frightening Shout
		4062, -- Heavy Dynamite
		11113, -- Blast Wave
		6789, -- Death Coil
		8122, -- Psychic Scream
		"fiend_interrupt",
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
	self:Log("SPELL_INTERRUPT", "Interrupt", "*")
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

function mod:Interrupt(args)
	if args.sourceName == L.fiend then -- WA: the fiend interrupted a cast, its next interrupt in 15s
		self:CDBar("fiend_interrupt", 15, L.fiend_interrupt, L.fiend_interrupt_icon)
	end
end
