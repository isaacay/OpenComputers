
local component = require("component")
local event = require("event")
local unicode = require("unicode")
local serialization = require("serialization")
local fs = require("filesystem")

--image
local colorlib = require("colorlib")
local buffer = require("doubleBuffering")
local context = require("context")
local bigLetters = require("bigLetters")
local ecs = require("ECSAPI")
local palette = require("palette")

local printer
local gpu = component.gpu
local hologramAvailable = component.isAvailable("hologram")

------------------------------------------------------------------------------------------------------------------------

if component.isAvailable("printer3d") then
	printer = component.printer3d
else
	ecs.error("This program requires a 3D-printer to work.")
end

------------------------------------------------------------------------------------------------------------------------

local colors = {
	drawingZoneCYKA = 0xCCCCCC,
	drawingZoneBackground = 0xFFFFFF,
	drawingZoneStartPoint = 0x262626,
	drawingZoneEndPoint = 0x555555,
	drawingZoneSelection = 0xFF5555,
	toolbarBackground = 0xEEEEEE,
	toolbarText = 0x262626,
	toolbarKeyText = 0x000000,
	toolbarValueText = 0x666666,
	toolbarBigLetters = 0x262626,
	shapeNumbersText = 0xFFFFFF,
	shapeNumbersBackground = 0xAAAAAA,
	shapeNumbersActiveBackground = ecs.colors.blue,
	shapeNumbersActiveText = 0xFFFFFF,
	toolbarInfoBackground = 0x262626,
	toolbarInfoText = 0xFFFFFF,
	toolbarButtonBackground = 0xCCCCCC,
	toolbarButtonText = 0x262626,
}

local xOld, yOld = gpu.getResolution()
local xSize, ySize = 160, 50
gpu.setResolution(160, 50)
buffer.start()

local widthOfToolbar = 33
local xToolbar = xSize - widthOfToolbar + 1
local widthOfDrawingCYKA = xSize - widthOfToolbar

local currentLayer = 1
local currentShape = 1
local maxShapeCount = printer.getMaxShapeCount()
if maxShapeCount > 24 then maxShapeCount = 24 end
local currentMode = 1
local modes = {
	"inactive",
	"active"
}
local currentTexture = "planks_oak"
local currentTint = ecs.colors.orange
local useTint = false
local showLayerOnHologram = true

local pixelWidth = 6
local pixelHeight = 3
local drawingZoneWidth = pixelWidth * 16
local drawingZoneHeight = pixelHeight * 16
local xDrawingZone = math.floor(widthOfDrawingCYKA / 2 - drawingZoneWidth / 2)
local yDrawingZone = 3

local shapeColors = {}
local HUE = 0
local HUEAdder = math.floor(360 / maxShapeCount)
for i = 1, maxShapeCount do
	shapeColors[i] = colorlib.HSBtoHEX(HUE, 100, 100)
	HUE = HUE + HUEAdder
end
HUE, HUEAdder = nil, nil

local model = {}

------------------------------------------------------------------------------------------------------------------------

local function swap(a, b)
	return b, a
end

local function correctShapeCoords(shapeNumber)
	if model.shapes[shapeNumber] then
		if model.shapes[shapeNumber][1] >= model.shapes[currentShape][4] then
			model.shapes[shapeNumber][1], model.shapes[currentShape][4] = swap(model.shapes[currentShape][1], model.shapes[currentShape][4])
			model.shapes[shapeNumber][1] = model.shapes[shapeNumber][1] - 1
			model.shapes[shapeNumber][4] = model.shapes[shapeNumber][4] + 1
			-- ecs.error("СУКА")
		end
		if model.shapes[shapeNumber][2] >= model.shapes[currentShape][5] then
			model.shapes[shapeNumber][2], model.shapes[currentShape][5] = swap(model.shapes[currentShape][2], model.shapes[currentShape][5])
			model.shapes[shapeNumber][2] = model.shapes[shapeNumber][2] - 1
			model.shapes[shapeNumber][5] = model.shapes[shapeNumber][5] + 1
			-- ecs.error("СУКА2")
		end
		if model.shapes[shapeNumber][3] >= model.shapes[currentShape][6] then
			model.shapes[shapeNumber][3], model.shapes[currentShape][6] = swap(model.shapes[currentShape][3], model.shapes[currentShape][6])
			model.shapes[shapeNumber][3] = model.shapes[shapeNumber][3] - 1
			model.shapes[shapeNumber][6] = model.shapes[shapeNumber][6] + 1
			-- ecs.error("СУКА3")
		end
	end
end

local function loadShapeParameters()
	if model.shapes[currentShape] then
		currentTexture = model.shapes[currentShape].texture
		if model.shapes[currentShape].tint then
			currentTint = model.shapes[currentShape].tint
			useTint = true
		else
			useTint = false
		end
	end
end

local function fixModelArray()
	model.label = model.label or "Sample label"
	model.tooltip = model.tooltip or "Sample tooltip"
	model.lightLevel = model.lightLevel or 0
	model.emitRedstone = model.emitRedstone or false
	model.buttonMode = model.buttonMode or false
	model.collidable = model.collidable or {true, true}
	model.shapes = model.shapes or {}

	currentLayer = 1
	currentShape = 1
	currentMode = 1
	loadShapeParameters()
end

--Объекты для тача
local obj = {}
local function newObj(class, name, ...)
	obj[class] = obj[class] or {}
	obj[class][name] = {...}
end

local function drawShapeNumbers(x, y)
	local counter = 1
	local xStart = x

	for j = 1, 4 do
		for i = 1, 6 do
			if currentShape == counter then
				newObj("ShapeNumbers", counter, buffer.button(x, y, 4, 1, shapeColors[counter], 0xFFFFFF - shapeColors[counter], tostring(counter)))
				-- newObj("ShapeNumbers", counter, buffer.button(x, y, 4, 1, colors.shapeNumbersActiveBackground, colors.shapeNumbersActiveText, tostring(counter)))
			else
				newObj("ShapeNumbers", counter, buffer.button(x, y, 4, 1, colors.shapeNumbersBackground, colors.shapeNumbersText, tostring(counter)))
			end

			x = x + 5
			counter = counter + 1
			if counter > maxShapeCount then return end
		end
		x = xStart
		y = y + 2
	end
end

local function toolBarInfoLine(y, text)
	buffer.square(xToolbar, y, widthOfToolbar, 1, colors.toolbarInfoBackground, 0xFFFFFF, " ")
	buffer.text(xToolbar + 1, y, colors.toolbarInfoText, text)
end

local function centerText(y, color, text)
	local x = math.floor(xToolbar + widthOfToolbar / 2 - unicode.len(text) / 2)
	buffer.text(x, y, color, text)
end

local function addButton(y, back, fore, text)
	newObj("ToolbarButtons", text, buffer.button(xToolbar + 2, y, widthOfToolbar - 4, 3, back, fore, text))
end

local function printKeyValue(x, y, keyColor, valueColor, key, value, limit)
	local totalLength = unicode.len(key .. ": " .. value) 
	if totalLength > limit then
		value = unicode.sub(value, 1, limit - unicode.len(key .. ": ") - 1) .. "…"
	end
	buffer.text(x, y, keyColor, key .. ":")
	buffer.text(x + unicode.len(key) + 2, y, valueColor, value)
end

local function getShapeCoords()
	local coords = "element is not created"
	if model.shapes[currentShape] then
		coords = "(" .. model.shapes[currentShape][1] .. "," .. model.shapes[currentShape][2] .. "," .. model.shapes[currentShape][3] .. ");(" .. model.shapes[currentShape][4] .. "," .. model.shapes[currentShape][5] .. "," .. model.shapes[currentShape][6] .. ")"
	end
	return coords
end

local function fixNumber(number)
	if number < 10 then number = "0" .. number end
	return tostring(number)
end

local function drawToolbar()
	buffer.square(xToolbar, 1, widthOfToolbar, ySize, colors.toolbarBackground, 0xFFFFFF, " ")

	local x = xToolbar + 8
	local y = 3

	--Текущий слой
	bigLetters.drawText(x, y, colors.toolbarBigLetters, fixNumber(currentLayer))
	y = y + 6
	centerText(y, colors.toolbarText, "Current layer")

	--Управление элементом
	y = y + 2
	x = xToolbar + 2
	toolBarInfoLine(y, "model Management"); y = y + 2
	printKeyValue(x, y, colors.toolbarKeyText, colors.toolbarValueText, "Name", model.label, widthOfToolbar - 4); y = y + 1
	printKeyValue(x, y, colors.toolbarKeyText, colors.toolbarValueText, "Description", model.tooltip, widthOfToolbar - 4); y = y + 1
	printKeyValue(x, y, colors.toolbarKeyText, colors.toolbarValueText, "Like button", tostring(model.buttonMode), widthOfToolbar - 4); y = y + 1
	printKeyValue(x, y, colors.toolbarKeyText, colors.toolbarValueText, "Redstone signal", tostring(model.emitRedstone), widthOfToolbar - 4); y = y + 1
	printKeyValue(x, y, colors.toolbarKeyText, colors.toolbarValueText, "conflict", tostring(model.collidable[currentMode]), widthOfToolbar - 4); y = y + 1
	printKeyValue(x, y, colors.toolbarKeyText, colors.toolbarValueText, "The level of light", tostring(model.lightLevel), widthOfToolbar - 4); y = y + 1
	y = y + 1
	printKeyValue(x, y, ecs.colors.blue, colors.toolbarValueText, "condition", modes[currentMode], widthOfToolbar - 4); y = y + 1
	y = y + 1
	addButton(y, colors.toolbarButtonBackground, colors.toolbarButtonText, "Change settings"); y = y + 4
	addButton(y, colors.toolbarButtonBackground, colors.toolbarButtonText, "Type"); y = y + 4
	toolBarInfoLine(y, "Управление элементом " .. currentShape); y = y + 2
	printKeyValue(x, y, colors.toolbarKeyText, colors.toolbarValueText, "Texture", tostring(currentTexture), widthOfToolbar - 4); y = y + 1
	printKeyValue(x, y, colors.toolbarKeyText, colors.toolbarValueText, "shade", ecs.HEXtoString(currentTint, 6, true), widthOfToolbar - 4); y = y + 1
	printKeyValue(x, y, colors.toolbarKeyText, colors.toolbarValueText, "Use shade", tostring(useTint), widthOfToolbar - 4); y = y + 1
	printKeyValue(x, y, colors.toolbarKeyText, colors.toolbarValueText, "position", getShapeCoords(), widthOfToolbar - 4); y = y + 2
	addButton(y, colors.toolbarButtonBackground, colors.toolbarButtonText, "Change settings "); y = y + 4

	--Элементы
	toolBarInfoLine(y, "Select an item"); y = y + 2
	drawShapeNumbers(x, y)
	y = y + 8
end

local function drawTopMenu(selected)
	obj["TopMenu"] = ecs.drawTopMenu(1, 1, xSize - widthOfToolbar, colors.toolbarBackground, selected, {"File", 0x262626}, {"Projector", 0x262626}, {"About the program", 0x262626})
end

local function renderCurrentLayerOnHologram(xStart, yStart, zStart)
	if showLayerOnHologram then
		for i = yStart, yStart + 16 do
			component.hologram.set(xStart - 1, i, zStart + (16 - currentLayer), 3)
			component.hologram.set(xStart + 16, i, zStart + (16 - currentLayer), 3)
		end

		for i = (xStart-1), (xStart + 16) do
			component.hologram.set(i, yStart - 1, zStart + (16 - currentLayer), 3)
			component.hologram.set(i, yStart + 16, zStart + (16 - currentLayer), 3)
		end
	end
end

local function drawModelOnHologram()
	if hologramAvailable then
		local xStart, yStart, zStart = 16,4,16
		component.hologram.clear()

		for shape in pairs(model.shapes) do
			if (currentMode == 2 and model.shapes[shape].state) or (currentMode == 1 and not model.shapes[shape].state) then
				if model.shapes[shape] then
					for x = model.shapes[shape][1], model.shapes[shape][4] - 1 do
						for y = model.shapes[shape][2], model.shapes[shape][5] - 1 do
							for z = model.shapes[shape][3], model.shapes[shape][6] - 1 do
								--Эта хуйня для того, чтобы в разных режимах не ебало мозг
								if (model.shapes[shape].state and currentMode == 2) or (not model.shapes[shape].state and currentMode == 1) then
									if shape == currentShape then
										component.hologram.set(xStart + x, yStart + y, zStart + 15 - z, 2)
									else
										component.hologram.set(xStart + x, yStart + y, zStart + 15 - z, 1)
									end
								end
							end
						end
					end
				end
			end
		end

		renderCurrentLayerOnHologram(xStart, yStart, zStart)
	end
end

local function printModel(count)
	printer.reset()
	printer.setLabel(model.label)
	printer.setTooltip(model.tooltip)
	printer.setCollidable(model.collidable[1], model.collidable[2])
	printer.setLightLevel(model.lightLevel)
	printer.setRedstoneEmitter(model.emitRedstone)
	printer.setButtonMode(model.buttonMode)
	
	for i in pairs(model.shapes) do
		printer.addShape(
			model.shapes[i][1],
			(model.shapes[i][2]),
			(model.shapes[i][3]),
			
			model.shapes[i][4],
			(model.shapes[i][5]),
			(model.shapes[i][6]),
			
			model.shapes[i].texture,
			model.shapes[i].state,
			model.shapes[i].tint
		)
	end

	local success, reason = printer.commit(count)
	if not success then
		ecs.error("printing Error: " .. reason)
	end
end

local function drawPixel(x, y, width, height, color, trasparency)
	buffer.square(xDrawingZone + x * pixelWidth - pixelWidth, yDrawingZone + y * pixelHeight - pixelHeight, width * pixelWidth, height * pixelHeight, color, 0xFFFFFF, " ", trasparency)
end

local function setka()
	drawPixel(1, 1, 16, 16, colors.drawingZoneBackground)
	local shade = colors.drawingZoneBackground - 0x111111

	for j = 1, 16 do
		for i = 1, 16 do
			if j % 2 == 0 then
				if i % 2 == 0 then
					drawPixel(i, j, 1, 1, shade)
				end
			else
				if i % 2 ~= 0 then
					drawPixel(i, j, 1, 1, shade)
				end
			end
		end
	end
end

local function drawDrawingZone()

	setka()

	local selectionStartPoint = {}
	local selectionEndPoint = {}
	local trasparency = 70

	for shape in pairs(model.shapes) do

		--Если по состояниям все заебок
		if ((model.shapes[shape].state and currentMode == 2) or (not model.shapes[shape].state and currentMode == 1)) then

			selectionStartPoint.x = model.shapes[shape][1] + 1
			selectionStartPoint.y = model.shapes[shape][2] + 1
			selectionStartPoint.z = model.shapes[shape][3] + 1
			selectionEndPoint.x = model.shapes[shape][4]
			selectionEndPoint.y = model.shapes[shape][5]
			selectionEndPoint.z = model.shapes[shape][6]
			local yDifference = selectionEndPoint.y - selectionStartPoint.y + 1

			if currentLayer >= selectionStartPoint.z and currentLayer <= selectionEndPoint.z then
				if shape ~= currentShape then
					local h, s, b = colorlib.HEXtoHSB(shapeColors[shape])
					s = 30
					-- ecs.error("draw")
					drawPixel(selectionStartPoint.x, 18 - selectionStartPoint.y - yDifference, selectionEndPoint.x - selectionStartPoint.x + 1, yDifference, colorlib.HSBtoHEX(h, s, b))
					-- drawPixel(selectionStartPoint.x, selectionStartPoint.z, selectionEndPoint.x - selectionStartPoint.x + 1, selectionEndPoint.z - selectionStartPoint.z + 1, shapeColors[shape], trasparency)
				else
					drawPixel(selectionStartPoint.x, 18 - selectionStartPoint.y - yDifference, selectionEndPoint.x - selectionStartPoint.x + 1, yDifference, shapeColors[shape])
				
					--Точки
					if selectionStartPoint.z == currentLayer then
						drawPixel(selectionStartPoint.x, 17 - selectionStartPoint.y, 1, 1, colors.drawingZoneStartPoint)
					end

					if selectionEndPoint.z == currentLayer then
						drawPixel(selectionEndPoint.x, 17 - selectionEndPoint.y, 1, 1, colors.drawingZoneEndPoint)
					end
				end
			end
		end
	end
end

local function drawAll()
	buffer.square(1, 2, xSize, ySize, colors.drawingZoneCYKA, 0xFFFFFF, " ")
	drawDrawingZone()
	drawToolbar()
	buffer.draw()
	drawTopMenu(0)
end

local function save(path)
	fs.makeDirectory(fs.path(path) or "")
	local file = io.open(path, "w")
	file:write(serialization.serialize(model))
	file:close()
end

local function open(path)
	if fs.exists(path) then
		if ecs.getFileFormat(path) == ".3dm" then
			local file = io.open(path, "r")
			model = serialization.unserialize(file:read("*a"))
			fixModelArray()
			file:close()
			drawAll()
			drawModelOnHologram()
		else
			ecs.error("The file has an unknown format. Supported models only format .3dm.")
		end
	else
		ecs.error("File \"" .. path .. "\" does not exist")
	end
end

------------------------------------------------------------------------------------------------------------------------

model = {}
fixModelArray()

local args = {...}
if args[1] == "open" or args[1] == "-o" then
	open(args[2])
end

drawAll()
drawModelOnHologram()

------------------------------------------------------------------------------------------------------------------------

local startPointSelected = false
local xShapeStart, yShapeStart, zShapeStart, xShapeEnd, yShapeEnd, zShapeEnd 

while true do
	local e = { event.pull() }
	if e[1] == "touch" then
		--Если кликнули в зону рисования
		if ecs.clickedAtArea(e[3], e[4], xDrawingZone, yDrawingZone, xDrawingZone + drawingZoneWidth - 1, yDrawingZone + drawingZoneHeight - 1) then
			if not startPointSelected then
				xShapeStart = math.ceil((e[3] - xDrawingZone + 1) / pixelWidth)
				yShapeStart = math.ceil((e[4] - yDrawingZone + 1) / pixelHeight)
				zShapeStart = currentLayer
				
				startPointSelected = true
				model.shapes[currentShape] = nil
				-- buffer.square(xDrawingZone, yDrawingZone, drawingZoneWidth, drawingZoneHeight, colors.drawingZoneBackground, 0xFFFFFF, " ")
			
				drawPixel(xShapeStart, yShapeStart, 1, 1, colors.drawingZoneStartPoint)
			
				buffer.draw()
			else
				xShapeEnd = math.ceil((e[3] - xDrawingZone + 1) / pixelWidth)
				yShapeEnd = math.ceil((e[4] - yDrawingZone + 1) / pixelHeight)
				zShapeEnd = currentLayer
				
				drawPixel(xShapeEnd, yShapeEnd, 1, 1, colors.drawingZoneEndPoint)
				startPointSelected = false

				model.shapes[currentShape] = {
					xShapeStart - 1,
					17 - yShapeStart - 1,
					zShapeStart - 1,
					
					xShapeEnd,
					17 - yShapeEnd,
					zShapeEnd,
					
					texture = currentTexture,
				}

				model.shapes[currentShape].state = nil
				model.shapes[currentShape].tint = nil
				if currentMode == 2 then model.shapes[currentShape].state = true end
				if useTint then model.shapes[currentShape].tint = currentTint end

				correctShapeCoords(currentShape)

				drawAll()
				drawModelOnHologram()
			end
		else
			for key in pairs(obj.ShapeNumbers) do
				if ecs.clickedAtArea(e[3], e[4], obj.ShapeNumbers[key][1], obj.ShapeNumbers[key][2], obj.ShapeNumbers[key][3], obj.ShapeNumbers[key][4]) then
					currentShape = key
					loadShapeParameters()
					drawAll()
					drawModelOnHologram()
					break
				end
			end

			for key in pairs(obj.ToolbarButtons) do
				if ecs.clickedAtArea(e[3], e[4], obj.ToolbarButtons[key][1], obj.ToolbarButtons[key][2], obj.ToolbarButtons[key][3], obj.ToolbarButtons[key][4]) then
					buffer.button(obj.ToolbarButtons[key][1], obj.ToolbarButtons[key][2], widthOfToolbar - 4, 3, ecs.colors.blue, 0xFFFFFF, key)
					buffer.draw()
					os.sleep(0.2)

					if key == "Type" then
						local data = ecs.universalWindow("auto", "auto", 36, 0x262626, true,
							{"EmptyLine"},
							{"CenterText", ecs.colors.orange, "Type"},
							{"EmptyLine"},
							{"Slider", 0xFFFFFF, ecs.colors.orange, 1, 64, 1, "", " pcs"},
							{"EmptyLine"},
							{"Button", {ecs.colors.orange, 0xffffff, "OK"}, {0x999999, 0xffffff, "Cancel"}}
						)

						if data[2] == "OK" then
							printModel(data[1])
						end

					elseif key == "Change settings" then
						local data = ecs.universalWindow("auto", "auto", 36, 0x262626, true,
							{"EmptyLine"},
							{"CenterText", ecs.colors.orange, "model parameters"},
							{"EmptyLine"},
							{"Input", 0xFFFFFF, ecs.colors.orange, model.label},
							{"Input", 0xFFFFFF, ecs.colors.orange, model.tooltip},
							{"Selector", 0xFFFFFF, ecs.colors.orange, "Inactive", "active"},
							{"EmptyLine"},
							{"Switch", ecs.colors.orange, 0xffffff, 0xFFFFFF, "Like button", model.buttonMode},
							{"EmptyLine"},
							{"Switch", ecs.colors.orange, 0xffffff, 0xFFFFFF, "Redstone signal", model.emitRedstone},
							{"EmptyLine"},
							{"Switch", ecs.colors.orange, 0xffffff, 0xFFFFFF, "conflict", model.collidable[currentMode]},
							{"EmptyLine"},
							{"Slider", 0xFFFFFF, ecs.colors.orange, 0, 15, model.lightLevel, "The level of light: ", ""},
							{"EmptyLine"},
							{"Button", {ecs.colors.orange, 0xffffff, "OK"}, {0x999999, 0xffffff, "Cancel"}}
						)

						if data[8] == "OK" then
							model.label = data[1] or "Sample label"
							model.tooltip = data[2] or "Sample tooltip"
							if data[3] == "active" then
								currentMode = 2
							else
								currentMode = 1
							end
							model.buttonMode = data[4]
							model.emitRedstone = data[5]
							model.collidable[currentMode] = data[6]
							model.lightLevel = data[7]
						end

					elseif key == "Change settings " then
						local data = ecs.universalWindow("auto", "auto", 36, 0x262626, true,
							{"EmptyLine"},
							{"CenterText", ecs.colors.orange, "Parameters element"},
							{"EmptyLine"},
							{"Input", 0xFFFFFF, ecs.colors.orange, currentTexture},
							{"Color", "shade", currentTint},
							{"EmptyLine"},
							{"Switch", ecs.colors.orange, 0xffffff, 0xFFFFFF, "Use shade", useTint},
							{"EmptyLine"},
							{"Button", {ecs.colors.orange, 0xffffff, "OK"}, {0x999999, 0xffffff, "Cancel"}}
						)

						if data[4] == "OK" then
							currentTexture = data[1]
							currentTint = data[2]
							useTint = data[3]

							if model.shapes[currentShape] then
								model.shapes[currentShape].texture = currentTexture
								if useTint then
									model.shapes[currentShape].tint = currentTint
								else
									model.shapes[currentShape].tint = nil
								end
							end
						end
					end

					drawAll()
					drawModelOnHologram()	
					break
				end
			end

			for key in pairs(obj.TopMenu) do
				if ecs.clickedAtArea(e[3], e[4], obj.TopMenu[key][1], obj.TopMenu[key][2], obj.TopMenu[key][3], obj.TopMenu[key][4]) then
					drawTopMenu(obj.TopMenu[key][5])
					-- buffer.button(obj.TopMenu[key][1] - 1, obj.TopMenu[key][2], unicode.len(key) + 2, 1, ecs.colors.blue, 0xFFFFFF, key)
					-- buffer.draw()

					local action
					if key == "File" then
						action = context.menu(obj.TopMenu[key][1] - 1, obj.TopMenu[key][2] + 1, {"New"}, "-", {"Open"}, {"retain"}, "-", {"Exit"})
					elseif key == "Projector" then
						action = context.menu(obj.TopMenu[key][1] - 1, obj.TopMenu[key][2] + 1, {"Scale", not hologramAvailable}, {"Offset projection", not hologramAvailable}, {"Change the palette", not hologramAvailable}, "-", {"Enable display layer", not hologramAvailable}, {"Disable display layer", not hologramAvailable}, "-", {"Enable rotation", not hologramAvailable}, {"Disable rotation", not hologramAvailable})
					elseif key == "About the program" then
						ecs.universalWindow("auto", "auto", 36, 0x262626, true, 
							{"EmptyLine"},
							{"CenterText", ecs.colors.orange, "3DPrint v3.0"}, 
							{"EmptyLine"},
							--{"CenterText", 0xFFFFFF, "Автор:"},
							--{"CenterText", 0xBBBBBB, "Тимофеев Игорь"},
							--{"CenterText", 0xBBBBBB, "vk.com/id7799889"},
							--{"EmptyLine"},
							--{"CenterText", 0xFFFFFF, "Тестеры:"},
							--{"CenterText", 0xBBBBBB, "Семёнов Сeмён"}, 
							--{"CenterText", 0xBBBBBB, "vk.com/day_z_utes"},
							--{"CenterText", 0xBBBBBB, "Бесфамильный Яков"},
							--{"CenterText", 0xBBBBBB, "vk.com/mathem"},
							--{"CenterText", 0xBBBBBB, "Егор Палиев"},
							--{"CenterText", 0xBBBBBB, "vk.com/mrherobrine"},
							{"EmptyLine"},
							{"Button", {ecs.colors.orange, 0xffffff, "OK"}}
						)
					end

					if action == "retain" then
						local data = ecs.universalWindow("auto", "auto", 30, 0x262626, true, 
							{"EmptyLine"},
							{"CenterText", ecs.colors.orange, "Save as"},
							{"EmptyLine"},
							{"Input", 0xFFFFFF, ecs.colors.orange, "Path to"},
							{"Selector", 0xFFFFFF, ecs.colors.orange, ".3dm"},
							{"EmptyLine"},
							{"Button", {ecs.colors.orange, 0xffffff, "OK"}, {0x999999, 0xffffff, "Cancel"}}
						)
						if data[3] == "OK" then
							data[1] = data[1] or "Untitled"
							local filename = data[1] .. data[2]
							save(filename)
						end
					elseif action == "Open" then
						local data = ecs.universalWindow("auto", "auto", 30, 0x262626, true,
							{"EmptyLine"},
							{"CenterText", ecs.colors.orange, "Open"},
							{"EmptyLine"},
							{"Input", 0xFFFFFF, ecs.colors.orange, "Path to"},
							{"EmptyLine"},
							{"Button", {ecs.colors.orange, 0xffffff, "OK"}, {0x999999, 0xffffff, "Cancel"}}
						)
						if data[2] == "OK" then
							open(data[1])
						end
					elseif action == "New" then
						model = {}
						fixModelArray()
						drawAll()
						drawModelOnHologram()
					elseif action == "Exit" then
						gpu.setResolution(xOld, yOld)
						buffer.start()	
						buffer.draw(true)
						if hologramAvailable then component.hologram.clear() end
						return
					elseif action == "Scale" then
						local data = ecs.universalWindow("auto", "auto", 36, 0x262626, true, 
							{"EmptyLine"},
							{"CenterText", ecs.colors.orange, "Change the scale"},
							{"EmptyLine"}, 
							{"Slider", ecs.colors.white, ecs.colors.orange, 1, 100, math.ceil(component.hologram.getScale() * 100 / 4), "", "%"},
							{"EmptyLine"},
							{"Button", {ecs.colors.orange, 0xffffff, "OK"}, {0x999999, 0xffffff, "Cancel"}}
						)

						if data[2] == "OK" then
							component.hologram.setScale(data[1] * 4 / 100)
						end
					elseif action == "Offset projection" then
						local translation = { component.hologram.getTranslation() }
						local data = ecs.universalWindow("auto", "auto", 36, 0x262626, true, 
							{"EmptyLine"},
							{"CenterText", ecs.colors.orange, "Offset projection"},
							{"EmptyLine"}, 
							{"CenterText", 0xFFFFFF, "These options allow you to project"},
							{"CenterText", 0xFFFFFF, "a hologram at a distance from"},
							{"CenterText", 0xFFFFFF, "the projector. Handy if you want to hide the"},
							{"CenterText", 0xFFFFFF, "projector from prying eyes."},
							{"EmptyLine"}, 
							{"Slider", 0xFFFFFF, ecs.colors.orange, 1, 100, translation[1] * 100, "Axis X: ", "%"},
							{"Slider", 0xFFFFFF, ecs.colors.orange, 1, 100, translation[2] * 100, "Axis Y: ", "%"},
							{"Slider", 0xFFFFFF, ecs.colors.orange, 1, 100, translation[3] * 100, "Axis Z: ", "%"},
							{"EmptyLine"},
							{"Button", {ecs.colors.orange, 0xffffff, "OK"}, {0x999999, 0xffffff, "Cancel"}}
						)

						if data[4] == "OK" then
							component.hologram.setTranslation(data[1] / 100, data[2] / 100, data[3] / 100)
						end
					elseif action == "Change the palette" then
						local data = ecs.universalWindow("auto", "auto", 36, 0x262626, true,
							{"EmptyLine"},
							{"CenterText", ecs.colors.orange, "projector Palette"},
							{"EmptyLine"},
							{"Color", "The color of the active element", component.hologram.getPaletteColor(2)},
							{"Color", "The color of other elements", component.hologram.getPaletteColor(1)},
							{"Color", "Border Color heights", component.hologram.getPaletteColor(3)},
							{"EmptyLine"},
							{"Button", {ecs.colors.orange, 0xffffff, "OK"}, {0x999999, 0xffffff, "Cancel"}}
						)

						if data[4] == "OK" then
							component.hologram.setPaletteColor(2, data[1])
							component.hologram.setPaletteColor(1, data[2])
							component.hologram.setPaletteColor(3, data[3])
						end
					elseif action == "Enable display layer" then
						showLayerOnHologram = true
						drawModelOnHologram()
					elseif action == "Disable display layer" then
						showLayerOnHologram = false
						drawModelOnHologram()
					elseif action == "Enable rotation" then
						component.hologram.setRotationSpeed(15, 0, 23, 0)
					elseif action == "Disable rotation" then
						component.hologram.setRotationSpeed(0, 0, 0, 0)
					end

					drawTopMenu(0)
				end
			end
		end
	elseif e[1] == "scroll" then
		if e[5] == 1 then
			if currentLayer < 16 then
				currentLayer = currentLayer + 1
				drawAll()
				drawModelOnHologram()
			end
		else
			if currentLayer > 1 then
				currentLayer = currentLayer - 1
				drawAll()
				drawModelOnHologram()
			end
		end
	end
end

















