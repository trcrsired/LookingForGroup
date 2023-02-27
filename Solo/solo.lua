local LookingForGroup = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup")
local LookingForGroup_Options = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup_Options")

function LookingForGroup_Options.hardware_solo_create(instance_leave)
	if LookingForGroup.db.profile.hardware then
		if LFGListFrame.EntryCreation.Name:GetText() == "" then
			C_LFGList.SetEntryTitle(16,0)
			local running = coroutine.running()
			local function resume()
				coroutine.resume(running,1)
			end
			local function cancel()
				coroutine.resume(running,0)
			end
			LookingForGroup.show_popup(SOLO,{cancel,LIST_GROUP,resume})
			local yd = coroutine.yield()
			if yd ~= 1 then
				return true
			end
		end
	else
		C_LFGList.SetEntryTitle(16,0)
	end
	C_LFGList.CreateListing(457,GetAverageItemLevel()-10,0,false,true)
	coroutine.wrap(LookingForGroup_Options.req_main)(1)
	if instance_leave then
		C_Timer.After(1,function()
			C_PartyInfo.LeaveParty()
		end)
	else
		if LookingForGroup_Options.db.profile.solo_convert_to_raid then
			C_Timer.After(1,C_PartyInfo.ConvertToRaid)
		end
	end
end

LookingForGroup_Options:push("solo",
{
	name = SOLO,
	type = "group",
	args =
	{
		start_a_group =
		{
			name = START_A_GROUP,
			type = "execute",
			func = function()
				if not IsInGroup() then
					coroutine.wrap(LookingForGroup_Options.hardware_solo_create)(false)
				end
			end,
			order = 1
		},
		instance_leave =
		{
			name = INSTANCE_LEAVE,
			type = "execute",
			func = function()
				if C_LFGList.HasActiveEntryInfo() and LFGListUtil_IsEntryEmpowered() then
					local info = C_LFGList.GetActiveEntryInfo()
					if info.activityID==457 and info.privateGroup then
						C_PartyInfo.LeaveParty()
					end
				elseif IsInInstance() and not IsInGroup() then
					coroutine.wrap(LookingForGroup_Options.hardware_solo_create)(true)
				end
			end,
			order = 2,
		},
		cvtr =
		{
			name = CONVERT_TO_RAID,
			type = "toggle",
			get = function()
				return LookingForGroup_Options.db.profile.solo_convert_to_raid
			end,
			set = function(info,val)
				LookingForGroup_Options.db.profile.solo_convert_to_raid = val or nil
			end,
			order = 4,
		},
	}
})
