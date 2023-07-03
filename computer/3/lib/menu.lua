version = 20230418.0800
--[[
	Last edited: see version YYYYMMDD.HHMM
	This is meant to be used as a library for any of your programs.
	Save it as menu.lua preferably in a subfolder called 'lib'
	To use it:
	local menu = require("lib.menu")
	
	local prompt = "Choose your option:"
	-- table of options, whatever text you like from 1 to 10 for turtles, 1 to 16 for computers
	local options = {"First choice", "Second choice", "Third choice", "Fourth choice", "Fifth choice",
					"Sixth choice","Seventh choice", "Eighth choice", "Ninth choice", "Tenth choice"}				
	local choice = menu.new(prompt, options) OR local choice = menu.menu(prompt, options)
	if choice == nil then
		print ("You chose to cancel the menu")
	else
		print("You chose option no "..choice..": "..options[choice])
	end
	
	print(menu.getString("What is your name?", true, 3, 8))
	print(menu.getInteger("How old are you?", 5, 100))
	print(menu.getFloat("How tall are you?",0.4, 2.4))
	print(menu.getBool("do you like Lua (y/n)?")) OR print(menu.getBoolean("do you like Lua (y/n)?"))
]]
local menuPrompt = "Type number (q to quit) -> Enter: "
local function clear()
	-- clear the terminal and reset cursor
	term.clear()
	term.setCursorPos(1, 1)
end

local function drawError(prompt, options, width, height, errorNo, currentLine)
	local errorText = ""
	-- check number of menu options is 3 less than screen height
	local numOptions = #options
	if numOptions > height - 3 then
		numOptions = height - 3
	end
	if errorNo == 1 then
		errorText = "Just pressing Enter does not work"
	elseif errorNo == 2 then
		errorText = "Incorrect input use numbers only"
	elseif errorNo == 3 then
		errorText = "Incorrect input use 1 to "..numOptions.." only"
	elseif errorNo == 4 then
		errorText = "Incorrect input use whole numbers only"
	end
	if currentLine == height then --using all available lines
		--[[ 
		if on lowest line, pressing Enter
		automatically scrolls all text up 1 line
		so redraw the menu.
		]]
		drawMenu(prompt, options, width, height)
		term.setCursorPos(1, currentLine - 1)
		term.clearLine()
		term.write(errorText)
		sleep(1.5)
		term.clearLine()
		term.setCursorPos(1, currentLine - 1)
		term.write(menuPrompt)
	else
		term.clearLine() 		-- use the current line to display error message
		term.setCursorPos(1, currentLine)
		term.write(errorText)	
		sleep(1.5)				-- pause for 1.5 secs
		term.clearLine()		-- clear line ready for user to re-enter their choice
		term.setCursorPos(1, currentLine)
		term.write(menuPrompt)
	end
end

local function drawMenu(title, options, width, height)
	local numOptions = #options
	if numOptions > height - 3 then
		numOptions = height - 3
	end
	clear()
	print(title)
	for i = 1, numOptions do
		local trimOption = string.sub(options[i], 1, width - 5)
		if i < 10 then
			print("\t"..i..") ".."\t"..trimOption)
		else
			print("\t"..i..") "..trimOption)
		end
	end
	term.write(menuPrompt)
	
	--return numOptions + 3
	return term.getCursorPos()
end

local function new(prompt, options)
	--turtle   terminal size = 39 x 13 -- max menu options = 10, max option length = 34
	--computer terminal size = 51 x 19 -- max menu options = 16, max option length = 47
	local width, height = term.getSize()
	local errorNo = 0
	local choice = nil
	local numOptions = #options
	local modifier = ""
	
	--local currentLine = drawMenu(prompt, options, width, height)
	local col, row = drawMenu(prompt, options, width, height)
	while choice == nil do
		--term.setCursorPos(1, currentLine)
		term.setCursorPos(col, row)
		if errorNo > 0 then
			--drawError(prompt, options, width, height, errorNo, currentLine)
			drawError(prompt, options, width, height, errorNo, row)
		end
		choice = read()
		if choice == "" then
			errorNo = 1 				-- enter only
			choice = nil
		else
			if choice == "q" or choice == "Q" then
				choice = nil
				modifier = "q"			-- quit chosen
				break
			elseif choice:find("h") ~= nil or choice:find("H") ~= nil then
				modifier = "h"			-- help chosen
				choice = tonumber(choice:sub(1, #choice - 1))
			else
				-- check for number entered eg "2 32"
				local space = choice:find(" ")
				if space ~= nil then
					modifier = tonumber(choice:sub(space + 1))
					choice = choice:sub(1, space)
				end
				choice = tonumber(choice)
				if choice == nil then
					errorNo = 2			-- numbers only
				else
					if math.floor(choice / 1) ~= choice then
						errorNo = 4		-- integer only
						choice = nil
					end
				end
			end
			if choice ~= nil then
				if choice < 1 or choice > numOptions then
					errorNo = 3	
					choice = nil
				end
			end
		end
	end
	clear()
	return choice, modifier -- nil, "q" = quit | #, "h" = help needed for that choice | #, "" number chosen
end

local function tchelper(first, rest)
	return first:upper()..rest:lower()
end

local function toTitle(inputText) --converts any string to Title Case
	return inputText:gsub("(%a)([%w_']*)", tchelper)
end

local function getBoolean(prompt) -- assumes yes/no type entries from user
	while true do
		write(prompt.."_")
		userInput = read()
		if string.len(userInput) == 0 then
			print("\nJust pressing the Enter key doesn't work...")
		else		
			if string.sub(userInput, 1, 1):lower() == "y" then
				userInput = true
				break
			elseif string.sub(userInput, 1, 1):lower() == "n" then
				userInput = false
				break
			else
				print("\nOnly anything starting with y or n is accepted...")
			end
		end	
	end
	return userInput
end

local function getNumber(prompt, minVal, maxVal) -- minInt and maxInt are given defaults if not passed
	local found = false
	while not found do
		write(prompt.."_")
		userInput = read()
		if string.len(userInput) == 0 then
			print("\nJust pressing the Enter key doesn't work...")
		else
			if tonumber(userInput) ~= nil then
				userInput = tonumber(userInput)
				if minVal ~= nil then --minValue set
					if maxVal ~= nil then
						if userInput >= minVal and userInput <= maxVal then
							found = true
						else
							print("\nTry a number from "..minInt.." to "..maxInt.."...")
						end
					else -- no max value
						if userInput >= minVal then
							found = true
						else
							print("\nTry a number from "..minInt.." to "..maxInt.."...")
						end
					end
				else -- no min value
					if maxVal ~= nil then
						if userInput <= maxVal then
							found = true
						else
							print("\nTry a number from "..minInt.." to "..maxInt.."...")
						end
					else -- no max value
						found = true
					end
				end
			else
				print("\nTry entering a number - "..userInput.." does not cut it...")
			end
		end
	end
	return userInput
end

local function getString(prompt, withTitle, minInt, maxInt) -- withTitle, minInt and maxInt are given defaults if not passed
	withTitle = withTitle or false
	minInt = minInt or 1
	maxInt = maxInt or 20
	while true do
		write(prompt.."_")
		userInput = read()
		if string.len(userInput) == 0 then
			print("\nJust pressing Enter doesn't work...")
		else		
			if string.len(userInput) >= minInt and string.len(userInput) <= maxInt then
				if withTitle then
					userInput = toTitle(userInput)
				end
				break
			else
				print("\nTry entering text between "..minInt.." and "..maxInt.." characters...")
			end
		end
	end

	return userInput
end

-- these functions MUST be left BELOW the main functions to prevent errors
local function menu(prompt, options)
	return new(prompt, options)
end

local function getFloat(prompt, minVal, maxVal)
	return getNumber(prompt, minVal, maxVal)
end

local function getInteger(prompt, minInt, maxInt)
	return math.floor(getNumber(prompt, minInt, maxInt))
end

local function getBool(prompt)
	return getBoolean(prompt)
end
	
return 
{
	new = new,
	menu = menu,
	getString = getString,
	getInteger = getInteger,
	getBoolean = getBoolean,
	getFloat = getFloat,
	getBool = getBool,
	getBoolean = getBoolean
}