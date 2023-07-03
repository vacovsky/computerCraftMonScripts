mc = peripheral.find("colonyIntegrator")
me = peripheral.find("meBridge")

monitor = peripheral.find("monitor")
monitor.setTextScale(2)

location = mc.getLocation()


function round(num, numDecimalPlaces)
    return tonumber(string.format("%." .. (numDecimalPlaces or 0) .. "f", num))
end

last_happ = round(mc.getHappiness(), 2) * 10


while (true) do
    local underAttack = "No"
    if mc.isUnderAttack() then
        underAttack = "Yes"
    end

    monitor.setCursorPos(1, 1)
    monitor.write(mc.getColonyName() .. ": " .. location.x  .. " " .. location.y .. " " .. location.z )

    monitor.setCursorPos(1, 2)
    monitor.write("Citizen Count: " .. mc.amountOfCitizens() .. " / " .. mc.maxOfCitizens())

    monitor.setCursorPos(1, 3)
    happ = round(mc.getHappiness(), 2) * 10
    
    trend = "-"
    if happ >= last_happ then
        trend = "UP"
    else
        trend = "DOWN" 
    end
    monitor.write("Happiness: " .. happ .. " %  /  " .. trend)
    if mc.getHappiness() < 9 then
        term.setBackgroundColor( colors.red )
    else
        term.setBackgroundColor( colors.black )
    end

    monitor.setCursorPos(1, 4)
    monitor.write("Active Build Sites: " .. mc.amountOfConstructionSites())

    monitor.setCursorPos(1, 5)
    monitor.write("Under Attack: " .. underAttack)

    monitor.setCursorPos(1, 6)
    monitor.write("Time: ".. textutils.formatTime(os.time(),true) .. "        ")


--    monitor.setCursorPos(1, 8)
--    monitor.write("AE/t: ".. me.getEnergyUsage().. "                   ")


    sleep(1)
end
