json = require "json"

local WAIT_SECONDS = 90
local exportDirection = "bottom"
local meBridge = peripheral.find("meBridge")
local colony = peripheral.find("colonyIntegrator")
--------------------------


function Main()
    -- get all requests
    local reqs = GetColonyRequests()
    -- submit all possible requests
    SubmitBuildRequestToAutomation(reqs)
    -- wait sme time for crafting to complete
    -- sleep(WAIT_SECONDS)   
end

function GetColonyRequests()
    local reqs = colony.getRequests()
    -- WriteToFile(json.encode(reqs), "requests.json", "w")
    return reqs
end

function SubmitBuildRequestToAutomation(requests)
    for k, request in pairs(requests) do
        for k2, item in pairs(request.items) do
            local acr = {
                name = item.name,
                count = item.count,
            }
            print("Crafting "..acr.name.." x "..acr.count)
            meBridge.craftItem(acr)
            print("Crafted "..acr.name.." x "..acr.count)

            print("Exporting "..acr.name.." x "..acr.count)
            meBridge.exportItem(acr, exportDirection)
            print("Exported "..acr.name.." x "..acr.count.. " to "..exportDirection)
        end
    end
end

function WriteToFile(input, fileName, mode)
    local file = io.open(fileName, mode)
    io.output(file)
    io.write(input)
    io.close(file)
 end


print("Loading devices.")
print("Beginning monitor loop.")

local loopCounter = 0

while true do
   loopCounter = loopCounter + 1
   print("Loop " .. loopCounter .. " started.")
   Main(0)
    --    WriteToFile(json.encode(last), "monitorData.json", "w")
   print("Loop " .. loopCounter .. " finished. Next pass in "..WAIT_SECONDS.." seconds.")
   sleep(WAIT_SECONDS)
end