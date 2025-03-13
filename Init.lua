local LookingForGroup = LibStub("AceAddon-3.0"):NewAddon("LookingForGroup","AceEvent-3.0","AceConsole-3.0")

local C_AddOns = C_AddOns
if C_AddOns == nil then
LookingForGroup.C_AddOns =
{
LoadAddOn = LoadAddOn,
GetNumAddOns = GetNumAddOns,
GetAddOnMetadata = GetAddOnMetadata,
IsAddOnLoaded = IsAddOnLoaded,
GetAddOnInfo = GetAddOnInfo,
GetAddOnDependencies = GetAddOnDependencies
}
else
LookingForGroup.C_AddOns = C_AddOns
end

local LFG_C_AddOns = LookingForGroup.C_AddOns
local GetAddOnMetadata = LFG_C_AddOns.GetAddOnMetadata
local GetAddOnInfo = LFG_C_AddOns.GetAddOnInfo
local GetNumAddOns = LFG_C_AddOns.GetNumAddOns
local IsAddOnLoaded = LFG_C_AddOns.IsAddOnLoaded
local LoadAddOn = LFG_C_AddOns.LoadAddOn

function LookingForGroup:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("LookingForGroupDB",{profile = ((GetCurrentRegion()==5 and {spam_filter_maxlength=120,spam_filter_digits=2,spam_filter_hyperlinks=2}) or {spam_filter_maxlength=80,hardware = true})},true)
	self:RegisterChatCommand("LookingForGroup", "ChatCommand")
	self:RegisterChatCommand("LFG", "ChatCommand")
	self:RegisterChatCommand(LFG_TITLE:gsub(" ",""), "ChatCommand")
	if LFGListFrame then
		if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE or 4 < LE_EXPANSION_LEVEL_CURRENT then
			LookingForGroup.lfgsystemactivate = true
		end
	end
	local disable_pve_frame
	for i = 1, GetNumAddOns() do
		if GetAddOnMetadata(i, "X-LFG-DISABLE-PVEFRAME") then
			local name, title, notes, loadable, reason, security, newVersion = GetAddOnInfo(i)
			if loadable or reason == "DEMAND_LOADED" then
				disable_pve_frame = true
				break
			end
		end
	end
	local portal = GetCVar("portal")
	local isprivateserver
	if portal == "127.0.0.1" then
		isprivateserver = true
	end
	local region = GetCurrentRegion()
	if isprivateserver then
		region = GetRealmName()
		LookingForGroup.privateservername = region
	end
	for i = 1, GetNumAddOns() do
		local metadata = GetAddOnMetadata(i, "X-LFG-REGION")
		if metadata and (metadata == "0" or region == tonumber(metadata)) then
			LoadAddOn(i)
		end
	end
	local event_zero
	for j=1,2 do
		local xevent,xmessage
		if j==1 then
			xevent = "X-LFG-EVENT"
			xmessage = "X-LFG-MESSAGE"
		elseif disable_pve_frame then
			xevent = "X-LFG-DISABLE-PVEFRAME-EVENT"
			xmessage = "X-LFG-DISABLE-PVEFRAME-MESSAGE"
		else
			xevent = "X-LFG-PVEFRAME-EVENT"
			xmessage = "X-LFG-PVEFRAME-MESSAGE"
		end
		for i = 1, GetNumAddOns() do
			local events = GetAddOnMetadata(i, xevent)
			if events then
				if events == "0" then
					event_zero = true
				else
					for event in gmatch(events, "([^,]+)") do
						self:RegisterEvent(event,"loadevent",i)
					end
				end
			end
			local messages = GetAddOnMetadata(i,xmessage)
			if messages then
				for message in gmatch(messages, "([^,]+)") do
					self:RegisterMessage(message,"loadevent",i)
				end
			end
		end
	end
	if event_zero then
		self:LOADING_SCREEN_DISABLED()
	else
		LookingForGroup.LOADING_SCREEN_DISABLED = nil
	end
	if disable_pve_frame then
		LookingForGroup.disable_pve_frame = nop
		LookingForGroup.enable_pve_frame = nop
	end
	self.OnInitialize = nil
end

function LookingForGroup:ChatCommand(input)
	self:SendMessage("LFG_ChatCommand",input)
end

function LookingForGroup:OnEnable()
	self.load_time = GetTime()
	self.OnInitialize = nil
	self.OnEnable = nil
end

function LookingForGroup.resume(current,...)
	local current_status = coroutine.status(current)
	if current_status =="suspended" then
		local status, msg = coroutine.resume(current,...)
		if not status then
			LookingForGroup:Print(msg)
		end
		return status,msg
	end
	return current_status
end

function LookingForGroup.Search(category,filters,preferredfilters,crossfactionlisting)
	LookingForGroup:SendMessage("LFG_CORE_FINALIZER",0)
	C_LFGList.Search(category,filters,preferredfilters,C_LFGList.GetLanguageSearchFilter(),crossfactionlisting)
	local current = coroutine.running()
	local function resume(...)
		LookingForGroup.resume(current,...)
	end
	LookingForGroup:RegisterEvent("LFG_LIST_SEARCH_RESULTS_RECEIVED",resume)
	LookingForGroup:RegisterEvent("LFG_LIST_SEARCH_FAILED",resume)
	local r = coroutine.yield()
	LookingForGroup:UnregisterEvent("LFG_LIST_SEARCH_RESULTS_RECEIVED")
	LookingForGroup:UnregisterEvent("LFG_LIST_SEARCH_FAILED")
	if r == "LFG_LIST_SEARCH_RESULTS_RECEIVED" then
		return C_LFGList.GetSearchResults()
	end
	return 0
end

function LookingForGroup:loadevent(p,event,...)
	LookingForGroup:UnregisterEvent(event)
	LookingForGroup:UnregisterMessage(event)
	if IsAddOnLoaded(p) then
		self:SendMessage(event,...)
		return true
	end
	LoadAddOn(p)
	if IsAddOnLoaded(p) then
		local addon = GetAddOnMetadata(p,"X-LFG-EM-HOSTER") or GetAddOnInfo(p)
		local a = LibStub("AceAddon-3.0"):GetAddon(addon)
		a[event](a,event,...)
		collectgarbage("collect")
		return true
	end
end

function LookingForGroup:LOADING_SCREEN_DISABLED()
	local name,v = GetInstanceInfo()
	if v == "none" or v == "scenario" then
		for i = 1, GetNumAddOns() do
			if GetAddOnMetadata(i, "X-LFG-EVENT") == "0" then
				LoadAddOn(i)
			end
		end
		self:UnregisterEvent("LOADING_SCREEN_DISABLED")
		LookingForGroup.LOADING_SCREEN_DISABLED = nil
	else
		self:RegisterEvent("LOADING_SCREEN_DISABLED")
	end
end

function LookingForGroup.accepted(...)
	LookingForGroup.accepted = nil
	local loaded, reason = LoadAddOn("LookingForGroup_Auto")
	if not loaded then return true end
	return LookingForGroup.accepted(...)
end

function LookingForGroup.realm_filter(name)
	if not name then return true end
	local profile = LookingForGroup.db.profile
	local mode_rf = profile.mode_rf
	local flags_disable = profile.flags_disable
	if mode_rf == nil and flags_disable then
		return
	end
	local _,realm = strsplit("-",name)
	if realm == nil then return end
	if mode_rf ~= nil then
		local t
		local realm_filters = profile.realm_filters
		if realm_filters and realm_filters[realm] then
			t = true
		end
		if mode_rf == false then
			t = not t
		end
		if t then
			return true
		end
	end
	local flags_tb = profile.flags
	local flags = LookingForGroup.flags
	if not flags_disable and flags_tb and flags then
		local f3 = flags[3][realm]
		local f
		if f3 == nil then
			f = flags_tb[0]
		else
			f = flags_tb[f3]
		end
		if f then
			return true
		elseif f == false then
			return
		end
		local has_white = profile.flags_has_white
		if has_white then
			return true
		end
	end
end

function LookingForGroup.create_popup()
	LookingForGroup.create_popup = nil
	local popup = CreateFrame("Frame","LFGPopupFrame",UIParent)
	popup:Hide()
	tinsert(UISpecialFrames, popup:GetName())
	LookingForGroup.popup = popup
	popup:SetScript("OnHide",function(self)
		if self.attached_frame then
			self.attached_frame:Hide()
			self.attached_frame = nil
		end
		self.buttons_pool:ReleaseAll()
		self.func_tb = nil
	end)
	local bgtexture = popup:CreateTexture(nil,"BACKGROUND")
	bgtexture:SetTexture(131071)
	bgtexture:SetAllPoints(popup)
	popup.bgtexture = bgtexture
	popup:SetPoint("TOP", UIParent, "TOP", 0, -135)
	popup:SetFrameStrata("TOOLTIP")
	local text = popup:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
	text:SetPoint("TOP", 0, -16)
	popup.text = text
	popup.buttons_pool = CreateFramePool("Button",popup)
end

function LookingForGroup.show_popup(text,tb,attached_frame)
	if LookingForGroup.create_popup then
		LookingForGroup.create_popup()
	end
	local popup = LookingForGroup.popup
	popup.text:SetText(text)
	if popup.attached_frame then
		popup.attached_frame:Hide()
		popup.attached_frame = nil
	end
	local height = 58 + popup.text:GetHeight()
	if attached_frame then
		popup.attached_frame = attached_frame
		attached_frame:SetParent(popup)
		attached_frame:ClearAllPoints()
		attached_frame:SetPoint("TOP",popup.text,"BOTTOM",0,-5)
		height = height + attached_frame:GetHeight() + 5
		attached_frame:Show()
	end
	popup.func_tb = tb
	local buttons_pool = popup.buttons_pool
	buttons_pool:ReleaseAll()
	local numtb = floor(#tb / 2) + 1
	local width = max(max(30+popup.text:GetWidth(),320),200*numtb)
	popup:SetSize(width,max(70,height))
	local buttonpoint = width/(numtb+1)
	for i=1,#tb,2 do
		local button = buttons_pool:Acquire()
		button:SetSize(130, 21)
		button:SetNormalFontObject(GameFontNormal)
		button:SetHighlightFontObject(GameFontHighlight)
		button:SetNormalTexture(130763) -- "Interface\\Buttons\\UI-DialogBox-Button-Up"
		button:GetNormalTexture():SetTexCoord(0.1, 0.9, 0.2, 0.51875)
		button:GetNormalTexture():SetVertexColor(0,0,0,0.8)
		local script = tb[i]
		button:SetScript("OnClick",function()
			popup.func_tb = nil
			popup:Hide()
			script()
		end)
		if i == 1 then
			button:SetText(tb[0] or CANCEL)
			button:SetPoint("BOTTOM",popup,"BOTTOMRIGHT",-buttonpoint,8)
		else
			button:SetText(tb[i-1])
			button:SetPoint("BOTTOM",popup,"BOTTOMLEFT",((i-1)/2)*buttonpoint,8)
		end
		button:Show()
	end
	popup:Show()
end

function LookingForGroup.disable_pve_frame(nochangehookstatus)
	LFGListFrame:UnregisterAllEvents()
	LFGListFrame:Hide()
	GroupFinderFrame.groupButton3:Hide()
	local LFGListPVPStub = LFGListPVPStub
	if LFGListPVPStub then
		LFGListPVPStub:Hide()
	end
	local PVPQueueFrame = PVPQueueFrame
	if PVPQueueFrame then
		PVPQueueFrame.CategoryButton3:Hide()
	end
	if not nochangehookstatus then
		local Hook = LookingForGroup:GetModule("Hook")
		if Hook ~= nil then
			if not Hook:IsHooked("QueueStatusDropDown_AddLFGListButtons") then
				Hook:RawHook("QueueStatusDropDown_AddLFGListButtons",true)
				Hook:RawHook("QueueStatusEntry_SetUpLFGListApplication",true)
				Hook:RawHook("QueueStatusEntry_SetUpLFGListActiveEntry",true)
				Hook:RawHook("LFGListUtil_OpenBestWindow",true)
			end
		end
	end
end

function LookingForGroup.enable_pve_frame(nochangehookstatus)
	LFGListFrame_OnLoad(LFGListFrame)
	LFGListFrame:Show()
	GroupFinderFrame.groupButton3:Show()
	local LFGListPVPStub = LFGListPVPStub
	if LFGListPVPStub then
		LFGListPVPStub:Show()
	end
	local PVPQueueFrame = PVPQueueFrame
	if PVPQueueFrame then
		PVPQueueFrame.CategoryButton3:Show()
	end
	if not nochangehookstatus then
		local Hook = LookingForGroup:GetModule("Hook")
		if Hook ~= nil then
			Hook:Unhook("QueueStatusDropDown_AddLFGListButtons")
			Hook:Unhook("QueueStatusEntry_SetUpLFGListApplication")
			Hook:Unhook("QueueStatusEntry_SetUpLFGListActiveEntry")
			Hook:Unhook("LFGListUtil_OpenBestWindow")
		end
	end
end

function LookingForGroup.lfglist_apis(LFGList)
	if LFGList == C_LFGList or LFGList == nil then
		LFGList = {}
	end
	for k,v in pairs(C_LFGList) do
		if LFGList[k] == nil then
			LFGList[k] = v
		end
	end
	if LFGList.Util_IsEntryEmpowered == nil then
		LFGList.Util_IsEntryEmpowered = LFGListUtil_IsEntryEmpowered
	end
	if LFGList.Util_IsAppEmpowered == nil then
		LFGList.Util_IsAppEmpowered = LFGListUtil_IsAppEmpowered
	end
	if LFGList.C_PartyInfo_InviteUnit == nil then
		LFGList.C_PartyInfo_InviteUnit = C_PartyInfo.InviteUnit
	end
	return LFGList
end

function LookingForGroup.IsLookingForGroupEnabled()
	local lfggroupenabled = C_LFGList.IsLookingForGroupEnabled
	if lfggroupenabled then
		return lfggroupenabled()
	end
	if IsRestrictedAccount() then
		return false
	end
	if GetMaxLevelForLatestExpansion == nil or UnitLevel("player") < GetMaxLevelForLatestExpansion() then
		return false
	end
	return true
end
