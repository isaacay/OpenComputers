--translation skipped on line 130 and 133
local ecs = require("ECSAPI")
local components = require("component")
local serialization = require("serialization")
local fs = require("filesystem")
local event = require("event")
local unicode = require("unicode")
local image = require("image")

--------------------------------------------------------------------------------------------------------------------------------------------

local pathToMultiScreenFolder = "MineOS/System/MultiScreen/"
local pathToConfigFile = pathToMultiScreenFolder .. "Config.cfg"

local colors = {
	background = 0x262626,
	foreground = 0xDDDDDD,
	currentScreen = ecs.colors.green,
	screen = 0xDDDDDD,
}

local baseResolution = {
	width = 135,
	height = 50,
}

local monitors = {}

--------------------------------------------------------------------------------------------------------------------------------------------

local function getAllConnectedScreens()
	local massiv = {}
	for address in pairs(components.list("screen")) do
		table.insert(massiv, address)
	end
	return massiv
end

local function configurator()
	fs.makeDirectory(pathToMultiScreenFolder)
	
	ecs.setScale(0.7)

	local data = ecs.universalWindow("auto", "auto", 40, 0xeeeeee, true, {"EmptyLine"}, {"CenterText", 0x880000, "Wow, ebana!"}, {"EmptyLine"}, {"WrappedText", 0x262626, "Welcome to the multi-monitor configuration. You need to specify the number of monitors on the width and height that you want to merge, and select the desired scale."}, {"EmptyLine"}, {"Input", 0x262626, 0x880000, "Width"}, {"Input", 0x262626, 0x880000, "Height"},  {"Slider", 0x262626, 0x880000, 1, 100, 100, "Scale: ", "%"}, {"EmptyLine"}, {"Button", {ecs.colors.orange, 0xffffff, "confirm"}, {0x777777, 0xffffff, "cancellation"}})
	local width, height, scale = tonumber(data[1]), tonumber(data[2]), tonumber(data[3]) / 100
	if data[4] == "cancellation" then
		ecs.prepareToExit()
		print("Calibration is canceled!")
		os.exit()
	end

	baseResolution.width, baseResolution.height = math.floor(baseResolution.width * scale), math.floor(baseResolution.height * scale)

	-- ecs.error(baseResolution.width .. "x" ..baseResolution.height .. " ccale = " ..scale)

	local countOfConnectedScreens = #getAllConnectedScreens()

	while ((countOfConnectedScreens - 1) ~= width * height) do
		data = ecs.universalWindow("auto", "auto", 44, 0xeeeeee, true, {"EmptyLine"}, {"WrappedText", 0x262626, "Now you need to connect an external monitor. You indicated that you are going to make of multi-monitor " .. width*height .. " monitors, but at the moment you connect " .. countOfConnectedScreens - 1 .. " monitors. So turn off everything as indicated and click \"Next\"."}, {"EmptyLine"}, {"Button", {ecs.colors.orange, 0xffffff, "Next"}, {0x777777, 0xffffff, "cancellation"}})
		if data[1] == "cancellation" then
			ecs.prepareToExit()
			print("Calibration is canceled!")
			os.exit()
		end
		countOfConnectedScreens = #getAllConnectedScreens()
	end

	----

	local w, h = 8, 3
	local xC, yC = 1, 1
	local xSize, ySize = gpu.getResolution()
	local mainScreenAddress = gpu.getScreen()

	local function drawMonitors()
		ecs.clearScreen(colors.background)
		local x, y = 3, 2
		local xPos, yPos = x, y
		for j = 1, height do
			for i = 1, width do
				if j == yC and i == xC then
					ecs.square(xPos, yPos, w, h, colors.currentScreen)
				else
					ecs.square(xPos, yPos, w, h, colors.screen)
				end
				xPos = xPos + w + 2
			end
			yPos = yPos + h + 1
			xPos = x
		end

		gpu.setBackground(colors.background)
		gpu.setForeground(colors.foreground)
		ecs.centerText("x", ySize - 5, "We start the calibration process. Tap the monitor, highlighted in green.")
		ecs.centerText("x", ySize - 4, "Do not defeat the touch!")
	end

	local touchArray = {}

	while xC <= width and yC <= height do
		drawMonitors()
		local e = {event.pull()}
		if e[1] == "touch" then
			if e[2] ~= mainScreenAddress then
				local success = true
				for i = 1, #touchArray do
					if touchArray[i] == e[2] then
						success = false
						break
					end
				end
				if success then
					ecs.rebindGPU(e[2])
					gpu.setResolution(baseResolution.width, baseResolution.height)
					local color = math.random(0x555555, 0xffffff)
					ecs.square(1,1,160,50,color)
					gpu.setForeground(0xffffff - color)
					ecs.centerText("xy", 0, "Monitor " .. xC .. "x" .. yC .. " calibrated!")
					
					-- table.insert(touchArray, {address = e[2], position = {x = xC, y = yC}})
					touchArray[xC] = touchArray[xC] or {}
					touchArray[xC][yC] = touchArray[xC][yC] or {}
					touchArray[xC][yC].address = e[2]

					ecs.rebindGPU(mainScreenAddress)
					ecs.setScale(0.7)

					xC = xC + 1
					if xC > width and yC < height then xC = 1; yC = yC + 1 end
				else
					ecs.error("Тупая скотина, зачем ты тыкаешь на монитор, которого уже касался? На твое счастье в этой проге есть защита от конченных дебилов вроде тебя.")
				end
			else
				ecs.error("Ну что ты за мудак криворукий! Сказано же, каких мониторов касаться. Не трогай этот монитор.")
			end
		end
	end

	monitors = touchArray
	monitors.countOfScreensByWidth = width
	monitors.countOfScreensByHeight = height
	monitors.screenResolutionByWidth = baseResolution.width
	monitors.screenResolutionByHeight = baseResolution.height
	monitors.totalResolutionByWidth = baseResolution.width * width
	monitors.totalResolutionByHeight = baseResolution.height * height

	ecs.prepareToExit()
	ecs.universalWindow("auto", "auto", 40, 0xeeeeee, true, {"EmptyLine"}, {"CenterText", 0x262626, "Calibration is successfully completed!"}, {"EmptyLine"}, {"Button", {ecs.colors.orange, 0xffffff, "Excellent"}})

	gpu.setBackground(0x000000)
	for x = 1, #monitors do
		for y = 1, #monitors[x] do
			gpu.bind(monitors[x][y].address)
			gpu.fill(1, 1, 160, 50, " ")
		end
	end
	gpu.bind(mainScreenAddress)
	ecs.prepareToExit()
end

local function saveConfig()
	local file = io.open(pathToConfigFile, "w")
	file:write(serialization.serialize(monitors))
	file:close()
end

local function loadConfig()
	if fs.exists(pathToConfigFile) then
		local file = io.open(pathToConfigFile, "r")
		monitors = serialization.unserialize(file:read("*a"))
		file:close()
		print(" ")
		print("multi-monitor configuration file was loaded successfully.")
		print(" ")
		print("Number of screens: " .. monitors.countOfScreensByWidth .. "x" .. monitors.countOfScreensByHeight .. " PC")
		print("The resolution of each screen: " .. monitors.screenResolutionByWidth .. "x" .. monitors.screenResolutionByHeight .. " px")
		print("Total resolution of the cluster: ".. monitors.totalResolutionByWidth .. "x" .. monitors.totalResolutionByHeight .. " px")
		print(" ")
	else
		configurator()
		saveConfig()
		loadConfig()
	end
end

--------------------------------------------------------------------------------------------------------------------------------------------

local currentBackground, currentForeground, currentAddress = 0x000000, 0xffffff, ""

local multiScreen = {}

function multiScreen.setBackground(color)
	currentBackground = color
end

function multiScreen.setForeground(color)
	currentForeground = color
end

local function getMonitorAndCoordinates(x, y)
	local xMonitor = math.ceil(x / monitors.screenResolutionByWidth)
	local yMonitor = math.ceil(y / monitors.screenResolutionByHeight)
	local xPos = x - (xMonitor - 1) * monitors.screenResolutionByWidth
	local yPos = y - (yMonitor - 1) * monitors.screenResolutionByHeight

	-- print("x = " .. x)
	-- print("y = " .. y)
	-- print("xMonitor = " .. xMonitor)
	-- print("yMonitor = " .. yMonitor)
	-- print("xPos = " .. xPos)
	-- print("yPos = " .. yPos)

	return xMonitor, yMonitor, xPos, yPos
end

function multiScreen.clear(color)
	for x = 1, #monitors do
		for y = 1, #monitors[x] do
			gpu.bind(monitors[x][y].address)
			gpu.setResolution(monitors.screenResolutionByWidth, monitors.screenResolutionByHeight)
			gpu.setBackground(color)
			gpu.fill(1, 1, 160, 50, " ")
		end
	end
end

function multiScreen.set(x, y, text)
	for i = 1, unicode.len(text) do
		local xMonitor, yMonitor, xPos, yPos = getMonitorAndCoordinates(x + i - 1, y)
		
		if currentAddress ~= monitors[xMonitor][yMonitor].address then
			gpu.bind(monitors[xMonitor][yMonitor].address)
			currentAddress = monitors[xMonitor][yMonitor].address
			gpu.setResolution(monitors.screenResolutionByWidth, monitors.screenResolutionByHeight)
		end
		
		if gpu.getBackground ~= currentBackground then gpu.setBackground(currentBackground) end
		if gpu.getForeground ~= currentForeground then gpu.setForeground(currentForeground) end
		
		gpu.set(xPos, yPos, unicode.sub(text, i, i))
	end
	
end

function multiScreen.image(x, y, picture)
	local sizeOfPixelData = 4
	
	local function convertIndexToCoords(index)
		index = (index + sizeOfPixelData - 1) / sizeOfPixelData
		local ostatok = index % picture.width
		local x = (ostatok == 0) and picture.width or ostatok
		local y = math.ceil(index / picture.width)
		ostatok = nil
		return x, y
	end

	local function convertCoordsToIndex(x, y)
		return (picture.width * (y - 1) + x) * sizeOfPixelData - sizeOfPixelData + 1
	end

	local xPos, yPos
	for i = 1, #picture, sizeOfPixelData do
		xPos, yPos = convertIndexToCoords(i)
		if picture[i + 2] ~= 0xff then
			multiScreen.setBackground(picture[i])
			multiScreen.setForeground(picture[i + 1])
			multiScreen.set(x + xPos - 1, y + yPos - 1, picture[i + 3])
		end
	end
end

--------------------------------------------------------------------------------------------------------------------------------------------

loadConfig()

multiScreen.clear(0x000000)

local picture = image.load("4.png")
multiScreen.image(2, 2, picture)

-- multiScreen.setBackground(ecs.colors.green)
-- multiScreen.setForeground(ecs.colors.white)

-- multiScreen.set(130, 2, "Сука мать ебал, пидор ты ебаный, хыыы!")
-- multiScreen.set(230, 4, "Сука мать ебал, пидор ты ебаный, хыыы!")

--------------------------------------------------------------------------------------------------------------------------------------------

return multiScreen






