-------------------------------------------------------------------------------
-- Module Declaration
--

local plugin, L = BigWigs:NewPlugin("Victory")
if not plugin then return end

-------------------------------------------------------------------------------
-- Locals
--

local LibSharedMedia = LibStub("LibSharedMedia-3.0")
local SOUND = LibSharedMedia.MediaType and LibSharedMedia.MediaType.SOUND or "sound"

-------------------------------------------------------------------------------
-- Options
--

plugin.defaultDB = {
	soundName = "BigWigs: Victory",
	blizzVictory = false,
	bigwigsVictory = true,
}

plugin.pluginOptions = {
	name = "|TInterface\\AddOns\\BigWigs\\Media\\Icons\\Menus\\Victory:20|t ".. L.Victory,
	type = "group",
	childGroups = "tab",
	get = function(i) return plugin.db.profile[i[#i]] end,
	set = function(i, value)
		local n = i[#i]
		plugin.db.profile[n] = value
	end,
	order = 11,
	args = {
		heading = {
			type = "description",
			name = L.victoryHeader.."\n\n",
			order = 1,
			width = "full",
			fontSize = "medium",
		},
		soundName = {
			type = "select",
			name = L.victorySound,
			order = 2,
			get = function(info)
				for i, v in next, LibSharedMedia:List(SOUND) do
					if v == plugin.db.profile[info[#info]] then
						return i
					end
				end
			end,
			set = function(info, value)
				plugin.db.profile[info[#info]] = LibSharedMedia:List(SOUND)[value]
			end,
			values = LibSharedMedia:List(SOUND),
			width = "full",
			dialogControl = "BigWigsSharedDropdown",
			itemControl = "DDI-Sound",
		},
		messages = {
			type = "group",
			name = L.victoryMessages,
			order = 3,
			inline = true,
			args = {
				bigwigsVictory = {
					type = "toggle",
					name = L.victoryMessageBigWigs,
					desc = L.victoryMessageBigWigsDesc,
					order = 1,
					width = "full",
				},
				blizzVictory = {
					type = "toggle",
					name = L.victoryMessageBlizzard,
					desc = L.victoryMessageBlizzardDesc,
					order = 2,
					width = "full",
					hidden = true, -- 3.3.5: no BossBanner
				},
			},
		},
	},
}

-------------------------------------------------------------------------------
-- Initialization
--

do
	local function updateProfile()
		local db = plugin.db.profile
		for k, v in next, db do
			local defaultType = type(plugin.defaultDB[k])
			if defaultType == "nil" then
				db[k] = nil
			elseif type(v) ~= defaultType then
				db[k] = plugin.defaultDB[k]
			end
		end

		if not LibSharedMedia:IsValid("sound", db.soundName) then
			db.soundName = plugin.defaultDB.soundName
		end
	end

	function plugin:OnPluginEnable()
		updateProfile()
		-- 3.3.5: no StopSound, so the victory sound can't be preloaded by playing and stopping it

		self:RegisterMessage("BigWigs_OnBossWin")
		self:RegisterMessage("BigWigs_VictorySound")

		self:RegisterMessage("BigWigs_ProfileUpdate", updateProfile)
	end
end

-------------------------------------------------------------------------------
-- Event Handlers
--

function plugin:BigWigs_OnBossWin(_, module)
	if self.db.profile.bigwigsVictory then
		self:SendMessage("BigWigs_Message", self, nil, L.defeated:format(module.displayName), "green")
	end
end

do
	local prev = 0
	local GetTime = GetTime
	function plugin:BigWigs_VictorySound()
		local t = GetTime()
		if t-prev > 5 then -- Dastardly Duos sanity preservation
			prev = t
			local soundName = self.db.profile.soundName
			if soundName ~= "None" then
				local sound = LibSharedMedia:Fetch(SOUND, soundName, true)
				if sound then
					self:PlaySoundFile(sound)
				end
			end
		end
	end
end
