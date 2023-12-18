local LFG = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup")
local LFG_OPT = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup_Options")

local disable_text = "|cffff0000"..string.gsub(MYTHIC_PLUS_TAB_DISABLE_TEXT, "\n"," ").."|r"

function LFG_OPT.do_with_completion_info(t,info,timeLimit)
	if info == nil then
		return
	end
	t[#t+1] = "\n"
	local completionDate = info.completionDate
	if completionDate.year < 100 then
		t[#t+1] = "20"
	end
	if completionDate.year < 10 then
		t[#t+1] = "0"
	end
	t[#t+1] = completionDate.year
	t[#t+1] = "-"
	local month = completionDate.month + 1
	if month < 10 then
		t[#t+1] = "0"
	end
	t[#t+1] = month
	t[#t+1] = "-"
	local day = completionDate.day + 1
	if day < 10 then
		t[#t+1] = "0"
	end
	t[#t+1] = day
	t[#t+1] = "T"
	if completionDate.hour < 10 then
		t[#t+1] = "0"
	end
	t[#t+1] = completionDate.hour
	t[#t+1] = ":"
	if completionDate.minute < 10 then
		t[#t+1] = "0"
	end
	t[#t+1] = completionDate.minute
	t[#t+1] = ":00Z\n"
	local affixIDs = info.affixIDs
	local durationSec = info.durationSec
	t[#t+1] = info.level
	if timeLimit < durationSec then
		t[#t+1] = "(|T137008:0|t)"
	elseif timeLimit * 0.8 < durationSec then
		t[#t+1] = "(+)"
	elseif timeLimit * 0.6 < durationSec then
		t[#t+1] = "(+2)"
	else
		t[#t+1] = "(+3)"
	end

	t[#t+1] = " "
	if timeLimit < durationSec then
		t[#t+1] = DUNGEON_SCORE_OVERTIME_TIME:format(SecondsToClock(durationSec))
	else
		t[#t+1] = SecondsToClock(durationSec)
	end
	t[#t+1] = " "
	for i=1,#affixIDs do
		local name,des,filedataid = C_ChallengeMode.GetAffixInfo(affixIDs[i])
		t[#t+1] = " |T"
		t[#t+1] = filedataid
		t[#t+1] = ":0:0:0:0:10:10:1:9:1:9|t|cff8080cc"
		t[#t+1] = name
		t[#t+1] = "|r"
	end
	local members = info.members
	local classcolors = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS
	local GetClassInfo = GetClassInfo
	local GetSpecializGetSpecializationInfoForSpecIDationInfo = GetSpecializationInfoForSpecID
	t[#t+1] = "\n"
	for i=1,#members do
		local m = members[i]
		local memname = m.name
		local classid = m.classID
		local specid = m.specID
		local classname,classFile = GetClassInfo(classid)
		if i~= 1 then
			t[#t+1] = " "
		end
		local id,specname,description,icon,role = GetSpecializationInfoForSpecID(specid)
		t[#t+1] = "|T"
		t[#t+1] = icon
		t[#t+1] = ":0:0:0:0:10:10:1:9:1:9|t"
		t[#t+1] = classcolors[classFile]:GenerateHexColorMarkup()
		t[#t+1] = memname
		t[#t+1] = "|r"
	end
end

LFG_OPT:push("m+",{
	name = LFG_OPT.mythic_keystone_label_name,
	type = "group",
	args =
	{
		create =
		{
			name = function()
				if C_LFGList.HasActiveEntryInfo() then
					return UNLIST_MY_GROUP
				else
					return LIST_GROUP
				end
			end,
			type = "execute",
			order = 2,
			func = function()
				if C_LFGList.HasActiveEntryInfo() then
					C_LFGList.RemoveListing()
					return
				end
				local activityID,groupID,key_level_number =  C_LFGList.GetOwnedKeystoneActivityAndGroupAndLevel()
				if not activityID then
					LFG_OPT.expected(disable_text)
					return
				end
				local mapid_fix = C_MythicPlus.GetOwnedKeystoneChallengeMapID()
				if mapid_fix == 392 then
					activityID = 1017
					groupID = 281
				elseif mapid_fix == 391 then
					activityID = 1016
					groupID = 280
				end
				local hw = LFGListFrame.EntryCreation.Name:GetText() == "+"..key_level_number
				if not hw then
					C_LFGList.SetEntryTitle(activityID,groupID)
				end
				if activityID == 1250 then
					activityID = 1247
					groupID = 316
				end
				local function callback()
					local activity_infotb = C_LFGList.GetActivityInfoTable(activityID)
					local profile = LFG_OPT.db.profile
					local a = profile.a
					local category = a.category
					wipe(a)
					a.category = activity_infotb.categoryID
					a.group = activity_infotb.groupFinderActivityGroupID
					a.activity = activityID
					if category ~= a.category then
						LFG_OPT.OnProfileChanged()
					end
					local s = profile.s
					local auto_accept = s.auto_accept
					wipe(s)
					s.auto_accept = auto_accept
					local mplus_callbacks = LFG_OPT.mplus_callbacks
					for i=1,#mplus_callbacks do
						mplus_callbacks[i](profile,a,s,key_level_number)
					end
					s.notcrossfaction = nil
					s.minimum_dungeon_score = C_ChallengeMode.GetOverallDungeonScore()
					LFG_OPT.listing(a.activity,3,s,nil,{"m+"})
				end
				if LFG.db.profile.hardware and not hw then
					LFG.show_popup(LFGListFrame.EntryCreation.Name:GetText(),{nop,LIST_GROUP,callback})
				else
					callback()
				end
			end
		},
		reset =
		{
			name = RESET,
			type = "execute",
			order = 3,
			func = C_LFGList.ClearCreationTextFields
		},
		auto_accept =
		{
			order = 4,
			name = LFG_LIST_AUTO_ACCEPT,
			type = "toggle",
			get = LFG_OPT.options_get_s_function,
			set = LFG_OPT.options_set_s_function
		},
		mplusdetails =
		{
			order = 5,
			name = LFG_LIST_DETAILS,
			type = "toggle",
			get = LFG_OPT.options_get_function,
			set = LFG_OPT.options_set_function
		},
		desc = 
		{
			order = 6,
			name = function()
				C_MythicPlus.RequestCurrentAffixes()
				C_MythicPlus.RequestMapInfo()
				C_MythicPlus.RequestRewards()
				local t = {}
				local C_MythicPlus = C_MythicPlus
				if C_MythicPlus.IsWeeklyRewardAvailable() then
					t[#t+1] = "|cff00ff00"
					t[#t+1] = CLAIM_REWARD
					t[#t+1] = "|r\n"
				end
				local best_kl = 10
				local best_rw = C_MythicPlus.GetRewardLevelForDifficultyLevel(best_kl)
				while best_kl < 31 do
					local gg = C_MythicPlus.GetRewardLevelForDifficultyLevel(best_kl+5)
					if gg == best_rw then
						break
					end
					best_rw = gg
					best_kl = best_kl + 5
				end
				local owned_keystone_level = C_MythicPlus.GetOwnedKeystoneLevel()
				local rewarded_owned 
				if owned_keystone_level then
					rewarded_owned = C_MythicPlus.GetRewardLevelForDifficultyLevel(owned_keystone_level)
					t[#t+1] = format(MYTHIC_PLUS_MISSING_WEEKLY_CHEST_REWARD,owned_keystone_level,
										rewarded_owned)
				end
				if rewarded_owned ~= best_rw then
					if owned_keystone_level then
						t[#t+1] = "\n"
					end
					t[#t+1] = "|cffff0000"
					t[#t+1] = format(MYTHIC_PLUS_MISSING_WEEKLY_CHEST_REWARD,best_kl,best_rw)
					t[#t+1] = "|r"
				end
				local score = C_ChallengeMode.GetOverallDungeonScore()
				local color_table = C_ChallengeMode.GetDungeonScoreRarityColor(score)
				t[#t+1] = "\n\n"
				t[#t+1] = DUNGEON_SCORE
				t[#t+1] = "  "
				if color_table then
					t[#t+1] = color_table:GenerateHexColorMarkup()
					t[#t+1] = score
					t[#t+1] = "|r"
				else
					t[#t+1] = score
				end
				
				local maptable = C_ChallengeMode.GetMapTable()
				t[#t+1] = "\n"
				t[#t+1] = #maptable
				local pos = #t
				t[#t+1] = "/"
				t[#t+1] = #maptable
				t[#t+1] = ""
				local C_ChallengeMode_GetMapUIInfo = C_ChallengeMode.GetMapUIInfo
				local C_MythicPlus_GetSeasonBestAffixScoreInfoForMap = C_MythicPlus.GetSeasonBestAffixScoreInfoForMap
				local GetSpecificDungeonOverallScoreRarityColor =  C_ChallengeMode.GetSpecificDungeonOverallScoreRarityColor
				local mplusdetails = LFG_OPT.db.profile.mplusdetails
				local finished = 0
				local challengemapid = C_MythicPlus.GetOwnedKeystoneChallengeMapID()
				for i=1,#maptable do
					local mi = maptable[i]
					local name,id,timeLimit,texture,backgroundtexture = C_ChallengeMode_GetMapUIInfo(mi)
					t[#t+1] = "\n\n"
					if challengemapid == mi then
						t[#t+1] = "|T4352494:0:0:0:0:10:10:1:9:1:9|t"
					end
					local affixesscores,bestOverAllScore = C_MythicPlus_GetSeasonBestAffixScoreInfoForMap(mi)
					if bestOverAllScore then
						finished = finished + 1
						local bestOverAllScore_color = GetSpecificDungeonOverallScoreRarityColor(bestOverAllScore)
						t[#t+1] = bestOverAllScore_color:GenerateHexColorMarkup()
						t[#t+1] = bestOverAllScore
						t[#t+1] = "|r"
					end
					t[#t+1] = "|T"
					t[#t+1] = texture
					t[#t+1] = ":0:0:0:0:10:10:1:9:1:9|t|cff8080cc"
					t[#t+1] = name
					t[#t+1] = "|r"
					if mplusdetails then
						t[#t+1] = " ("
						t[#t+1] = ID
						t[#t+1] = ":"
						t[#t+1] = id
						t[#t+1] = ")"
					end
					t[#t+1] = " "
					t[#t+1] = SecondsToClock(timeLimit)
					if affixesscores then
						for i=1,#affixesscores do
							t[#t+1] = "\n"
							local ai = affixesscores[i]
							local aiscore = ai.score
							local aicolor = GetSpecificDungeonOverallScoreRarityColor(aiscore*2)
							local markup = aicolor:GenerateHexColorMarkup()
							t[#t+1] = "|cff8080cc"
							t[#t+1] = ai.name
							t[#t+1] = "|r "
							t[#t+1] = markup
							t[#t+1] = "["
							t[#t+1] = ai.score
							t[#t+1] = "/"
							t[#t+1] = ai.level
							local durationSec = ai.durationSec
							if timeLimit < durationSec then
								t[#t+1] = "(|T137008:0|t)"
							elseif timeLimit * 0.8 < durationSec then
								t[#t+1] = "(+)"
							elseif timeLimit * 0.6 < durationSec then
								t[#t+1] = "(+2)"
							else
								t[#t+1] = "(+3)"
							end
							t[#t+1] = "]|r "
							if timeLimit < durationSec then
								t[#t+1] = DUNGEON_SCORE_OVERTIME_TIME:format(SecondsToClock(durationSec))
							else
								t[#t+1] = SecondsToClock(durationSec)
							end
						end
					end
					if mplusdetails then
						local inTimeInfo, overtimeInfo = C_MythicPlus.GetSeasonBestForMap(mi)
						LFG_OPT.do_with_completion_info(t,inTimeInfo,timeLimit)
						if overtimeInfo then
							LFG_OPT.do_with_completion_info(t,overtimeInfo,timeLimit)
						end
					end
				end
				t[pos] = finished
				local affixes = C_MythicPlus.GetCurrentAffixes()
				if affixes then
					t[#t+1] = "\n\n\n"
					t[#t+1] = CHALLENGE_MODE_THIS_WEEK
					t[#t+1] = "|cff8080cc("
					t[#t+1] = #affixes
					t[#t+1] = ")|r"
					for i=1,#affixes do
						local name,description,filedataid = C_ChallengeMode.GetAffixInfo(affixes[i].id)
						t[#t+1] = "\n\n|T"
						t[#t+1] = filedataid
						t[#t+1] = ":0:0:0:0:10:10:1:9:1:9|t|cff8080cc"
						t[#t+1] = name
						t[#t+1] = "|r\n"
						t[#t+1] = description
					end
				end
				local currentWeekBestLevel,weeklyRewardLevel,nextDifficultyWeeklyRewardLevel,nextBestLevel=C_MythicPlus.GetWeeklyChestRewardLevel()
				if currentWeekBestLevel~=0 then
					t[#t+1] = "\n\n|cff8080cc"
					t[#t+1] = currentWeekBestLevel
					t[#t+1] = "|r |cff00ff00"
					t[#t+1] = format(string.gsub(MYTHIC_PLUS_CHEST_ITEM_LEVEL_REWARD, "\n",""),weeklyRewardLevel)
					t[#t+1] = "|r"
				end
				t[#t+1] = "\n\n"
				t[#t+1] = HONORABLE_KILLS
				t[#t+1] = ": |cff8080cc"
				t[#t+1] = GetPVPLifetimeStats()
				t[#t+1] = "|r\n"
				t[#t+1] = LFG_LIST_HONOR_LEVEL_INSTR_SHORT
				local currentHonor = UnitHonor("player")
				local maxHonor = UnitHonorMax("player")
				local honorlevel =UnitHonorLevel("player")
				t[#t+1] = ": |cff8080cc"
				t[#t+1] = honorlevel
				t[#t+1] = "|r |cffff00ff("
				t[#t+1] = format(PVP_PRESTIGE_RANK_UP_NEXT_MAX_LEVEL_REWARD,C_PvP.GetNextHonorLevelForReward(honorlevel))
				t[#t+1] = ")|r\n"
				t[#t+1] = HONOR
				t[#t+1] = ": |cff8080cc"
				t[#t+1] = currentHonor
				t[#t+1] = "/"
				t[#t+1] = maxHonor
				t[#t+1] = format("|r |cffff00ff(%.2f%%)|r\n",currentHonor/maxHonor*100)
				local rewardAchieved, lastWeekRewardAchieved, lastWeekRewardClaimed, pvpTierMaxFromWins = C_PvP.GetWeeklyChestInfo()
				if lastWeekRewardAchieved and not lastWeekRewardClaimed then
					t[#t+1] = "\n|cff00ff00"
					t[#t+1] = RATED_PVP_WEEKLY_CHEST_TOOLTIP_COLLECT
					t[#t+1] = "|r"
					if pvpTierMaxFromWins ~= -1 then
						local activityItemLevel, weeklyItemLevel = C_PvP.GetRewardItemLevelsByTierEnum(pvpTierMaxFromWins)
						t[#t+1] = "\n"
						t[#t+1] = weeklyItemLevel
					end
				end
				if rewardAchieved then
					t[#t+1] = "\n|cff00ff00"
					t[#t+1] = RATED_PVP_WEEKLY_CHEST_EARNED
					t[#t+1] = "|r"
				end
				return table.concat(t)
			end,
			fontSize = "large",
			type = "description"
		},
	}
})

LFG_OPT.Register("mplus_callbacks",nil,function(profile,a,s)
	local avgItemLevel, avgItemLevelEquipped, avgItemLevelPvp = GetAverageItemLevel()
--	s.minimum_item_level = avgItemLevelEquipped-10
	s.role = true
	s.diverse = true
	local level = C_MythicPlus.GetOwnedKeystoneLevel()
	if level then
		if 2 < level then
			level = level - 1
		end
	end
	s.mplus_elitist_level = level
end)

local function is_finish_unsuccessful(mplus_elitist_level,bestRunLevel,finishedSuccess)
	if finishedSuccess then
		return bestRunLevel < mplus_elitist_level
	else
		return bestRunLevel < mplus_elitist_level + 2
	end
end

local function is_mplus_elitist_applicant_impl(applicantID,i,mplus_elitist_level,activityID)
	local info = C_LFGList.GetApplicantDungeonScoreForListing(applicantID,i,activityID)
	if info == nil then
		return false
	end
	if is_finish_unsuccessful(mplus_elitist_level,info.bestRunLevel,info.finishedSuccess) then
		return false
	end
	return true
end

LFG_OPT.RegisterSimpleApplicantFilter("s",function(applicantID,i,profile,mplus_elitist_level,entryinfo)
	local activityid = entryinfo.activityID
	if activityid == 1016 or activityid == 1017 then
		-- work around tazavesh bug
		if not is_mplus_elitist_applicant_impl(applicantID,i,mplus_elitist_level,1016) or
			not is_mplus_elitist_applicant_impl(applicantID,i,mplus_elitist_level,1017) then
			return 1
		end
	else
		if not is_mplus_elitist_applicant_impl(applicantID,i,mplus_elitist_level,activityid) then
			return 1
		end
	end
end,function(profile)
	local level = profile.s.mplus_elitist_level
	if level then
		return profile.s.mplus_elitist_level
	end
end)

LFG_OPT.RegisterSimpleFilterExpensive("find",function(info,_,dungeonscoremin)
	if info.leaderOverallDungeonScore <= dungeonscoremin then
		return 1
	end
end,function(profile)
	local a = profile.a
	if a.category == 2 then
		return a.dungeonscoremin
	end
end)

LFG_OPT.RegisterSimpleFilterExpensive("find",function(info,_,dungeonscoremax)
	if dungeonscoremax < info.leaderOverallDungeonScore then
		return 1
	end
end,function(profile)
	local a = profile.a
	if a.category == 2 then
		return a.dungeonscoremax
	end
end)

LFG_OPT.RegisterSimpleFilterExpensive("find",function(info,_,dungeonlevelmin)
	local groupdungeonlevel = 0
	local scoreinfo = info.leaderDungeonScoreInfo
	if scoreinfo then
		groupdungeonlevel = scoreinfo.bestRunLevel
	end
	if groupdungeonlevel <= dungeonlevelmin then
		return 1
	end
end,function(profile)
	local a = profile.a
	if a.category == 2 then
		return a.dungeonlevelmin
	end
end)

LFG_OPT.RegisterSimpleFilterExpensive("find",function(info,_,dungeonlevelmax)
	local groupdungeonlevel = 0
	local scoreinfo = info.leaderDungeonScoreInfo
	if scoreinfo then
		groupdungeonlevel = scoreinfo.bestRunLevel
	end
	if dungeonlevelmax < groupdungeonlevel then
		return 1
	end
end,function(profile)
	local a = profile.a
	if a.category == 2 then
		return a.dungeonlevelmax
	end
end)
