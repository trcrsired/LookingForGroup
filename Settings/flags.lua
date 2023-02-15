local AceAddon = LibStub("AceAddon-3.0")
local LFG = AceAddon:GetAddon("LookingForGroup")
if LFG.flags == nil then
	return
end
local LFG_OPT = AceAddon:GetAddon("LookingForGroup_Options")
local L = LibStub("AceLocale-3.0"):GetLocale("LookingForGroup")

local duplicated_flags2_tb = {[0]=OTHER}
local flags2 = LFG.flags[2]
for i=1,#flags2 do
	duplicated_flags2_tb[i] = flags2[i]
end

local function generate_flags_descriptions()
	local tb = {}
	local flags_region = LFG.flags[3]
	for k,v in pairs(flags_region) do
		local tbv = tb[v]
		if tbv then
			tbv[#tbv+1] = k
		else
			tb[v] = {k}
		end
	end
	for _,v in pairs(tb) do
		table.sort(v)
	end
	local flags_name = flags2
	local concat_tb = {}
	for i=1,#flags_name do
		if i ~= 1 then
			concat_tb[#concat_tb+1] = "\n"
		end
		concat_tb[#concat_tb + 1] = flags_name[i]
		local tbv = tb[i]
		if tbv then
			concat_tb[#concat_tb + 1] = " : "
			for j=1,#tbv do
				if j~= 1 then
					concat_tb[#concat_tb + 1] = " , "
				end
				concat_tb[#concat_tb+1] = tbv[j]
			end
		end
	end
	return table.concat(concat_tb)
end

LFG_OPT:push_settings("flags",
{
	name = L.Flags,
	desc = L.flags_block_server_tootip,
	type = "group",
	args =
	{
		disable =
		{
			name = DISABLE,
			type = "toggle",
			order = 1,
			get = function()
				return LFG.db.profile.flags_disable
			end,
			set = function(_,val)
				if not val then
					val = nil
				end
				LFG.db.profile.flags_disable = val
			end,
			width = "full",
		},
		fts =
		{
			name = FILTERS,
			type = "multiselect",
			order = 2,
			values = duplicated_flags2_tb,
			set = function(_,key,val)
				local lfg_profile = LFG.db.profile
				lfg_profile.flags_has_white = nil
				if val == false then
					val = nil
				elseif val ~= true then
					val = false
				end
				local flags_tb = lfg_profile.flags
				if flags_tb == nil then
					flags_tb = {}
					lfg_profile.flags = flags_tb
				end
				flags_tb[key] = val
				if val == false then
					lfg_profile.flags_has_white = true
				else
					for _,v in pairs(flags_tb) do
						if v == false then
							lfg_profile.flags_has_white = true
							return
						end	
					end
					lfg_profile.flags_has_white = nil
				end
				if next(flags_tb) == nil then
					lfg_profile.flags = nil
					lfg_profile.flags_has_white = nil
				end
			end,
			get = function(_,key)
				local flags_tb = LFG.db.profile.flags
				if flags_tb then
					local fk = flags_tb[key]
					if fk then
						return true
					elseif fk == false then
						return
					end
				end
				return false
			end,
			tristate = true,
			width = "full",
		},
		desc =
		{
			name = generate_flags_descriptions(),
			type = "description",
			order = 3,
			fontSize = "large",
		}
	}
})
