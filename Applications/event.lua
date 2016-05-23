local event = require "event"

while true do
  local eventData = { event.pull() }
  print("event: " .. tostring(eventData[1]))
  for i = 2, #eventData do
    print("Argument" .. (i) .. ": " .. tostring(eventData[i]))
  end
  print(" ")
end
