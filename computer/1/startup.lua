--monitor = peripheral.wrap("right")
-- shell.run("gps host -1923 97 -860")
--shell.run("gps", "host", -1923, 97, -860)

--monitor.clear()
--monitor.write("GPS HOST ACTIVE.")
---parallel.waitForAny(function() os.run({print = function() end}, "gps", "host", "-1923", "87", "-860") end, function() term.clear() term.setCursorPos(1,1) shell.run("shell") end)

--shell.run("gps host -1923 97 -860")

peripheral.find("meBridge")

-- mechanical crusher
c = peripheral.find("crusher")
c.getRecipeProgress() / c.getTicksRequired()
(c.getEnergyFilledPercentage() / 1) * 100