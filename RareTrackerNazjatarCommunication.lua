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

-- ####################################################################
-- ##                        Helper Functions                        ##
-- ####################################################################

RTN.last_message_sent = 0
-- A function that acts as a rate limiter for channel messages.
function RTN:SendRateLimitedAddonMessage(message, target, target_id)
	-- We only allow one message to be sent every ~4 seconds.
	if time() - RTN.last_message_sent > 4 then
		C_ChatInfo.SendAddonMessage("RTN", message, target, target_id)
		RTN.last_message_sent = time()
	end
end

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

-- ####################################################################
-- ##            Shard Group Management Register Functions           ##
-- ####################################################################

-- Inform other clients of your arrival.
function RTN:RegisterArrival(shard_id)
	-- Attempt to load previous data from our cache.
	if RTNDB.previous_records[shard_id] then
		if time() - RTNDB.previous_records[shard_id].time_stamp < 300 then
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
	
	-- Join the appropriate channel.
	JoinTemporaryChannel(RTN.channel_name)

	-- Announce to the others that you have arrived.
	RTN.arrival_register_time = time()
	RTN.rare_table_updated = false
		
	if not is_in_channel then
		-- If we are not in the channel yet, we cannot immediately send a message.
		-- Wait for a few seconds and send the arrival announcement message.
		local frame = CreateFrame("Frame", "RTN.message_delay_frame", self)
		frame.start_time = time()
		frame:SetScript("OnUpdate", 
			function()
				if time() - frame.start_time > 3 then
					print("<RTN> Requesting rare kill data for shard "..(shard_id + 42)..".")
					C_ChatInfo.SendAddonMessage("RTN", "A-"..shard_id.."-"..RTN.version..":"..RTN.arrival_register_time, "CHANNEL", select(1, GetChannelName(RTN.channel_name)))
					frame:SetScript("OnUpdate", nil)
					frame:Hide()
				end
			end
		)
		frame:Show()
		print("<RTN> Channel joined, requesting rare kill data in 3 seconds.")
	else
		C_ChatInfo.SendAddonMessage("RTN", "A-"..shard_id.."-"..RTN.version..":"..RTN.arrival_register_time, "CHANNEL", select(1, GetChannelName(RTN.channel_name)))
	end	
end

-- Inform the others that you are still present.
function RTN:RegisterPresenceWhisper(shard_id, target, time_stamp)
	-- Announce to the others that you are still present on the shard.
	C_ChatInfo.SendAddonMessage("RTN", "PW-"..shard_id.."-"..RTN.version..":"..RTN:GetCompressedSpawnData(time_stamp), "WHISPER", target)
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
		RTNDB.previous_records[shard_id].time_stamp = time()
		RTNDB.previous_records[shard_id].time_table = RTN.last_recorded_death
	end
end

-- ####################################################################
-- ##          Shard Group Management Acknowledge Functions          ##
-- ####################################################################

function RTN:AcknowledgeArrival(player, time_stamp)
	-- Notify the newly arrived user of your presence through a whisper.
	if player_name ~= player then
		RTN:RegisterPresenceWhisper(RTN.current_shard_id, player, time_stamp)
	end	
end

function RTN:AcknowledgePresenceWhisper(player, spawn_data)
	RTN:DecompressSpawnData(spawn_data, RTN.arrival_register_time)
end

-- ####################################################################
-- ##               Entity Information Share Functions               ##
-- ####################################################################

-- Inform the others that a specific entity has died.
function RTN:RegisterEntityDeath(shard_id, npc_id)
	C_ChatInfo.SendAddonMessage("RTN", "ED-"..shard_id.."-"..RTN.version..":"..npc_id, "CHANNEL", select(1, GetChannelName(RTN.channel_name)))
end

-- Inform the others that you have spotted an alive entity.
function RTN:RegisterEntityAlive(shard_id, npc_id, spawn_id)
	C_ChatInfo.SendAddonMessage("RTN", "EA-"..shard_id.."-"..RTN.version..":"..npc_id.."-"..spawn_id, "CHANNEL", select(1, GetChannelName(RTN.channel_name)))
end

-- Inform the others that you have spotted an alive entity.
function RTN:RegisterEntityTarget(shard_id, npc_id, spawn_id, percentage, x, y)
	C_ChatInfo.SendAddonMessage("RTN", "ET-"..shard_id.."-"..RTN.version..":"..npc_id.."-"..spawn_id.."-"..percentage.."-"..x.."-"..y, "CHANNEL", select(1, GetChannelName(RTN.channel_name)))
end

-- Inform the others the health of a specific entity.
function RTN:RegisterEntityHealth(shard_id, npc_id, spawn_id, percentage)
	if not RTN.last_health_report[npc_id] or time() - RTN.last_health_report[npc_id] > 2 then
		RTN:SendRateLimitedAddonMessage("EH-"..shard_id.."-"..RTN.version..":"..npc_id.."-"..spawn_id.."-"..percentage, "CHANNEL", select(1, GetChannelName(RTN.channel_name)))
	end
end


function RTN:AcknowledgeEntityDeath(npc_id)
	RTN.last_recorded_death[npc_id] = time()
	RTN.is_alive[npc_id] = nil
	RTN.current_health[npc_id] = nil
	RTN.current_coordinates[npc_id] = nil
	RTN:UpdateDailyKillMark(npc_id)
	
	if RTN.waypoints[npc_id] and TomTom then
		TomTom:RemoveWaypoint(RTN.waypoints[npc_id])
		RTN.waypoints[npc_id] = nil
	end
end

function RTN:AcknowledgeEntityAlive(npc_id, spawn_id)
	RTN.is_alive[npc_id] = time()
	
	if RTNDB.favorite_rares[npc_id] and not RTN.reported_spawn_uids[spawn_id] then
		-- Play a sound file.
		PlaySoundFile(543587)
		RTN.reported_spawn_uids[spawn_id] = true
	end
end

function RTN:AcknowledgeEntityTarget(npc_id, spawn_id, percentage, x, y)
	RTN.last_recorded_death[npc_id] = nil
	RTN.is_alive[npc_id] = time()
	RTN.current_health[npc_id] = percentage
	RTN.current_coordinates[npc_id] = {}
	RTN.current_coordinates[npc_id].x = x
	RTN.current_coordinates[npc_id].y = y
	
	if RTNDB.favorite_rares[npc_id] and not RTN.reported_spawn_uids[spawn_id] then
		-- Play a sound file.
		PlaySoundFile(543587)
		RTN.reported_spawn_uids[spawn_id] = true
	end
end

function RTN:AcknowledgeEntityHealth(npc_id, spawn_id, percentage)
	RTN.last_recorded_death[npc_id] = nil
	RTN.is_alive[npc_id] = time()
	RTN.current_health[npc_id] = percentage
	RTN.last_health_report[npc_id] = time()
	
	if RTNDB.favorite_rares[npc_id] and not RTN.reported_spawn_uids[spawn_id] then
		-- Play a sound file.
		PlaySoundFile(543587)
		RTN.reported_spawn_uids[spawn_id] = true
	end
end

function RTN:OnChatMessageReceived(player, prefix, shard_id, addon_version, payload)
	
	if not reported_version_mismatch and RTN.version < addon_version and addon_version ~= 9001 then
		print("<RTN> Your version or RareTrackerMechagon is outdated. Please update to the most recent version at the earliest convenience.")
		reported_version_mismatch = true
	end
	
	if RTN.current_shard_id == shard_id and RTN.version == addon_version then
		if prefix == "A" then
			time_stamp = tonumber(payload)
			RTN:AcknowledgeArrival(player, time_stamp)
		elseif prefix == "PW" then
			RTN:AcknowledgePresenceWhisper(player, payload)
		elseif prefix == "ED" then
			local npc_id = tonumber(payload)
			RTN:AcknowledgeEntityDeath(npc_id)
		elseif prefix == "EA" then
			local npcs_id_str, spawn_id = strsplit("-", payload)
			local npc_id = tonumber(npcs_id_str)
			RTN:AcknowledgeEntityAlive(npc_id, spawn_id)
		elseif prefix == "ET" then
			local npc_id_str, spawn_id, percentage_str, x_str, y_str = strsplit("-", payload)
			local npc_id, percentage, x, y = tonumber(npc_id_str), tonumber(percentage_str), tonumber(x_str), tonumber(y_str)
			RTN:AcknowledgeEntityTarget(npc_id, spawn_id, percentage, x, y)
		elseif prefix == "EH" then
			local npc_id_str, spawn_id, percentage_str = strsplit("-", payload)
			local npc_id, percentage = tonumber(npc_id_str), tonumber(percentage_str)
			RTN:AcknowledgeEntityHealth(npc_id, spawn_id, percentage)
		end
	end
end