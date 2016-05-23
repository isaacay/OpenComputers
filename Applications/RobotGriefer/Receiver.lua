
local component = require("component")
local robot = require("robot")
local event = require("event")
local fs = require("filesystem")
local port = 512
local keyWord = "ECSGrief"
local modem
local redstone = component.redstone
local redstoneState = false
local toolUsingMode = false
local toolUsingSide = 1

if component.isAvailable("modem") then
	modem = component.modem
else
	error("This program requires a wireless modem for the job!")
end

modem.open(port)

-------------------------------------------------------------------------------------

local commands = {
	forward = robot.forward,
	back = robot.back,
	turnRight = robot.turnRight,
	turnLeft = robot.turnLeft,
	up = robot.up,
	down = robot.down,
	swing = robot.swing,
	drop = robot.drop
}

local function redstoneControl()
	if not redstone then return end
	if redstoneState then
		for i = 0, 5 do
			redstone.setOutput(i, 0)
		end
		print("Redstone signal is enabled on all sides of the robot!")
		redstoneState = false
	else
		for i = 0, 5 do
			redstone.setOutput(i, 15)
		end
		print("Redstone signal is turned off.")
		redstoneState = true
	end
end

local function receive()
	while true do
		local eventData = { event.pull() }
		if eventData[1] == "modem_message" and eventData[4] == port and eventData[6] == keyWord then
			local message = eventData[7]
			local message2 = eventData[8]

			if commands[message] then
				commands[message]()
			else
				if message == "selfDestroy" then
					local fs = require("filesystem")
					for file in fs.list("") do
						print("kill \"" .. file .. "\"")
						fs.remove(file)
					end
					require("term").clear()
					require("computer").shutdown()
				elseif message == "use" then
					if toolUsingMode then
						if toolUsingSide == 1 then
							print("Equipped using the right-click the object in front of the robot mode")
							robot.use()
						elseif toolUsingSide == 0 then
							print("Equipped using the object in the right-click operation by robot")
							robot.useDown()
						elseif toolUsingSide == 2 then
							print("Equipped using the right-click the object in the robot mode")
							robot.useUp()
						end
					else
						if toolUsingSide == 1 then
							print("Using Equipped object in the left-click mode to robot")
							robot.swing()
						elseif toolUsingSide == 0 then
							print("Using Equipped object in the left-click mode for robot")
							robot.swingDown()
						elseif toolUsingSide == 2 then
							print("Using Equipped object in the left-click mode, the robot")
							robot.swingUp()
						end
					end
				elseif message == "exit" then
					return
				elseif message == "redstone" then
					redstoneControl()
				elseif message == "changeToolUsingMode" then
					toolUsingMode = not toolUsingMode
				elseif message == "increaseToolUsingSide" then
					print("Change the mode of using things")
					toolUsingSide = toolUsingSide + 1
					if toolUsingSide > 2 then toolUsingSide = 2 end
				elseif message == "decreaseToolUsingSide" then
					print("Change the mode of using things")
					toolUsingSide = toolUsingSide - 1
					if toolUsingSide < 0 then toolUsingSide = 0 end
				end
			end
		end
	end
end

local function main()
	print(" ")
	print("Welcome to the ECS Grief Receiver v1.0 alpha early access! There is a waiting command from the wireless device.")
	print(" ")
	receive()
	print(" ")
	print("Messages reception program is complete!")
end

-------------------------------------------------------------------------------------

main()

-------------------------------------------------------------------------------------







