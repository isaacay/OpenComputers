
local component = require("component")
local event = require("event")
local port = 512
local keyWord = "ECSGrief"
local modem

if component.isAvailable("modem") then
	modem = component.modem
else
	error("This program requires a wireless modem for the job!")
end

modem.open(port)

-------------------------------------------------------------------------------------

local commands = {
	[17] = {
		messageToRobot = "forward",
		screenText = "I order the robot to move forward",
	},
	[31] = {
		messageToRobot = "back",
		screenText = "I order the robot to move backwards",
	},
	[30] = {
		messageToRobot = "turnLeft",
		screenText = "I order the robot to turn left",
	},
	[32] = {
		messageToRobot = "turnRight",
		screenText = "I order the robot to turn to the right",
	},
	[57] = {
		messageToRobot = "up",
		screenText = "I order the robot to move up",
	},
	[42] = {
		messageToRobot = "down",
		screenText = "I order the robot to move down",
	},
	[18] = {
		messageToRobot = "use",
		screenText = "I order the robot to use the object in their hands",
	},
	[14] = {
		messageToRobot = "exit",
		screenText = "I order the robot to complete the adoption of the program messages",
	},
	[59] = {
		messageToRobot = "selfDestroy",
		screenText = "I order the robot to destroy all information on the disk. it was a pleasure to work with you, Lord!",
	},
	[19] = {
		messageToRobot = "redstone",
		screenText = "I order the robot to turn on / off Redstone around him",
	},
	[16] = {
		messageToRobot = "drop",
		screenText = "I order the robot to throw out an item from the selected slot",
	},
	[33] = {
		messageToRobot = "changeToolUsingMode",
		screenText = "I order the robot to change the mode of use of the subject, namely the swing () or use ()",
	},
}

local function send()
	while true do
		local eventData = { event.pull() }
		if eventData[1] == "key_down" then
			if commands[eventData[4]] then
				print(commands[eventData[4]].screenText)
				modem.broadcast(port, keyWord, commands[eventData[4]].messageToRobot)
				if commands[eventData[4]].messageToRobot == "exit" then
					return
				end
			end
		elseif eventData[1] == "scroll" then
			if eventData[5] == 1 then
				print("I order the robot to increase the mode of use of objects, ie, useDown () will change to use (), and use () to useUp ()")
				modem.broadcast(port, keyWord, "increaseToolUsingSide")
			else
				print("I order the robot mode to reduce the use of objects, ie, useUp () will change to use (), and use () to useDown ()")
				modem.broadcast(port, keyWord, "decreaseToolUsingSide")
			end
		end
	end
end

local function main()
	print(" ")
	print("Welcome to the ECS Grief Sender v1.0 alpha early access!")
	print(" ")
	print("Use WASD, as well as the SPACE and SHIFT to move. Pressing the E key will cause the robot to use the items found in his hand. You can also use the F1 key for emergency removal of all data from the robot and BACKSPACE for easy exit from the program. Happy hunting for ests!")
	print(" ")
	send()
	print(" ")
	print("The program of domination of the robot is complete!")
end

-------------------------------------------------------------------------------------

main()

-------------------------------------------------------------------------------------







