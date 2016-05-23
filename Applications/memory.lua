local c = require("computer")

local arg = {...}

local width = arg[1] or 50
local height = arg[2] or 50
local pixels = {}
local history = {}
local historySize = arg[3] or 1

local function mem()
  local free = c.freeMemory()
  local total = c.totalMemory()
  local used = total-free

  return math.floor(used/1024)
end

local start = mem()

for z=1,1 do
  history[z] = {"Сука блядь",{}}
  for j=1,height do
    history[z][2][j] = {}
    for i=1,width do
      history[z][2][j][i] = {0x000000,0xffffff,"#"}
    end
  end
end

local ending = mem()
print("Total available "..math.floor(c.totalMemory()/1024).."КБ RAM")
print(" ")
print("Before rendering zayuzat "..start.."КБ RAM")
print("I start drawing a picture...")
print("After drawing zayuzat "..ending.."КБ RAM")
print(" ")
local say = "bed"
if tonumber(historySize) > 1 then say = "layers" end
print("Conclusion: The size of the image "..width.."x"..height.." с "..historySize.." "..say.." shavaet "..((ending-start)*historySize).."КБ RAM")
