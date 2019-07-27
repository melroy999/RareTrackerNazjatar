-- Redefine often used functions locally.
local CreateFrame = CreateFrame
local IsLeftControlKeyDown = IsLeftControlKeyDown
local IsRightControlKeyDown = IsRightControlKeyDown
local UnitInRaid = UnitInRaid
local IsLeftAltKeyDown = IsLeftAltKeyDown
local IsRightAltKeyDown = IsRightAltKeyDown
local SendChatMessage = SendChatMessage
local GetServerTime = GetServerTime
local IsQuestFlaggedCompleted = IsQuestFlaggedCompleted
local UIDropDownMenu_SetWidth = UIDropDownMenu_SetWidth
local UIDropDownMenu_SetText = UIDropDownMenu_SetText
local PlaySoundFile = PlaySoundFile
local UIDropDownMenu_CreateInfo = UIDropDownMenu_CreateInfo
local UIDropDownMenu_AddButton = UIDropDownMenu_AddButton
local getglobal = getglobal
local InterfaceOptions_AddCategory = InterfaceOptions_AddCategory

-- Redefine global variables locally.
local UIParent = UIParent
local C_Map = C_Map

-- Width and height variables used to customize the window.
local entity_name_width = 208
local entity_status_width = 50
local frame_padding = 4
local favorite_rares_width = 10
local shard_id_frame_height = 16

-- Values for the opacity of the background and foreground.
local background_opacity = 0.4
local front_opacity = 0.6

-- ####################################################################
-- ##                              GUI                               ##
-- ####################################################################

RTN.last_reload_time = 0

function RTN:InitializeShardNumberFrame()
	local f = CreateFrame("Frame", "RTN.shard_id_frame", self)
	f:SetSize(
      entity_name_width + entity_status_width + 3 * frame_padding + 2 * favorite_rares_width,
      shard_id_frame_height
  )
  
	local texture = f:CreateTexture(nil, "BACKGROUND")
	texture:SetColorTexture(0, 0, 0, front_opacity)
	texture:SetAllPoints(f)
	f.texture = texture
	
	f.status_text = f:CreateFontString(nil, nil, "GameFontNormal")
	f.status_text:SetPoint("TOPLEFT", 10 + 2 * favorite_rares_width + 2 * frame_padding, -3)
	f.status_text:SetText("Shard ID: Unknown")
	f:SetPoint("TOPLEFT", self, frame_padding, -frame_padding)
	
	return f
end

function RTN:CreateRareTableEntry(npc_id, parent_frame)
	local f = CreateFrame("Frame", "RTN.entities_frame.entities["..npc_id.."]", parent_frame);
	f:SetSize(entity_name_width + entity_status_width + 3 * frame_padding + 2 * favorite_rares_width, 12)
	
	-- Add the favorite button.
	f.favorite = CreateFrame("CheckButton", "RTN.entities_frame.entities["..npc_id.."].favorite", f)
	f.favorite:SetSize(10, 10)
	local texture = f.favorite:CreateTexture(nil, "BACKGROUND")
	texture:SetColorTexture(0, 0, 0, front_opacity)
	texture:SetAllPoints(f.favorite)
	f.favorite.texture = texture
	f.favorite:SetPoint("TOPLEFT", 1, 0)
	
	-- Add an action listener.
	f.favorite:SetScript("OnClick",
		function()
			if RTNDB.favorite_rares[npc_id] then
				RTNDB.favorite_rares[npc_id] = nil
				f.favorite.texture:SetColorTexture(0, 0, 0, front_opacity)
			else
				RTNDB.favorite_rares[npc_id] = true
				f.favorite.texture:SetColorTexture(0, 1, 0, 1)
			end
		end
	);
	
	-- Add the announce/waypoint button.
	f.announce = CreateFrame("Button", "RTN.entities_frame.entities["..npc_id.."].announce", f)
	f.announce:SetSize(10, 10)
	texture = f.announce:CreateTexture(nil, "BACKGROUND")
	texture:SetColorTexture(0, 0, 0, front_opacity)
	texture:SetAllPoints(f.announce)
	f.announce.texture = texture
	f.announce:SetPoint("TOPLEFT", frame_padding + favorite_rares_width + 1, 0)
	f.announce:RegisterForClicks("LeftButtonDown", "RightButtonDown")
	
	-- Add an action listener.
	f.announce:SetScript("OnClick",
		function(_, button)
			local name = self.rare_names[npc_id]
			local health = self.current_health[npc_id]
			local last_death = self.last_recorded_death[npc_id]
			local loc = self.current_coordinates[npc_id]
			
			if button == "LeftButton" then
				local target = "CHANNEL"
				
				if IsLeftControlKeyDown() or IsRightControlKeyDown() then
					if UnitInRaid("player") then
						target = "RAID"
					else
						target = "PARTY"
					end
				elseif IsLeftAltKeyDown() or IsRightAltKeyDown() then
					target = "SAY"
				end
			
				if self.current_health[npc_id] then
					-- SendChatMessage
					if loc then
						SendChatMessage(
							string.format("<RTN> %s (%s%%) seen at ~(%.2f, %.2f)", name, health, loc.x, loc.y),
							target,
							nil,
							1
						)
					else
						SendChatMessage(
							string.format("<RTN> %s (%s%%)", name, health),
							target,
							nil,
							1
						)
					end
				elseif self.last_recorded_death[npc_id] ~= nil then
					if GetServerTime() - last_death < 60 then
						SendChatMessage(
							string.format("<RTN> %s has died", name, GetServerTime() - last_death),
							target,
							nil,
							1
						)
					else
						SendChatMessage(
							string.format(
								"<RTN> %s was last seen ~%s minutes ago",
								name,
								math.floor((GetServerTime() - last_death) / 60)
							),
							target,
							nil,
							1
						)
					end
				elseif self.is_alive[npc_id] then
					if loc then
						SendChatMessage(
							string.format("<RTN> %s seen alive, vignette at ~(%.2f, %.2f)", name, loc.x, loc.y),
							target,
							nil,
							1
						)
					else
						SendChatMessage(
							string.format("<RTN> %s seen alive (combat log)", name),
							target,
							nil,
							1
						)
					end
				end
			else
				-- does the user have tom tom? if so, add a waypoint if it exists.
				if TomTom ~= nil and loc then
					self.waypoints[npc_id] = TomTom:AddWaypointToCurrentZone(loc.x, loc.y, name)
				end
			end
		end
	);
	
	-- Add the entities name.
	f.name = f:CreateFontString(nil, nil, "GameFontNormal")
	f.name:SetJustifyH("LEFT")
	f.name:SetJustifyV("TOP")
	f.name:SetPoint("TOPLEFT", 2 * frame_padding + 2 * favorite_rares_width + 10, 0)
	f.name:SetText(self.rare_names[npc_id])
	
	-- Add the timer/health entry.
	f.status = f:CreateFontString(nil, nil, "GameFontNormal")
	f.status:SetPoint("TOPRIGHT", 0, 0)
	f.status:SetText("--")
	f.status:SetJustifyH("MIDDLE")
	f.status:SetJustifyV("TOP")
	f.status:SetSize(entity_status_width, 12)
	
	return f
end

function RTN:InitializeRareTableEntries(parent_frame)
	-- Create a holder for all the entries.
	parent_frame.entities = {}
	
	-- Create a frame entry for all of the NPC ids, even the ignored ones.
	-- The ordering and hiding of rares will be done later.
	for i=1, #self.rare_ids do
		local npc_id = self.rare_ids[i]
		parent_frame.entities[npc_id] = self:CreateRareTableEntry(npc_id, parent_frame)
	end
end

function RTN:ReorganizeRareTableFrame(f)
	-- How many ignored rares do we have?
	local n = 0
	for _, _ in pairs(RTNDB.ignore_rare) do
		n = n + 1
	end
	
	-- Resize all the frames.
	self:SetSize(
		entity_name_width + entity_status_width + 2 * favorite_rares_width + 5 * frame_padding,
		shard_id_frame_height + 3 * frame_padding + (#self.rare_ids - n) * 12 + 8
	)
	f:SetSize(
		entity_name_width + entity_status_width + 2 * favorite_rares_width + 3 * frame_padding,
		(#self.rare_ids - n) * 12 + 8
	)
	f.entity_name_backdrop:SetSize(entity_name_width, f:GetHeight())
	f.entity_status_backdrop:SetSize(entity_status_width, f:GetHeight())
	
	-- Give all of the table entries their new positions.
	local i = 1
	RTNDB.rare_ordering:ForEach(
		function(npc_id, _)
			if RTNDB.ignore_rare[npc_id] then
				f.entities[npc_id]:Hide()
			else
				f.entities[npc_id]:SetPoint("TOPLEFT", f, 0, -(i - 1) * 12 - 5)
				f.entities[npc_id]:Show()
				i = i + 1
			end
		end
	)
end

function RTN:InitializeRareTableFrame(f)
	-- First, add the frames for the backdrop and make sure that the hierarchy is created.
	f:SetPoint("TOPLEFT", frame_padding, -(2 * frame_padding + shard_id_frame_height))
	
	f.entity_name_backdrop = CreateFrame("Frame", "RTN.entities_frame.entity_name_backdrop", f)
	local texture = f.entity_name_backdrop:CreateTexture(nil, "BACKGROUND")
	texture:SetColorTexture(0, 0, 0, front_opacity)
	texture:SetAllPoints(f.entity_name_backdrop)
	f.entity_name_backdrop.texture = texture
	f.entity_name_backdrop:SetPoint("TOPLEFT", f, 2 * frame_padding + 2 * favorite_rares_width, 0)
	
	f.entity_status_backdrop = CreateFrame("Frame", "RTN.entities_frame.entity_status_backdrop", f)
	texture = f.entity_status_backdrop:CreateTexture(nil, "BACKGROUND")
	texture:SetColorTexture(0, 0, 0, front_opacity)
	texture:SetAllPoints(f.entity_status_backdrop)
	f.entity_status_backdrop.texture = texture
	f.entity_status_backdrop:SetPoint("TOPRIGHT", f, 0, 0)
	
	-- Next, add all the rare entries to the table.
	self:InitializeRareTableEntries(f)
	
	-- Arrange the table such that it fits the user's wishes. Resize the frames appropriately.
	self:ReorganizeRareTableFrame(f)
end

function RTN:UpdateStatus(npc_id)
	local target = self.entities_frame.entities[npc_id]

	if self.current_health[npc_id] then
		target.status:SetText(self.current_health[npc_id].."%")
    target.status:SetFontObject("GameFontGreen")
		target.announce.texture:SetColorTexture(0, 1, 0, 1)
	elseif self.is_alive[npc_id] then
		target.status:SetText("N/A")
    target.status:SetFontObject("GameFontGreen")
		target.announce.texture:SetColorTexture(0, 1, 0, 1)
	elseif self.last_recorded_death[npc_id] ~= nil then
		local last_death = self.last_recorded_death[npc_id]
		target.status:SetText(math.floor((GetServerTime() - last_death) / 60).."m")
    target.status:SetFontObject("GameFontNormal")
		target.announce.texture:SetColorTexture(0, 0, 1, front_opacity)
	else
		target.status:SetText("--")
    target.status:SetFontObject("GameFontNormal")
		target.announce.texture:SetColorTexture(0, 0, 0, front_opacity)
	end
end

function RTN:UpdateShardNumber(shard_number)
	if shard_number then
		self.shard_id_frame.status_text:SetText("Shard ID: "..(shard_number + 42))
	else
		self.shard_id_frame.status_text:SetText("Shard ID: Unknown")
	end
end

function RTN:CorrectFavoriteMarks()
	for i=1, #self.rare_ids do
		local npc_id = self.rare_ids[i]
		
		if RTNDB.favorite_rares[npc_id] then
			self.entities_frame.entities[npc_id].favorite.texture:SetColorTexture(0, 1, 0, 1)
		else
			self.entities_frame.entities[npc_id].favorite.texture:SetColorTexture(0, 0, 0, front_opacity)
		end
	end
end

function RTN:UpdateDailyKillMark(npc_id)
	if not self.completion_quest_ids[npc_id] then
		return
	end
	
	-- Multiple NPCs might share the same quest id.
	local completion_quest_id = self.completion_quest_ids[npc_id]
	local npc_ids = self.completion_quest_inverse[completion_quest_id]
	
	for _, target_npc_id in pairs(npc_ids) do
		if self.completion_quest_ids[target_npc_id] and IsQuestFlaggedCompleted(self.completion_quest_ids[target_npc_id]) then
			self.entities_frame.entities[target_npc_id].name:SetText(self.rare_names[target_npc_id])
			self.entities_frame.entities[target_npc_id].name:SetFontObject("GameFontRed")
		else
			self.entities_frame.entities[target_npc_id].name:SetText(self.rare_names[target_npc_id])
			self.entities_frame.entities[target_npc_id].name:SetFontObject("GameFontNormal")
		end
	end
end

function RTN:UpdateAllDailyKillMarks()
	for i=1, #RTN.rare_ids do
		local npc_id = RTN.rare_ids[i]
		self:UpdateDailyKillMark(npc_id)
	end
end

function RTN.InitializeFavoriteIconFrame(f)
	f.favorite_icon = CreateFrame("Frame", "RTN.favorite_icon", f)
	f.favorite_icon:SetSize(10, 10)
	f.favorite_icon:SetPoint("TOPLEFT", f, frame_padding + 1, -(frame_padding + 3))

	f.favorite_icon.texture = f.favorite_icon:CreateTexture(nil, "OVERLAY")
	f.favorite_icon.texture:SetTexture("Interface\\AddOns\\RareTrackerNazjatar\\Icons\\Favorite.tga")
	f.favorite_icon.texture:SetSize(10, 10)
	f.favorite_icon.texture:SetPoint("CENTER", f.favorite_icon)
	
	f.favorite_icon.tooltip = CreateFrame("Frame", nil, UIParent)
	f.favorite_icon.tooltip:SetSize(300, 18)
	
	local texture = f.favorite_icon.tooltip:CreateTexture(nil, "BACKGROUND")
	texture:SetColorTexture(0, 0, 0, front_opacity)
	texture:SetAllPoints(f.favorite_icon.tooltip)
	f.favorite_icon.tooltip.texture = texture
	f.favorite_icon.tooltip:SetPoint("TOPLEFT", f, 0, 19)
	f.favorite_icon.tooltip:Hide()
	
	f.favorite_icon.tooltip.text = f.favorite_icon.tooltip:CreateFontString(nil, nil, "GameFontNormal")
	f.favorite_icon.tooltip.text:SetJustifyH("LEFT")
	f.favorite_icon.tooltip.text:SetJustifyV("TOP")
	f.favorite_icon.tooltip.text:SetPoint("TOPLEFT", f.favorite_icon.tooltip, 5, -3)
	f.favorite_icon.tooltip.text:SetText("Click on the squares to add rares to your favorites.")
	
	f.favorite_icon:SetScript("OnEnter",
		function(self)
			self.tooltip:Show()
		end
	);
	
	f.favorite_icon:SetScript("OnLeave",
		function(self)
			self.tooltip:Hide()
		end
	);
end

function RTN.InitializeAnnounceIconFrame(f)
	f.broadcast_icon = CreateFrame("Frame", "RTN.broadcast_icon", f)
	f.broadcast_icon:SetSize(10, 10)
	f.broadcast_icon:SetPoint("TOPLEFT", f, 2 * frame_padding + favorite_rares_width + 1, -(frame_padding + 3))

	f.broadcast_icon.texture = f.broadcast_icon:CreateTexture(nil, "OVERLAY")
	f.broadcast_icon.texture:SetTexture("Interface\\AddOns\\RareTrackerNazjatar\\Icons\\Broadcast.tga")
	f.broadcast_icon.texture:SetSize(10, 10)
	f.broadcast_icon.texture:SetPoint("CENTER", f.broadcast_icon)
	f.broadcast_icon.icon_state = false
	
	f.broadcast_icon.tooltip = CreateFrame("Frame", nil, UIParent)
	f.broadcast_icon.tooltip:SetSize(273, 68)
	
	local texture = f.broadcast_icon.tooltip:CreateTexture(nil, "BACKGROUND")
	texture:SetColorTexture(0, 0, 0, front_opacity)
	texture:SetAllPoints(f.broadcast_icon.tooltip)
	f.broadcast_icon.tooltip.texture = texture
	f.broadcast_icon.tooltip:SetPoint("TOPLEFT", f, 0, 69)
	f.broadcast_icon.tooltip:Hide()
	
	f.broadcast_icon.tooltip.text1 = f.broadcast_icon.tooltip:CreateFontString(nil, nil, "GameFontNormal")
	f.broadcast_icon.tooltip.text1:SetJustifyH("LEFT")
	f.broadcast_icon.tooltip.text1:SetJustifyV("TOP")
	f.broadcast_icon.tooltip.text1:SetPoint("TOPLEFT", f.broadcast_icon.tooltip, 5, -3)
	f.broadcast_icon.tooltip.text1:SetText("Click on the squares to announce rare timers.")
	
	f.broadcast_icon.tooltip.text2 = f.broadcast_icon.tooltip:CreateFontString(nil, nil, "GameFontNormal")
	f.broadcast_icon.tooltip.text2:SetJustifyH("LEFT")
	f.broadcast_icon.tooltip.text2:SetJustifyV("TOP")
	f.broadcast_icon.tooltip.text2:SetPoint("TOPLEFT", f.broadcast_icon.tooltip, 5, -15)
	f.broadcast_icon.tooltip.text2:SetText("Left click: report to general chat")
	
	f.broadcast_icon.tooltip.text3 = f.broadcast_icon.tooltip:CreateFontString(nil, nil, "GameFontNormal")
	f.broadcast_icon.tooltip.text3:SetJustifyH("LEFT")
	f.broadcast_icon.tooltip.text3:SetJustifyV("TOP")
	f.broadcast_icon.tooltip.text3:SetPoint("TOPLEFT", f.broadcast_icon.tooltip, 5, -27)
	f.broadcast_icon.tooltip.text3:SetText("Control-left click: report to party/raid chat")
	
	f.broadcast_icon.tooltip.text4 = f.broadcast_icon.tooltip:CreateFontString(nil, nil, "GameFontNormal")
	f.broadcast_icon.tooltip.text4:SetJustifyH("LEFT")
	f.broadcast_icon.tooltip.text4:SetJustifyV("TOP")
	f.broadcast_icon.tooltip.text4:SetPoint("TOPLEFT", f.broadcast_icon.tooltip, 5, -39)
	f.broadcast_icon.tooltip.text4:SetText("Alt-left click: report to say")
	  
	f.broadcast_icon.tooltip.text5 = f.broadcast_icon.tooltip:CreateFontString(nil, nil, "GameFontNormal")
	f.broadcast_icon.tooltip.text5:SetJustifyH("LEFT")
	f.broadcast_icon.tooltip.text5:SetJustifyV("TOP")
	f.broadcast_icon.tooltip.text5:SetPoint("TOPLEFT", f.broadcast_icon.tooltip, 5, -51)
	f.broadcast_icon.tooltip.text5:SetText("Right click: set waypoint if available")
	
	f.broadcast_icon:SetScript("OnEnter",
		function(self)
			self.tooltip:Show()
		end
	);
	
	f.broadcast_icon:SetScript("OnLeave",
		function(self)
			self.tooltip:Hide()
		end
	);
end

function RTN:InitializeReloadButton(f)
	f.reload_button = CreateFrame("Button", "RTN.reload_button", f)
	f.reload_button:SetSize(10, 10)
	f.reload_button:SetPoint("TOPRIGHT", f, -2 * frame_padding, -(frame_padding + 3))

	f.reload_button.texture = f.reload_button:CreateTexture(nil, "OVERLAY")
	f.reload_button.texture:SetTexture("Interface\\AddOns\\RareTrackerNazjatar\\Icons\\Reload.tga")
	f.reload_button.texture:SetSize(10, 10)
	f.reload_button.texture:SetPoint("CENTER", f.reload_button)
	
	-- Create a tooltip window.
	f.reload_button.tooltip = CreateFrame("Frame", nil, UIParent)
	f.reload_button.tooltip:SetSize(390, 34)
	
	local texture = f.reload_button.tooltip:CreateTexture(nil, "BACKGROUND")
	texture:SetColorTexture(0, 0, 0, front_opacity)
	texture:SetAllPoints(f.reload_button.tooltip)
	f.reload_button.tooltip.texture = texture
	f.reload_button.tooltip:SetPoint("TOPLEFT", f, 0, 35)
	f.reload_button.tooltip:Hide()
	
	f.reload_button.tooltip.text1 = f.reload_button.tooltip:CreateFontString(nil, nil, "GameFontNormal")
	f.reload_button.tooltip.text1:SetJustifyH("LEFT")
	f.reload_button.tooltip.text1:SetJustifyV("TOP")
	f.reload_button.tooltip.text1:SetPoint("TOPLEFT", f.reload_button.tooltip, 5, -3)
	f.reload_button.tooltip.text1:SetText("Reset your data and replace it with the data of others.")
	
	f.reload_button.tooltip.text2 = f.reload_button.tooltip:CreateFontString(nil, nil, "GameFontNormal")
	f.reload_button.tooltip.text2:SetJustifyH("LEFT")
	f.reload_button.tooltip.text2:SetJustifyV("TOP")
	f.reload_button.tooltip.text2:SetPoint("TOPLEFT", f.reload_button.tooltip, 5, -15)
	f.reload_button.tooltip.text2:SetText("Note: you do not need to press this button to receive new timers.")
	
	-- Hide and show the tooltip on mouseover.
	f.reload_button:SetScript("OnEnter",
		function(self2)
			self2.tooltip:Show()
		end
	);
	
	f.reload_button:SetScript("OnLeave",
		function(self2)
			self2.tooltip:Hide()
		end
	);
	
	f.reload_button:SetScript("OnClick",
		function()
			if self.current_shard_id ~= nil and GetServerTime() - self.last_reload_time > 600 then
				print("<RTN> Resetting current rare timers and requesting up-to-date data.")
				self.is_alive = {}
				self.current_health = {}
				self.last_recorded_death = {}
				self.recorded_entity_death_ids = {}
				self.current_coordinates = {}
				self.reported_spawn_uids = {}
				self.reported_vignettes = {}
				self.last_reload_time = GetServerTime()
				
				-- Reset the cache.
				RTNDB.previous_records[self.current_shard_id] = nil
				
				-- Re-register your arrival in the shard.
				RTN:RegisterArrival(self.current_shard_id)
			elseif self.current_shard_id == nil then
				print("<RTN> Please target a non-player entity prior to resetting, "..
						"such that the addon can determine the current shard id.")
			else
				print("<RTN> The reset button is on cooldown. Please note that a reset is not needed "..
					"to receive new timers. If it is your intention to reset the data, "..
					"please do a /reload and click the reset button again.")
			end
		end
	);
end


function RTN:InitializeInterface()
	self:SetSize(
		entity_name_width + entity_status_width + 2 * favorite_rares_width + 5 * frame_padding,
		shard_id_frame_height + 3 * frame_padding + #self.rare_ids * 12 + 8
	)
	
	local texture = self:CreateTexture(nil, "BACKGROUND")
	texture:SetColorTexture(0, 0, 0, background_opacity)
	texture:SetAllPoints(self)
	self.texture = texture
	self:SetPoint("CENTER")
	
	-- Create a sub-frame for the entity names.
	self.shard_id_frame = self:InitializeShardNumberFrame()
	self.entities_frame = CreateFrame("Frame", "RTN.entities_frame", self)
	self:InitializeRareTableFrame(self.entities_frame)

	self:SetMovable(true)
	self:EnableMouse(true)
	self:RegisterForDrag("LeftButton")
	self:SetScript("OnDragStart", self.StartMoving)
	self:SetScript("OnDragStop", self.StopMovingOrSizing)
	
	-- Add icons for the favorite and broadcast columns.
	self.InitializeFavoriteIconFrame(self)
	self.InitializeAnnounceIconFrame(self)
	
	-- Create a reset button.
	self:InitializeReloadButton(self)
	self:SetClampedToScreen(true)
	
	self:Hide()
end

-- ####################################################################
-- ##                       Options Interface                        ##
-- ####################################################################

-- The provided sound options.
local sound_options = {}
sound_options[''] = -1
sound_options["Rubber Ducky"] = 566121
sound_options["Cartoon FX"] = 566543
sound_options["Explosion"] = 566982
sound_options["Shing!"] = 566240
sound_options["Wham!"] = 566946
sound_options["Simon Chime"] = 566076
sound_options["War Drums"] = 567275
sound_options["Scourge Horn"] = 567386
sound_options["Pygmy Drums"] = 566508
sound_options["Cheer"] = 567283
sound_options["Humm"] = 569518
sound_options["Short Circuit"] = 568975
sound_options["Fel Portal"] = 569215
sound_options["Fel Nova"] = 568582
sound_options["PVP Flag"] = 569200
sound_options["Beware!"] = 543587
sound_options["Laugh"] = 564859
sound_options["Not Prepared"] = 552503
sound_options["I am Unleashed"] = 554554
sound_options["I see you"] = 554236

local sound_options_inverse = {}
for key, value in pairs(sound_options) do
	sound_options_inverse[value] = key
end

function RTN.IntializeSoundSelectionMenu(parent_frame)
	local f = CreateFrame("frame", "RTN.options_panel.sound_selection", parent_frame, "UIDropDownMenuTemplate")
	UIDropDownMenu_SetWidth(f, 140)
	UIDropDownMenu_SetText(f, sound_options_inverse[RTNDB.selected_sound_number])
	
	f.onClick = function(_, sound_id, _, _)
		RTNDB.selected_sound_number = sound_id
		UIDropDownMenu_SetText(f, sound_options_inverse[RTNDB.selected_sound_number])
		PlaySoundFile(RTNDB.selected_sound_number)
	end
	
	f.initialize = function()
		local info = UIDropDownMenu_CreateInfo()
		
		for key, value in pairs(sound_options) do
			info.text = key
			info.arg1 = value
			info.func = f.onClick
			info.menuList = key
			info.checked = RTNDB.selected_sound_number == value
			UIDropDownMenu_AddButton(info)
		end
	end
	
	f.label = f:CreateFontString(nil, "BORDER", "GameFontNormal")
	f.label:SetJustifyH("LEFT")
	f.label:SetText("Favorite sound alert")
	f.label:SetPoint("TOPLEFT", parent_frame)
	
	f:SetPoint("TOPLEFT", f.label, -20, -13)
	
	return f
end

function RTN:IntializeMinimapCheckbox(parent_frame)
	local f = CreateFrame(
		"CheckButton", "RTN.options_panel.minimap_checkbox", parent_frame, "ChatConfigCheckButtonTemplate"
	)
	
	getglobal(f:GetName() .. 'Text'):SetText(" Show minimap icon");
	f.tooltip = "Show or hide the minimap button.";
	f:SetScript("OnClick",
		function()
			RTNDB.minimap_icon_enabled = not RTNDB.minimap_icon_enabled
			if not RTNDB.minimap_icon_enabled then
				self.icon:Hide("RTN_icon")
			elseif RTN.target_zones[C_Map.GetBestMapForUnit("player")] then
				self.icon:Show("RTN_icon")
			end
		end
	);
	f:SetChecked(RTNDB.minimap_icon_enabled)
	f:SetPoint("TOPLEFT", parent_frame, 0, -53)
end

function RTN.IntializeRaidCommunicationCheckbox(parent_frame)
	local f = CreateFrame(
		"CheckButton", "RTN.options_panel.raid_comms_checkbox", parent_frame, "ChatConfigCheckButtonTemplate"
	)
	
	getglobal(f:GetName() .. 'Text'):SetText(" Enable communication over part/raid channel")
	f.tooltip = "Enable communication over party/raid channel, "..
					"to support CRZ functionality while in a party or raid group."

	f:SetScript("OnClick",
		function()
			RTNDB.enable_raid_communication = not RTNDB.enable_raid_communication
		end
	);
	f:SetChecked(RTNDB.enable_raid_communication)
	f:SetPoint("TOPLEFT", parent_frame, 0, -75)
end

function RTN.IntializeDebugCheckbox(parent_frame)
	local f = CreateFrame("CheckButton", "RTN.options_panel.debug_checkbox", parent_frame, "ChatConfigCheckButtonTemplate")
	getglobal(f:GetName() .. 'Text'):SetText(" Enable debug mode");
	f.tooltip = "Show or hide the minimap button.";
	f:SetScript("OnClick",
		function()
			RTNDB.debug_enabled = not RTNDB.debug_enabled
		end
	);
	f:SetChecked(RTNDB.debug_enabled)
	f:SetPoint("TOPLEFT", parent_frame, 0, -97)
end

function RTN:IntializeScaleSlider(parent_frame)
	local f = CreateFrame("Slider", "RTN.options_panel.scale_slider", parent_frame, "OptionsSliderTemplate")
	f.tooltip = "Set the scale of the rare window.";
	f:SetMinMaxValues(0.5, 2)
	f:SetValueStep(0.05)
	f:SetValue(RTNDB.window_scale)
	self:SetScale(RTNDB.window_scale)
	f:Enable()
	
	f:SetScript("OnValueChanged",
		function(self2, value)
			-- Round the value to the nearest step value.
			value = math.floor(value * 20) / 20
		
			RTNDB.window_scale = value
			self2.label:SetText("Rare window scale "..string.format("(%.2f)", RTNDB.window_scale))
			RTN:SetScale(RTNDB.window_scale)
		end
	);
	
	f.label = f:CreateFontString(nil, "BORDER", "GameFontNormal")
	f.label:SetJustifyH("LEFT")
	f.label:SetText("Rare window scale "..string.format("(%.2f)", RTNDB.window_scale))
	f.label:SetPoint("TOPLEFT", parent_frame, 0, -125)
	
	f:SetPoint("TOPLEFT", f.label, 5, -15)
end

function RTN:InitializeButtons(parent_frame)
	parent_frame.reset_favorites_button = CreateFrame(
		"Button", "RTN.options_panel.reset_favorites_button", parent_frame, 'UIPanelButtonTemplate'
	)
	
	parent_frame.reset_favorites_button:SetText("Reset Favorites")
	parent_frame.reset_favorites_button:SetSize(150, 25)
	parent_frame.reset_favorites_button:SetPoint("TOPLEFT", parent_frame, 0, -175)
	parent_frame.reset_favorites_button:SetScript("OnClick",
		function()
			RTNDB.favorite_rares = {}
			self:CorrectFavoriteMarks()
		end
	)
	
	parent_frame.reset_blacklist_button = CreateFrame(
		"Button", "RTN.options_panel.reset_blacklist_button", parent_frame, 'UIPanelButtonTemplate'
	)
	
	parent_frame.reset_blacklist_button:SetText("Reset Blacklist")
	parent_frame.reset_blacklist_button:SetSize(150, 25)
	parent_frame.reset_blacklist_button:SetPoint("TOPRIGHT", parent_frame.reset_favorites_button, 155, 0)
	parent_frame.reset_blacklist_button:SetScript("OnClick",
		function()
			RTNDB.banned_NPC_ids = {}
		end
	)
end

function RTN:CreateRareSelectionEntry(npc_id, parent_frame, entry_data)
	local f = CreateFrame("Frame", "RTN.options_panel.rare_selection.frame.list["..npc_id.."]", parent_frame);
	f:SetSize(500, 12)
	
	f.enable = CreateFrame("Button", "RTN.options_panel.rare_selection.frame.list["..npc_id.."].enable", f);
	f.enable:SetSize(10, 10)
	local texture = f.enable:CreateTexture(nil, "BACKGROUND")
	
	if not RTNDB.ignore_rare[npc_id] then
		texture:SetColorTexture(0, 1, 0, 1)
	else
		texture:SetColorTexture(1, 0, 0, 1)
	end
	
	texture:SetAllPoints(f.enable)
	f.enable.texture = texture
	f.enable:SetPoint("TOPLEFT", f, 0, 0)
	f.enable:SetScript("OnClick",
		function()
			if not RTNDB.ignore_rare[npc_id] then
				if RTNDB.favorite_rares[npc_id] then
					print("<RTN> Favorites cannot be hidden.")
				else
					RTNDB.ignore_rare[npc_id] = true
					f.enable.texture:SetColorTexture(1, 0, 0, 1)
					RTN:ReorganizeRareTableFrame(RTN.entities_frame)
				end
			else
				RTNDB.ignore_rare[npc_id] = nil
				f.enable.texture:SetColorTexture(0, 1, 0, 1)
				RTN:ReorganizeRareTableFrame(RTN.entities_frame)
			end
		end
	)
	
	f.up = CreateFrame("Button", "RTN.options_panel.rare_selection.frame.list["..npc_id.."].up", f);
	f.up:SetSize(10, 10)
	texture = f.up:CreateTexture(nil, "OVERLAY")
	texture:SetTexture("Interface\\AddOns\\RareTrackerNazjatar\\Icons\\UpArrow.tga")
	texture:SetSize(10, 10)
	texture:SetPoint("CENTER", f.up)
	texture:SetAllPoints(f.up)
	
	f.up.texture = texture
	f.up:SetPoint("TOPLEFT", f, 13, 0)
	
	f.up:SetScript("OnClick",
		function()
      -- Here, we use the most up-to-date entry data, instead of the one passed as an argument.
      local previous_entry = RTNDB.rare_ordering.__raw_data_table[npc_id].__previous
			RTNDB.rare_ordering:SwapNeighbors(previous_entry, npc_id)
			self.ReorderRareSelectionEntryItems(parent_frame)
			self:ReorganizeRareTableFrame(self.entities_frame)
		end
	)
		
	if entry_data.__previous == nil then
		f.up:Hide()
	end
	
	f.down = CreateFrame("Button", "RTN.options_panel.rare_selection.frame.list["..npc_id.."].down", f);
	f.down:SetSize(10, 10)
	texture = f.down:CreateTexture(nil, "OVERLAY")
	texture:SetTexture("Interface\\AddOns\\RareTrackerNazjatar\\Icons\\DownArrow.tga")
	texture:SetSize(10, 10)
	texture:SetPoint("CENTER", f.down)
	texture:SetAllPoints(f.down)
	f.down.texture = texture
	f.down:SetPoint("TOPLEFT", f, 26, 0)
	
	f.down:SetScript("OnClick",
		function()
      -- Here, we use the most up-to-date entry data, instead of the one passed as an argument.
      local next_entry = RTNDB.rare_ordering.__raw_data_table[npc_id].__next
			RTNDB.rare_ordering:SwapNeighbors(npc_id, next_entry)
			self.ReorderRareSelectionEntryItems(parent_frame)
			self:ReorganizeRareTableFrame(self.entities_frame)
		end
	)

	if entry_data.__next == nil then
		f.down:Hide()
	end
	
	f.text = f:CreateFontString(nil, "BORDER", "GameFontNormal")
	f.text:SetJustifyH("LEFT")
	f.text:SetText(self.rare_names[npc_id])
	f.text:SetPoint("TOPLEFT", f, 42, 0)
	
	return f
end

function RTN.ReorderRareSelectionEntryItems(parent_frame)
	local i = 1
	RTNDB.rare_ordering:ForEach(
		function(npc_id, entry_data)
			local f = parent_frame.list_item[npc_id]
			if entry_data.__previous == nil then
				f.up:Hide()
			else
				f.up:Show()
			end
			
			if entry_data.__next == nil then
				f.down:Hide()
			else
				f.down:Show()
			end
				
			f:SetPoint("TOPLEFT", parent_frame, 1, -(i - 1) * 12 - 5)
			i = i + 1
		end
	)
end

function RTN:DisableAllRaresButton(parent_frame)
  parent_frame.reset_all_button = CreateFrame(
		"Button", "RTN.options_panel.rare_selection.reset_all_button", parent_frame, 'UIPanelButtonTemplate'
	)
	
	parent_frame.reset_all_button:SetText("Disable All")
	parent_frame.reset_all_button:SetSize(150, 25)
	parent_frame.reset_all_button:SetPoint("TOPRIGHT", parent_frame, 0, 0)
	parent_frame.reset_all_button:SetScript("OnClick",
		function()
			for i=1, #self.rare_ids do
        local npc_id = self.rare_ids[i]
        if RTNDB.favorite_rares[npc_id] ~= true then
          RTNDB.ignore_rare[npc_id] = true
          parent_frame.list_item[npc_id].enable.texture:SetColorTexture(1, 0, 0, 1)
        end
      end
      self:ReorganizeRareTableFrame(self.entities_frame)
		end
	)
end

function RTN:EnableAllRaresButton(parent_frame)
  parent_frame.enable_all_button = CreateFrame(
		"Button", "RTN.options_panel.rare_selection.enable_all_button", parent_frame, 'UIPanelButtonTemplate'
	)
	
	parent_frame.enable_all_button:SetText("Enable All")
	parent_frame.enable_all_button:SetSize(150, 25)
	parent_frame.enable_all_button:SetPoint("TOPRIGHT", parent_frame, 0, -25)
	parent_frame.enable_all_button:SetScript("OnClick",
		function()
      for i=1, #self.rare_ids do
        local npc_id = self.rare_ids[i]
        RTNDB.ignore_rare[npc_id] = nil
        parent_frame.list_item[npc_id].enable.texture:SetColorTexture(0, 1, 0, 1)
      end
      self:ReorganizeRareTableFrame(self.entities_frame)
		end
	)
end

function RTN:ResetRareOrderButton(parent_frame)
  parent_frame.reset_order_button = CreateFrame(
		"Button", "RTN.options_panel.rare_selection.reset_order_button", parent_frame, 'UIPanelButtonTemplate'
	)
	
	parent_frame.reset_order_button:SetText("Reset Order")
	parent_frame.reset_order_button:SetSize(150, 25)
	parent_frame.reset_order_button:SetPoint("TOPRIGHT", parent_frame, 0, -50)
	parent_frame.reset_order_button:SetScript("OnClick",
		function()
			RTNDB.rare_ordering:Clear()
      for i=1, #self.rare_ids do
        local npc_id = self.rare_ids[i]
        RTNDB.rare_ordering:AddBack(npc_id)
      end
      self:ReorganizeRareTableFrame(self.entities_frame)
      self.ReorderRareSelectionEntryItems(parent_frame)
		end
	)
end

function RTN:InitializeRareSelectionChildMenu(parent_frame)
	parent_frame.rare_selection = CreateFrame("Frame", "RTN.options_panel.rare_selection", parent_frame)
	parent_frame.rare_selection.name = "Rare ordering/selection"
	parent_frame.rare_selection.parent = parent_frame.name
	InterfaceOptions_AddCategory(parent_frame.rare_selection)
	
	parent_frame.rare_selection.frame = CreateFrame(
      "Frame",
      "RTN.options_panel.rare_selection.frame",
      parent_frame.rare_selection
  )
  
	parent_frame.rare_selection.frame:SetPoint("LEFT", parent_frame.rare_selection, 101, 0)
	parent_frame.rare_selection.frame:SetSize(400, 500)
	
	local f = parent_frame.rare_selection.frame
	local i = 1
	f.list_item = {}
	
	RTNDB.rare_ordering:ForEach(
		function(npc_id, entry_data)
			f.list_item[npc_id] = self:CreateRareSelectionEntry(npc_id, f, entry_data)
			f.list_item[npc_id]:SetPoint("TOPLEFT", f, 1, -(i - 1) * 12 - 5)
			i = i + 1
		end
	)
  
  -- Add utility buttons.
  RTN:DisableAllRaresButton(f)
  RTN:EnableAllRaresButton(f)
  RTN:ResetRareOrderButton(f)
end

function RTN:InitializeConfigMenu()
	self.options_panel = CreateFrame("Frame", "RTN.options_panel", UIParent)
	self.options_panel.name = "RareTrackerNazjatar"
	InterfaceOptions_AddCategory(self.options_panel)
	
	self.options_panel.frame = CreateFrame("Frame", "RTN.options_panel.frame", self.options_panel)
	self.options_panel.frame:SetPoint("TOPLEFT", self.options_panel, 11, -14)
	self.options_panel.frame:SetSize(500, 500)

	self.options_panel.sound_selector = self.IntializeSoundSelectionMenu(self.options_panel.frame)
	self.options_panel.minimap_checkbox = self:IntializeMinimapCheckbox(self.options_panel.frame)
	self.options_panel.raid_comms_checkbox = self.IntializeRaidCommunicationCheckbox(self.options_panel.frame)
	self.options_panel.debug_checkbox = self.IntializeDebugCheckbox(self.options_panel.frame)
	self.options_panel.scale_slider = self:IntializeScaleSlider(self.options_panel.frame)
	self:InitializeButtons(self.options_panel.frame)
	self:InitializeRareSelectionChildMenu(self.options_panel)
end
