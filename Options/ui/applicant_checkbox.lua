local AceGUI = LibStub("AceGUI-3.0")
local LookingForGroup_Options = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup_Options")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")

local L = LibStub("AceLocale-3.0"):GetLocale("LookingForGroup")

local function AlignImage(self)
	local img = self.image:GetTexture()
	self.text:ClearAllPoints()
	if not img then
		self.text:SetPoint("LEFT", self.checkbg, "RIGHT")
		self.text:SetPoint("RIGHT")
	else
		self.text:SetPoint("LEFT", self.image,"RIGHT", 1, 0)
		self.text:SetPoint("RIGHT")
	end
end

local LFGListApplicanter =
{
	notCheckable = true,
}
LFGListApplicanter.__index = LFGListApplicanter

function LFGListApplicanter:new(o)
	setmetatable(o,self)
	return o
end

local function backfunc()
	if LookingForGroup_Options.option_table.args.requests then
		AceConfigDialog:SelectGroup("LookingForGroup","requests")
	end
end

local function paste(text)
	LookingForGroup_Options.Paste(text,backfunc)
end

local tank_icon = "|T337497:16:16:0:0:64:64:0:19:22:41|t"
local healer_icon = "|T337497:16:16:0:0:64:64:20:39:1:20|t"
local damager_icon = "|T337497:16:16:0:0:64:64:20:39:22:41|t"

local CLASS_COLORS = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS
local LFG_LIST_APPLICANT_MEMBER_MENU
local LFG_LIST_APPLICANT_MEMBER_MENU_LAST_API_SET

LookingForGroup_Options:RegisterMessage("UpdateArmory",function()
	LFG_LIST_APPLICANT_MEMBER_MENU_LAST_API_SET = nil
end)

local function GetApplicantMemberMenu(LFGList,applicantID, memberIdx)
	LFGListApplicanter.arg1 = applicantID
	LFGListApplicanter.arg2 = memberIdx
	if LFGList ~= LFG_LIST_APPLICANT_MEMBER_MENU_LAST_API_SET then
		local armory_menu = {}
		for k,v in pairs(LookingForGroup_Options.armory) do
			armory_menu[#armory_menu + 1] = LFGListApplicanter:new(
			{
				text = k,
				func = function(_, id,memberIdx)
					local applicantName = LFGList.GetApplicantMemberInfo(id,memberIdx)
					if applicantName then
						local armory_link = v(applicantName)
						if armory_link then
							paste(armory_link)
						end
					end
				end,
			})
		end
		table.sort(armory_menu,function(a,b)
			return a.text < b.text
		end)
		LFG_LIST_APPLICANT_MEMBER_MENU =
		{
			{
				notCheckable = true,
				disabled = true
			},
			LFGListApplicanter:new({text = WHISPER,
			func = function(_, id,memberIdx)
				local applicantName = LFGList.GetApplicantMemberInfo(id,memberIdx)
				if applicantName then
					ChatFrame_SendTell(applicantName)
				end
			end}),
			{
				text = ROLE,
				hasArrow = true,
				notCheckable = true,
				menuList =
				{
				}
			},
			{
				text = CALENDAR_COPY_EVENT,
				hasArrow = true,
				notCheckable = true,
				menuList =
				{
					LFGListApplicanter:new(
					{
						text = NAME,
						func = function(_, id, memberIdx)
							local applicantName = LFGList.GetApplicantMemberInfo(id,memberIdx)
							if applicantName then
								paste(applicantName)
							end
						end,
					}),
					LFGListApplicanter:new(
					{
						text = LFG_LIST_BAD_DESCRIPTION,
						func = function(_, id)
							paste(LFGList.GetApplicantInfo(id).comment)
						end,
					}),
				}
			},
			{
				text = L.Armory,
				hasArrow = true,
				notCheckable = true,
				menuList = armory_menu
			},
			{
				text = IGNORE,
				hasArrow = true,
				notCheckable = true,
				menuList =
				{
					LFGListApplicanter:new({text = PLAYER,func = function(_,id,memberIdx)
						local applicantName = LFGList.GetApplicantMemberInfo(id,memberIdx)
						if applicantName then
							AddIgnore(applicantName)
						end
						LFGList.DeclineApplicant(id)
					end}),
					LFGListApplicanter:new({text = FRIENDS_LIST_REALM:match("^(.*)%:") or FRIENDS_LIST_REALM:match("^(.*)%：") or FRIENDS_LIST_REALM,func = function(_,id,memberIdx)
						local applicantName = LFGList.GetApplicantMemberInfo(id,memberIdx)
						if applicantName then
							local _,realm = strsplit("-",applicantName)
							if realm then
								LookingForGroup_Options:add_realm_filter(realm)
							end
						end
						LFGList.DeclineApplicant(id)
					end}),
				}
			},
			{
				text = LFG_LIST_REPORT_FOR,
				hasArrow = true,
				notCheckable = true,
				menuList =
				{
					LFGListApplicanter:new({text = LFG_LIST_REPORT_PLAYER,func = function(_,id,memberIdx) LFGList_ReportApplicant(id,LFGList.GetApplicantMemberInfo(id,memberIdx)); end}),
				}
			},
			{
				text = CANCEL,
				notCheckable = true,
			},
		}
	end
	local name, class, localizedClass, level, itemLevel, honorLevel, tank, healer, damage, assignedRole, relationship = LFGList.GetApplicantMemberInfo(applicantID,memberIdx)
	LFG_LIST_APPLICANT_MEMBER_MENU[1].text = table.concat{"|c",CLASS_COLORS[class].colorStr,name,"|r"}
	local roleMenuList = LFG_LIST_APPLICANT_MEMBER_MENU[3].menuList
	wipe(roleMenuList)
	if tank then
		roleMenuList[#roleMenuList + 1] = LFGListApplicanter:new(
		{
			text = tank_icon..TANK,
			func = function(_, id, memberIdx)
				LFGList.SetApplicantMemberRole(id,memberIdx,"TANK")
			end,
		})
	end
	if healer then
		roleMenuList[#roleMenuList + 1] = LFGListApplicanter:new(
		{
			text = healer_icon..HEALER,
			func = function(_, id, memberIdx)
				LFGList.SetApplicantMemberRole(id,memberIdx,"HEALER")
			end,
		})
	end
	if damage then
		roleMenuList[#roleMenuList + 1] = LFGListApplicanter:new(
		{
			text = damager_icon..DAMAGER,
			func = function(_, id, memberIdx)
				LFGList.SetApplicantMemberRole(id,memberIdx,"DAMAGER")
			end,
		})
	end
	return LFG_LIST_APPLICANT_MEMBER_MENU
end

local max_lvl = GetMaxPlayerLevel()
local concat_tb = {}

function LookingForGroup_Options.tooltip_show_dungeonscore_info(DungeonScoreInfo)
	if DungeonScoreInfo then
		if DungeonScoreInfo.mapName then
			if DungeonScoreInfo.mapName:len() ~=0 then
				if(DungeonScoreInfo.mapScore == 0) then
					GameTooltip:AddDoubleLine(DUNGEON_SCORE_PER_DUNGEON_NO_RATING:format(DungeonScoreInfo.mapName, DungeonScoreInfo.mapScore));
				elseif (DungeonScoreInfo.finishedSuccess) then 
					GameTooltip:AddDoubleLine(DUNGEON_SCORE_DUNGEON_RATING:format(DungeonScoreInfo.mapName, DungeonScoreInfo.mapScore, DungeonScoreInfo.bestRunLevel));
				else 
					GameTooltip:AddDoubleLine(DUNGEON_SCORE_DUNGEON_RATING_OVERTIME:format(DungeonScoreInfo.mapName, DungeonScoreInfo.mapScore, DungeonScoreInfo.bestRunLevel));
				end
			end
		end
	end
end

function LookingForGroup_Options.tooltip_show_pvp_rating_info(pvpRatingForEntry)
	if pvpRatingForEntry then
		local tier = pvpRatingForEntry.tier
		GameTooltip_AddNormalLine(GameTooltip, PVP_RATING_GROUP_FINDER:format(pvpRatingForEntry.activityName, pvpRatingForEntry.rating,
		string.format("|cff8080cc%d|r[%s]",tier,PVPUtil.GetTierName(tier))))
	end
end

local player_faction_group = LookingForGroup_Options.player_faction_group
local player_faction_colored_strings = LookingForGroup_Options.player_faction_colored_strings
local C_CreatureInfo_GetRaceInfo = C_CreatureInfo.GetRaceInfo
local PlayerUtil_GetSpecNameBySpecID = PlayerUtil.GetSpecNameBySpecID

local function member_info(LFGList,id,i)
	local name, class, localizedClass, level, itemLevel, honorLevel, tank, healer, damage, assignedRole, relationship, dungeonScore, pvpItemLevel, factionGroup, raceID, specID = LFGList.GetApplicantMemberInfo(id,i)
	if i ~= 1 then
		concat_tb[#concat_tb+1] = "\n"
	end
	if assignedRole == "DAMAGER" then
		concat_tb[#concat_tb+1] = damager_icon
	elseif assignedRole == "HEALER" then
		concat_tb[#concat_tb+1] = healer_icon
	elseif assignedRole == "TANK" then
		concat_tb[#concat_tb+1] = tank_icon
	end
	if level ~= max_lvl then
		concat_tb[#concat_tb+1] = LEVEL_ABBR
		concat_tb[#concat_tb+1] = ":"
		concat_tb[#concat_tb+1] = level
		concat_tb[#concat_tb+1] = " "
	end
	concat_tb[#concat_tb+1] = math.floor(itemLevel)
	if pvpItemLevel ~= 0 and pvpItemLevel ~= itemLevel then
		concat_tb[#concat_tb+1] = "(PvP:"
		concat_tb[#concat_tb+1] = math.floor(pvpItemLevel)
		concat_tb[#concat_tb+1] = ")"
	end
	concat_tb[#concat_tb+1] = " |c"
	concat_tb[#concat_tb+1] = CLASS_COLORS[class].colorStr
	concat_tb[#concat_tb+1] = name
	local flag = LookingForGroup_Options.execute_flags(name)
	if flag then
		concat_tb[#concat_tb + 1] = flag
	end
	if raceID then
		local raceinfo = C_CreatureInfo_GetRaceInfo(raceID)
		concat_tb[#concat_tb+1] = " "
		concat_tb[#concat_tb+1] = raceinfo.clientFileString
	end
	if specID then
		local specName = PlayerUtil_GetSpecNameBySpecID(specID)
		concat_tb[#concat_tb+1] = " "
		concat_tb[#concat_tb+1] = specName
	end
	concat_tb[#concat_tb+1] = " "
	concat_tb[#concat_tb+1] = localizedClass
	concat_tb[#concat_tb+1] = "|r"
	if factionGroup and player_faction_group[factionGroup] ~= UnitFactionGroup("player") then
		concat_tb[#concat_tb+1] = " "
		concat_tb[#concat_tb+1] = player_faction_colored_strings[factionGroup]
	end
	if dungeonScore ~= 0 then
		concat_tb[#concat_tb+1] = " DS:"
		concat_tb[#concat_tb+1] = dungeonScore
	end
	local roles = 0
	if tank then
		roles = roles + 1
	end
	if healer then
		roles = roles + 1
	end
	if damage then
		roles = roles + 1
	end
	if 1< roles then
		concat_tb[#concat_tb+1] = " "
		if tank then
			concat_tb[#concat_tb+1] = tank_icon
		end
		if healer then
			concat_tb[#concat_tb+1] = healer_icon
		end
		if damage then
			concat_tb[#concat_tb+1] = damager_icon
		end
	end
	if relationship ~= nil then
		concat_tb[#concat_tb+1] = " "
		concat_tb[#concat_tb+1] = relationship
	end
--[[
	local brief = LookingForGroup_Options.lfgscoresbrief
	if brief then
		for j=1,#brief do
			concat_tb[#concat_tb+1] = brief[j](name,2)
		end
	end]]
end

function LookingForGroup_Options.updateapplicant(obj)
	local users = obj:GetUserDataTable()
	local info = users.applicantInfo
	if not info then
		return
	end
	local id = info.applicantID
	local comment = info.comment
	local numMembers = info.numMembers
	obj.text:SetText(comment)
	obj.text:SetTextColor(1,0.82,0)
	wipe(concat_tb)
	for i=1,numMembers do
		member_info(info.LFGList,id,i)
	end
	if numMembers == 1 and comment == "" then
		obj.text:SetText(table.concat(concat_tb))	
	else
		obj:SetDescription(table.concat(concat_tb))
	end
end

function LookingForGroup_Options:applicants_tooltip()
	local lfg_applicant_scores = LookingForGroup_Options.lfg_applicant_scores
	if lfg_applicant_scores then
		local owner = GameTooltip:GetOwner()
		if owner == nil then
			return
		end
		local obj = owner.obj
		local users = obj:GetUserDataTable()
		local info = users.applicantInfo
		GameTooltip:ClearLines()
		local status
		for i=1,#lfg_applicant_scores do
			if lfg_applicant_scores[i](info) then
				status = true
			end
		end
		if status then
			GameTooltip:Show()
		end
	end
end

local function on_enter(self)
	GameTooltip:SetOwner(self,"ANCHOR_TOPRIGHT")
	local onenter = self:GetScript("OnEnter")
	self:SetScript("OnEnter", nop)
	local onleave = self:GetScript("OnLeave")
	self:SetScript("OnLeave",function(self)
		self:SetScript("OnEnter",onenter)
		self:SetScript("OnLeave",onleave)
		GameTooltip:Hide()
	end)
	local users = self.obj:GetUserDataTable()
	local applicantInfo = users.applicantInfo
	local val = applicantInfo.applicantID
	GameTooltip:ClearLines()
	GameTooltip:AddDoubleLine(ID,val,nil,nil,nil,0.5,0.5,0.8)
	local entry = applicantInfo.activeEntryInfo
	local activityID = entry.activityID
	local LFGList = applicantInfo.LFGList
	local GetApplicantDungeonScoreForListing = LFGList.GetApplicantDungeonScoreForListing
	local tooltip_show_dungeonscore_info = LookingForGroup_Options.tooltip_show_dungeonscore_info
	local GetApplicantPvpRatingInfoForListing = LFGList.GetApplicantPvpRatingInfoForListing
	local tooltip_show_pvp_rating_info = LookingForGroup_Options.tooltip_show_pvp_rating_info
	local GetApplicantMemberInfo = LFGList.GetApplicantMemberInfo

	local tb
	local applicant_tooltips = LookingForGroup_Options.applicant_tooltips
	if applicant_tooltips then
		local profile = LookingForGroup_Options.db.profile
		for i=1,#applicant_tooltips do
			local f = applicant_tooltips[i](val,entry,profile)
			if f then
				if tb then
					tb[#tb+1] = f
				else
					tb = {f}
				end
			end
		end
	end
	for i=1,applicantInfo.numMembers do
		local name, class, localizedClass, level, itemLevel, honorLevel, tank, healer, damage, assignedRole, relationship, dunegeonScore, pvpItemLevel, factionGroup, raceID, specID =
		GetApplicantMemberInfo(val,i)
		local color = CLASS_COLORS[class]
		GameTooltip:AddDoubleLine(name,i,color.r,color.g,color.b,0.5,0.5,0.8)
		tooltip_show_dungeonscore_info(GetApplicantDungeonScoreForListing(val,i,activityID))
		tooltip_show_pvp_rating_info(GetApplicantPvpRatingInfoForListing(val,i,activityID))
		if tb then
			for j=1,#tb do
				tb[j](val, i, name, class, localizedClass, level, itemLevel, honorLevel, tank, healer, damage, assignedRole, relationship, dunegeonScore, pvpItemLevel, factionGroup, raceID, specID)
			end
		end
	end
	GameTooltip:Show()
end

AceGUI:RegisterWidgetType("LookingForGroup_applicant_checkbox", function()
	local check = AceGUI:Create("CheckBox")
	local frame = check.frame
	frame:RegisterForClicks("LeftButtonDown","RightButtonDown")

	frame:SetScript("OnMouseUp",function(self,button)
		local obj = self.obj
		local user = obj:GetUserDataTable()
		if button == "LeftButton" then
			if not obj.disabled then
--				obj:ToggleChecked()
				if obj.checked then
					PlaySound(856)
				else -- for both nil and false (tristate)
					PlaySound(857)
				end
				obj:Fire("OnValueChanged", obj.checked)
				AlignImage(obj)
			end
		else
			local info = user.applicantInfo
			local numMembers = info.numMembers
			if numMembers == 1 then
				EasyMenu(GetApplicantMemberMenu(info.LFGList,info.applicantID,1), LFGListFrameDropDown, "cursor" , 0, 0, "MENU")
			else
				local cursor_x,cursor_y = GetCursorPosition()
				local desc = obj.desc
				local pos = math.floor((desc:GetTop()-cursor_y/UIParent:GetEffectiveScale()) / desc:GetHeight() * numMembers + 1)
				if pos < 1 then
					pos = 1
				end
				if numMembers < pos then
					pos = numMembers
				end
				EasyMenu(GetApplicantMemberMenu(info.LFGList,info.applicantID,pos), LFGListFrameDropDown, "cursor" , 0, 0, "MENU")
			end
		end
	end)
	check.updateapplicant = LookingForGroup_Options.updateapplicant
	frame:SetScript("OnEnter", on_enter)
	function check:OnAcquire()
		self:SetType()
		self:SetValue(false)
		self:SetTriState(nil)
		-- height is calculated from the width and required space for the description
		self:SetWidth(200)
		self:SetImage()
		self:SetDisabled(false)
		self:SetDescription(nil)
		self.width = "fill"
	end
	check.type = "LookingForGroup_applicant_checkbox"
	return AceGUI:RegisterAsWidget(check)
end, 1)
