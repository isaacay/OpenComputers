
------------------------------------------ Библиотеки -----------------------------------------------------------------

local event = require("event")
local component = require("component")
local unicode = require("unicode")
local fs = require("filesystem")
local sides = require("sides")
local serialization = require("serialization")
local chestSide = sides.up
local gpu = component.gpu
local inventoryController

if not component.isAvailable("inventory_controller") then
	ecs.error("This program requires a connection adapter inserted therein improvement \"inventory controller\", while on the adapter itself must be put on top of the chest in which to do things for sale.")
	return
else
	inventoryController = component.inventory_controller
end

------------------------------------------ Переменные -----------------------------------------------------------------

local colors = {
	["background"] = 0x262626,
	["topbar"] = 0xffffff,
	["topbarText"] = 0x444444,
	["topbarActive"] = ecs.colors.blue,
	["topbarActiveText"] = 0xffffff,
	["inventoryBorder"] =  0xffffff,
	["inventoryBorderSelect"] = ecs.colors.blue,
	["inventoryBorderSelectText"] = 0xffffff,
	["inventoryText"] = 0x262626,
	["inventoryTextDarker"] = 0x666666,
	["sellButtonColor"] = ecs.colors.blue,
	["sellButtonTextColor"] = 0xffffff,
	rarity = {
		["Common"] = 0xB0C3D9,
		["Uncommon"] = 0x5E98D9,
		["Rare"] = 0x4B69FF,
		["Mythical"] = 0x8847FF,
		["Legendary"] = 0xD32CE6,
		["Immortal"] = 0xE4AE33,
		["Arcana"] = 0xADE55C,
		["Ancient"] = 0xEB4B4B
	}
}

--Массив админшопа с базовой информацией о блоках
local adminShop = {
	["minecraft:stone"] = {
		[0] = {
			["price"] = 4,
			["rarity"] = "Uncommon",
		},
	},
	["minecraft:diamond"] = {
		[0] = {
			["price"] = 200,
			["rarity"] = "Legendary",
		},
	},
	["minecraft:grass"] = {
		[0] = {
			["price"] = 4,
			["rarity"] = "Uncommon",
		},
	},
	["minecraft:cobblestone"] = {
		[0] = {
			["price"] = 2,
			["rarity"] = "Common",
		},
	},
	["minecraft:dirt"] = {
		[0] = {
			["price"] = 2,
			["rarity"] = "Common",
		},
	},
	["minecraft:iron_ore"] = {
		[0] = {
			["price"] = 20,
			["rarity"] = "Rare",
		},
	},
	["minecraft:gold_ore"] = {
		[0] = {
			["price"] = 40,
			["rarity"] = "Mythical",
		},
	},
	["minecraft:coal_ore"] = {
		[0] = {
			["price"] = 5,
			["rarity"] = "Uncommon",
		},
	},
	["minecraft:wool"] = {
		[0] = {
			["price"] = 10,
			["rarity"] = "Uncommon",
		},
		[15] = {
			["price"] = 15,
			["rarity"] = "Uncommon",
		},
		[14] = {
			["price"] = 15,
			["rarity"] = "Uncommon",
		},
	},
	["minecraft:redstone"] = {
		[0] = {
			["price"] = 10,
			["rarity"] = "Rare",
		},
	},
	["minecraft:log"] = {
		[0] = {
			["price"] = 3,
			["rarity"] = "Common",
		},
	},
	["IC2:itemOreIridium"] = {
		[0] = {
			["price"] = 50000,
			["rarity"] = "Arcana",
		},
	},
}

--Массив инвентаря конкретного игрока
local massivWithProfile = {
	-- ["nickname"] = "IT",
	-- ["money"] = 100,
	-- ["inventory"] = {
	-- 	{
	-- 		["id"] = "minecraft:stone",
	-- 		["label"] = "Stone",
	-- 		["data"] = 0,
	-- 		["count"] = 64,
	-- 	},
	-- 	{
	-- 		["id"] = "minecraft:grass",
	-- 		["data"] = 0,
	-- 		["label"] = "Grass",
	-- 		["count"] = 32,
	-- 	},
	-- 	{
	-- 		["id"] = "minecraft:wool",
	-- 		["data"] = 0,
	-- 		["label"] = "Red wool",
	-- 		["count"] = 12,
	-- 	},
	-- 	{
	-- 		["id"] = "minecraft:diamond",
	-- 		["data"] = 0,
	-- 		["label"] = "Diamond",
	-- 		["count"] = 999,
	-- 	},
	-- 	{
	-- 		["id"] = "minecraft:cobblestone",
	-- 		["data"] = 0,
	-- 		["label"] = "Cobblestone",
	-- 		["count"] = 47000,
	-- 	},
	-- 	{
	-- 		["id"] = "minecraft:redstone",
	-- 		["data"] = 0,
	-- 		["label"] = "Redstone",
	-- 		["count"] = 12000,
	-- 	},
	-- 	{
	-- 		["id"] = "minecraft:iron_ore",
	-- 		["data"] = 0,
	-- 		["label"] = "Iron ore",
	-- 		["count"] = 572,
	-- 	},
	-- 	{
	-- 		["id"] = "minecraft:gold_ore",
	-- 		["data"] = 0,
	-- 		["label"] = "Gold ore",
	-- 		["count"] = 246,
	-- 	},
	-- 	{
	-- 		["id"] = "minecraft:coal_ore",
	-- 		["data"] = 0,
	-- 		["label"] = "Coal ore",
	-- 		["count"] = 11,
	-- 	},
	-- 	{
	-- 		["id"] = "IC2:itemOreIridium",
	-- 		["data"] = 0,
	-- 		["label"] = "Iridium Ore",
	-- 		["count"] = 5,
	-- 	},
	-- 	{
	-- 		["id"] = "minecraft:log",
	-- 		["data"] = 0,
	-- 		["label"] = "Log",
	-- 		["count"] = 124782,
	-- 	},
	-- },
}

--Массив торговой площадки
local market = {
	["minecraft:diamond"] = {
		[0] = {
			["label"] = "Diamond",
			{
				["nickname"] = "Daun228",
				["count"] = 228,
				["price"] = 150,
			},
		},
	},
	["minecraft:log"] = {
		[0] = {
			["label"] = "Log",
			{
				["nickname"] = "CykaRotEbal",
				["count"] = 121304,
				["price"] = 21.8,
			},
		},
	},
	["minecraft:iron_ore"] = {
		[0] = {
			["label"] = "Iron Ore",
			{
				["nickname"] = "Blyad",
				["count"] = 2424194,
				["price"] = 20,
			},
		},
	},
	["minecraft:gold_ore"] = {
		[0] = {
			["label"] = "Gold Ore",
			{
				["nickname"] = "EEOneGuy",
				["count"] = 5,
				["price"] = 5,
			},
			{
				["nickname"] = "Pidar",
				["count"] = 10,
				["price"] = 10,
			},
			{
				["nickname"] = "Mamoeb",
				["count"] = 15,
				["price"] = 15,
			},
		},
	},
}


local moneySymbol = "$"
local adminSellMultiplyer = 0.5
local comissionMultiplyer = 0.04

local username = "ECS"
local currentMode = 2

local xSize, ySize = gpu.getResolution()

local widthOfOneItemElement = 12
local heightOfOneItemElement = widthOfOneItemElement / 2

------------------------------------------ Функции сохранения -----------------------------------------------------------------

local shopPath = "System/Shop/"
local databasePath = shopPath .. "Users/"
local marketPath = shopPath .. "Market.txt"
local adminShopPath = shopPath .. "AdminShop.txt"
local adminMoneyPath = shopPath .. "AdminMoney.txt"
local logPath = shopPath .. "Shop.log"

local function init()
	fs.makeDirectory(databasePath)
end

local function saveUser(massiv)
	local file = io.open(databasePath .. massiv.nickname .. ".txt", "w")
	file:write(serialization.serialize(massiv))
	file:close()
end

local function createNewUser(nickname)
	local massiv = {
		["nickname"] = nickname,
		["money"] = 0,
		["inventory"] = {
			{
				["id"] = "minecraft:cobblestone",
				["label"] = "Stone",
				["data"] = 0,
				["count"] = 1,
			},
		},
	}
	saveUser(massiv)
	return massiv
end

local function loadUser(nickname)
	if not fs.exists(databasePath .. nickname .. ".txt") then
		return createNewUser(nickname)
	else
		local file = io.open(databasePath .. nickname .. ".txt", "r")
		local text = file:read("*a")
		file:close()
		return serialization.unserialize(text)
	end
end

local function saveMarket()
	local file = io.open(marketPath, "w")
	file:write(serialization.serialize(market))
	file:close()
end

local function loadMarket()
	if not fs.exists(marketPath) then
		saveMarket()
	else
		local file = io.open(marketPath, "r")
		local text = file:read("*a")
		file:close()
		market = serialization.unserialize(text)
	end
end

local function loadAdminShop()
	if not fs.exists(adminShopPath) then
		local file = io.open(adminShopPath, "w")
		file:write(serialization.serialize(adminShop))
		file:close()
	else
		local file = io.open(adminShopPath, "r")
		local text = file:read("*a")
		file:close()
		adminShop = serialization.unserialize(text)
	end
end

local function saveAdminMoney(money)
	local file = io.open(adminMoneyPath, "w")
	file:write(tostring(money))
	file:close()
end

local function loadAdminMoney()
	if not fs.exists(adminMoneyPath) then
		saveAdminMoney(0)
		return 0
	else
		local file = io.open(adminMoneyPath, "r")
		local text = file:read("*a")
		file:close()
		return tonumber(text)
	end
end

local function addMoneyToAdmins(money)
	local currentAdminsMoney = loadAdminMoney()
	currentAdminsMoney = currentAdminsMoney + money
	saveAdminMoney(currentAdminsMoney)
end

local function log(text)
	local file = io.open(logPath, "a")
	file:write(text, "\n")
	file:close()
end

------------------------------------------ Функции -----------------------------------------------------------------

--Обжекты
local obj = {}
local function newObj(class, name, ...)
	obj[class] = obj[class] or {}
	obj[class][name] = {...}
end

--Округление до опред. кол-ва знаков после запятой
local function round(num, idp)
	local mult = 10^(idp or 0)
	return math.floor(num * mult + 0.5) / mult
end

--Сконвертировать кол-во предметов в более компактный вариант
local function prettyItemCount(count)
	if count >= 1000000 then
		return tostring(round(count / 1000000, 2)) .. "M"
	elseif count >= 1000 then
		return tostring(round(count / 1000, 2)) .. "K"
	end
	return tostring(count)
end

--Фиксим число до 2-х знаков после запятой
local function fixMoney(money)
	return round(money, 2)
end

--Взымаем комиссию с купли/продажи
local function comission(money)
	return fixMoney(money - money * comissionMultiplyer)
end

--Добавление предмета в инвентарь
local function addItemToInventory(id, data, label, count)
	--Переменная успеха, означающая, что такой предмет уже есть,
	--и что его количество успешно увеличилось
	local success = false
	--Перебираем весь массив инвентаря и смотрим, есть ли чет такое
	for i = 1, #massivWithProfile.inventory do
		if id == massivWithProfile.inventory[i].id then
			if data == massivWithProfile.inventory[i].data then
				massivWithProfile.inventory[i].count = massivWithProfile.inventory[i].count + count
				success = true
				break
			end
		end
	end

	--Если такого предмета нет, то создать новый слот в инвентаре
	if not success then
		table.insert(massivWithProfile.inventory, { ["id"] = id, ["data"] = data, ["label"] = label, ["count"] = count } )
	end
end

--Удалить кол-во предмета из инвентаря
local function removeItemFromInventory(numberOfItemInInventory, count)
	--Небольшая подстраховка, чтобы не удалить больше, чем возможно
	local skokaMozhnaUdalit = massivWithProfile.inventory[numberOfItemInInventory].count
	if count > skokaMozhnaUdalit then count = skokaMozhnaUdalit end
	--Уменьшаем количество этого предмета
	massivWithProfile.inventory[numberOfItemInInventory].count = massivWithProfile.inventory[numberOfItemInInventory].count - count
	--Если количество равно нулю, то удаляем запись о предмете из инвентаря
	if massivWithProfile.inventory[numberOfItemInInventory].count == 0 then
		table.remove(massivWithProfile.inventory, numberOfItemInInventory)
	end
end

--Просканировать сундук и добавить в него шмот
local function addToInventoryFromChest()
	local counter = 0
	local inventorySize = inventoryController.getInventorySize(chestSide)
	for i = 1, inventorySize do
		local stack = inventoryController.getStackInSlot(chestSide, i)
		if stack then
			addItemToInventory(stack.name, stack.damage, stack.label, stack.size)
			counter = counter + stack.size
		end
	end

	return counter
end

--Продать шмотку одменам
local function sellToAdmins(numberOfItemInInventory, skoka)
	local item = massivWithProfile.inventory[numberOfItemInInventory]
	if adminShop[item.id] then
		if adminShop[item.id][item.data] then
			local price = fixMoney(adminShop[item.id][item.data].price * adminSellMultiplyer)
			removeItemFromInventory(numberOfItemInInventory, skoka)
			massivWithProfile.money = massivWithProfile.money + price * skoka
			return (price * skoka)
		else
			ecs.error("The admins no date "..tostring(item.data)..", unable to translate")
			return 0
		end
	else
		ecs.error("There are no admins id"..tostring(item.id)..", unable to translate")
		return 0
	end
end

--Продать шмотку игрокам на ТП
local function sellToPlayers(number, count, priceForOneItem, nameOfSeller)
	--Получаем инфо о шмотке
	local item = massivWithProfile.inventory[number]
	--Удаляем шмотку
	removeItemFromInventory(number, count)
	--Че будем добавлять на ТП
	local govno = { ["nickname"] = nameOfSeller, ["count"] = count, ["price"] = priceForOneItem}
	--Добавляем ее на ТП
	--Если есть такой ид
	if market[item.id] then
		--И если есть такая дата
		if market[item.id][item.data] then
			table.insert(market[item.id][item.data], govno)
		else
			market[item.id][item.data] = { ["label"] = item.label, govno }
		end
	else
		market[item.id] = { [item.data] = { ["label"] = item.label, govno } }
	end
end

--Анализ торговой площадки
--Выдает успех, если предмет найден
--А также самую лучшую цену, количество предмета на торг. площадке и никнейм самого дешевого
local function getInfoAboutItemOnMarket(id, data)
	local price, count, success, nickname, label = nil, 0, false, nil, "JUICE"
	--Если в маркете есть такой ид
	if market[id] then
		--И такая дата
		if market[id][data] then
			--Перебираем все айтемы на маркете
			for i = 1, #market[id][data] do
				--Если данных таких нет, то создать стартовые
				price = price or market[id][data][i].price
				nickname = nickname or market[id][data][i].nickname

				--Если цена меньше, чем другие, то новая цена = этой
				if market[id][data][i].price < price then
					price = market[id][data][i].price
					nickname = market[id][data][i].nickname
				end

				--Прибавляем кол-во предметов
				count = count + market[id][data][i].count
			end
			label = market[id][data].label
			success = true
		end
	end
	return success, price, count, nickname, label
end



--Нарисовать конкретный айтем
local function drawItem(xPos, yPos, back, fore, text1, text2)
	--Рисуем квадратик
	ecs.square(xPos, yPos, widthOfOneItemElement, heightOfOneItemElement, back)
	--Рисуем текст в рамке
	text1 = ecs.stringLimit("end", text1, widthOfOneItemElement - 2)
	text2 = ecs.stringLimit("end", prettyItemCount(text2), widthOfOneItemElement - 2)
	local x
	x = xPos + math.floor(widthOfOneItemElement / 2 - unicode.len(text1) / 2)
	ecs.colorText(x, yPos + 2, fore, text1)
	x = xPos + math.floor(widthOfOneItemElement / 2 - unicode.len(text2) / 2)
	ecs.colorText(x, yPos + 3, fore, text2)
	x = nil
end

--Показ инвентаря
local function showInventory(x, y, page, currentItem)
	obj["SellItems"] = nil
	obj["SellButtons"] = nil

	local widthOfItemInfoPanel = 26
	local width = math.floor((xSize - widthOfItemInfoPanel - 4) / (widthOfOneItemElement))
	local height = math.floor((ySize - 8) / (heightOfOneItemElement))
	local countOfItems = #massivWithProfile.inventory
	local countOfItemsOnOnePage = width * height
	local countOfPages = math.ceil(countOfItems / countOfItemsOnOnePage)
	local widthOfAllElements = width * widthOfOneItemElement
	local heightOfAllElements = height * heightOfOneItemElement

	--Очищаем фоном
	ecs.square(x, y, widthOfAllElements, heightOfAllElements, colors.background)

	--Рисуем айтемы
	local textColor, borderColor, itemCounter, xPos, yPos = nil, nil, 1 + page * width * height - width * height, x, y
	for j = 1, height do
		xPos = x
		for i = 1, width do
			--Если такой предмет вообще существует
			if massivWithProfile.inventory[itemCounter] then
				--Делаем цвет рамки
				if itemCounter == currentItem then
					borderColor = colors.inventoryBorderSelect
					textColor = colors.inventoryBorderSelectText
				else
					local cyka = false
					if j % 2 == 0 then
						if i % 2 ~= 0 then
							cyka = true
						end
					else
						if i % 2 == 0 then
							cyka = true
						end
					end

					if cyka then
						borderColor = colors.inventoryBorder
					else
						borderColor = colors.inventoryBorder - 0x111111
					end
					textColor = colors.inventoryText
				end

				--Рисуем итем
				drawItem(xPos, yPos, borderColor, textColor, massivWithProfile.inventory[itemCounter].label, massivWithProfile.inventory[itemCounter].count)
			
				newObj("SellItems", itemCounter, xPos, yPos, xPos + widthOfOneItemElement - 1, yPos + heightOfOneItemElement - 1)
			else
				break
			end

			itemCounter = itemCounter + 1

			xPos = xPos + widthOfOneItemElement
		end
		yPos = yPos + heightOfOneItemElement
	end

	--Рисуем инфу о кнкретном айтеме
	xPos = x + widthOfAllElements + 2
	yPos = y
	widthOfItemInfoPanel = xSize - xPos - 1
	
	--Рамку рисуем
	ecs.square(xPos, yPos, widthOfItemInfoPanel, ySize - 5, colors.inventoryBorder)
	yPos = yPos + 1
	xPos = xPos + 2
	
	--Инфа о блоке
	local currentRarity = "Common"
	if adminShop[massivWithProfile.inventory[currentItem].id] then
		if adminShop[massivWithProfile.inventory[currentItem].id][massivWithProfile.inventory[currentItem].data] then
			currentRarity = adminShop[massivWithProfile.inventory[currentItem].id][massivWithProfile.inventory[currentItem].data].rarity
		end
	end
	ecs.colorText(xPos, yPos, colors.inventoryText, massivWithProfile.inventory[currentItem].label); yPos = yPos + 1
	ecs.colorText(xPos, yPos, colors.rarity[currentRarity], currentRarity); yPos = yPos + 2
	ecs.colorText(xPos, yPos, colors.inventoryTextDarker, "ID: " .. massivWithProfile.inventory[currentItem].id); yPos = yPos + 1
	ecs.colorText(xPos, yPos, colors.inventoryTextDarker, "Colour: " .. massivWithProfile.inventory[currentItem].data); yPos = yPos + 1
	ecs.colorText(xPos, yPos, colors.inventoryTextDarker, "amount: " .. massivWithProfile.inventory[currentItem].count); yPos = yPos + 1

	--Твой бабос
	yPos = yPos + 1
	ecs.colorText(xPos, yPos, colors.inventoryText, "your capital:"); yPos = yPos + 1
	ecs.colorText(xPos, yPos, colors.inventoryTextDarker, massivWithProfile.money .. moneySymbol); yPos = yPos + 1
	
	--Цена админов
	yPos = yPos + 1
	local adminPrice = "Absent"
	if adminShop[massivWithProfile.inventory[currentItem].id] then
		if adminShop[massivWithProfile.inventory[currentItem].id][massivWithProfile.inventory[currentItem].data] then
			adminPrice = fixMoney(adminShop[massivWithProfile.inventory[currentItem].id][massivWithProfile.inventory[currentItem].data].price * adminSellMultiplyer)
		end
	end
	ecs.colorText(xPos, yPos, colors.inventoryText, "Price from admins:"); yPos = yPos + 1
	ecs.colorText(xPos, yPos, colors.inventoryTextDarker, tostring(adminPrice)..moneySymbol)

	--Цена на ТП
	yPos = yPos + 2
	local success, price, count = getInfoAboutItemOnMarket(massivWithProfile.inventory[currentItem].id, massivWithProfile.inventory[currentItem].data)
	ecs.colorText(xPos, yPos, colors.inventoryText, "Price on the Marketplace:"); yPos = yPos + 1
	if success then
		ecs.colorText(xPos, yPos, colors.inventoryTextDarker, "For sale " .. prettyItemCount(count) .. " штук"); yPos = yPos + 1
		ecs.colorText(xPos, yPos, colors.inventoryTextDarker, "Price starts at " .. prettyItemCount(price) .. moneySymbol); yPos = yPos + 1
	else
		ecs.colorText(xPos, yPos, colors.inventoryTextDarker, "Absent"); yPos = yPos + 1
	end

	--Кнопы
	xPos = xPos - 2
	yPos = ySize - 3
	local x1, y1, x2, y2, name
	name = "Sell players"; x1, y1, x2, y2 = ecs.drawButton(xPos, yPos, widthOfItemInfoPanel, 3, name, colors.sellButtonColor, colors.sellButtonTextColor); newObj("SellButtons", name, x1, y1, x2, y2, widthOfItemInfoPanel); yPos = yPos - 3
	if adminPrice ~= "Absent" then
		name = "Sell admins"; x1, y1, x2, y2 = ecs.drawButton(xPos, yPos, widthOfItemInfoPanel, 3, name, 0x66b6ff, colors.sellButtonTextColor); newObj("SellButtons", name, x1, y1, x2, y2, widthOfItemInfoPanel); yPos = yPos - 3
	end
	name = "Add inventory"; x1, y1, x2, y2 = ecs.drawButton(xPos, yPos, widthOfItemInfoPanel, 3, name, 0x99dbff, colors.sellButtonTextColor); newObj("SellButtons", name, x1, y1, x2, y2, widthOfItemInfoPanel); yPos = yPos - 3

	--Перелистывалки
	local stro4ka = tostring(page) .. " из " .. tostring(countOfPages)
	local sStro4ka = unicode.len(stro4ka) + 2
	xPos = xPos - sStro4ka - 16
	yPos = ySize - 3
	name = "<"; x1, y1, x2, y2 = ecs.drawButton(xPos, yPos, 7, 3, name, colors.sellButtonColor, colors.sellButtonTextColor); newObj("SellButtons", name, x1, y1, x2, y2, 7); xPos = xPos + 7
	ecs.square(xPos, yPos, sStro4ka, 3, colors.inventoryBorder)
	ecs.colorText(xPos + 1, yPos + 1, 0x000000, stro4ka); xPos = xPos + sStro4ka
	name = ">"; x1, y1, x2, y2 = ecs.drawButton(xPos, yPos, 7, 3, name, colors.sellButtonColor, colors.sellButtonTextColor); newObj("SellButtons", name, x1, y1, x2, y2, 7)

	return countOfPages
end

local function sell()

	--Если в инвентаре ни хуя нет, то сасируй
	if #massivWithProfile.inventory == 0 then
		ecs.centerText("xy", 0, "Your inventory is empty.")
		return
	end

	--Показываем инвентарь
	local xInventory, yInventory, currentPage, currentItem = 3, 5, 1, 1
	local countOfPages
	countOfPages = showInventory(xInventory, yInventory, currentPage, currentItem)

	while true do
		local e = {event.pull()}
		if e[1] == "touch" then

			for key in pairs(obj["SellItems"])do
				if ecs.clickedAtArea(e[3], e[4], obj["SellItems"][key][1], obj["SellItems"][key][2], obj["SellItems"][key][3], obj["SellItems"][key][4]) then
					currentItem = key
					showInventory(xInventory, yInventory, currentPage, currentItem)
					break
				end
			end

			for key in pairs(obj["SellButtons"])do
				if ecs.clickedAtArea(e[3], e[4], obj["SellButtons"][key][1], obj["SellButtons"][key][2], obj["SellButtons"][key][3], obj["SellButtons"][key][4]) then
					ecs.drawButton(obj["SellButtons"][key][1], obj["SellButtons"][key][2], obj["SellButtons"][key][5], 3, key, ecs.colors.green, 0xffffff)
					os.sleep(0.3)

					if key == ">" then
						if currentPage < countOfPages then currentPage = currentPage + 1 end
					
					elseif key == "<" then
						if currentPage > 1 then currentPage = currentPage - 1 end
					
					elseif key == "Add inventory" then
						ecs.error("Пихай предметы в сундук и жми ок, епта! (bad translation: Piha items in the chest and PUSH app epta!)")
						local addedCount = addToInventoryFromChest()
						ecs.error("Added "..addedCount.." items.")
					
					elseif key == "Sell admins" then
						local maxToSell = massivWithProfile.inventory[currentItem].count
						local data = ecs.universalWindow("auto", "auto", 40, 0x444444, true, {"EmptyLine"}, {"CenterText", 0xffffff, "How to sell?"}, {"EmptyLine"}, {"Slider", 0xffffff, 0x33db80, 1, maxToSell, math.floor(maxToSell / 2), "", " PC."}, {"EmptyLine"}, {"Button", {0x33db80, 0xffffff, "Sell"}})
						local count = data[1]
						if count then
							local money = sellToAdmins(currentItem, count)
							ecs.universalWindow("auto", "auto", 40, 0x444444, true, {"EmptyLine"}, {"CenterText", 0xffffff, "Successfully submitted!"}, {"CenterText", 0xffffff, "You earned "..money..moneySymbol}, {"EmptyLine"}, {"Button", {0x33db80, 0xffffff, "Ok"}})
						else
							ecs.error("Error in the sale!")
						end
					
					elseif key == "Sell players" then
						local maxToSell = massivWithProfile.inventory[currentItem].count
						local data = ecs.universalWindow("auto", "auto", 36, 0x444444, true, {"EmptyLine"}, {"CenterText", 0xffffff, "Sell players"}, {"EmptyLine"}, {"Input", 0xffffff, 0x33db80, "Price for one"}, {"EmptyLine"}, {"CenterText", 0xffffff, "amount:"}, {"Slider", 0xffffff, 0x33db80, 1, maxToSell, math.floor(maxToSell / 2), "", " PC."}, {"EmptyLine"}, {"CenterText", 0xffffff, "With each sale with you"}, {"CenterText", 0xffffff, "It charges a fee of 4%"}, {"EmptyLine"}, {"Button", {0x33db80, 0xffffff, "Sell"}})
						local price, count = tonumber(data[1]), data[2]
						if price then
							sellToPlayers(currentItem, count, price, massivWithProfile.nickname)
							ecs.universalWindow("auto", "auto", 36, 0x444444, true, {"EmptyLine"}, {"CenterText", 0xffffff, "Your subject may be for sale!"}, {"EmptyLine"}, {"Button", {0x33db80, 0xffffff, "Ok"}})
						else
							ecs.error("Error! Invalid sale price!")
						end
					end

					countOfPages = showInventory(xInventory, yInventory, currentPage, currentItem) 

					break
				end
			end

			-- for key in pairs(obj["TopButtons"])do
			-- 	if ecs.clickedAtArea(e[3], e[4], obj["TopButtons"][key][1], obj["TopButtons"][key][2], obj["TopButtons"][key][3], obj["TopButtons"][key][4]) then
			-- 		currentMode = key
			-- 		return
			-- 	end
			-- end
		elseif e[1] == "key_down" then
			if e[4] >= 2 and e[4] <= 5 then
				--ecs.error("afae")
				currentMode = e[4] - 1
				return
			end
		end
	end
end

--Купить указанное количество указанного предмета у указанного продавца
local function buyFromSeller(id, data, sellerNumber, count)
	--Считаем, сколько бабок будет у нас в обиходе
	local moneyToWork = count * market[id][data][sellerNumber].price
	--Считаем, сколько админы наварят с этого обихода
	local moneyForAdmins = round(moneyToWork * comissionMultiplyer, 2)
	--Отнимаем бабки у нас с учетом навара админов
	massivWithProfile.money = massivWithProfile.money - (moneyToWork + moneyForAdmins)
	--Загружаем профиль продавца
	local massivWithSellerProfile = loadUser(market[id][data][sellerNumber].nickname)
	--Добавляем бабки продавцу
	massivWithSellerProfile.money = massivWithSellerProfile.money + comission(moneyToWork)
	--Добавляем бабки админам
	addMoneyToAdmins(moneyForAdmins)
	--Добавляем предметы нам
	addItemToInventory(id, data, market[id][data].label, count)
	--Удаляем указанное количество предметов с торговой площадки
	market[id][data][sellerNumber].count = market[id][data][sellerNumber].count - count
	--Сохраняем в лог данные о трансакции
	log("Player " .. massivWithProfile.nickname .. " I bought " .. count .. " piece goods \"" .. market[id][data].label .. " (" .. id .. " " .. data .. ")\" Player " .. market[id][data][sellerNumber].nickname .. " buy price " .. market[id][data][sellerNumber].price .. moneySymbol .. " a piece. The amount of the transaction " .. moneyToWork .. moneySymbol .. ", store administration received " .. moneyForAdmins .. moneySymbol)
	--Если количество предметов стало 0, то удалить запись продавца об этом предмете
	if market[id][data][sellerNumber].count <= 0 then table.remove(market[id][data], sellerNumber) end
	--Если не существует более продавцов данной Даты, то удалить запись о дате
	if #market[id][data] <= 0 then market[id] = nil end
	--Сохраняем базу данных торговой площадки
	saveMarket()
	--Сохраняем свой профиль
	saveUser(massivWithProfile)
	--Сохраняем профиль продавца
	saveUser(massivWithSellerProfile)
end

--Окно покупки
local function buy()
	--Если ТП в данный момент пуста, и ничего на ней не продается
	
	--ecs.error("#market = "..#market)

	-- if #market == 0 then
	-- 	gpu.setForeground(0xFFFFFF)
	-- 	ecs.centerText("x", math.floor(ySize / 2), "Торговая Площадка в данный момент пуста.")
	-- 	ecs.centerText("x", math.floor(ySize / 2) + 1, "Вы можете разместить свое объявление о продаже выше.")
	-- end

	local countOfItemsOfMarketToShop = math.floor((ySize - 12) / 4)
	local itemOfMarketToShow = 1
	local filteredMakretArray = {}
	local itemMarketArray = {}
	local currentFilter
	local marketSellersList = false

	local currentID, currentData, currentSeller

	local function filter(makretFilter)
		filteredMakretArray = {}

		local success, price, count, nickname, label
		for id in pairs(market) do
			for data in pairs(market[id]) do

				success, price, count, nickname, label = getInfoAboutItemOnMarket(id, data)

				if makretFilter then
					if string.find(string.lower(id), string.lower(makretFilter)) then
						table.insert(filteredMakretArray, {["id"] = id, ["data"] = data, ["count"] = count, ["price"] = price, ["label"] = label})
					end
				else
					table.insert(filteredMakretArray, {["id"] = id, ["data"] = data, ["count"] = count, ["price"] = price, ["label"] = label})
				end

			end
		end
	end

	local function getItemSellers(id, data)
		itemMarketArray = {}
		for i = 1, #market[id][data] do
			table.insert(itemMarketArray, {["nickname"] = market[id][data][i].nickname, ["count"] = market[id][data][i].count, ["price"] = market[id][data][i].price})
		end
	end

	local xName, xCountOrSeller, xPrice = 6, math.floor(xSize * 3/7), math.floor(xSize * 4/6)

	local function infoPanel(yPos)

		local width = 40
		local xPos = math.floor(xSize / 2 - width / 2)

		if not marketSellersList then
			ecs.border(xPos, yPos, width, 3, 0x262626, 0xFFFFFF)
			gpu.set(xPos + 2, yPos + 1, "Search subjects")

			yPos = yPos + 4
		end

		local background, foreground = ecs.colors.blue, 0xFFFFFF
		ecs.square(4, yPos, xSize - 7, 1, background)
		ecs.colorText(xName, yPos, foreground, (function () if marketSellersList then return "SELLER" else return "SUBJECT" end end)())
		ecs.colorText(xCountOrSeller, yPos, foreground, "QUANTITY")
		ecs.colorText(xPrice, yPos, foreground, "PRICE")

		yPos = yPos + 2

		return yPos
	end

	local function showItemsList()
		
		obj["BuyButtons"] = nil
		obj["BuyItems"] = nil

		local xPos, yPos = 4, 5

		ecs.square(1, yPos, xSize, ySize - yPos, 0x262626)

		if marketSellersList then

			gpu.setForeground(0xFFFFFF)
			ecs.centerText("x", yPos, "List object sellers \"" .. currentID .. " " .. currentData .. "\"")
			yPos = yPos + 2

			yPos = infoPanel(yPos)

			countOfItemsOfMarketToShop = math.floor((ySize - yPos - 1) / 4)

			ecs.srollBar(xSize - 1, yPos, 2, countOfItemsOfMarketToShop * 4, #itemMarketArray, itemOfMarketToShow, 0xFFFFFF, ecs.colors.blue)

			for i = itemOfMarketToShow, (itemOfMarketToShow + countOfItemsOfMarketToShop - 1) do
				if itemMarketArray[i] then
					ecs.square(xPos, yPos, xSize - 7, 3, 0xFFFFFF)
					ecs.colorText(xPos + 2, yPos + 1, 0x000000, itemMarketArray[i].nickname )
					gpu.set(xCountOrSeller, yPos + 1, tostring(itemMarketArray[i].count) .. " PC.")
					gpu.set(xPrice, yPos + 1, tostring(itemMarketArray[i].price) .. moneySymbol ..  " per Unit.")

					if itemMarketArray[i].price > massivWithProfile.money or itemMarketArray[i].nickname == massivWithProfile.nickname then
						ecs.drawAdaptiveButton(xSize - 13, yPos, 2, 1, "Buy", 0xBBBBBB, 0xFFFFFF)
					else
						newObj("BuyButtons", i, ecs.drawAdaptiveButton(xSize - 13, yPos, 2, 1, "Buy", 0x66b6ff, 0xFFFFFF))
					end

					yPos = yPos + 4
				end
			end

		else

			yPos = infoPanel(yPos)

			countOfItemsOfMarketToShop = math.floor((ySize - yPos - 1) / 4)

			ecs.srollBar(xSize - 1, yPos, 2, countOfItemsOfMarketToShop * 4, #filteredMakretArray, itemOfMarketToShow, 0xFFFFFF, ecs.colors.blue)

			for i = itemOfMarketToShow, (itemOfMarketToShow + countOfItemsOfMarketToShop - 1) do
				if filteredMakretArray[i] then
					ecs.square(xPos, yPos, xSize - 7, 3, 0xFFFFFF)
					ecs.colorText(xPos + 2, yPos + 1, 0x000000, filteredMakretArray[i].label)
					gpu.set(xCountOrSeller, yPos + 1, tostring(filteredMakretArray[i].count) .. " PC.")
					gpu.set(xPrice, yPos + 1, "From " .. tostring(filteredMakretArray[i].price) .. moneySymbol ..  " per Unit.")

					newObj("BuyItems", i, xPos, yPos, xPos + xSize - 7 , yPos + 2)

					yPos = yPos + 4
				end
			end
		end

	end

	filter(currentFilter)
	showItemsList()

	while true do
		local e = {event.pull()}
		
		if e[1] == "touch" then

			--Клик на конкретный айтем
			if obj["BuyItems"] then
				for key in pairs(obj["BuyItems"]) do
					if ecs.clickedAtArea(e[3], e[4], obj["BuyItems"][key][1], obj["BuyItems"][key][2], obj["BuyItems"][key][3], obj["BuyItems"][key][4]) then
						ecs.square(obj["BuyItems"][key][1], obj["BuyItems"][key][2], obj["BuyItems"][key][3] - obj["BuyItems"][key][1], 3, ecs.colors.blue)
						os.sleep(0.2)
						--Рисуем
						currentID = filteredMakretArray[key].id
						currentData = filteredMakretArray[key].data

						marketSellersList = true
						getItemSellers(filteredMakretArray[key].id, filteredMakretArray[key].data)
						itemOfMarketToShow = 1
						showItemsList()
						break
					end
				end
			end

			--Клики на кнопочки "Купить"
			if obj["BuyButtons"] then
				for key in pairs(obj["BuyButtons"]) do
					if ecs.clickedAtArea(e[3], e[4], obj["BuyButtons"][key][1], obj["BuyButtons"][key][2], obj["BuyButtons"][key][3], obj["BuyButtons"][key][4]) then
						ecs.drawAdaptiveButton(obj["BuyButtons"][key][1], obj["BuyButtons"][key][2], 2, 1, "Buy", 0xFF4940, 0xFFFFFF)
						
						local skokaMozhnaKupit = math.min(itemMarketArray[key].count, math.floor(massivWithProfile.money / (itemMarketArray[key].price + round(itemMarketArray[key].price * comissionMultiplyer))))

						local text = "Summary of purchase: You can buy a maximum of " .. skokaMozhnaKupit .. " pieces. The rules of the user agreement: pressing \"Buy\", you get the specified number of items on the optimally chosen price. The system will automatically find the most profitable items, and will transfer your money to the seller. Then, the specified number of objects will be immediately sent to you in digital equipment. Author of this program is not responsible for the loss of cash due to any external influences on the computer. You decide to trust a similar service or not."

						local data = ecs.universalWindow("auto", "auto", 40, 0xDDDDDD, true, {"EmptyLine"}, {"CenterText", 0x262626, "How much do you want to buy?"}, {"EmptyLine"}, {"Slider", 0x262626, 0x880000, 1, skokaMozhnaKupit, 1, "", " PC."}, {"EmptyLine"}, {"TextField", 6, 0xFFFFFF, 0x262626, 0xBBBBBB, ecs.colors.blue, text}, {"EmptyLine"}, {"Switch", 0x3366CC, 0xffffff, 0x262626, "With the terms of the above agreement", true}, {"EmptyLine"}, {"Button", {0x33db80, 0xffffff, "Buy"}})

						if not data[2] then
							ecs.universalWindow("auto", "auto", 40, 0xDDDDDD, true, {"EmptyLine"}, {"CenterText", 0x262626, "To purchase necessary to take"}, {"CenterText", 0x262626, "Terms of Service."}, {"EmptyLine"}, {"Button", {0x33db80, 0xffffff, "OK"}})
						else
							buyFromSeller(currentID, currentData, key, data[1])
						end

						--Рефрешим список айтемов ТП
						marketSellersList = false
						filter(currentFilter)
						itemOfMarketToShow = 1
						showItemsList()

						break
					end
				end
			end

		elseif e[1] == "scroll" then
			if not marketSellersList then
				if e[5] == 1 then
					if itemOfMarketToShow > 1 then itemOfMarketToShow = itemOfMarketToShow - 1; showItemsList() end
				else
					if itemOfMarketToShow < #filteredMakretArray then itemOfMarketToShow = itemOfMarketToShow + 1; showItemsList() end
				end
			else
				if e[5] == 1 then
					if itemOfMarketToShow > 1 then itemOfMarketToShow = itemOfMarketToShow - 1; showItemsList() end
				else
					if itemOfMarketToShow < #itemMarketArray then itemOfMarketToShow = itemOfMarketToShow + 1; showItemsList() end
				end
			end
		elseif e[1] == "key_down" then
			if e[4] >= 2 and e[4] <= 5 then
				currentMode = e[4] - 1
				return
			end
		end
	end
end

local function main()
	--Рисуем топбар
	ecs.drawTopBar(1, 1, xSize, currentMode, colors.topbar, colors.topbarText, {"home", "🏠"}, {"Buy", "⟱"}, {"Sell", "⟰"}, {"Lottery", "☯"}, {"My profile", moneySymbol})
	--Рисуем данные о юзере справа вверху
	local text = "§f" .. massivWithProfile.nickname .. "§7, " .. massivWithProfile.money .. moneySymbol
	ecs.smartText(xSize - unicode.len(text) + 3, 2, text)
	--Рисуем серый фон
	ecs.square(1, 4, xSize, ySize - 3, colors.background)
end

------------------------------------------ Программа -----------------------------------------------------------------

--Очищаем экран
ecs.prepareToExit()
--Создание папок, если их нет
init()
--Загрузка файла торговой площадки
--loadMarket()
--Загрузка файла магазина админов
loadAdminShop()

massivWithProfile = loadUser("IT")

while true do
	main()

	if currentMode == 1 then
		 currentMode = 2
		--about()
	elseif currentMode == 2 then
		buy()
	elseif currentMode == 3 then
		sell()
	elseif currentMode == 4 then
		 currentMode = 2
		--fortune()
	else
		 currentMode = 2
		--user()
	end
end

------------------------------------------ Выход -----------------------------------------------------------------








