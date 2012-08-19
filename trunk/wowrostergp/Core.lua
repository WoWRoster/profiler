
--wowrostergp = LibStub("AceAddon-3.0"):NewAddon("wowrostergp", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0")
wowrostergp = LibStub("AceAddon-3.0"):NewAddon("wowrostergp", "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0")
local acr = LibStub("AceConfigRegistry-3.0")
local state = {};
local acd = LibStub("AceConfigDialog-3.0")
local ac = LibStub("AceConfig-3.0")
local f = CreateFrame('GameTooltip', 'MyTooltip', UIParent, 'GameTooltipTemplate') 

local LDB = LibStub("LibDataBroker-1.1", true)
local LDBIcon = LibStub("LibDBIcon-1.0", true)


local gnews = {"Player Achievements","Instances","Item Loots","Items Crafted","Items Purchesed","Guild Level","Player Level","opps1","opps2"};gnews[0]="Guild Achievements";gnews["-1"]="Guild Achievements";

if(not wowroster) then wowroster={}; end
if(not wowroster.colorTitle) then wowroster.colorTitle="909090"; end
if(not wowroster.colorGreen) then wowroster.colorGreen="00cc00"; end
if(not wowroster.colorRed)   then wowroster.colorRed  ="ff0000"; end

--wowrostergp.sv = {};
local Guild_name = nil;
local Server = nil;
local stat = {
	_server=GetRealmName(),
	_player=UnitName("player"),
	_guild=GetGuildInfo("player"),
	_officer=CanViewOfficerNote(),
	_guilded=IsInGuild(),
	_guildInfo=nil,
	_loaded,
	_time,
	_guildNum,
	Vault={},
	Vaultavl=true,
};

local function findPanel(name, parent)
	for i, button in next, InterfaceOptionsFrameAddOns.buttons do
		if button.element then
			if name and button.element.name == name then return button
			elseif parent and button.element.parent == parent then return button
			end
		end
	end
end

function wowrostergp:OnEnable()
	self:RegisterEvent("GUILDBANKFRAME_OPENED");
	self:RegisterEvent("ADDON_LOADED");
	wowrostergp:Print("Hello, WoWRoster Guild Profiler Enabled and Loaded! |cffff3399["..wowroster.betar.."]|r");
	wowrostergp:Print("Open the menu, click Interface, then go to the Addons tab to configure");
	wowrostergp:InitState();
end

function wowrostergp:ADDON_LOADED(arg1,arg2)
	--wowrostergp:Print(" --: "..arg1.." - "..arg2.."");
	if arg2 == "Blizzard_GuildUI" then
		wowrostergp:ButtonHandler();
	end
end

function wowrostergp:ButtonHandler()
	self.buttons = {}
	local button = CreateFrame("Button", "GuildProfilerbtm", GuildFrame, "UIPanelButtonTemplate");
	button.tooltip = "Save guild data"--L["Click to export your Guild Profile!"]
	button.startTooltip = button.tooltip
	button:SetPoint("TOPRIGHT", GuildFrame, "TOPRIGHT", -25, 0)
	button:SetWidth(50)
	button:SetHeight(18)
	button:SetText("Save") --L["save"])
	button:SetScript("OnEnter", showTooltip)
	button:SetScript("OnLeave", hideTooltip)
	button:SetScript("OnClick", function(self)wowrostergp:gpexport()end )
	self.buttons.save = button
end

function wowrostergp:OnDisable()
	LibStub("AceDB-3.0"):New("cpProfile",wowrostergp.sv)
end

function wowrostergp:OnInitialize()
	wowrostergp:InitState();
	self.sv = LibStub("AceDB-3.0"):New("cpProfile");
	local function profileUpdate()
		addon:SendMessage("scan updated");
	end
	wowrostergp:InitProfile();

end

function wowrostergp:InitState()
	Guild_name = GetGuildInfo("player");
	Server = GetRealmName();

	stat={
		_server=GetRealmName(),
		_player=UnitName("player"),
		_guild=GetGuildInfo("player"),
		_officer=CanViewOfficerNote(),
		_guilded=IsInGuild(),
		_guildInfo=nil,
		_loaded,
		_time,
		_guildNum,
		Vault={},
		Vaultavl=false,
	};
end

function wowrostergp:gpexport()
	wowrostergp:InitProfile();
	wowrostergp:ScanGuildMembers();
	wowrostergp:GetGuildInfo();
	wowrostergp:Scannews();
	wowrostergp:ScanGuildControl();
	wowrostergp:ScanGuildEventLog()
	if(wowrpref["guild"]["trades"]) then
		wowrostergp:ScanProfessions();
	end

	msg = stat["_guild"];
	wowrostergp:Print(msg);
	msg = "Vault:";
	tsort={};
	table.foreach(stat["Vault"], function(k,v) table.insert(tsort,k) end );
		table.sort(tsort);
		if(table.getn(tsort)==0) then
			msg=msg..wowroster.StringColorize(wowroster.colorRed," not scanned")..".  - open your guild vault to scan";
		else
		for _,item in pairs(tsort) do
			msg=msg .. " " .. item.."-"..stat["Vault"][item]["inv"].."/"..stat["Vault"][item]["slot"];
		end
	end

	wowrostergp:Print(msg);
	msg = "Members: "..stat["_guildNum"].." ";
	wowrostergp:Print(msg);
end

function wowrostergp:InitProfile()
	if ( not(Guild_name) ) then
		Guild_name = GetGuildInfo("player");
	end
	if ( not(Guild_name) ) then
		return stat["_loaded"];
	end

	if( not cpProfile ) then
		cpProfile={}; 
	end
	if( not cpProfile[Server] ) then
		cpProfile[Server]={}; 
	end
	if( not cpProfile[Server]["Guild"] ) then
		cpProfile[Server]["Guild"]={}; 
	end
	if( not cpProfile[Server]["Guild"][Guild_name] ) then
		cpProfile[Server]["Guild"][Guild_name]={}; 
	end

	self.sv = cpProfile[Server]["Guild"][Guild_name];
	local currentXP, nextLevelXP, dailyXP, maxDailyXP = UnitGetGuildXP("player");
	local nextxp = nextLevelXP + currentXP;
	if( self.sv ) then
		wowrostergp:Print("Guild profile started");

		self.sv["GPversion"]	= "1.0.0";
		self.sv["CPprovider"]	= "wowr";
		self.sv["DBversion"]	= "3.1";
		self.sv["GuildName"]	= Guild_name;
		self.sv["Server"]		= Server;
		self.sv["Locale"]		= GetLocale();
		self.sv["GuildXP"]		= currentXP..":"..nextxp;
		self.sv["GuildXPCap"]	= dailyXP..":"..maxDailyXP;
		self.sv["GuildLevel"]	= GetGuildLevel();
		self.sv["FactionEn"],self.sv["Faction"]=UnitFactionGroup("player");
		self.sv["timestamp"] = {};
		wowrostergp:UpdateDate();
		stat["_loaded"] = true;
	end
	return stat["_loaded"];
end




function wowrostergp:ScanGuildEventLog()
	if(not wowrostergp.sv["EventLog"]) then
		wowrostergp.sv["EventLog"]={};
	end
	local db = wowrostergp.sv["EventLog"];
	local type, player1, player2, rank, year, month, day, hour;
	local numEvents = GetNumGuildEvents();
	local time=time();

--RPGOGP:PrintDebug("EventLog",numEvents,table.getn(db));
	if(numEvents >= table.getn(db)) then
		for idx=1, numEvents, 1 do
			type, player1, player2, rank, year, month, day, hour = GetGuildEventInfo(idx);
			if ( not player1 ) then
				player1 = UNKNOWN;
			end
			if ( not player2 ) then
				player2 = UNKNOWN;
			end
			db[idx] = {
				Type	= type,
				Player1	= player1,
				Player2	= player2,
				Rank	= rank,
				Time	= time,
				LogTime	= strjoin(":",year, month, day, hour),
			};
		end
	else
		--rpgo.qInsert(RPGOGP.queue, {"GUILD_EVENT_LOG_UPDATE",RPGOGP.ScanGuildEventLog} );
		QueryGuildEventLog();
	end
end



function wowrostergp:UpdateDate()
	if(not wowrostergp.sv) then return; end;

	local struct=wowrostergp.sv;
	if ( not struct["timestamp"] ) then struct["timestamp"]={}; end;
	local timestamp = time();
	local currHour,currMinute=GetGameTime();
	struct["timestamp"]={};
	struct["timestamp"]["init"]={};
	struct["timestamp"]["init"]["TimeStamp"]=timestamp;
	struct["timestamp"]["init"]["Date"]=date("%Y-%m-%d %H:%M:%S",timestamp);
	struct["timestamp"]["init"]["DateUTC"]=date("!%Y-%m-%d %H:%M:%S",timestamp);
	struct["timestamp"]["init"]["ServerTime"]=format("%02d:%02d",currHour,currMinute);
	struct["timestamp"]["init"]["datakey"]=wowrostergp.versionkey();
end

wowrostergp.versionkey = function()
	local version,buildnum,_ = GetBuildInfo();
	return strjoin(":", wowrostergp.GetSystem(),version,buildnum);
end

wowrostergp.GetSystem = function()
	local _,_,sys=string.find(GetCVar("realmList"),"^[%a.]-(%a+).%a+.%a+.%a+$");
	if(not sys) then sys="" end return sys;
end

function wowrostergp:GUILDBANKFRAME_OPENED()
	if(wowrpref["guild"]["vault"]) then
		numTabs = GetNumGuildBankTabs();
		for tab=1, numTabs do
			QueryGuildBankTab(tab);
		end
		wowrostergp:ScanGuildBank();
	end
end

function wowrostergp:GetGuildInfo()
	if( not IsInGuild() ) then
		stat["_guilded"]=false;
		return;
	end
	strict = {};
	stat["_guild"] = GetGuildInfo("player");
	local numGuildMembers, onlineMembers = GetNumGuildMembers();

	QueryGuildEventLog();

	stat["_guilded"]=true;
	strict["Info"] = GetGuildInfoText();
	strict["FactionEn"],strict["Faction"] = UnitFactionGroup("player");
	if(numGuildMembers~=0) then
		strict["NumMembers"]=numGuildMembers;
		wowrostergp:ScanGuildMembers(numGuildMembers);
		stat["_guildNum"]=numGuildMembers;
	end
	wowrostergp:ScanGuildMOTD();
	strict["ScanInfo"] = {
		Character = stat["_player"],
		IsGuildLeader = (IsGuildLeader()==1 or false),
		HasOfficerNote = (stat["_officer"]==1 or false)
	};
end

function wowrostergp:ScanGuildMOTD()
	wowrostergp.sv["Motd"] = GetGuildRosterMOTD();
end

function wowrostergp:ScanGuildMembers(numMembers)
	stat["_officer"] = CanViewOfficerNote();
	--if(numMembers > 0 and (stat["_guildNum"]~=numMembers)) then
	local numMembers, onlineMembers = GetNumGuildMembers();
	local showOfflineTemp=GetGuildRosterShowOffline();
	SetGuildRosterShowOffline(true);
	local cnt = 0;
	local guildMemberTemp={};
	for idx=1,numMembers do
		local name,rank,rankIndex,level,class,zone,note,officernote,online,status,classEn,achievementPoints,achievementRank,isMobile=GetGuildRosterInfo(idx);
		local lastonline;
		if(name~=nil)then
			if(stat["_officer"]) then
			elseif((guildMemberTemp) and guildMemberTemp[name]) then
				officernote = guildMemberTemp[name]["OfficerNote"];
			end

			-- ################### now hardcode but can be used rankindex and setup in options!
			if (rank=="Alter" or rank=="Alter de Ofi") then
				local correct = string.find(note,"ALT-");
				local main = string.sub(note, 5);
				if (correct == nil) then
					wowrostergp:Print(string.format(L["Note: Revise public note for %s (%s) = '%s' should start with 'ALT-'."],name,rank,note));
				elseif ( not UnitIsInMyGuild(main)) then
					wowrostergp:Print(string.format(L["Note: Revise public note for %s (%s) = '%s' because %s is not in the guild."],name,rank,note,main));
				end
			end
			-- ##################

			if(not wowrpref["guild"]["title"]) then rank = nil; end

			if(wowrpref["guild"]["compact"]) then
				if(status=="") then status = nil; end
				if(note=="") then note = nil; end
				if(officernote=="") then officernote = nil; end
			end
			if(not online) then
				lastonline = strjoin(":",GetGuildRosterLastOnline(idx));
			end
			
			guildMemberTemp[name] = {
				Name	= name,
				Rank	= rankIndex,
				RankEn	= rank,
				Title	= rank,
				Level	= level,
				Class	= class,
				ClassId	= wowroster.UnitClassID(classEn),
				Zone	  = zone,
				Status	= status,
				Note	  = note,
				OfficerNote= officernote,
				Online	   = online,
				LastOnline = lastonline,
				AchPoints = achievementPoints,
				AchRank = achievementRank,
				Mobile = isMobile,
			};

			local weeklyXP, totalXP, weeklyRank, totalRank = GetGuildRosterContribution(idx);
			if weeklyXP then
				guildMemberTemp[name]["XP"] = {};
				guildMemberTemp[name]["XP"] = {
					WeeklyXP = weeklyXP,
					TotalXP = totalXP,
					WeeklyRank = weeklyRank,
					TotalRank = totalRank,
				};
			end
			cnt=cnt+1;
		end
	end

	SetGuildRosterShowOffline(showOfflineTemp);
	if(numMembers==table.count(guildMemberTemp)) then
		stat["_guildNum"] = cnt;
		if(stat["_guildInfo"]~=numMembers) then
			GuildInfo();
			stat["_guildInfo"]=numMembers;
		end
		wowrostergp.sv["Members"]=guildMemberTemp;
		--=--wowrostergp.sv["timestamp"]["Members"]=time();
	end
end

--[[
local NEWS_MOTD = -1;				-- pseudo category
local NEWS_GUILD_ACHIEVEMENT = 0;
local NEWS_PLAYER_ACHIEVEMENT = 1;
local NEWS_DUNGEON_ENCOUNTER = 2;
local NEWS_ITEM_LOOTED = 3;
local NEWS_ITEM_CRAFTED = 4;
local NEWS_ITEM_PURCHASED = 5;
local NEWS_GUILD_LEVEL = 6;
local NEWS_GUILD_CREATE = 7;
]]--

function wowrostergp:Scannews()
	xx = 0;
	local numGuildNews = GetNumGuildNews();
	wowrostergp.sv["News"]={};
	structnews = {};
	for index=1, numGuildNews do
		order = nil;
		xx = xx+1;
		local isSticky, isHeader, newsType, text1, text2, id, data, data2, weekday, day, month, year = GetGuildNewsInfo(index);

		--wowrostergp:Print("News type "..newsType.."");

		if ( weekday) then
			weekday = weekday + 1;
		else
			weekday = "";
		end

		if ( day ) then
			day = day + 1;
		else
			day = "";
		end

		if ( month ) then
			month = month + 1;
		else
			month = "";
		end

		if ( year ) then
			year = year;
		else
			year = "";
		end

		NewsType = gnews[newsType];
		order = day.."/"..month.."/"..year or "";

		if( not structnews[NewsType] ) then
			structnews[NewsType]={};
		end
--[[
		if( not structnews[NewsType][xx] ) then
			structnews[NewsType][xx]={};
		end
]]--
		if ( weekday == 0 ) then
			weekday = 7;
		end
		if (not isHeader) then
			structnews[NewsType][xx] = {
				--Type		= NewsType,
				Typpe		= newsType,
				--isheader	= isHeader,
				Weekday		= weekday or "",
				Date		= order,
				DATEday 	= day or "",
				DATEmonth 	= month or "",
				DATEyear 	= year or "",
				ID			= id,
				Data 		= data or "",
				Data2 		= data2 or "",
				Member 		= text1 or "",
				Achievement	= text2 or "",
				Issticky 	= isSticky or "",
			};
		end
	end

	wowrostergp.sv["News"] = structnews;
end


function wowrostergp:ScanProfessions()
	local numTradeSkill = GetNumGuildTradeSkill();

	wowrostergp.sv["Trades"]={};
	structtrade = {};
	for index = 1, numTradeSkill do
		local skillID,isCollapsed,iconTexture,headerName,numOnline,numPlayers,playerName,class,online,zone,skill,classFileName = GetGuildTradeSkillInfo(index);
			if ( headerName ) then
				local skillHeader=headerName;
				structtrade[skillHeader] = {
					skid = skillID,
					icon = iconTexture,
					
				};
			elseif( skillHeader ) then
			structtrade[skillHeader][playerName] = {};
				structtrade[skillHeader][playerName] = {
					name = playerName,
					class = class,
					lvl = skill,
				};
			end
	end
	wowrostergp.sv["Trades"] = structtrade;
end

function wowrostergp:ScanGuildControl()
	wowrostergp.sv["Control"]={};
--	for idx=1,MAX_GUILDCONTROL_OPTIONS do
--	MAX_GUILDCONTROL_OPTIONS variable is wrong
	for idx=1,GuildControlGetRankFlagsNum(GuildControlGetRankFlags()) do
		wowrostergp.sv["Control"][idx]=getglobal("GUILDCONTROL_OPTION"..idx);
	end
	wowrostergp.sv["Ranks"]={};
	for idx=1,GuildControlGetNumRanks() do
		GuildControlSetRank(idx);
		wowrostergp.sv["Ranks"][idx-1]={
			Title=GuildControlGetRankName(idx),
			Control=self:GuildControlGetRankFlagsStr(GuildControlGetRankFlags()),
			--Withdraw= GetGuildBankTabPermissions(currentTab) (),
		};
		local numTabs = GetNumGuildBankTabs();
		for i=1, MAX_GUILDBANK_TABS do
			if ( i <= numTabs ) then
				local viewTab, canDeposit, updatetext, numWithdrawals = GetGuildBankTabPermissions(i);
				viewTab = viewTab or 0;
				canDeposit = canDeposit or 0;
				numWithdrawals = numWithdrawals or 0;
				wowrostergp.sv["Ranks"][idx-1]["Tab"..i]=strjoin(":",viewTab, canDeposit, numWithdrawals);
			else
				wowrostergp.sv["Ranks"][idx-1]["Tab"..i]=nil;
			end
		end
	end
end

function GuildControlGetRankFlagsNum(...)
	return select("#",...);
end

function  wowrostergp:GuildControlGetRankFlagsStr(...)
	local flags={};
	for i=1,select("#",...) do
		local v=select(i,...);
		v = v or 0;
		table.insert(flags,v);
	end
	return(table.concat(flags,":"));
end

function  wowrostergp:GuildVaultFlags(...)
	local str = "";
	for i=1, MAX_GUILDBANK_TABS do
		str = str ..strjoin(":",GetGuildBankTabPermissions(i))
	end
end

function wowrostergp:GUILDBANKBAGSLOTS_CHANGED()
	stat["Vaultavl"] = false;
	wowrostergp:ScanGuildBank();
end

function wowrostergp.ScanGuildBankQueue()
	local queue = wowrostergp.queue;
	if(not queue or table.getn(queue) == 0) then return end;
	for idx,tab in pairs( queue ) do
		if( tab[1] == "GUILDBANKBAGSLOTS_CHANGED" ) then
			QueryGuildBankTab(tab[3]);
		elseif( tab[1] == "GUILDBANKLOG_UPDATE" ) then
			QueryGuildBankLog(tab[3]);
		end
	end
end

function wowrostergp:ScanGuildBank()
	if(not wowrostergp.sv["Vault"]) then
		wowrostergp.sv["Vault"]={};
	end
	if(not wowrostergp.sv["Vault"]["Tabs"]) then
		wowrostergp.sv["Vault"]["Tabs"]={};
	end
	if(not wowrostergp.sv["Vault"]["Log"]) then
		wowrostergp.sv["Vault"]["Log"]={};
	end
	stat["Vault"] = {};
	numTabs = GetNumGuildBankTabs()
	local isViewable
	for tab=1, numTabs do
		if ( stat["Vaultavl"]) then
			QueryGuildBankTab(tab);
		end
		_,_,isViewable = GetGuildBankTabInfo(tab);

		if( isViewable ) then
			wowrostergp.ScanGuildBankTab(tab);
		else
			wowrostergp.sv["Vault"]["Tabs"]["Tab"..tab]=nil;
			wowrostergp.sv["Vault"]["Log"]["Tab"..tab]=nil;
		end
	end
	if(wowrpref["guild"]["vault_money"]) then
		wowrostergp:ScanGuildBankMoney()
	end
	wowrostergp:Print("Guild vault scaned");
end

function wowrostergp.ScanGuildBankTab(tab)
	if(not wowrostergp.sv["Vault"]["Tabs"]["Tab"..tab]) then
		wowrostergp.sv["Vault"]["Tabs"]["Tab"..tab]={};
	end
	if(not wowrostergp.sv["Vault"]["Tabs"]["Tab"..tab]["Contents"]) then
		wowrostergp.sv["Vault"]["Tabs"]["Tab"..tab]["Contents"]={};
	end

	local gb = wowrostergp.sv["Vault"]["Tabs"]["Tab"..tab];
	local tabName,tabIcon  = GetGuildBankTabInfo(tab);

	gb["Name"] = tabName;
	gb["Icon"] = wowroster.scanIcon(tabIcon);
	local itemLink;
	local itemIcon, itemCount;
	local bagInv = 0;
	for idx=1, MAX_GUILDBANK_SLOTS_PER_TAB do
		itemIcon, itemCount,_ = GetGuildBankItemInfo(tab,idx);
		itemLink = GetGuildBankItemLink(tab,idx)
		if(itemLink) then
			bagInv=bagInv+1;
		end
		gb["Contents"][idx] = wowrostergp:ScanItemInfo(itemLink,itemIcon,itemCount,idx,tab);
	end
	
	if(wowrpref["guild"]["vault_log"]) then
		wowrostergp.ScanGuildBankTabLog(tab)
	end
	local numTransactions = GetNumGuildBankTransactions(tab);

	wowrostergp:Print("Tab "..tab.." items "..bagInv.." log entrys "..numTransactions.."");
	stat["Vault"]["Tab"..tab]={slot=MAX_GUILDBANK_SLOTS_PER_TAB,inv=bagInv};
end

function wowrostergp:ScanItemInfo(itemstr,itemtexture,itemcount,idx,tab)
	local function numNil(num)
		if(wowrpref["fixquantity"] and num and num<=1) then return nil
		else return num
		end
	end
	if(itemstr) then
		local itemColor,itemLink,itemID,itemName,itemTexture,itemType,itemSubType,itemLevel,itemReqLevel,itemRarity=wowroster.GetItemInfo(itemstr);
		if(not itemName or not itemColor) then
			itemName,itemColor=wowroster.GetItemInfoTT(self.tooltip);
		end

		GameTooltip:SetOwner(UIParent, 'ANCHOR_NONE'); 
		GameTooltip:SetGuildBankItem(tab,idx);
		tooltip = wowroster.scantooltip2();
		GameTooltip:Hide();
		local itemBlock={
			Name	= itemName,
			Item	= itemID,
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
		return itemBlock;
	end

	return nil;
end

function wowrostergp.ScanGuildBankTabLog(tab)
	if(not wowrostergp.sv["Vault"]["Log"]["Tab"..tab]) then
		wowrostergp.sv["Vault"]["Log"]["Tab"..tab]={};
	end

	local db = wowrostergp.sv["Vault"]["Log"]["Tab"..tab];
	local type, name, itemLink, count, tab1, tab2, year, month, day, hour;
	local itemID
	local numTransactions = GetNumGuildBankTransactions(tab);

	if(numTransactions >= table.getn(db)) then
		for idx=1, numTransactions, 1 do
			type, name, itemLink, count, tab1, tab2, year, month, day, hour = GetGuildBankTransaction(tab,idx);
			_,_,itemID=wowroster.GetItemInfo(itemLink);
			db[idx] = {
				Type	= type,
				Name	= name or UNKNOWN,
				Tab1	= tab1,
				Tab2	= tab2,
				Item	= itemID,
				Count	= count,
				Time	= strjoin(":",year, month, day, hour)
			};
		end
	else
		QueryGuildBankLog(tab);
	end
end

function wowrostergp:ScanGuildBankMoney()
	if(not wowrostergp.sv["Vault"]) then
		wowrostergp.sv["Vault"]={};
	end
	wowrostergp.sv["Vault"]["Money"] = wowroster.Arg2Tab("Gold","Silver","Copper",wowroster.parseMoney(GetGuildBankMoney()));
	QueryGuildBankLog(MAX_GUILDBANK_TABS+1);
	
	if(wowrpref["guild"]["vault_log"]) then
		wowrostergp.ScanGuildBankMoneyLog()
	end
end

function wowrostergp.ScanGuildBankMoneyLog()
	if(not wowrostergp.sv["Vault"]) then
		wowrostergp.sv["Vault"]={};
	end
	if(not wowrostergp.sv["Vault"]["Log"]) then
		wowrostergp.sv["Vault"]["Log"]={};
	end
	if(not wowrostergp.sv["Vault"]["Log"]["Money"]) then
		wowrostergp.sv["Vault"]["Log"]["Money"]={};
	end
	local db = wowrostergp.sv["Vault"]["Log"]["Money"];
	local type, name, amount, year, month, day, hour;
	local numTransactions = GetNumGuildBankMoneyTransactions();

	if(numTransactions >= table.getn(db)) then
		for idx=1, numTransactions, 1 do
			type, name, amount, year, month, day, hour = GetGuildBankMoneyTransaction(idx);
			db[idx] = {
				Type	= type,
				Name	= name or UNKNOWN,
				Amount	= amount,
				Time	= strjoin(":",year, month, day, hour)
			};
		end
	end
end


function wowrostergp:Print(...)
	print("|cff33ff88WoWR-GP|r: ", ...)
end
