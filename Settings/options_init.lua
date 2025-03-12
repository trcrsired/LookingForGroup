local AceAddon = LibStub("AceAddon-3.0")
local LFG_OPT = AceAddon:NewAddon("LookingForGroup_Options","AceEvent-3.0")
local LookingForGroup = AceAddon:GetAddon("LookingForGroup")
local LFG_C_AddOns = LookingForGroup.C_AddOns

LFG_OPT.player_faction_name,LFG_OPT.player_localized_faction_name = UnitFactionGroup("player")

if LFG_OPT.player_localized_faction_name ==nil or LFG_OPT.player_localized_faction_name:len()==0 then
	if LFG_OPT.player_faction_name == "Neutral" then
		LFG_OPT.player_localized_faction_name = FACTION_NEUTRAL
	else
		LFG_OPT.player_localized_faction_name = LFG_OPT.player_faction_name
	end
end
LFG_OPT.option_table =
{
	type = "group",
	name = LFG_TITLE:gsub(" ","").." |cff8080cc"..LFG_C_AddOns.GetAddOnMetadata("LookingForGroup","Version").."|r",
	args = {}
}

function LFG_OPT:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("LookingForGroup_OptionsDB",{profile ={a={},s={},f={},window_height=600,window_width=840}},true)
end

local order = 0

function LFG_OPT:push(key,val)
	if val.order == nil then
		val.order = order
		order = order + 1
	end
	self.option_table.args[key] = val
end

function LFG_OPT.lfg_frame_is_open()
	return LibStub("AceConfigDialog-3.0").OpenFrames.LookingForGroup
end

function LFG_OPT.expected(message)
	LFG_OPT.lfg_frame_is_open():SetStatusText(message)
	PlaySound(882)
end

local function get_get_set_tb(tb,parameters)
	local t = tb
	for i = 1,#parameters do
		t=t[parameters[i]]
	end
	return t
end

function LFG_OPT.duplicate_table(tb)
	local tb2 = {}
	for k,v in pairs(tb) do
		tb2[k] = v
	end
	return tb2
end

local function generate_get_set(tb,parameters,tristate)
	if parameters == nil then
		parameters = {"db","profile"}
	end
	local get
	if tristate then
		get = function(info)
			local v = get_get_set_tb(tb,parameters)[info[#info]]
			if v then
				return true
			elseif v == nil then
				return false
			else
				return
			end
		end
	else
		get = function(info)
			return get_get_set_tb(tb,parameters)[info[#info]]
		end
	end
	local set
	if tristate then
		set = function(info,val)
			if val then
				get_get_set_tb(tb,parameters)[info[#info]]=true
			elseif val == nil then
				get_get_set_tb(tb,parameters)[info[#info]]=false
			else
				get_get_set_tb(tb,parameters)[info[#info]]=nil
			end
		end

	else
		set = function(info,val)
			if val then
				get_get_set_tb(tb,parameters)[info[#info]]=true
			else
				get_get_set_tb(tb,parameters)[info[#info]]=nil
			end
		end
	end
	if tristate then
		return get,set,
			function(info)
				local val = get(info)
				if val == true then
					return nil
				elseif val == false then
					return false
				else
					return true
				end
			end,
			function(info,val)
				if val == true then
					val = nil
				elseif val == nil then
					val = true
				end
				set(info,val)
			end
	else
		return get,set,function(info) return not get(info) end,function(info,val) set(info,not val) end
	end
end

LFG_OPT.get_function,LFG_OPT.set_function,LFG_OPT.get_function_negative,LFG_OPT.set_function_negative=generate_get_set(LookingForGroup)
LFG_OPT.get_tristate_function,LFG_OPT.set_tristate_function,LFG_OPT.get_tristate_function_negative,LFG_OPT.set_tristate_function_negative=generate_get_set(LookingForGroup,nil,true)
LFG_OPT.options_get_function,LFG_OPT.options_set_function,LFG_OPT.options_get_function_negative,LFG_OPT.options_set_function_negative=generate_get_set(LFG_OPT)
LFG_OPT.options_get_a_function,LFG_OPT.options_set_a_function,LFG_OPT.options_get_a_function_negative,LFG_OPT.options_set_a_function_negative=generate_get_set(LFG_OPT,{"db","profile","a"})
LFG_OPT.options_get_s_function,LFG_OPT.options_set_s_function,LFG_OPT.options_get_s_function_negative,LFG_OPT.options_set_s_function_negative=generate_get_set(LFG_OPT,{"db","profile","s"})
LFG_OPT.options_get_f_function,LFG_OPT.options_set_s_function,LFG_OPT.options_get_f_function_negative,LFG_OPT.options_set_f_function_negative=generate_get_set(LFG_OPT,{"db","profile","f"})
LFG_OPT.options_get_tristate_function,LFG_OPT.options_set_tristate_function,
LFG_OPT.options_get_tristate_function_negative,LFG_OPT.options_set_tristate_function_negative = generate_get_set(LFG_OPT, nil, true)
LFG_OPT.options_get_a_tristate_function,LFG_OPT.options_set_a_tristate_function,
LFG_OPT.options_get_a_tristate_function_negative,LFG_OPT.options_set_a_tristate_function_negative = generate_get_set(LFG_OPT,{"db","profile","a"}, true)
LFG_OPT.options_get_s_tristate_function,LFG_OPT.options_set_s_tristate_function,
LFG_OPT.options_get_s_tristate_function_negative,LFG_OPT.options_set_s_tristate_function_negative = generate_get_set(LFG_OPT,{"db","profile","s"}, true)
LFG_OPT.options_get_f_tristate_function,LFG_OPT.options_set_f_tristate_function,
LFG_OPT.options_get_f_tristate_function_negative,LFG_OPT.options_set_f_tristate_function_negative = generate_get_set(LFG_OPT,{"db","profile","f"}, true)

local player_faction_group = {[0]="Horde",[1]="Alliance",[2]="Neutral", Horde = 0, Alliance = 1, Neutral = 2}
local player_faction_strings = { [0]=FACTION_HORDE, [1]=FACTION_ALLIANCE, [2]=FACTION_NEUTRAL}
local player_faction_colored_strings = { [0]="|cffff0000"..FACTION_HORDE.."|r", [1]="|cff0000ff"..FACTION_ALLIANCE.."|r", [2]="|cff00ff00"..FACTION_NEUTRAL.."|r"}

LFG_OPT.player_faction_group = player_faction_group
LFG_OPT.player_faction_strings = player_faction_strings
LFG_OPT.player_faction_colored_strings = player_faction_colored_strings

local localizedSpecNameToIndex = {}
local GetSpecializationInfoForClassID = GetSpecializationInfoForClassID
LFG_OPT.localizedSpecNameToIndex = localizedSpecNameToIndex

if GetSpecializationInfoForClassID then

for classID = 1, GetNumClasses() do
	local lspectoicontb = localizedSpecNameToIndex[classID]
	lspectoicontb = {}
	localizedSpecNameToIndex[classID] = lspectoicontb
	for specIndex = 1, 5 do
		local specId, localizedSpecName, _, icon = GetSpecializationInfoForClassID(classID, specIndex)
		if localizedSpecName then
			lspectoicontb[localizedSpecName] = specIndex
		end
	end
end
end

function LFG_OPT.IsSelected(groupname)
	local status_table = LibStub("AceConfigDialog-3.0"):GetStatusTable("LookingForGroup")
	if status_table.groups and status_table.groups.selected == groupname then
		return true
	end
end

function LFG_OPT.NotifyChangeIfSelected(groupname)
	if LFG_OPT.IsSelected(groupname) then
		LibStub("AceConfigRegistry-3.0"):NotifyChange("LookingForGroup")
		return true
	end
end

function LFG_OPT.Register(table_name,filtername,func)
	local tbl = LFG_OPT[table_name]
	if tbl == nil then
		tbl = {}
	end
	if filtername then
		local tblf = tbl[filtername]
		if tblf == nil then
			tbl[filtername] = {func}
		else
			tblf[#tblf+1] = func
		end
	else
		tbl[#tbl+1] = func
	end
	LFG_OPT[table_name] = tbl
end

LFG_OPT.Register("category_callbacks",nil,function()
	local st = LibStub("AceConfigDialog-3.0"):GetStatusTable("LookingForGroup")
	local db = LFG_OPT.db
	local profile = db.profile
	local default = db.defaults.profile
	st.height,st.width = profile.window_height or default.window_height,profile.window_width or default.window_width
	st.left,st.top = profile.window_left,profile.window_top
end)

function LFG_OPT:OnEnable()
	local options = LFG_OPT.option_table
	LibStub("AceConfig-3.0"):RegisterOptionsTable("LookingForGroup", options)
	self.db.RegisterCallback(self, "OnProfileChanged", "OnProfileChanged")
	self.db.RegisterCallback(self, "OnProfileCopied", "OnProfileChanged")
	self.db.RegisterCallback(self, "OnProfileReset", "OnProfileChanged")
	self:RegisterMessage("LFG_ICON_LEFT_CLICK")
	self:RegisterMessage("LFG_ChatCommand")
	if self.options_onenable then
		self:options_onenable()
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
					LFG_C_AddOns.LoadAddOn("LookingForGroup_Settings")
					collectgarbage("collect")
					LFG_OPT:SendMessage("LFG_SETTINGS_ENABLED")
				end
			}
		}
	}
	self.OnEnable = nil
	self.OnInitialize = nil
end

function LFG_OPT.OnProfileChanged(update_db)
	if LookingForGroup.lfgsystemactivate then
	local type = type
	local category=LFG_OPT.db.profile.a.category
	local category_callbacks = LFG_OPT.category_callbacks
	local fd = LFG_OPT.option_table.args.find
	local find_args
	local f_args,s_args
	if fd then
		find_args = fd.args
		f_args,s_args = find_args.f.args.opt.args,find_args.s.args.opt.args
	end
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
end

function LFG_OPT:LFG_ChatCommand(message,input)
	if not input or input:trim() == "" then
		LibStub("AceConfigDialog-3.0"):Open("LookingForGroup")
	else
		LibStub("AceConfigCmd-3.0"):HandleCommand("LookingForGroup", "LookingForGroup",input)
	end
end

function LFG_OPT:LFG_ICON_LEFT_CLICK(message,para,...)
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
