--------------------------------------------------------------------------------
-- Module Declaration
--

local mod, CL = BigWigs:NewBoss("Old Hillsbrad Foothills Trash", 560)
if not mod then return end
mod:SetTrashModule(true)
mod:RegisterEnableMob(
	18723, -- Erozion
	17876, -- Thrall
	18887, -- Taretha

	-- To ensure the module is loaded for Incendiary Bombs, mobs from Durnholde Keep:
	17840, -- Durnholde Tracking Hound
	18598, -- Orc Prisoner
	17820, -- Durnholde Rifleman
	17833 -- Durnholde Warden
)

--------------------------------------------------------------------------------
-- Localization
--

local L = mod:SetDefaultLocale({
	custom_on_autotalk = CL.autotalk,
	custom_on_autotalk_desc = "Instantly select Erozion's, Thrall's and Taretha's gossip options.",
	custom_on_autotalk_icon = mod:GetMenuIcon("SAY"),

	incendiary_bombs = "Incendiary Bombs",
	incendiary_bombs_desc = "Display a message when an Incendiary Bomb is planted.",
	incendiary_bombs_icon = "inv_misc_bomb_05",
})

--------------------------------------------------------------------------------
-- Initialization
--

function mod:GetOptions()
	return {
		"custom_on_autotalk",
		"incendiary_bombs"
	}
end

function mod:OnBossEnable()
	self:RegisterMessage("BigWigs_OnBossEngage", "Disable")
	if self:Retail() then
		self:RegisterWidgetEvent(522, "BombPlanted")
	else -- 3.3.5: no UI widgets, the bomb counter is a world state ("N/5")
		self:RegisterEvent("UPDATE_WORLD_STATES")
		self:UPDATE_WORLD_STATES()
	end
	self:RegisterEvent("GOSSIP_SHOW")
end

--------------------------------------------------------------------------------
-- Event Handlers
--

function mod:GOSSIP_SHOW()
	if self:GetOption("custom_on_autotalk") then
		-- 3.3.5: no C_GossipInfo, the gossip quest functions
		if GetNumGossipAvailableQuests() > 0 or GetNumGossipActiveQuests() > 0 then return end -- let the player take / turn in the quest

		-- If the player is in a group, do not free Thrall automatically,
		-- because they may deny others a chance to turn in the quest.
		local mobId = self:MobId(self:UnitGUID("npc"))
		if mobId == 17876 and not self:Solo() then
			if self:Classic() then
				-- no scenario APIs in Classic
				return
			else
				local info = C_ScenarioInfo.GetCriteriaInfo(2)
				if info and not info.completed then return end
			end
		end

		if self:GetGossipOptions() then
			-- Erozion:
			-- 33853:I need a pack of incendiary bombs.
			-- Brazen:
			-- 34081:I'm ready to go to Durnholde Keep.
			-- Thrall:
			-- 33364:We are ready to get you out of here, Thrall. Let's go!
			-- 34372:Taretha cannot see you, Thrall.
			-- 35171:The situation is rather complicated, Thrall. It would be best for you to head into the mountains now, before more of Blackmoore's men show up. We'll make sure Taretha is safe.
			-- 34362:Tarren Mill.
			-- 32900:We're ready, Thrall.
			-- Taretha
			-- 34893:Strange wizard?
			-- 33525:We'll get you out, Taretha. Don't worry. I doubt the wizard would wander too far away.
			self:SelectGossipOption(1)
		end
	end
end

local prevBombs = 0 -- 3.3.5: world states update on any change, warn on a new count only
function mod:UPDATE_WORLD_STATES() -- 3.3.5
	for i = 1, GetNumWorldStateUI() do
		local _, _, text = GetWorldStateUIInfo(i)
		if text and text:find("%d+.+5") then
			self:BombPlanted(nil, text)
			return
		end
	end
end

function mod:BombPlanted(id, text)
	local bombText = text:match("(%d+).+5")
	if bombText then
		local bombCount = tonumber(bombText)
		if bombCount and bombCount > 0 and (id or bombCount ~= prevBombs) then
			prevBombs = bombCount
			self:MessageOld("incendiary_bombs", "cyan", "info", CL.count:format(L.incendiary_bombs, bombCount), L.incendiary_bombs_icon)

			if bombCount == 5 then
				if id then
					self:UnregisterWidgetEvent(id)
				else
					self:UnregisterEvent("UPDATE_WORLD_STATES") -- 3.3.5
				end
				local drakeModule = BigWigs:GetBossModule("Lieutenant Drake", true)
				if drakeModule then
					drakeModule:Enable()
					drakeModule:Warmup(20.5)
				end
			end
		end
	end
end
