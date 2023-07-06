json = require "json"

local WAIT_SECONDS = 300
local DEVICES = {}
local LastLoopResult = {}

function LoadDevices()
   for k,v in pairs(peripheral.getNames()) do
      if not string.starts(v, "meBridge") then
         DEVICES[v] = peripheral.getMethods(v) 
      end
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
         if string.starts(method, "get") 
         or string.starts(method, "is") then
            if method ~= "getMode" 
            and method ~= "isEjecting" 
            and method ~= "getInputColor" 
            and method ~= "isOpen" 
            and method ~= "getItem" 
            and method ~= "getOutput" 
            and method ~= "getRecipeProgress" 
            and method ~= "getConfigurableTypes" 
            and method ~= "getSupportedUpgrades" 
            and method ~= "getOwnerUUID" 
            and method ~= "getInput" 
            and method ~= "getTypeRemote" 
            and method ~= "getItemLimit" 
            and method ~= "isPresentRemote" 
            and method ~= "getDirection" 
            and method ~= "getMethodsRemote" 
            and method ~= "getRedstoneMode" 
            and method ~= "getNamesRemote" 
            and method ~= "getItemDetail" 
            and method ~= "isItemCraftable" 
            and method ~= "isItemCrafting" 
            and method ~= "fingerprint" 
            and method ~= "getSupportedModes" then
               -- print(deviceName.. "." .. method)

               local result = device[method]()
               
               if type(result) == table and result.tags ~= nil then
                  print(result)
                  result.tags = {}
               end

               MM[deviceName][method] = result
               MM[deviceName]["name"] = deviceName

            end
         end
      end
      -- print(MM[deviceName])
   end
   LastLoopResult = MM
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
   
   if pcall(GetStatusOfAttachedDevices) then 
      WriteToFile(json.encode(LastLoopResult), "monitorData.json", "w")
      print("Loop " .. loopCounter .. " finished. Next pass in "..WAIT_SECONDS.." seconds.")
   end
   -- local last = GetStatusOfAttachedDevices()
   -- WriteToFile(json.encode(last), "monitorData.json", "w")
   print("Loop " .. loopCounter .. " finished. Next pass in "..WAIT_SECONDS.." seconds.")
   sleep(WAIT_SECONDS)
end
