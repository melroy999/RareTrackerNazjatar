local _, data = ...

local RTN = data.RTN

-- ####################################################################
-- ##                         Event Handlers                         ##
-- ####################################################################

-- Listen to a given set of events and handle them accordingly.
function RTN:OnEvent(event, ...)
	if event == "PLAYER_TARGET_CHANGED" then
		RTN:OnTargetChanged(...)
	elseif event == "UNIT_HEALTH" then
		RTN:OnUnitHealth(...)
	elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
		RTN:OnCombatLogEvent(...)
	elseif event == "ZONE_CHANGED_NEW_AREA" or event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED" then
		RTN:OnZoneTransition()
	elseif event == "CHAT_MSG_CHANNEL" then
		RTN:OnChatMsgChannel(...)
	elseif event == "CHAT_MSG_ADDON" then
		RTN:OnChatMsgAddon(...)
	elseif event == "VIGNETTE_MINIMAP_UPDATED" then
		RTN:OnVignetteMinimapUpdated(...)
	elseif event == "ADDON_LOADED" then
		RTN:OnAddonLoaded()
	elseif event == "PLAYER_LOGOUT" then
		RTN:OnPlayerLogout()
	end
end

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

function RTN:CheckForShardChange(zone_uid)
	local has_changed = false

	if RTN.current_shard_id ~= zone_uid and zone_uid ~= nil then
		print("<RTN> Moving to shard", (zone_uid + 42)..".")
		RTN:UpdateShardNumber(zone_uid)
		
		if RTN.current_shard_id == nil then
			-- Register yourRTN for the given shard.
			RTN:RegisterArrival(zone_uid)
			has_changed = true
		else
			-- Move from one shard to another.
			RTN:ChangeShard(RTN.current_shard_id, zone_uid)
			has_changed = true
		end
		
		RTN.current_shard_id = zone_uid
	end
	
	return has_changed
end

function RTN:OnTargetChanged(...)
	if UnitGUID("target") ~= nil then
		-- Get information about the target.
		local guid, name = UnitGUID("target"), UnitName("target")
		local unittype, zero, server_id, instance_id, zone_uid, npc_id, spawn_uid = strsplit("-", guid);
		npc_id = tonumber(npc_id)
		
		RTN:CheckForShardChange(zone_uid)
		
		if RTN.rare_ids_set[npc_id] then
			-- Find the health of the entity.
			local health = UnitHealth("target")
			
			if health > 0 then
				local percentage = RTN:GetTargetHealthPercentage()
				
				RTN.is_alive[npc_id] = time()
				RTN.current_health[npc_id] = percentage
				RTN:UpdateStatus(npc_id)
				
				-- Get the current position of the player.
				local pos = C_Map.GetPlayerMapPosition(C_Map.GetBestMapForUnit("player"), "player")
				local x, y = math.floor(pos.x * 10000 + 0.5) / 100, math.floor(pos.y * 10000 + 0.5) / 100
				
				RTN:RegisterEntityTarget(RTN.current_shard_id, npc_id, spawn_uid, percentage, x, y)
			else 
				if RTN.recorded_entity_death_ids[spawn_uid] == nil then
					RTN.recorded_entity_death_ids[spawn_uid] = true
					RTN:RegisterEntityDeath(RTN.current_shard_id, npc_id)
				end
			end
		end
	end
end

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
		
		RTN:CheckForShardChange(zone_uid)
		
		if RTN.rare_ids_set[npc_id] then
			-- Update the current health of the entity.
			local percentage = RTN:GetTargetHealthPercentage()
			
			RTN.is_alive[npc_id] = time()
			RTN.current_health[npc_id] = percentage
			RTN:UpdateStatus(npc_id)
			
			RTN:RegisterEntityHealth(RTN.current_shard_id, npc_id, spawn_uid, percentage)
		end
	end
end

function RTN:OnCombatLogEvent(...)
	-- The event itRTN does not have a payload (8.0 change). Use CombatLogGetCurrentEventInfo() instead.
	local timestamp, subevent, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = CombatLogGetCurrentEventInfo()
	local unittype, zero, server_id, instance_id, zone_uid, npc_id, spawn_uid = strsplit("-", destGUID);
	local unittype2, _, _, _, zone_uid2, _, _ = strsplit("-", sourceGUID);
	npc_id = tonumber(npc_id)
	
	-- We can always check for a shard change.
	-- We only take fights between creatures, since they seem to be the only reliable option.
	if unittype == "Creature" and unittype2 == "Creature" and zone_uid == zone_uid2 then
		if RTN:CheckForShardChange(zone_uid) then
			print(sourceGUID, destGUID)
		end
	end	
		
	if subevent == "UNIT_DIED" then
		if RTN.rare_ids_set[npc_id] then
			if RTN.recorded_entity_death_ids[spawn_uid] == nil then
				RTN.recorded_entity_death_ids[spawn_uid] = true
				RTN:RegisterEntityDeath(RTN.current_shard_id, npc_id)
			end
		end
	end
end	

function RTN:OnZoneTransition()
	-- The zone the player is in.
	local zone_id = C_Map.GetBestMapForUnit("player")
		
	if RTN.target_zones[zone_id] and not RTN.target_zones[RTN.last_zone_id] then
		-- Enable the Nazjatar rares.
		RTN:StartInterface()
		
	elseif not RTN.target_zones[zone_id] then
		-- Disable the addon.
		
		-- If we do not have a shard ID, we are not subscribed to one of the channels.
		RTN:RegisterDeparture(RTN.current_shard_id)
		
		RTN:CloseInterface()
	end
	
	RTN.last_zone_id = zone_id
end	

function RTN:OnChatMsgChannel(...)
	local text, playerName, languageName, channelName, playerName2, specialFlags, zoneChannelID, channelIndex, channelBaseName, unused, lineID, guid, bnSenderID, isMobile, isSubtitle, hideSenderInLetterbox, supressRaidIcons = ...

end	

function RTN:OnChatMsgAddon(...)
	local addon_prefix, message, channel, sender = ...
	
	if addon_prefix == "RTN" then
		local header, payload = strsplit(":", message)
		local prefix, shard_id, addon_version_str = strsplit("-", header)
		local addon_version = tonumber(addon_version_str)

		RTN:OnChatMessageReceived(sender, prefix, shard_id, addon_version, payload)
	end
end	



function RTN:OnVignetteMinimapUpdated(...)
	vignetteGUID, onMinimap = ...
	vignetteInfo = C_VignetteInfo.GetVignetteInfo(vignetteGUID)
	
	if vignetteInfo == nil and RTN.current_shard_id ~= nil then
		-- An entity we saw earlier might have died.
		if RTN.reported_vignettes[vignetteGUID] then
			RTN:RegisterEntityDeath(RTN.current_shard_id, RTN.reported_vignettes[vignetteGUID])
		end
	else
		-- Report the entity.
		local unittype, zero, server_id, instance_id, zone_uid, npc_id, spawn_uid = strsplit("-", vignetteInfo.objectGUID);
		local npc_id = tonumber(npc_id)
		
		if unittype == "Creature" then
			RTN:CheckForShardChange(zone_uid)
			
			if RTN.rare_ids_set[npc_id] and not RTN.reported_vignettes[vignetteGUID] then
				RTN.is_alive[npc_id] = time()
				RTN.reported_vignettes[vignetteGUID] = npc_id
				RTN:RegisterEntityAlive(RTN.current_shard_id, npc_id, spawn_uid)
			end
		end
	end
end

RTN.last_display_update = 0

function RTN:OnUpdate()
	if (RTN.last_display_update + 0.25 < time()) then
		for i=1, #RTN.rare_ids do
			local npc_id = RTN.rare_ids[i]
			
			-- It might occur that the rare is marked as alive, but no health is known.
			-- If 20 seconds pass without a health value, the alive tag will be reset.
			if RTN.is_alive[npc_id] and not RTN.current_health[npc_id] and time() - RTN.is_alive[npc_id] > 20 then
				RTN.is_alive[npc_id] = nil
			end
			
			-- It might occur that we have both a hp and health, but no changes.
			-- If 2 minutes pass without a health value, the alive and health tags will be reset.
			if RTN.is_alive[npc_id] and RTN.current_health[npc_id] and time() - RTN.is_alive[npc_id] > 120 then
				RTN.is_alive[npc_id] = nil
				RTN.current_health[npc_id] = nil
			end
			
			RTN:UpdateStatus(npc_id)
		end
		
		RTN.last_display_update = time();
	end
end	

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
		
		-- Remove any data in the previous records that has expired.
		for key, _ in pairs(RTNDB.previous_records) do
			if time() - RTNDB.previous_records[key].time_stamp > 300 then
				print("<RTN> Removing cached data for shard", (key + 42)..".")
				RTNDB.previous_records[key] = nil
			end
		end
	end
end	

function RTN:OnPlayerLogout()
	if RTN.current_shard_id then
		RTNDB.previous_records[RTN.current_shard_id] = {}
		RTNDB.previous_records[RTN.current_shard_id].time_stamp = time()
		RTNDB.previous_records[RTN.current_shard_id].time_table = RTN.last_recorded_death
	end
end

function RTN:RegisterEvents()
	RTN:RegisterEvent("PLAYER_TARGET_CHANGED")
	RTN:RegisterEvent("UNIT_HEALTH")
	RTN:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	RTN:RegisterEvent("CHAT_MSG_CHANNEL")
	RTN:RegisterEvent("CHAT_MSG_ADDON")
	RTN:RegisterEvent("VIGNETTE_MINIMAP_UPDATED")
end

function RTN:UnregisterEvents()
	RTN:UnregisterEvent("PLAYER_TARGET_CHANGED")
	RTN:UnregisterEvent("UNIT_HEALTH")
	RTN:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	RTN:UnregisterEvent("CHAT_MSG_CHANNEL")
	RTN:UnregisterEvent("CHAT_MSG_ADDON")
	RTN:UnregisterEvent("VIGNETTE_MINIMAP_UPDATED")
end

RTN.updateHandler = CreateFrame("Frame", "RTN.updateHandler", RTN)
RTN.updateHandler:SetScript("OnUpdate", RTN.OnUpdate)

-- Register the event handling of the frame.
RTN:SetScript("OnEvent", RTN.OnEvent)
RTN:RegisterEvent("ZONE_CHANGED_NEW_AREA")
RTN:RegisterEvent("ZONE_CHANGED")
RTN:RegisterEvent("PLAYER_ENTERING_WORLD")
RTN:RegisterEvent("ADDON_LOADED")
RTN:RegisterEvent("PLAYER_LOGOUT")