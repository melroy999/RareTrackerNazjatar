local _, data = ...

local RTN = data.RTN

-- ####################################################################
-- ##                         Communication                          ##
-- ####################################################################

-- The time at which you broad-casted the joined the shard group.
RTN.arrival_register_time = nil

-- The name and realm of the player.
local player_name = UnitName("player").."-"..GetRealmName()

-- A flag that ensures that the version warning is only given once per session.
local reported_version_mismatch = false

-- The name of the current channel.
local channel_name = nil

-- The last time the health of an entity has been reported.
-- Used for limiting the number of messages sent to the channel.
RTN.last_health_report = {}
RTN.last_health_report["CHANNEL"] = {}
RTN.last_health_report["RAID"] = {}

-- ####################################################################
-- ##                        Helper Functions                        ##
-- ####################################################################

-- A time stamp at which the last message was sent in the rate limited message sender.
RTN.last_message_sent = {}
RTN.last_message_sent["CHANNEL"] = 0
RTN.last_message_sent["RAID"] = 0

-- A function that acts as a rate limiter for channel messages.
function RTN:SendRateLimitedAddonMessage(message, target, target_id, target_channel)
	-- We only allow one message to be sent every ~4 seconds.
	if GetServerTime() - RTN.last_message_sent[target_channel] > 4 then
		C_ChatInfo.SendAddonMessage("RTN", message, target, target_id)
		RTN.last_message_sent[target_channel] = GetServerTime()
	end
end

-- Compress all the kill data the user has to Base64.
function RTN:GetCompressedSpawnData(time_stamp)
	local data = ""
	
	for i=1, #RTN.rare_ids do
		local npc_id = RTN.rare_ids[i]
		local kill_time = RTN.last_recorded_death[npc_id]
		
		if kill_time ~= nil then
			data = data..RTN:toBase64(time_stamp - kill_time)..","
		else
			data = data..RTN:toBase64(0)..","
		end
	end
	
	return data:sub(1, #data - 1)
end

-- Decompress all the Base64 data sent by a peer to decimal and update the timers.
function RTN:DecompressSpawnData(spawn_data, time_stamp)
	local spawn_data_entries = {strsplit(",", spawn_data, #RTN.rare_ids)}

	for i=1, #RTN.rare_ids do
		local npc_id = RTN.rare_ids[i]
		local kill_time = RTN:toBase10(spawn_data_entries[i])
		
		if kill_time ~= 0 then
			if RTN.last_recorded_death[npc_id] then
				-- If we already have an entry, take the minimal.
				if time_stamp - kill_time < RTN.last_recorded_death[npc_id] then
					RTN.last_recorded_death[npc_id] = time_stamp - kill_time
				end
			else
				RTN.last_recorded_death[npc_id] = time_stamp - kill_time
			end
		end
	end
end

-- A function that enables the delayed execution of a function.
function RTN:DelayedExecution(delay, _function)
	local frame = CreateFrame("Frame", "RTN.message_delay_frame", self)
	frame.start_time = GetServerTime()
	frame:SetScript("OnUpdate", 
		function(self)
			if GetServerTime() - self.start_time > delay then
				_function()
				self:SetScript("OnUpdate", nil)
				self:Hide()
			end
		end
	)
	frame:Show()
end

-- ####################################################################
-- ##            Shard Group Management Register Functions           ##
-- ####################################################################

-- Inform other clients of your arrival.
function RTN:RegisterArrival(shard_id)
	-- Attempt to load previous data from our cache.
	if RTNDB.previous_records[shard_id] then
		if GetServerTime() - RTNDB.previous_records[shard_id].time_stamp < 900 then
			print("<RTN> Restoring data from previous session in shard "..(shard_id + 42)..".")
			RTN.last_recorded_death = RTNDB.previous_records[shard_id].time_table
		else
			RTNDB.previous_records[shard_id] = nil
		end
	end

	RTN.channel_name = "RTN"..shard_id
	
	local is_in_channel = false
	if select(1, GetChannelName(RTN.channel_name)) ~= 0 then
		is_in_channel = true
	end

	-- Announce to the others that you have arrived.
	RTN.arrival_register_time = GetServerTime()
	RTN.rare_table_updated = false
		
	if not is_in_channel then
		-- Join the appropriate channel.
		JoinTemporaryChannel(RTN.channel_name)		
		
		-- We want to avoid overwriting existing channel numbers. So delay the channel join.
		RTN:DelayedExecution(1, function()
				print("<RTN> Requesting rare kill data for shard "..(shard_id + 42)..".")
				C_ChatInfo.SendAddonMessage("RTN", "A-"..shard_id.."-"..RTN.version..":"..RTN.arrival_register_time, "CHANNEL", select(1, GetChannelName(RTN.channel_name)))
			end
		)
	else
		C_ChatInfo.SendAddonMessage("RTN", "A-"..shard_id.."-"..RTN.version..":"..RTN.arrival_register_time, "CHANNEL", select(1, GetChannelName(RTN.channel_name)))
	end
	
	-- Register your arrival within the group.
	if RTNDB.enable_raid_communication and (UnitInRaid("player") or UnitInParty("player")) then
		C_ChatInfo.SendAddonMessage("RTN", "AP-"..shard_id.."-"..RTN.version..":"..RTN.arrival_register_time, "RAID", nil)
	end
end

-- Inform the others that you are still present and give them your data.
function RTN:RegisterPresenceWhisper(shard_id, target, time_stamp)
	if next(RTN.last_recorded_death) ~= nil then
		-- Announce to the others that you are still present on the shard.
		C_ChatInfo.SendAddonMessage("RTN", "PW-"..shard_id.."-"..RTN.version..":"..RTN:GetCompressedSpawnData(time_stamp), "WHISPER", target)
	end
end

-- Inform the others that you are still present and give them your data through the group/raid channel.
function RTN:RegisterPresenceGroup(shard_id, target, time_stamp)
	if next(RTN.last_recorded_death) ~= nil then
		-- Announce to the others that you are still present on the shard.
		C_ChatInfo.SendAddonMessage("RTN", "PP-"..shard_id.."-"..RTN.version..":"..RTN:GetCompressedSpawnData(time_stamp).."-"..time_stamp, "RAID", nil)
	end
end

--Leave the channel.
function RTN:RegisterDeparture(shard_id)
	local n_channels = GetNumDisplayChannels()
	local channels_to_leave = {}
	
	-- Leave all channels with an RTN prefix.
	for i = 1, n_channels do
		local _, channel_name = GetChannelName(i)
		if channel_name and channel_name:find("RTN") then
			channels_to_leave[channel_name] = true
		end
	end
	
	for channel_name, _ in pairs(channels_to_leave) do
		LeaveChannelByName(channel_name)
	end
	
	-- Store any timer data we previously had in the saved variables.
	if shard_id then
		RTNDB.previous_records[shard_id] = {}
		RTNDB.previous_records[shard_id].time_stamp = GetServerTime()
		RTNDB.previous_records[shard_id].time_table = RTN.last_recorded_death
	end
end

-- ####################################################################
-- ##          Shard Group Management Acknowledge Functions          ##
-- ####################################################################

-- Acknowledge that the player has arrived and whisper your data table.
function RTN:AcknowledgeArrival(player, time_stamp)
	-- Notify the newly arrived user of your presence through a whisper.
	if player_name ~= player then
		RTN:RegisterPresenceWhisper(RTN.current_shard_id, player, time_stamp)
	end	
end

-- Acknowledge that the player has arrived and whisper your data table.
function RTN:AcknowledgeArrivalGroup(player, time_stamp)
	-- Notify the newly arrived user of your presence through a whisper.
	if player_name ~= player then
		if RTNDB.enable_raid_communication and (UnitInRaid("player") or UnitInParty("player")) then
			RTN:RegisterPresenceGroup(RTN.current_shard_id, player, time_stamp)
		end
	end	
end

-- Acknowledge the welcome message of other players and parse and import their tables.
function RTN:AcknowledgePresence(player, spawn_data)
	RTN:DecompressSpawnData(spawn_data, RTN.arrival_register_time)
end

-- ####################################################################
-- ##               Entity Information Share Functions               ##
-- ####################################################################

-- Inform the others that a specific entity has died.
function RTN:RegisterEntityDeath(shard_id, npc_id, spawn_uid)
	if not RTN.recorded_entity_death_ids[spawn_uid..npc_id] then
		-- Mark the entity as dead.
		RTN.last_recorded_death[npc_id] = GetServerTime()
		RTN.is_alive[npc_id] = nil
		RTN.current_health[npc_id] = nil
		RTN.current_coordinates[npc_id] = nil
		RTN.recorded_entity_death_ids[spawn_uid..npc_id] = true
		
		-- We want to avoid overwriting existing channel numbers. So delay the channel join.
		RTN:DelayedExecution(3, function() RTN:UpdateDailyKillMark(npc_id) end)
		
		-- Send the death message.
		C_ChatInfo.SendAddonMessage("RTN", "ED-"..shard_id.."-"..RTN.version..":"..npc_id.."-"..spawn_uid, "CHANNEL", select(1, GetChannelName(RTN.channel_name)))
	
		if RTNDB.enable_raid_communication and (UnitInRaid("player") or UnitInParty("player")) then
			C_ChatInfo.SendAddonMessage("RTN", "EDP-"..shard_id.."-"..RTN.version..":"..npc_id.."-"..spawn_uid, "RAID", nil)
		end
	end
end

-- Inform the others that you have spotted an alive entity.
function RTN:RegisterEntityAlive(shard_id, npc_id, spawn_uid, x, y)
	if RTN.recorded_entity_death_ids[spawn_uid..npc_id] == nil then
		-- Mark the entity as alive.
		RTN.is_alive[npc_id] = GetServerTime()
	
		-- Send the alive message.
		if x and y then 
			RTN.current_coordinates[npc_id] = {}
			RTN.current_coordinates[npc_id].x = x
			RTN.current_coordinates[npc_id].y = y
			C_ChatInfo.SendAddonMessage("RTN", "EA-"..shard_id.."-"..RTN.version..":"..npc_id.."-"..spawn_uid.."-"..x.."-"..y, "CHANNEL", select(1, GetChannelName(RTN.channel_name)))
		
			if RTNDB.enable_raid_communication and (UnitInRaid("player") or UnitInParty("player")) then
				C_ChatInfo.SendAddonMessage("RTN", "EAP-"..shard_id.."-"..RTN.version..":"..npc_id.."-"..spawn_uid.."-"..x.."-"..y, "RAID", nil)
			end
		else
			C_ChatInfo.SendAddonMessage("RTN", "EA-"..shard_id.."-"..RTN.version..":"..npc_id.."-"..spawn_uid.."--", "CHANNEL", select(1, GetChannelName(RTN.channel_name)))
		
			if RTNDB.enable_raid_communication and (UnitInRaid("player") or UnitInParty("player")) then
				C_ChatInfo.SendAddonMessage("RTN", "EAP-"..shard_id.."-"..RTN.version..":"..npc_id.."-"..spawn_uid.."--", "RAID", nil)
			end
		end
	end
end

-- Inform the others that you have spotted an alive entity.
function RTN:RegisterEntityTarget(shard_id, npc_id, spawn_uid, percentage, x, y)
	if RTN.recorded_entity_death_ids[spawn_uid..npc_id] == nil then
		-- Mark the entity as targeted and alive.
		RTN.is_alive[npc_id] = GetServerTime()
		RTN.current_health[npc_id] = percentage
		RTN.current_coordinates[npc_id] = {}
		RTN.current_coordinates[npc_id].x = x
		RTN.current_coordinates[npc_id].y = y
		RTN:UpdateStatus(npc_id)
	
		-- Send the target message.
		C_ChatInfo.SendAddonMessage("RTN", "ET-"..shard_id.."-"..RTN.version..":"..npc_id.."-"..spawn_uid.."-"..percentage.."-"..x.."-"..y, "CHANNEL", select(1, GetChannelName(RTN.channel_name)))
		
		if RTNDB.enable_raid_communication and (UnitInRaid("player") or UnitInParty("player")) then
			C_ChatInfo.SendAddonMessage("RTN", "ETP-"..shard_id.."-"..RTN.version..":"..npc_id.."-"..spawn_uid.."-"..percentage.."-"..x.."-"..y, "RAID", nil)
		end
	end
end

-- Inform the others the health of a specific entity.
function RTN:RegisterEntityHealth(shard_id, npc_id, spawn_uid, percentage)
	if not RTN.last_health_report["CHANNEL"][npc_id] or GetServerTime() - RTN.last_health_report["CHANNEL"][npc_id] > 2 then
		-- Mark the entity as targeted and alive.
		RTN.is_alive[npc_id] = GetServerTime()
		RTN.current_health[npc_id] = percentage
		RTN:UpdateStatus(npc_id)
	
		-- Send the health message, using a rate limited function.
		RTN:SendRateLimitedAddonMessage("EH-"..shard_id.."-"..RTN.version..":"..npc_id.."-"..spawn_uid.."-"..percentage, "CHANNEL", select(1, GetChannelName(RTN.channel_name)), "CHANNEL")
	end
	
	if RTNDB.enable_raid_communication and (UnitInRaid("player") or UnitInParty("player")) then
		if not RTN.last_health_report["RAID"][npc_id] or GetServerTime() - RTN.last_health_report["RAID"][npc_id] > 2 then
			-- Mark the entity as targeted and alive.
			RTN.is_alive[npc_id] = GetServerTime()
			RTN.current_health[npc_id] = percentage
			RTN:UpdateStatus(npc_id)
		
			-- Send the health message, using a rate limited function.
			RTN:SendRateLimitedAddonMessage("EHP-"..shard_id.."-"..RTN.version..":"..npc_id.."-"..spawn_uid.."-"..percentage, "RAID", nil, "RAID")
		end
	end
end

-- Acknowledge that the entity has died and set the according flags.
function RTN:AcknowledgeEntityDeath(npc_id, spawn_uid)	
	if not RTN.recorded_entity_death_ids[spawn_uid..npc_id] then
		-- Mark the entity as dead.
		RTN.last_recorded_death[npc_id] = GetServerTime()
		RTN.is_alive[npc_id] = nil
		RTN.current_health[npc_id] = nil
		RTN.current_coordinates[npc_id] = nil
		RTN.recorded_entity_death_ids[spawn_uid..npc_id] = true
		RTN:UpdateStatus(npc_id)
		RTN:DelayedExecution(3, function() RTN:UpdateDailyKillMark(npc_id) end)
	end

	if RTN.waypoints[npc_id] and TomTom then
		TomTom:RemoveWaypoint(RTN.waypoints[npc_id])
		RTN.waypoints[npc_id] = nil
	end
end

-- Acknowledge that the entity is alive and set the according flags.
function RTN:AcknowledgeEntityAlive(npc_id, spawn_uid, x, y)
	if not RTN.recorded_entity_death_ids[spawn_uid..npc_id] then
		RTN.is_alive[npc_id] = GetServerTime()
		RTN:UpdateStatus(npc_id)
		
		if x and y then
			RTN.current_coordinates[npc_id] = {}
			RTN.current_coordinates[npc_id].x = x
			RTN.current_coordinates[npc_id].y = y
		end
		
		if RTNDB.favorite_rares[npc_id] and not RTN.reported_spawn_uids[spawn_uid] then
			-- Play a sound file.
			PlaySoundFile(RTNDB.selected_sound_number)
			RTN.reported_spawn_uids[spawn_uid] = true
		end
	end
end

-- Acknowledge that the entity is alive and set the according flags.
function RTN:AcknowledgeEntityTarget(npc_id, spawn_uid, percentage, x, y)
	if not RTN.recorded_entity_death_ids[spawn_uid..npc_id] then
		RTN.last_recorded_death[npc_id] = nil
		RTN.is_alive[npc_id] = GetServerTime()
		RTN.current_health[npc_id] = percentage
		RTN.current_coordinates[npc_id] = {}
		RTN.current_coordinates[npc_id].x = x
		RTN.current_coordinates[npc_id].y = y
		RTN:UpdateStatus(npc_id)
		
		if RTNDB.favorite_rares[npc_id] and not RTN.reported_spawn_uids[spawn_uid] then
			-- Play a sound file.
			PlaySoundFile(RTNDB.selected_sound_number)
			RTN.reported_spawn_uids[spawn_uid] = true
		end
	end
end

-- Acknowledge the health change of the entity and set the according flags.
function RTN:AcknowledgeEntityHealth(npc_id, spawn_uid, percentage)
	if not RTN.recorded_entity_death_ids[spawn_uid..npc_id] then
		RTN.last_recorded_death[npc_id] = nil
		RTN.is_alive[npc_id] = GetServerTime()
		RTN.current_health[npc_id] = percentage
		RTN.last_health_report["CHANNEL"][npc_id] = GetServerTime()
		RTN:UpdateStatus(npc_id)
		
		if RTNDB.favorite_rares[npc_id] and not RTN.reported_spawn_uids[spawn_uid] then
			-- Play a sound file.
			PlaySoundFile(RTNDB.selected_sound_number)
			RTN.reported_spawn_uids[spawn_uid] = true
		end
	end
end

-- Acknowledge the health change of the entity and set the according flags.
function RTN:AcknowledgeEntityHealthRaid(npc_id, spawn_uid, percentage)
	if not RTN.recorded_entity_death_ids[spawn_uid..npc_id] then
		RTN.last_recorded_death[npc_id] = nil
		RTN.is_alive[npc_id] = GetServerTime()
		RTN.current_health[npc_id] = percentage
		RTN.last_health_report["RAID"][npc_id] = GetServerTime()
		RTN:UpdateStatus(npc_id)
		
		if RTNDB.favorite_rares[npc_id] and not RTN.reported_spawn_uids[spawn_uid] then
			-- Play a sound file.
			PlaySoundFile(RTNDB.selected_sound_number)
			RTN.reported_spawn_uids[spawn_uid] = true
		end
	end
end

-- ####################################################################
-- ##                      Core Chat Management                      ##
-- ####################################################################

-- Determine what to do with the received chat message.
function RTN:OnChatMessageReceived(player, prefix, shard_id, addon_version, payload)
	-- The format of messages might change over time and as such, versioning is needed.
	-- To ensure optimal performance, all users should use the latest version.
	if not reported_version_mismatch and RTN.version < addon_version and addon_version ~= 9001 then
		print("<RTN> Your version or RareTrackerNazjatar is outdated. Please update to the most recent version at the earliest convenience.")
		reported_version_mismatch = true
	end
	
	RTN:Debug(player, prefix, shard_id, addon_version, payload)
	
	-- Only allow communication if the users are on the same shards and if their addon version is equal.
	if RTN.current_shard_id == shard_id and RTN.version == addon_version then
		if prefix == "A" then
			time_stamp = tonumber(payload)
			RTN:AcknowledgeArrival(player, time_stamp)
		elseif prefix == "PW" then
			RTN:AcknowledgePresence(player, payload)
		elseif prefix == "ED" then
			local npcs_id_str, spawn_uid = strsplit("-", payload)
			local npc_id = tonumber(npcs_id_str)
			RTN:AcknowledgeEntityDeath(npc_id, spawn_uid)
		elseif prefix == "EA" then
			local npcs_id_str, spawn_uid, x_str, y_str = strsplit("-", payload)
			local npc_id, x, y = tonumber(npcs_id_str), tonumber(x_str), tonumber(y_str)
			RTN:AcknowledgeEntityAlive(npc_id, spawn_uid, x, y)
		elseif prefix == "ET" then
			local npc_id_str, spawn_uid, percentage_str, x_str, y_str = strsplit("-", payload)
			local npc_id, percentage, x, y = tonumber(npc_id_str), tonumber(percentage_str), tonumber(x_str), tonumber(y_str)
			RTN:AcknowledgeEntityTarget(npc_id, spawn_uid, percentage, x, y)
		elseif prefix == "EH" then
			local npc_id_str, spawn_uid, percentage_str = strsplit("-", payload)
			local npc_id, percentage = tonumber(npc_id_str), tonumber(percentage_str)
			RTN:AcknowledgeEntityHealth(npc_id, spawn_uid, percentage)
		elseif RTNDB.enable_raid_communication then
			if prefix == "AP" then
				time_stamp = tonumber(payload)
				RTN:AcknowledgeArrivalGroup(player, time_stamp)
			elseif prefix == "PP" then
				local payload, arrival_time_str = strsplit("-", payload)
				local arrival_time = tonumber(arrival_time_str)
				if RTN.arrival_register_time == arrival_time then
					RTN:AcknowledgePresence(player, payload)	
				end
			elseif prefix == "EDP" then
				local npcs_id_str, spawn_uid = strsplit("-", payload)
				local npc_id = tonumber(npcs_id_str)
				RTN:AcknowledgeEntityDeath(npc_id, spawn_uid)	
			elseif prefix == "EAP" then
				local npcs_id_str, spawn_uid, x_str, y_str = strsplit("-", payload)
				local npc_id, x, y = tonumber(npcs_id_str), tonumber(x_str), tonumber(y_str)
				RTN:AcknowledgeEntityAlive(npc_id, spawn_uid, x, y)
			elseif prefix == "ETP" then
				local npc_id_str, spawn_uid, percentage_str, x_str, y_str = strsplit("-", payload)
				local npc_id, percentage, x, y = tonumber(npc_id_str), tonumber(percentage_str), tonumber(x_str), tonumber(y_str)
				RTN:AcknowledgeEntityTarget(npc_id, spawn_uid, percentage, x, y)
			elseif prefix == "EHP" then
				local npc_id_str, spawn_uid, percentage_str = strsplit("-", payload)
				local npc_id, percentage = tonumber(npc_id_str), tonumber(percentage_str)
				RTN:AcknowledgeEntityHealthRaid(npc_id, spawn_uid, percentage)
			end
		end
	end
end
