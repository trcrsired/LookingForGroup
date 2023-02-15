local LFG = LibStub("AceAddon-3.0"):GetAddon("LookingForGroup")
local languages =
{
"brazilian",
"chinese",
"mexican",
"oceanic",
}

local flags = {}

for i=1,#languages do
	flags[i] = "|TInterface\\AddOns\\LookingForGroup_Flags_US\\textures\\"..languages[i]..":0|t"
end

local realms =
{
["Frostmourne"] = 4,
["Nagrand"] = 4,
["Caelestrasz"] = 4,
["Dreadmaul"] = 4,
["Saurfang"] = 4,
["Dath'Remar"] = 4,
["Thaurissan"] = 4,
["Khaz'goroth"] = 4,
["Barthilas"] = 4,
["Gundrak"] = 4,
["Aman'Thul"] = 4,
["Jubei'Thos"] = 4,

["TolBarad"] = 1,
["Nemesis"] = 1,
["Goldrinn"] = 1,
["Gallywix"] = 1,
["Azralon"] = 1,

["Ragnaros"] = 3,
["Quel'Thalas"] = 3,
["Drakkari"] = 3,

["Illidan"] = 2
}

LFG.flags={languages,flags,realms}
