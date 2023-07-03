while true do --Always loop
    peripheral.call("back", "clear")
    local timeStr = textutils.formatTime(os.time(), false)
    peripheral.call( "back ", "write", timeStr )
    sleep(1)
end
