mc = peripheral.find("colonyIntegrator")
monitor = peripheral.find("monitor")
monitor.setTextScale(1)

location = mc.getLocation()


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
    monitor.write("Happiness: " .. math.floor(mc.getHappiness()) .. " / 10" )

    monitor.setCursorPos(1, 4)
    monitor.write("Active Build Sites: " .. mc.amountOfConstructionSites())

    monitor.setCursorPos(1, 5)
    monitor.write("Under Attack: " .. underAttack)

    monitor.setCursorPos(1,6)
    monitor.write(textutils.formatTime(os.time()) .. "   ",true)
    sleep(1)
end
