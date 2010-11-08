

wowroster = LibStub("AceAddon-3.0"):NewAddon("wowroster", "AceConsole-3.0", "AceEvent-3.0")
local acr = LibStub("AceConfigRegistry-3.0")
local state = {};
local acd = LibStub("AceConfigDialog-3.0")
local ac = LibStub("AceConfig-3.0")

local defaults={
	profile={
		["enabled"]=true,
		["verbose"]=false,
		["reagentfull"]=true,
		["talentsfull"]=true,
		["questsfull"]=false,
		["debug"]=false,
		["ver"]=030000,
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
	},		
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

function wowroster:OnEnable()
    -- Called when the addon is enabled\
	
	-- Trade skill window changes
    --self:RegisterEvent("TRADE_SKILL_CLOSE")
    --self:RegisterEvent("TRADE_SKILL_SHOW")
    --self:RegisterEvent("TRADE_SKILL_UPDATE")

    -- Learning or unlearning a tradeskill
    --self:RegisterEvent('SKILL_LINES_CHANGED')
	
	
	
	wowroster:Print("Hello, WoW Roster Profiler Enabled");
	self:InitState()
	self:InitProfile();
	self:ScanProfs();
	wowroster:Print("Hello, WoW Roster Profiler Loaded go to the addons tab in the Interface config section of wow to configure the addon ");
end

function wowroster:OnDisable()
	self.prefs = wowrpref;
	LibStub("AceDB-3.0"):New("wowrpref",self.prefs)
	LibStub("AceDB-3.0"):New("cpProfile",self.db)
end

function wowroster:OnInitialize()

	self.prefs = LibStub("AceDB-3.0"):New("wowrpref")
	if(not wowrpref["enabled"]) then
		wowrpref = defaults.profile;
		self.prefs = wowrpref;
		wowroster:Print("defaults loaded verson ".. self.prefs["ver"] .."")
	end
	self.db = LibStub("AceDB-3.0"):New("cpProfile");
	local function profileUpdate()
		addon:SendMessage("scan updated")
	end
	self.db.RegisterCallback(self, "OnProfileChanged", profileUpdate)
	self.db.RegisterCallback(self, "OnProfileCopied", profileUpdate)
	self.db.RegisterCallback(self, "OnProfileReset", profileUpdate)
	--self.db = db
	wowroster:makeconfig()
end


function wowroster:makeconfig()
			
	local acOptions = {
	type = "group",
	name = "WoW Roster Character Profiler",
	get = GetProperty, set = SetProperty, handler = wowroster,
	args = {
		heading = {
			type = "description",
			name = "Welcome to the wow roster cp config section these are the settings for the addon",
			fontSize = "medium",
			order = 10,
			width = "full",
		},
		questsfull= {
			type = "toggle",
			name = "Full Quests",
			desc = "get quest Description and Objectives or not",--.broadcastDesc,
			set = function(info,val) wowrpref[info[#info]] = val end,
			get = function(info) return wowrpref[info[#info]] end,

			order = 12,
		},
		Scan ={
		
			type = "group",
			name = "Scanning Options",
			args = {
				
				heading = {
					type = "description",
					name = "Scanning Options",
					fontSize = "medium",
					order = 14,
					width = "full",
				},
				inventory = {
					type = "toggle",
					name = "Inventory",
					desc = "get contents of your bags or not",--.broadcastDesc,
					set = function(info,val) wowrpref["scan"][info[#info]]  = val end,
					get = function(info) return wowrpref["scan"][info[#info]]  end,
					order = 16,
				},
				bank = {
					type = "toggle",
					name = "Bank",
					desc = "get contents of your Bank or not",--.broadcastDesc,
					set = function(info,val) wowrpref["scan"][info[#info]] = val end,
					get = function(info) return wowrpref["scan"][info[#info]]  end,
					order = 17,
				},
				quests = {
					type = "toggle",
					name = "Quests",
					desc = "get contents of your Quest log or not",--.broadcastDesc,
					set = function(info,val) wowrpref["scan"][info[#info]] = val end,
					get = function(info) return wowrpref["scan"][info[#info]] end,
					order = 18,
				},
				mail = {
					type = "toggle",
					name = "Mail Box",
					desc = "get contents of your Mail Box or not",--.broadcastDesc,
					set = function(info,val) wowrpref["scan"][info[#info]] = val end,
					get = function(info) return wowrpref["scan"][info[#info]] end,
					order = 19,
				},
				glyphs = {
					type = "toggle",
					name = "Glyphs",
					desc = "get characters Glyphs",--.broadcastDesc,
					set = function(info,val) wowrpref["scan"][info[#info]] = val end,
					get = function(info) return wowrpref["scan"][info[#info]] end,
					order = 20,
				},
				talents = {
					type = "toggle",
					name = "Talents",
					desc = "Get your characters Talents or not",--.broadcastDesc,
					set = function(info,val) wowrpref["scan"][info[#info]] = val end,
					get = function(info) return wowrpref["scan"][info[#info]] end,
					order = 21,
				},
				pet = {
					type = "toggle",
					name = "Pets",
					desc = "Scan Pets NYI (returns no data)",--.broadcastDesc,
					set = function(info,val) wowrpref["scan"][info[#info]] = val end,
					get = function(info) return wowrpref["scan"][info[#info]] end,
					order = 22,
				},
				spells = {
					type = "toggle",
					name = "Spell Book",
					desc = "Get your spells from the spell book",--.broadcastDesc,
					set = function(info,val) wowrpref["scan"][info[#info]] = val end,
					get = function(info) return wowrpref["scan"][info[#info]] end,
					order = 23,
				},
				professions = {
					type = "toggle",
					name = "Professions",
					desc = "get your profeshion recipes or skills",--.broadcastDesc,
					set = function(info,val) wowrpref["scan"][info[#info]] = val end,
					get = function(info) return wowrpref["scan"][info[#info]] end,
					order = 24,
				},
				companions = {
					type = "toggle",
					name = "Companions/Mounts",
					desc = "Companion and mount information",--.broadcastDesc,
					set = function(info,val) wowrpref["scan"][info[#info]] = val end,
					get = function(info) return wowrpref["scan"][info[#info]] end,
					order = 25,
				},
				honor = {
					type = "toggle",
					name = "Honor",
					desc = "Honor Info for your character",--.broadcastDesc,
					set = function(info,val) wowrpref["scan"][info[#info]] = val end,
					get = function(info) return wowrpref["scan"][info[#info]] end,
					order = 26,
				},
				reputation = {
					type = "toggle",
					name = "Reputation",
					desc = "Get Reputation info for your character",--.broadcastDesc,
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
					order = 29,
					width = "full",
				},
				dsglyphs = {
					type = "toggle",
					name = "Glyphs",
					desc = "get characters Glyphs",--.broadcastDesc,
					set = function(info,val) wowrpref["scan"][info[#info]] = val end,
					get = function(info) return wowrpref["scan"][info[#info]] end,
					order = 30,
				},
				dstalents = {
					type = "toggle",
					name = "Talents",
					desc = "Get your characters Talents or not",--.broadcastDesc,
					set = function(info,val) wowrpref["scan"][info[#info]] = val end,
					get = function(info) return wowrpref["scan"][info[#info]] end,
					order = 31,
				},
				dsspells = {
					type = "toggle",
					name = "Spell Book",
					desc = "Get your spells from the spell book",--.broadcastDesc,
					set = function(info,val) wowrpref["scan"][info[#info]] = val end,
					get = function(info) return wowrpref["scan"][info[#info]] end,
					order = 33,
				},	
			},
		},
	},
	}

	LibStub( 'AceConfig-3.0'):RegisterOptionsTable( "wowroster cp",acOptions)
	
	ac:RegisterOptionsTable("WoW Roster Cp", acOptions)
	local mainOpts = acd:AddToBlizOptions("WoW Roster Cp", "WoWRoster Profiler")
	mainOpts:HookScript("OnShow", function()
		wowroster:Enable()
		local p = findPanel("WoW Roster Cp")
		if p and p.element.collapsed then OptionsListButtonToggle_OnClick(p.toggle) end
	end)
end

function wowroster:InitState()
	local _,class=UnitClass("player");
	self.state = {
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
		Professions={}, SpellBook={},
		Pets={}, Stable={}, PetSpell={}, PetTalent={},
		Companions={},
	};
	self.queue={};
	
	state = function(self,...)
	if(not self.prefs) then return end
	local state = self.prefs;
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

function wowroster:InitProfile()
	if( not cpProfile ) then
		cpProfile={}; end
	if( not cpProfile[self.state["_server"]] ) then
		cpProfile[self.state["_server"]]={}; end
	if( not cpProfile[self.state["_server"]]["Character"] ) then
		cpProfile[self.state["_server"]]["Character"]={}; end
	if( not cpProfile[self.state["_server"]]["Character"][self.state["_player"]] ) then
		cpProfile[self.state["_server"]]["Character"][self.state["_player"]]={}; end

	self.db = cpProfile[self.state["_server"]]["Character"][self.state["_player"]];
	if( self.db ) then
		self.db["CPversion"]	= "1.0";
		self.db["CPprovider"]	= "wowr";
		self.db["DBversion"]	= "3.1";
		self.db["Name"]			= self.state["_player"];
		self.db["Server"]		= self.state["_server"];
		self.db["Locale"]		= GetLocale();
		self.db["Race"],self.db["RaceEn"],self.db["RaceId"]=UnitRace("player")
		self.db["Class"],self.db["ClassEn"],self.db["ClassId"]=UnitClass("player");
		self.db["Sex"],self.db["SexId"]=UnitSex("player");
		self.db["FactionEn"],self.db["Faction"]=UnitFactionGroup("player");
		self.db["HasRelicSlot"]	= UnitHasRelicSlot("player")==1 or false;
		--self:UpdateDate();
		self.state["_loaded"] = true;
	end
	return self.state["_loaded"];
end


function wowroster.ScanProfs()

	wowroster.db = cpProfile[wowroster.state["_server"]]["Character"][wowroster.state["_player"]];
	wowroster.db["Professions"]={};
    local skills = {}
	local prof1, prof2, archaeology, fishing, cooking, firstAid = GetProfessions();
	--local numTradeSkills = GetNumTradeSkills();
	local skillHeader,skillName,skillType;
		local cooldown;
		local reagents={};
		local skillIcon;
		local itemColor,itemLink;
		local tt;
		local reagentName,reagentIcon,reagentCount,reagentColor,reagentLink;
		local itemID;
		local lastHeaderIdx;
	local profs  = {GetProfessions()}
    for i=1,6 do 
         
		local profIndex=profs[i];
        
		if (profIndex and profIndex~=fishing)then
             local skillName, icon, skillLevel, maxSkillLevel, numAbilities, spelloffset, skillLine, skillModifier = GetProfessionInfo(profIndex);
			 
				numSkills = GetNumTradeSkills();
				idxStart = 1;
				
				skills[skillName] = {
					name = skillName,
					skilllevel = skillLevel,
					skillmax = maxSkillLevel,
					number = numSkills,
					index = profIndex, -- no real reasion to have this just want it...
				};
				
				--[[
				ok now we have the list of skills/profeshions ... now we need to get the header functions and recipes...
				]]--
				
				for idx=idxStart, numSkills do
			-- Save each enchant ID to our known enchants table
					tskillName, skillType, numAvailable, isExpanded, altVerb = GetTradeSkillInfo(idx);
					
					if( tskillName~="" ) then -- dont wana create errors with profs with no data ex fishing...
					
					--[[	if( skillType=="header" ) then -- findout if its a header if so make it a header lol
					
							lastHeaderIdx = idx;
							local skillHeader=tskillName;
							
							skills[skillName][skillHeader]={header = true};

						end]]--
						--if( skillType~="header" ) then
						
							skills[skillName][tskillName]={
								name = tskillName,
								difaculty = skillType,
							};
						
						--end
						
					
					end
				
				
				end
        end
--[[for idx=idxStart,numSkills do

				skillName,skillType,_,_,serviceType=GetTradeSkillInfo(idx);
			
					if( skillName and skillName~="" ) then
				
						if( skillType=="header" ) then
					
							lastHeaderIdx = idx;
							skillHeader=skillName;
							
							if( not skills[skillLineName][skillHeader] ) then
								skills[skillLineName][skillHeader]={};
							end

						elseif( skillHeader ) then
					
							cooldown,numMade=nil,nil;
							reagents={};
								
							skills[skillLineName][skillHeader][skillName]={
								name = skillName,
								--RecipeID  = rpgo.GetRecipeId( GetTradeSkillRecipeLink(idx) ),
								--Difficulty= TradeSkillCode[skillType],
								Reagents  = reagents,
								--Result    = result,
								Service   = serviceType,
							};
						end
					
					
				end 
				
			end
			 
		end --skillName end
	 
        end
		profIndex=nil;
		]]--
	end
    wowroster.db["Professions"] = skills
end

function wowroster:Print(...)
	print("|cff33ff99WoW Roster CP|r:", ...)
end