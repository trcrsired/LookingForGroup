local LFG_OPT = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup_Options")
--local L = LibStub("AceLocale-3.0"):GetLocale("LookingForGroup")
local instance_tb = {}

function LFG_OPT.generate_encounters_table(groupid, instancetb)
	if groupid and groupid ~= 0 then
		local igp = instancetb[groupid]
		if igp then
			return igp
		else
			local name = C_LFGList.GetActivityGroupInfo(groupid)
			local num = GetNumSavedInstances()
			local string_find = string.find
			local GetSavedInstanceInfo = GetSavedInstanceInfo
			for i=1,num do
				local instanceName, instanceID, _, instanceDifficulty, locked, _, instanceIDMostSig, isRaid, maxPlayers, difficultyName, maxBosses = GetSavedInstanceInfo(i)
				if (string_find(name,instanceName) or string_find(instanceName,name)) then
					local encounters_tb = {}
					for j = 1, maxBosses do
						encounters_tb[j] = GetSavedInstanceEncounterInfo(i,j)
					end
					instancetb[groupid] = encounters_tb
					return encounters_tb
				end
			end
		end
	end
end

LFG_OPT.RegisterSimpleFilter("find",function(info,profile,mbnm)
	local rse = C_LFGList.GetSearchResultEncounterInfo(info.searchResultID)
	local encounters = profile.a.encounters
	local mct = 0
	if rse then
		for i=1,#rse do
			local ectb = encounters[rse[i]]
			local gt
			if ectb then
				gt = ectb[2]
			end
			if gt then
				mct = mct + 1
			elseif gt == false then
				return 1
			end
		end
	end
	if mct < mbnm then
		return 1
	end
end,function(profile)
	local encounters = profile.a.encounters
	if encounters then
		local mbnm = 0
		for _,v in pairs(encounters) do
			if v[2] then
				mbnm = mbnm + 1
			end
		end
		return mbnm
	end
end)

LFG_OPT.RegisterSimpleFilter("find",
function(info)
	return C_LFGList.GetSearchResultEncounterInfo(info.searchResultID) and 1 or 0
end,
function(profile)
	return profile.a.encountersnew
end)

local function get_activity_id_func()
	return LFG_OPT.db.profile.a.activity
end

local function get_profile_a()
	return LFG_OPT.db.profile.a
end

local function get_profile_s()
	return LFG_OPT.db.profile.s
end

function LFG_OPT.generate_encounters_options(metadata)
	local encounters_tb = metadata.encounters_tb
	if encounters_tb == nil then
		encounters_tb = {}
		metadata.encounters_tb = encounters_tb
	end
	local get_profile = metadata.get_profile
	if get_profile == nil then
		if metadata.get_profile_opt == 1 then
			get_profile = get_profile_s
		else
			get_profile = get_profile_a
		end
		metadata.get_profile = get_profile
	end
	local encounters_name = metadata.encounters
	local killed_func = metadata.killed_func
	local get_activityID = metadata.get_activityID
	if get_activityID == nil then
		get_activityID = get_activity_id_func
		metadata.get_activityID = get_activity_id_func
	end
	local generate_encounters_table = metadata.generate_encounters_table
	if generate_encounters_table == nil then
		generate_encounters_table = LFG_OPT.generate_encounters_table
	end
	local generate_encounters_table_on_null = metadata.generate_encounters_table_on_null
	local new = metadata.new
	local all = metadata.all
	local tb =
	{
		name = metadata.name,
		desc = metadata.desc,
		type = "group",
		args =
		{
			encounters =
			{
				order = 0,
				name = RAID_ENCOUNTERS,
				type = "multiselect",
				width = "full",
				values = function()
					local profile = get_profile(metadata)
					if not encounters_tb or not profile[encounters_name] then
						encounters_tb = generate_encounters_table(profile.group, instance_tb, metadata)
						if encounters_tb == nil and generate_encounters_table_on_null then
							encounters_tb = generate_encounters_table_on_null(profile.group, instance_tb, metadata)
						end
					end
					return encounters_tb
				end,
				tristate = true,
				get = function(info,val)
					local profile = get_profile(metadata)
					local encounters = profile[encounters_name]
					if encounters == nil then
						return false
					end
					local etb = encounters[encounters_tb[val]]
					if etb == nil then
						return false
					end
					local v = etb[2]
					if v then
						return true
					elseif v == false then
						return nil
					end
					return false
				end,
				set = function(info,key,val)
					local v = false
					if val then
						v = true
					elseif val == false then
						v = nil
					end
					local profile = get_profile(metadata)
					if new then
						profile[new] = nil
					end
					local profileencountersname = profile[encounters_name]
					if profileencountersname == nil then
						profileencountersname = {}
						profile[encounters_name] = profileencountersname
					end
					local pcetb = profileencountersname[encounters_tb[key]]
					if pcetb == nil then
						pcetb = {}
						profileencountersname[encounters_tb[key]] = pcetb
					end
					pcetb[1] = key
					pcetb[2] = v
				end
			},
			clearall =
			{
				order = 2,
				name = REMOVE_WORLD_MARKERS,
				type = "execute",
				func = function()
					local profile = get_profile(metadata)
					profile[encounters_name] = nil
				end,
			},
			raidinfo =
			{
				order = 4,
				name = RAID_INFO,
				type = "execute",
				func = function()
					local profile = get_profile(metadata)
					repeat
					if encounters_tb == nil then
						break
					end
					local temp_encounters = profile[encounters_name]
					profile[encounters_name] = nil
					local activity = get_activityID(metadata,profile)
					if activity == nil then
						break
					end
					local activity_infotb = C_LFGList.GetActivityInfoTable(activity)
					local fullname,shortname = activity_infotb.fullName,activity_infotb.shortName
					local groupnm = C_LFGList.GetActivityGroupInfo(activity_infotb.groupFinderActivityGroupID)
					local num = GetNumSavedInstances()
					local GetSavedInstanceInfo = GetSavedInstanceInfo
					local string_find = string.find
					for i=1,num do
						local instanceName, instanceID, _, instanceDifficulty, locked, _, instanceIDMostSig, isRaid, maxPlayers, difficultyName, maxBosses = GetSavedInstanceInfo(i)
						if groupnm == instanceName and difficultyName == shortname then
							local t = {}
							for j = 1, maxBosses do
								t[encounters_tb[j]] = {j,killed_func(metadata,i,j,activity,activity_infotb,locked)}
							end
							if temp_encounters then
								local same = true
								for k,v in pairs(t) do
									if temp_encounters[k] ~= v then
										same = nil
										break
									end
								end
								if same then
									for k,v in pairs(temp_encounters) do
										if not v then
											if v == false then
												t[k] = nil
											else
												t[k] = false
											end
										end
									end
								end
							end
							profile[encounters_name] = t
							if new then
								profile[new] = nil
							end
							return
						end
					end
					until true
					if new then
						profile[new] = not profile[new]
					end
				end,
			}
		}
	}
	if all then
		tb.args[all] =
		{
			name = ALL,
			type = "toggle",
			get = function()
				local profile = get_profile(metadata)
				return profile[all]
			end,
			set = function(_,val)
				local profile = get_profile(metadata)
				if val then
					profile[all] = true
					if new then
						profile[new] = nil
					end
				else
					profile[all] = nil
				end
			end,
			width = "full",
			order = 5,
		}
	end
	if new then
		tb.args[new] =
		{
			name = NEW,
			type = "toggle",
			get = function()
				local profile = get_profile(metadata)
				return profile[new]
			end,
			set = function(_,val)
				local profile = get_profile(metadata)
				if val then
					profile[new] = true
					if all then
						profile[all] = nil
					end
					profile[encounters_name] = nil
				else
					profile[new] = nil
				end
			end,
			width = "full",
			order = 5,
		}
	end

	local extra = metadata.extra
	if extra then
		for k, v in pairs(extra) do
			tb[k] = v
		end
	end
	return tb
end

LFG_OPT.option_table.args.find.args.f.args.encounters =
LFG_OPT.generate_encounters_options(
{name = RAID_BOSSES,
killed_func = function(_,i,j,_,_,locked)
	local _, _, isKilled = GetSavedInstanceEncounterInfo(i,j)
	return locked and isKilled
end,
encounters = "encounters",
new = "encountersnew",
})
