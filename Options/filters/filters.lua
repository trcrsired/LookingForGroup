local LookingForGroup = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup")
local LookingForGroup_Options = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup_Options")
LookingForGroup_Options.applicant_filters = {}

function LookingForGroup_Options.RegisterFilter(...)
	LookingForGroup_Options.Register("filters",...)
end

function LookingForGroup_Options.RegisterSearchPattern(...)
	LookingForGroup_Options.Register("patterns",...)
end

function LookingForGroup_Options.Unregister(tb_name,filtername,func)
	local tbl = LookingForGroup_Options[tb_name]
	if tbl == nil then
		return
	end
	local f = tbl[filtername]
	if f == nil then
		return
	end
	for i=1,#f do
		if f[i] == func then
			table.remove(f,i)
			return
		end
	end
	if next(f) == nil then
		tbl[filtername] = nil
	end
end

local function null_prepare() return true end

function LookingForGroup_Options.RegisterSimpleFilter(filtername,func,prepare)
	local f = {func,prepare or null_prepare}
	LookingForGroup_Options.RegisterFilter(filtername,f)
	return f
end


function LookingForGroup_Options.RegisterApplicantFilter(filtername,func,prepare)
	local f = LookingForGroup_Options.applicant_filters[filtername]
	local g = {func,prepare or null_prepare}
	if f == nil then
		LookingForGroup_Options.applicant_filters[filtername] = {g}
	else
		f[#f+1] = g
	end
end

function LookingForGroup_Options.RegisterSimpleApplicantFilter(filtername,func,prepare)
	LookingForGroup_Options.RegisterApplicantFilter(filtername,function(applicant_id,profile,a,entryinfo,info,...)
		local b = 0
		local bor = bit.bor
		for i = 1,info.numMembers do
			local ret = func(applicant_id,i,profile,a,entryinfo,info,...)
			if ret then
				b = bor(b,ret)
			end
		end
		return b
	end,prepare)
end

function LookingForGroup_Options.RegisterSimpleFilterExpensive(filtername,func,prepare)
	local f = {function(info,profile,a,tb,k)
		local searchResultID = info.searchResultID
		while true do
			if not info.leaderName then
				info = C_LFGList.GetSearchResultInfo(searchResultID)
				tb[k] = info
			end
			if info and info.leaderName then
				local ok,r = pcall(func,info,profile,a,tb,k)
				if ok then
					return r
				end
				LookingForGroup_Options.Paste(r,nop)
				return
			end
			local current = coroutine.running()
			if current == nil then		--not running coroutine
				return 1
			end
			local ticker = C_Timer.NewTicker(0.1,function()
				local t = C_LFGList.GetSearchResultInfo(searchResultID)
				tb[k] = t
				if t.leaderName then
					LookingForGroup.resume(current,"LFG_LIST_SEARCH_RESULT_UPDATED",searchResultID)
				end
			end)
			LookingForGroup_Options:RegisterEvent("LFG_LIST_SEARCH_RESULT_UPDATED",function(event,resultID)
				if searchResultID == resultID then
					LookingForGroup.resume(current,event,resultID)
				else
					tb[k] = C_LFGList.GetSearchResultInfo(resultID)
				end
			end)
			while coroutine.yield()~= "LFG_LIST_SEARCH_RESULT_UPDATED" do end	--block any yield value
			LookingForGroup_Options:UnregisterEvent("LFG_LIST_SEARCH_RESULT_UPDATED")
			ticker:Cancel()
		end
		return 1
	end,prepare or null_prepare}
	LookingForGroup_Options.RegisterFilter(filtername,f)
	return f
end

local function simplefilter(filters,result,filter_options,...)
	local type = type
	local band = bit.band
	local bor = bit.bor
	local b = 0
	local profile = LookingForGroup_Options.db.profile
	for i=1,#filter_options do
		local f = filters[filter_options[i]]
		if f then
			for j=1,#f do
				local fj = f[j]
				if type(fj) == "table" then
					local a = fj[2](profile,...)
					if a then
						b = bor(b,fj[1](result,profile,a,...) or 0)
						if 3 < b then
							return b
						end
					end
				end
			end
		end
	end
	return b
end

function LookingForGroup_Options.ExecuteApplicantFilter(result,...)
	local ok,b = pcall(simplefilter,LookingForGroup_Options.applicant_filters,result,...)
	if not ok then
		LookingForGroup_Options.Paste(b,nop)
		return true
	end
	if b < 4 and bit.band(b,1) == 0 then
		return true
	end
end

function LookingForGroup_Options.Execute(bts,tb,table_name,info_func,results,filter_options,first)
	wipe(bts)
	for i=1,#results do
		bts[i]=0
	end
	local profile = LookingForGroup_Options.db.profile
	local filters = LookingForGroup_Options[table_name]
	local type = type
	local band = bit.band
	local bor = bit.bor
	wipe(tb)
	for i=1,#results do
		tb[i] = info_func(results[i]) or false
	end
	for i=1,#filter_options do
		local f = filters[filter_options[i]]
		if f then
			for j=1,#f do
				local fj = f[j]
				if type(fj) == "table" then
					local a = fj[2](profile,first)
					if a then
						local simple_filter_func = fj[1]
						for k=1,#results do
							local b = bts[k]
							if b < 4 then
								bts[k] = bor(b,simple_filter_func(tb[k],profile,a,tb,k) or 0)
							end
						end
					end
				else
					fj(tb,bts,first,profile)
				end
			end
		end
	end
end

function LookingForGroup_Options.ExecuteFilter(bts,tb,results,filter_options,first)
	local profile = LookingForGroup_Options.db.profile
	LookingForGroup_Options.Execute(bts,tb,"filters",C_LFGList.GetSearchResultInfo,results,filter_options,first)
	local C_LFGList_ReportSearchResult = C_LFGList.ReportSearchResult
	wipe(tb)
	local band = bit.band
	local bor = bit.bor
	local a_filters = profile.a.filters
	local gold = profile.a.gold
	if gold ~= nil then
		for i=1,#results do
			local v = bts[i]
			local w = a_filters == false
			if not w then
				w = band(v,1) == 0
				if a_filters then
					w= not w
				end
			end
			local gw = gold == false
			if not gw then
				gw = 1 < v
			end
			if gw and w then
				tb[#tb+1] = results[i]
			end
		end
	else
		local auto_report 
		if LookingForGroup.db.profile.hardware then
			if first and not profile.auto_report then
				auto_report = true
			end
		else
			auto_report = not profile.auto_report
		end
		local leadername_ignore_tb
		UIErrorsFrame:UnregisterEvent("UI_INFO_MESSAGE") -- Don't show the "Thanks for the report" message
		DEFAULT_CHAT_FRAME:UnregisterEvent("CHAT_MSG_SYSTEM")
		for i=1,#results do
			local v = bts[i]
			local g = results[i]
			if v < 2 then
				local w = a_filters == false
				if not w then
					w = band(v,1) == 0
					if a_filters == true then
						w = not w
					end
				end
				if w then
					tb[#tb+1] = g
				end
			elseif 3 < v and auto_report then
				if band(v,32) == 32 then
					local leaderName = GetSearchResultInfo(g).leaderName
					if leaderName then
						if leadername_ignore_tb == nil then
							leadername_ignore_tb = {}
						end
						leadername_ignore_tb[leaderName:lower()] = 0
					end
				end
			end
		end
		DEFAULT_CHAT_FRAME:RegisterEvent("CHAT_MSG_SYSTEM")
		C_Timer.After(0.5,function()
			UIErrorsFrame:RegisterEvent("UI_INFO_MESSAGE")
		end)
		if leadername_ignore_tb then
			local keywords = LookingForGroup.db.profile.spam_filter_keywords
			if keywords == nil then
				keywords = {}
			end
			for i=1,#keywords do
				leadername_ignore_tb[keywords[i]] = nil
			end
			for k,v in pairs(leadername_ignore_tb) do
				keywords[#keywords+1] = k
			end
			if #keywords == 0 then
				LookingForGroup.db.profile.spam_filter_keywords = nil
			else
				LookingForGroup.db.profile.spam_filter_keywords = keywords
			end
		end
	end
	LookingForGroup_Options.SortSearchResults(tb)
	return tb
end

function LookingForGroup_Options.do_auto_accept(LFGList,filters,entryinfo,app_invited,app_applied,app,ap)
--	local autoaccept_to_invite_hash_tb = {}
--	local auto_accept_filters = LookingForGroup_Options.auto_accept_filters

	local profile = LookingForGroup.db.profile
	local hardware = profile.hardware
	local nhp___InviteApplicant = not hardware or LFGList.nhp___InviteApplicant

	local activityInfo = entryinfo.activityInfo

	local numInvited = LFGList.GetNumInvitedApplicantMembers()
	local groupmembers = GetNumGroupMembers(LE_PARTY_CATEGORY_HOME)
	if groupmembers == 0 then
		groupmembers = 1
	end
	local maxNumPlayers = activityInfo.maxNumPlayers
	if profile.categoryID == 9 then
		maxNumPlayers = 10
	end
	if maxNumPlayers ~=0 and numInvited + groupmembers >= activityInfo.maxNumPlayers then
		return
	end

	local total_players = numInvited + groupmembers
--[[
	local role = LookingForGroup.db.profile.s.role
	if role then
		if #app_invited ~= 0 then
			return
		end
		local need_tank = 0 
		local need_healer = 0
		local need_dps = 0
		local categoryID = activityInfo.categoryID
		if categoryID == 9 then
			need_healer = 3
			need_dps = 7
		elseif categoryID ~= 1 then
			need_healer = math.ceil(maxNumPlayers/5)
			if categoryID == 2 or categoryID == 3 or categoryID == 6 or categoryID == 113 then
				if maxNumPlayers >= 10 then
					need_tank = 2
				else
					need_tank = 1
				end
				need_dps = maxNumPlayers - need_tank-need_healer
			end
		end
		local groupmembercounts = GetGroupMemberCounts()
		local tanks_count = groupmembercounts.TANK
		local healers_count = groupmembercounts.HEALER
		local dps_count = groupmembercounts.NOROLE + groupmembercounts.DAMAGER
		if tanks_count < need_tank then
			total_players = need_tank - tanks_count + total_players
		end
		if healers_count < need_healer then
			total_players = need_healer - healers_count + total_players
		end
		if dps_count < need_dps then
			total_players = need_dps - dps_count + total_players
		end
	end]]
	local C_PartyInfo_InviteUnit = LFGList.InviteUnit or C_PartyInfo.InviteUnit
	for i=1,#app_applied do
		if maxNumPlayers ~=0 and total_players >= maxNumPlayers then
			break
		end
		local info = app_applied[i]
		local numMembers = info.numMembers
		if maxNumPlayers == 0 or numMembers+total_players <= maxNumPlayers then
			if numMembers == 1 or nhp___InviteApplicant then
				if nhp___InviteApplicant then
					LFGList.InviteApplicant(info.applicantID)
				else
					local name = LFGList.GetApplicantMemberInfo(info.applicantID,1)
					C_PartyInfo_InviteUnit(name)
				end
				total_players = total_players + total_players
			end
		end
	end
	if maxNumPlayers ~=0 and total_players >= maxNumPlayers then
		if profile.taskbar_flash  then
			FlashClientIcon()
		end
		if not profile.mute then
			PlaySound(SOUNDKIT.RAID_WARNING)
		end
	end
end

function LookingForGroup_Options.ExecuteSearchPattern(filter_options)
	local patterns = LookingForGroup_Options.patterns
	local profile = LookingForGroup_Options.db.profile
	local a = profile.a
	local category = a.category
--	local dbf_mx_length = category == 2 and 3 or 1
	for i=1,#filter_options do
		local f = patterns[filter_options[i]]
		if f then
			for j=1,#f do
--[[				local r = f[j](profile,a,category,p)
				if r then
					if #r <= dbf_mx_length then
						p[#p+1] = {matches = r}
					end
				end]]
				f[j](profile,a,category)
			end
		end
	end
end

function LookingForGroup_Options.execute_flags(name)
	local flags = LookingForGroup.flags
	if flags then
		local realm = name:match("-(.*)$")
		if realm == nil then
			realm = GetNormalizedRealmName()
		end
		local language = flags[3][realm]
		if language then
			return flags[2][language]
		end
	end
end
