json = require "json"
-- Specific to colony integrator

local WAIT_SECONDS = 120
local DEVICES = {}

function LoadDevices()
   for k,v in pairs(peripheral.getNames()) do
         DEVICES[v] = peripheral.getMethods(v)
   end
   WriteToFile(json.encode(DEVICES), "devices.json", "w")
end

function string.starts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end

function GetStatusOfAttachedDevices()
   local MM = {}
   MM.timeStamp = os.epoch("utc")
   for deviceName, v in pairs(DEVICES) do
      local device = peripheral.wrap(deviceName)
      MM[deviceName] = {}
      for _, method in pairs(v) do
         -- TODO make whitelist or blacklist for methods and devices
            if method == "amountOfCitizens"
            or method == "getHappiness"
            or method == "maxOfCitizens"
            -- or method == "getCitizens"
            or method == "isUnderAttack"
            or method == "isUnderRaid"
            or method == "getRequests"
            or method == "getBuildings"
            or method == "isUnderRaid"
            or method == "getVisitors"
            or method == "getRequests"
            or method == "getWorkOrders" 
            then
            local result = device[method]()
            print(device, method, result)

            if method == "getBuildings"
            or method == "getRequests"
            or method == "getWorkOrders"
            or method == "getVisitors" then
               local count = 0
               for _, item in pairs(result) do
                  count = count +1
               end
               result = count
            end
            MM[deviceName][method] = result
            MM[deviceName]["name"] = "MagicTownColonyIntegrator"
         end
      end
   end
   return MM
end

function WriteToFile(input, fileName, mode)
   local file = io.open(fileName, mode)
   io.output(file)
   io.write(input)
   io.close(file)
end

function tablelength(T)
   local count = 0
   for _ in pairs(T) do count = count + 1 end
   return count
 end

--------------------------
print("Loading devices.")
LoadDevices()
print(tablelength(DEVICES) .. " Devices loaded.")
print("Beginning monitor loop.")

local loopCounter = 0

while true do
   loopCounter = loopCounter + 1
   print("Loop " .. loopCounter .. " started.")
   local last = GetStatusOfAttachedDevices()
   -- print(last)
   WriteToFile(json.encode(last), "monitorData.json", "w")
   print("Loop " .. loopCounter .. " finished. Next pass in "..WAIT_SECONDS.." seconds.")
   sleep(WAIT_SECONDS)
end
