if( GetLocale() ~= "deDE" ) then
	return
end

local addon = select(2, ...)
addon.L = setmetatable({
	["save"] = "speichern",
  ["Click to export your Guild Profile"] = "Klicken, um Ihr Profil Guild Export",
}, {__index = addon.L})