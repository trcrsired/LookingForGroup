local LookingForGroup = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup")
local Event = LookingForGroup:NewModule("Event","AceEvent-3.0")

function Event:OnEnable()
	if LFGListInviteDialog then
		LFGListInviteDialog:UnregisterAllEvents()
	end
	self:RegisterEvent("PARTY_INVITE_REQUEST")
	UIParent:UnregisterEvent("PARTY_INVITE_REQUEST")
	local profile = LookingForGroup.db.profile
	if not profile.spam_filter_community then
		local frames = {GetFramesRegisteredForEvent("CLUB_INVITATION_ADDED_FOR_SELF")}
		for i=1,#frames do
			frames[i]:UnregisterEvent("CLUB_INVITATION_ADDED_FOR_SELF")
		end
	end
	if profile.disable_quick_join then
		local frames = {GetFramesRegisteredForEvent("SOCIAL_QUEUE_UPDATE")}
		for i=1,#frames do
			frames[i]:UnregisterEvent("SOCIAL_QUEUE_UPDATE")
		end
		FriendsFrameTab4:Hide()
		if QuickJoinFrame then
			QuickJoinFrame:Hide()
			QuickJoinToastButton:Hide()
			QuickJoinFrame:UnregisterAllEvents()
			QuickJoinToastButton:UnregisterAllEvents()
		end
	end
	local elvui = LibStub("AceAddon-3.0"):GetAddon("ElvUI",true)
	if elvui then
		local S = elvui:GetModule("Skins")
		S:RegisterMessage("LFG_QUEST_BUTTON",function(event,button,questID,block)
			if not button.elvui then
				S:HandleButton(button)
				button:Size(20)
				button.elvui = true
			end
			button:ClearAllPoints()
			button:SetPoint("TOPLEFT", block, "TOPRIGHT",4,0)
		end)
	end
	self.OnEnable = nil
	if C_LFGList.GetNumApplications then
	local numApplications, numActiveApplications = C_LFGList.GetNumApplications()
	if numActiveApplications ~= 0 then
		local applications = C_LFGList.GetApplications()
		local GetApplicationInfo = C_LFGList.GetApplicationInfo
		for i =1, #applications do
			local id, appStatus,pendingStatus = GetApplicationInfo(applications[i])
			if appStatus == "invited" then
				self:LFG_LIST_APPLICATION_STATUS_UPDATED(nil,id, appStatus,pendingStatus,arg3,arg4,arg5)
				return
			end
		end
	end
	end
	if LookingForGroup.disable_pve_frame == nop then
		if LFGEventFrame then
			LFGEventFrame:UnregisterEvent("LFG_UPDATE")
			LFGEventFrame:UnregisterEvent("LFG_LIST_ACTIVE_ENTRY_UPDATE");
			LFGEventFrame:UnregisterEvent("LFG_LIST_SEARCH_RESULT_UPDATED");
		end
		if PVEFrame then
			PVEFrame:UnregisterAllEvents()
		end
		if LFDParentFrame then
			LFDParentFrame:UnregisterEvent("AJ_DUNGEON_ACTION")
			LFDParentFrame:UnregisterEvent("LFG_OPEN_FROM_GOSSIP")
		end
		if RaidFinderFrame then
			RaidFinderFrame:UnregisterAllEvents()
		end
		if LFGListFrame then
			LFGListFrame:UnregisterAllEvents()
			LFGListFrame:RegisterEvent("LFG_LIST_APPLICATION_STATUS_UPDATED")
		end
	else
		if LFGListFrame then
			LFGListFrame:UnregisterEvent("LFG_LIST_ACTIVE_ENTRY_UPDATE")
			LFGListFrame:UnregisterEvent("LFG_LIST_APPLICANT_UPDATED")
		end
	end
	if LookingForGroup.lfgsystemactivate then
		self:RegisterEvent("LFG_LIST_ACTIVE_ENTRY_UPDATE")
		self:RegisterEvent("LFG_LIST_APPLICANT_UPDATED")
		self:RegisterEvent("LFG_LIST_APPLICATION_STATUS_UPDATED")
	end
end

function Event:LFG_LIST_APPLICANT_UPDATED()
	if InCombatLockdown() or ( select(2,C_LFGList.GetNumApplicants()) == 0 ) then
		QueueStatusButton:SetGlowLock("lfglist-applicant", false)
	end
end

function Event:LFG_LIST_ACTIVE_ENTRY_UPDATE(event,creatednew)
	if creatednew and not LookingForGroup.db.profile.mute then
		PlaySound(SOUNDKIT.PVP_ENTER_QUEUE)
	end
end

function Event:PARTY_INVITE_REQUEST(event, name, tank, healer, damage, isXRealm, allowMultipleRoles, inviterGuid)
	-- Color the name by our relationship
	local modifiedName, color, selfRelationship = SocialQueueUtil_GetRelationshipInfo(inviterGuid);
	if ( selfRelationship ) then
		name = color..name..FONT_COLOR_CODE_CLOSE;
	elseif not LookingForGroup.db.profile.sf_invite_relationship then
		Event:SendMessage("LFG_CHAT_MSG_SILENT",0)
		DeclineGroup()
		return
	end
	-- if there's a role, it's an LFG invite
	if ( tank or healer or damage ) then
		StaticPopupSpecial_Show(LFGInvitePopup);
		LFGInvitePopup_Update(name, tank, healer, damage, allowMultipleRoles);
	else
		local text = isXRealm and INVITATION_XREALM or INVITATION;
		text = string.format(text, name);

		if ( WillAcceptInviteRemoveQueues() ) then
			text = text.."\n\n"..ACCEPTING_INVITE_WILL_REMOVE_QUEUE;
		end
		StaticPopup_Show("PARTY_INVITE", text);
	end
end

function Event.show_invite_dialog(resultID)
	local searchResultInfo = C_LFGList.GetSearchResultInfo(resultID)

	local concat_tb = {}
	local member_counts = C_LFGList.GetSearchResultMemberCounts(resultID)

	local activityID = searchResultInfo.activityID
	if activityID then
		local activityName = C_LFGList.GetActivityInfoTable(activityID).fullName
		if activityName then
			concat_tb[#concat_tb+1] = activityName
		end
	end
	local activityIDs = searchResultInfo.activityIDs
	if activityIDs then
		local nothing = true
		for i=1,#activityIDs do
			local activityName = C_LFGList.GetActivityInfoTable(activityID).fullName
			if nothing then
				nothing = false
			else
				concat_tb[#concat_tb+1] = '\n'
			end
			concat_tb[#concat_tb+1] = activityName
		end
	end
	concat_tb[#concat_tb+1] = '\n|cff00ffff'
	concat_tb[#concat_tb+1] = searchResultInfo.numMembers
	concat_tb[#concat_tb+1] = "("
	concat_tb[#concat_tb+1] = member_counts.TANK
	concat_tb[#concat_tb+1] = "/"
	concat_tb[#concat_tb+1] = member_counts.HEALER
	concat_tb[#concat_tb+1] = "/"
	concat_tb[#concat_tb+1] = member_counts.DAMAGER + member_counts.NOROLE
	concat_tb[#concat_tb+1] = ")|r"
	if searchResultInfo.leaderName then
		concat_tb[#concat_tb+1] = "\n|cffff00ff"
		concat_tb[#concat_tb+1] = searchResultInfo.leaderName
		concat_tb[#concat_tb + 1] = "|r"
	end
	local LFGListInviteDialog = LFGListInviteDialog
	LFGListInviteDialog.GroupName:SetText(searchResultInfo.name);
	LFGListInviteDialog.ActivityName:SetText(table.concat(concat_tb));
	wipe(concat_tb)
	local applicationid, status, pending, appduration, role = C_LFGList.GetApplicationInfo(resultID);
	local informational = (status ~= "invited");

	LFGListInviteDialog.Role:SetText(_G[role]);
--[[
	if ElvUI then
		LFGListInviteDialog.RoleIcon:SetTexCoord(GetBackgroundTexCoordsForRole(role));
	else
		LFGListInviteDialog.RoleIcon:SetTexCoord(GetTexCoordsForRole(role));
	end
]]
	LFGListInviteDialog.RoleIcon:SetAtlas(GetIconForRole(role, false), TextureKitConstants.IgnoreAtlasSize)
	LFGListInviteDialog.Label:SetText(informational and LFG_LIST_JOINED_GROUP_NOTICE or LFG_LIST_INVITED_TO_GROUP);
	LFGListInviteDialog.AcceptButton:SetShown(true);
	LFGListInviteDialog.DeclineButton:SetShown(true);
	LFGListInviteDialog.AcknowledgeButton:SetShown(false);

	LFGListInviteDialog:SetHeight(210);
	LFGListInviteDialog.OfflineNotice:Hide();

	StaticPopupSpecial_Show(LFGListInviteDialog);

	local profile = LookingForGroup.db.profile
	if not profile.mute then
		PlaySound(SOUNDKIT.READY_CHECK);
	end
	if profile.taskbar_flash then
		FlashClientIcon();
	end
end

local function invited_cofunc(applicationid,invited,applied)
	local current = coroutine.running()
	local function event_callback(...)
		LookingForGroup.resume(current,...)
	end
	Event:RegisterEvent("LFG_LIST_JOINED_GROUP",event_callback)
	Event:RegisterEvent("LFG_LIST_APPLICATION_STATUS_UPDATED",event_callback) 
	Event:RegisterEvent("PARTY_LEADER_CHANGED",event_callback)
	local LFGListInviteDialog = LFGListInviteDialog
	local AcceptButton = LFGListInviteDialog.AcceptButton
	local DeclineButton = LFGListInviteDialog.DeclineButton
	local original_accept_onclick = AcceptButton:GetScript("OnClick")
	local original_decline_onclick = DeclineButton:GetScript("OnClick")
	AcceptButton:SetScript("OnClick",function()
		LookingForGroup.resume(current,0,true)
	end)
	DeclineButton:SetScript("OnClick",function()
		LookingForGroup.resume(current,0,false)
	end)
	if LFGListUtil_IsAppEmpowered() then
		if not LFGListInviteDialog:IsShown() then
			Event.show_invite_dialog(applicationid)
		end
	end
	while true do
		local event,arg1,arg2,arg3,arg4,arg5 = coroutine.yield()
		if event == "LFG_LIST_JOINED_GROUP" then
			StaticPopupSpecial_Hide(LFGListInviteDialog)
			break
		elseif event == "PARTY_LEADER_CHANGED" then
			if LFGListUtil_IsAppEmpowered() then
				if not LFGListInviteDialog:IsShown() then
					Event.show_invite_dialog(applicationid)
				end
			else
				StaticPopupSpecial_Hide(LFGListInviteDialog)
			end
		else
			if event == 0 then
				if arg1 then
					C_LFGList.AcceptInvite(applicationid)
				else
					C_LFGList.DeclineInvite(applicationid)
				end
				StaticPopupSpecial_Hide(LFGListInviteDialog)
				local numApplications, numActiveApplications = C_LFGList.GetNumApplications()
				if numActiveApplications == 0 then
					break
				end
			elseif event == "LFG_LIST_APPLICATION_STATUS_UPDATED" then
				if arg1 == applicationid and arg2 ~= "invited" then
					StaticPopupSpecial_Hide(LFGListInviteDialog)
				end
			end
			local applications = C_LFGList.GetApplications()
			local GetApplicationInfo = C_LFGList.GetApplicationInfo
			local i = 1
			while i <= #applications do
				local id, appStatus,pending = GetApplicationInfo(applications[i])
				if appStatus == "invited" and pending ~= "invitedeclined" then
					applicationid = id
					Event.show_invite_dialog(id)
					break
				end
				i = i + 1
			end
			if #applications < i then
				break
			end
		end
	end
	AcceptButton:SetScript("OnClick",original_accept_onclick)
	DeclineButton:SetScript("OnClick",original_decline_onclick)
	Event:UnregisterEvent("LFG_LIST_JOINED_GROUP")
	Event:UnregisterEvent("PARTY_LEADER_CHANGED")
	Event:RegisterEvent("LFG_LIST_APPLICATION_STATUS_UPDATED")
end

function Event:LFG_LIST_APPLICATION_STATUS_UPDATED(event,applicationid,invited,pendingStatus)
	if invited == "invited" then
		coroutine.wrap(invited_cofunc)(applicationid,invited,applied)
	end
end
