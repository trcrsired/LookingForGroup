local LookingForGroup_Options = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup_Options")

function LookingForGroup_Options.player_armory_name(playername)
	local name,realm = strsplit("-",playername)
	if realm == nil or realm == "" then
		realm = GetNormalizedRealmName()
	end
	if GetCurrentRegion() < 4 then
		if realm ~= "AzjolNerub" then
			local sbyte = string.byte
			local i = 2
			local n = realm:len()
			while i<=n do
				local bt = sbyte(realm,i)
				if bt==39 or bt == 45 then
					realm = table.concat{realm:sub(1,i-1),realm:sub(i+1)}
					n = realm:len()
					if bt == 39 then
						i = i + 1
					end
				elseif (64<bt and bt<91) or (47<bt and bt <58) then
					realm = table.concat{realm:sub(1,i-1), '-', realm:sub(i)}
					break
				else
					i = i + 1
				end
			end
		end
	end
	return name,realm
end

local function region_name()
	local region = GetCurrentRegion()
	if region == 1 then
		return "us"
	elseif region == 2 then
		return "kr"
	elseif region == 3 then
		return "eu"
	elseif region == 4 then
		return "tw"
	elseif region == 5 then
		return "cn"
	end
end

local function battlenetarmorycommon(playername,achievements)
	local name,realm = LookingForGroup_Options.player_armory_name(playername)
	local region = GetCurrentRegion()
	local regionurlprefix
	local regionurlsuffix
	if region == 2 then
		regionurlprefix = "https://worldofwarcraft.com/ko-kr/character/"
		regionurlsuffix = "classic-kr"
	elseif region == 3 then
		regionurlprefix = "https://worldofwarcraft.com/en-gb/character/"
		regionurlsuffix = "classic-eu"
	elseif region == 4 then
		regionurlprefix = "https://worldofwarcraft.com/zh-tw/character/"
		regionurlsuffix = "classic-tw"
	elseif region == 5 then
		regionurlprefix = "http://www.battlenet.com.cn/wow/zh/character/"
		regionurlsuffix = "classic-zh"
	else
		regionurlprefix = "https://worldofwarcraft.com/en-us/character/"
		regionurlsuffix = "classic-us"
	end
	local rmtb = {regionurlprefix}
	if WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE then
		rmtb[#rmtb+1] = regionurlsuffix
	end
	rmtb[#rmtb+1] = realm
	rmtb[#rmtb+1] = "/"
	rmtb[#rmtb+1] = name
	if achievements == 1 then
		rmtb[#rmtb+1] = "/achievements/feats-of-strength/raids"
	elseif achievements == 2 then
		rmtb[#rmtb+1] = "/pve/raids"
	end
	return table.concat(rmtb)
end

LookingForGroup_Options.armory =
{
	["Battle.net"] = function(playername)
		return battlenetarmorycommon(playername)
	end,
	[_G.ACHIEVEMENTS] = function(playername)
		return battlenetarmorycommon(playername,1)
	end,
	[_G.RAID] = function(playername)
		return battlenetarmorycommon(playername,2)
	end,
	WarcraftLogs = function(playername)
		local name,realm = LookingForGroup_Options.player_armory_name(playername)
		local reg = region_name()
		local versionstr
		if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
			versionstr = "https://www.warcraftlogs.com/character/"
		else
			versionstr = "https://classic.warcraftlogs.com/character/"
		end
		if reg then
			return table.concat{versionstr,reg,"/",realm,"/",name}
		end
	end,	
	["Ask Mr. Robot"] = function(playername)
		local name,realm = LookingForGroup_Options.player_armory_name(playername)
		local reg = region_name()
		if reg then
			return "https://www.askmrrobot.com/optimizer#"..reg.."/"..realm.."/"..name
		end
	end,
	WoWProgress = function(playername)
		local name,realm = LookingForGroup_Options.player_armory_name(playername)
		local reg = region_name()
		if reg then
			return "https://www.wowprogress.com/character/"..reg.."/"..realm.."/"..name
		end
	end,
	["Raider.IO"] = function(playername)
		local name,realm = LookingForGroup_Options.player_armory_name(playername)
		local reg = region_name()
		if reg then
			return "https://raider.io/characters/"..reg.."/"..realm.."/"..name
		end
	end,
	["Murlok.io PVP"] = function(playername)
		local name,realm = LookingForGroup_Options.player_armory_name(playername)
		local reg = region_name()
		if reg then
			return table.concat{"https://murlok.io/character/",reg,"/",string.lower(realm),"/",string.lower(name),"/pvp"}
		end
	end,
	["Murlok.io PVE"] = function(playername)
		local name,realm = LookingForGroup_Options.player_armory_name(playername)
		local reg = region_name()
		if reg then
			return table.concat{"https://murlok.io/character/",reg,"/",string.lower(realm),"/",string.lower(name),"/pve"}
		end
	end,
}
