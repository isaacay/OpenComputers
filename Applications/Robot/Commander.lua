local robot = require("robot")
local robotAPI = require("robotAPI")

local args = {...}

------------------------------------------------------------------------------------------------------------------------

if #args < 0 then error("No arguments!") end
local commands = args[1]

local symbols = {}
local symbolcounter = 1

------------------------------------------------------------------------------------------------------------------------

local function executeCommand(symbol)
	if symbol == "f" then
		robotAPI.move("forward")
	elseif symbol == "r" then
		robot.turnRight()
		print("Turn right!")
	elseif symbol == "l" then
		robot.turnLeft()
		print("Turn left!")
	elseif symbol == "t" then
		robot.turnAround()
		print("Krrrrruuu by God!")
	elseif symbol == "u" then
		robotAPI.move("up")
		print("I rise above!")
	elseif symbol == "d" then
		robotAPI.move("down")
		print("Falls below!")
	elseif symbol == "m" then
		robotAPI.move("forward")
		robot.swing()
		print("I dig ahead!")
	elseif symbol == "s" then
		print("I dig ahead!", robot.swing())

	--Вообще потная хуйня, но работает, епта!
	elseif tonumber(symbol) ~= nil then
		local startNumber = symbol
		local counter = 1
		for i = (symbolcounter + 1), #symbols do
			local newNumber = tonumber(symbols[i])
			if newNumber then
				startNumber = startNumber .. symbols[i]
				counter = counter + 1
			else
				break
			end
		end
		startNumber = tonumber(startNumber)

		print("I carry "..startNumber.." just click "..symbols[symbolcounter + counter])
		for i = 1, startNumber do
			executeCommand(symbols[symbolcounter + counter])
		end

		symbolcounter =  symbolcounter + counter
	end
end

------------------------------------------------------------------------------------------------

for i = 1, #commands do
	table.insert(symbols, string.sub(commands, i, i))
end

print(" ")
print("I began to work!")
print(" ")

while symbolcounter <= #symbols do
	executeCommand(symbols[symbolcounter])
	symbolcounter = symbolcounter + 1
end

print(" ")
print("Completed!")
print(" ")