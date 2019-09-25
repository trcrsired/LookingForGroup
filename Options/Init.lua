local AceAddon = LibStub("AceAddon-3.0")
local LookingForGroup_Options = AceAddon:NewAddon("LookingForGroup_Options","AceEvent-3.0")
local LookingForGroup = AceAddon:GetAddon("LookingForGroup")

LookingForGroup_Options.option_table =
{
	type = "group",
	name = LFG_TITLE:gsub(" ","").." |cff8080cc"..GetAddOnMetadata("LookingForGroup","Version").."|r",
	args = {}
}

function LookingForGroup_Options:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("LookingForGroup_OptionsDB",{profile ={a={},s={},window_height=600,window_width=840}},true)
end

local order = 0

function LookingForGroup_Options:push(key,val)
	if val.order == nil then
		val.order = order
		order = order + 1
	end
	self.option_table.args[key] = val
end

function LookingForGroup_Options.lfg_frame_is_open()
	return LibStub("AceConfigDialog-3.0").OpenFrames.LookingForGroup
end

function LookingForGroup_Options.expected(message)
	LookingForGroup_Options.lfg_frame_is_open():SetStatusText(message)
	PlaySound(882)
end

function LookingForGroup_Options.listing(activity,s,filters,back_list,provider,...)
	local quest_id = s.quest_id
	local expected = s.expected or LookingForGroup_Options.expected
	if quest_id then
		if not activity then
			activity = C_LFGList.GetActivityIDForQuestID(quest_id) or 16
		end
	else
		if not activity then
			local L = LibStub("AceLocale-3.0"):GetLocale("LookingForGroup")
			expected(format(L.must_select_xxx,LFG_LIST_ACTIVITY,START_A_GROUP))
			LibStub("AceConfigDialog-3.0"):SelectGroup("LookingForGroup","find")
			return
		end
	end
	local listing
	provider = provider or C_LFGList
	if C_LFGList.HasActiveEntryInfo() then
		local actv = C_LFGList.GetActiveEntryInfo().activityID
		activity = actv
		listing = provider.UpdateListing
		if quest_id == nil and LFGListFrame.EntryCreation.Name:GetText()=="" then
			expected(LFG_LIST_MUST_HAVE_NAME)
			return
		end
		LookingForGroup_Options:SendMessage("LFG_LIST_OR_UPDATE")
	else
		listing = provider.CreateListing
		if quest_id == nil and LFGListFrame.EntryCreation.Name:GetText()=="" then
			expected(LFG_LIST_MUST_HAVE_NAME)
			return
		end
	end
	if listing(activity,s.minimum_item_level or 0,s.minimum_honor_level or 0,s.auto_accept or false,s.private or false,quest_id) then
		if not active then
			coroutine.wrap(LookingForGroup_Options.req_main)(s.auto_accept,filters,back_list,provider,...)
		end
		return true
	else
		expected(FAILED)
	end
end

local function get_get_set_tb(tb,parameters)
	local t = tb
	for i = 1,#parameters do
		t=t[parameters[i]]
	end
	return t
end

local function generate_get_set(tb,parameters)
	if parameters == nil then
		parameters = {"db","profile"}
	end
	local function get(info)
		return get_get_set_tb(tb,parameters)[info[#info]]
	end
	local function set(info,val)
		if val then
			get_get_set_tb(tb,parameters)[info[#info]]=true
		else
			get_get_set_tb(tb,parameters)[info[#info]]=nil
		end
	end
	return get,set,function(info) return not get(info) end,function(info,val) set(info,not val) end
end


LookingForGroup_Options.get_function,LookingForGroup_Options.set_function,LookingForGroup_Options.get_function_negative,LookingForGroup_Options.set_function_negative=generate_get_set(LookingForGroup)

LookingForGroup_Options.options_get_function,LookingForGroup_Options.options_set_function,LookingForGroup_Options.options_get_function_negative,LookingForGroup_Options.options_set_function_negative=generate_get_set(LookingForGroup_Options)

LookingForGroup_Options.options_get_a_function,LookingForGroup_Options.options_set_a_function,LookingForGroup_Options.options_get_a_function_negative,LookingForGroup_Options.options_set_a_function_negative=generate_get_set(LookingForGroup_Options,{"db","profile","a"})

LookingForGroup_Options.options_get_s_function,LookingForGroup_Options.options_set_s_function,LookingForGroup_Options.options_get_s_function_negative,LookingForGroup_Options.options_set_s_function_negative=generate_get_set(LookingForGroup_Options,{"db","profile","s"})
