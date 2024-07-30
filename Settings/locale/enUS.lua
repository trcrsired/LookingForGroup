local L = LibStub("AceLocale-3.0"):NewLocale("LookingForGroup", "enUS", true)

L["Abandon Tutorial Area"] = true
L["armor_desc"] = "Groups that comprise a minimum of 40% of classes match your armor type."
L["Armory"] = true
L["Auto"] = true
L["auto_disable_desc"] = "Preventing quests, invasion points, elites, and other types of LFG auto groups from appearing automatically. There's no need to disable this because LFG will automatically close static popups when you leave those areas."
L["auto_leave_party_desc"] = [=[Normal Click = Automatically leave the party upon quest completion.
Dark Click = Never automatically leave the party, even if the player is flying.
No Click = Automatically leave the party only when the player is flying.]=]
L["auto_no_info_quest"] = "Block No Info Quest"
L["auto_no_info_quest_desc"] = "Prevent quests that cannot retrieve information from the API. Enabling this option may block many bothersome quests, but it could also block meaningful ones."
L["auto_report"] = "Auto Report"
L["auto_report_desc"] = "Automatically report groups engaging in spamming within the LFG system."
L["auto_wq_only_desc"] = "%s Only"
L["Backfill"] = true
L["background_search"] = "Background Search"
L["bwlist_desc"] = [=[Normal Click = %s Blacklist
Dark Click = %s Whitelist
No Click = %s]=]
L["cr_realm_rand_hop"] = "Random Hop"
L["cr_realm_rand_hop_desc"] = "Hop to a random realm. You can achieve this by pressing Ctrl and right-clicking the minimap icon. Alternatively, you can use the following macro: /lfg cr rand_hop. Another option is to bind this action to a key in the ESC-Key Bindings-AddOns-LookingForGroup-Random Hop menu."
L["cr_realm_scan"] = "Scan Your Realm"
L["cr_realm_scan_desc"] = "Initiating a scan of your present realm. You can also perform this action by right-clicking on the minimap icon. Additionally, you have the option to bind this function to a key in the ESC-Key Bindings-AddOns-LookingForGroup-Scan Your Realm menu."
L["Cross Realm"] = true
L["digits_desc"] = "Spammers often include numerous numbers in their descriptions. This option manages the maximum allowable quantity of numbers in a description."
L["Diverse"] = true
L["diverse_desc"] = "Groups with diverse classes"
L["Fast"] = true
L["Fast_desc"] = "On average, the quickest role matching is for group formation."
L["find_f_advanced_class"] = "Groups have >= 2 your class"
L["find_f_advanced_complete"] = "Groups with a minimum of 2/3 participants engaged in that activity."
L["find_f_advanced_gold"] = "Searching for WTS (Want To Sell) or RMT (Real Money Trade) Groups."
L["find_f_advanced_role"] = "Filter groups based on your role. For instance, if you are a healer, you won't encounter dungeon groups with another healer in the search results."
L["find_f_encounters"] = [=[Normal Click = This boss must be defeated
Dark Click = This boss must not be defeated
No Click = Do not care whether this boss is defeated or not.]=]
L["find_recommended_desc"] = [=[Normal Click = Display recommended activities only
Dark Click = Display other activities
No Click = Display all activities]=]
L["Flags"] = true
L["flags_block_server_tootip"] = "Flags can assist in blocking servers, encompassing both chat and LFG. For instance, you can block or exclusively allow Oceanic servers to address lag problems in the US region. (Please note that this option is not applicable to your server.)"
L["hyperlinks_desc"] = "Spam messages typically contain numerous hyperlinks in their descriptions. This option regulates the maximum number of hyperlinks allowed in a description."
L["Keywords"] = true
L["language_sf_desc"] = "An advanced feature of the AddOn BlockChinese. It can block not only Chinese and Korean languages but also other languages."
L["max_length_desc"] = "Spam messages are usually quite lengthy. This option imposes a maximum text length limit on LFG group descriptions."
L["Maximum Text Length"] = true
L["must_input_title"] = "You must input %s before you %s"
L["must_select_xxx"] = "You must select a(n) %s before you %s"
L["options_advanced_complete"] = "When activated, copying a group name or description will not merely filter spam but rather remove it entirely."
L["options_advanced_hardware"] = "Enable a protected mode for LFG operation, automatically activated when necessary."
L["options_advanced_mute"] = "When enabled, no sounds will be played, and the minimap icon will not emit any light."
L["options_advanced_role_check"] = "When activated, you will be prompted to confirm your role and comment before submitting each application. Alternatively, you can adjust the default application settings in the |cffff2020%s|r option page if this option is disabled."
L["options_auto_fnd_desc"] = [=[Normal Click = Manually choose to find or create a group
No click = Auto find or create a group]=]
L["options_auto_start_desc"] = [=[Normal Click = ALWAYS create a group
Dark Click = NEVER create a group
No click = Create a group if there are no relative groups]=]
L["options_sort_shuffle_desc"] = "The search results will be shuffled, overriding other sorting options."
L["options_window"] = "Window Size"
L["rand_rare"] = "Random Rare"
L["rand_rare_desc"] = "Hop to a random realm for rare encounters. You can achieve this by holding Shift and right-clicking the minimap icon. Alternatively, use the following macro: /lfg cr rand_rare. You also have the option to assign this action to a key binding in the ESC-Key Bindings-AddOns-LookingForGroup-Random Rare menu."
L["ratedbg_bot_desc"] = [=[In the Chinese region, you can obtain a free boost in Rated Battlegrounds by simply going AFK and facing off against bots. This Rated BG Bot mode automatically filters out players with a rating above 1000 or insufficient item levels.

Here's how it works: After entering the Battleground, check your PvP rating. If it's above 800, go AFK and allow the opposing faction to win. Once your rating drops below 800, participate in the next match. You'll notice that your opponents are bots, and they will initiate the process.

It's advisable to avoid queuing for this mode between 12:00 and 21:00 daily, as more human players are active during that time, reducing the likelihood of encountering bots.]=]
L["ratedbg_bots"] = "Rated BG Bots"
L["Relist"] = true
L["sf_add_desc"] = "Please input your filter keywords here. This filter is specifically designed for the chat channel. Please note that, due to Blizzard's API restrictions in version 8.0, this filter only applies to filtering the leader's name and does not affect the LFG group's title, comment, or voice chat."
L["sf_dk_desc"] = "Spammers frequently employ a large number of level 55 Death Knights to form LFG groups. This option is highly effective and successfully eliminates more than 80% of LFG spamming in the Chinese Region."
L["sf_ilvl"] = "Many spammers establish groups with unusual item level (iLvl) requirements."
L["sf_invite_relationship_desc"] = "This setting permits only individuals with a recognized relationship to invite you."
L["sf_language_lfg"] = "Extend the Language Blocker to encompass not only chat but also LFG."
L["sf_player_name_desc"] = "Implement spam filters for player names."
L["sf_solo"] = "Spammers frequently form LFG groups using a single character for advertising purposes. Activating this option will eliminate all LFG groups consisting of only one character."
L["sf_whisper_desc"] = "Many AddOns, such as WQGF and WQA, persistently spam chat to promote themselves. Additionally, numerous Chinese users utilize AddOn packages that flood chat with lengthy spam messages. Enabling this option will counter these AddOns by sending notifications to spammers, encouraging them to discontinue their activities."
L["solo_hint"] = "Please input something into the %s edit box before you click %s button."
L["Taskbar Flash"] = true
L["unique_desc"] = "Groups that do not include your class and role."
L["warning_not_working"] = "Warning! Enabling this option may result in LFG not functioning correctly."

