local LookingForGroup = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup")
local LookingForGroup_Options = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup_Options")

local function issubstr(s,substr)
	local sbyte = string.byte
	local i = 1
	local slen = s:len()
	local substr_len = substr:len()
	local j = 1
	while i <= slen and j <= substr_len do
		if sbyte(s,i) == sbyte(substr,j) then
			j = j + 1
		else
			j = 1
		end
		i = i + 1
	end
	if substr_len < j then
		return true
	end
end

LookingForGroup_Options.RegisterSearchPattern("find",function(profile,a,category)
	if LFGListFrame.SearchPanel.SearchBox:GetText():len() == 0 and a.activity then
		C_LFGList.SetSearchToActivity(a.activity)
	end
end)


LookingForGroup_Options.RegisterSimpleFilter("find",function(info,profile,class)
	local class_tb = C_LFGList.GetSearchResultMemberCounts(info.searchResultID)
	if class_tb and class_tb[class] < 2 then
		return 1
	end
end,function(profile)
	if profile.a.class then
		return select(2,UnitClass("player"))
	end
end)

LookingForGroup_Options.RegisterSimpleFilter("find",function(info,profile,armor)
	local class_tb = C_LFGList.GetSearchResultMemberCounts(info.searchResultID)
	local atleast = info.numMembers * 0.4
	if atleast < 2 then
		atleast = 2
	end
	local total = 0
	for k,v in pairs(armor) do
		total = total + class_tb[k]
		if atleast <= total then
			return 0
		end
	end
	return 1
end,function(profile)
	if profile.a.armor then
		local classlocalized,class,id = UnitClass("player")
		local leather = {DEMONHUNTER=true,DRUID=true,MONK=true,ROGUE=true}
		if leather[class] then
			return leather
		end
		local cloth = {MAGE=true,PRIEST=true,WARLOCK=true}
		if cloth[class] then
			return cloth
		end
		local plate = {DEATHKNIGHT=true,PALADIN=true,WARRIOR=true}
		if plate[class] then
			return plate
		end
		local mail = {HUNTER=true,SHAMAN=true,EVOKER=true}
		if mail[class] then
			return mail
		end
	end
end)

LookingForGroup_Options.RegisterSimpleFilter("find",function(info,profile,classroleinfo)
	local C_LFGList_GetSearchResultMemberInfo = C_LFGList.GetSearchResultMemberInfo
	local id = info.searchResultID
	local bit_band = bit.band
	for i=1,info.numMembers do
		local role, class = C_LFGList_GetSearchResultMemberInfo(id,i)
		local classroletb = classroleinfo[class]
		if classroletb then
			if role == "TANK" then
				if bit_band(classroletb,1)==1 then
					return 1
				end
			elseif role == "HEALER" then
				if bit_band(classroletb,2)==2 then
					return 1
				end
			elseif bit_band(classroletb,4)==4 then
				return 1
			end
		end
	end
end,function(profile)
	if profile.a.unique then
		local UnitClass = UnitClass
		local classlocalized,class,id = UnitClass("player")
		local leader,t,h,d = GetLFGRoles()
		if not t and not h and not d then
			d = true
		end
		local bit_bor = bit.bor
		local classroletb = {[class]=bit_bor((d and 4 or 0),bit_bor((t and 1 or 0),(h and 2 or 0)))}
		if IsInGroup() and not UnitInRaid("player") then	-- player not raid this would apply to entire group
			local UnitGroupRolesAssigned = UnitGroupRolesAssigned
			for i=1,GetNumGroupMembers()-1 do
				local unit = "party"..i
				local pclasslocalized,pclass = UnitClass(unit)
				if pclass then
					local crtbent = classroletb[pclass]
					if crtbent == nil then
						crtbent = 0
					end
					local role = UnitGroupRolesAssigned(unit)
					if role then
						if role == "TANK" then
							crtbent = bit_bor(crtbent,1)
						elseif role == "HEALER" then
							crtbent = bit_bor(crtbent,2)
						else
							crtbent = bit_bor(crtbent,4)
						end
					end
					if crtbent == 0 then
						classroletb[pclass] = nil
					else
						classroletb[pclass] = crtbent
					end
				end
			end
		end
		return classroletb
	end
end)

LookingForGroup_Options.RegisterSimpleFilter("find",function(info,profile,ilvl)
	if info.requiredItemLevel < ilvl then
		return 1
	end
end,function(profile)
	return profile.a.ilvl
end)

LookingForGroup_Options.RegisterSimpleFilter("find",function(info)
	local activityIDs = LookingForGroup.getActivityIDsInTable(info)
	for i=1,#activityIDs do
		if info.numMembers * 3 < C_LFGList.GetActivityInfoTable(activityIDs[i]).maxNumPlayers * 2 then
			return 1
		end
	end
end,function(profile)
	return profile.a.complete
end)


LookingForGroup_Options.RegisterSimpleFilter("find",function(info,profile,last_time)
	if GetTime() < info.age + last_time then
		return 1
	end
end,function(profile,first)
	local a = profile.a
	if first then
		if a.current_time then
			a.last_time = a.current_time
		end
		a.current_time = GetTime()
	end
	if a.newg then
		return a.last_time
	end
end)

LookingForGroup_Options.RegisterSimpleApplicantFilter("s",function(id,pos,profile,func)
	local name = C_LFGList.GetApplicantMemberInfo(id,pos)
	return func(name) and 1
end,function()
	local lfg_profile = LookingForGroup.db.profile
	if (lfg_profile.mode_rf ~= nil) or
		(not lfg_profile.flags_disable and lfg_profile.flags) then
		return LookingForGroup.realm_filter
	end
end)

LookingForGroup_Options.RegisterSimpleApplicantFilter("s",function(id,pos,profile,fakeilvl)
	local name, class, localizedClass, level, itemLevel, honorLevel, tank, healer, damage, assignedRole, relationship = C_LFGList.GetApplicantMemberInfo(id,pos)
	if itemLevel < fakeilvl then
		return 1
	end
end,function(profile)
	return profile.s.fake_minimum_item_level
end)

LookingForGroup_Options.RegisterSimpleApplicantFilter("s",function(id,pos,profile)
	local entry = C_LFGList.GetActiveEntryInfo()
	local ratinginfo = C_LFGList.GetApplicantPvpRatingInfoForListing(id,pos,entry.activityID)
	if ratinginfo then
		if leader_rating_info.rating and leader_rating_info.rating > 784 then
			return 1
		end
		for i=1,#leader_rating_info do
			local rating = leader_rating_info[i].rating
			if rating and rating > 784 then
				return 1
			end
		end
	else
		return 1
	end
end,function(profile)
	return profile.s.ratedbg_bots
end)

LookingForGroup_Options.RegisterSimpleFilter("find",function(info)
	if info.requiredPvpRating >= 1000 then
		return 1
	end
	local leader_rating_info = info.leaderPvpRatingInfo
	if leader_rating_info then
		if leader_rating_info.rating and leader_rating_info.rating >= 1000 then
			return 1
		end
		for i=1,#leader_rating_info do
			for k,v in paris(leader_rating_info[i]) do
				print(k,v)
			end
			local rating = leader_rating_info[i].rating
			if rating and rating >= 1000 then
				return 1
			end
		end
	end
end,function(profile)
	return profile.a.ratedbg_bots
end)
	

LookingForGroup_Options.RegisterSimpleFilter("spam",function(info)
	local numMembers = info.numMembers
	if numMembers < 2 then
		local activityIDs = LookingForGroup.getActivityIDsInTable(info)
		for i=1,#activityIDs do
			local categoryID = C_LFGList.GetActivityInfoTable(activityIDs[i]).categoryID
			local age = info.age
			if numMembers == 1 then
				if 3600 < age then
					return 2
				else
					if categoryID == 3 or categoryID == 9 then
						if 300 < age then
							return 2
						end
					end
				end
			elseif numMembers == 2 then
				if categoryID == 3 or categoryID == 9 then
					if 3600 < age then
						return 2
					end
				end
			end
		end
	end
end,function(profile)
	return not profile.spam_filter_solo
end)


LookingForGroup_Options.RegisterSimpleFilterExpensive("spam",function(info,profile,sf_kw)
	local leaderName = info.leaderName:lower()
	for i=1,#sf_kw do
		if issubstr(leaderName,sf_kw[i]) then
			return 8
		end
	end
end,function()
	local lfg_profile = LookingForGroup.db.profile
	return not lfg_profile.spam_filter_player_name and lfg_profile.spam_filter_keywords
end)

LookingForGroup_Options.RegisterSimpleFilter("spam",function(info,profile)
	local iLvl = info.requiredItemLevel
	if iLvl~=0 then
		local activityIDs = LookingForGroup.getActivityIDsInTable(info)
		for i=1,#activityIDs do
			if iLvl < C_LFGList.GetActivityInfoTable(activityIDs[i]).ilvlSuggestion then
				return 8
			end
		end
	end
end,function(profile)
	return not profile.spam_filter_ilvl
end)

LookingForGroup_Options.RegisterSimpleFilterExpensive("spam",function()
	return 32
end,
function()
	return LookingForGroup_Options.spam_filter_ignore_all and LFGListFrame.SearchPanel.SearchBox:GetText():len()~=0
end)

LookingForGroup_Options.RegisterSimpleFilter("spam",function(info)
	local activityIDs = LookingForGroup.getActivityIDsInTable(info)
	for i=1,#activityIDs do
		if C_LFGList.GetActivityInfoTable(activityIDs[i]).groupFinderActivityGroupID == 136 then
			return 8
		end
	end
end,function(profile)
	return not profile.spam_filter_activity and profile.a.group ~= 136
end)


LookingForGroup_Options.RegisterSimpleFilter("spam",function(info,profile,length)
	local approximate_length= LookingForGroup_Options.approximate_length
	if length < approximate_length(info.name) or length < approximate_length(info.comment) or length < approximate_length(info.voiceChat) then
		return 8
	end
end,function(profile)
	local maxlen =  LookingForGroup.db.profile.spam_filter_maxlength
	if maxlen then
		if GetCurrentRegion()==5 then
			return maxlen/3
		end
		return maxlen
	end
end)

LookingForGroup_Options.RegisterSimpleFilter("spam",function(info)
	local rse = C_LFGList.GetSearchResultEncounterInfo(info.searchResultID)
	local age = info.age
	if rse then
		if 36000 < age then
			return 8
		end
	elseif 1200 < age then
		if 10800 < age then
			return 8
		end
		return 2
	end
end,function(profile) return not profile.spam_filter_ages end)

LookingForGroup_Options.RegisterSimpleFilter("spam",function(info)
	if info == nil or info.isDelisted then
		return 1
	end
	local _, appStatus = C_LFGList.GetApplicationInfo(info.searchResultID)
	if appStatus ~= "none" then
		return 1
	end
end)

LookingForGroup_Options.RegisterSimpleFilter("find",function(info)
	if info.numMembers == 4 and 2400 < info.age then
		local activityIDs = LookingForGroup.getActivityIDsInTable(info)
		for i=1,#activityIDs do
			local categoryID = C_LFGList.GetActivityInfoTable(activityIDs[i]).categoryID
			if categoryID == 2 then
				local tb = C_LFGList.GetSearchResultMemberCounts(info.searchResultID)
				if tb.TANK == 1 and tb.HEALER == 1 then
					return 8
				end
			end
		end
	end
end,function(profile)
	return not profile.spam_filter_fast
end)

LookingForGroup_Options.RegisterSimpleFilter("find",function(info,profile)
-- Todo fix here
	local a = profile.a
	local val = a.activities_blacklist and 1 or 0
	local reverse_val = val == 1 and 0 or 1
	local activityIDs = LookingForGroup.getActivityIDsInTable(info)
	for i=1,#activityIDs do
		local activityID = activityIDs[i]
		local activity_infotb = C_LFGList.GetActivityInfoTable(activityID)
		local fullName, shortName, groupID = activity_infotb.fullName,activity_infotb.shortName,activity_infotb.groupFinderActivityGroupID
		local fsname = fullName or shortName

		if a.activity then
			if a.activity == activityID then
				return val
			end
		elseif a.group then
			if a.group == groupID then
				return val
			end
		end
		local activities = a.activities
		if activities and next(activities) then
			for i=1,#activities do
				local ctv = activities[i]
				if issubstr(fsname,ctv) then
					return val
				end
			end
		elseif a.activity == nil and a.group == nil then
			return val
		end
	end
	return reverse_val
end)

LookingForGroup_Options.RegisterSimpleFilter("find",function(info,profile,membercounts)
	local this_group = C_LFGList.GetSearchResultMemberCounts(info.searchResultID)

	local GetClassInfo = GetClassInfo
	local numclasses = GetNumClasses()
	local activityIDs = LookingForGroup.getActivityIDsInTable(info)
	for j=1,#activityIDs do
		local activity_infotb = C_LFGList.GetActivityInfoTable(activityIDs[j])
		local maxPlayers = activity_infotb.maxNumPlayers
		if maxPlayers < numclasses then
			for i=1,numclasses do
				local id,class = GetClassInfo(i)
				if 1 < this_group[class] then
					return 1
				end
			end
		end
		for i=1,numclasses do
			local id,class = GetClassInfo(i)
			if this_group[class] == 0 and membercounts[class] ~= 0 then
				return
			end
		end
	end
	return 1
end,function(profile)
	if profile.a.diverse then
		local membercounts = GetGroupMemberCounts()
		if not IsInGroup() then
			local classlocalized,class,id = UnitClass("player")
			membercounts[class] = 1
		end
		return membercounts
	end
end)

local label = UIParent:CreateFontString(nil, "BACKGROUND","GameFontHighlightSmall")
label:Hide()
label:SetFont("Fonts\\FRIZQT__.TTF",1)

function LookingForGroup_Options.approximate_length(encrypt_string)
	if encrypt_string:len() == 0 then
		return 0
	end
	label:SetText("O")
	local o_size = label:GetStringWidth()
	label:SetText(encrypt_string)
	local string_height = label:GetStringHeight()
	if string_height == 0 then
		return math.floor(label:GetStringWidth()/o_size)
	end
	return math.floor(string_height*label:GetStringWidth()/o_size)
end

LookingForGroup_Options.RegisterSimpleFilter("spam",function(info)
	if 10000 < info.age and 0 < info.comment:len() and info.name == info.comment then
		return 8
	end
end,function(profile)
	return profile.spam_filter_equal
end)

LookingForGroup_Options.RegisterFilter("spam",function(infos,bts,first,profile)
	if not profile.spam_filter_equal then
		return
	end
	local hash = {}
	local categoryID
	for i=1,#infos do
		local info = infos[i]
		repeat
		if not info then
			break
		end
		if not categoryID then
			local activityIDs = LookingForGroup.getActivityIDsInTable(info)
			for j=1,activityIDs do	
				categoryID = C_LFGList.GetActivityInfoTable(activityIDs[j]).categoryID
				if categoryID == 1 then
					return
				end
			end
		end
		if info.questID then
			break
		end
		local name,comment = info.name,info.comment
		if comment:len() == 0 and LookingForGroup_Options.approximate_length(name) < 5 then
			break
		end
		local v = name..comment
		local t = hash[v]
		if t == nil then
			t = {}
			hash[v] = t
		end
		t[#t+1] = i
		until true
	end
	local limits = 2
	local slen = string.len
	local bor = bit.bor
	for k,v in pairs(hash) do
		local lm = limits
		if slen(k) == 8 then
			lm = lm * 4
		end
		if lm < #v then
			for i=1,#v do
				local e=v[i]
				bts[e] = bor(bts[e],8)
			end
		end
	end
end)

LookingForGroup_Options.RegisterSimpleFilterExpensive("spam",function(info,profile,func)
	return func(info.leaderName) and 1
end,function()
	local lfg_profile = LookingForGroup.db.profile
	if (lfg_profile.mode_rf ~= nil) or
		(not lfg_profile.flags_disable and lfg_profile.flags) then
		return LookingForGroup.realm_filter
	end
end)

LookingForGroup_Options.RegisterSimpleFilter("find",function(info,_,playstyle)
	if info.playstyle ~= playstyle then
		return 1
	end
end,function(profile)
	return profile.a.playstyle
end)

LookingForGroup_Options.RegisterSimpleFilter("find",function(info,_,warmode)
	local wm = info.isWarMode
	local cwm = 0
	if wm then
		cwm = 1
	end
	if cwm ~= warmode then
		return 1
	end
end,function(profile)
	local wm = profile.a.warmode
	if wm ~= nil then
		if wm then
			return 1
		else
			return 0
		end
	end
end)

LookingForGroup_Options.RegisterSimpleFilter("find",function(info,_,crossfactionlisting)
	local wm = info.crossFactionListing
	local cwm = 0
	if wm then
		cwm = 1
	end
	if cwm ~= crossfactionlisting then
		return 1
	end
end,function(profile)
	local wm = profile.a.crossfactionlisting
	if wm ~= nil then
		if wm then
			return 1
		else
			return 0
		end
	end
end)
