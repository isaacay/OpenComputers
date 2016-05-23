local archive = require("lib/archive")
local shell = require("shell")
local fs = require("filesystem")

------------------------------------------------------------------------------------------------------------------------------------

local args, options = shell.parse(...)

if not options.q then
	archive.debugMode = true
end

local function debug(text)
	if not options.q then print(text) end
end

if args[1] == "pack" then
	if not args[2] or not args[3] then
		debug(" ")
		debug("Use: archive pack <file name> <archived folder>")
		debug(" ")
		return
	end 
	debug(" ")
	debug("package Packing launched")
	debug(" ")
	archive.pack(args[2], args[3])
	debug(" ")
	debug("package Packing completed, the file is saved as \"" .. args[2] .. "\", its size was " .. math.ceil(fs.size(args[2]) / 1024) .. "КБ")
	debug(" ")
elseif args[1] == "unpack" then
	if not args[2] or not args[3] then
		debug(" ")
		debug("Use: archive unpack <path to file> <folder for saving files>")
		debug(" ")
		return
	end
	debug(" ")
	debug("Unpack package launched")
	debug(" ")
	archive.unpack(args[2], args[3])
	debug(" ")
	debug("Unpacking package \"" .. args[2] .. "\" completed")
	debug(" ")
elseif args[1] == "download" or args[1] == "get" then
	if not args[2] or not args[3] then
		debug(" ")
		debug("Use: archive download <URL-link to the file> <folder for saving files>")
		debug(" ")
		return
	end
	debug(" ")
	debug("Download link file \"" .. args[2] .. "\"")
	shell.execute("wget " .. args[2] .. " TempFile.pkg -fq")
	debug(" ")
	debug("Unpack the downloaded package")
	archive.unpack("TempFile.pkg", args[3])
	shell.execute("rm TempFile.pkg")
	debug(" ")
	debug("Package \"" .. args[2] .. "\" It has been successfully downloaded and unpacked")
	debug(" ")
else
	debug(" ")
	debug("Use: archive <pack/unpack/download> ...")
	debug(" ")
	return
end

archive.debugMode = false

------------------------------------------------------------------------------------------------------------------------------------
