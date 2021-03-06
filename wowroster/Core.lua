
wowroster = LibStub("AceAddon-3.0"):NewAddon("wowroster", "AceConsole-3.0", "AceEvent-3.0")
local acr = LibStub("AceConfigRegistry-3.0")
local state = {};
local acd = LibStub("AceConfigDialog-3.0")
local ac = LibStub("AceConfig-3.0")
local f = CreateFrame('GameTooltip', 'MyTooltip', UIParent, 'GameTooltipTemplate')


if(not wowroster.colorTitle) then wowroster.colorTitle="909090"; end
if(not wowroster.colorGreen) then wowroster.colorGreen="00cc00"; end
if(not wowroster.colorRed)   then wowroster.colorRed  ="ff0000"; end

local scan_numtradeskills=0;
local scan_nextskill=0;
local scan_reagentcount=0;
local scan_tradename=nil;
local scan_cache=true;

wowroster.betar = "1.0.0 r77";



local LDB = LibStub("LibDataBroker-1.1", true)
local LDBIcon = LibStub("LibDBIcon-1.0", true)

local L_BT_LEFT = "|cffffff00Click|r to save character";
local L_BT_SLEFT = "|cffffff00Shift Click|r to open Options";
local L_BT_RIGHT = "|cffffff00Right-click|r to save guild";

local wowrgpLDB = LibStub("LibDataBroker-1.1"):NewDataObject("wowrostermm", {
	type = "launcher",
	label = "WoWRoster Profiler",
	OnClick = function(_, msg, down)
	
		if msg == "LeftButton" and IsShiftKeyDown() then
			InterfaceOptionsFrame_OpenToCategory("WoWRoster Profiler")
			
		elseif msg == "LeftButton" then
			wowroster:export();
		elseif msg == "RightButton" then
			wowrostergp:gpexport();
		end
		
		--wroptions - InterfaceOptionsFrame_OpenToCategory("WoWRoster Profiler")
	end,
	icon = "Interface\\Icons\\ACHIEVEMENT_GUILDPERK_EVERYONES A HERO_RANK2",
	OnTooltipShow = function(tooltip)
		if not tooltip or not tooltip.AddLine then return end
		tooltip:AddLine("WoWRoster Profiler")
		tooltip:AddLine(L_BT_LEFT)
		tooltip:AddLine(L_BT_SLEFT)
		tooltip:AddLine(L_BT_RIGHT)
	end,
})

local wricon = LibStub("LibDBIcon-1.0")




wowroster.class = {WARRIOR=1,PALADIN=2,HUNTER=3,ROGUE=4,PRIEST=5,DEATHKNIGHT=6,SHAMAN=7,MAGE=8,WARLOCK=9,DRUID=11};
wowroster.race = {Human=1,Orc=2,Dwarf=3,NightElf=4,Scourge=5,Tauren=6,Gnome=7,Troll=8,BloodElf=10,Draenei=11,Worgen=22};
wowroster.tooltip = "wowrcptooltip";


--[UnitClass] arg1:unit
wowroster.UnitSex = function(arg1)
	local UnitSexLabel={UNKNOWN,MALE,FEMALE};
	local unitSexID=UnitSex(arg1);
	return UnitSexLabel[unitSexID],mod(unitSexID,2);
end

--[UnitClass] arg1:unit
wowroster.UnitClass = function(arg1)
	local unitClass,unitClassEn=UnitClass(arg1);
	return unitClass,unitClassEn,wowroster.class[unitClassEn];
end

--[UnitClassID] arg1:unit
wowroster.UnitClassID = function(classEn)
	return wowroster.class[classEn];
end

--[UnitRace] arg1:unit
wowroster.UnitRace = function(arg1)
	local unitRace,unitRaceEn=UnitRace(arg1);
	return unitRace,unitRaceEn,wowroster.race[unitRaceEn];
end

local stat = {
	_loaded=nil,_lock=nil,_bag=nil,_bank=nil,_mail=nil,
	_server=GetRealmName(),_player=UnitName("player"),_class=class,
	_skills={},
	Equipment=0,
	Guild=nil, GuildNum=nil,
	Skills=0, Glyphs=0,
	Talents={},DSTalents={},TalentPts=0,
	Reputation=0,
	Quests=0, QuestsLog=0,
	Mail=nil,
	Honor=nil,
	Bag={},Inventory={},Bank={},
	Professions={}, SpellBook={},
	Pets={}, Stable={}, PetSpell={}, PetTalent={},
	Companions={},
	Achi={},
};

local defaults={
	profile={
		["enabled"]=true,
		["verbose"]=false,
		["reagentfull"]=true,
		["talentsfull"]=true,
		["questsfull"]=false,
		["debug"]=false,
		["ver"]=031000,
		["scan"]={
			["inventory"]=true,
			["currency"]=true,
			["talents"]=true,
			["honor"]=true,
			["reputation"]=true,
			["spells"]=true,
			["pet"]=true,
			["companions"]=true,
			["equipment"]=true,
			["mail"]=true,
			["professions"]=true,
			["quests"]=true,
			["bank"]=true,
			["glyphs"]=true,
			["dstalents"] = true,
			["dsglyphs"] = true,
			["dsspells"] = true,
		},
		["guild"]={
			["compact"]=true,
			["title"]=true,
			["vault"]=true,
			["vault_log"]=true,
			["vault_money"]=true,
			["trades"]=true,
		},
	},
};

local mmdefaults = {
	profile = {
		tooltip = "enabled",
		minimap = {
			hide = false,
			minimapPos = 225.6416264355972,
		},
		
	}
}

local UnitPower={"Rage","Focus","Energy","Happiness","Runes","RunicPower"};UnitPower[0]="Mana";
local UnitSlots={"Head","Neck","Shoulder","Shirt","Chest","Waist","Legs","Feet","Wrist","Hands","Finger0","Finger1","Trinket0","Trinket1","Back","MainHand","SecondaryHand","Ranged","Tabard"};
local UnitStatName={"Strength","Agility","Stamina","Intellect","Spirit"};
local UnitSchoolName={"Physical","Holy","Fire","Nature","Frost","Shadow","Arcane"};
local UnitResistanceName={"Holy","Fire","Nature","Frost","Shadow","Arcane"};

local function findPanel(name, parent)
	for i, button in next, InterfaceOptionsFrameAddOns.buttons do
		if button.element then
			if name and button.element.name == name then return button
			elseif parent and button.element.parent == parent then return button
			end
		end
	end
end

function wowroster:OnEnable()
	-- Called when the addon is enabled
	self:RegisterEvent("TRADE_SKILL_SHOW")
	self:RegisterEvent("BANKFRAME_OPENED")
	self:RegisterEvent("BANKFRAME_CLOSED")
	self:RegisterEvent("ARCHAEOLOGY_TOGGLE");
	self.buttons = {}

	local button = CreateFrame("Button", "GuildProfilerButton", PaperDollFrame, "UIPanelButtonTemplate")
	button.tooltip = "Save player data"--L["Click to export your Guild Profile!"]
	button.startTooltip = button.tooltip
	button:SetPoint("TOPRIGHT", PaperDollFrame, "TOPRIGHT", -30, 0)
	button:SetWidth(55)
	button:SetHeight(22)
	button:SetText("Save") --L["save"])
	button:SetScript("OnEnter", showTooltip)
	button:SetScript("OnLeave", hideTooltip)
	button:SetScript("OnClick", function(self)
		wowroster:export()
		end
	)

	self.buttons.save = button
	
	if (not self.mm.profile.minimap["hide"]) then
		wricon:Hide("WoWRoster Profiler")
	else
		wricon:Show("WoWRoster Profiler")
	end
						
	wowroster:Print("Hello, WoWRoster Profiler Enabled and Loaded |cffff3399["..wowroster.betar.."]|r");
	wowroster:Print("Open the menu, click Interface, then go to the Addons tab to configure");

	wowroster:RegisterChatCommand("wrcp", "WOWRP_ChatCommandHandler");
	wowroster:RegisterChatCommand("wr", "ChatCommand")
	wowroster:RegisterChatCommand("wroptions", "ChatCommand")
	--icon:Load();
end



function wowroster:WOWRP_ChatCommandHandler(argline)
	--wowroster:Print("purge "..argline.." ");
	local msg = wowroster.Str2Ary(argline);
	--wowroster:Print("purge "..msg[1].." "..msg[2].."");
	local server = GetRealmName();

	if ( msg[1] == "" or msg[1] == "help") then
		wowroster:Print("Purge commands for character data.");
		wowroster:Print("NOTE: The first two commands will only work on your current server, except 'purge all' which will purge all data");
		wowroster:Print("/wrcp purge char <CHARNAME> - Purges <CHARNAME>");
		wowroster:Print("/wrcp purge server - Purges all data for this server");
		wowroster:Print("/wrcp purge all - This will purge |cffff0000ALL|r data");

		return;
	end
--wowroster:Achi()
	if (msg[1] == "achi") then
		wowroster:Achi();
		return;
	end
	if (msg[1] == "purge") then
		if ( msg[2] == "all" ) then
			cpProfile=nil;
			wowroster:Print("All Data Purged!");--cpProfile=nil;
			return;
		end
		if ( msg[2] == "char" ) then
			if(cpProfile[server] and cpProfile[server]["Character"] and cpProfile[server]["Character"][msg[3]]) then
				cpProfile[server]["Character"][msg[3]]=nil;
				isPurged=true;
				wowroster:Print("Player "..msg[3].."@"..server.." purged");
			end
			return;
		end
		if ( msg[2] == "server" ) then
			if(cpPofile[stat["_server"]] and cpProfile[stat["_server"]]["Character"]) then
				cpProfile[stat["_server"]]["Character"]=nil;
				isPurged=true;
				wowroster:Print("Server "..stat["_server"].." purged");
			end
			return;
		end
		if ( msg[2] == "guild" ) then
			profile=msg[3] or GetGuildInfo("player") or "";
			if(myProfile[server] and myProfile[server]["Guild"] and myProfile[server]["Guild"][profile]) then
				cpProfile[server]["Guild"][profile]=nil;
				isPurged=true;
				wowroster:Print("Guild "..profile.."@"..stat["_server"].." purged");
			end
			return;
		end
	end
end

wowroster.Str2Ary = function(str)
	local tab={};
	str = strtrim(str);
	while( str and str ~="" ) do
		local word,string;
		if( strfind(str, '^|c.+|r') ) then
			_,_,word,string = strfind( str, '^(|c.+|r)(.*)');
		elseif( strfind(str, '^"[^"]+"') ) then
			_,_,word,string = strfind( str, '^"([^"]+)"(.*)');
		else
			_,_,word,string = strfind( str, '^(%S+)(.*)');
		end
		if( word ) then
			table.insert(tab,word);
		end
		if( string ) then
			string=strtrim(string);
		end
		str = string;
	end
	return tab;
end

function wowroster:OnDisable()
	wowrpref = wowrpref;
	LibStub("AceDB-3.0"):New("wowrpref",wowrpref)
	LibStub("AceDB-3.0"):New("cpProfile",self.db)
	LibStub("AceDB-3.0"):New("cpminimap",wowroster.mm)
	if ( IsAddOnLoaded("WoWRoster Guild Profiler") ) then
		LibStub("AceDB-3.0"):New("cpProfile",wowrostergp.sv)
	end
end

function wowroster:OnInitialize()
	wowrpref = LibStub("AceDB-3.0"):New("wowrpref")

	if(not wowrpref["enabled"]) then
		wowrpref = defaults.profile;
		wowrpref = wowrpref;
		wowroster:Print("Defaults loaded, verson ".. wowrpref["ver"])
	end
	self.db = LibStub("AceDB-3.0"):New("cpProfile");
	--self.profileOptions = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)

	local function profileUpdate()
		wowroster:SendMessage("scan updated")
	end
	if (not cpminimap) then
		self.mm = LibStub("AceDB-3.0"):New("cpminimap", mmdefaults, true);
	else
		self.mm = LibStub("AceDB-3.0"):New("cpminimap");
	end
	
	if (not self.mm.profile.minimap) then
		self.mm = LibStub("AceDB-3.0"):New("cpminimap", mmdefaults, true);
	end
	
	
	wricon:Register("WoWRoster Profiler", wowrgpLDB, self.mm.profile.minimap)
	
	--MinimapIcon:OnEnable();

	self.tooltip = CreateFrame("GameTooltip",self.tooltip,UIParent,"GameTooltipTemplate");
	self.tooltip:SetOwner(UIParent,"ANCHOR_NONE");
	self.db.RegisterCallback(self, "OnProfileChanged", profileUpdate)
	self.db.RegisterCallback(self, "OnProfileCopied", profileUpdate)
	self.db.RegisterCallback(self, "OnProfileReset", profileUpdate)
	wowroster:InitState()
	wowroster:InitProfile()
	--self.db = db
	wowroster:makeconfig()
	wowroster:UpdateDate()
end

function wowroster:UpdateDate()
	if(not wowroster.db) then return; end;
	local struct=wowroster.db;
	if ( not struct["timestamp"] ) then struct["timestamp"]={}; end
	local timestamp = time();
	local currHour,currMinute=GetGameTime();
	struct["timestamp"]["init"]={};
	struct["timestamp"]["init"]["TimeStamp"]=timestamp;
	struct["timestamp"]["init"]["Date"]=date("%Y-%m-%d %H:%M:%S",timestamp);
	struct["timestamp"]["init"]["DateUTC"]=date("!%Y-%m-%d %H:%M:%S",timestamp);
	struct["timestamp"]["init"]["ServerTime"]=format("%02d:%02d",currHour,currMinute);
	struct["timestamp"]["init"]["datakey"]=wowroster.versionkey();
	struct["timestamp"]["SpellBook"]={};
end

--[[
this function is fired when the paperdoll frame button is pressed
]]--
function wowroster:export()
	wowroster:Print("Save button call");
	wowroster:UpdateDate();
	wowroster:GetSpellBook();
	wowroster:GetInventory();
	wowroster:GetBuffs(wowroster.db);
	wowroster:GetEquipment();
	wowroster:GetTalents();

	wowroster:ScanCurrency();
	wowroster:SKILLS();
	wowroster:ScanGlyphs();
	wowroster:GetReputation();
	wowroster:GetQuests();
	wowroster:GetHonor();
	wowroster:GetArena();
	wowroster:ScanCompanions();
	
	wowroster:ScanPetInfo();

	wowroster:Show();
end

function wowroster:Show()
	msg = "Equipment:"..stat["Equipment"].."/"..table.getn(UnitSlots).." ";	
	wowroster:Print(msg);
	msg="";

	msg = "Skills:";
	tsort={};
	table.foreach(stat["Professions"], function (k,v) table.insert(tsort,k) end );
	table.sort(tsort);
	if(table.getn(tsort)==0) then
		msg=msg..wowroster.StringColorize(wowroster.colorRed," not scanned")..".  - open each profession to scan";
	else
		for _,item in pairs(tsort) do
			msg=msg .. " " .. item..":"..stat["Professions"][item]["ct"].." errors("..stat["Professions"][item]["errors"]..")";
		end
	end
	wowroster:Print(msg);
	msg="";

	msg = "Spells:";
		tsort={};
		table.foreach(stat["SpellBook"], function(k,v) table.insert(tsort,k) end );
		table.sort(tsort);
		if(table.getn(tsort)==0) then
			msg=msg..wowroster.StringColorize(wowroster.colorRed," not scanned")..".  - open your spellbook to scan";
		else
			for _,item in pairs(tsort) do
				msg=msg .. " " .. item..":"..stat["SpellBook"][item];
			end
		end
	wowroster:Print(msg);
	msg="";

	msg = "Inventory:";
		tsort={};
		table.foreach(stat["Inventory"], function(k,v) table.insert(tsort,k) end );
		table.sort(tsort);
		if(table.getn(tsort)==0) then
			msg=msg..wowroster.StringColorize(wowroster.colorRed," not scanned")..".  - open your bank or 'character info' to scan";
		else
			for _,item in pairs(tsort) do
				msg=msg .. " " .. item.."]"..stat["Inventory"][item]["inv"].."/"..stat["Inventory"][item]["slot"];
			end
		end
	wowroster:Print(msg);
	msg="";

	msg = "Bank:";
		tsort={};
		table.foreach(stat["Bank"], function(k,v) table.insert(tsort,k) end );
		table.sort(tsort);
		if(table.getn(tsort)==0) then
			msg=msg..wowroster.StringColorize(wowroster.colorRed," not scanned")..".  - open your bank to scan";
		else
			for _,item in pairs(tsort) do
				msg=msg .. " " .. item.."]"..stat["Bank"][item]["inv"].."/"..stat["Bank"][item]["slot"];
			end
		end
	wowroster:Print(msg);
	msg="";

	msg = "Talents:";
		tsort={};
		table.foreach(stat["Talents"], function(k,v) table.insert(tsort,k) end );
		table.sort(tsort);
		if(table.getn(tsort)==0) then
			msg=msg..wowroster.StringColorize(wowroster.colorRed," not scanned")..".  - open your talents to scan";
		else
			for _,item in pairs(tsort) do
				msg=msg .. " " .. item..":"..stat["Talents"][item];
			end
		end
	wowroster:Print(msg);
	msg="";

	if (GetNumTalentGroups(false, "player") == 2) then
		msg = "Dual Spec Talents:";
			tsort={};
			table.foreach(stat["DSTalents"], function(k,v) table.insert(tsort,k) end );
			table.sort(tsort);
			if(table.getn(tsort)==0) then
				msg=msg..wowroster.StringColorize(wowroster.colorRed," not scanned")..".  - open your talents to scan";
			else
				for _,item in pairs(tsort) do
					msg=msg .. " " .. item..":"..stat["DSTalents"][item];
				end
			end
		wowroster:Print(msg);
		msg="";
	end

	if( GetNumCompanions ) then 
		msg = "Companions:";
		tsort={};
		table.foreach(stat["Companions"], function(k,v) table.insert(tsort,k) end );
		table.sort(tsort);
		if(table.getn(tsort)==0) then
			msg=msg..wowroster.StringColorize(wowroster.colorRed," not scanned");
		else
			for _,item in pairs(tsort) do
				msg=msg .. " " .. item..":"..stat["Companions"][item];
			end
		end
	end

	wowroster:Print(msg);
	msg="";

end

function wowroster:ARCHAEOLOGY_TOGGLE()
	wowroster:ARCH_frame()
end

function wowroster:BANKFRAME_OPENED()
	wowroster:GetBank();
end

function wowroster:BANKFRAME_CLOSED()
	wowroster:GetBank();
	wowroster:GetInventory();
	wowroster:GetEquipment();
end

function wowroster:makeconfig()
	local acOptions = {
		type = "group",
		name = "WoWRoster Profiler",
		get = GetProperty, set = SetProperty, handler = wowroster,
		args = {
			heading = {
				type = "description",
				name = "Welcome to the WoWRoster Profiler configuration",
				fontSize = "medium",
				order = 9,
				width = "full",
			},

			hide = {
				type = "toggle",
				name = "Mini Map Icon",
				desc = "Show/Hide the MiniMap icon check for hide uncheck for show",
				get = function() return wowroster.mm.profile.minimap.hide end,
				set = function(_, value) 
					wowroster.mm.profile.minimap.hide = value

					if wowroster.mm.profile.minimap.hide then
						wricon:Hide("WoWRoster Profiler")
					else
						wricon:Show("WoWRoster Profiler")
					end
				end,		
				order = 10,
			},


			Scan ={
				type = "group",
				name = "Scan Options",
				args = {
					heading = {
						type = "description",
						name = "Scan Options",
						fontSize = "medium",
						order = 13,
						width = "full",
					},
					heading_info = {
						type = "description",
						name = "Choose what WoWRoster Profiler will scan on your character",
						fontSize = "medium",
						order = 14,
						width = "full",
					},
					inventory = {
						type = "toggle",
						name = "Inventory",
						desc = "Scan the contents of your bags",
						set = function(info,val) wowrpref["scan"][info[#info]] = val end,
						get = function(info) return wowrpref["scan"][info[#info]] end,
						order = 15,
					},
					bank = {
						type = "toggle",
						name = "Bank",
						desc = "Scan the contents of your bank",
						set = function(info,val) wowrpref["scan"][info[#info]] = val end,
						get = function(info) return wowrpref["scan"][info[#info]] end,
						order = 16,
					},
					quests = {
						type = "toggle",
						name = "Quests",
						desc = "Scan your quest log",
						set = function(info,val) wowrpref["scan"][info[#info]] = val end,
						get = function(info) return wowrpref["scan"][info[#info]] end,
						order = 17,
					},
					questsfull= {
						type = "toggle",
						name = "Full Quests",
						desc = "Scan full quest description and objective list",
						set = function(info,val) wowrpref[info[#info]] = val end,
						get = function(info) return wowrpref[info[#info]] end,
						order = 18,
					},
					mail = {
						type = "toggle",
						name = "Mail Box",
						desc = "Scan your mail box",
						set = function(info,val) wowrpref["scan"][info[#info]] = val end,
						get = function(info) return wowrpref["scan"][info[#info]] end,
						order = 19,
					},
					talents = {
						type = "toggle",
						name = "Talents",
						desc = "Scan your talents",
						set = function(info,val) wowrpref["scan"][info[#info]] = val end,
						get = function(info) return wowrpref["scan"][info[#info]] end,
						order = 20,
					},
					glyphs = {
						type = "toggle",
						name = "Glyphs",
						desc = "Scan your glyphs",
						set = function(info,val) wowrpref["scan"][info[#info]] = val end,
						get = function(info) return wowrpref["scan"][info[#info]] end,
						order = 21,
					},
					pet = {
						type = "toggle",
						name = "Pets",
						desc = "Scan Pets [NYI] (returns no data)",
						set = function(info,val) wowrpref["scan"][info[#info]] = val end,
						get = function(info) return wowrpref["scan"][info[#info]] end,
						order = 22,
					},
					spells = {
						type = "toggle",
						name = "Spell Book",
						desc = "Scan your spell book",
						set = function(info,val) wowrpref["scan"][info[#info]] = val end,
						get = function(info) return wowrpref["scan"][info[#info]] end,
						order = 23,
					},
					professions = {
						type = "toggle",
						name = "Professions",
						desc = "Scan Professions",
						set = function(info,val) wowrpref["scan"][info[#info]] = val end,
						get = function(info) return wowrpref["scan"][info[#info]] end,
						order = 24,
					},
					companions = {
						type = "toggle",
						name = "Companions/Mounts",
						desc ="Scan companion and mount data",
						set = function(info,val) wowrpref["scan"][info[#info]] = val end,
						get = function(info) return wowrpref["scan"][info[#info]] end,
						order = 25,
					},
					honor = {
						type = "toggle",
						name = "Honor",
						desc = "Scan honor data",
						set = function(info,val) wowrpref["scan"][info[#info]] = val end,
						get = function(info) return wowrpref["scan"][info[#info]] end,
						order = 26,
					},
					reputation = {
						type = "toggle",
						name = "Reputation",
						desc="Scan reputation data",
						set = function(info,val) wowrpref["scan"][info[#info]] = val end,
						get = function(info) return wowrpref["scan"][info[#info]] end,
						order = 27,
					},
				},
			},

			DSScan ={
				type = "group",
				name = "Dual Spec Options",
				args = {
					heading = {
						type = "description",
						name = "Dual Spec Options",
						fontSize = "medium",
						order = 28,
						width = "full",
					},
					heading_info = {
						type = "description",
						name = "Enable or disable scanning options for your secondary talent spec",
						fontSize = "medium",
						order = 29,
						width = "full",
					},
					dstalents = {
						type = "toggle",
						name = "Talents",
						desc = "Scan your secondary talents",
						set = function(info,val) wowrpref["scan"][info[#info]] = val end,
						get = function(info) return wowrpref["scan"][info[#info]] end,
						order = 30,
					},
					dsglyphs = {
						type = "toggle",
						name = "Glyphs",
						desc = "Scan your secondary glyphs",
						set = function(info,val) wowrpref["scan"][info[#info]] = val end,
						get = function(info) return wowrpref["scan"][info[#info]] end,
						order = 31,
					},
					dsspells = {
						type = "toggle",
						name = "Spell Book",
						desc = "Scan your secondary spell book",
						set = function(info,val) wowrpref["scan"][info[#info]] = val end,
						get = function(info) return wowrpref["scan"][info[#info]] end,
						order = 32,
					},
				},
			},

			guildss ={
				type = "group",
				name = "Guild Scan Options",
				args = {
					heading = {
						type = "description",
						name = "Guild Scan Options",
						fontSize = "medium",
						order = 28,
						width = "full",
					},
					heading_info = {
						type = "description",
						name = "Choose what WoWRoster Profiler will scan for your guild",
						fontSize = "medium",
						order = 29,
						width = "full",
					},
					title = {
						type = "toggle",
						name = "Ranks",
						desc = "Scan member rank data",
						set = function(info,val) wowrpref["guild"][info[#info]] = val end,
						get = function(info) return wowrpref["guild"][info[#info]] end,
						order = 30,
					},
					compact = {
						type = "toggle",
						name = "Compact",
						desc = "Allow empty variables to be skipped",
						set = function(info,val) wowrpref["guild"][info[#info]] = val end,
						get = function(info) return wowrpref["guild"][info[#info]] end,
						order = 31,
					},
					vault = {
						type = "toggle",
						name = "Guild Vault",
						desc = "Scan the guild vault",
						set = function(info,val) wowrpref["guild"][info[#info]] = val end,
						get = function(info) return wowrpref["guild"][info[#info]] end,
						order = 32,
					},
					vault_log = {
						type = "toggle",
						name = "Guild Vault Logs",
						desc = "Scan the guild vault item logs",
						set = function(info,val) wowrpref["guild"][info[#info]] = val end,
						get = function(info) return wowrpref["guild"][info[#info]] end,
						order = 33,
					},
					vault_money = {
						type = "toggle",
						name = "Guild Vault Money Log",
						desc = "Scan the guild vault money log",
						set = function(info,val) wowrpref["guild"][info[#info]] = val end,
						get = function(info) return wowrpref["guild"][info[#info]] end,
						order = 34,
					},
					trades = {
						type = "toggle",
						name = "Guild Skills",
						desc = "Scan the professions list for entire guild [NYI] (no recipes stored)",
						set = function(info,val) wowrpref["guild"][info[#info]] = val end,
						get = function(info) return wowrpref["guild"][info[#info]] end,
						order = 35,
					},
				},
			},
		},
	}

	local server = GetRealmName();
	local acPurge = {
		type = "group",
		name = "Delete Profile Data",
		get = GetProperty, set = SetProperty, handler = wowroster,

		args = {
			heading = {
				type = "description",
				name = "Welcome to the WoWRoster Profiler data configuration",
				fontSize = "medium",
				order = 10,
				width = "full",
			},

			wipec = {
				order = 100,
				name = "Delete one Character",
				desc = "Select a character to delete",
				type = "select",
				values = function( info )
					local t = { }
					for k in pairs( cpProfile[GetRealmName()].Character ) do
						t[k] = k
					end
					return t
				end,
				get = false, -- no default value
				set = function( info, v )
				wowroster:Print("Code to delete data for cpProfiler[" .. GetRealmName() .. "].Character[" .. v .. "]" )
				end,
			},
			wipeac = {
				order = 100,
				name = "Delete all Characters",
				desc = "Delete all character data",
				type = "select",
				values = function( info )
				local t = { }
					for k in pairs( cpProfile ) do
						if (k ~= "profileKeys") then
							for c in pairs( cpProfile[k].Character ) do
								--wowroster:Print("Char: "..c.." "..k);
								if (c ~= "profileKeys") then
									t[c.."-"..k] = ""..c.." ("..k..")"
								end
							end
						end
					end
					return t
				end,
				get = false, -- no default value
				set = function( info, v )
				wowroster:Print("Code to delete data for cpProfiler[" .. GetRealmName() .. "].Character[" .. v .. "]" )
				end,
			},
			wipes = {
				order = 101,
				name = "Delete Server Data",
				desc = "Select a server to delete",
				type = "select",
				values = function( info )
				local t = { }
					for k in pairs( cpProfile ) do
						if (k ~= "profileKeys") then
							t[k] = k
						end
					end
					return t
				end,
				get = false, -- no default value
				set = function( info, v )
				wowroster:Print("Code to delete data for cpProfiler[" .. v .. "]" )
				end,
			},
			wipeg = {
				order = 102,
				name = "Delete Guild Data",
				desc = "Select a guild to delete",
				type = "select",
				values = function( info )
					local t = { }
					if (cpProfile[GetRealmName()]["Guild"]) then
						for k in pairs( cpProfile[GetRealmName()].Guild ) do
							if (k ~= "profileKeys") then
								t[k] = k
							end
					end
					else
						t=nil;
					end
					return t
				end,
				get = false, -- no default value
				set = function( info, v )
				wowroster:Print("Code to delete data for cpProfiler[" .. v .. "]" )
					if(cpProfile[GetRealmName()] and cpProfile[GetRealmName()]["Guild"] and cpProfile[GetRealmName()]["Guild"][v]) then
						cpProfile[GetRealmName()]["Guild"][v]=nil;
						isPurged=true;
						wowroster:Print("Guild "..v.."@"..GetRealmName().." purged");
					end
				end,
			},
--[[
			wipeall = {
				order = 104,
				name = "Delete All",
				desc = "Wipe all data stored",
				type = "execute",
				confirm = "function",
				values = cpProfile = nil,
				get = false, -- no default value
				set = 
				wowroster:Print( "Code to delete data for cpProfiler[" .. GetRealmName() .. "].Character[all]" ),
			
			},
]]--
		},
	}

--[[
	anchor = {
		order	= 9,
		type	= "select",
		name	= L["Anchor"],
		desc	= L["The corner of the Artifacts list that the frame will grow from."],
		get	= function() return db.artifact.anchor end,
		set	= function(_, value) 
			db.artifact.anchor = value
			Archy:SaveFramePosition(racesFrame)
		end,
		values	= frameAnchorOptions,
	},
]]--

	LibStub('AceConfig-3.0'):RegisterOptionsTable("wowroster cp",acOptions)

	ac:RegisterOptionsTable("WoWRoster CP", acOptions)
	--ac:RegisterOptionsTable("Profiles", LibStub("AceDBOptions-3.0"):GetOptionsTable(wowrpref.profiles))

	local mainOpts = acd:AddToBlizOptions("wowroster cp", "WoWRoster Profiler")

	LibStub("AceConfig-3.0"):RegisterOptionsTable("wowroster profiles", acPurge)
	self.profilesFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("wowroster profiles", "Profiles", "WoWRoster Profiler")


	mainOpts:HookScript("OnShow", function()
		wowroster:Enable()
		local p = findPanel("wowroster cp")
		if p and p.element.collapsed then OptionsListButtonToggle_OnClick(p.toggle) end
	end)
end

function wowroster:ChatCommand(input)
	if not input or input:trim() == "" then
		InterfaceOptionsFrame_OpenToCategory("WoWRoster Profiler")
	else
		LibStub("AceConfigCmd-3.0").HandleCommand("WoWRoster CP", "wr", "wroptions", input)
	end
end

function wowroster:InitState()
	local _,class=UnitClass("player");
	stat = {
		_loaded=nil,_lock=nil,_bag=nil,_bank=nil,_mail=nil,
		_server=GetRealmName(),_player=UnitName("player"),_class=class,
		_skills={},
		Equipment=0,
		Guild=nil, GuildNum=nil,
		Skills=0, Glyphs=0,
		Talents=0,TalentPts=0,
		Reputation=0,
		Quests=0, QuestsLog=0,
		Mail=nil,
		Honor=nil,
		Bag={},Inventory={},Bank={},
		Professions={}, SpellBook={}, Achi={},
		Pets={}, Stable={}, PetSpell={}, PetTalent={},
		Companions={},
	};
	self.queue={};

	state = function(self,...)
	if(not wowrpref) then return end
	local state = wowrpref;
	local n=select("#",...);
	local key=select(1,...);
	if(n==2) then
		local val=select(2,...);
		if(not state[key]) then
			if(val=='++' or val=='--') then
				state[key]=0;
			end
		end
		if(val=='++') then
			state[key]=state[key]+1;
		elseif(val=='--') then
			state[key]=state[key]-1;
		else
			state[key]=val;
		end
		return true;
	elseif( state and state[key] ) then
		return state[key];
	end
		return nil;
	end
end


State = function(self,...)
	if(not wowrpref) then return end
	local state = wowrpref;
	local n=select("#",...);
	local key=select(1,...);
	if(n==2) then
		local val=select(2,...);
		if(not state[key]) then
			if(val=='++' or val=='--') then
				state[key]=0;
			end
		end
		if(val=='++') then
			state[key]=state[key]+1;
		elseif(val=='--') then
			state[key]=state[key]-1;
		else
			state[key]=val;
		end
		return true;
	elseif( state and state[key] ) then
		return state[key];
	end
	return nil;
end

function wowroster:InitProfile()
	if( not cpProfile ) then
		cpProfile={}; end
	if( not cpProfile[stat["_server"]] ) then
		cpProfile[stat["_server"]]={}; end
	if( not cpProfile[stat["_server"]]["Character"] ) then
		cpProfile[stat["_server"]]["Character"]={}; end
	if( not cpProfile[stat["_server"]]["Character"][stat["_player"]] ) then
		cpProfile[stat["_server"]]["Character"][stat["_player"]]={}; end

	self.db = cpProfile[stat["_server"]]["Character"][stat["_player"]];

	if( self.db ) then
		self.db["CPversion"]	= "1.0.0";
		self.db["CPprovider"]	= "wowr";
		self.db["DBversion"]	= "3.1";
		self.db["Name"]			= stat["_player"];
		self.db["Server"]		= stat["_server"];
		self.db["Locale"]		= GetLocale();
		self.db["TimePlayed"]	= RequestTimePlayed();
		self.db["Race"],self.db["RaceEn"],self.db["RaceId"]=UnitRace("player")
		self.db["Class"],self.db["ClassEn"],self.db["ClassId"]=wowroster.UnitClass("player");
		self.db["Sex"],self.db["SexId"]=wowroster.UnitSex("player");
		self.db["FactionEn"],self.db["Faction"]=UnitFactionGroup("player");
		self.db["HasRelicSlot"]	= UnitHasRelicSlot("player")==1 or false;
		self.db["timestamp"] = {};
		self.db["Cached"] = {};
		self:UpdateDate();
		stat["_loaded"] = true;
	end
	return stat["_loaded"];
end


function wowroster:ScanPetInit(name)
	if(name) then
		if(not self.db["Pets"]) then
			self.db["Pets"]={};
		end
		if(not self.db["Pets"][name]) then
			self.db["Pets"][name]={};
		end
		if(not self.db["timestamp"]["Pets"]) then
			self.db["timestamp"]["Pets"]={};
		end
	end
end

function wowroster:ScanPetStable()
	if(wowrpref["scan"]["pet"] and (self:State("_class")=="HUNTER" and UnitLevel("player")>9)) then
		local stablePets={};
		for petIndex=0,GetNumStableSlots() do
			local petIcon,petName,petLevel,petType,petLoyalty=GetStablePetInfo(petIndex);
			if(petName and petName~=UNKNOWN) then
				self:ScanPetInit(petName);
				local structPets=self.db["Pets"];
				structPets[petName]["Slot"]=petIndex;
				structPets[petName]["Icon"]=rpgo.scanIcon(petIcon);
				structPets[petName]["Name"]=petName;
				structPets[petName]["Level"]=petLevel;
				structPets[petName]["Type"]=petType;
				structPets[petName]["Loyalty"]=petLoyalty;
				stablePets[petName]=petIndex;
				self.db["timestamp"]["Pets"][petName]=time();
			end
			stat["Stable"][petIndex]=petName;
		end
		for petName,_ in pairs( self.db["Pets"] ) do
			if( not stablePets[petName] ) then
				self.db["Pets"][petName]=nil;
			end
		end
		for petName,_ in pairs( self.db["timestamp"]["Pets"] ) do
			if( not stablePets[petName] ) then
				self.db["timestamp"]["Pets"][petName]=nil;
			end
		end
		self:ScanPetInfo();
	elseif(self.db) then
		self.db["Pets"]=nil;
		stat["Pets"]={};
	end
end

function wowroster:ScanPetInfo()
	if(wowrpref["scan"]["pet"]) then
		if(HasPetUI()) then
			local petName=UnitName("pet");
			if( petName and petName~=UNKNOWN ) then
				self:ScanPetInit(petName);
				local structPet=self.db["Pets"][petName];
				structPet["Name"]=petName;
				structPet["Type"]=UnitCreatureFamily("pet");
				structPet["Experience"]=strjoin(":", GetPetExperience());
				self:GetStats(structPet,"pet");
				self:GetBuffs(structPet,"pet");
				
--WotLK
			if( GetPetTalentPoints and (self:State("_class")=="HUNTER" and UnitLevel("player")>9) ) then
				--self:GetTalents("pet");
			end
				self:GetPetSpellBook();
				stat["Pets"][petName]=1;
				self.db["timestamp"]["Pets"][petName]=time();
			end
		end
	elseif(self.db) then
		self.db["Pets"]=nil;
		stat["Pets"]={};
	end
end

function wowroster:GetPetAttack(structAttack,unit,prefix)


	local mainHandAttackBase, mainHandAttackMod, offHandHandAttackBase, offHandAttackMod = UnitAttackBothHands("Pet")
	local base, posBuff, negBuff = UnitAttackPower(unit)
	local speed, offhandSpeed = UnitAttackSpeed(unit)
	local minDamage, maxDamage, minOffHandDamage, maxOffHandDamage, physicalBonusPos, physicalBonusNeg, percent = UnitDamage(unit)
	local base, modifier = UnitDefense(unit)
--	local base, resistance, positive, negative = UnitResistance(unit, resistanceIndex)

	local displayMin = max(floor(minDamage),1);
	local displayMax = max(ceil(maxDamage),1);

	minDamage = (minDamage / percent) - physicalBonusPos - physicalBonusNeg;
	maxDamage = (maxDamage / percent) - physicalBonusPos - physicalBonusNeg;

	local baseDamage = (minDamage + maxDamage) * 0.5;
	local fullDamage = (baseDamage + physicalBonusPos + physicalBonusNeg) * percent;
	local totalBonus = (fullDamage - baseDamage);
	local damagePerSecond = (max(fullDamage,1) / speed);
	--local damageText = getglobal(statFrame:GetName().."StatText");



	structAttack["Melee"]={};
	structAttack["Melee"]["MainHand"]={};
	structAttack["Melee"]["MainHand"]["AttackSpeed"]=wowroster.round(speed,2);
	structAttack["Melee"]["MainHand"]["AttackDPS"]=wowroster.round(damagePerSecond,1);
	structAttack["Melee"]["MainHand"]["AttackRating"]=mainHandAttackBase+mainHandAttackMod;

	--local tt=damageText:GetText();
	--tt=wowroster.StripColor(tt);
	structAttack["Melee"]["MainHand"]["DamageRange"]=""..wowroster.round(minDamage,0)..":"..wowroster.round(maxDamage,0).."";
	
	local base,posBuff,negBuff = UnitAttackPower(unit);
	
	apDPS=max((base+posBuff+negBuff),0)/ATTACK_POWER_MAGIC_NUMBER;
	structAttack["Melee"]["AttackPower"] = strjoin(":", base,posBuff,negBuff);
	structAttack["Melee"]["AttackPowerDPS"]=wowroster.round(apDPS,1);
	structAttack["Melee"]["AttackPowerTooltip"]=format(MELEE_ATTACK_POWER_TOOLTIP,apDPS);

end

function wowroster:GetPetSpellBook()
	if(wowrpref["scan"]["spells"]) then
		local petName=UnitName("pet");
		if( petName and petName~=UNKNOWN ) then
			numSpells,_=HasPetSpells();
			if( numSpells ) then
				self:ScanPetInit(petName);
				if (not self.db["Pets"][petName]["SpellBook"]) then
					self.db["Pets"][petName]["SpellBook"]={};
				end
				local structPetSpell=self.db["Pets"][petName]["SpellBook"];
				if (not structPetSpell["Spells"]) then
					structPetSpell["Spells"]={};
				end

				local cnt=0;
				for petSpellId=1,numSpells do
	local spellName, spellRank, icon, powerCost, isFunnel, powerType, castingTime, minRange, maxRange = GetSpellInfo(petSpellId,BOOKTYPE_PET)
					--local spellName=GetSpellName(petSpellId,BOOKTYPE_PET);
					if ( spellName ) then
						structPetSpell["Spells"][spellName] = wowroster:ScanSpellInfo(petSpellId,BOOKTYPE_PET);
						cnt=cnt+1;
					end
				end
				structPetSpell["Count"]=cnt;
				stat["PetSpell"][petName]=cnt;
			end
		end
	end
end


wowroster.UpdateDate = function(self,...)
	if(not wowroster.db) then return; end;
	local struct=wowroster.db;
	if ( not struct["timestamp"] ) then struct["timestamp"]={}; end
	local timestamp = time();
	local currHour,currMinute=GetGameTime();
	struct["timestamp"]={};
	struct["timestamp"]["init"]={};
	struct["timestamp"]["init"]["TimeStamp"]=timestamp;
	struct["timestamp"]["init"]["Date"]=date("%Y-%m-%d %H:%M:%S",timestamp);
	struct["timestamp"]["init"]["DateUTC"]=date("!%Y-%m-%d %H:%M:%S",timestamp);
	struct["timestamp"]["init"]["ServerTime"]=format("%02d:%02d",currHour,currMinute);
	struct["timestamp"]["init"]["datakey"]=wowroster.versionkey();
end


--[GetReputation]
function wowroster:GetReputation()
	if(not wowrpref["scan"]["reputation"]) then
		wowroster.db["Reputation"]=nil;
		return;
	end
	wowroster.db["Reputation"]={};
	stat["Reputation"]=0;
	local toCollapse={};
	for idx=GetNumFactions(),1,-1 do
		local _,_,_,_,_,_,_,_,isHeader,isCollapsed=GetFactionInfo(idx);
		if(isHeader and isCollapsed) then
			table.insert(toCollapse,idx);
			ExpandFactionHeader(idx);
		end
	end

	local thisHeader,thisSubHeader,numFactions,structRep = NONE,NONE,GetNumFactions(),wowroster.db["Reputation"];
	structRep["Count"]=numFactions;
	for idx=1,numFactions do
		local name,description,standingId,bottomValue,topValue,earnedValue,atWarWith,canToggleAtWar,isHeader,isCollapsed,hasRep,isWatched,isChild = GetFactionInfo(idx);
		local item;
		if(isHeader and (not isChild)) then --Super category, like 'Classic' or 'The Burning Crusade'
			thisHeader=name;
			thisSubHeader=NONE;
			structRep[thisHeader]={};
			item=structRep[thisHeader];
		elseif((not isHeader) and (not isChild)) then --Supercategory member, like 'Darkmoon Faire' or 'Thrallmar'
			structRep[thisHeader][name]={};
			item=structRep[thisHeader][name];
		elseif(isHeader and isChild) then --Subcategory, like 'Horde Forces' or 'Shattrath City'
			thisSubHeader=name;
			structRep[thisHeader][thisSubHeader]={};
			item=structRep[thisHeader][thisSubHeader];
		elseif((not isHeader) and isChild) then --Subcategory member, like 'Orgrimmar' or 'Lower City'
			structRep[thisHeader][thisSubHeader][name]={};
			item=structRep[thisHeader][thisSubHeader][name];
		end

		item["Description"] = description;
		item["Standing"] = getglobal("FACTION_STANDING_LABEL"..standingId);
		item["AtWar"] = atWarWith or 0;
		item["Value"] = earnedValue-bottomValue..":"..topValue-bottomValue;
		stat["Reputation"]=stat["Reputation"]+1;
	end

	table.sort(toCollapse);
	for _,idx in pairs(toCollapse) do
		CollapseFactionHeader(idx);
	end
end

--[GetHonor]
function wowroster:GetHonor()
	if(not wowrpref["scan"]["honor"]) then
		wowroster.db["Honor"]=nil;
		return;
	end
	local lifetimeHK,lifetimeRank=GetPVPLifetimeStats();
	if(stat["Honor"]~=lifetimeHK) then
		if (not wowroster.db["Honor"]) then
			wowroster.db["Honor"]={};
		end
		local structHonor=wowroster.db["Honor"];
		local rankName,rankNumber=GetPVPRankInfo(lifetimeRank);
		local sessionHK,sessionCP=GetPVPSessionStats();
		local GetArenaCurrency = GetArenaCurrency or function() return select(2,GetCurrencyInfo(390)) or 0 end
		local GetHonorCurrency = GetHonorCurrency or function() return select(2,GetCurrencyInfo(392)) or 0 end

		if ( not rankName ) then rankName=NONE; end
		structHonor["Lifetime"]={
			Rank=rankNumber,
			Name=rankName,
			HK=lifetimeHK
		};
		structHonor["Current"]={
			Rank=0,
			Name=NONE,
			Icon="",
			Progress=0,
			HonorPoints=GetHonorCurrency(),
			ArenaPoints=GetArenaCurrency()
		};
		structHonor["Session"]={HK=sessionHK,CP=sessionCP};
		structHonor["Yesterday"]=wowroster.Arg2Tab("HK","CP",GetPVPYesterdayStats());

		stat["Honor"]=lifetimeHK;
	end
end

function wowroster:ScanCurrency(force)
	if( not GetCurrencyListSize ) then return end;
	if(not wowrpref["scan"]["currency"]) then
		wowroster.db["Currency"]=nil;
		return;
	end

	local toCollapse={};
	for idx=GetCurrencyListSize(),1,-1 do
		local _,isHeader,isExpanded=GetCurrencyListInfo(idx);
		if(isHeader and not isExpanded) then
			table.insert(toCollapse,idx);
			ExpandCurrencyList(idx,1);
		end
	end

	if( force or (stat["Currency"]~=GetCurrencyListSize()) ) then
		if (not wowroster.db["Currency"]) then
			wowroster.db["Currency"]={};
		end
		local structCurrency = wowroster.db["Currency"];
		local thisHeader;
		local cnt = 0;
		local name,isHeader,isExpanded,isUnused,isWatched,count,extraCurrencyType,icon;
		for idx=1,GetCurrencyListSize() do
			name, isHeader, isExpanded, isUnused, isWatched, count, extraCurrencyType, icon, itemID = GetCurrencyListInfo(idx);
			if ( name and name ~= "" ) then
				if ( isHeader ) then
					thisHeader=name;
					structCurrency[thisHeader]={};
				else
					if ( extraCurrencyType ~= 0 ) then
					end
					GameTooltip:SetCurrencyToken(idx)
					tooltip = wowroster.scantooltip2()
					if( not isWatched ) then
						isWatched=nil;
					end

					structCurrency[thisHeader][name] = {
						Name	= name,
						Watched	= isWatched,
						Count	= count,
						Icon	= wowroster.scanIcon(extraCurrencyType),
						Tooltip	= tooltip,
					};
				end
				cnt=cnt+1;
			end
		end
		stat["Currency"]=cnt;
	end

	table.sort(toCollapse);
	for _,idx in pairs(toCollapse) do
		ExpandCurrencyList(idx,0);
	end
end

function wowroster:GetArena()
	if(not wowrpref["scan"]["honor"]) then
		wowroster.db["Honor"]=nil;
		return;
	end
	--PVPFrame_Update();
	local arenaGames = 0;
	local ARENA_TEAMS = {};
	ARENA_TEAMS[1] = {size = 2};
	ARENA_TEAMS[2] = {size = 3};
	ARENA_TEAMS[3] = {size = 5};
	for index,value in pairs(ARENA_TEAMS) do
		for i=1, MAX_ARENA_TEAMS do
			ArenaTeamRoster(i);
			local _, teamSize, _, _, _, seasonTeamPlayed = GetArenaTeam(i);
			if ( value.size == teamSize ) then
				value.index = i;
				arenaGames = arenaGames + seasonTeamPlayed;
			end
		end
	end
	if (not wowroster.db["Honor"]) then
		wowroster.db["Honor"]={};
	end
	structHonor = wowroster.db["Honor"];
	if(stat["Arena"]~=arenaGames) then
		arenaGames = 0;
		for index,value in pairs(ARENA_TEAMS) do
			local key = value.size..'v'..value.size;
			if ( value.index ) then
				if(not structHonor[key]) then
					structHonor[key] = {};
				end
				local teamName, teamSize, teamRating, teamPlayed, teamWins, seasonTeamPlayed, seasonTeamWins, playerPlayed, seasonPlayerPlayed, teamRank, playerRating = GetArenaTeam(value.index);
				structHonor[key]['Name'] = teamName;
				structHonor[key]['Size'] = teamSize;
				structHonor[key]['Rating'] = teamRating;
				structHonor[key]['Rank'] = teamRank;
				structHonor[key]['PlayerRating'] = playerRating;
				structHonor[key]['Week'] = {Games=teamPlayed,Wins=teamWins,Played=playerPlayed};
				structHonor[key]['Season'] = {Games=seasonTeamPlayed,Wins=seasonTeamWins,Played=seasonPlayerPlayed};

				local teamNumMembers = GetNumArenaTeamMembers(value.index,true);
				if( teamNumMembers ~= 0 ) then
					structHonor[key]['NumMembers'] = teamNumMembers;
					arenaGames = arenaGames + seasonTeamPlayed;
				elseif( not structHonor[key]['NumMembers'] ) then
					structHonor[key]['NumMembers'] = '';
				end
			else
				structHonor[key]=nil;
			end
		end
		stat["Arena"]=arenaGames;
	end
end

--[GetQuests]
function wowroster:GetQuests(force)
	if(not wowrpref["scan"]["quests"]) then
		wowroster.db["Quests"]=nil;
		return;
	end

	local selected=GetQuestLogSelection();
	local toCollapse={};
	for idx=GetNumQuestLogEntries(),1,-1 do
		_,_,_,_,isHeader,isCollapsed,_ = GetQuestLogTitle(idx);
		if(isHeader and isCollapsed) then
			table.insert(toCollapse,idx);
			ExpandQuestHeader(idx);
		end
	end

	local numEntries,numQuests=GetNumQuestLogEntries();

	local function GetDifficultyValue(level)
		local levelDiff = level - UnitLevel("player");
		local color
		if ( levelDiff >= 5 ) then
			color = 4;
		elseif ( levelDiff >= 3 ) then
			color = 3;
		elseif ( levelDiff >= -2 ) then
			color = 2;
		elseif ( -levelDiff <= GetQuestGreenRange() ) then
			color = 1;
		else
			color = 0;
		end
		return color;
	end

	if( force or (stat["QuestsLog"]~=numEntries) ) then
		wowroster.db["Quests"]={};
		stat["Quests"]=0;
		stat["QuestsLog"]=0;
		local slot,num,header,structQuest = 1,nil,UNKNOWN,wowroster.db["Quests"];
		for idx=1,numEntries do
			local questDescription,questObjective;
			local questId = wowroster.GetQuestID( GetQuestLink(idx) );
			local questTitle,questLevel,questTag,suggestedGroup,isHeader,isCollapsed,isComplete,isDaily = GetQuestLogTitle(idx);
			if(questTitle) then
				if(isHeader) then
					header=questTitle;
					if(not structQuest[header]) then
						structQuest[header]={}
					end
				else
					SelectQuestLogEntry(idx);
					if(suggestedGroup and tonumber(suggestedGroup) and suggestedGroup<=1) then
						suggestedGroup=nil;
					end
					if(wowrpref["questsfull"]) then
						questDescription,questObjective = GetQuestLogQuestText(idx);
					end
					structQuest[header][slot]={
						QuestId	=questId,
						Title	=questTitle,
						Level	=questLevel,
						Complete=isComplete,
						Daily	=isDaily,
						Tag		=questTag,
						Difficulty=GetDifficultyValue(questLevel),
						Group=suggestedGroup,
						Description=questDescription,
						Objective=questObjective
					};

					num=GetNumQuestLeaderBoards(idx);
					if(num and num > 0) then
						structQuest[header][slot]["Tasks"]={};
						for idx2=1,num do
							structQuest[header][slot]["Tasks"][idx2]=wowroster.Arg2Tab("Note","Type","Done",GetQuestLogLeaderBoard(idx2,idx));
						end
					end
					num=GetQuestLogRewardMoney(idx);
					if(num and num > 0) then
						structQuest[header][slot]["RewardMoney"]=num;
					end
					num=GetNumQuestLogRewards(idx);
					if(num and num > 0) then
						structQuest[header][slot]["Rewards"]={};
						for idx2=1,num do
							_,curItemTexture,itemCount,_,_=GetQuestLogRewardInfo(idx2);
							GameTooltip:SetQuestLogItem("reward",idx2);
							table.insert(structQuest[header][slot]["Rewards"],self:ScanItemInfo(GetQuestLogItemLink("reward",idx2),curItemTexture,itemCount));
						end
					end
					num=GetNumQuestLogChoices(idx);
					if(num and num > 0) then
						structQuest[header][slot]["Choice"]={};
						for idx2=1,num do
							_,curItemTexture,itemCount,_,_=GetQuestLogChoiceInfo(idx2);
							GameTooltip:SetQuestLogItem("choice",idx2);
							table.insert(structQuest[header][slot]["Choice"],self:ScanItemInfo(GetQuestLogItemLink("choice",idx2),curItemTexture,itemCount));
						end
					end
					slot=slot+1;
					stat["Quests"] = stat["Quests"]+1;
				end
			end
			stat["QuestsLog"] = stat["QuestsLog"]+1;
		end
	end

	table.sort(toCollapse);
	for _,idx in pairs(toCollapse) do
		CollapseQuestHeader(idx);
	end
	SelectQuestLogEntry(selected);
end


function wowroster:ScanCompanions()
	if( not GetNumCompanions) then return; end

	if(wowrpref["scan"]["companions"]) then
		local crittertypes={"Critter","Mount"};

		if(not wowroster.db["Companions"]) then
			wowroster.db["Companions"]={};
		end
		if(not wowroster.db["timestamp"]["Companions"]) then
			wowroster.db["timestamp"]["Companions"]={};
		end
		local structCompanion=wowroster.db["Companions"];

		for index,companionType in pairs(crittertypes) do
			local numCompanions = GetNumCompanions(companionType);
			if(not wowroster.db["Companions"][companionType]) then
				wowroster.db["Companions"][companionType]={};
			end

			if( stat["Companions"][companionType] ~= numCompanions ) then
				stat["Companions"][companionType] = 0;
				for companionIndex=1,numCompanions do
					local creatureID,creatureName,spellID,icon,active = GetCompanionInfo(companionType,companionIndex);

					if(creatureName and creatureName~=UNKNOWN) then
						GameTooltip:SetOwner(UIParent, 'ANCHOR_NONE')  
						GameTooltip:SetSpellByID(spellID)
						tooltip = wowroster.scantooltip2()
						GameTooltip:Hide()
						structCompanion[companionType][companionIndex] = {
							Name		= creatureName,
							CreatureID	= creatureID,
							SpellId		= spellID,
							Active		= active,
							Icon		= wowroster.scanIcon(icon),
							Tooltip		= tooltip,
						};
					end
					stat["Companions"][companionType] = stat["Companions"][companionType]+1;
				end
				wowroster.db["timestamp"]["Companions"][companionType] = time();
			end
		end
	elseif(wowroster.db) then
		wowroster.db["Companions"]=nil;
		stat["Companions"]={};
	end
end

function wowroster:ScanGlyphs(startGlyph)
	if( not GetNumGlyphSockets) then return; end
	numTalentGroups = GetNumTalentGroups(false, "player");
	atg = GetActiveTalentGroup(false, "player");
	if (atg == 2) then
		TalentGroup = 1;
	else
		TalentGroup = 2;
	end

	if(wowrpref["scan"]["glyphs"]) then
		if(not wowroster.db["Glyphs"]) then
			wowroster.db["Glyphs"]={};
		end
		local numGlyphs;
		if( not startGlyph ) then
			startGlyph = 1;
			numGlyphs=GetNumGlyphSockets();
		else
			numGlyphs=startGlyph;
			stat["Glyphs"] = stat["Glyphs"]-1;
		end

		if( startGlyph==numGlyphs or stat["Glyphs"]==0 ) then
			local structGlyph=wowroster.db["Glyphs"];
			for index=startGlyph,numGlyphs do
				local enabled, glyphType, glyphTooltipIndex, glyphSpell, icon = GetGlyphSocketInfo(index);
				if(enabled == 1 and glyphSpell) then
					GameTooltip:SetOwner(UIParent, 'ANCHOR_NONE')  
					GameTooltip:SetGlyph(index);
					tooltip = wowroster.scantooltip2()
					GameTooltip:Hide()
					name, rank, icon, powerCost, isFunnel, powerType, castingTime, minRange, maxRange = GetSpellInfo(glyphSpell)
					structGlyph[index] = {
						Name	= name,
						Type	= glyphType,
						Icon	= wowroster.scanIcon(icon),
						Tooltip	= tooltip,
					};
					stat["Glyphs"] = stat["Glyphs"]+1;
				else
					structGlyph[index] = nil;
				end
			end
			wowroster.db["timestamp"]["Glyphs"]=time();
		end

		if (numTalentGroups==2 and wowrpref["scan"]["dsglyphs"]) then	
			if( not startGlyph ) then
				startGlyph = 1;
				numGlyphs=GetNumGlyphSockets();
			else
				numGlyphs=startGlyph;
				stat["Glyphs"] = stat["Glyphs"]-1;
			end

			local structGlyphs={};
			for index=1, GetNumGlyphSockets() do
				local enabled, glyphType, glyphTooltipIndex, glyphSpell, icon = GetGlyphSocketInfo(index,TalentGroup);
				if(enabled == 1 and glyphSpell) then
					GameTooltip:SetOwner(UIParent, 'ANCHOR_NONE')  
					GameTooltip:SetGlyph(index,TalentGroup);
					local name, link = GameTooltip:GetItem()
					tooltip = wowroster.scantooltip2()
					GameTooltip:Hide()
					name, rank, icon, powerCost, isFunnel, powerType, castingTime, minRange, maxRange = GetSpellInfo(glyphSpell)
					structGlyphs[index] = {
						Name	= name,
						Type	= glyphType,
						Icon	= wowroster.scanIcon(icon),
						Tooltip	= tooltip,
					};
					stat["Glyphs"] = stat["Glyphs"]+1;
				else
					structGlyphs[index] = nil;
				end
			end
			wowroster.db["DualSpec"]["Glyphs"]=structGlyphs;
			wowroster.db["timestamp"]["Glyphs"]=time();
		end

	elseif(wowroster.db) then
		wowroster.db["Glyphs"] = nil;
		stat["Glyphs"] = 0;
	end
end

function wowroster:GetEquipment(force)
	if(not wowrpref["scan"]["equipment"]) then
		wowroster.db["Equipment"]=nil;
		return;
	end

	wowroster.db["Equipment"]={};
	stat["Equipment"] = 0;

	local structEquip=wowroster.db["Equipment"];
	for index,slot in pairs(UnitSlots) do
		local itemLink,itemCount;
		local itemTexture = GetInventoryItemTexture("player",index);
		local headSlot = getglobal("Character"..slot);

		itemLink = GetInventoryItemLink("player",index);
		if(itemLink) then
			itemCount=GetInventoryItemCount("player",index);
			if(itemCount == 1) then itemCount=nil; end

			structEquip[slot]=wowroster:ScanItemInfo(itemLink,itemTexture,itemCount,index,"player");
			stat["Equipment"]=stat["Equipment"]+1;
			itemLink=nil;
		end
	end
	wowroster.db["timestamp"]["Equipment"]=time();

	self:GetStats(self.db);
end

wowroster.UnitHasResSickness = function(unit)
	local idx=1;
	if(UnitDebuff(unit,idx)) then
		while(UnitDebuff(unit,idx)) do
			buffTexture=UnitDebuff(unit,idx);
			if(buffTexture == "Interface\\Icons\\Spell_Shadow_DeathScream") then
				return true;
			end
			idx=idx+1;
		end
	end
	return nil;
end

function wowroster:GetStats(structStats,unit)
	unit = unit or "player";
	if( unit=="player" and (UnitIsDeadOrGhost("player") or wowroster.UnitHasResSickness("player")) ) then
		return
	end
	if(not structStats["Attributes"]) then
		structStats["Attributes"]={};
	end
	structStats["Level"]=UnitLevel(unit);
	structStats["Health"]=UnitHealthMax(unit);
	structStats["Mana"]=UnitPowerMax(unit);
	structStats["Power"]=UnitPower[UnitPowerType(unit)];
	structStats["Attributes"]["Stats"]={};
	for i=1,table.getn(UnitStatName) do
		local stat,effectiveStat,posBuff,negBuff=UnitStat(unit,i);
		structStats["Attributes"]["Stats"][UnitStatName[i]] = strjoin(":", (stat - posBuff - negBuff),posBuff,negBuff);
	end
	local base,posBuff,negBuff,modBuff,effBuff,stat;
	base,modBuff = UnitDefense(unit);
	posBuff,negBuff = 0,0;
	if ( modBuff > 0 ) then
		posBuff = modBuff;
	elseif ( modBuff < 0 ) then
		negBuff = modBuff;
	end
	structStats["Attributes"]["Defense"] = {};
	structStats["Attributes"]["Defense"]["Defense"] = strjoin(":", base,posBuff,negBuff);
	base,effBuff,stat,posBuff,negBuff=UnitArmor(unit);
	structStats["Attributes"]["Defense"]["Armor"] = strjoin(":", base,posBuff,negBuff);
	structStats["Attributes"]["Defense"]["ArmorReduction"] = PaperDollFrame_GetArmorReduction(effBuff, UnitLevel("player"));
	base,posBuff,negBuff = GetCombatRating(CR_DEFENSE_SKILL),wowroster.round(GetCombatRatingBonus(CR_DEFENSE_SKILL),2),0;
	structStats["Attributes"]["Defense"]["DefenseRating"]=strjoin(":", base,posBuff,negBuff);
	structStats["Attributes"]["Defense"]["DefensePercent"]=GetCombatRatingBonus(CR_DEFENSE_SKILL);--GetDodgeBlockParryChanceFromDefense();
	base,posBuff,negBuff = GetCombatRating(CR_DODGE),wowroster.round(GetCombatRatingBonus(CR_DODGE),2),0;
	structStats["Attributes"]["Defense"]["DodgeRating"]=strjoin(":", base,posBuff,negBuff);
	structStats["Attributes"]["Defense"]["DodgeChance"]=wowroster.round(GetDodgeChance(),2);
	base,posBuff,negBuff = GetCombatRating(CR_BLOCK),wowroster.round(GetCombatRatingBonus(CR_BLOCK),2),0;
	structStats["Attributes"]["Defense"]["BlockRating"]=strjoin(":", base,posBuff,negBuff);
	structStats["Attributes"]["Defense"]["BlockChance"]=wowroster.round(GetBlockChance(),2);
	base,posBuff,negBuff = GetCombatRating(CR_PARRY),wowroster.round(GetCombatRatingBonus(CR_PARRY),2),0;
	structStats["Attributes"]["Defense"]["ParryRating"]=strjoin(":", base,posBuff,negBuff);
	structStats["Attributes"]["Defense"]["ParryChance"]=wowroster.round(GetParryChance(),2);
	structStats["Attributes"]["Defense"]["Resilience"]={};
	structStats["Attributes"]["Defense"]["Resilience"]["Melee"]=GetCombatRating(COMBAT_RATING_RESILIENCE_CRIT_TAKEN);

	structStats["Attributes"]["Resists"]={};
	for i=1,table.getn(UnitResistanceName) do
		local base,resistance,positive,negative=UnitResistance(unit,i);
		structStats["Attributes"]["Resists"][UnitResistanceName[i]] = strjoin(":", base,positive,negative);
	end
	if(unit=="player") then
		structStats["Hearth"]=GetBindLocation();
		structStats["Money"]=wowroster.Arg2Tab("Gold","Silver","Copper",wowroster.parseMoney(GetMoney()));
		structStats["IsResting"]=IsResting() == 1 or false;
		structStats["Experience"]=strjoin(":", UnitXP("player"),UnitXPMax("player"),GetXPExhaustion() or 0);
		self:GetAttackRating(structStats["Attributes"],unit);
		wowroster.db["timestamp"]["Attributes"]=time();
	elseif(unit=="pet") then
		self:GetPetAttack(structStats["Attributes"],unit,"Pet");
	else
		self:GetAttackRatingOld(structStats["Attributes"],unit,"Pet");
	end
end

function wowroster:CharacterDamageFrame(damageFrame)
	damageFrame = damageFrame or getglobal("PlayerStatFrameLeft1StatText");
	if (not damageFrame.damage) then return; end
	wowroster.tooltip:ClearLines();
	-- Main hand weapon
	wowroster.tooltip:SetText(INVTYPE_WEAPONMAINHAND, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	wowroster.tooltip:AddDoubleLine(ATTACK_SPEED_COLON, format("%.2f", damageFrame.attackSpeed), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
	wowroster.tooltip:AddDoubleLine(DAMAGE_COLON, damageFrame.damage, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
	wowroster.tooltip:AddDoubleLine(DAMAGE_PER_SECOND, format("%.1f", damageFrame.dps), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
	-- Check for offhand weapon
	if ( damageFrame.offhandAttackSpeed ) then
		wowroster.tooltip:AddLine("\n");
		wowroster.tooltip:AddLine(INVTYPE_WEAPONOFFHAND, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
		wowroster.tooltip:AddDoubleLine(ATTACK_SPEED_COLON, format("%.2f", damageFrame.offhandAttackSpeed), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
		wowroster.tooltip:AddDoubleLine(DAMAGE_COLON, damageFrame.offhandDamage, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
		wowroster.tooltip:AddDoubleLine(DAMAGE_PER_SECOND, format("%.1f", damageFrame.offhandDps), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
	end
end

function wowroster:CharacterRangedDamageFrame(damageFrame)
	damageFrame = damageFrame or getglobal("PlayerStatFrameLeft1");
	if (not damageFrame.damage) then return; end
	wowroster.tooltip:ClearLines();
	wowroster.tooltip:SetText(INVTYPE_RANGED, HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b);
	wowroster.tooltip:AddDoubleLine(ATTACK_SPEED_COLON, format("%.2f", damageFrame.attackSpeed), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
	wowroster.tooltip:AddDoubleLine(DAMAGE_COLON, damageFrame.damage, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
	wowroster.tooltip:AddDoubleLine(DAMAGE_PER_SECOND, format("%.1f", damageFrame.dps), NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b);
end

function wowroster:GetAttackRating(structAttack,unit,prefix)
	unit = unit or "player";
	prefix = prefix or "PlayerStatFrameLeft";

	local stat = getglobal(prefix.."1");
	local stat1 = getglobal(prefix..1)          
	local stat2 = getglobal(prefix..2)          
	local stat3 = getglobal(prefix..3)          
	local stat4 = getglobal(prefix..4)          
	local stat5 = getglobal(prefix..5)          
	local stat6 = getglobal(prefix..6)  

	local mainHandAttackBase,mainHandAttackMod,offHandAttackBase,offHandAttackMod = UnitAttackBothHands(unit);
	local speed,offhandSpeed = UnitAttackSpeed(unit);
	local minDamage;
	local maxDamage; 
	local minOffHandDamage;
	local maxOffHandDamage; 
	local physicalBonusPos;
	local physicalBonusNeg;
	local percent;
	minDamage, maxDamage, minOffHandDamage, maxOffHandDamage, physicalBonusPos, physicalBonusNeg, percent = UnitDamage(unit);
	local displayMin = max(floor(minDamage),1);
	local displayMax = max(ceil(maxDamage),1);

	minDamage = (minDamage / percent) - physicalBonusPos - physicalBonusNeg;
	maxDamage = (maxDamage / percent) - physicalBonusPos - physicalBonusNeg;

	local baseDamage = (minDamage + maxDamage) * 0.5;
	local fullDamage = (baseDamage + physicalBonusPos + physicalBonusNeg) * percent;
	local totalBonus = (fullDamage - baseDamage);
	local damagePerSecond = (max(fullDamage,1) / speed);

	structAttack["Melee"]={};
	structAttack["Melee"]["Expertise"]=GetExpertise();
	structAttack["Melee"]["MainHand"]={};
	structAttack["Melee"]["MainHand"]["AttackSpeed"]=wowroster.round(speed,2);
	structAttack["Melee"]["MainHand"]["AttackDPS"]=wowroster.Percent(damagePerSecond);--wowroster.round(stat.dps,1);
	structAttack["Melee"]["MainHand"]["AttackSkill"]=mainHandAttackBase+mainHandAttackMod;
	structAttack["Melee"]["MainHand"]["AttackRating"]=strjoin(":", wowroster.Percent(mainHandAttackBase),wowroster.Percent(mainHandAttackMod),0);

	structAttack["Melee"]["MainHand"]["DamageRangeBase"]=strjoin(":",wowroster.Percent(minDamage),wowroster.Percent(maxDamage));

	if ( offhandSpeed ) then
		minOffHandDamage = (minOffHandDamage / percent) - physicalBonusPos - physicalBonusNeg;
		maxOffHandDamage = (maxOffHandDamage / percent) - physicalBonusPos - physicalBonusNeg;

		local offhandBaseDamage = (minOffHandDamage + maxOffHandDamage) * 0.5;
		local offhandFullDamage = (offhandBaseDamage + physicalBonusPos + physicalBonusNeg) * percent;
		local offhandDamagePerSecond = (max(offhandFullDamage,1) / offhandSpeed);
		local offhandTotalBonus = (offhandFullDamage - offhandBaseDamage);

		structAttack["Melee"]["OffHand"]={};
		structAttack["Melee"]["OffHand"]["AttackSpeed"]=wowroster.round(offhandSpeed,2);
		structAttack["Melee"]["OffHand"]["AttackDPS"]=offhandDamagePerSecond;--wowroster.round(stat.offhandDps,1);
		structAttack["Melee"]["OffHand"]["AttackSkill"]=offHandAttackBase+offHandAttackMod;
		structAttack["Melee"]["OffHand"]["AttackRating"]=strjoin(":", offHandAttackBase,offHandAttackMod,0);
	else
		structAttack["Melee"]["OffHand"]=nil;
	end

	local stat4 = getglobal(prefix.."4");
	local base,posBuff,negBuff;
	base,posBuff,negBuff = UnitAttackPower(unit);
	structAttack["Melee"]["AttackPower"] = strjoin(":", base,posBuff,negBuff);
	structAttack["Melee"]["AttackPowerDPS"]=wowroster.round(max((base+posBuff+negBuff), 0)/ATTACK_POWER_MAGIC_NUMBER,1);
	--structAttack["Melee"]["AttackPowerTooltip"]=stat4.tooltip2;
	base,posBuff,negBuff = GetCombatRating(CR_EXPERTISE),wowroster.round(GetCombatRatingBonus(CR_EXPERTISE),2),0;
	structAttack["Melee"]["Expertise"]=strjoin(":", base,posBuff,negBuff);
	base,posBuff,negBuff = GetCombatRating(CR_HIT_MELEE),wowroster.round(GetCombatRatingBonus(CR_HIT_MELEE),2),0;
	structAttack["Melee"]["HitRating"]=strjoin(":", base,posBuff,negBuff);
	base,posBuff,negBuff = GetCombatRating(CR_CRIT_MELEE),wowroster.round(GetCombatRatingBonus(CR_CRIT_MELEE),2),0;
	structAttack["Melee"]["CritRating"]=strjoin(":", base,posBuff,negBuff);
	base,posBuff,negBuff = GetCombatRating(CR_HASTE_MELEE),wowroster.round(GetCombatRatingBonus(CR_HASTE_MELEE),2),0;
	structAttack["Melee"]["HasteRating"]=strjoin(":", base,posBuff,negBuff);

	structAttack["Melee"]["CritChance"]=wowroster.round(GetCritChance(),2);

	if(unit=="player") then
		if ( not GetInventoryItemTexture(unit,18) and not UnitHasRelicSlot(unit)) then
			structAttack["Ranged"]=nil;
		else
			--UpdatePaperdollStats(prefix, "PLAYERSTAT_RANGED_COMBAT");
			local damageFrame = getglobal(prefix.."1");
			local damageFrameText = getglobal(prefix.."1".."StatText");

			if(PaperDollFrame.noRanged) then
				structAttack["Ranged"]=nil;
			else
				local rangedAttackSpeed, minDamage, maxDamage, physicalBonusPos, physicalBonusNeg, percent = UnitRangedDamage(unit);

				-- Round to the third decimal place (i.e. 99.9 percent)
				percent = math.floor(percent  * 10^3 + 0.5) / 10^3
				local displayMin = max(floor(minDamage),1);
				local displayMax = max(ceil(maxDamage),1);

				local baseDamage;
				local fullDamage;
				local totalBonus;
				local damagePerSecond;
				local tooltip;

				if ( HasWandEquipped() ) then
					baseDamage = (minDamage + maxDamage) * 0.5;
					fullDamage = baseDamage * percent;
					totalBonus = 0;
					if( rangedAttackSpeed == 0 ) then
						damagePerSecond = 0;
					else
						damagePerSecond = (max(fullDamage,1) / rangedAttackSpeed);
					end
					tooltip = max(floor(minDamage),1).." - "..max(ceil(maxDamage),1);
				else
					minDamage = (minDamage / percent) - physicalBonusPos - physicalBonusNeg;
					maxDamage = (maxDamage / percent) - physicalBonusPos - physicalBonusNeg;

					baseDamage = (minDamage + maxDamage) * 0.5;
					fullDamage = (baseDamage + physicalBonusPos + physicalBonusNeg) * percent;
					totalBonus = (fullDamage - baseDamage);
					if( rangedAttackSpeed == 0 ) then
						damagePerSecond = 0;
					else
						damagePerSecond = (max(fullDamage,1) / rangedAttackSpeed);
						damagePerSecond = math.floor(damagePerSecond  * 10^3 + 0.5) / 10^3
					end
					tooltip = max(floor(minDamage),1).." - "..max(ceil(maxDamage),1);
				end

				local rangedAttackSpeed,minDamage,maxDamage,physicalBonusPos,physicalBonusNeg,percent = UnitRangedDamage(unit);
				structAttack["Ranged"]={};
				structAttack["Ranged"]["AttackSpeed"]=wowroster.round(rangedAttackSpeed,2);
				structAttack["Ranged"]["AttackDPS"]=wowroster.round(damagePerSecond,1);
				structAttack["Ranged"]["AttackSkill"]=UnitRangedAttack(unit);

				local rangedAttackBase,rangedAttackMod = UnitRangedAttack(unit);
				structAttack["Ranged"]["AttackRating"]=strjoin(":", rangedAttackBase,rangedAttackMod,0);

				structAttack["Ranged"]["DamageRangeBase"]=strjoin(":", wowroster.Percent(minDamage),wowroster.Percent(maxDamage));
				structAttack["Ranged"]["DamageRangeBonus"]=totalBonus;

				base,posBuff,negBuff = GetCombatRating(CR_HIT_RANGED),wowroster.round(GetCombatRatingBonus(CR_HIT_RANGED),2),0;
				structAttack["Ranged"]["HitRating"]=strjoin(":", base,posBuff,negBuff);
				base,posBuff,negBuff = GetCombatRating(CR_CRIT_RANGED),wowroster.round(GetCombatRatingBonus(CR_CRIT_RANGED),2),0;
				structAttack["Ranged"]["CritRating"]=strjoin(":", base,posBuff,negBuff);
				base,posBuff,negBuff = GetCombatRating(CR_HASTE_RANGED),wowroster.round(GetCombatRatingBonus(CR_HASTE_RANGED),2),0;
				structAttack["Ranged"]["HasteRating"]=strjoin(":", base,posBuff,negBuff);
				structAttack["Ranged"]["CritChance"]=wowroster.round(GetRangedCritChance(),2);

				structAttack["Ranged"]["DamageRangeTooltip"]=tooltip;
				local base,posBuff,negBuff=UnitRangedAttackPower(unit);
				apDPS=base/ATTACK_POWER_MAGIC_NUMBER;
				structAttack["Ranged"]["AttackPower"] = strjoin(":", base,posBuff,negBuff);
				structAttack["Ranged"]["AttackPowerDPS"]=wowroster.round(apDPS,1);
				structAttack["Ranged"]["AttackPowerTooltip"]=format(RANGED_ATTACK_POWER_TOOLTIP,apDPS);
				structAttack["Ranged"]["HasWandEquipped"]=false;
			end
		end

		structAttack["Spell"] = {};
		structAttack["Spell"]["BonusHealing"] = GetSpellBonusHealing();

		local holySchool = 2;
		local minCrit = GetSpellCritChance(holySchool);
		structAttack["Spell"]["School"]={};
		structAttack["Spell"]["SchoolCrit"]={};
		for i=holySchool,MAX_SPELL_SCHOOLS do
			bonusDamage = GetSpellBonusDamage(i);
			spellCrit = GetSpellCritChance(i);
			minCrit = min(minCrit,spellCrit);
			structAttack["Spell"]["School"][UnitSchoolName[i]] = bonusDamage;
			structAttack["Spell"]["SchoolCrit"][UnitSchoolName[i]] = wowroster.round(spellCrit,2);
		end

		structAttack["Spell"]["CritChance"] = wowroster.round(minCrit,2);
		structAttack["Spell"]["BonusDamage"]=GetSpellBonusDamage(holySchool);
		base,posBuff,negBuff = GetCombatRating(CR_HIT_SPELL),wowroster.round(GetCombatRatingBonus(CR_HIT_SPELL),2),0;
		structAttack["Spell"]["HitRating"]=strjoin(":", base,posBuff,negBuff);
		base,posBuff,negBuff = GetCombatRating(CR_CRIT_SPELL),wowroster.round(GetCombatRatingBonus(CR_CRIT_SPELL),2),0;
		structAttack["Spell"]["CritRating"]=strjoin(":", base,posBuff,negBuff);
		base,posBuff,negBuff = GetCombatRating(CR_HASTE_SPELL),wowroster.round(GetCombatRatingBonus(CR_HASTE_SPELL),2),0;
		structAttack["Spell"]["HasteRating"]=strjoin(":", base,posBuff,negBuff);
		structAttack["Spell"]["Penetration"] = GetSpellPenetration();

		local base,casting = GetManaRegen();
		base = floor( (base * 5.0) + 0.5);
		casting = floor( (casting * 5.0) + 0.5);
		structAttack["Spell"]["ManaRegen"] = strjoin(":", base,casting);
	end
	PaperDollFrame_UpdateStats();
end

function wowroster.Percent(percent)
	percent = math.floor(percent  * 10^3 + 0.5) / 10^3
	return percent;
end

function wowroster:GetAttackRatingOld(structAttack,unit,prefix)
	if(not unit) then unit="pet"; end
	if(not prefix) then prefix="Pet"; end

	PaperDollFrame_SetDamage(PetDamageFrame, "Pet");
	PaperDollFrame_SetArmor(PetArmorFrame, "Pet");
	PaperDollFrame_SetAttackPower(PetAttackPowerFrame, "Pet");

	local damageFrame = getglobal(prefix.."DamageFrame");
	local damageText = getglobal(prefix.."DamageFrameStatText");
	local mainHandAttackBase,mainHandAttackMod = UnitAttackBothHands(unit);

	structAttack["Melee"]={};
	structAttack["Melee"]["MainHand"]={};
	structAttack["Melee"]["MainHand"]["AttackSpeed"]=wowroster.round(damageFrame.attackSpeed,2);
	structAttack["Melee"]["MainHand"]["AttackDPS"]=wowroster.round(damageFrame.dps,1);
	structAttack["Melee"]["MainHand"]["AttackRating"]=mainHandAttackBase+mainHandAttackMod;

	local tt=damageText:GetText();
	tt=wowroster.StripColor(tt);
	structAttack["Melee"]["MainHand"]["DamageRange"]=string.gsub(tt,"^(%d+)%s?-%s?(%d+)$","%1:%2");

	self:CharacterDamageFrame();
	local tt=wowroster.scantooltip2();
	tt=wowroster.StripColor(tt);
	structAttack["Melee"]["DamageRangeTooltip"]=tt;
	local base,posBuff,negBuff = UnitAttackPower(unit);
	apDPS=max((base+posBuff+negBuff),0)/ATTACK_POWER_MAGIC_NUMBER;
	structAttack["Melee"]["AttackPower"] = strjoin(":", base,posBuff,negBuff);
	structAttack["Melee"]["AttackPowerDPS"]=wowroster.round(apDPS,1);
	structAttack["Melee"]["AttackPowerTooltip"]=format(MELEE_ATTACK_POWER_TOOLTIP,apDPS);
end

--[GetBuffs]
function wowroster:GetBuffs(structBuffs,unit)
	unit = unit or "player";
	local idx=1;
	if(not structBuffs["Attributes"]) then structBuffs["Attributes"]={}; end
	local function strNil(str)
		if(str and str=="") then return nil
		else return str
		end
	end
	local function numNil(num)
		if(num and num<=1) then return nil
		else return num
		end
	end
	if(UnitBuff(unit,idx)) then
		structBuffs["Attributes"]["Buffs"]={};
		while(UnitBuff(unit,idx)) do
			local name,rank,iconTexture,count,duration,timeLeft = UnitBuff(unit,idx);
			
			GameTooltip:SetOwner(UIParent, 'ANCHOR_NONE')  
			GameTooltip:SetUnitBuff(unit,idx);
			tooltip = wowroster.scantooltip2()
			GameTooltip:Hide()
			structBuffs["Attributes"]["Buffs"][idx]={
				Name	= name,
				Rank	= strNil(rank),
				Count	= numNil(count),
				Icon	= wowroster.scanIcon(iconTexture),
				Tooltip	= tooltip};
			idx=idx+1
		end
	else
		structBuffs["Attributes"]["Buffs"]=nil;
	end
	idx=1;
	if(UnitDebuff(unit,idx)) then
		structBuffs["Attributes"]["Debuffs"]={};
		while(UnitDebuff(unit,idx)) do
			local name,rank,iconTexture,count,debuffType,duration,timeLeft = UnitDebuff(unit,idx);
			wowroster.tooltip:SetUnitDebuff(unit,idx);
			structBuffs["Attributes"]["Debuffs"][idx]={
				Name	= name,
				Rank	= strNil(rank),
				Count	= numNil(count),
				Icon	= wowroster.scanIcon(iconTexture),
				Tooltip	= wowroster.scantooltip2()};
			idx=idx+1
		end
	else
		structBuffs["Attributes"]["Debuffs"]=nil;
	end
end

function wowroster:SKILLS()
	local prof1, prof2, archaeology, fishing, cooking, firstAid = GetProfessions();
	--local name, icon, skillLevel, maxSkillLevel, numAbilities, spelloffset, skillLine, skillModifier = GetProfessionInfo(index)
	skill = {};
	skill["Secondary Skills"]={};
	skill["Professions"]={};

	if prof1 then
		local name, icon, skillLevel, maxSkillLevel, numAbilities, spelloffset, skillLine, skillModifier = GetProfessionInfo(prof1);
		skill["Professions"][name] = skillLevel..":"..maxSkillLevel;
	end

	if prof2 then
		local name2, icon2, skillLevel2, maxSkillLevel2, numAbilities2, spelloffset2, skillLine2, skillModifier2 = GetProfessionInfo(prof2);
		skill["Professions"][name2] = skillLevel2..":"..maxSkillLevel2;
		skill["Professions"]["Order"] = "1";
	end

	if archaeology then
		local namea, icona, skillLevela, maxSkillLevela, numAbilitiesa, spelloffseta, skillLinea, skillModifiera = GetProfessionInfo(archaeology);
		skill["Secondary Skills"][namea] = skillLevela..":"..maxSkillLevela;
		--skill["Secondary Skills"][namea]["test"] = skillLinea;
	end

	if fishing then
		local nameb, iconb, skillLevelb, maxSkillLevelb, numAbilitiesb, spelloffsetb, skillLineb, skillModifierb = GetProfessionInfo(fishing);
		skill["Secondary Skills"][nameb] = skillLevelb..":"..maxSkillLevelb;
	end

	if cooking then
		local namec, iconc, skillLevelc, maxSkillLevelc, numAbilitiesc, spelloffsetc, skillLinec, skillModifierc = GetProfessionInfo(cooking);
		skill["Secondary Skills"][namec] = skillLevelc..":"..maxSkillLevelc;
	end

	if firstAid then
		local named, icond, skillLeveld, maxSkillLeveld, numAbilitiesd, spelloffsetd, skillLined, skillModifierd = GetProfessionInfo(firstAid);
		skill["Secondary Skills"][named] = skillLeveld..":"..maxSkillLeveld;
		skill["Secondary Skills"]["Order"] = "2";
	end

	wowroster.db["Skills"] = skill;
end

function wowroster:SaveHeaders()
	local headerCount = 0		-- use a counter to avoid being bound to header names, which might not be unique.

	for i = GetNumTradeSkills(), 1, -1 do		-- 1st pass, expand all categories
		local _, skillType, _, isExpanded  = GetTradeSkillInfo(i)
		 if (skillType == "header") then
			headerCount = headerCount + 1
			if not isExpanded then
				ExpandTradeSkillSubClass(i)
				headersState[headerCount] = true
			end
		end
	end
end

function wowroster:ARCH_frame()

	if ( not wowroster.db["Archaeology"] ) then
		wowroster.db["Archaeology"]={};
	end

	local structArch=wowroster.db["Archaeology"];

	local numRaces = GetNumArchaeologyRaces();

	for i=1,numRaces do
		local name, description, rarity, icon, spellDescription, numSockets, bgTexture =  nil,nil,nil,nil,nil,nil,nil;

		--	•SetSelectedArtifact
		local RaceName, RaceCurrency, RaceTexture, RaceitemID	= GetArchaeologyRaceInfo(i);
		local aname, adescription, ararity, aicon, aspellDescription, anumSockets, abgTexture =  GetSelectedArtifactInfo();
		--wowroster:Print(" Races "..RaceName.." ");
		if( not structArch[RaceName] ) then
			structArch[RaceName] = {};
		end

		Artifactlist={};
		for artifactIndex=1,GetNumArtifactsByRace(i) do
			local complete = nil;
			local artifactName,artifactDesc,artifactRarity,artifactIcon,hoverDescription,keystoneCount,bgTexture,firstCompletionTime,completionCount=GetArtifactInfoByRace(i, artifactIndex);
			SetSelectedArtifact(i, artifactIndex);--SetSelectedArtifact();
			local name, description, rarity, icon, spellDescription, numSockets, bgTexture =  GetSelectedArtifactInfo();

			if (firstCompletionTime == 0) then
				ArtifactCurrent={};
				table.insert(ArtifactCurrent,{
					Name 			= artifactName,
					Desc 			= artifactDesc,
					hdesc			= hoverDescription,
					Rarity 			= artifactRarity,
					Count			= completionCount,
					First			= firstCompletionTime,
					Icon 			= wowroster.scanIcon(artifactIcon),
					SpellDesc 		= spellDescription,
					NumSockets 		= keystoneCount,
					BGTexture 		= wowroster.scanIcon(bgTexture),
				});
				complete = artifactName;
			end

			if (artifactName ~= complete) then
				table.insert(Artifactlist,{
					Name 			= artifactName,
					Desc 			= artifactDesc,
					hdesc			= hoverDescription,
					Rarity 			= artifactRarity,
					Count			= completionCount,
					First			= firstCompletionTime,
					Icon 			= wowroster.scanIcon(artifactIcon),
					SpellDesc 		= spellDescription,
					NumSockets 		= keystoneCount,
					BGTexture 		= wowroster.scanIcon(bgTexture),
				});
			end

		end

		structArch[RaceName] = {
			Name 			= RaceName,
			Currency 		= RaceCurrency,
			Texture 		= wowroster.scanIcon(RaceTexture),
			RaceID			= RaceitemID,
			NumArtifacts	= GetNumArtifactsByRace(i),
			Current			= ArtifactCurrent,
			Artifacts 		= Artifactlist,
		};
	end
end

--[[
	ok i got mad damn reagents are not working so heres what we are gona do....
	this will cache everything to your local cach run each time you open to cache
	new trades...
]]--
function wowroster:ReagentCache()

	if(scan_nextskill>=scan_numtradeskills) then
		wowroster:FinalizeCacheScan();
	else

		local skillName, skillType, numAvailable, isExpanded = GetTradeSkillInfo(scan_nextskill);
		if(skillName~=nil) then
			if(skillType~="header") then
				local numReagents = GetTradeSkillNumReagents(scan_nextskill);
				local skillLink = GetTradeSkillItemLink(scan_nextskill);
				local numMade = GetTradeSkillNumMade(scan_nextskill);
				for j=1, numReagents, 1 do
					local reagentName, reagentTexture, reagentCount, playerReagentCount = GetTradeSkillReagentInfo(scan_nextskill, j);
					local reagentLink = GetTradeSkillReagentItemLink(scan_nextskill,j);
					scan_reagentcount=scan_reagentcount+1;
				end
			end
		end
		scan_nextskill=scan_nextskill+1;
		wowroster:ReagentCache();
	end

	return;
end

function wowroster:BeginCache()
	wowroster:Print("Building Cache for "..scan_tradename.." ");

	scan_reagentcount=0;
	scan_nextskill=1;
	wowroster:ReagentCache();
	return;
end

function wowroster:FinalizeCacheScan()
	wowroster.db["Cached"][scan_tradename]=true;
	scan_tradename=nil;
	wowroster:Print("Cached "..scan_reagentcount.." Reagents");
	return

end


function wowroster:TRADE_SKILL_SHOW()
	if(IsTradeSkillLinked() or IsTradeSkillGuild()) then
		return nil;
	end

	local skillLineName,skillLineRank,skillLineMaxRank=GetTradeSkillLine();
	local numTradeSkills = GetNumTradeSkills();
	local cnt = 0;
	scan_tradename = skillLineName;

	if (IsAddOnLoaded("AdvancedTradeSkillWindow") ) then
		wowroster:Print("ATSW Detected, disabling cache");
		scan_cache = false;
	end

	if (not wowroster.db["Cached"][scan_tradename]) then
		wowroster.db["Cached"][scan_tradename]=false;

		-- build cache functions
		scan_numtradeskills = numTradeSkills;

		if (scan_cache) then
			wowroster:BeginCache();
		end
	end

	stat["Professions"][skillLineName] = {};
	if ( not wowroster.db["Professions"] ) then
		wowroster.db["Professions"]={};
	end
	if ( not wowroster.db["Professions"] ) then
		wowroster.db["Professions"]={};
	end

	local skills=wowroster.db["Professions"];
	stat["Professions"][skillLineName]["ct"] = 0;
	stat["Professions"][skillLineName]["errors"] = 0;

	if(not skills[skillLineName] ) then
		skills[skillLineName]={};
	end

	idxStart = 1;

	for idx=idxStart,numTradeSkills do
		skillName,skillType,_,_,serviceType=GetTradeSkillInfo(idx);
		if( skillName and skillName~="" ) then
			if( skillType=="header" ) then
				lastHeaderIdx = idx;
				skillHeader=skillName;
				if( not skills[skillLineName][skillHeader] ) then
					skills[skillLineName][skillHeader]={};
				end
				--pdb = skills[skillLineName][skillHeader];
			elseif( skillHeader ) then
				cooldown,numMade=nil,nil;
				numReagents = GetTradeSkillNumReagents(idx);
				description = GetTradeSkillDescription(idx)
				reagentlist={};
				reagentids={};
				reagentc = 0;
				local numReagents = GetTradeSkillNumReagents(idx);
				local skillLink = GetTradeSkillItemLink(idx);
				local numMade = GetTradeSkillNumMade(idx);
				for j=1, numReagents, 1 do
					local reagentName, reagentTexture, reagentCount, playerReagentCount = GetTradeSkillReagentInfo(idx, j);
					local reagentLink = GetTradeSkillReagentItemLink(idx,j);
					reagentID  = wowroster.GetReagentId( reagentLink );
					table.insert(reagentids,{Item=reagentID,Count=reagentCount,Link=reagentLink});
					if(reagentName) then
						itemName, itemLink, itemRarity, itemLevel, _, itemType, itemSubType, _,_, itemTexture,_ = GetItemInfo(reagentName);
						local ritemColor,_,_,_=wowroster.GetItemInfo(reagentLink);

					--	reagentID  = wowroster.GetReagentId( reagentLink );
						GameTooltip:SetOwner(UIParent, 'ANCHOR_NONE')
						GameTooltip:SetTradeSkillItem(idx,j); --SetTradeSkillItem(idx)
						tooltip = wowroster.scantooltip2();
						GameTooltip:Hide()
						color = wowroster.scanColor(ritemColor);
						itexture = wowroster.scanIcon(reagentTexture);
						table.insert(reagentlist,{Name=reagentName,Icon=itexture,Tooltip=tooltip,Item=reagentID,Color=color,Count=reagentCount,link=reagentLink});
						reagentc = reagentc+1;
					end
				end

				if (reagentc < numReagents) then
					--wowroster:Print("".. skillLineName ..":".. skillName .." partical scan. scan agian later");
					stat["Professions"][skillLineName]["errors"] = stat["Professions"][skillLineName]["errors"]+1;
				end

				GameTooltip:SetOwner(UIParent, 'ANCHOR_NONE')  
				GameTooltip:SetTradeSkillItem(idx) --SetTradeSkillItem(idx)
				tooltip1 = wowroster.scantooltip2()
				GameTooltip:Hide()
				tooltip = tooltip1 or "";
				local temColor,_,itemID,itemName=wowroster.GetItemInfo(GetTradeSkillItemLink(idx));
				local Icon = GetTradeSkillIcon(idx) or "";
				skills[skillLineName][skillHeader][skillName]={
					RecipeID  = wowroster.GetRecipeId( GetTradeSkillRecipeLink(idx) ) or "",
					Difficulty= skillType or "",
					Color = wowroster.scanColor(temColor) or "",
					numMade = GetTradeSkillNumMade(idx) or "",
					itemLink= GetTradeSkillItemLink(idx) or "",
					Reagentsnum = numReagents or "0",
					Reagents = reagentlist or "",
					ReagentIds = reagentids or "",
					Icon = wowroster.scanIcon(Icon) or "",
					desc  = description or "",
					Tooltip	= tooltip,
				};
				cnt = cnt+1;
			end
		end
	end
	stat["Professions"][skillLineName]["ct"] = cnt;
	--wowroster.db = skills
end

wowroster.scantooltip2 = function()
	local ttName = "GameTooltip";
	local isHTML = true

	if(GameTooltip and GameTooltip:NumLines() > 0) then
		local idx,ttFontStr,tmpbuff,ttText=nil,nil,nil,{};
		for idx=1,GameTooltip:NumLines() do
			tmpbuff=nil;
			ttFontStr=getglobal(ttName.."TextLeft"..idx);
			if(ttFontStr and ttFontStr:IsShown()) then
				tmpbuff=ttFontStr:GetText();
				if (ttFontStr) then
					tmpbuff=string.gsub(tmpbuff,"\n","<br>");
					tmpbuff=string.gsub(tmpbuff,"\r","");
				end
			end
			ttFontStr=getglobal(ttName.."TextRight"..idx);
			if(ttFontStr and ttFontStr:IsShown() and ttFontStr:GetText()) then
				if(tmpbuff) then
					tmpbuff=tmpbuff.."\t"..ttFontStr:GetText();
				else
					tmpbuff=ttFontStr:GetText();
				end
			end
			if(tmpbuff) then table.insert(ttText,tmpbuff); end
		end
		GameTooltip:ClearLines();
		if(isHTML) then
			return table.concat(ttText,"<br>");
		else
			return ttText;
		end
	end
	return "";
end

wowroster.GetReagentId = function(itemStr)
	if(itemStr) then 
		local _,_,itemid,_,_,_,_,_,_,_=string.find(itemStr,"([-%d]+):([-%d]+):([-%d]+):([-%d]+):([-%d]+):([-%d]+):([-%d]+):([-%d]+):([-%d]+):([-%d]+)");
		if( itemid ~= 0) then
			--wowroster:Print("has gem "..gid1.." "..gid2.." "..gid3.."");
			return itemid;
		else
			return nil;
		end
	end
	return nil;
end

wowroster.GetRecipeId = function(recipeStr)
	local id;
	if(recipeStr) then _,_,id = string.find(recipeStr, "|Henchant:(%d+)|h"); end
	return tonumber(id);
end

wowroster.GetItemID = function(itemStr)
	local id,rid;
	if(itemStr) then _,_,id,rid=string.find(itemStr,"|Hitem:(%d+):[-%d]+:[-%d]+:[-%d]+:[-%d]+:[-%d]+:([-%d]+):[-%d]+:[%d]+|h"); end
	return tonumber(id),tonumber(rid);
end

function wowroster:GetInventory()
	if(not wowrpref["scan"]["inventory"]) then
		wowroster.db["Inventory"]=nil;
		return;
	elseif(not wowroster.db["Inventory"]) then
		wowroster.db["Inventory"]={};
	end
	wowroster.db["Inventory"]={};
	local structInventory=wowroster.db["Inventory"];
	local containers={};
	for bagid=0,NUM_BAG_FRAMES do
		table.insert(containers,bagid);
	end
	if(HasKey and HasKey()) then
		table.insert(containers,KEYRING_CONTAINER);
	end
	for bagidx,bagid in pairs(containers) do
		bagidx=bagidx-1;
		if(not stat["Inventory"][bagidx] or not stat["Bag"][bagid]) then
			structInventory["Bag"..bagidx]=wowroster:ScanContainer("Inventory",bagidx,bagid);
		end
	end
	wowroster.db["timestamp"]["Inventory"]=time();
end

function wowroster:GetBank()
	if(not wowrpref["scan"]["bank"]) then
		wowroster.db["Bank"]=nil;
		return;
	elseif(not wowroster.db["Bank"]) then
		wowroster.db["Bank"]={};
	end

	local structBank=wowroster.db["Bank"];
	local containers={};
	table.insert(containers,BANK_CONTAINER);

	for bagid=1,NUM_BANKBAGSLOTS do
		table.insert(containers,bagid+NUM_BAG_SLOTS);
	end

	for bagidx,bagid in pairs(containers) do
		bagidx=bagidx-1;
		if(not stat["Bank"][bagidx] or not stat["Bag"][bagid]) then
			structBank["Bag"..bagidx]=wowroster:ScanContainer("Bank",bagidx,bagid);
		end
	end
	wowroster.db["timestamp"]["Bank"]=time();
end

function wowroster:ScanContainer(invgrp,bagidx,bagid)
	local itemColor,itemID,itemName,itemIcon,itemLink;

	local function numNil(num)
		if(wowrpref["fixquantity"] and num and num<=1) then return nil
		else return num
		end
	end

	if(bagid==0) then
		itemName=GetBagName(bagid);
		itemIcon="Button-Backpack-Up";
		if(not wowrpref["fixicon"]) then
			itemIcon="Interface\\Buttons\\"..itemIcon;
		end
		GameTooltip:SetText(""..itemName.."",_,_,_,_);
		GameTooltip:AddLine(format(CONTAINER_SLOTS,wowroster.GetContainerNumSlots(bagid),BAGSLOT));
	elseif(bagid==BANK_CONTAINER) then
		itemName = "Bank Contents";
	elseif(bagid==KEYRING_CONTAINER) then
		itemName = KEYRING;
		itemIcon="UI-Button-KeyRing";
		if(not wowrpref["fixicon"]) then
			itemIcon="Interface\\Buttons\\"..itemIcon;
		end
		GameTooltip:SetText(itemName);
		tooltip = wowroster.scantooltip2()
		GameTooltip:Hide()
	else
		local invID = ContainerIDToInventoryID(bagid)
		itemColor,_,itemID,itemName=wowroster.GetItemInfo( GetInventoryItemLink("player",ContainerIDToInventoryID(bagid)) );
		itemIcon=GetInventoryItemTexture("player",ContainerIDToInventoryID(bagid));	
		GameTooltip:SetOwner(UIParent, 'ANCHOR_NONE')  
		GameTooltip:SetInventoryItem("player",invID)
		tooltip = wowroster.scantooltip2()
		GameTooltip:Hide()
	end

	local bagSlot = GetContainerNumSlots(bagid)
	local bagInv = 0;
	if(bagSlot==nil or bagSlot==0) then
		stat[invgrp][bagidx]=nil
		return nil;
	end

	local container={
		Name	= itemName,
		Color	= wowroster.scanColor(itemColor),
		Slots	= wowroster.GetContainerNumSlots(bagid),
		Item	= itemID,
		Icon	= wowroster.scanIcon(itemIcon),
		Tooltip	= tooltip,
		Contents= {}
	};

	for slot=1,bagSlot do
		local itemLink=GetContainerItemLink(bagid,slot);
		if(itemLink) then
			local itemIcon,itemCount,_,_=GetContainerItemInfo(bagid,slot);
			container["Contents"][slot]=wowroster:ScanItemInfo(itemLink,itemIcon,itemCount,slot,bagid);
			bagInv=bagInv+1;
		end
	end

	stat["Bag"][bagid]=true;
	stat[invgrp][bagidx]={slot=bagSlot,inv=bagInv};
	return container
end

--[ScanTooltipOO]
wowroster.ScanTooltipOO = function(self)
	local tooltipname=wowroster.tooltip:GetName();

	if( not wowroster.tooltip:IsOwned(UIParent) ) then
		--wowroster:PrintDebug("Tooltip fix owner");
		wowroster.tooltip:SetOwner(UIParent,"ANCHOR_NONE");
	end
	return wowroster.ScanTooltip(tooltipname,wowroster.tooltip,true)
end

--[ScanTooltip] ttName,ttFrame,isHTML
wowroster.ScanTooltip = function(ttName,ttFrame,isHTML)
	if(ttFrame and ttFrame:NumLines()~=0) then
		local idx,ttFontStr,tmpbuff,ttText=nil,nil,nil,{};
		for idx=1,ttFrame:NumLines() do
			tmpbuff=nil;
			ttFontStr=getglobal(ttName.."TextLeft"..idx);
			if(ttFontStr and ttFontStr:IsShown()) then
				tmpbuff=ttFontStr:GetText();
				if (ttFontStr) then
					tmpbuff=string.gsub(tmpbuff,"\n","<br>");
					tmpbuff=string.gsub(tmpbuff,"\r","");
				end
			end
			ttFontStr=getglobal(ttName.."TextRight"..idx);
			if(ttFontStr and ttFontStr:IsShown() and ttFontStr:GetText()) then
				if(tmpbuff) then
					tmpbuff=tmpbuff.."\t"..ttFontStr:GetText();
				else
					tmpbuff=ttFontStr:GetText();
				end
			end
			if(tmpbuff) then table.insert(ttText,tmpbuff); end
		end
		ttFrame:ClearLines();
		if(isHTML) then return table.concat(ttText,"<br>");
		else return ttText; end
	end
	return nil
end

function wowroster:ScanItemInfo(itemstr,itemtexture,itemcount,slot,bagid)
	local function numNil(num)
		if(wowrpref["fixquantity"] and num and num<=1) then
			return nil
		else
			return num
		end
	end
	if(itemstr) then
		local itemColor,itemLink,itemID,itemName,itemTexture,itemType,itemSubType,itemLevel,itemReqLevel,itemRarity=wowroster.GetItemInfo(itemstr);
		if(not itemName or not itemColor) then
			itemName,itemColor=wowroster.GetItemInfoTT(self.tooltip);
		end
		slotx=nil;
		if(bagid=="player") then
			GameTooltip:SetOwner(UIParent, 'ANCHOR_NONE'); 
			GameTooltip:SetInventoryItem("player",slot);
			slotx = slot;
			tooltip = wowroster.scantooltip2();
			wowroster.tooltip:Hide();
			link = GetInventoryItemLink("player",slot);
		elseif(bagid==BANK_CONTAINER) then
			GameTooltip:SetOwner(UIParent, 'ANCHOR_NONE');  
			GameTooltip:SetInventoryItem("player",BankButtonIDToInvSlotID(slot));--SetBagItem(bagid,slot);
			slotx = BankButtonIDToInvSlotID(slot);
			tooltip = wowroster.scantooltip2();
			GameTooltip:Hide();
		elseif(bagid==KEYRING_CONTAINER) then
			GameTooltip:SetOwner(UIParent, 'ANCHOR_NONE');  
			GameTooltip:SetInventoryItem("player",KeyRingButtonIDToInvSlotID(slot));
			slotx = KeyRingButtonIDToInvSlotID(slot);
			tooltip = wowroster.scantooltip2();
			GameTooltip:Hide();
		else
			GameTooltip:SetOwner(UIParent, 'ANCHOR_NONE');  
			slotx = slot;
			GameTooltip:SetBagItem(bagid,slot);
			tooltip = wowroster.scantooltip2();
			GameTooltip:Hide();
		end

		local itemBlock={
			Name	= itemName,
			Item	= itemID,
			Link	= link,
			Color	= wowroster.scanColor(itemColor),
			Rarity	= itemRarity,
			Quantity= numNil(itemcount),
			Icon	= wowroster.scanIcon(itemtexture or itemTexture),
			Tooltip	= tooltip,
			Type	= itemType,
			SubType	= itemSubType,
			iLevel	= itemLevel,
			reqLevel= itemReqLevel,
		};

		if( wowroster.ItemHasGem(itemID) ) then
			--wowroster:Print("gem scan "..slot.."-"..slotx.."");
			local gem1, gem2, gem3 = GetInventoryItemGems(slotx);
			local _,_,_,_,gid1,gid2,gid3,_,_,_=string.find(itemID,"([-%d]+):([-%d]+):([-%d]+):([-%d]+):([-%d]+):([-%d]+):([-%d]+):([-%d]+):([-%d]+):([-%d]+)");
			itemBlock["Gem"] = {};

			if (gid1 ~= '0') then
				local itemColor,itemLink,itemID,itemName,itemTexture,itemType,itemSubType,itemLevel,itemReqLevel,itemRarity=wowroster.GetItemInfo(gem1);

				if (itemLink)then
					GameTooltip:SetOwner(UIParent, 'ANCHOR_NONE');
					GameTooltip:SetHyperlink(itemLink);
					tooltip = wowroster.scantooltip2();
					GameTooltip:Hide();
				else
					tooltip = nil;
				end
				itemBlock["Gem"][1]={ --wowroster:ScanItemInfo(gemItemLink,nil,1,nil,nil);
					Name = itemName,
					Item = gem1,
					gemID = gid1,
					Color = wowroster.scanColor(itemColor),
					Link = itemLink,
					Tooltip = tooltip,
					Icon = wowroster.scanIcon(itemTexture),
				};
			end

			if (gid2 ~= '0') then
				local itemColor,itemLink,itemID,itemName,itemTexture,itemType,itemSubType,itemLevel,itemReqLevel,itemRarity=wowroster.GetItemInfo(gem2);
				if (itemLink)then
				GameTooltip:SetOwner(UIParent, 'ANCHOR_NONE');
				GameTooltip:SetHyperlink(itemLink);
				tooltip = wowroster.scantooltip2();
				GameTooltip:Hide();
				else
					tooltip = nil;
				end
				itemBlock["Gem"][2]={ --wowroster:ScanItemInfo(gemItemLink,nil,1,nil,nil);
					Name = itemName,
					Item = gem2,
					gemID = gid2,
					Color = wowroster.scanColor(itemColor),
					Link = itemLink,
					Tooltip = tooltip,
					Icon = wowroster.scanIcon(itemTexture),
				};
			end

			if (gid3 ~= '0') then

				local itemColor,itemLink,itemID,itemName,itemTexture,itemType,itemSubType,itemLevel,itemReqLevel,itemRarity=wowroster.GetItemInfo(gem3);					
				if (itemLink)then
				GameTooltip:SetOwner(UIParent, 'ANCHOR_NONE');
				GameTooltip:SetHyperlink(itemLink);
				tooltip = wowroster.scantooltip2();
				GameTooltip:Hide();
				else
					tooltip = nil;
				end
				itemBlock["Gem"][3]={ --wowroster:ScanItemInfo(gemItemLink,nil,1,nil,nil);
					Name = itemName,
					Item = gem3,
					gemID = gid3,
					Color = wowroster.scanColor(itemColor),
					Link = itemLink,
					Tooltip = tooltip,
					Icon = wowroster.scanIcon(itemTexture),
				};
			end
		end
		return itemBlock;
	end
	return nil;
end

--[ItemHasGem] itemStr
wowroster.ItemHasGem = function(itemStr)
	local gem1name, gem1Link = GetItemGem(itemStr, 1)

	if(itemStr) then 
		local _,_,_,_,gid1,gid2,gid3,_,_,_=string.find(itemStr,"([-%d]+):([-%d]+):([-%d]+):([-%d]+):([-%d]+):([-%d]+):([-%d]+):([-%d]+):([-%d]+):([-%d]+)");

		if( gid1 and gid2 and gid3 and gid1+gid2+gid3 ~= 0) then
			return true;
		else
			return nil;
		end
	end
	return nil;
end

--[[
	begin spellbook functions
]]--
function wowroster:GetSpellBook()
	if(not wowrpref["scan"]["spells"]) then
		self.db["SpellBook"]=nil;
		return;
	end
	if ( not wowroster.db["SpellBook"] ) then
		wowroster.db["SpellBook"]={};
	end
	if ( not wowroster.db["timestamp"]["SpellBook"] ) then
		wowroster.db["timestamp"]["SpellBook"] = {};
	end

	local Spelltotal = 0
	local structSpell=wowroster.db["SpellBook"];
	for spellTab=1,GetNumSpellTabs() do
		local spellTabname,spellTabtexture,offset,numSpells=GetSpellTabInfo(spellTab);
		local cnt=0;
		if(not stat["SpellBook"][spellTabname] or stat["SpellBook"][spellTabname]~=numSpells) then
			if (not spellTabtexture) then spellTabtexture = "achievement_guildperk_fasttrack_rank2"; end
			structSpell[spellTabname]={
				Icon	= wowroster.scanIcon(spellTabtexture),
				Spells	= {},
			};
			stat["SpellBook"][spellTabname]=0;
			cnt=0;
			for spellId=1+offset,numSpells+offset do
				local spellName, spellRank, icon, powerCost, isFunnel, powerType, castingTime, minRange, maxRange = GetSpellInfo(spellId,BOOKTYPE_SPELL)
				if ( spellName ) then
					structSpell[spellTabname]["Spells"][spellName] = wowroster:ScanSpellInfo(spellId,BOOKTYPE_SPELL);
					cnt=cnt+1;
					Spelltotal = Spelltotal+1;
				end
			end
			stat["SpellBook"][spellTabname]=cnt;
			structSpell[spellTabname]["Count"]=numSpells;
		end
		wowroster.db["timestamp"]["SpellBook"]=time();
	end
end

function wowroster:ScanSpellInfo(idx,bookType)
	if(not idx or not bookType ) then return end

	local spellName, spellRank, icon, powerCost, isFunnel, powerType, castingTime, minRange, maxRange = GetSpellInfo(idx,bookType);

	GameTooltip:SetOwner(UIParent, 'ANCHOR_NONE')  
	GameTooltip:SetSpellBookItem(idx,bookType);
	tooltip = wowroster.scantooltip2()
	GameTooltip:Hide()

	if( spellRank and spellRank == "" ) then
		spellRank = nil;
	end
	local structSpellInfo={
		SpellId	= wowroster.GetSpellID( GetSpellLink( spellName,spellRank ) ),
		Icon	= wowroster.scanIcon(icon),
		Rank	= spellRank,
		Tooltip	= tooltip
	};
	return structSpellInfo;
end

wowroster.GetSpellID = function(spellStr)
	local id;
	if(spellStr) then _,_,id=string.find(spellStr,"|Hspell:(%d+)|h"); end
	return tonumber(id);
end


--[[
we are gona scan for achievement ids... because i want them..
]]--
function wowroster:Achi()

	wowroster.db["Achi"]=nil;
	wowroster.db["Crit"]=nil;
	local cats = GetCategoryList()
	local achievementID, achCompleted
	local prevID
	local structAchi={};
	local structCrit={};
	
	for _, categoryID in ipairs(cats) do
		
		local pname, parentID, flags = GetCategoryInfo(categoryID)
		structAchi[categoryID] = {};
		structAchi[categoryID] = {
					pID = parentID,
					name = pname,
					cID = categoryID,
					flages = flags
			};
		--structAchi[pname][categoryID] = {};
		for i = 1, GetCategoryNumAchievements(categoryID) do
			local achievementID,aname,points,achCompleted,month,day,year,description,flags,icon,rewardText,isGuildAch = GetAchievementInfo(categoryID, i);
			structCrit[achievementID] ={};
			structAchi[categoryID][achievementID] = {
					achID = achievementID,	
					desc=description,
					icon = wowroster.scanIcon(icon),
					point = points,
					name = aname or ""
			};
			
--			
			local count = GetAchievementNumCriteria(achievementID)
			for c = 1, count do
			
			local description,type,comp,quant,reqQuant,_,flags,assetID,quantString,criteriaID = GetAchievementCriteriaInfo(achievementID, c)
				structCrit[achievementID][criteriaID] = {
					cid=criteriaID,
					desc=description,
					type=type,
					rquantity=reqquant,
					c_string=quantString					
				};
			end
	--]]--		
		end
	end
	wowroster.db["Achi"] = structAchi;
	wowroster.db["Crit"] = structCrit;
end

--[[
	begin talent data 
]]--
function wowroster:GetTalents(unit)
	if(not wowrpref["scan"]["talents"] or UnitLevel("player") < 10 ) then
		wowroster.db["Talents"]=nil; return;
	end
	unit = unit or "player";

	local numTabs,numPts,state,petName;

	local structTalent={};
	local structTalents={};
	atg = GetActiveTalentGroup(false, "player");
	if (atg == 2) then
		TalentGroup = 1;
	else
		TalentGroup = 2;
	end

	stat["Talents"] = {};
	if ( unit == "pet" ) then
		petName = UnitName("pet");
		numPts = GetUnspentTalentPoints(false, true, TlentGroup);
		numTabs = 1;
		wowroster.db["Pets"][petName]["TalentPointsUsed"]=nil;
		wowroster.db["Pets"][petName]["TalentPoints"]=numPts;
		state = "PetTalents";
	else
		numPts =  GetUnspentTalentPoints(false, false, TalentGroup)--UnitCharacterPoints("player");
		numTalentGroups = GetNumTalentGroups(false, "player");
		numTabs=GetNumTalentTabs();
		wowroster.db["TalentPoints"]=numPts;
		state = "Talents";
	end

	local tabName,iconTexture,pointsSpent,background;

	local cnt=0;
	local nameTalent,iconTexture,tier,column,currentRank,maxRank,isExceptional,meetsPrereq;
	for tabIndex=1,numTabs do
		Tabid, tabName, desc, iconTexture, pointsSpent, background, previewPoints, isUnlocked = GetTalentTabInfo(tabIndex,nil,unit=="pet",nil);
		stat["Talents"][tabName] = 0;
		if(not wowrpref["fixicon"]) then
			background="Interface\\TalentFrame\\"..background;
		end

		structTalent[tabName]={
			Background=wowroster.scanIcon(background),
			PointsSpent=pointsSpent,
			Desc = desc,
			Unlocked=isUnlocked,
			Order=tabIndex
		};

		for talentIndex=1,GetNumTalents(tabIndex,nil,unit=="pet") do
			name,iconTexture,tier,column,rank,maxRank,isExceptional,meetsPrereq,previewRank,meetsPreviewPrereq=GetTalentInfo(tabIndex,talentIndex,nil,unit=="pet",nil);
			if( name ) then
				structTalent[tabName][name]={
					Rank	= strjoin(":", rank,maxRank),
					Location= strjoin(":", tier,column),
				};
			end
		end
		stat["Talents"][tabName] = pointsSpent;
	end

	if ( unit == "pet" ) then
		wowroster.db["Pets"][petName]["Talents"]=structTalent;
	else
		wowroster.db["Talents"]=structTalent;
	end

	if (numTalentGroups==2) then
		wowroster.db["DualSpec"]={}
		if(not wowrpref["scan"]["dstalents"] or UnitLevel("player") < 10 ) then
			wowroster.db["DualSpec"]["Talents"]=nil; return;
		end
		stat["DSTalents"] = {};
		wowroster.db["DualSpec"] = {};
		local tabName,iconTexture,pointsSpent,background;

		local nameTalent, iconTexture, tier, column, currentRank, maxRank, isExceptional, meetsPrereq, previewRank, meetsPreviewPrereq;
		for tabIndex=1,numTabs do
			Tabid, tabName, desc, iconTexture, pointsSpent, background, previewPoints, isUnlocked = GetTalentTabInfo(tabIndex,nil,unit=="pet", TalentGroup);
			stat["DSTalents"][tabName] = 0;
			if(not wowrpref["fixicon"]) then
				background="Interface\\TalentFrame\\"..background; end
				structTalents[tabName]={
					Background=wowroster.scanIcon(background),
					PointsSpent=pointsSpent,
					Desc = desc,
					Unlocked=isUnlocked,
					Order=tabIndex
				};
			for talentIndex=1,GetNumTalents(tabIndex,nil,unit=="pet") do
			nameTalent,iconTexture,tier,column,currentRank,maxRank,isExceptional,meetsPrereq,_,_q=GetTalentInfo(tabIndex, talentIndex, nil, unit=="pet", TalentGroup);
				if(nameTalent) then
					structTalents[tabName][nameTalent]={
						Rank	= strjoin(":", currentRank,maxRank),
						Location= strjoin(":", tier,column),
					};
				end
			end
			stat["DSTalents"][tabName] = pointsSpent;
		end
		wowroster.db["DualSpec"]["Talents"]=structTalents;
	end
end

--[GetItemInfo] itemStr
wowroster.GetItemInfo = function(itemStr)
	if(itemStr) then
		local itemColor,itemID;
		local itemName,itemLink,itemRarity,itemLevel,itemReqLevel,itemType,itemSubType,itemStackCount,itemEquipLoc,invTexture = GetItemInfo(itemStr);
		if(itemLink) then
			_,_,itemColor,itemID=string.find(itemLink,"|c(%x+)|Hitem:([-%d:]+)|h%[.-%]|h");
		end
		return itemColor,itemLink,itemID,itemName,invTexture,itemType,itemSubType,itemLevel,itemReqLevel,itemRarity;
	end
	return nil;
end

--[GetItemInfoTT] tooltip
wowroster.GetItemInfoTT = function(tooltip)
	local ttName,ttFrame
	if( tooltip ) then
		if(type(tooltip)=="string") then
			ttName=tooltip;
			ttFrame=getglobal(tooltip);
		elseif(type(tooltip)=="table" and tooltip:IsObjectType("GameTooltip")) then
			ttName=UIParent.GetName(tooltip);
			ttFrame=tooltip;
		end
	end
	local nTT,cTT,r,g,b;
	if(ttName==nil) then return end

	ttText=getglobal(ttName.."TextLeft1");

	if(ttText) then
		nTT=ttText:GetText();
	end
	if(nTT) then
		r,g,b=ttText:GetTextColor();
		cTT=string.format("ff%02x%02x%02x",r*256,g*256,b*256);
	end
	return nTT,cTT;
end

wowroster.GetContainerNumSlots = function(bagID)
	if(bagID==KEYRING_CONTAINER) then
		return GetKeyRingSize();
	else
		return GetContainerNumSlots(bagID);
	end
end

wowroster.scanIcon = function(str)
	if(not str) then return nil; end
	return table.remove({ strsplit("\\", str) });
end

wowroster.GetItemId = function(itemStr)
	if(itemStr) then 
		local _,_,itemid,_,gid1,gid2,gid3,_,_,_=string.find(itemStr,"([-%d]+):([-%d]+):([-%d]+):([-%d]+):([-%d]+):([-%d]+):([-%d]+):([-%d]+):([-%d]+):([-%d]+)");
		if( itemid ~= 0) then
		--wowroster:Print("has gem "..gid1.." "..gid2.." "..gid3.."");
			return itemid;
		else
			return nil;
		end
	end
	return nil;
end

wowroster.scanColor = function(str)
	if(not str) then return nil; end
	local _,_,c = string.find(str,"%x%x(%x%x%x%x%x%x)");
	return c
end

--[[########################################################
--## queue functions
--######################################################--]]
function wowroster.qInsert(queue,tbl,pri)
	local q = true;
	for idx,que in pairs( queue ) do
		if(tbl[1]==que[1] and tbl[2]==que[2] and tbl[3]==que[3] and tbl[4]==que[4] and tbl[5]==que[5] and tbl[6]==que[6]) then
			q=nil; break;
		end
	end
	if(q) then 
		if(not pri or pri > table.getn(queue)) then
			pri = table.getn(queue)+1;
		end
		table.insert(queue,pri,tbl);
	end
end

function wowroster.qProcess(queue,e)
	if(not queue or table.getn(queue) == 0) then return end;
	if(not e) then return end;
	for idx,tab in pairs( queue ) do
		if(e==tab[1]) then
			tab = table.remove(queue,idx);
			local f,a1,a2
			f = tab[2];
			f(tab[3],tab[4],tab[5],tab[6]);
			--break;
			return true;
		end
	end
	return nil;
end

wowroster.parseMoney = function(money)
	local gold,silver,copper;
	local COPPER_PER_GOLD=COPPER_PER_SILVER * SILVER_PER_GOLD;
	gold=floor(money/COPPER_PER_GOLD);
		money=mod(money,COPPER_PER_GOLD);
	silver=floor(money/COPPER_PER_SILVER);
		copper=mod(money,COPPER_PER_SILVER);
	return gold,silver,copper;
end

--[wowroster.round](num,[digit])
wowroster.round = function(num,digit)
	if(not tonumber(num)) then return nil; end
	if(digit==nil) then digit=0; end
--	local shift=10^digit;
--	return floor( num*shift + 0.5 ) / shift;
	if(num==0) then return num; end
	local fmt
	if(digit<10) then fmt="%.0"..digit.."f";
	else fmt="%."..digit.."f"; end
	return format(fmt,num);
end

--[Str2Ary] str
wowroster.Str2Ary = function(str)
	local tab={};
	str = strtrim(str);
	while( str and str ~="" ) do
		local word,string;
		if( strfind(str, '^|c.+|r') ) then
			_,_,word,string = strfind( str, '^(|c.+|r)(.*)');
		elseif( strfind(str, '^"[^"]+"') ) then
			_,_,word,string = strfind( str, '^"([^"]+)"(.*)');
		else
			_,_,word,string = strfind( str, '^(%S+)(.*)');
		end
		if( word ) then
			table.insert(tab,word);
		end
		if( string ) then
			string=strtrim(string);
		end
		str = string;
	end
	return tab;
end

--[Str2Abbr] str
wowroster.Str2Abbr = function(str)
	local abbr='';
	local function S2Ahelper(word) abbr=abbr..string.sub(word,1,1) end
	if not string.find(string.gsub(str,"%w+",S2Ahelper),"%S") then return abbr end
end

--[Arg2Tab] arg:key.1,key.n,val.1,val.n
wowroster.Arg2Tab = function(...)
	local tab={};
	local split=floor( select("#",...) /2);
	for i=1,split do tab[select(i,...)]=select(i+split,...); end
	return tab;
end

--[Arg2Ary] arg:arg.1,arg.n
wowroster.Arg2Ary = function(...)
	local tab={};
	for i=1,select("#",...) do tab[i]=select(i,...); end
	return tab; 
end

wowroster.StringColorize = function(color,msg)
	if(color and msg) then
		return "|cff"..color..msg.."|r";
	end
end

--[function] str
wowroster.version = function()
	local version,_,_ = GetBuildInfo();
	local _,_,version,major,minor=string.find(version,"(%d+).(%d+).(%d+)");
	return tonumber(version),tonumber(major),tonumber(minor);
end

--[GetQuestID] questStr
wowroster.GetQuestID = function(questStr)
	local id,lvl;
	if(questStr) then _,_,id,lvl=string.find(questStr,"|Hquest:(%d+):([-%d]+)|h"); end
	return tonumber(id);
end

wowroster.versionkey = function()
	local version,buildnum,_ = GetBuildInfo();
	return strjoin(":", wowroster.GetSystem(),version,buildnum);
end

--[function] str
wowroster.GetSystem = function()
	local _,_,sys=string.find(GetCVar("realmList"),"^[%a.]-(%a+).%a+.%a+.%a+$");
	if(not sys) then sys="" end return sys;
end

function wowroster:Print(...)
	print("|cff33ff99WoWR-P|r:", ...)
end
