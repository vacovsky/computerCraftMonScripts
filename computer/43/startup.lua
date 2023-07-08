json = require "json"

local WAIT_SECONDS = 30
local exportDirection = "down"
local meBridge = peripheral.find("meBridge")
local colony = peripheral.find("colonyIntegrator")
local colonyName = "TronaColonyIntegrator"
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

function ExportItemWrapper(item)
    print("Exporting "..item.name)
    local count, _ = meBridge.exportItem(item, exportDirection)
    print("Exported "..item.name.." x "..count.. " to "..exportDirection)
    return count
end

function SubmitBuildRequestToAutomation(requests)
    local countToWrite = 0
    for k, request in pairs(requests) do
        for k2, item in pairs(request.items) do
            local acr = {
                name = item.name,
                count = item.count,
            }
            print("Crafting "..acr.name.." x "..acr.count)
            meBridge.craftItem(acr)
            print("Crafted "..acr.name.." x "..acr.count)
            local c = ExportItemWrapper(acr)
            countToWrite = countToWrite + c
        end
    end
    WriteToFile(json.encode({
        timeStamp = os.epoch("utc"),
        [colonyName] = {
            name = colonyName,
            servedCraftingRequests = countToWrite
        }
    }), "requestsServed.json", "w")
    
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
   if pcall(Main) then
        print("Loop " .. loopCounter .. " finished. Next pass in "..WAIT_SECONDS.." seconds.") 
   end
   sleep(WAIT_SECONDS)
end

-- json = require "json"

-- local WAIT_SECONDS = 30
-- local exportDirection = "bottom"
-- local meBridge = peripheral.find("meBridge")
-- local colony = peripheral.find("colonyIntegrator")
-- --------------------------


-- function Main()
--     -- get all requests
--     local reqs = GetColonyRequests()
--     -- submit all possible requests
--     SubmitBuildRequestToAutomation(reqs)
--     -- wait sme time for crafting to complete
--     -- sleep(WAIT_SECONDS)   
-- end

-- function GetColonyRequests()
--     local reqs = colony.getRequests()
--     -- WriteToFile(json.encode(reqs), "requests.json", "w")
--     return reqs
-- end

-- function SubmitBuildRequestToAutomation(requests)
--     for k, request in pairs(requests) do
--         for k2, item in pairs(request.items) do
--             local acr = {
--                 name = item.name,
--                 count = item.count,
--             }
--             print("Crafting "..acr.name.." x "..acr.count)
--             meBridge.craftItem(acr)
--             print("Crafted "..acr.name.." x "..acr.count)

--             print("Exporting "..acr.name.." x "..acr.count)
--             meBridge.exportItem(acr, exportDirection)
--             print("Exported "..acr.name.." x "..acr.count.. " to "..exportDirection)
--         end
--     end
-- end

-- function WriteToFile(input, fileName, mode)
--     local file = io.open(fileName, mode)
--     io.output(file)
--     io.write(input)
--     io.close(file)
--  end


-- print("Loading devices.")
-- print("Beginning monitor loop.")

-- local loopCounter = 0

-- while true do
--    loopCounter = loopCounter + 1
--    print("Loop " .. loopCounter .. " started.")
--    Main(0)
--     --    WriteToFile(json.encode(last), "monitorData.json", "w")
--    print("Loop " .. loopCounter .. " finished. Next pass in "..WAIT_SECONDS.." seconds.")
--    sleep(WAIT_SECONDS)
-- end
-- ===================

-- json = require "json"

-- local WAIT_SECONDS = 30
-- local exportDirection = "down"
-- local meBridge = peripheral.find("meBridge")
-- local colony = peripheral.find("colonyIntegrator")
-- --------------------------


-- function Main()
--     -- get all requests
--     local reqs = GetColonyRequests()
--     -- submit all possible requests
--     SubmitBuildRequestToAutomation(reqs)
--     -- wait sme time for crafting to complete
--     -- sleep(WAIT_SECONDS)   
-- end

-- function GetColonyRequests()
--     local reqs = colony.getRequests()
--     -- WriteToFile(json.encode(reqs), "requests.json", "w")
--     return reqs
-- end

-- function SubmitBuildRequestToAutomation(requests)
--     WriteToFile(json.encode(requests), "requests.json", "w")

--     for k, request in pairs(requests) do
--         for k2, item in pairs(request.items) do
--             local acr = {
--                 name = item.name,
--                 count = item.count,
--             }
--             print("Crafting "..acr.name.." x "..acr.count)
--             meBridge.craftItem(acr)
--             print("Crafted "..acr.name.." x "..acr.count)

--             print("Exporting "..acr.name.." x "..acr.count)
--             meBridge.exportItem(acr, exportDirection)
--             print("Exported "..acr.name.." x "..acr.count.. " to "..exportDirection)
--         end
--     end
-- end

-- function WriteToFile(input, fileName, mode)
--     local file = io.open(fileName, mode)
--     io.output(file)
--     io.write(input)
--     io.close(file)
--  end


-- print("Loading devices.")
-- print("Beginning monitor loop.")

-- local loopCounter = 0

-- while true do
--    loopCounter = loopCounter + 1
--    print("Loop " .. loopCounter .. " started.")
--    if pcall(Main) then
--         print("Loop " .. loopCounter .. " finished. Next pass in "..WAIT_SECONDS.." seconds.") 
--    end
--    sleep(WAIT_SECONDS)
-- end