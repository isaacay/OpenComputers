local internet = require("internet")
local fs = require("filesystem")
local seri = require("serialization")
local shell = require("shell")
local config = require("config")

local args, options = shell.parse(...)

local function printUsage()
  io.write("\n Using:\n")
  io.write(" github set <link to the repository> - install the specified repository as a permanent\n")
  io.write(" github get <link> <storage path> - to download the specified file from the current repository\n")
  io.write(" github fast <reference to the raw file> <path to save> - download without fucked brains file\n\n")
  io.write(" Examples:\n")
  io.write(" github set isaacay/OpenComputers\n")
  io.write(" github get Applications/Home.lua Home.lua\n")
  io.write(" github fast isaacay/OpenComputers/master/Applications/Home.lua Home.lua\n\n")	
end

if #args < 2 or string.lower(tostring(args[1])) == "help" then
  printUsage()
  return
end

local quiet = false
if args[1] == "fast" then quiet = true end

local pathToConfig = "System/GitHub/Repository.cfg"
local currentRepository
local userUrl = "https://raw.githubusercontent.com/"

--pastebin run SthviZvU isaacay/OpenComputers/master/Applications.txt hehe.txt

------------------------------------------------------------------------------------------

local function info(text)
	if not quiet then print(text) end
end

--ЗАГРУЗОЧКА С ГИТХАБА
local function getFromGitHub(url, path)
	local sContent = ""

	info(" ")
	info("Connecting to GitHub at "..url)

	local result, response = pcall(internet.request, url)
	if not result then
		return nil
	end

	info(" ")

	if result == "" or result == " " or result == "\n" then info("empty file, or an incorrect link."); return end

	if fs.exists(path) then
		info("The file already exists, delete the old one.")
		fs.remove(path)
	end
	fs.makeDirectory(fs.path(path))
	local file = io.open(path, "w")

	for chunk in response do
		file:write(chunk)
		sContent = sContent .. chunk
	end

	file:close()
	info("The file is downloaded and stored in the /"..path)
	info(" ")
	return sContent
end

--БЕЗОПАСНАЯ ЗАГРУЗОЧКА
local function getFromGitHubSafely(url, path)
	local success, sRepos = pcall(getFromGitHub, url, path)
	if not success then
		io.stderr:write("Unable to connect to this link. Probably, it is incorrect or there is no Internet connection.")
		return nil
	end
	return sRepos
end

if args[1] == "set" then
	if fs.exists(pathToConfig) then fs.remove(pathToConfig) end
	fs.makeDirectory(fs.path(pathToConfig))
	config.write(pathToConfig, "currentRepository", args[2])
	currentRepository = args[2]
	info(" ")
	info("Current repository changed to "..currentRepository)
	info(" ")
elseif args[1] == "get" then
	if not fs.exists(pathToConfig) then
		io.write("\nCurrent repository is not installed. Use \"github set <path to the repository>\".\n\n")
	else
		currentRepository = config.readAll(pathToConfig).currentRepository
		getFromGitHubSafely(userUrl .. currentRepository .. "/master/" .. args[2], args[3])
	end
elseif args[1] == "fast" then
	getFromGitHubSafely(userUrl .. args[2], args[3])
else
	printUsage()
	return
end
