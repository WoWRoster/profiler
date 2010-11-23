if( GetLocale() ~= "ruRU" ) then
	return
end

local addon = select(2, ...)
addon.L = setmetatable({
	["save"] = "сохранить",
	["Click to export your Guild Profile"] = "Нажмите, чтобы экспортировать Гильдии профиль",
}, {__index = addon.L})
