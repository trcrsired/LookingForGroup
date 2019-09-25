local AceAddon = LibStub("AceAddon-3.0")
local LookingForGroup = AceAddon:GetAddon("LookingForGroup")
local LookingForGroup_Options = AceAddon:GetAddon("LookingForGroup_Options")

function LookingForGroup_Options:OnEnable()
	local options = LookingForGroup_Options.option_table
	LibStub("AceConfig-3.0"):RegisterOptionsTable("LookingForGroup", options)
	options.args.find.args.profile = LibStub("AceDBOptions-3.0"):GetOptionsTable(LookingForGroup_Options.db)
	self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
	self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")
	self.db.RegisterCallback(self, "OnProfileReset", "OnProfileChanged")
	local GetAddOnMetadata = GetAddOnMetadata
	local GetAddOnInfo = GetAddOnInfo
	local region = GetCurrentRegion()
	for i = 1, GetNumAddOns() do
		local metadata = GetAddOnMetadata(i, "X-LFG-OPT")
		if metadata and (metadata == "0" or region == tonumber(metadata)) then
			LoadAddOn(i)
		end
	end
	self:RegisterEvent("LFG_LIST_ACTIVE_ENTRY_UPDATE")
	self:RegisterMessage("LFG_UPDATE_EDITING")
	self:RegisterMessage("LFG_ICON_LEFT_CLICK")
	self:RegisterMessage("LFG_ChatCommand")
	self:RegisterMessage("LFG_AUTO_MAIN_LOOP")
	self:RegisterEvent("AJ_PVE_LFG_ACTION")
	self:RegisterEvent("AJ_PVP_LFG_ACTION")
	if C_LFGList.HasActiveEntryInfo() then
		coroutine.wrap(self.req_main)()
	end
	self:OnProfileChanged()
	self.option_table.args.settings=
	{
		name = SETTINGS,
		type = "group",
		args =
		{
			enable =
			{
				name = ENABLE,
				type = "execute",
				func = function()
					LoadAddOn("LookingForGroup_Settings")
					collectgarbage("collect")
					LookingForGroup_Options:SendMessage("LFG_SETTINGS_ENABLED")
				end
			}
		}
	}
	self.OnEnable = nil
	self.OnInitialize = nil
end

function LookingForGroup_Options.IsSelected(groupname)
	local status_table = LibStub("AceConfigDialog-3.0"):GetStatusTable("LookingForGroup")
	if status_table.groups and status_table.groups.selected == groupname then
		return true
	end
end

function LookingForGroup_Options.NotifyChangeIfSelected(groupname)
	if LookingForGroup_Options.IsSelected(groupname) then
		LibStub("AceConfigRegistry-3.0"):NotifyChange("LookingForGroup")
		return true
	end
end

function LookingForGroup_Options.OnProfileChanged(update_db)
	local type = type
	local category=LookingForGroup_Options.db.profile.a.category
	local category_callbacks = LookingForGroup_Options.category_callbacks
	local find_args = LookingForGroup_Options.option_table.args.find.args
	local f_args,s_args = find_args.f.args.opt.args,find_args.s.args.opt.args
	for i=1,#category_callbacks do
		local ci = category_callbacks[i]
		if type(ci) == "table" then
			local ok = #ci < 3
			if not ok then
				for j=3,#ci do
					if ci[j] == category then
						ok = true
					end
				end
			end
			if ok then
				ci[1](find_args,f_args,s_args,category)
			else
				ci[2](find_args,f_args,s_args,category)
			end
		elseif update_db then
			ci()
		end
	end
end

function LookingForGroup_Options:LFG_ChatCommand(message,input)
	if not input or input:trim() == "" then
		LibStub("AceConfigDialog-3.0"):Open("LookingForGroup")
	else
		LibStub("AceConfigCmd-3.0"):HandleCommand("LookingForGroup", "LookingForGroup",input)
	end
end

function LookingForGroup_Options:LFG_ICON_LEFT_CLICK(message,para,...)
	local AceConfigDialog = LibStub("AceConfigDialog-3.0")
	if AceConfigDialog.OpenFrames.LookingForGroup then
		AceConfigDialog:Close("LookingForGroup")
	else
		if para then
			AceConfigDialog:SelectGroup(para,...)
		end
		AceConfigDialog:Open("LookingForGroup")
	end
end

function LookingForGroup_Options.aj_open_action(...)
	local AceConfigDialog = LibStub("AceConfigDialog-3.0")
	AceConfigDialog:SelectGroup("LookingForGroup",...)
	AceConfigDialog:Open("LookingForGroup")
end

function LookingForGroup_Options:LFG_UPDATE_EDITING()
	self.update_editing()
	self.aj_open_action("find","s")
end

function LookingForGroup_Options:AJ_PVE_LFG_ACTION()
	self.aj_open_action("find")
end

LookingForGroup_Options.AJ_PVP_LFG_ACTION = LookingForGroup_Options.AJ_PVE_LFG_ACTION
