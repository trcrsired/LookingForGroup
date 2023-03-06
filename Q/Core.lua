local LookingForGroup = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup")
local LookingForGroup_Q = LibStub("AceAddon-3.0"):NewAddon("LookingForGroup_Q","AceEvent-3.0")

function LookingForGroup_Q:OnInitialize()
	local db = LookingForGroup.db
	local defaults = LookingForGroup.db.defaults
	defaults.profile.q = {[42170]=true,[42233]=true,[42234]=true,[42420]=true,[42421]=true,[42422]=true,[43179]=true,[43943]=true,[45379]=true,[48338]=true,[48358]=true,[48360]=true,[48374]=true,[48592]=true,[48639]=true,[48641]=true,[48642]=true,[50562]=true,
	[54978] = true, -- Against Overwhelming Odds
	[51017] = true, -- Supplies Needed: Monelite Ore
	[54618] = true, -- Paragon of the 7th Legion
	[48973] = true, -- Paragon of Argussian Reach
	[48974] = true, -- Paragon of the Army of the Light
	[54453] = true, -- Paragon Order of Embers
	[54456] = true, -- Paragon Order of Embers
-- bfa assaults
	[51982] = true, -- Storm's Rage
	[53701] = true, -- A Drust Cause
	[53711] = true, -- A Sound Defense
	[53883] = true, -- Shores of Zuldazar
	[53885] = true, -- Isolated Victory
	[53939] = true, -- Breaching Boralus
	[54132] = true, -- Horde of Heroes
	[53414] = true,
	[53416] = true, -- Warfront: The Battle for Stromgarde
	[53992] = true, 
	[53995] = true, -- Warfront: The Battle for Darkshore
	[56119] = true, -- The Waveblade Ankoan
	[56120] = true, -- The Unshackled
	[56206] = true, -- Heroic: The Battle for Stromgarde
	[56136] = true, -- Heroic Warfront: The Battle for Stromgarde
	[56137] = true, -- Heroic Warfront: The Battle for Stromgarde
	[56128] = true, -- Drowning the Horde
	[56129] = true, -- Heroic: The Battle for Stromgarde
	[56433] = true, -- Drowning the Alliance
	[56003] = true, -- Runelocked Chest
	[63850] = true, -- Tracking - Small Consoles
	[65089] = true, -- Frog'it
	}
	db:RegisterDefaults(defaults)
end

function LookingForGroup_Q:OnEnable()
	LookingForGroup_Q:RegisterEvent("QUEST_ACCEPTED")
	LookingForGroup_Q:RegisterEvent("QUEST_WATCH_UPDATE","QUEST_ACCEPTED")
	LookingForGroup_Q:RegisterMessage("LFG_SECURE_QUEST_ACCEPTED")
end

local function get_quest_tag_info(questID)
	local GetQuestTagInfo = GetQuestTagInfo
	if GetQuestTagInfo then
		local tagID, tagName, worldQuestType, rarity, isElite, tradeskillLineIndex, displayTimeLeft = GetQuestTagInfo(questID)
		if tagID == nil then
			return nil
		end
		return
		{
			tagName = tagName,
			tagID = tagID,
			worldQuestType = worldQuestType,
			quality = rarity,
			tradeskillLineID = tradeskillLineIndex,
			isElite = isElite,
			displayExpiration = displayTimeLeft
		}
	else
		return C_QuestLog.GetQuestTagInfo(questID)
	end
end

local function cofunc(quest_id,secure,gp)
	local questName = C_TaskQuest.GetQuestInfoByQuestID(quest_id)
	if questName == nil then
		if secure <= 0 and LookingForGroup.db.profile.auto_no_info_quest then
			return
		end

		local GetInfo = C_QuestLog.GetInfo
		if GetInfo then
			for i=1,C_QuestLog.GetNumQuestLogEntries() do
				local tb=GetInfo(i)
				if GetInfo(i).questID == quest_id then
					if secure <= 0 and tb.frequency == 3 then
						return
					end
					questName = tb.title
					break
				end
			end
		else
			for i=1,GetNumQuestLogEntries() do
				local title, level, suggestedGroup, isHeader, isCollapsed, isComplete, frequency, questID, startEvent, displayQuestID, isOnMap, hasLocalPOI, isTask, isBounty, isStory, isHidden, isScaling = GetQuestLogTitle(i)
				if questID == quest_id then
					if secure <= 0 and frequency == 3 then
						return
					end
					questName = title
					break
				end
			end
		end
	end
	if questName == nil then
		questName = ("QuestID:%d"):format(quest_id)
	end
	local function func(info,id)
		if quest_id == id and LookingForGroup.popup and LookingForGroup.popup:IsShown() then
			LookingForGroup.popup:Hide()
		end
	end
	if not gp and IsInGroup() then
		if 0 < secure and UnitIsGroupLeader("player", 1) then
			gp = true
		else
			return
		end
	end
	local acceptedtb =
	{name = questName,
	secure=secure,
	in_range = function()
		if C_TaskQuest.GetDistanceSqToQuest then
			local distance = C_TaskQuest.GetDistanceSqToQuest(quest_id)
			return not distance or distance < 40000
		else
			return true
		end
	end,
	ty_pe = "<LFG>Q",
	create_only = gp
	}
	if LookingForGroup.IsLookingForGroupEnabled() then
		local activityID = C_LFGList.GetActivityIDForQuestID(quest_id)
		if activityID  == nil then
			local activities = C_LFGList.GetAvailableActivities()
			local C_LFGList_GetActivityInfoExpensive = C_LFGList.GetActivityInfoExpensive
			for i=1,#activities do
				if C_LFGList_GetActivityInfoExpensive(activities[i]) then
					activityID = activities[i]
					break
				end
			end
			if activityID == nil then
				activityID = 280 --use wandering isle activity since no one will use it unless you are a level capped neutral pandaren like me
			end
		end
		local activity_infotb = C_LFGList.GetActivityInfoTable(activityID)
		local categoryID, iLevel, filters = activity_infotb.categoryID,activity_infotb.ilvlSuggestion,activity_infotb.filters
		local confirm_keyword = not C_LFGList.CanCreateQuestGroup(quest_id) and tostring(quest_id) or nil
		acceptedtb.create= function()
			local ilvl = 0
			if confirm_keyword then
				if math.floor(ilvl) == ilvl then
					ilvl = ilvl + 0.125
				end
				C_LFGList.CreateListing(activityID,ilvl,0,true,false)
			else
				C_LFGList.ClearCreationTextFields()
				C_LFGList.CreateListing(activityID,ilvl,0,true,false,quest_id)
			end
		end
		acceptedtb.search = function()
			if not confirm_keyword then
				C_LFGList.SetSearchToQuestID(quest_id)
			end
			return LookingForGroup.Search(categoryID,filters,0)
		end
		acceptedtb.keyword = confirm_keyword
	else
		acceptedtb.keyword = tostring(quest_id)
		acceptedtb.create = nop
		acceptedtb.search = nop
	end
	local quest_tag_tb = get_quest_tag_info(quest_id)
	acceptedtb.raid = quest_tag_tb and quest_tag_tb.quality == 2
	LookingForGroup_Q:RegisterEvent("QUEST_REMOVED",func)
	if LookingForGroup.accepted(acceptedtb) then
		return
	end
	local current = coroutine.running()
	local function accepted_function(event,id)
		if IsInGroup() then
			if quest_id == id then
				LookingForGroup.resume(current,3)
			end
		else
			if not LookingForGroup.IsLookingForGroupEnabled() then
				if LookingForGroup.auto_is_running then
					if quest_id == id then
						LookingForGroup.resume(current,3)
					end
					return
				end
			end
			LookingForGroup.resume(current)
			LookingForGroup_Q:RegisterEvent("QUEST_ACCEPTED")
			LookingForGroup_Q:RegisterEvent("QUEST_WATCH_UPDATE","QUEST_ACCEPTED")
		end
	end
	LookingForGroup_Q:RegisterEvent("QUEST_ACCEPTED",accepted_function)
	LookingForGroup_Q:RegisterEvent("QUEST_WATCH_UPDATE",accepted_function)
	LookingForGroup_Q:RegisterEvent("QUEST_TURNED_IN",function(info,id)
		if quest_id == id then
			LookingForGroup.resume(current,0,gp)
		end
	end)
	LookingForGroup_Q:RegisterEvent("QUEST_REMOVED",function(info,id)
		if quest_id == id then
			LookingForGroup.resume(current,1,gp)
		end
	end)
	LookingForGroup.autoloop(acceptedtb)
	LookingForGroup_Q:UnregisterEvent("QUEST_TURNED_IN")
	LookingForGroup_Q:UnregisterEvent("QUEST_REMOVED")
	LookingForGroup_Q:RegisterEvent("QUEST_ACCEPTED")
	LookingForGroup_Q:RegisterEvent("QUEST_WATCH_UPDATE","QUEST_ACCEPTED")
end

local available_quest_tag_tb =
{
[1] = true,  --Group
[21] = true, --Class
[41] = true, --PVP
[104] = true, --Side Quest
[107] = true, --Artifact
[109] = true, --World Quest
[110] = true, --Epic World Quest
[111] = true, --Elite World Quest
[112] = true, --Epic Elite World Quest
[113] = true, --PvP World Quest
[135] = true, --Rare World Quest
[136] = true, --Rare Elite World Quest
[142] = true, --Legion Invasion Elite World Quest
[144] = true, --Legionfall World Quest
[146] = true, --Legion Invasion World Quest Wrapper
}

LookingForGroup.lfgq_available_quest_tag_tb = available_quest_tag_tb

local function is_group_q(id,ignore)
	if id == nil or IsRestrictedAccount() then
		return
	end
	local profile = LookingForGroup.db.profile
	if 45068 <= id and id < 45073 then	-- Barrels o' Fun
		LookingForGroup_Q:SendMessage("LFG_Barrels_o_Fun",id)
		return
	end
	if ignore then
		return true
	end
	if (46794 <= id and id <= 46802) -- legion paragon quests
		or (50598<=id and id <= 50606) -- bfa bounty quests
		or (51021<=id and id <= 51051) or (52375<=id and id <= 52388) -- bfa supplies needed
		or (54134<=id and id <= 54138) --bfa assaults
		or (54626<=id and id <= 54632) -- bfa paragon quests
		or (56006<=id and id <= 56022 and id~= 56012 and id~=56017) -- 8.2 Runelocked Chest
		or (56023<=id and id <= 56025) -- 8.2 Laylocked Chest
		or (65402<=id and id <= 65417) -- 9.2 Puzzling Quests
		then return
	end
	if profile.q[id] then
		return
	end
	local quest_tb = get_quest_tag_info(id)
	if quest_tb == nil then
		if not profile.auto_wq_only then
			if not LookingForGroup.IsLookingForGroupEnabled() then
				return true
			end
		end
		return
	end
	local tagID,wq_type = quest_tb.tagID,quest_tb.worldQuestType
	if tagID and not available_quest_tag_tb[tagID] then
		return
	end
	if profile.auto_wq_only and wq_type == nil then
		return
	end
	local C_LFGList_CanCreateQuestGroup = C_LFGList.CanCreateQuestGroup
	if profile.auto_ccqg and (not C_LFGList_CanCreateQuestGroup or not C_LFGList.CanCreateQuestGroup(id)) then
		return
	end
	local QuestTagType = Enum.QuestTagType
	if wq_type == QuestTagType.PetBattle or wq_type == QuestTagType.Profession or wq_type == QuestTagType.Dungeon or
		wq_type == QuestTagType.Islands or wq_type == QuestTagType.Raid or wq_type == QuestTagType.RatedReward then
		return
	end
	if math.floor(id/100) == 413 then
		return
	end
	local quest_faction = select(2,C_TaskQuest.GetQuestInfoByQuestID(id))
	if quest_faction == 1090 or quest_faction == 2163 then
		return
	end
	local num_wq_watches = C_QuestLog.GetNumWorldQuestWatches()
	if num_wq_watches ~= 0 then
		local i = 1
		local GetQuestIDForWorldQuestWatchIndex = C_QuestLog.GetQuestIDForWorldQuestWatchIndex
		while i<=num_wq_watches do
			if GetQuestIDForWorldQuestWatchIndex(i) == id then
				break
			end
			i = i + 1
		end
		if num_wq_watches < i then
			return
		end
	end
	return true
end

function LookingForGroup_Q:QUEST_ACCEPTED(event,quest_id)
	local load_time = LookingForGroup.load_time
	if load_time == nil or GetTime() < load_time + 5 then
		return
	end
	if is_group_q(quest_id) then
		coroutine.wrap(cofunc)(quest_id,0)
	end
end

function LookingForGroup_Q:LFG_SECURE_QUEST_ACCEPTED(_,quest_id,group)
	if is_group_q(quest_id,true) then
		coroutine.wrap(cofunc)(quest_id,1,group)
	end
end
