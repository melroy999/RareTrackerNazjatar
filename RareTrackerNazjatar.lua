-- Redefine often used functions locally.
local CreateFrame = CreateFrame
local InterfaceOptionsFrame_Show = InterfaceOptionsFrame_Show
local InterfaceOptionsFrame_OpenToCategory = InterfaceOptionsFrame_OpenToCategory
local LibStub = LibStub
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax

-- Redefine global variables locally.
local UIParent = UIParent
local C_ChatInfo = C_ChatInfo

-- ####################################################################
-- ##                      Localization Support                      ##
-- ####################################################################

-- Get an object we can use for the localization of the addon.
local L = LibStub("AceLocale-3.0"):GetLocale("RareTrackerNazjatar", true)

-- ####################################################################
-- ##                              Core                              ##
-- ####################################################################

local RTN = CreateFrame("Frame", "RTN", UIParent);

-- The current data we have of the rares.
RTN.is_alive = {}
RTN.current_health = {}
RTN.last_recorded_death = {}
RTN.current_coordinates = {}

-- The zone_uid can be used to distinguish different shards of the zone.
RTN.current_shard_id = nil

-- A table containing all UID deaths reported by the player.
RTN.recorded_entity_death_ids = {}

-- A table containing all vignette UIDs reported by the player.
RTN.reported_vignettes = {}

-- A table containing all spawn UIDs that have been reported through a sound warning.
RTN.reported_spawn_uids = {}

-- The version of the addon.
RTN.version = 6
-- Version 2: changed the order of the rares.
-- Version 3: death messages now send the spawn id.
-- Version 4: changed the interface of the alive message to include coordinates.
-- Version 5: added a future version of Mechtarantula.
-- Version 6: the time stamp that was used to generate the compressed table is now included in group messages.

-- The last zone the user was in.
RTN.last_zone_id = nil

-- Check whether the addon has loaded.
RTN.is_loaded = false

-- ####################################################################
-- ##                         Saved Variables                        ##
-- ####################################################################

-- Setting saved in the saved variables.
RTNDB = {}

-- The rares marked as RTNDB.favorite_rares by the player.
RTNDB.favorite_rares = {}

-- Remember whether the user wants to see the window or not.
RTNDB.show_window = nil

-- Keep a cache of previous data, that we can restore if appropriate.
RTNDB.previous_records = {}

-- ####################################################################
-- ##                        Helper functions                        ##
-- ####################################################################

-- Get the current health of the entity, rounded down to an integer.
function RTN.GetTargetHealthPercentage()
	-- Find the current and maximum health of the current target.
	local max_hp = UnitHealthMax("target")
	
	-- Check for division by zero.
	if max_hp == 0 then
		return -1
	end
	
	return math.floor((100 * UnitHealth("target")) / UnitHealthMax("target"))
end

-- A print function used for debug purposes.
function RTN.Debug(...)
	if RTNDB.debug_enabled then
		print(...)
	end
end

-- Open and start the RTN interface and subscribe to all the required events.
function RTN:StartInterface()
	-- Reset the data, since we cannot guarantee its correctness.
	self.is_alive = {}
	self.current_health = {}
	self.last_recorded_death = {}
	self.current_coordinates = {}
	self.reported_spawn_uids = {}
	self.reported_vignettes = {}
	self.waypoints = {}
	self.current_shard_id = nil
	self:UpdateShardNumber(nil)
	self:UpdateAllDailyKillMarks()
	
	self:RegisterEvents()
	
	if RTNDB.minimap_icon_enabled then
		self.icon:Show("RTN_icon")
	else
		self.icon:Hide("RTN_icon")
	end
	
	if C_ChatInfo.RegisterAddonMessagePrefix("RTN") ~= true then
		print(L["<RTN> Failed to register AddonPrefix 'RTN'. RTN will not function properly."])
	end
	
	if RTNDB.show_window then
		self:Show()
	end
end

-- Open and start the RTN interface and unsubscribe to all the required events.
function RTN:CloseInterface()
	-- Reset the data.
	self.is_alive = {}
	self.current_health = {}
	self.last_recorded_death = {}
	self.current_coordinates = {}
	self.reported_spawn_uids = {}
	self.reported_vignettes = {}
	self.current_shard_id = nil
	self:UpdateShardNumber(nil)
	
	-- Register the user's departure and disable event listeners.
	self:RegisterDeparture(self.current_shard_id)
	self:UnregisterEvents()
	self.icon:Hide("RTN_icon")
	
	-- Hide the interface.
	self:Hide()
end

-- ####################################################################
-- ##                          Minimap Icon                          ##
-- ####################################################################

local RTN_LDB = LibStub("LibDataBroker-1.1"):NewDataObject("RTN_icon_object", {
	type = "data source",
	text = "RTN",
	icon = "Interface\\AddOns\\RareTrackerNazjatar\\Icons\\RareTrackerIcon",
	OnClick = function(_, button)
		if button == "LeftButton" then
			if RTN.last_zone_id and RTN.target_zones[RTN.last_zone_id] then
				if RTN:IsShown() then
					RTN:Hide()
					RTNDB.show_window = false
				else
					RTN:Show()
					RTNDB.show_window = true
				end
			end
		else
			InterfaceOptionsFrame_Show()
			InterfaceOptionsFrame_OpenToCategory(RTN.options_panel)
		end
	end,
	OnTooltipShow = function(tooltip)
		tooltip:SetText("RTN")
		tooltip:AddLine(L["Left-click: hide/show RTN"], 1, 1, 1)
		tooltip:AddLine(L["Right-click: show options"], 1, 1, 1)
		tooltip:Show()
	end
})

RTN.icon = LibStub("LibDBIcon-1.0")
RTN.icon:Hide("RTN_icon")

function RTN:RegisterMapIcon()
	self.ace_db = LibStub("AceDB-3.0"):New("RTN_ace_db", {
		profile = {
			minimap = {
				hide = false,
			},
		},
	})
	RTN.icon:Register("RTN_icon", RTN_LDB, self.ace_db.profile.minimap)
end


