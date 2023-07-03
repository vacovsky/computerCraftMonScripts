json = require "json"

local WAIT_SECONDS = 60
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

               if method == "getCraftingCPUs" then
                  totalCpus = 0
                  totalActiveCPUs = 0

                  totalMem = 0
                  totalActiveMemory = 0

                  for k, cpu in pairs(result) do
                     totalCpus = totalCpus + 1
                     totalMem = totalMem + cpu.storage
                     if cpu.isBusy then
                        totalActiveCPUs = totalActiveCPUs + 1
                        totalActiveMemory = totalActiveMemory + cpu.storage
                  end

                  end
                  MM[deviceName][method.."ActiveCPUs"] = totalActiveCPUs
                  MM[deviceName][method.."UsedMemory"] = totalActiveMemory
                  MM[deviceName][method.."TotalMemory"] = totalMem
                  MM[deviceName][method.."TotalCPUs"] = totalCpus

                  MM[deviceName]["name"] = deviceName
               else
                  MM[deviceName][method] = result
                  MM[deviceName]["name"] = deviceName
               end



            end
         end
      end
      -- print(MM[deviceName])
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
   WriteToFile(json.encode(last), "monitorData.json", "w")
   print("Loop " .. loopCounter .. " finished. Next pass in "..WAIT_SECONDS.." seconds.")
   sleep(WAIT_SECONDS)
end
