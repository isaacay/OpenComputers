
local component = require("component")
local modem = component.modem
local event = require("event")
local keyboard = require("keyboard")
local port = 512
modem.open(port)

local keys = {
  [17] = "moveForward",
  [31] = "moveBack",
  [30] = "turnLeft",
  [32] = "turnRight",
  [42] = "moveDown",
  [57] = "moveUp",
  [46] = "changeColor",
  [18] = "OTSOS",
  [16] = "dropAll",
  [33] = "toggleLeash",
}

---------------------------------------------------------------------------------------------------------

print(" ")
print("Welcome to the DroneGrief. Use W and S keys to move the drone, and A and D to change the direction of motion. By pressing the SHIFT drone is below, and on SPACE - above. E button will cause the drone to suck from the inventory items above and below it, and the C button will change the color of its glow. When scrolling the mouse wheel changes the speed of movement of the robot, and scrolling with clamped ALT changes its acceleration.")
print(" ")

---------------------------------------------------------------------------------------------------------

while true do
  local e = {event.pull()}
  if e[1] == "key_down" then
    if keys[e[4]] then
      print("Team drone: " .. keys[e[4]])
      modem.broadcast(port, "ECSDrone", keys[e[4]])
    end
  elseif e[1] == "scroll" then
    if e[5] == 1 then
      if keyboard.isAltDown() then
        modem.broadcast(port, "ECSDrone", "accelerationUp")
        print("Команда дрону: accelerationUp")
      else
        modem.broadcast(port, "ECSDrone", "moveSpeedUp")
        print("Команда дрону: moveSpeedUp")
      end
    else
      if keyboard.isAltDown() then
        modem.broadcast(port, "ECSDrone", "accelerationDown")
        print("Команда дрону: accelerationDown")
      else
        modem.broadcast(port, "ECSDrone", "moveSpeedDown")
        print("Команда дрону: moveSpeedDown")
      end
    end
  elseif e[1] == "modem_message" then
    if e[6] == "ECSDrone" and e[7] == "DroneInfo" then
      print(" ")
      print("drone speed: " .. tostring(e[8]))
      print("drone Acceleration: " .. tostring(e[9]))
      print("The direction of the drone: " .. tostring(e[10]))
      print(" ")
    end
  end
end





