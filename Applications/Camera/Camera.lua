local component = require("component")
local buffer = require("doubleBuffering")
local event = require("event")
local camera

if not component.isAvailable("camera") then
	ecs.error("This program requires a camera of fashion Computronix.")
	return
else
	camera = component.camera
end

local step = 0.04
local from = step * 25
local distanceLimit = 36

local widthOfImage, heightOfImage = 100, 50

local grayScale = {
	0x000000,
	0x111111,
	0x111111,
	0x222222,
	0x333333,
	0x333333,
	0x444444,
	0x555555,
	0x666666,
	0x777777,
	0x777777,
	0x888888,
	0x999999,
	0xaaaaaa,
	0xbbbbbb,
	0xbbbbbb,
	0xcccccc,
	0xdddddd,
	0xeeeeee,
	0xeeeeee,
	0xffffff,
}

local rainbow = {
  0x000000,
  0x000040,
  0x000080,
  0x002480,
  0x0000BF,
  0x0024BF,
  0x002400,
  0x004900,
  0x006D00,
  0x009200,
  0x00B600,
  0x33DB00,
  0x99FF00,
  0xCCFF00,
  0xFFDB00,
  0xFFB600,
  0xFF9200,
  0xFF6D00,
  0xFF4900,
  0xFF2400,
  0xFF0000,
}

local currentPalette = rainbow

local topObjects

local currentTopObject = 0

local function gui()
	topObjects = ecs.drawTopMenu(1, 1, widthOfImage, 0xeeeeee, currentTopObject, {"Camera", 0x000000}, {"To take a photo", 0x444444}, {"render Settings", 0x444444}, {"Palette", 0x444444})
end

local function capture(x, y)
	local xPos, yPos = x, y
	local distance, color

	local oldPixels = ecs.info("auto", "auto", " ", "     snapshot...     ")

	for y = from, -from, -step do
		for x = -from, from, step do
			distance = camera.distance(x, y)
			if distance >= 0 then
				if distance > distanceLimit then distance = distanceLimit end
				
				color = currentPalette[(#currentPalette + 1) - math.ceil(distance / (distanceLimit / #currentPalette))]
				
				buffer.set(xPos, yPos, color, 0x000000, " ")
				buffer.set(xPos + 1, yPos, color, 0x000000, " ")
			else
				buffer.set(xPos, yPos, 0x000000, 0x000000, " ")
				buffer.set(xPos + 1, yPos, 0x000000, 0x000000, " ")
			end

			percent = (x * y) / (widthOfImage * heightOfImage)
			xPos = xPos + 2
		end
		xPos = x
		yPos = yPos + 1
	end

	ecs.drawOldPixels(oldPixels)
end

local function drawDistanceMeter()
	local width = 4
	local xPos, yPos = widthOfImage - 3 - width, 3
	buffer.square(xPos, yPos, width + 2, #currentPalette * 2 + 2, 0x000000, 0x000000, " ")
	yPos = yPos + 1
	xPos = xPos + 1
	for i = #currentPalette, 1, -1 do
		buffer.square(xPos, yPos, width, 2, currentPalette[i], 0x000000, " ")
		yPos = yPos + 2
	end
end

local xOld, yOld = gpu.getResolution()
gpu.setResolution(100, 50)
buffer.start()

gui()
ecs.square(1, 2, widthOfImage, heightOfImage - 1, 0x000000)
buffer.square(1, 2, widthOfImage, heightOfImage - 1, 0x000000, 0x000000, " ")
capture(1, 1)
drawDistanceMeter()
buffer.draw()
gui()

while true do
	local e = {event.pull()}
	if e[1] == "touch" then
		for key in pairs(topObjects) do
			if ecs.clickedAtArea(e[3], e[4], topObjects[key][1], topObjects[key][2], topObjects[key][3], topObjects[key][4]) then
				currentTopObject = topObjects[key][5]
				gui()

				if key == "Camera" then

					local action = context.menu(topObjects[key][1] - 1, 2, {"About the program"}, {"Exit"})

					if action == "About the program" then

						local text = "This program is a test library dual image buffer, is written to check the adequacy of some functions. The idea stale in some tough guy from the forum CC, but a bit modified in the GUI-term. So it goes."
						
						ecs.universalWindow("auto", "auto", 36, 0xeeeeee, true, {"EmptyLine"}, {"CenterText", 0x000000, "About the program \"Camera\""}, {"EmptyLine"}, {"TextField", 9, 0xFFFFFF, 0x000000, 0xaaaaaa, ecs.colors.blue, text}, {"EmptyLine"}, {"Button", {0x999999, 0xffffff, "OK"}})

					elseif action == "Exit" then
						gpu.setResolution(xOld, yOld)
						ecs.prepareToExit()
						return
					end

				elseif key == "To take a photo" then
					capture(1, 1)
					drawDistanceMeter()
					buffer.draw()
					gui()
				elseif key == "render Settings" then
					
					local action = context.menu(topObjects[key][1] - 1, 2, {"Scale"}, {"Range Settings"})

					if action == "Scale" then
						local data = ecs.universalWindow("auto", "auto", 36, 0xeeeeee, true, {"EmptyLine"}, {"CenterText", 0x000000, "Change the scale:"}, {"EmptyLine"}, {"Slider", 0x262626, 0x880000, 1, 100, 100, "", "%"}, {"EmptyLine"}, {"Button", {0x999999, 0xffffff, "OK"}})
						
						local part = (0.04 - 0.01) / 100
						local percent = part * data[1]

						step = percent
						from = step * 25

						capture(1, 1)
						drawDistanceMeter()
						buffer.draw()
						gui()
					elseif action == "Range Settings" then
						local data = ecs.universalWindow("auto", "auto", 36, 0xeeeeee, true, {"EmptyLine"}, {"CenterText", 0x000000, "Change the range:"}, {"EmptyLine"}, {"Slider", 0x262626, 0x880000, 10, 36, distanceLimit, "", " blocks"}, {"EmptyLine"}, {"Button", {0x999999, 0xffffff, "OK"}})

						distanceLimit = data[1]

						capture(1, 1)
						drawDistanceMeter()
						buffer.draw()
						gui()
					end

				elseif key == "Palette" then
					
					local action = context.menu(topObjects[key][1] - 1, 2, {"Black and White"}, {"thermal"})

					if action == "Black and White" then
						currentPalette = grayScale
						capture(1, 1)
						drawDistanceMeter()
						buffer.draw()
						gui()
					elseif action == "thermal" then
						currentPalette = rainbow
						capture(1, 1)
						drawDistanceMeter()
						buffer.draw()
						gui()
					end
				end

				currentTopObject = 0
				gui()
				break
			end			
		end
	end
end












