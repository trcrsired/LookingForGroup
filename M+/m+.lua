local LFG_OPT = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup_Options")

local activity_infotb = C_LFGList.GetActivityInfoTable(459)

LFG_OPT.mythic_keystone = activity_infotb.fullName:sub(C_LFGList.GetActivityGroupInfo(112):len()+1)
local label_name = activity_infotb.shortName
LFG_OPT.mythic_keystone_label_name = label_name

LFG_OPT.RegisterSimpleFilter("find",function(info,profile,val)
	local info_tb = C_LFGList.GetActivityInfoTable(info.activityID)
	local shortname = info_tb.shortName
	if val == 1 then
		if shortname ~= label_name then
			return 1
		end
	else
		if shortname == label_name then
			return 1
		end
	end
end,function(profile)
	local a = profile.a
	if a.category == 2 then
		local mplus = profile.mplus
		if mplus then
			return 1
		elseif mplus == false then
			return 0
		end
	end
end)

LFG_OPT.Register("category_callbacks",nil,{function(find_args,f_args,s_args)
	f_args.mplus =
	{
		name = label_name,
		type = "toggle",
		get = function(info)
			local v = LFG_OPT.db.profile.mplus
			if v then
				return true
			elseif v == false then
				return
			else
				return false
			end
		end,
		set = function(info,val)
			if val then
				val = true
			elseif val == nil then
				val = false
			else
				val = nil
			end
			LFG_OPT.db.profile.mplus = val
		end,
		tristate = true,
	}
	f_args.dungeonscoremin =
	{
		name = format("%s(%s)",DUNGEON_SCORE,MINIMUM),
		type = "input",
		order = 1,
		get = function(info)
			local val = LFG_OPT.db.profile.a[info[#info]]
			if val then
				return tostring(val)
			end
		end,
		set = function(info,val)
			if val == "" then
				LFG_OPT.db.profile.a[info[#info]] = nil
			else
				LFG_OPT.db.profile.a[info[#info]] = tonumber(val)
			end
		end,
		pattern = "^[0-9]*$"
	}
	f_args.dungeonscoremax =
	{
		name = format("%s(%s)",DUNGEON_SCORE,MAXIMUM),
		type = "input",
		order = 2,
		get = f_args.dungeonscoremin.get,
		set = f_args.dungeonscoremin.set,
		pattern = "^[0-9]*$"
	}
	f_args.dungeonlevelmin =
	{
		name = format("%s(%s)",MYTHIC_PLUS_OVERTIME_SEASON_BEST,MINIMUM),
		type = "input",
		order = 3,
		get = f_args.dungeonscoremin.get,
		set = f_args.dungeonscoremin.set,
		pattern = "^[0-9]*$"
	}
	f_args.dungeonlevelmax =
	{
		name = format("%s(%s)",MYTHIC_PLUS_OVERTIME_SEASON_BEST,MAXIMUM),
		type = "input",
		order = 4,
		get = f_args.dungeonscoremin.get,
		set = f_args.dungeonscoremin.set,
		pattern = "^[0-9]*$"
	}
	s_args.mplus_min_score=
	{
		name = "M+ "..MINIMUM,
		type = "input",
		order = 1,
		get = function(info)
			local val = LFG_OPT.db.profile.s[info[#info]]
			if val then
				return tostring(val)
			end
		end,
		set = function(info,val)
			if val == "" then
				LFG_OPT.db.profile.s[info[#info]] = nil
			else
				LFG_OPT.db.profile.s[info[#info]] = tonumber(val)
			end
		end,
		pattern = "^[0-9]*$"
	}
	s_args.mplus_max_score=
	{
		name = "M+ "..MAXIMUM,
		type = "input",
		order = 2,
		get = s_args.mplus_min_score.get,
		set = s_args.mplus_min_score.set,
		pattern = "^[0-9]*$"
	}
	s_args.mplus_elitist_level =
	{
		name = "Elitist M+",
		type = "input",
		get = s_args.mplus_min_score.get,
		set = s_args.mplus_max_score.set,
		pattern = "^[0-9]*$"
	}
end,function(find_args,f_args,s_args)
	f_args.mplus_min_score = nil
	f_args.mplus_max_score = nil
	s_args.mplus_min_score = nil
	s_args.mplus_max_score= nil
	s_args.mplus_elitist_level = nil
	f_args.mplus=nil
end,2})

function LFG_OPT.get_mplus_lfg_activities()
	local cache = LFG_OPT.mplus_lfg_activities_cache
	if cache then
		return cache
	else
		local res = {}
		local activities = C_LFGList.GetAvailableActivities(2,nil,Enum.LFGListFilter.Recommended)
		local GetActivityInfoTable = C_LFGList.GetActivityInfoTable
		for i=1,#activities do
			local id = activities[i]
			local tb = GetActivityInfoTable(id)
			if tb and tb.shortName == label_name then
				res[#res+1] = id
			end
		end
		if #res ~= 0 then
			LFG_OPT.mplus_lfg_activities_cache = res
		end
		return res
	end
end
