if( GetLocale() ~= "frFR" ) then
	return
end

local addon = select(2, ...)
addon.L = setmetatable({
	["save"] = "sauver",
	["Click to export your Guild Profile"] = "Cliquez pour exporter vos Guild profil",
}, {__index = addon.L})