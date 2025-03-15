local LookingForGroup = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup")
local Hook = LookingForGroup:NewModule("Hook","AceHook-3.0")

function Hook:OnInitialize()
	if WOW_PROJECT_ID == 1 or WOW_PROJECT_ID >= 11 then
	if QuestObjectiveSetupBlockButton_FindGroup then
		self:SecureHook("QuestObjectiveSetupBlockButton_FindGroup")
	end
	if QuestObjectiveReleaseBlockButton_FindGroup then
		self:SecureHook("QuestObjectiveReleaseBlockButton_FindGroup")
	end
	local disable_pve_frame = LookingForGroup.disable_pve_frame
	if disable_pve_frame == nop then
		if QueueStatusDropDown_AddLFGListButtons then
			self:RawHook("QueueStatusDropDown_AddLFGListButtons",true)
		end
		self:RawHook("QueueStatusEntry_SetUpLFGListApplication",true)
		self:RawHook("QueueStatusEntry_SetUpLFGListActiveEntry",true)
		self:RawHook("LFGListUtil_OpenBestWindow",true)
		self:RawHook("PVEFrame_ShowFrame",function()
			LookingForGroup:SendMessage("LFG_ICON_LEFT_CLICK")
		end,true)			-- lol. RawHook is correct while SecureHook is wrong here!
	else
		local EntryCreation = LFGListFrame.EntryCreation
		local original_description_ontextchanged = EntryCreation.Description.EditBox:GetScript("OnTextChanged")
		local original_voicechat_oneditfocuslost = EntryCreation.VoiceChat.EditBox:GetScript("OnEditFocusLost")
		LFGListFrame.EntryCreation:HookScript("OnShow",function(EntryCreation)
			local name,description,voicechat = EntryCreation.Name,EntryCreation.Description,EntryCreation.VoiceChat
			name:SetScript("OnTextChanged",InputBoxInstructions_OnTextChanged)
			name:SetScript("OnEnterPressed",EditBox_ClearFocus)
			name:ClearAllPoints()
			name:SetPoint("TOPLEFT", EntryCreation.NameLabel,"BOTTOMLEFT",5,-5)
			name:SetParent(EntryCreation)
			description.EditBox:SetScript("OnTextChanged",original_description_ontextchanged)
			description:ClearAllPoints()
			description:SetPoint("TOPLEFT",EntryCreation.DescriptionLabel, "BOTTOMLEFT",5,-10)
			description:SetParent(EntryCreation)
			local voicechat_editbox = voicechat.EditBox
			local voicechat_checkbutton = voicechat.CheckButton
			voicechat_editbox:SetScript("OnEditFocusLost",original_voicechat_oneditfocuslost)
			voicechat_editbox:ClearAllPoints()
			voicechat_editbox:SetPoint("RIGHT",voicechat,0,-3)
			voicechat_editbox:SetParent(voicechat)
			voicechat_checkbutton:ClearAllPoints()
			voicechat_checkbutton:SetPoint("LEFT",voicechat,0,0)
			name:Show()
			description:Show()
			voicechat_checkbutton:Show()
			voicechat:Show()
		end)
		local SearchBox = LFGListFrame.SearchPanel.SearchBox
		local original_searchbox_oneditfocusgained = SearchBox:GetScript("OnEditFocusGained")
		local original_searchbox_oneditfocuslost = SearchBox:GetScript("OnEditFocusLost")
		local original_clearbutton_onclick = SearchBox.clearButton:GetScript("OnClick")
		LFGListFrame.SearchPanel:HookScript("OnShow",function(SearchPanel)
			local SearchBox = SearchPanel.SearchBox
			SearchBox:ClearAllPoints()
			LFGListSearchPanel_UpdateAutoComplete(SearchPanel);
			SearchBox:SetParent(SearchPanel)
			SearchBox:SetScript("OnEnterPressed",LFGListSearchPanelSearchBox_OnEnterPressed)
			SearchBox:SetScript("OnArrowPressed",LFGListSearchPanelSearchBox_OnArrowPressed)
			SearchBox:SetScript("OnTabPressed",LFGListSearchPanelSearchBox_OnTabPressed)
			SearchBox:SetScript("OnTextChanged",LFGListSearchPanelSearchBox_OnTextChanged)
			SearchBox:SetScript("OnEditFocusGained",original_searchbox_oneditfocusgained)
			SearchBox:SetScript("OnEditFocusLost",original_searchbox_oneditfocuslost)
			SearchBox:SetPoint("TOPLEFT",SearchPanel.CategoryName,"BOTTOMLEFT",4,-7)
			SearchBox.clearButton:SetScript("OnClick",original_clearbutton_onclick)
			SearchBox:Show()
		end)
	end
	end
	self.OnInitialize=nil
	self.quest_objective_pool = CreateFramePool("BUTTON", nil, "QuestObjectiveFindGroupButtonTemplate", function(framePool, frame)
		frame.questID = nil
		frame:Hide()
		frame:ClearAllPoints()
		frame:SetParent(nil)
	end);
end

function Hook:LFGListUtil_OpenBestWindow()
	LookingForGroup:SendMessage("LFG_ICON_LEFT_CLICK","LookingForGroup","requests")
end

function Hook:QueueStatusDropDown_AddLFGListButtons()
	local info = {text = UnitIsGroupLeader("player") and EDIT or VIEW,func = function()
		LookingForGroup:SendMessage("LFG_UPDATE_EDITING")
	end,notCheckable = 1}
	UIDropDownMenu_AddButton(info)
	info.text = LFG_LIST_VIEW_GROUP
	info.func = function()
		LookingForGroup:SendMessage("LFG_ICON_LEFT_CLICK","LookingForGroup","requests")
	end
	UIDropDownMenu_AddButton(info)
	if UnitIsGroupLeader("player") then
		info.text = UNLIST_MY_GROUP
		info.func = C_LFGList.RemoveListing
		UIDropDownMenu_AddButton(info)
	end
end

function Hook:QueueStatusEntry_SetUpLFGListApplication(entry,resultID)
	local searchResultInfo = C_LFGList.GetSearchResultInfo(resultID)
	local concat_tb = {}
	local member_counts = C_LFGList.GetSearchResultMemberCounts(resultID)
	concat_tb[#concat_tb+1] = C_LFGList.GetActivityInfoTable(searchResultInfo.activityID).fullName
	concat_tb[#concat_tb+1] = "\n|cff00ffff"
	concat_tb[#concat_tb+1] = numMembers
	concat_tb[#concat_tb+1] = "("
	concat_tb[#concat_tb+1] = member_counts.TANK
	concat_tb[#concat_tb+1] = "/"
	concat_tb[#concat_tb+1] = member_counts.HEALER
	concat_tb[#concat_tb+1] = "/"
	concat_tb[#concat_tb+1] = member_counts.DAMAGER + member_counts.NOROLE
	concat_tb[#concat_tb+1] = ")|r"
	QueueStatusEntry_SetMinimalDisplay(entry,searchResultInfo.name,QUEUE_STATUS_SIGNED_UP,table.concat(concat_tb))
end

function Hook:QueueStatusEntry_SetUpLFGListActiveEntry(entry)
	local activeEntryInfo = C_LFGList.GetActiveEntryInfo();

	local concat_tb = {}
	
	local C_LFGList_GetActivityInfoTable = C_LFGList.GetActivityInfoTable
	local activityID = activeEntryInfo.activityID
	if activityID then
		local activityName = C_LFGList_GetActivityInfoTable(activeEntryInfo.activityID).fullName
		if activityName then
			concat_tb[#concat_tb+1] = "|cff8080cc"
			concat_tb[#concat_tb+1] = activityName
			concat_tb[#concat_tb+1] ="|r\n"
		end
	end
	local activityIDs = activeEntryInfo.activityIDs
	if activityIDs then
		for i=1,#activityIDs do
			local activityName = C_LFGList_GetActivityInfoTable(activityIDs[i]).fullName
			if activityName then
				concat_tb[#concat_tb+1] = "|cff8080cc"
				concat_tb[#concat_tb+1] = activityName
				concat_tb[#concat_tb+1] ="|r\n"	
			end
		end
	end
	local numApplicants,numActiveApplicants = C_LFGList.GetNumApplicants()
	concat_tb[#concat_tb+1] = LFG_LIST_PENDING_APPLICANTS:format(numActiveApplicants)
	local member_count_tb = GetGroupMemberCounts()
	local tank = member_count_tb.TANK
	local healer = member_count_tb.HEALER
	local damager = member_count_tb.DAMAGER+member_count_tb.NOROLE
	local total = tank+healer+damager
	concat_tb[#concat_tb+1]="\n|cffffffff"
	concat_tb[#concat_tb+1]=total
	concat_tb[#concat_tb+1]="("
	concat_tb[#concat_tb+1]=tank
	concat_tb[#concat_tb+1]="/"
	concat_tb[#concat_tb+1]=healer
	concat_tb[#concat_tb+1]="/"
	concat_tb[#concat_tb+1]=damager
	concat_tb[#concat_tb+1]=")|r"
	local questID, voiceChat, iLevel, comment, privateGroup,autoAccept = activeEntryInfo.questID,activeEntryInfo.voiceChat,activeEntryInfo.requiredItemLevel,activeEntryInfo.comment,activeEntryInfo.privateGroup,activeEntryInfo.autoAccept
	if questID then
		concat_tb[#concat_tb+1]="\n"
		concat_tb[#concat_tb+1]=questID
	end
	if voiceChat:len() ~= 0 then
		concat_tb[#concat_tb+1]="\n"
		concat_tb[#concat_tb+1]=LFG_LIST_VOICE_CHAT
		concat_tb[#concat_tb+1]=" |cff00ff00"
		concat_tb[#concat_tb+1]=voiceChat
		concat_tb[#concat_tb+1]="|r"
	end
	if iLevel ~= 0 then
		concat_tb[#concat_tb+1]="\n"
		concat_tb[#concat_tb+1]=ITEM_LEVEL_ABBR
		concat_tb[#concat_tb+1]=" |cffff00ff"
		concat_tb[#concat_tb+1]=iLevel
		concat_tb[#concat_tb+1]="|r"
	end
	local requiredPvpRating = activeEntryInfo.requiredPvpRating
	if requiredPvpRating then
		concat_tb[#concat_tb+1]="\n"
		concat_tb[#concat_tb+1]=GUILD_PVP_STATUS
		concat_tb[#concat_tb+1]=" |cffff00ff"
		concat_tb[#concat_tb+1]=requiredPvpRating
		concat_tb[#concat_tb+1]="|r"
	end
	local requiredDungeonScore = activeEntryInfo.requiredDungeonScore
	if requiredDungeonScore then
		concat_tb[#concat_tb+1]="\n"
		concat_tb[#concat_tb+1]=DUNGEON_SCORE
		concat_tb[#concat_tb+1]=" |cffff00ff"
		concat_tb[#concat_tb+1]=requiredDungeonScore
		concat_tb[#concat_tb+1]="|r"
	end
	local requiredHonorLevel = activeEntryInfo.requiredHonorLevel
	if requiredHonorLevel ~= 0 then
		concat_tb[#concat_tb+1]="\n"
		concat_tb[#concat_tb+1]=LFG_LIST_HONOR_LEVEL_INSTR_SHORT
		concat_tb[#concat_tb+1]=" |cffff00ff"
		concat_tb[#concat_tb+1]=requiredHonorLevel
		concat_tb[#concat_tb+1]="|r"
	end
	if comment:len() ~= 0  then
		concat_tb[#concat_tb+1]="\n\n|cff8080cc"
		concat_tb[#concat_tb+1]=comment
		concat_tb[#concat_tb+1]="|r"
	end
	local isCrossFactionListing = activeEntryInfo.isCrossFactionListing
	if privateGroup or autoAccept or isCrossFactionListing then
		concat_tb[#concat_tb+1]="\n"
		if privateGroup then
			concat_tb[#concat_tb+1]="\n"
			concat_tb[#concat_tb+1]=LFG_LIST_PRIVATE
		end
		if autoAccept then
			concat_tb[#concat_tb+1]="\n"
			concat_tb[#concat_tb+1]=LFG_LIST_AUTO_ACCEPT
		end
		if isCrossFactionListing then
			concat_tb[#concat_tb+1]="\n|cff8080cc"
			concat_tb[#concat_tb+1]=COMMUNITIES_EDIT_DIALOG_CROSS_FACTION
			concat_tb[#concat_tb+1]="|r"
		end
	end
	QueueStatusEntry_SetMinimalDisplay(entry,activeEntryInfo.name,QUEUE_STATUS_LISTED,table.concat(concat_tb))
end

function Hook.quest_group_onclick(button,key,unknown)
	if not IsInInstance() and not LookingForGroup:loadevent("LookingForGroup_Q","LFG_SECURE_QUEST_ACCEPTED",button.questID,key=="RightButton") then
		LookingForGroup:Print("LookingForGroup_Q failed to load")
	end
end

function Hook:QuestObjectiveSetupBlockButton_FindGroup(block, questID)
	if block.groupFinderButton then
		block.groupFinderButton:Hide()
	end
	if LookingForGroup.db.profile.auto_no_info_quest and not C_TaskQuest.GetQuestInfoByQuestID(questID) then
		return
	end
	local lfg_button = block.lfg_button
	if lfg_button then
		if lfg_button.questID == questID then 
			return
		else
			self.quest_objective_pool:Release(lfg_button)
		end
	end
	local button = self.quest_objective_pool:Acquire();
	button:SetParent(block)
	button.questID = questID
	button:RegisterForClicks("AnyUp")
	button:SetScript("OnClick",self.quest_group_onclick)
	button:ClearAllPoints()
	LookingForGroup:SendMessage("LFG_QUEST_BUTTON",button,questID,block)
	if button:GetNumPoints() == 0 then
		button:SetPoint("TOPRIGHT", block, "TOPRIGHT",-257,0)
	end
	button:Show()
	block.lfg_button = button
end

function Hook:QuestObjectiveReleaseBlockButton_FindGroup(block)
	local lfg_button = block.lfg_button
	if lfg_button then
		self.quest_objective_pool:Release(lfg_button)
		block.lfg_button = nil
	end
end
