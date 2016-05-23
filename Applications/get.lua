
local component = require("component")
local serialization = require("serialization")
local unicode = require("unicode")
local shell = require("shell")

local pathToApplications = "MineOS/System/OS/Applications.txt"
local applications = {}
local arguments = { ... }
local initPhase = false

--------------------------------------------------------------------------------------------------------------

local function loadApplications()
	local file = io.open(pathToApplications, "r")
	applications = serialization.unserialize(file:read("*a"))
	file:close()
end

local function printUsage()
	print("Использование:")
	print("  get <file name> - the program tries to find the file name and download it")
	print("  get all <Applications/Wallpapers/Scripts/Libraries> - the program will load all existing files from this category")
	print("  get everything - program to download all the files from the list")
	print("  get list - the program will update the list of applications")
	print("  get ecsapi - Program updates the main author MineOS library")
	-- print("Доступные категории:")
	-- print("  Applications - приложения MineOS")
	-- print("  Wallpapers - обои для MineOS")
	-- print("  Scripts - различные программы с расширением .lua")
	-- print("  Libraries - библиотеки")
	-- print(" ")
end

local function searchFile(searchName)
	searchName = unicode.lower(searchName)
	if ecs.getFileFormat(searchName) == ".app" then searchName = ecs.hideFileFormat(searchName) end
	for i = 1, #applications do
		if unicode.lower(fs.name(applications[i].name)) == searchName then
			return i
		end
	end
end

local function getCategory(category)
	local counter = 0
	for i = 1, #applications do
		if applications[i].type == category then
			print("upload files \"" .. applications[i].name .. "\" by the address \"" .. applications[i].url .. "\"")
			ecs.getOSApplication(applications[i])
			counter = counter + 1
		end
	end
	if counter > 0 then print(" ") end
	print("Number of uploaded files: " .. counter)
end

local function getEverything()
	local counter = 0
	for i = 1, #applications do
		print("upload files \"" .. applications[i].name .. "\" by the address \"" .. applications[i].url .. "\"")
		ecs.getOSApplication(applications[i])
		counter = counter + 1
	end
	print(" ")
	print("Number of uploaded files: " .. counter)
end

local function getECSAPI()
	print("loading library ECSAPI.lua...")
	shell.execute("wget -fQ https://raw.githubusercontent.com/isaacay/OpenComputers/master/lib/ECSAPI.lua lib/ECSAPI.lua")
	package.loaded.ECSAPI = nil
	package.loaded.ecs = nil
	_G.ecs = require("ECSAPI")
	print("initialized Library.")
end

local function getApplicationList()
	print("Updating the application list...")
	shell.execute("wget -fQ https://raw.githubusercontent.com/isaacay/OpenComputers/master/Applications.txt MineOS/System/OS/Applications.txt")
	print("The list of applications is updated.")
end

local function separator(text)
	text = " " .. text .. " "
	local textLength = unicode.len(text)
	local xSize, ySize = component.gpu.getResolution()
	local widthOfEachLine = math.floor((xSize - textLength) / 2)
	print(string.rep("─", widthOfEachLine) .. text .. string.rep("─", widthOfEachLine))
end

local function parseArguments()
	if not arguments[1] then
		printUsage()
	elseif unicode.lower(arguments[1]) == "list" then
		getApplicationList()
	elseif unicode.lower(arguments[1]) == "ecsapi" or unicode.lower(arguments[1]) == "ecsapi.lua" then
		getECSAPI()
	elseif unicode.lower(arguments[1]) == "all" then
		if not arguments[2] then
			printUsage()
		elseif unicode.lower(arguments[2]) == "libraries" then
			getCategory("Library")
		elseif unicode.lower(arguments[2]) == "wallpapers" then
			getCategory("Wallpaper")
		elseif unicode.lower(arguments[2]) == "scripts" then
			getCategory("Script")
		elseif unicode.lower(arguments[2]) == "applications" then
			getCategory("Application")
		else
			print("Disclosure of the unknown category \"" .. arguments[2] .. "\", only supported Applications, Wallpapers, Libraries and Scripts.")
		end
	elseif unicode.lower(arguments[1]) == "everything" then
		getEverything()
	else
		local foundedID = searchFile(arguments[1])
		if foundedID then
			print("File \"" .. applications[foundedID].name .. "\" found, the load at \"" .. applications[foundedID].url .. "\"")
			ecs.getOSApplication(applications[foundedID])
		else
			print("The specified file is not found")
		end
	end
end

--------------------------------------------------------------------------------------------------------------

if not component.isAvailable("internet") then 
	print("This program requires the online internet card for it to work")
	return
end

print(" ")

if not fs.exists("lib/ECSAPI.lua") then
	if not initPhase then
		separator("Initialization")
		print(" ")
	end
	getECSAPI()
	print(" ")
	initPhase = true
end

if not fs.exists("MineOS/System/OS/Applications.txt") then
	if not initPhase then
		separator("Initialization")
		print(" ")
	end
	getApplicationList()
	print(" ")
	initPhase = true
end

if initPhase then
	separator("Initialization")
	print(" ")
end

loadApplications()
parseArguments()

print(" ")












