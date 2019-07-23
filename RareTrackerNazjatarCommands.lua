local _, data = ...

local RTN = data.RTN

-- ####################################################################
-- ##                        Command Handlers                        ##
-- ####################################################################

-- Process the given command.
function CommandHandler(msg, editbox)
	-- pattern matching that skips leading whitespace and whitespace between cmd and args
	-- any whitespace at end of args is retained
	local _, _, cmd, args = string.find(msg, "%s?(%w+)%s?(.*)")
   
	if cmd == "show" then
		if RTN.last_zone_id and RTN.target_zones[RTN.last_zone_id] then
			RTN:Show()
			RTNDB.show_window = true
		end
	elseif cmd == "hide" then
		RTN:Hide()  
		RTNDB.show_window = false
	else 
		InterfaceOptionsFrame_Show()
		InterfaceOptionsFrame_OpenToCategory(RTN.options_panel)
	end
end

-- Register the slashes that can be used to issue commands.
SLASH_RTN1 = "/rtn"
SlashCmdList["RTN"] = CommandHandler
