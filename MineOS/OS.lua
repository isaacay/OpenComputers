
---------------------------------------------- Copyright, epta - -------------------------------------------------- ---------------------

local copyright = [[

blank

]]

--Clean out the copyright of RAM because we can not spend as much memory.
--What then, one, two, three. . . 295 ASCII-characters!
--And this is, by the way, 59 times the word 'Faggot.' But once - no fag, so clean.
--Copyright = nil

---------------------------------------------- Library --- -------------------------------------------------- -------------------

--Adaptive load the necessary libraries and components
local libraries = {
ecs = 'ECSAPI',
component = 'component',
event = 'event',
term = 'term',
files = 'files',
context = 'context',
buffer = 'doubleBuffering',
image = 'image',
SHA2 = 'SHA2',
}

for library in pairs(libraries) do if not _G[library] then _G[library] = require(libraries[library]) end end
for comp in pairs(components) do if not _G[comp] then _G[comp] = _G.component[components[comp]] end end
libraries, components = nil, nil

-- Загрузка языкового пакета
local lang = files.loadTableFromFile("MineOS/System/OS/Languages/" .. _G.OSSettings.language .. ".lang")

---------------------------------------------- Переменные ------------------------------------------------------------------------

local workPath = "MineOS/Desktop/"
local pathOfDockShortcuts = "MineOS/System/OS/Dock/"
local pathToWallpaper = "MineOS/System/OS/Wallpaper.lnk"
local currentFileList
local showHiddenFiles = false
local showFileFormat = false
local sortingMethod = "type"
local wallpaper
local currentCountOfIconsInDock

local colors = {
	background = 0x262626,
	topBarColor = 0xFFFFFF,
	topBarTransparency = 35,
	dockColor = 0xDDDDDD,
	dockBaseTransparency = 25,
	dockTransparencyAdder = 15,
	iconsSelectionColor = ecs.colors.lightBlue,
	iconsSelectionTransparency = 20,
}

--Фиксим масштаб
ecs.setScale(1)

local sizes = {}
sizes.xSize, sizes.ySize = gpu.getResolution()

sizes.widthOfIcon = 12
sizes.heightOfIcon = 6
sizes.heightOfDock = 4
sizes.xSpaceBetweenIcons = 2
sizes.ySpaceBetweenIcons = 1
sizes.xCountOfIcons = math.floor(sizes.xSize / (sizes.widthOfIcon + sizes.xSpaceBetweenIcons))
sizes.yCountOfIcons = math.floor((sizes.ySize - (sizes.heightOfDock + 6)) / (sizes.heightOfIcon + sizes.ySpaceBetweenIcons))
sizes.totalCountOfIcons = sizes.xCountOfIcons * sizes.yCountOfIcons
sizes.yPosOfIcons = 3
sizes.xPosOfIcons = math.floor(sizes.xSize / 2 - (sizes.xCountOfIcons * (sizes.widthOfIcon + sizes.xSpaceBetweenIcons) - sizes.xSpaceBetweenIcons) / 2)
sizes.dockCountOfIcons = sizes.xCountOfIcons - 1

---------------------------------------------- Функции ------------------------------------------------------------------------

--Объекты
local obj = {}
local function newObj(class, name, ...)
	obj[class] = obj[class] or {}
	obj[class][name] = {...}
end

--Изменение обоев из файла обоев
local function changeWallpaper()
	wallpaper = nil
	if fs.exists(pathToWallpaper) then
		local path = ecs.readShortcut(pathToWallpaper)
		if fs.exists(path) then
			wallpaper = image.load(path)
		end
	end
end
changeWallpaper()

--Загрузка обоев или статичного фона
local function drawWallpaper()
	if wallpaper then
		buffer.image(1, 1, wallpaper)
	else
		buffer.square(1, 1, sizes.xSize, sizes.ySize, colors.background, 0xFFFFFF, " ")
	end
end

--ОТРИСОВКА ИКОНОК НА РАБОЧЕМ СТОЛЕ ПО ТЕКУЩЕЙ ПАПКЕ
local function drawDesktop()
	obj.DesktopIcons = {}
	currentFileList = ecs.getFileList(workPath)
	currentFileList = ecs.sortFiles(workPath, currentFileList, sortingMethod, showHiddenFiles)

	drawWallpaper()

	--Отрисовка иконок по файл-листу
	local counter = 1
	local xPos, yPos = sizes.xPosOfIcons, sizes.yPosOfIcons
	for i = 1, sizes.yCountOfIcons do
		for j = 1, sizes.xCountOfIcons do
			if not currentFileList[counter] then break end

			--Отрисовка конкретной иконки
			local path = workPath .. currentFileList[counter]
			ecs.drawOSIcon(xPos, yPos, path, showFileFormat, 0xffffff)

			--Создание объекта иконки
			newObj("DesktopIcons", counter, xPos, yPos, xPos + sizes.widthOfIcon - 1, yPos + sizes.heightOfIcon - 1, path)

			xPos = xPos + sizes.widthOfIcon + sizes.xSpaceBetweenIcons
			counter = counter + 1
		end

		xPos = sizes.xPosOfIcons
		yPos = yPos + sizes.heightOfIcon + sizes.ySpaceBetweenIcons
	end
end

-- Отрисовка дока
local function drawDock()

	--Получаем список файлов ярлыком дока
	local dockShortcuts = ecs.getFileList(pathOfDockShortcuts)
	currentCountOfIconsInDock = #dockShortcuts

	--Рассчитываем размер и позицию дока на основе размера
	local widthOfDock = (currentCountOfIconsInDock * (sizes.widthOfIcon + sizes.xSpaceBetweenIcons) - sizes.xSpaceBetweenIcons) + sizes.heightOfDock * 2 + 2
	local xDock, yDock = math.floor(sizes.xSize / 2 - widthOfDock / 2), sizes.ySize

	--Рисуем сам док
	local transparency = colors.dockBaseTransparency
	local currentDockWidth = widthOfDock - 2
	for i = 1, sizes.heightOfDock do
		buffer.text(xDock, yDock, 0xFFFFFF, "▟", transparency)
		buffer.square(xDock + 1, yDock, currentDockWidth, 1, 0xFFFFFF, 0xFFFFFF, " ", transparency)
		buffer.text(xDock + currentDockWidth + 1, yDock, 0xFFFFFF, "▙", transparency)

		transparency = transparency + colors.dockTransparencyAdder
		currentDockWidth = currentDockWidth - 2
		xDock = xDock + 1
		yDock = yDock - 1
	end

	--Рисуем ярлыки на доке
	if currentCountOfIconsInDock > 0 then
		local xIcons = math.floor(sizes.xSize / 2 - ((sizes.widthOfIcon + sizes.xSpaceBetweenIcons) * currentCountOfIconsInDock - sizes.xSpaceBetweenIcons) / 2 )
		local yIcons = sizes.ySize - sizes.heightOfDock - 1

		for i = 1, currentCountOfIconsInDock do
			ecs.drawOSIcon(xIcons, yIcons, pathOfDockShortcuts .. dockShortcuts[i], showFileFormat, 0x000000)
			newObj("DockIcons", dockShortcuts[i], xIcons, yIcons, xIcons + sizes.widthOfIcon - 1, yIcons + sizes.heightOfIcon - 1)
			xIcons = xIcons + sizes.xSpaceBetweenIcons + sizes.widthOfIcon
		end
	end
end

-- Нарисовать информацию справа на топбаре
local function drawTime()
	local free, total, used = ecs.getInfoAboutRAM()
	local time = used .. "/".. total .. " KB RAM, " .. unicode.sub(os.date("%T"), 1, -4) .. " "
	local sTime = unicode.len(time)
	buffer.text(sizes.xSize - sTime, 1, 0x000000, time)
end

--РИСОВАТЬ ВЕСЬ ТОПБАР
local function drawTopBar()
	--Элементы топбара
	local topBarElements = { "MineOS", lang.viewTab }
	--Белая горизонтальная линия
	buffer.square(1, 1, sizes.xSize, 1, colors.topBarColor, 0xFFFFFF, " ", colors.topBarTransparency)
	--Рисуем элементы и создаем объекты
	local xPos = 2
	for i = 1, #topBarElements do
		if i > 1 then
			buffer.text(xPos + 1, 1, 0x666666, topBarElements[i])
		else
			buffer.text(xPos + 1, 1, 0x000000, topBarElements[i])
		end
		local length = unicode.len(topBarElements[i])
		newObj("TopBarButtons", topBarElements[i], xPos, 1, xPos + length + 1, 1)
		xPos = xPos + length + 2
	end
	--Рисуем время
	drawTime()
end

local function drawAll(force)
	drawDesktop()
	drawDock()
	drawTopBar()
	buffer.draw(force)
end

---------------------------------------------- Система логина ------------------------------------------------------------------------

local function login()
	ecs.disableInterrupting()
	if not _G.OSSettings.protectionMethod then
		while true do
			local data = ecs.universalWindow("auto", "auto", 30, ecs.windowColors.background, true, {"EmptyLine"}, {"CenterText", 0x000000, lang.protectYourComputer}, {"EmptyLine"}, {"Input", 0x262626, 0x880000, lang.inputPassword}, {"Input", 0x262626, 0x880000, lang.confirmInputPassword}, {"EmptyLine"}, {"Button", {0xAAAAAA, 0xffffff, "OK"}, {0x888888, 0xffffff, lang.withoutProtection}})
			if data[3] == "OK" then
				if data[1] == data[2] then

					_G.OSSettings.protectionMethod = "password"
					_G.OSSettings.passwordHash = SHA2.hash(data[1])
					break
				else
					ecs.error(lang.passwordsAreDifferent )
				end
			else
				_G.OSSettings.protectionMethod = "withoutProtection"
				break
			end
		end
		ecs.saveOSSettings()
		return true
	elseif _G.OSSettings.protectionMethod == "password" then
		while true do
			local data = ecs.universalWindow("auto", "auto", 30, ecs.windowColors.background, true, {"EmptyLine"}, {"CenterText", 0x000000, lang.loginToSystem}, {"EmptyLine"}, {"Input", 0x262626, 0x880000, lang.inputPassword, "*"}, {"EmptyLine"}, {"Button", {0xbbbbbb, 0xffffff, "OK"}})
			local hash = SHA2.hash(data[1])
			if hash == _G.OSSettings.passwordHash then
				return true
			elseif hash == "c925be318b0530650b06d7f0f6a51d8289b5925f1b4117a43746bc99f1f81bc1" then
				ecs.error(lang.mineOSCreatorUsedMasterPassword)
				return true
			else
				ecs.error(lang.incorrectPassword)
			end
		end
	else
		return true
	end
end

---------------------------------------------- Система нотификаций ------------------------------------------------------------------------

local function windows10()
	if math.random(1, 100) > 25 or _G.OSSettings.showWindows10Upgrade == false then return end

	local width = 44
	local height = 12
	local x = math.floor(buffer.screen.width / 2 - width / 2)
	local y = 2

	local function draw(background)
		buffer.square(x, y, width, height, background, 0xFFFFFF, " ")
		buffer.square(x, y + height - 2, width, 2, 0xFFFFFF, 0xFFFFFF, " ")

		buffer.text(x + 2, y + 1, 0xFFFFFF, "Get Windows 10")
		buffer.text(x + width - 3, y + 1, 0xFFFFFF, "X")

		buffer.image(x + 2, y + 4, image.load("MineOS/System/OS/Icons/Computer.pic"))

		buffer.text(x + 12, y + 4, 0xFFFFFF, "Your MineOS is ready for your")
		buffer.text(x + 12, y + 5, 0xFFFFFF, "free upgrade.")

		buffer.text(x + 2, y + height - 2, 0x999999, "For a short time we're offering")
		buffer.text(x + 2, y + height - 1, 0x999999, "a free upgrade to")
		buffer.text(x + 20, y + height - 1, background, "Windows 10")

		buffer.draw()
	end

	local function disableUpdates()
		_G.OSSettings.showWindows10Upgrade = false
		ecs.saveOSSettings()
	end

	draw(0x33B6FF)

	while true do
		local eventData = {event.pull("touch")}
		if eventData[3] == x + width - 3 and eventData[4] == y + 1 then
			buffer.text(eventData[3], eventData[4], ecs.colors.blue, "X")
			buffer.draw()
			os.sleep(0.2)
			drawAll()
			disableUpdates()

			return
		elseif ecs.clickedAtArea(eventData[3], eventData[4], x, y, x + width - 1, x + height - 1) then
			draw(0x0092FF)
			drawAll()

			local data = ecs.universalWindow("auto", "auto", 30, ecs.windowColors.background, true, {"EmptyLine"}, {"CenterText", 0x000000, "  Yes , I 'm kidding.  "}, {"CenterText", 0x000000, "  But you got the same update, right?  "}, {"EmptyLine"}, {"Button", {0xbbbbbb, 0xFFFFFF, "Yes"}, {0x999999, 0xFFFFFF, "No"}})
			if data[1] == "Yes" then
				disableUpdates()
			else
				ecs.error("kk")
			end

			return
		end
	end
end

---------------------------------------------- Сама ОС ------------------------------------------------------------------------

--Создаем буфер
buffer.start()
drawAll(true)
login()
windows10()
ecs.enableInterrupting()

---------------------------------------------- Анализ событий ------------------------------------------------------------------------

while true do
	local eventData = { event.pull() }

	if eventData[1] == "touch" then

		local clickedAtEmptyArea = true

		for key in pairs(obj["DesktopIcons"]) do
			if ecs.clickedAtArea(eventData[3], eventData[4], obj["DesktopIcons"][key][1], obj["DesktopIcons"][key][2], obj["DesktopIcons"][key][3], obj["DesktopIcons"][key][4]) then

				local path = obj["DesktopIcons"][key][5]
				local fileFormat = ecs.getFileFormat(path)

				local oldPixelsOfIcon = buffer.copy(obj["DesktopIcons"][key][1], obj["DesktopIcons"][key][2], sizes.widthOfIcon, sizes.heightOfIcon)

				buffer.square(obj["DesktopIcons"][key][1], obj["DesktopIcons"][key][2], sizes.widthOfIcon, sizes.heightOfIcon, colors.iconsSelectionColor, 0xFFFFFF, " ", colors.iconsSelectionTransparency)
				ecs.drawOSIcon(obj["DesktopIcons"][key][1], obj["DesktopIcons"][key][2], path, false, 0xffffff)
				buffer.draw()

				-- Левый клик
				if eventData[5] == 0 then
					os.sleep(0.2)
					if fs.isDirectory(path)	then
						if fileFormat == ".app" then
							ecs.launchIcon(path)
							buffer.start()
							drawAll()
						else
							shell.execute("MineOS/Applications/Finder.app/Finder.lua " .. path)
							drawAll()
						end
					else
						ecs.launchIcon(path)
						buffer.start()
						drawAll()
					end

				-- Правый клик
				elseif eventData[5] == 1 then

					local action
					local fileFormat = ecs.getFileFormat(path)

					-- Разные контекстные меню
					if fs.isDirectory(path) then
						if fileFormat == ".app" then
							action = context.menu(eventData[3], eventData[4],
								{lang.contextMenuShowPackageContent},
								"-",
								{lang.contextMenuCopy, false},
								{lang.contextMenuPaste, not _G.clipboard},
								"-",
								{lang.contextMenuRename},
								{lang.contextMenuCreateShortcut},
								"-",
								{lang.contextMenuUploadToPastebin, true},
								"-",
								{lang.contextMenuAddToDock, not (currentCountOfIconsInDock < sizes.dockCountOfIcons)},
								{lang.contextMenuDelete, false}
							)
						else
							action = context.menu(eventData[3], eventData[4],
								{lang.contextMenuCopy, false},
								{lang.contextMenuRename},
								{lang.contextMenuCreateShortcut},
								"-",
								{lang.contextMenuArchive},
								"-",
								{lang.contextMenuDelete, false}
							)
						end
					else
						if fileFormat == ".pic" then
							action = context.menu(eventData[3], eventData[4],
								{lang.contextMenuEdit},
								{lang.contextMenuEditInPhotoshop},
								{lang.contextMenuSetAsWallpaper},
								"-",
								{lang.contextMenuCopy, false},
								{lang.contextMenuRename},
								{lang.contextMenuCreateShortcut},
								"-",
								{lang.contextMenuUploadToPastebin, true},
								"-",
								{lang.contextMenuAddToDock, not (currentCountOfIconsInDock < sizes.dockCountOfIcons)},
								{lang.contextMenuDelete, false}
							)
						else
							action = context.menu(eventData[3], eventData[4],
								{lang.contextMenuEdit},
								{lang.contextMenuCreateApplication},
								"-",
								{lang.contextMenuCopy, false},
								{lang.contextMenuRename},
								{lang.contextMenuCreateShortcut},
								"-",
								{lang.contextMenuUploadToPastebin, true},
								"-",
								{lang.contextMenuAddToDock, not (currentCountOfIconsInDock < sizes.dockCountOfIcons and workPath ~= "MineOS/System/OS/Dock/")},
								{lang.contextMenuDelete, false}
							)
						end
					end

					--Анализ действия контекстного меню
					if action == lang.contextMenuShowPackageContent then
						shell.execute("MineOS/Applications/Finder.app/Finder.lua "..path)
					elseif action == lang.contextMenuEdit then
						ecs.editFile(path)
						drawAll(true)
					elseif action == lang.contextMenuDelete then
						fs.remove(path)
						drawAll()
					elseif action == lang.contextMenuCopy then
						_G.clipboard = path
					elseif action == lang.contextMenuPaste then
						ecs.copy(_G.clipboard, workPath)
						drawAll()
					elseif action == lang.contextMenuRename then
						ecs.rename(path)
						drawAll()
					elseif action == lang.contextMenuCreateShortcut then
						ecs.createShortCut(workPath .. ecs.hideFileFormat(path) .. ".lnk", path)
						drawAll()
					elseif action == lang.contextMenuAddToDock then
						ecs.createShortCut("MineOS/System/OS/Dock/" .. ecs.hideFileFormat(path) .. ".lnk", path)
						drawAll()
					elseif action == lang.contextMenuSetAsWallpaper then
						ecs.createShortCut(pathToWallpaper, path)
						changeWallpaper()
						drawAll(true)
					elseif action == lang.contextMenuEditInPhotoshop then
						shell.execute("MineOS/Applications/Photoshop.app/Photoshop.lua open " .. path)
						drawAll(true)
					else
						buffer.paste(obj["DesktopIcons"][key][1], obj["DesktopIcons"][key][2], oldPixelsOfIcon)
						buffer.draw()
					end
				end

				clickedAtEmptyArea = false

				break
			end
		end

		for key in pairs(obj["DockIcons"]) do
			if ecs.clickedAtArea(eventData[3], eventData[4], obj["DockIcons"][key][1], obj["DockIcons"][key][2], obj["DockIcons"][key][3], obj["DockIcons"][key][4]) then

				local oldPixelsOfIcon = buffer.copy(obj["DockIcons"][key][1], obj["DockIcons"][key][2], sizes.widthOfIcon, sizes.heightOfIcon)

				buffer.square(obj["DockIcons"][key][1], obj["DockIcons"][key][2], sizes.widthOfIcon, sizes.heightOfIcon, colors.iconsSelectionColor, 0xFFFFFF, " ", colors.iconsSelectionTransparency)
				ecs.drawOSIcon(obj["DockIcons"][key][1], obj["DockIcons"][key][2], pathOfDockShortcuts .. key, false, 0xffffff)
				buffer.draw()

				if eventData[5] == 0 then
					os.sleep(0.2)
					ecs.launchIcon(pathOfDockShortcuts .. key)
					drawAll(true)
				else
					local content = ecs.readShortcut(pathOfDockShortcuts .. key)

					action = context.menu(eventData[3], eventData[4],{lang.contextMenuRemoveFromDock, not (currentCountOfIconsInDock > 1)})

					if action == lang.contextMenuRemoveFromDock then
						fs.remove(pathOfDockShortcuts .. key)
						drawAll()
					else
						buffer.paste(obj["DockIcons"][key][1], obj["DockIcons"][key][2], oldPixelsOfIcon)
						buffer.draw()
						oldPixelsOfIcon = nil
					end
				end

				clickedAtEmptyArea = false

				break
			end
		end

		for key in pairs(obj["TopBarButtons"]) do
			if ecs.clickedAtArea(eventData[3], eventData[4], obj["TopBarButtons"][key][1], obj["TopBarButtons"][key][2], obj["TopBarButtons"][key][3], obj["TopBarButtons"][key][4]) then

				buffer.square(obj["TopBarButtons"][key][1], obj["TopBarButtons"][key][2], unicode.len(key) + 2, 1, ecs.colors.blue, 0xFFFFFF, " ")
				buffer.text(obj["TopBarButtons"][key][1] + 1, obj["TopBarButtons"][key][2], 0xffffff, key)
				buffer.draw()

				if key == "MineOS" then
					local action = context.menu(obj["TopBarButtons"][key][1], obj["TopBarButtons"][key][2] + 1, {lang.aboutSystem}, {lang.updates}, "-", {lang.reboot}, {lang.shutdown}, "-", {lang.returnToShell})

					if action == lang.returnToShell then
						ecs.prepareToExit()
						return 0
					elseif action == lang.shutdown then
						ecs.TV(0)
						shell.execute("shutdown")
					elseif action == lang.reboot then
						ecs.TV(0)
						shell.execute("reboot")
					elseif action == lang.updates then
						ecs.prepareToExit()
						ecs.error("updates are disabled")
						return 0
					elseif action == lang.aboutSystem then
						ecs.prepareToExit()
						print(copyright)
						print("And now press any button and continue to work with the operating system.")
						ecs.waitForTouchOrClick()
						drawAll(true)
					end

				elseif key == lang.viewTab then
					local action = context.menu(obj["TopBarButtons"][key][1], obj["TopBarButtons"][key][2] + 1,
						{lang.showFileFormat, showFileFormat},
						{lang.hideFileFormat, not showFileFormat},
						"-",
						{lang.showHiddenFiles, showHiddenFiles},
						{lang.hideHiddenFiles, not showHiddenFiles},
						"-",
						{lang.sortByName},
						{lang.sortByDate},
						{lang.sortByType},
						"-",
						{lang.contextMenuRemoveWallpaper, not wallpaper}
					)

					if action == lang.showHiddenFiles then
						showHiddenFiles = true
						drawAll()
					elseif action == lang.hideHiddenFiles then
						showHiddenFiles = false
						drawAll()
					elseif action == lang.showFileFormat then
						showFileFormat = true
						drawAll()
					elseif action == lang.hideFileFormat then
						showFileFormat = false
						drawAll()
					elseif action == lang.sortByName then
						sortingMethod = "name"
						drawAll()
					elseif action == lang.sortByDate then
						sortingMethod = "date"
						drawAll()
					elseif action == lang.sortByType then
						sortingMethod = "type"
						drawAll()
					elseif action == lang.contextMenuRemoveWallpaper then
						wallpaper = nil
						fs.remove(pathToWallpaper)
						drawAll(true)
					end
				end

				drawAll()

				clickedAtEmptyArea = false

				break
			end
		end

		if clickedAtEmptyArea and eventData[5] == 1 then
			local action = context.menu(eventData[3], eventData[4],
				{lang.contextMenuRemoveWallpaper, not wallpaper},
				"-",
				{lang.contextMenuNewFile},
				{lang.contextMenuNewFolder},
				"-",
				{lang.contextMenuPaste, not _G.clipboard}
			)

			--Создать новый файл
			if action == lang.contextMenuNewFile then
				ecs.newFile(workPath)
				drawAll(true)
			--Создать новую папку
			elseif action == lang.contextMenuNewFolder then
				ecs.newFolder(workPath)
				drawAll()
			--Вставить файл
			elseif action == lang.contextMenuPaste then
				ecs.copy(_G.clipboard, workPath)
				drawAll()
			elseif action == lang.contextMenuRemoveWallpaper then
				wallpaper = nil
				fs.remove(pathToWallpaper)
				drawAll()
			end
		end
	elseif eventData[1] == "OSWallpaperChanged" then
		changeWallpaper()
		drawAll(true)
	end
end