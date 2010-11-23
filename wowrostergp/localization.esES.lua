if( GetLocale() ~= "esES" ) then
	return
end

local addon = select(2, ...)
addon.L = setmetatable({
	["save"] = "grabar",
	["Click to export your Guild Profile"] = "Pulsa aqui, para exportar la lista de tu hermandad",
}, {__index = addon.L})