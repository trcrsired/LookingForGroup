local LookingForGroup = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup")
local LookingForGroup_Options = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup_Options")

function LookingForGroup_Options.req_main(auto_accept,filters,back_list,LFGList,dialogControl)
	local current = coroutine.running()
	local function event_func(...)
		LookingForGroup.resume(current,...)
	end
	local LFGList = LookingForGroup.lfglist_apis(LFGList)
	local to_list = not LFGList.HasActiveEntryInfo()
	if to_list then
		LookingForGroup_Options:RegisterEvent("LFG_LIST_ACTIVE_ENTRY_UPDATE",event_func)
		LookingForGroup_Options:RegisterEvent("LFG_LIST_ENTRY_CREATION_FAILED",event_func)
		local yd = coroutine.yield()
		if auto_accept == 1 or yd == "LFG_LIST_ENTRY_CREATION_FAILED" then
			if auto_accept ~= 1 then
				LookingForGroup_Options.expected(FAILED..": LFG_LIST_ENTRY_CREATION_FAILED")
			end
			LookingForGroup_Options:UnregisterEvent("LFG_LIST_ENTRY_CREATION_FAILED")
			LookingForGroup_Options:RegisterEvent("LFG_LIST_ACTIVE_ENTRY_UPDATE")
			return
		end
		LookingForGroup_Options:SendMessage("LFG_LIST_OR_UPDATE")
	end
	filters = filters or {"s","f"}
	local app_tb = {}
	LookingForGroup_Options.applicants = app_tb
	local app = {}
	local app_invited = {}
	local app_applied = {}
	local b =
	{
		type = "multiselect",
		width = "full",
		dialogControl = dialogControl or "lfg_opt_rq_default_multiselect",
		values = app,
		name = nop
	}
	local a =
	{
		type = "group",
		order = 5,
		name = nop,
		args =
		{
			applicant_list = b
		}
	}
	local enable_filters = true
--	local whisper_text
	if auto_accept ~= 1 then
		LookingForGroup_Options.option_table.args.requests =
		{
			name = LFGUILD_TAB_REQUESTS_NONE,
			type = "group",
			childGroups = "tab",
			args =
			{
				apply =
				{
					name = APPLY,
					type = "execute",
					order = 1,
					func = function()
						LookingForGroup.resume(current,1)
					end,
					width = 0.667
				},
				delist =
				{
					order = 2,
					name = UNLIST_MY_GROUP,
					type = "execute",
					func = function()
						LookingForGroup.resume(current,0)
					end
				},
				filters =
				{
					order = 3,
					name = FILTERS,
					type = "toggle",
					get = function()
						return enable_filters
					end,
					set = function(_,val)
						enable_filters = val
						auto_accept = false
						LookingForGroup_Options:SendMessage("LFG_APPLICANT_LIST_REFRESH")
					end,
					width = 0.667
				},
				autoaccept = auto_accept ~= 0 and
				{
					order = 4,
					name = LFG_LIST_AUTO_ACCEPT,
					type = "toggle",
					get = function()
						if LFGList.CanActiveEntryUseAutoAccept() then
							return LFGList.GetActiveEntryInfo().autoAccept
						else
							return auto_accept
						end
					end,
					set = function(_,val)
						if LFGList.Util_IsEntryEmpowered() then
							if LFGList.CanActiveEntryUseAutoAccept() then
								local info = LFGList.GetActiveEntryInfo()				
								LFGList.UpdateListing(info.activityID,info.requiredItemLevel,info.requiredHonorLevel,val,info.privateGroup,info.questID)
							else
								auto_accept = val
								LookingForGroup_Options:SendMessage("LFG_APPLICANT_LIST_REFRESH")
							end
						end
					end,
					width = 0.667
				} or nil,
--[[				whisper=
				{
					order = 4,
					name = WHISPER,
					type = "input",
					get = function()
						return whisper_text
					end,
					set = function(_,val)
						if val:len()==0 then
							whisper_text = nil
						else
							whisper_text = val
						end
					end,
					width = "full"
				},]]
				applicants = a
			}
		}
		if auto_accept == 0 then
			auto_accept = nil
		end
		local AceConfigDialog = LibStub("AceConfigDialog-3.0")
		if to_list then
			AceConfigDialog:SelectGroup("LookingForGroup","requests")
		else
			LibStub("AceConfigRegistry-3.0"):NotifyChange("LookingForGroup")
		end
	end
	LookingForGroup.disable_pve_frame()
	QueueStatusButton:SetGlowLock("lfglist-applicant", false)
	local event = LookingForGroup:GetModule("Event")
	event:UnregisterEvent("LFG_LIST_APPLICANT_UPDATED")
	if auto_accept == 1 then
		auto_accept = nil
	else
		LookingForGroup_Options:RegisterEvent("LFG_LIST_APPLICANT_LIST_UPDATED",event_func)
		LookingForGroup_Options:RegisterEvent("LFG_LIST_APPLICANT_UPDATED",event_func)
	end
	LookingForGroup_Options:RegisterEvent("LFG_LIST_ACTIVE_ENTRY_UPDATE",event_func)
	LookingForGroup_Options:RegisterMessage("LFG_APPLICANT_LIST_REFRESH",event_func)
	local profile = LookingForGroup.db.profile
	local hardware = profile.hardware
	local yd,arg1,arg2 = "LFG_LIST_APPLICANT_UPDATED"
	local concat = {}

	local relist_timer
	local cache = {}
	while true do
		local entryinfo = LFGList.GetActiveEntryInfo()
		if not entryinfo then
			break
		end
		local entryinfo = LFGList.GetActiveEntryInfo()
		entryinfo.activityInfo = LFGList.GetActivityInfoTable(entryinfo.activityID)
		if not hardware then
			local duration = entryinfo.duration - 60
			if duration < 0 then
				duration = 1
			end
			if relist_timer then
				relist_timer:Cancel()
			end
			relist_timer=C_Timer.NewTimer(duration,function()
				LookingForGroup.resume(current,"LFG_Relist_Timer")
			end) 
		end
		if yd == 0 then
			if LFGList.Util_IsEntryEmpowered() then
				LFGList.RemoveListing()
			end
		elseif yd == 1 then
			if LFGList.Util_IsEntryEmpowered() then
				if hardware then
					local k,v = next(app_tb)
					if k then
						if v then
							LFGList.InviteApplicant(k)
						elseif v == false then
							LFGList.DeclineApplicant(k)
						end
						app_tb[k]=nil
					end
				else
					local InviteApplicant = LFGList.InviteApplicant
					local DeclineApplicant = LFGList.DeclineApplicant
					for k,v in pairs(app_tb) do
						if v then
							InviteApplicant(k)
						elseif v == false then
							DeclineApplicant(k)
						end
					end
				end
			end
		elseif yd=="LFG_Relist_Timer" then
			LFGList.UpdateListing(entryinfo.activityID,entryinfo.requiredItemLevel,entryinfo.requiredHonorLevel,entryinfo.autoAccept,entryinfo.privateGroup,entryinfo.questID)
		else
			wipe(app)
			wipe(app_invited)
			wipe(app_applied)
			local ap = LFGList.GetApplicants()
			local LFGList_GetApplicantInfo = LFGList.GetApplicantInfo
			if ap then
				local exf = LookingForGroup_Options.ExecuteApplicantFilter
				for i=1,#ap do
					local info = LFGList_GetApplicantInfo(ap[i])
					ap[i] = info
					info.activeEntryInfo = entryinfo
					info.LFGList = LFGList
					local id = info.applicantID
					local status = info.applicationStatus
					if status == "invited" then
						app_invited[#app_invited+1] = info
						app[#app+1] = info
					elseif status == "applied" and (not enable_filters or exf(id,filters,entryinfo,info,cache)) then
						app_applied[#app_applied+1] = info
						app[#app+1] = info
					end
				end
				wipe(concat)
				concat[#concat+1] = #app_invited
				concat[#concat+1] = '/'
				concat[#concat+1] = #app_applied
				concat[#concat+1] = '/'
				concat[#concat+1] = #app
				concat[#concat+1] = '/'
				local numApplicants,numActiveApplicants = LFGList.GetNumApplicants()
				concat[#concat+1] = numApplicants
				concat[#concat+1] = '/'
				concat[#concat+1] = numActiveApplicants
				a.name = table.concat(concat)
			else
				a.name = nop
			end
			if profile.mute or InCombatLockdown() or not LFGList.Util_IsEntryEmpowered() or #app_applied == 0 then
				QueueStatusButton:SetGlowLock("lfglist-applicant", false)
			elseif yd == "LFG_LIST_APPLICANT_LIST_UPDATED" and ( arg1 and arg2 ) and not entryinfo.autoAccept and not auto_accept then
				QueueStatusButton:SetGlowLock("lfglist-applicant", true)
			end
			LookingForGroup_Options.NotifyChangeIfSelected("requests")
			if profile.taskbar_flash and #app_applied ~= 0  then
				FlashClientIcon()
			end
			if not entryinfo.autoAccept and not LFGList.CanActiveEntryUseAutoAccept() and auto_accept then
				local ok,error_msg = pcall(LookingForGroup_Options.do_auto_accept,LFGList,filters,entryinfo,app_invited,app_applied,app,ap)
				if not ok then
					LookingForGroup_Options.Paste(error_msg,nop)
				end
			end
		end
		yd,arg1,arg2 = coroutine.yield()
	end
	QueueStatusButton:SetGlowLock("lfglist-applicant", false)
	LookingForGroup_Options:UnregisterEvent("LFG_LIST_APPLICANT_LIST_UPDATED")
	LookingForGroup_Options:UnregisterEvent("LFG_LIST_APPLICANT_UPDATED")
	LookingForGroup_Options:UnregisterMessage("LFG_APPLICANT_LIST_REFRESH")
	event:RegisterEvent("LFG_LIST_APPLICANT_UPDATED")
	LookingForGroup_Options.option_table.args.requests = nil
	if LookingForGroup_Options.IsSelected("requests") then
		local AceConfigDialog = LibStub("AceConfigDialog-3.0")
		if back_list then
			AceConfigDialog:SelectGroup("LookingForGroup",unpack(back_list))
		else
			AceConfigDialog:SelectGroup("LookingForGroup","find","s")
		end
	else
		LibStub("AceConfigRegistry-3.0"):NotifyChange("LookingForGroup")
	end
	if LookingForGroup.disable_pve_frame == nop then
		LookingForGroup_Options:RegisterEvent("LFG_LIST_ACTIVE_ENTRY_UPDATE")
	end
	LookingForGroup.enable_pve_frame()
	if relist_timer then
		relist_timer:Cancel()
	end
end

function LookingForGroup_Options:LFG_LIST_ACTIVE_ENTRY_UPDATE(event,new)
	if new and C_LFGList.HasActiveEntryInfo() then
		coroutine.wrap(LookingForGroup_Options.req_main)()
	end
end

function LookingForGroup_Options:LFG_AUTO_MAIN_LOOP(event,keyword)
	coroutine.wrap(LookingForGroup_Options.req_main)(1)
end

local AceGUI = LibStub("AceGUI-3.0")
AceGUI:RegisterWidgetType("lfg_opt_rq_default_multiselect", function()
	local control = AceGUI:Create("InlineGroup")
	control.type = "lfg_opt_rq_default_multiselect"
	function control.OnAcquire()
		control:SetLayout("Flow")
		control.width = "fill"
		control.SetList = function(self,values)
			self.values = values
		end
		control.SetLabel = function(self,value)
			self:SetTitle(value)
		end
		control.SetDisabled = function(self,disabled)
			self.disabled = disabled
		end
		control.SetMultiselect = nop
		QueueStatusButton:SetGlowLock("lfglist-applicant", false)
		local app_tb = LookingForGroup_Options.applicants
		control.SetItemValue = function(self,key)
			local applicantInfo = self.values[key]
			if applicantInfo then
				local check = AceGUI:Create("LookingForGroup_applicant_checkbox")
				check:SetUserData("applicantInfo", applicantInfo)
				check:updateapplicant()
				local applicantID = applicantInfo.applicantID
				local v = app_tb[applicantID]
				if v then
					check:SetValue(true)
				elseif v == nil then
					check:SetValue(false)
				end
				local status = applicantInfo.applicationStatus
				if status == "applied" then
					check:SetTriState(true)
					check:SetCallback("OnValueChanged",function(self,event,val)
						local user = self:GetUserDataTable()
						local appInfo = user.applicantInfo
						if appInfo then
							local LFGList = appInfo.LFGList
							if LFGList.Util_IsEntryEmpowered() then
								if val == nil then
									val = false
								elseif val == false then
									val = true
								else
									val = nil
								end
								local key = appInfo.applicantID
								if val then
									app_tb[key] = true
								elseif val == nil then
									app_tb[key] = false
								else
									app_tb[key] = nil
								end
								check:SetValue(val)
							end
						end
					end)
				elseif status == "invited" then
					check:SetValue(true)
					check:SetCallback("OnValueChanged",nop)
				end
				check.width = "fill"
				self:AddChild(check)
			end
		end
	end
	return AceGUI:RegisterAsContainer(control)
end , 1)
