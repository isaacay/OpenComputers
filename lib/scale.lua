local component = require("component")
local gpu, screen = component.gpu, component.screen

local scale = {}

------------------------------------------------------------------------------------------

--Изменить масштаб монитора
function scale.set(scale, debug)
	--Базовая коррекция масштаба, чтобы всякие умники не писали своими погаными ручонками, чего не следует
	if scale > 1 then
		scale = 1
	elseif scale < 0.1 then
		scale = 0.1
	end

	--Просчет монитора в псевдопикселях - забей, даже объяснять не буду, работает как часы
	local function calculateAspect(screens)
	  local abc = 12

	  if screens == 2 then
	    abc = 28
	  elseif screens > 2 then
	    abc = 28 + (screens - 2) * 16
	  end

	  return abc
	end

	--Рассчитываем пропорцию монитора в псевдопикселях
	local xScreens, yScreens = component.screen.getAspectRatio()
	local xPixels, yPixels = calculateAspect(xScreens), calculateAspect(yScreens)
	local proportion = xPixels / yPixels

	--Получаем максимально возможное разрешение данной видеокарты
	local xMax, yMax = gpu.maxResolution()

	--Получаем теоретическое максимальное разрешение монитора с учетом его пропорции, но без учета лимита видеокарты
	local newWidth, newHeight
	if proportion >= 1 then
		newWidth = math.floor(xMax)
		newHeight = math.floor(newWidth / proportion / 2)
	else
		newHeight = math.floor(yMax)
		newWidth = math.floor(newHeight * proportion * 2)
	end

	--Получаем оптимальное разрешение для данного монитора с поддержкой видеокарты
	local optimalNewWidth, optimalNewHeight = newWidth, newHeight

	if optimalNewWidth > xMax then
		local difference = optimalNewWidth - xMax
		optimalNewWidth = xMax
		optimalNewHeight = optimalNewHeight - math.ceil(difference / 2 )
	end

	if optimalNewHeight > yMax then
		local difference = optimalNewHeight - yMax
		optimalNewHeight = yMax
		optimalNewWidth = optimalNewWidth - difference * 2 - math.ceil(difference / 2)
	end

	--Корректируем идеальное разрешение по заданному масштабу
	local finalNewWidth, finalNewHeight = math.floor(optimalNewWidth * scale), math.floor(optimalNewHeight * scale)

	--Выводим инфу, если нужно
	if debug then
		print(" ")
		print("Maximum resolution: "..xMax.."x"..yMax)
		print("proportion monitor: "..xPixels.."x"..yPixels)
		print("factor proportions: "..proportion)
		print(" ")
		print("Theoretical resolution: "..newWidth.."x"..newHeight)
		print("Optimized resolution: "..optimalNewWidth.."x"..optimalNewHeight)
		print(" ")
		print("New resolution: "..finalNewWidth.."x"..finalNewHeight)
		print(" ")
	end

	--Устанавливаем выбранное разрешение
	gpu.setResolution(finalNewWidth, finalNewHeight)
end

--scale.set(1, true)
