if( GetLocale() ~= "zhTW" ) then
	return
end

local addon = select(2, ...)
addon.L = setmetatable({
	["save"] = "บันทึก",
	["Click to export your Guild Profile"] = "คลิกเพื่อส่งออก ตระกูล โปรไฟล์ของคุณ",
}, {__index = addon.L})