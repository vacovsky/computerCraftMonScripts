file = fs.open("/SFGarageDoorStatus.txt", "w")
if file then
    input = read()
file.write(input)
file.close()
print("Saved "..input..".")
else
print("Failed")
end