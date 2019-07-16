local _, data = ...

-- ####################################################################
-- ##                              Core                              ##
-- ####################################################################

data.RTN = CreateFrame("Frame", "RTN", UIParent);
local RTN = data.RTN

-- The current data we have of the rares.
RTN.is_alive = {}
RTN.current_health = {}
RTN.last_recorded_death = {}
RTN.current_coordinates = {}

-- The zone_uid can be used to distinguish different shards of the zone.
RTN.current_shard_id = nil

-- An override to hide the interface initially (development).
RTN.hide_override = false

-- A table containing all UID deaths reported by the player.
RTN.recorded_entity_death_ids = {}

-- A table containing all vignette UIDs reported by the player.
RTN.reported_vignettes = {}

-- A table containing all spawn UIDs that have been reported through a sound warning.
RTN.reported_spawn_uids = {}

-- Sound file options.
local sound_options = {}
sound_options['none'] = -1
sound_options['Algalon: Beware!'] = 543587

-- The version of the addon.
RTN.version = 4
-- Version 2: changed the order of the rares.
-- Version 3: death messages now send the spawn id.
-- Version 4: changed the interface of the alive message to include coordinates.

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
function RTN:GetTargetHealthPercentage()
	-- Find the current and maximum health of the current target.
	local max_hp = UnitHealthMax("target")
	
	-- Check for division by zero.
	if max_hp == 0 then
		return -1
	end
	
	return math.floor((100 * UnitHealth("target")) / UnitHealthMax("target")) 
end

-- Open and start the RTN interface and subscribe to all the required events.
function RTN:StartInterface()
	-- Reset the data, since we cannot guarantee its correctness.
	RTN.is_alive = {}
	RTN.current_health = {}
	RTN.last_recorded_death = {}
	RTN.current_coordinates = {}
	RTN.reported_spawn_uids = {}
	RTN.reported_vignettes = {}
	RTN.waypoints = {}
	RTN.current_shard_id = nil
	RTN:UpdateShardNumber(nil)
	RTN:UpdateAllDailyKillMarks()
	
	RTN:RegisterEvents()
	RTN.icon:Show("RTN_icon")
	
	if C_ChatInfo.RegisterAddonMessagePrefix("RTN") ~= true then
		print("<RTN> Failed to register AddonPrefix 'RTN'. RTN will not function properly.")
	end
	
	if RTNDB.show_window then 
		RTN:Show()
	end
end

-- Open and start the RTN interface and unsubscribe to all the required events.
function RTN:CloseInterface()
	-- Reset the data.
	RTN.is_alive = {}
	RTN.current_health = {}
	RTN.last_recorded_death = {}
	RTN.current_coordinates = {}
	RTN.reported_spawn_uids = {}
	RTN.reported_vignettes = {}
	RTN.current_shard_id = nil
	RTN:UpdateShardNumber(nil)
	
	-- Register the user's departure and disable event listeners.
	RTN:RegisterDeparture(RTN.current_shard_id)
	RTN:UnregisterEvents()
	RTN.icon:Hide("RTN_icon")
	
	-- Hide the interface.
	RTN:Hide()
end

-- ####################################################################
-- ##                          Minimap Icon                          ##
-- ####################################################################

local RTN_LDB = LibStub("LibDataBroker-1.1"):NewDataObject("RTN_icon_object", {
	type = "data source",
	text = "RTN",
	icon = "Interface\\Icons\\inv_gizmo_goblingtonkcontroller",
	OnClick = function() 
		if RTN.last_zone_id and RTN.target_zones[RTN.last_zone_id] then
			if RTN:IsShown() then
				RTN:Hide()
				RTNDB.show_window = false
			else
				RTN:Show()
				RTNDB.show_window = true
			end
		end
	end,
	OnTooltipShow = function(tooltip)
		tooltip:SetText("RTN")
		tooltip:AddLine("Hide/Show RTN", 1, 1, 1)
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


