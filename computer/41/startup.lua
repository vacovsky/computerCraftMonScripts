json = require "json"

local WAIT_SECONDS = 60
local DEVICES = {}
local FUEL_MATS = {
   "ae2:fluix_crystal",
   "ae2:certus_quartz_crystal",
   "ae2:charged_certus_quartz_crystal",
   --
   "minecraft:nether_star",
   "minecraft:wither_skull",
   "minecraft:obsidian",
   "minecraft:water",

   "minecraft:gold_ingot",
   "minecraft:raw_gold",

   "minecraft:raw_iron",
   "minecraft:iron_ingot",

   "minecraft:glowstone",
   "minecraft:emerald",
   "minecraft:diamond",

   "minecraft:chorus_fruit",
   "minecraft:chorus_flower",
   --
   "thermal:sulfur",
   "thermal:sulfur_ore",
   --
   "bigreactors:yellorium_ingot",
   "bigreactors:yellorite_ore",
   --
   "mekanism:refined_obsidian",
   "mekanism:ingot_uranium",
   "mekanism:dust_sulfur",
   "mekanism:fissile_fuel",
   "mekanism:pellet_polonium",
   "mekanism:pellet_plutonium",
   "mekanism:pellet_antimatter",
   "mekanism:polonium",
   "mekanism:pellet_uranium",
   "mekanism:uranium",
   "mekanism:block_uranium",
   "mekanism:raw_uranium",
   "mekanism:fluorite_gem",
   "mekanism:lithium",
   "mekanism:raw_osmium",
   --
   "industrialforegoing:ether_gas",
   "industrialforegoing:latex",
   "industrialforegoing:pink_slime",
   "industrialforegoing:essence",
   "industrialforegoing:meat",
}

function string.starts(String,Start)
   return string.sub(String,1,string.len(Start))==Start
end

function GetInventoryItemsCount()
   local MM = {}
   MM.ae2InventoryItem = {}

   MM.timeStamp = os.epoch("utc")
   local device = peripheral.find("meBridge")
   -- print(device)
   for _, itemType in pairs(FUEL_MATS) do
      -- print(FUEL_MATS, itemType)
      local result = device.getItem({name = itemType})
      if result == nil then result = { amount = 0 } end
      MM.ae2InventoryItem[itemType] = result.amount
      print(itemType, result.amount)
      MM.ae2InventoryItem["name"] = "ae2InventoryItem"
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
print(tablelength(DEVICES) .. " Devices loaded.")
print("Beginning monitor loop.")

local loopCounter = 0

while true do
   loopCounter = loopCounter + 1
   print("Loop " .. loopCounter .. " started.")
   local last = GetInventoryItemsCount()
   WriteToFile(json.encode(last), "monitorData.json", "w")
   print("Loop " .. loopCounter .. " finished. Next pass in "..WAIT_SECONDS.." seconds.")
   sleep(WAIT_SECONDS)
end
