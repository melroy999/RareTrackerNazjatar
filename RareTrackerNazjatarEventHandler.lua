local _, data = ...

local RTN = data.RTN

-- ####################################################################
-- ##                         Event Handlers                         ##
-- ####################################################################

-- Listen to a given set of events and handle them accordingly.
function RTN:OnEvent(event, ...)
	if event == "PLAYER_TARGET_CHANGED" then
		RTN:OnTargetChanged(...)
	elseif event == "UNIT_HEALTH" and RTN.chat_frame_loaded then
		RTN:OnUnitHealth(...)
	elseif event == "COMBAT_LOG_EVENT_UNFILTERED" and RTN.chat_frame_loaded then
		RTN:OnCombatLogEvent(...)
	elseif event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED" then
		RTN:OnZoneTransition()
	elseif event == "CHAT_MSG_ADDON" then
		RTN:OnChatMsgAddon(...)
	elseif event == "VIGNETTE_MINIMAP_UPDATED" and RTN.chat_frame_loaded then
		RTN:OnVignetteMinimapUpdated(...)
	elseif event == "ADDON_LOADED" then
		RTN:OnAddonLoaded()
	elseif event == "PLAYER_LOGOUT" then
		RTN:OnPlayerLogout()	
	end
end

-- Change from the original shard to the other.
function RTN:ChangeShard(old_zone_uid, new_zone_uid)
	-- Notify the users in your old shard that you have moved on to another shard.
	RTN:RegisterDeparture(old_zone_uid)
	
	-- Reset all the data we have, since it has all become useless.
	RTN.is_alive = {}
	RTN.current_health = {}
	RTN.last_recorded_death = {}
	RTN.recorded_entity_death_ids = {}
	RTN.current_coordinates = {}
	RTN.reported_spawn_uids = {}
	RTN.reported_vignettes = {}
	
	-- Announce your arrival in the new shard.
	RTN:RegisterArrival(new_zone_uid)
end

-- Check whether the user has changed shards and proceed accordingly.
function RTN:CheckForShardChange(zone_uid)
	local has_changed = false

	if RTN.current_shard_id ~= zone_uid and zone_uid ~= nil then
		print("<RTN> Moving to shard", (zone_uid + 42)..".")
		RTN:UpdateShardNumber(zone_uid)
		has_changed = true
		
		if RTN.current_shard_id == nil then
			-- Register yourRTN for the given shard.
			RTN:RegisterArrival(zone_uid)
		else
			-- Move from one shard to another.
			RTN:ChangeShard(RTN.current_shard_id, zone_uid)
		end
		
		RTN.current_shard_id = zone_uid
	end
	
	return has_changed
end

-- Called when a target changed event is fired.
function RTN:OnTargetChanged(...)
	if UnitGUID("target") ~= nil then
		-- Get information about the target.
		local guid, name = UnitGUID("target"), UnitName("target")
		local unittype, zero, server_id, instance_id, zone_uid, npc_id, spawn_uid = strsplit("-", guid);
		npc_id = tonumber(npc_id)
		
		if RTN:CheckForShardChange(zone_uid) then
			RTN:Debug("[Target]", guid)
		end
		
		if RTN.rare_ids_set[npc_id] then
			-- Find the health of the entity.
			local health = UnitHealth("target")
			
			if health > 0 then
				-- Get the current position of the player and the health of the entity.
				local pos = C_Map.GetPlayerMapPosition(C_Map.GetBestMapForUnit("player"), "player")
				local x, y = math.floor(pos.x * 10000 + 0.5) / 100, math.floor(pos.y * 10000 + 0.5) / 100
				local percentage = RTN:GetTargetHealthPercentage()
				
				-- Mark the entity as alive and report to your peers.
				RTN:RegisterEntityTarget(RTN.current_shard_id, npc_id, spawn_uid, percentage, x, y)
			else 
				-- Mark the entity has dead and report to your peers.
				RTN:RegisterEntityDeath(RTN.current_shard_id, npc_id, spawn_uid)
			end
		end
	end
end

-- Called when a unit health update event is fired.
function RTN:OnUnitHealth(unit)
	-- If the unit is not the target, skip.
	if unit ~= "target" then 
		return 
	end
	
	if UnitGUID("target") ~= nil then
		-- Get information about the target.
		local guid, name = UnitGUID("target"), UnitName("target")
		local unittype, zero, server_id, instance_id, zone_uid, npc_id, spawn_uid = strsplit("-", guid);
		npc_id = tonumber(npc_id)
		
		if RTN:CheckForShardChange(zone_uid) then
			RTN:Debug("[OnUnitHealth]", guid)
		end
		
		if RTN.rare_ids_set[npc_id] then
			-- Update the current health of the entity.
			local percentage = RTN:GetTargetHealthPercentage()
			
			-- Does the entity have any health left?
			if percentage > 0 then
				-- Report the health of the entity to your peers.
				RTN:RegisterEntityHealth(RTN.current_shard_id, npc_id, spawn_uid, percentage)
			else
				-- Mark the entity has dead and report to your peers.
				RTN:RegisterEntityDeath(RTN.current_shard_id, npc_id, spawn_uid)
			end
		end
	end
end

-- The flag used to detect guardians or pets.
local flag_mask = bit.bor(COMBATLOG_OBJECT_TYPE_GUARDIAN, COMBATLOG_OBJECT_TYPE_PET, COMBATLOG_OBJECT_TYPE_OBJECT)

-- Called when a unit health update event is fired.
function RTN:OnCombatLogEvent(...)
	-- The event does not have a payload (8.0 change). Use CombatLogGetCurrentEventInfo() instead.
	local timestamp, subevent, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = CombatLogGetCurrentEventInfo()
	local unittype, zero, server_id, instance_id, zone_uid, npc_id, spawn_uid = strsplit("-", destGUID);
	npc_id = tonumber(npc_id)
	
	-- We can always check for a shard change.
	-- We only take fights between creatures, since they seem to be the only reliable option.
	-- We exclude all pets and guardians, since they might have retained their old shard change.
	if unittype == "Creature" and not RTN.banned_NPC_ids[npc_id] and bit.band(destFlags, flag_mask) == 0 then
		if RTN:CheckForShardChange(zone_uid) then
			RTN:Debug("[OnCombatLogEvent]", sourceGUID, destGUID)
		end
	end	
		
	if subevent == "UNIT_DIED" then
		if RTN.rare_ids_set[npc_id] then
			-- Mark the entity has dead and report to your peers.
			RTN:RegisterEntityDeath(RTN.current_shard_id, npc_id, spawn_uid)
		end
	end
end	

-- Called when a vignette on the minimap is updated.
function RTN:OnVignetteMinimapUpdated(...)
	vignetteGUID, onMinimap = ...
	vignetteInfo = C_VignetteInfo.GetVignetteInfo(vignetteGUID)
	vignetteLocation = C_VignetteInfo.GetVignettePosition(vignetteGUID, C_Map.GetBestMapForUnit("player"))
	
	if not vignetteInfo and RTN.current_shard_id ~= nil then
		-- An entity we saw earlier might have died.
		if RTN.reported_vignettes[vignetteGUID] then
			-- Fetch the npc_id and spawn_uid from our cached data.
			npc_id, spawn_uid = RTN.reported_vignettes[vignetteGUID][1], RTN.reported_vignettes[vignetteGUID][2]
		
			-- Mark the entity has dead and report to your peers.
			RTN:RegisterEntityDeath(RTN.current_shard_id, npc_id, spawn_uid)
		end
	elseif vignetteInfo then
		-- Report the entity.
		local unittype, zero, server_id, instance_id, zone_uid, npc_id, spawn_uid = strsplit("-", vignetteInfo.objectGUID);
		local npc_id = tonumber(npc_id)
		
		if unittype == "Creature" then
			if RTN:CheckForShardChange(zone_uid) then
				RTN:Debug("[OnVignette]", vignetteInfo.objectGUID)
			end
			
			if RTN.rare_ids_set[npc_id] and not RTN.reported_vignettes[vignetteGUID] then
				RTN.reported_vignettes[vignetteGUID] = {npc_id, spawn_uid}
				
				local x, y = 100 * vignetteLocation.x, 100 * vignetteLocation.y
				RTN:RegisterEntityAlive(RTN.current_shard_id, npc_id, spawn_uid, x, y)
			end
		end
	end
end

-- Called whenever an event occurs that could indicate a zone change.
function RTN:OnZoneTransition()
	-- The zone the player is in.
	local zone_id = C_Map.GetBestMapForUnit("player")
		
	if RTN.target_zones[zone_id] and not RTN.target_zones[RTN.last_zone_id] then
		RTN:StartInterface()	
	elseif not RTN.target_zones[zone_id] then
		RTN:RegisterDeparture(RTN.current_shard_id)
		RTN:CloseInterface()
	end
	
	RTN.last_zone_id = zone_id
end	

-- Called on every addon message received by the addon.
function RTN:OnChatMsgAddon(...)
	local addon_prefix, message, channel, sender = ...

	if addon_prefix == "RTN" then
		local header, payload = strsplit(":", message)
		local prefix, shard_id, addon_version_str = strsplit("-", header)
		local addon_version = tonumber(addon_version_str)

		RTN:OnChatMessageReceived(sender, prefix, shard_id, addon_version, payload)
	end
end	

-- A counter that tracks the time stamp on which the displayed data was updated last. 
RTN.last_display_update = 0

-- Called on every addon message received by the addon.
function RTN:OnUpdate()
	if (RTN.last_display_update + 0.25 < GetServerTime()) then
		for i=1, #RTN.rare_ids do
			local npc_id = RTN.rare_ids[i]
			
			-- It might occur that the rare is marked as alive, but no health is known.
			-- If 20 seconds pass without a health value, the alive tag will be reset.
			if RTN.is_alive[npc_id] and not RTN.current_health[npc_id] and GetServerTime() - RTN.is_alive[npc_id] > 120 then
				RTN.is_alive[npc_id] = nil
			end
			
			-- It might occur that we have both a hp and health, but no changes.
			-- If 2 minutes pass without a health value, the alive and health tags will be reset.
			if RTN.is_alive[npc_id] and RTN.current_health[npc_id] and GetServerTime() - RTN.is_alive[npc_id] > 120 then
				RTN.is_alive[npc_id] = nil
				RTN.current_health[npc_id] = nil
			end
			
			RTN:UpdateStatus(npc_id)
		end
		
		RTN.last_display_update = GetServerTime();
	end
end	

-- Called when the addon loaded event is fired.
function RTN:OnAddonLoaded()
	-- OnAddonLoaded might be called multiple times. We only want it to do so once.
	if not RTN.is_loaded then
		self:CorrectFavoriteMarks()
		self:RegisterMapIcon()
		RTN.is_loaded = true
		
		if RTNDB.show_window == nil then
			RTNDB.show_window = true
		end
		
		if not RTNDB.favorite_rares then
			RTNDB.favorite_rares = {}
		end
		
		if not RTNDB.previous_records then
			RTNDB.previous_records = {}
		end
		
		if not RTNDB.selected_sound_number then
			RTNDB.selected_sound_number = 552503
		end
		
		if RTNDB.minimap_icon_enabled == nil then
			RTNDB.minimap_icon_enabled = true
		end
		
		if RTNDB.debug_enabled == nil then
			RTNDB.debug_enabled = false
		end
		
		-- Initialize the configuration menu.
		RTN:InitializeConfigMenu()
		
		-- Remove any data in the previous records that has expired.
		for key, _ in pairs(RTNDB.previous_records) do
			if GetServerTime() - RTNDB.previous_records[key].time_stamp > 300 then
				print("<RTN> Removing cached data for shard", (key + 42)..".")
				RTNDB.previous_records[key] = nil
			end
		end
	end
end	

-- Called when the player logs out, such that we can save the current time table for later use.
function RTN:OnPlayerLogout()
	if RTN.current_shard_id then
		-- Save the records, such that we can use them after a reload.
		RTNDB.previous_records[RTN.current_shard_id] = {}
		RTNDB.previous_records[RTN.current_shard_id].time_stamp = GetServerTime()
		RTNDB.previous_records[RTN.current_shard_id].time_table = RTN.last_recorded_death
	end
end

-- Register to the events required for the addon to function properly.
function RTN:RegisterEvents()
	RTN:RegisterEvent("PLAYER_TARGET_CHANGED")
	RTN:RegisterEvent("UNIT_HEALTH")
	RTN:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	RTN:RegisterEvent("CHAT_MSG_ADDON")
	RTN:RegisterEvent("VIGNETTE_MINIMAP_UPDATED")
end

-- Unregister from the events, to disable the tracking functionality.
function RTN:UnregisterEvents()
	RTN:UnregisterEvent("PLAYER_TARGET_CHANGED")
	RTN:UnregisterEvent("UNIT_HEALTH")
	RTN:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	RTN:UnregisterEvent("CHAT_MSG_ADDON")
	RTN:UnregisterEvent("VIGNETTE_MINIMAP_UPDATED")
end

-- Create a frame that handles the frame updates of the addon.
RTN.updateHandler = CreateFrame("Frame", "RTN.updateHandler", RTN)
RTN.updateHandler:SetScript("OnUpdate", RTN.OnUpdate)

-- Register the event handling of the frame.
RTN:SetScript("OnEvent", RTN.OnEvent)
RTN:RegisterEvent("ZONE_CHANGED_NEW_AREA")
RTN:RegisterEvent("ZONE_CHANGED")
RTN:RegisterEvent("PLAYER_ENTERING_WORLD")
RTN:RegisterEvent("ADDON_LOADED")
RTN:RegisterEvent("PLAYER_LOGOUT")

-- ####################################################################
-- ##                       Channel Wait Frame                       ##
-- ####################################################################

-- One of the issues encountered is that the chat might be joined before the default channels.
-- In such a situation, the order of the channels changes, which is undesirable.
-- Thus, we block certain events until these chats have been loaded.
RTN.chat_frame_loaded = false

RTN.message_delay_frame = CreateFrame("Frame", "RTN.message_delay_frame", self)
RTN.message_delay_frame.start_time = GetServerTime()
RTN.message_delay_frame:SetScript("OnUpdate", 
	function(self)
		if GetServerTime() - self.start_time > 0 then
			if #{GetChannelList()} == 0 then
				self.start_time = GetServerTime()
			else
				RTN.chat_frame_loaded = true
				self:SetScript("OnUpdate", nil)
				self:Hide()
			end
		end
	end
)
RTN.message_delay_frame:Show()
