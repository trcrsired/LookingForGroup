local AceAddon = LibStub("AceAddon-3.0")
local LookingForGroup = AceAddon:GetAddon("LookingForGroup")
local LookingForGroup_Options = AceAddon:GetAddon("LookingForGroup_Options")
local L = LibStub("AceLocale-3.0"):GetLocale("LookingForGroup")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local order = 0
local function get_order()
	local temp = order
	order = order + 1
	return temp
end

local function get_filters()
	local recommended = LookingForGroup_Options.db.profile.recommended
	if recommended then
		return Enum.LFGListFilter.NotRecommended
	elseif recommended == false then
		return
	else
		return Enum.LFGListFilter.Recommended
	end
end

function LookingForGroup_Options.find_search()
	local db = LookingForGroup_Options.db
	local a = db.profile.a
	local category = a.category
	if category then
		coroutine.wrap(function()
			LookingForGroup_Options.Search("lfg_opt_sr_default_multiselect",{"spam","find"},category,get_filters(),0,a.crossfactionlisting)
		end)()
	else
		pcall(LookingForGroup_Options.expected,format(L.must_select_xxx,CATEGORY,SEARCH))
		AceConfigDialog:SelectGroup("LookingForGroup","find")
	end
end

function LookingForGroup_Options.update_editing()
	local profile = LookingForGroup_Options.db.profile
	local s = profile.s
	wipe(s)
	if C_LFGList.HasActiveEntryInfo() then
		C_LFGList.CopyActiveEntryInfoToCreationFields()
		local info = C_LFGList.GetActiveEntryInfo()
		local iLevel = info.requiredItemLevel
		if iLevel == 0 then
			s.minimum_item_level=nil
		else
			s.minimum_item_level=iLevel
		end
		local honorLevel = info.requiredHonorLevel
		if honorLevel == 0 then
			s.minimum_honor_level = nil
		else
			s.minimum_honor_level = honorLevel
		end
		s.quest_id = info.questID
		s.auto_accept,s.private = info.autoAccept or nil, info.privateGroup or nil
-- Todo: Add multi activity support
		local activityIDs, activityIDsInfos = LookingForGroup.getActivityIDsInTable(info, true)
		if not activityIDsInfos or #activityIDsInfos == 0 then
			wipe(profile.a)
			profile.recommended = nil
		else
			local activity_infotb = activityIDsInfos[1]
			local activityID = activity_infotb.activityID
			local categoryID, groupID, filters = activity_infotb.categoryID,activity_infotb.groupFinderActivityGroupID,activity_infotb.filters
			if bit.band(filters,Enum.LFGListFilter.Recommended) == 1 then
				profile.recommended = nil
			elseif bit.band(filters,Enum.LFGListFilter.NotRecommended) == 1 then
				profile.recommended = false
			else
				profile.recommended = true
			end
			local a = profile.a
			wipe(a)
			a.category,a.group,a.activity=categoryID,groupID,activityID
		end
	else
		C_LFGList.ClearCreationTextFields()
	end
end

local activities_select_tb = {}

LookingForGroup_Options:push("find",{
	name = FIND_A_GROUP,
	desc = LFG_LIST_SELECT_A_CATEGORY,
	type = "group",
	childGroups = "tab",
	args =
	{
		category =
		{
			order = get_order(),
			name = function()
				local category = LookingForGroup_Options.db.profile.a.category
				if category then
					return CATEGORY.." |cffff00ff"..category.."|r"
				end
				return CATEGORY
			end,
			type = "select",
			values = function()
				local categorys_tb = {[0]=""}
				local C_LFGList_GetLfgCategoryInfo = C_LFGList.GetLfgCategoryInfo
				local filters = get_filters()
				if filters then
					local categorys = C_LFGList.GetAvailableCategories(filters)
					for i=1,#categorys do
						categorys_tb[categorys[i]] = C_LFGList_GetLfgCategoryInfo(categorys[i]).name
					end
				else
					local i = 1
					local j = 0
					while true do
						local ctg = C_LFGList_GetLfgCategoryInfo(i)
						if ctg == nil then
							j = j + 1
							if j == 150 then
								break
							end
						else
							j = 0
							categorys_tb[i] = ctg.name
						end
						i = i + 1
					end
				end
				return categorys_tb
			end,
			set = function(_,v)
				local a = LookingForGroup_Options.db.profile.a
				local ps = a.playstyle
				wipe(a)
				a.playstyle = ps
				if v ~= 0 then
					a.category = v
				end
				C_LFGList.ClearSearchTextFields()
				LookingForGroup_Options.OnProfileChanged()
			end,
			get = function() return LookingForGroup_Options.db.profile.a.category or 0 end,
			width = 1.5,
		},
		recommanded =
		{
			order = get_order(),
			name = RECOMMENDED,
			desc = L.find_recommended_desc,
			type = "toggle",
			get = function()
				local recommended = LookingForGroup_Options.db.profile.recommended
				if recommended then
					return
				elseif recommended == false then
					return false
				else
					return true
				end
			end,
			set = function(_,val)
				if val then
					LookingForGroup_Options.db.profile.recommended = nil
				elseif val == false then
					LookingForGroup_Options.db.profile.recommended = false
				else
					LookingForGroup_Options.db.profile.recommended = true
				end
			end,
			tristate = true,
		},
		current =
		{
			order = get_order(),
			name = REFORGE_CURRENT,
			type = "execute",
			func = function()
				local activities = C_LFGList.GetAvailableActivities()
				local C_LFGList_GetActivityInfoExpensive = C_LFGList.GetActivityInfoExpensive
				local activity_id
				for i=1,#activities do
					if C_LFGList_GetActivityInfoExpensive(activities[i]) then
						activity_id = activities[i]
						break
					end
				end
				if activity_id == nil then
					return
				end
				local profile = LookingForGroup_Options.db.profile
				local a = profile.a
				C_LFGList.ClearSearchTextFields()
				local activities = a.activities
				local category = a.category
				wipe(a)
				a.activity = activity_id
				a.activities = activities
				local activity_infotb = C_LFGList.GetActivityInfoTable(activity_id)
				local categoryID, groupID, filters = activity_infotb.categoryID,activity_infotb.groupFinderActivityGroupID,activity_infotb.filters
				local LE_LFG_LIST_FILTER_RECOMMENDED = LE_LFG_LIST_FILTER_RECOMMENDED
				if LE_LFG_LIST_FILTER_RECOMMENDED == nil then
					LE_LFG_LIST_FILTER_RECOMMENDED = Enum.LFGListFilter.Recommended
				end
				local LE_LFG_LIST_FILTER_NOT_RECOMMENDED = LE_LFG_LIST_FILTER_NOT_RECOMMENDED
				if LE_LFG_LIST_FILTER_NOT_RECOMMENDED == nil then
					LE_LFG_LIST_FILTER_NOT_RECOMMENDED = Enum.LFGListFilter.NotRecommended
				end
				if bit.band(filters,LE_LFG_LIST_FILTER_RECOMMENDED) == LE_LFG_LIST_FILTER_RECOMMENDED then
					profile.recommended = nil
				elseif bit.band(filters,LE_LFG_LIST_FILTER_NOT_RECOMMENDED) == LE_LFG_LIST_FILTER_NOT_RECOMMENDED then
					profile.recommended = false
				else
					profile.recommended = true
				end
				a.category,a.group = categoryID,groupID
				if category ~= a.category then
						LookingForGroup_Options.OnProfileChanged()
				end
			end
		},
		group =
		{
			order = get_order(),
			name = function()
				local group = LookingForGroup_Options.db.profile.a.group
				if group then
					return GROUP.." |cff00ff00"..group.."|r"
				end
				return GROUP			
			end,
			type = "select",
			values = function()
				local a = LookingForGroup_Options.db.profile.a
				local category = a.category
				local filters = get_filters()
				if filters then
					local groups_tb = {[-1]="",[0]="..."}
					local categorys
					if category then
						categorys = {category}
					else
						categorys = C_LFGList.GetAvailableCategories(filters)
					end
					local C_LFGList_GetAvailableActivityGroups = C_LFGList.GetAvailableActivityGroups
					local C_LFGList_GetActivityGroupInfo = C_LFGList.GetActivityGroupInfo
					for i=1,#categorys do
						local groups = C_LFGList_GetAvailableActivityGroups(categorys[i],filters)
						for i = 1,#groups do
							local groups_i = groups[i]
							groups_tb[groups_i] = C_LFGList_GetActivityGroupInfo(groups_i)
						end
					end
					local grp = a.group
					if grp and groups_tb[grp] == nil then
						groups_tb[grp] = C_LFGList_GetActivityGroupInfo(grp)
					end
					return groups_tb
				end
				local temp = {}
				local i = 1
				local j = 0
				local C_LFGList_GetActivityInfoTable = C_LFGList.GetActivityInfoTable
				local C_LFGList_GetActivityGroupInfo = C_LFGList.GetActivityGroupInfo
				while true do
					local activity_infotb = C_LFGList_GetActivityInfoTable(i)
					local categoryID, groupID
					if activity_infotb then
						categoryID = activity_infotb.categoryID
						groupID = activity_infotb.groupFinderActivityGroupID
					end					
					if categoryID == nil then
						j = j + 1
						if j == 150 then
							break
						end
					else
						j = 0
					end
					if groupID and (category == nil or category == categoryID)  then
						temp[groupID] = true
					end
					i = i + 1
				end
				local groups = {}
				for k,v in pairs(temp) do
					groups[k] = C_LFGList_GetActivityGroupInfo(k)
				end
				groups[-1]=""
				groups[0]="..."
				return groups
			end,
			set = function(_,v)
				local a = LookingForGroup_Options.db.profile.a
				local category = a.category
				local activities = a.activities
				local ps = a.playstyle
				wipe(a)
				C_LFGList.ClearSearchTextFields()
				a.category = category
				a.activities = activities
				a.playstyle = ps
				if v ~= -1 then
					a.group = v
				end
				if category == nil then
					if v == 0 then return end
					local i = 1
					local j = 0
					local C_LFGList_GetActivityInfoTable = C_LFGList.GetActivityInfoTable
					while true do
						local activity_infotb = C_LFGList_GetActivityInfoTable(i)
						local categoryID, groupID = activity_infotb.categoryID,activity_infotb.groupFinderActivityGroupID
						if categoryID == nil then
							j = j + 1
							if j == 150 then
								break
							end
						else
							j = 0
						end
						if groupID == v and categoryID then
							a.category = categoryID
							LookingForGroup_Options.OnProfileChanged()
							return
						end
						i = i + 1
					end					
				end
			end,
			get = function() return LookingForGroup_Options.db.profile.a.group or -1 end,
			width = "full",
		},
		activity =
		{
			order = get_order(),
			name = function()
				local activity = LookingForGroup_Options.db.profile.a.activity
				if activity then
					return LFG_LIST_ACTIVITY.." |cff8080cc"..activity.."|r"
				end
				return LFG_LIST_ACTIVITY			
			end,
			type = "select",
			values = function()
				local a = LookingForGroup_Options.db.profile.a
				local ret = {[0]=""}
				local c,g = a.category,a.group
				local filters = get_filters()
				if filters then
					local res = C_LFGList.GetAvailableActivities(c,g,filters)
					local i
					for i=1,#res do
						local res_i = res[i]
						local activity_infotb = C_LFGList.GetActivityInfoTable(res_i)
						local fullName, shortName = activity_infotb.fullName,activity_infotb.shortName
						if fullName then
							ret[res_i] = fullName
						else
							if shortName then
								ret[res_i] = shortName
							end
						end
					end
				else
					local i = 1
					local j = 0
					while true do
						local activity_infotb = C_LFGList.GetActivityInfoTable(i)
						local fullName, shortName, categoryID, groupID
						if activity_infotb then
							fullName, shortName, categoryID, groupID = activity_infotb.fullName,activity_infotb.shortName,activity_infotb.categoryID,activity_infotb.groupFinderActivityGroupID
						end
						if categoryID == nil then
							j = j + 1
							if j == 150 then
								break
							end
						else
							j = 0
						end
						if (c == nil or c == categoryID) and (g == nil or g == groupID) then
							if fullName then
								ret[i] = fullName
							elseif shortName then
								ret[i] = shortName
							end
						end
						i = i + 1
					end
				end
				return ret
			end,
			set = function(_,v)
				local a = LookingForGroup_Options.db.profile.a
				local activity = a.activity
				C_LFGList.ClearSearchTextFields()
				if v == 0 then
					local category = a.category
					local group = a.group
					local activities = a.activities
					local ps = a.playstyle
					wipe(a)
					a.category = category
					a.group = group
					a.activities = activities
					a.playstyle = ps
				else
					local activities = a.activities
					local category = a.category
					local ps = a.playstyle
					wipe(a)
					a.activity = v
					a.activities = activities
					a.playstyle = ps

					local activity_infotb = C_LFGList.GetActivityInfoTable(v)
					a.category,a.group = activity_infotb.categoryID,activity_infotb.groupFinderActivityGroupID
					if category ~= a.category then
						LookingForGroup_Options.OnProfileChanged()
					end
				end
			end,
			get = function() return LookingForGroup_Options.db.profile.a.activity or 0 end,
			width = "full",
		},
		playstyle =
		{
			order = get_order(),
			name = function()
				local playstyle = LookingForGroup_Options.db.profile.a.playstyle
				if playstyle then
					return LFG_PLAYSTYLE_LABEL_PVE_RAID.." |cff8080cc"..playstyle.."|r"
				end
				return LFG_PLAYSTYLE_LABEL_PVE_RAID	
			end,
			type = "select",
			values = function()
				local hardware_strings =  {"",NONE,GUILD_PLAYSTYLE_CASUAL,GUILD_PLAYSTYLE_MODERATE,GUILD_PLAYSTYLE_HARDCORE}
				if false then
					return hardware_strings
				else
					local a = LookingForGroup_Options.db.profile.a
					local actv = a.activity
					local tb = {""}
					local capable = C_LFGList.IsPlayerAuthenticatedForLFG()
					if actv and capable then
						local activity_infotb = C_LFGList.GetActivityInfoTable(actv)
						local C_LFGList_GetPlayStyleString = C_LFGList.GetPlaystyleString
						for i=1,4 do
							local str = C_LFGList_GetPlayStyleString(i-1,activity_infotb)
							if str == nil or str:len() == 0 then
								str=hardware_strings[i+1]
							end
							tb[i+1]=str
						end
						return tb
					else
						return hardware_strings
					end
				end
			end,
			set = function(_,v)
				if v == 1 then
					LookingForGroup_Options.db.profile.a.playstyle = nil
				else
					LookingForGroup_Options.db.profile.a.playstyle = v - 2
				end
			end,
			get = function()
				local ps = LookingForGroup_Options.db.profile.a.playstyle
				if ps then
					return ps + 2
				else
					return 1
				end
			end,
			width = "full",
		},
		f =
		{
			name = LFG_LIST_FIND_A_GROUP,
			order = get_order(),
			type = "group",
			childGroups = "select",
			args =
			{
				search =
				{
					order = get_order(),
					name = SEARCH,
					type = "execute",
					func = LookingForGroup_Options.find_search
				},
				reset = 
				{
					order = get_order(),
					name = RESET,
					type = "execute",
					func = function()
						wipe(LookingForGroup_Options.db.profile.a)
						C_LFGList.ClearSearchTextFields()
					end
				},
				opt =
				{
					name = BASE_SETTINGS,
					order = get_order(),
					type = "group",
					args =
					{
						role =
						{
							name = ROLE,
							desc = L.find_f_advanced_role,
							type = "toggle",
							get = LookingForGroup_Options.options_get_a_function,
							set = LookingForGroup_Options.options_set_a_function
						},
						class =
						{
							name = CLASS,
							desc = L.find_f_advanced_class,
							type = "toggle",
							get = LookingForGroup_Options.options_get_a_function,
							set = LookingForGroup_Options.options_set_a_function
						},
						armor =
						{
							name = ARMOR,
							desc = L.armor_desc,
							type = "toggle",
							get = LookingForGroup_Options.options_get_a_function,
							set = LookingForGroup_Options.options_set_a_function
						},
						complete =
						{
							name = COMPLETE,
							desc = L.find_f_advanced_complete,
							type = "toggle",
							get = LookingForGroup_Options.options_get_a_function,
							set = LookingForGroup_Options.options_set_a_function
						},
						warmode =
						{
							name = PVP_LABEL_WAR_MODE,
							type = "toggle",
							set = function(_,val)
								LookingForGroup_Options.db.profile.a.warmode = val
							end,
							get = function()
								return LookingForGroup_Options.db.profile.a.warmode
							end,
							tristate = true
						},
						signup=
						{
							name = SIGN_UP,
							desc = L.Auto,
							type = "toggle",
							get = function()
								local hardware = LookingForGroup.db.profile.hardware
								local a = LookingForGroup_Options.db.profile.a
								local signup = a.signup
								if hardware then
									if signup then
										return true
									else
										return false
									end
								else
									if signup then
										return true
									elseif signup == false then
										return
									else
										return false
									end
								end
							end,
							set = function(info,val)
								local hardware = LookingForGroup.db.profile.hardware
								local a = LookingForGroup_Options.db.profile.a
								if hardware then
									if val then
										a.signup = true
									else
										a.signup = nil
									end
								else
									if val then
										a.signup = true
									elseif val == false then
										a.signup = nil
									else
										a.signup = false
									end
								end
							end,
							tristate = true
						},
						filters =
						{
							name =FILTERS,
							type = "toggle",
							set = function(info,val)
								if val then
									LookingForGroup_Options.db.profile.a.filters = nil
								elseif val == false then
									LookingForGroup_Options.db.profile.a.filters = false
								else
									LookingForGroup_Options.db.profile.a.filters = true
								end
							end,
							get = function()
								local d = LookingForGroup_Options.db.profile.a.filters
								if d then
									return
								elseif d == false then
									return false
								else
									return true
								end
							end,
							tristate = true
						},
						gold =
						{
							name ="|TInterface\\MoneyFrame\\UI-GoldIcon:%d:%d:2:0|t",
							type = "toggle",
							desc = L.find_f_advanced_gold,
							set = function(info,val)
								if val then
									LookingForGroup_Options.db.profile.a.gold = true
								elseif val == false then
									LookingForGroup_Options.db.profile.a.gold = nil
								else
									LookingForGroup_Options.db.profile.a.gold = false
								end
							end,
							get = function()
								local d = LookingForGroup_Options.db.profile.a.gold
								if d then
									return true
								elseif d == false then
									return
								else
									return false
								end
							end,
							tristate = true
						},
						ilvl =
						{
							name = ITEM_LEVEL_ABBR,
							desc = LFG_LIST_ITEM_LEVEL_REQ,
							type = "input",
							order = -1,
							get = function()
								local ilv = LookingForGroup_Options.db.profile.a.ilvl
								if ilv then
									return tostring(ilv)
								end
							end,
							set = function(_,val)
								if val == "" then
									LookingForGroup_Options.db.profile.a.ilvl = nil
								else
									local num = tonumber(val)
									local average = GetAverageItemLevel()
									if num <= average then
										LookingForGroup_Options.db.profile.a.ilvl = num
									else
										LookingForGroup_Options.db.profile.a.ilvl = math.floor(average)
									end
								end
							end,
							pattern = "^[0-9]*$"
						},
						crossfactionlisting =
						{
							order = get_order(),
							name = COMMUNITIES_EDIT_DIALOG_CROSS_FACTION,
							type = "toggle",
							set = function(info,val)
								if val then
									LookingForGroup_Options.db.profile.a.crossfactionlisting = true
								elseif val == false then
									LookingForGroup_Options.db.profile.a.crossfactionlisting = nil
								else
									LookingForGroup_Options.db.profile.a.crossfactionlisting = false
								end
							end,
							get = function()
								local d = LookingForGroup_Options.db.profile.a.crossfactionlisting
								if d then
									return true
								elseif d == false then
									return
								else
									return false
								end
							end,
							tristate = true
						},
						newg =
						{
							order = get_order(),
							name = NEW,
							type = "toggle",
							get = LookingForGroup_Options.options_get_a_function,
							set = LookingForGroup_Options.options_set_a_function
						},
						fast =
						{
							order = get_order(),
							name = L.Fast,
							desc = L.Fast_desc,
							type = "toggle",
							get = LookingForGroup_Options.options_get_a_function,
							set = LookingForGroup_Options.options_set_a_function
						},
						diverse =
						{
							name = L.Diverse,
							desc = L.diverse_desc,
							type = "toggle",
							get = LookingForGroup_Options.options_get_a_function,
							set = LookingForGroup_Options.options_set_a_function
						},
						unique =
						{
							name = ITEM_UNIQUE,
							desc = L.unique_desc,
							type = "toggle",
							get = LookingForGroup_Options.options_get_a_function,
							set = LookingForGroup_Options.options_set_a_function
						},
						ft =
						{
							order = get_order(),
							name = nop,
							type = "input",
							dialogControl = "LFG_SECURE_SEARCH_BOX_REFERENCE",
							width = "full",
							order = 0
						},
						ratedbg_bots =
						{
							name = L.ratedbg_bots,
							desc = L.ratedbg_bot_desc,
							type = "toggle",
							get = LookingForGroup_Options.options_get_a_function,
							set = LookingForGroup_Options.options_set_a_function
						}
					},
				},
				act =
				{
					name = LFG_LIST_ACTIVITY,
					order = get_order(),
					type = "group",
					args =
					{
						add =
						{
							order = get_order(),
							name = ADD,
							type = "execute",
							func = function()
								local a = LookingForGroup_Options.db.profile.a
								if not a.category then return end
								local act = a.activity
								local mtc
								if act then
									local activity_infotb = C_LFGList.GetActivityInfoTable(act)
									mtc = activity_infotb.fullName or activity_infotb.shortName
								else
									local grp = a.group
									if grp then
										mtc = C_LFGList.GetActivityGroupInfo(grp)
									end
								end
								local atvs = a.activities
								if atvs then
									for i=1,#atvs do
										if mtc == atvs[i] then
											return
										end
									end
								else
									atvs = {}
									a.activities = atvs
								end
								atvs[#atvs+1] = mtc
							end
						},
						rmv = 
						{
							name = REMOVE,
							type = "execute",
							order = get_order(),
							func = function()
								local a = LookingForGroup_Options.db.profile.a
								local atvs = a.activities
								if atvs then
									local tb = {}
									for i = 1,#atvs do
										if not activities_select_tb[i] then
											tb[#tb+1] = atvs[i]
										end
									end
									if #tb == 0 then
										a.activities = nil
									else
										a.activities = tb
									end
								end
								wipe(activities_select_tb)
							end
						},
						activities_blacklist =
						{
							name = "-",
							type = "toggle",
							order = get_order(),
							get = LookingForGroup_Options.options_get_a_function,
							set = LookingForGroup_Options.options_set_a_function
						},
						activities =
						{
							order = get_order(),
							name = LFG_LIST_ACTIVITY,
							type = "multiselect",
							width = "full",
							values = function()	return LookingForGroup_Options.db.profile.a.activities end,
							get = function(info,key)
								return activities_select_tb[key]
							end,
							set = function(info,key,val)
								if val then
									activities_select_tb[key] = true
								else
									activities_select_tb[key] = nil
								end
							end
						},
					}
				},
			}
		},
		s =
		{
			name = START_A_GROUP,
			order = get_order(),
			type = "group",
			childGroups = "select",
			args =
			{
				cancel = 
				{
					order = get_order(),
					name = CANCEL,
					type = "execute",
					func = LookingForGroup_Options.update_editing
				},
				start =
				{
					order = get_order(),
					name = function()
						if C_LFGList.HasActiveEntryInfo() then
							return DONE_EDITING
						end
						return LIST_GROUP
					end,
					type = "execute",
					func = function()
						local profile = LookingForGroup_Options.db.profile
						if LookingForGroup_Options.listing(profile.a.activity,profile.a.playstyle,profile.s,{"s","f"}) then
							AceConfigDialog:SelectGroup("LookingForGroup","requests")
						end
					end
				},
				s =
				{
					order = 1,
					name = DESCRIPTION,
					type = "group",
					args =
					{
						title =
						{
							order = get_order(),
							name = LFG_LIST_TITLE,
							type = "input",
							dialogControl = "LFG_SECURE_NAME_EDITBOX_REFERENCE",
							width = "full"
						},
						details =
						{
							order = get_order(),
							name = LFG_LIST_DETAILS,
							type = "input",
							multiline = true,
							dialogControl = "LFG_SECURE_DESCRIPTION_EDITBOX_REFERENCE",
							width = "full"
						},
						minitemlvl =
						{
							order = get_order(),
							name = LFG_LIST_ITEM_LEVEL_INSTR_SHORT,
							desc = LFG_LIST_ITEM_LEVEL_REQ,
							type = "input",
							get = function(info)
								local sminilv = LookingForGroup_Options.db.profile.s.minimum_item_level
								if sminilv then
									return tostring(sminilv)
								end
							end,
							pattern = "^[0-9,.,-]*$",
							set = function(info,val)
								if val == "" then
									LookingForGroup_Options.db.profile.s.minimum_item_level = nil
								else
									local player_ilv = GetAverageItemLevel()
									local v = tonumber(val)
									if v then
										if player_ilv < v then
											LookingForGroup_Options.db.profile.s.minimum_item_level = player_ilv
										else
											LookingForGroup_Options.db.profile.s.minimum_item_level = v
										end
									end
								end
							end
						},
						minhonorlvl =
						{
							order = get_order(),
							name = LFG_LIST_HONOR_LEVEL_INSTR_SHORT,
							desc = LFG_LIST_HONOR_LEVEL_REQ,
							type = "input",
							get = function(info)
								local sminilv = LookingForGroup_Options.db.profile.s.minimum_honor_level
								if sminilv then
									return tostring(sminilv)
								end
							end,
							pattern = "^[0-9,.]*$",
							set = function(info,val)
								if val == "" then
									LookingForGroup_Options.db.profile.s.minimum_honor_level = nil
								else
									local player_ilv = math.floor(UnitHonorLevel("player"))
									local v = tonumber(val)
									if v then
										if player_ilv < v then
											LookingForGroup_Options.db.profile.s.minimum_honor_level = player_ilv
										else
											LookingForGroup_Options.db.profile.s.minimum_honor_level = v
										end
									end
								end
							end
						},
						min_dungeon_score =
						{
							order = get_order(),
							name = DUNGEON_SCORE == nil and "DS" or DUNGEON_SCORE,
							type = "input",
							get = function(info)
								local sminds = LookingForGroup_Options.db.profile.s.minimum_dungeon_score
								if sminds then
									return tostring(sminds)
								end
							end,
							pattern = "^[0-9,.]*$",
							set = function(info,val)
								if val == "" then
									LookingForGroup_Options.db.profile.s.minimum_dungeon_score = nil
								else
									local v = tonumber(val)
									if v then
										LookingForGroup_Options.db.profile.s.minimum_dungeon_score = v
									end
								end
							end
						},
						min_pvp_rating =
						{
							order = get_order(),
							name = GUILD_PVP_STATUS,
							desc = GROUP_FINDER_PVP_RATING_REQ_LABEL,
							type = "input",
							get = function(info)
								local sminds = LookingForGroup_Options.db.profile.s.minimum_pvp_rating
								if sminds then
									return tostring(sminds)
								end
							end,
							pattern = "^[0-9,.]*$",
							set = function(info,val)
								if val == "" then
									LookingForGroup_Options.db.profile.s.minimum_pvp_rating = nil
								else
									local v = tonumber(val)
									if v then
										LookingForGroup_Options.db.profile.s.minimum_pvp_rating = v
									end
								end
							end
						},
						vc =
						{
							order = get_order(),
							name = VOICE_CHAT,
							type = "input",
							dialogControl = "LFG_SECURE_VOICE_CHAT_EDITBOX_REFERENCE",
							width = "full",
						},
						auto_accept =
						{
							order = get_order(),
							name = LFG_LIST_AUTO_ACCEPT,
							type = "toggle",
							get = LookingForGroup_Options.options_get_s_function,
							set = LookingForGroup_Options.options_set_s_function
						},
						private =
						{
							order = get_order(),
							name = LFG_LIST_PRIVATE,
							desc = LFG_LIST_PRIVATE_TOOLTIP,
							type = "toggle",
							get = LookingForGroup_Options.options_get_s_function,
							set = LookingForGroup_Options.options_set_s_function
						},
						notcrossfactiongroup = LFG_LIST_CROSS_FACTION and
						{
							order = get_order(),
							name = LFG_LIST_CROSS_FACTION:format(LookingForGroup_Options.player_localized_faction_name),
							desc = LFG_LIST_CROSS_FACTION_TOOLTIP:format(LookingForGroup_Options.player_localized_faction_name),
							type = "toggle",
							get = function(_)
								return LookingForGroup_Options.db.profile.s.notcrossfactiongroup
							end,
							set = function(_,val)
								if val then
									val = true
								else
									val = nil
								end
								LookingForGroup_Options.db.profile.s.notcrossfactiongroup=val
							end
						} or nil,
						quest_id =
						{
							order = get_order(),
							name = BATTLE_PET_SOURCE_2,
							type = "input",
							get = function(info)
								local quest_id = LookingForGroup_Options.db.profile.s.quest_id
								if quest_id then
									return tostring(quest_id)
								end
							end,
							pattern = "^[0-9]*$",
							set = function(info,val)
								local s = LookingForGroup_Options.db.profile.s
								if val == "" or 10 < val:len() then
									s.quest_id = nil
								else
									local n = tonumber(val)
									if C_LFGList.CanCreateQuestGroup(n) then
										LookingForGroup_Options.db.profile.s.quest_id = n
									end
								end
							end,
							width = "full"
						},
					}
				},
				opt =
				{
					name = BASE_SETTINGS,
					order = 2,
					type = "group",
					args =
					{
						minitemlvl =
						{
							name = LFG_LIST_ITEM_LEVEL_INSTR_SHORT,
							desc = LFG_LIST_ITEM_LEVEL_REQ,
							type = "input",
							get = function(info)
								local sminilv = LookingForGroup_Options.db.profile.s.fake_minimum_item_level
								if sminilv then
									return tostring(sminilv)
								end
							end,
							pattern = "^[0-9,.,-]*$",
							set = function(info,val)
								if val == "" then
									LookingForGroup_Options.db.profile.s.fake_minimum_item_level = nil
								else
									local v = tonumber(val)
									if v then
										LookingForGroup_Options.db.profile.s.fake_minimum_item_level = v
									end
								end
							end
						},
						role =
						{
							name = ROLE,
							desc = L.find_f_advanced_role,
							type = "toggle",
							get = LookingForGroup_Options.options_get_s_function,
							set = LookingForGroup_Options.options_set_s_function
						},
						diverse =
						{
							name = L.Diverse,
							desc = L.diverse_desc,
							type = "toggle",
							get = LookingForGroup_Options.options_get_s_function,
							set = LookingForGroup_Options.options_set_s_function
						},
						ratedbg_bots =
						{
							name = L.ratedbg_bots,
							desc = L.ratedbg_bot_desc,
							type = "toggle",
							get = LookingForGroup_Options.options_get_s_function,
							set = LookingForGroup_Options.options_set_s_function
						}
					}
				}
			}
		},
	}
})
