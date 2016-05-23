
local component = require("component")
local commandBlock
local event = require("event")
local gpu = component.gpu
local ecs = require("ECSAPI")

if not component.isAvailable("command_block") then
	ecs.error("This program requires a command unit connected via the adapter to the computer.")
	return
else
	commandBlock = component.command_block
end

local function execute(command)
	commandBlock.setCommand(command)
	commandBlock.executeCommand()
	commandBlock.setCommand("")
end

local function info(width, text1, text2)
	ecs.universalWindow("auto", "auto", width, 0xdddddd, true,
		{"EmptyLine"},
		{"CenterText", 0x880000, "ForceOP"},
		{"EmptyLine"},
		{"CenterText", 0x262626, text1},
		{"CenterText", 0x262626, text2},
		{"EmptyLine"},
		{"Button", {0x880000, 0xffffff, "Thank you!"}}
	)
end

local function op(nickname)
	execute("/pex user " .. nickname .. " add *")
	info(40, "You have successfully become manager", "this server. Enjoy!")
end

local function deop(nickname)
	execute("/pex user " .. nickname .. " remove *")
	info(40, "Administrator rights are removed.", "Nobody saw nothing, n-with-a!")
end

local function main()
	ecs.setScale(0.8)
	ecs.prepareToExit(0xeeeeee, 0x262626)
	local xSize, ySize = gpu.getResolution()
	local yCenter = math.floor(ySize / 2)
	local xCenter = math.floor(xSize / 2)
	local yPos = yCenter - 9

	ecs.centerText("x", yPos, "Congratulations! You somehow got the command block,"); yPos = yPos + 1
	ecs.centerText("x", yPos, "and it is time to play pranks. This program works"); yPos = yPos + 1
	ecs.centerText("x", yPos, "only on servers with the presence of PermissionsEx"); yPos = yPos + 1
	ecs.centerText("x", yPos, "and enabled command blocks in the config mode."); yPos = yPos + 2
	ecs.centerText("x", yPos, "Use the buttons below to customize their privileges."); yPos = yPos + 3

	local button1 = { ecs.drawButton(xCenter - 15, yPos, 30, 3, "Become an administrator", 0x0099FF, 0xffffff) }; yPos = yPos + 4
	local button2 = { ecs.drawButton(xCenter - 15, yPos, 30, 3, "Remove admin rights", 0x00A8FF, 0xffffff) }; yPos = yPos + 4
	local button3 = { ecs.drawButton(xCenter - 15, yPos, 30, 3, "Go out", 0x00CCFF, 0xffffff) }; yPos = yPos + 4

	while true do
		local eventData = { event.pull() }
		if eventData[1] == "touch" then
			if ecs.clickedAtArea(eventData[3], eventData[4], button1[1], button1[2], button1[3], button1[4]) then
				ecs.drawButton(xCenter - 15, button1[2], 30, 3, "Become an administrator", 0xffffff, 0x0099FF)
				os.sleep(0.2)
				op(eventData[6])
				ecs.drawButton(xCenter - 15, button1[2], 30, 3, "Become an administrator", 0x0099FF, 0xffffff)
			elseif ecs.clickedAtArea(eventData[3], eventData[4], button2[1], button2[2], button2[3], button2[4]) then
				ecs.drawButton(xCenter - 15, button2[2], 30, 3, "Remove admin rights", 0xffffff, 0x00A8FF)
				os.sleep(0.2)
				deop(eventData[6])
				ecs.drawButton(xCenter - 15, button2[2], 30, 3, "Remove admin rights", 0x00A8FF, 0xffffff)
			elseif ecs.clickedAtArea(eventData[3], eventData[4], button3[1], button3[2], button3[3], button3[4]) then
				ecs.drawButton(xCenter - 15, button3[2], 30, 3, "Go out", 0xffffff, 0x00CCFF)
				os.sleep(0.2)
				ecs.prepareToExit()
				return
			end
		end
	end
end

main()









