local AceAddon = LibStub("AceAddon-3.0")
local LookingForGroup = AceAddon:GetAddon("LookingForGroup")
local LookingForGroup_Elite = AceAddon:NewAddon("LookingForGroup_Elite","AceEvent-3.0")
local UnitGUID = UnitGUID
local UnitTarget = UnitTarget
local UnitClassification = UnitClassification
local IsInGroup = IsInGroup
local GetNumQuestLogEntries = C_QuestLog.GetNumQuestLogEntries
local GetInfo = C_QuestLog.GetInfo

function LookingForGroup_Elite:OnInitialize()
end

function LookingForGroup_Elite:OnEnable()
	self:RegisterEvent("LOADING_SCREEN_DISABLED")
end

local function cofunc(npc_id,name,guid)
	local quest_id,questName
	local n_npcid = tonumber(npc_id)
	if 120393 <= n_npcid and n_npcid <= 127706 then
		local C_TaskQuest_GetQuestInfoByQuestID = C_TaskQuest.GetQuestInfoByQuestID
		for i=48000,50000 do
			local title = C_TaskQuest_GetQuestInfoByQuestID(i)
			if title and title:find(name) then
				quest_id = i
				questName = title
				break
			end
		end
	end
	if quest_id then
		return
	end
	local activityID
	local activities = C_LFGList.GetAvailableActivities()
	local C_LFGList_GetActivityInfoExpensive = C_LFGList.GetActivityInfoExpensive
	for i=1,#activities do
		if C_LFGList_GetActivityInfoExpensive(activities[i]) then
			activityID = activities[i]
			break
		end
	end
	if activityID == nil then
		activityID = 280
	end
	local infotb = C_LFGList.GetActivityInfoTable(activityID)
	local categoryID = infotb.categoryID
	local filters = infotb.filters
	local function create()
		C_LFGList.CreateListing(activityID,0.1,0,true,false)
	end
	local function search()
		C_LFGList.SetSearchToActivity(activityID)
		return LookingForGroup.Search(categoryID,filters,0)
	end
	local confirm_keyword = "<LFG>Elite"..npc_id
	if LookingForGroup.accepted(name,search,create,0,nil,confirm_keyword) then
		return
	end
	local current = coroutine.running()
	LookingForGroup_Elite:RegisterEvent("LOADING_SCREEN_DISABLED",function()
		LookingForGroup.resume(current,0)
	end)
	local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
	LookingForGroup_Elite:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED",function()
		local timeStamp, event, hideCaster, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = CombatLogGetCurrentEventInfo()
		if event == "UNIT_DIED" and destGUID == guid then
			LookingForGroup.resume(current,0)
		end
	end)
	LookingForGroup.autoloop(name,create,true,nil,confirm_keyword,function()
		return true
	end)
	LookingForGroup_Elite:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	LookingForGroup_Elite:RegisterEvent("LOADING_SCREEN_DISABLED")
	LookingForGroup_Elite:LOADING_SCREEN_DISABLED()
end

function LookingForGroup_Elite:PLAYER_TARGET_CHANGED()
	if IsInGroup() then
		return
	end
	local guid = UnitGUID("target")
	if guid then
		local classification = UnitClassification("target")
		if classification == "rareelite" then
			local npc_id = select(6,strsplit("-",guid))
			if npc_id then
				local name = UnitName("target")
				if name then
					if UnitIsDead("target") then
						return
					end
					local i=1
					local n=GetNumQuestLogEntries()
					while i<=n do
						local info = GetInfo(i)
						if info then
							local title = info.title
							if title and title:find(name) then
								break
							end
						end
						i=i+1
					end
					if n<i then
						local player_level = UnitLevel("player")
						local target_level = UnitLevel("target")
						if target_level >= player_level then
							coroutine.wrap(cofunc)(npc_id,name,guid)
						end
					end
				end
			end
		end
	end
end

function LookingForGroup_Elite:LOADING_SCREEN_DISABLED()
	if IsInInstance() then
		self:UnregisterEvent("PLAYER_TARGET_CHANGED")
	else
		self:RegisterEvent("PLAYER_TARGET_CHANGED")
	end
end