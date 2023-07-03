version = 20230520.0700
--[[
	**********Toolkit v2**********
	https://pastebin.com/UFvjc1bw
	Last edited: see version YYYYMMDD.HHMM
	if NOT online:
		Make sure you create a folder 'lib' and place menu.lua and clsTurtle.lua into it
	else
		lib folder will be created and files obtained automatically!
	end
]]

args = {...} -- eg "farm", "tree"

local menu, T
--[[
Computercraft started with mc version 1.7.10 and went to 1.8.9
ccTweaked started around mc 1.12 and currently at 1.18
mc 1.18 has new blocks and bedrock at -64, so needs to be taken into account.
_HOST = The ComputerCraft and Minecraft version of the current computer environment.
For example, ComputerCraft 1.93.0 (Minecraft 1.15.2).
]]
local bedrock = 0
local ceiling = 255
local deletesWater = false
local mcMajorVersion = tonumber(_HOST:sub(_HOST:find("Minecraft") + 10, _HOST:find("\)") -3)) -- eg 1.18
if mcMajorVersion < 1.7  and mcMajorVersion >= 1.18 then -- 1.12 to 1.??
	bedrock = -64
	ceiling = 319
end
if mcMajorVersion < 1.7  and mcMajorVersion <= 1.12 then -- 1.12 to 1.??
	deletesWater = true
end

local utils = {}

function utils.calculateDimensions(R)
	if R.data == "" then -- not being called from other functions
		if R.width == 0 then -- user chose auto settings
			R.length = utils.calculateDistance(R.length) -- still facing forward
			print("Calculated Length = "..R.length)
			T:turnRight(1) -- ready to check width
			R.width = utils.calculateDistance(R.width) -- now facing right
			print("Calculated width = "..R.width)
			T:go("R2F"..R.width - 1 .."L1".. "F"..R.length - 1 .."R2") -- back at start. width/length confirmed
		end
	end
	if R.height == 0 then -- use auto settings based on water detection
		R.height = 64
	end
	return R
end

function utils.calculateDistance(estDistance)
	--[[
	measure length
	movement stops when either solid block in front or solid below
	called from utils.calculateDimensions
	]]
	local moves = 1
	local nonSolidBelow = utils.clearVegetation("down")
	if estDistance == 0 then
		while nonSolidBelow and turtle.forward() do -- while able to move and air/water below
			moves = moves + 1
			nonSolidBelow = utils.clearVegetation("down")
		end
	else
		while moves < estDistance * 2 do -- loop can only run for max of double estimated distance
			if turtle.forward() then -- able to move forward
				moves = moves + 1
			else
				break
			end
			if not utils.clearVegetation("down") then -- solid below
				turtle.back()
				moves = moves - 1
				break
			end
		end
	end
	return moves
end

function utils.checkFuelNeeded(quantity)
	local fuelNeeded = quantity - turtle.getFuelLevel() -- eg 600
	if fuelNeeded > 0 then
		if T:checkInventoryForItem({"minecraft:lava_bucket"}, {1}, false) == nil then	
			if T:checkInventoryForItem({"coal"}, {math.ceil(fuelNeeded / 60)}, false) == nil then
				T:checkInventoryForItem({"planks"}, {math.ceil(fuelNeeded / 15)})
			end
		end
		T:refuel(quantity, true)
	end
end

function utils.clearVegetation(direction)
	local isAirWaterLava = true
	-- blockType, blockModifier, data
	local blockType, blockModifier = T:getBlockType(direction)
	if blockType ~= "" then --not air
		if T:isVegetation(blockType) then
			T:dig(direction)
		elseif blockType:find("water") == nil
			   and blockType:find("lava") == nil
			   and blockType:find("bubble") == nil
			   and blockType:find("ice") == nil then
			-- NOT water, ice or lava 
			isAirWaterLava = false -- solid block
		end
	end
	
	return isAirWaterLava --clears any grass or sea plants, returns true if air or water, bubble column or ice
end

function utils.createWaterSource(level)
	if level == nil then
		level = 0
	end
	if level > 0 then
		T:up(level)
	elseif level < 0 then
		T:down(math.abs(level))
	end
	-- assume on flat surface, but allow for blocks above
	T:go("x0C2F1 x0C2F1 x0C2F1 x0C2R1 F1 x0C2F1 x0C2F1 x0C2R1 F1 x0C2F1 x0C2F1 x0C2R1 F1 x0C2F1 x0C2", false, 0, false)
	T:go("R1F1D1", false, 0, false) --move to corner and drop down
	T:go("C2F1R1 C2F1R1 C2F1R1 C2F1R1", false, 0, false)
	T:go("U1")
	for i = 1, 2 do
		T:place("minecraft:water_bucket", -1, "down", false)
		T:go("F1R1F1R1", false, 0, false)
	end
	-- refill water buckets
	for i = 1, 2 do
		sleep(0.5)
		T:place("minecraft:bucket", -1, "down", false)
	end
	T:go("R2F1R1F1R1")
	-- end above lower left of pond (starting point)
	return {}
end

function utils.drainWaterLava(R) -- 84
	local lib = {}
		
	function lib.startCorner()
		-- assume starting mid 3 high column
		T:go("D1C1R1C1 U1C1 L1C1 U1C1 R1C1 L1D1 C2C0", false, 0, true)
		-- finished on same mid 3 high column with wall in front and right completed
	end
	
	function lib.midWall()
		-- assume starting mid 3 high column
		T:go("D1R1C1 U1C1 U1C1 L1D1 C2C0", false, 0, true)
		-- finished on same mid 3 high column with wall on right completed
	end
	
	function lib.endCorner()
		-- assume starting mid 3 high column
		T:go("D1R1C1 R1C1 U1C1 L1C1 U1C1 R1C1 L2D1 C2C0", false, 0, true)
		-- finished on same mid 3 high column with wall behind and right completed
	end
	
	function lib.backTurn(offset)
		-- assume starting mid 3 high column with completed wall behind
		T:go("L1F"..offset.."L2C1 R1D1C1 U1C1 U1C1 D1")
		-- end next row along the width, facing the back, mid point
		-- wall ahead completed
	end
	
	function lib.frontTurn()
		-- assume starting mid 3 high column facing back
		-- next move is to turn toward previous wall and remove

		T:go("L2D1C1 U1C1 U1C1 D1R1 C2C0 F1R2C1 L1")
		-- end facing back ready to remove wall
	end
	
	function lib.placeRetainingWall(distance)
		-- assume starting above 3 block high area facing front (player)
		--T:down(1)
		for i = 1, distance do
			if i == 1 then -- start wall
				lib.startCorner()
			else
				if i < distance then -- mid wall
					lib.midWall()
				else -- end of the wall
					lib.endCorner()
				end
			end
			if i < distance then
				if not turtle.back() then
					T:go("R2F1R2")
				end
				T:go("C1", false, 0, true)
			end
		end
		return 1
	end
		
	function lib.placeDam(distance)
		--T:go(path, useTorch, torchInterval, leaveExisting, preferredBlock)
		local waterPresent = false
		for i = 1, distance do
			if T:isWater("down") then
				waterPresent = true
			end
			T:go("C0C2")
			if i < distance then
				if not turtle.back() then
					T:go("R2F1R2")
				end
				T:go("C1", false, 0, true)
			end
		end
		return waterPresent
	end
	
	function lib.removeDam(distance)
		-- facing towards back, dig wall up down and ahead
		for i = 1, distance do
			T:go("x0x2")
			if i < distance then
				T:forward(1)
			end
		end
		T:turnRight(2)
		-- end up back to retaining wall, mid point
	end
	
	if R.data == "" then
		if turtle.detectDown() then -- on solid surface
			turtle.forward()
		end
	end
	if deletesWater then --turtle replaces source so use clearSolid()
		R.silent = true
		R.down = true
		R.up = false
		clearSolid(R)
	else -- mc 1.12.15+ turtle does NOT replace source blocks
		-- place first stone along the length of water and measure length
		R = utils.calculateDimensions(R)
		local depth = 0
		for h = 1, R.height do
			local waterPresent = false -- resets at each level
			local row = 0
			T:go("R2D2", false, 0, true)	-- at start, level 2, facing towards the front, move backards
			--lib.startCorner()
			row = row + lib.placeRetainingWall(R.length)
			lib.backTurn(1)
			if lib.placeDam(R.length) then
				waterPresent = true
			end
			row = row + 1
			-- left side wall has been built, 2 rows of walls laid. row = 2
			while row < R.width - 1 do -- eg width=2, row=2, this will not run. width=5, row=2
				lib.frontTurn()
				lib.removeDam(R.length)
				lib.backTurn(2)
				if lib.placeDam(R.length) then
					waterPresent = true
				end
				row = row + 1
			end
			-- lay right wall
			lib.frontTurn()
			lib.removeDam(R.length)
			lib.backTurn(2)
			row = row + lib.placeRetainingWall(R.length)
			lib.frontTurn()
			lib.removeDam(R.length) -- faces to front on finish
			T:go("L1F1R1")
			lib.removeDam(R.length) -- faces to front on finish
			depth = depth + 3
			T:go("L1F"..R.width - 1 .."R1D1")
			if depth == R.height or not waterPresent then -- still replacing water
				T:up(depth - 1) -- when h == R.height will go up
				break -- in case water dries up before loop has completed
			end
		end
	end
	return {}
end

function utils.dropSand()
	while not turtle.detectDown() do -- over water. will be infinite loop if out of sand
		if not T:place("sand", -1, "down", false) then
			print("Out of sand. Add more to continue...")
			sleep(2)
		end
	end
	return true --will only get to this point if turtle.detectDown() = true
end

function utils.startWaterFunction(inWater, onWater, maxDescent, goIn)
	--[[
		Use with utils.getWaterStatus
		could be inWater and not onWater if on single layer of water with floor below
	]]
	maxDescent = maxDescent or 1 -- prevents continuous down due to lack of water
	if goIn == nil then	-- turtle should submerge
		goIn = true
	end
	local descent = 0 -- counter for going down
	if inWater then -- job done
		return inWater, onWater
	end
	if onWater and goIn then --inWater already returned so must be false
		if turtle.down() then
			if T:getBlockType("forward"):find("water") ~= nil or T:getBlockType("forward"):find("bubble") ~= nil then
				inWater = true
				return inWater, onWater
			end
		end
	end
	if not onWater then
		T:forward(1)
	end
	-- should now be above water, but may be further down so onWater still false
	while T:getBlockType("down"):find("water") == nil and T:getBlockType("down"):find("bubble") == nil do-- go down until water below
		if turtle.down() then
			descent = descent + 1
			if descent >= maxDescent then -- limit descent in case no water present
				onWater = false
				return inWater, onWater -- false,false
			end
		else
			onWater = false
			return inWater, onWater -- false,false
		end
	end
	-- now above water
	if goIn then
		turtle.down() -- now inside water block
		inWater = true
	end
	return inWater, onWater
end

function utils.fillBucket(direction)
	if T:place("minecraft:bucket", -1, direction, true) then
		sleep(0.3)
		return true
	else
		return false
	end
end

function utils.getEmptyBucketCount()
	local lastSlot, leastModifier, total, slotData = T:getItemSlot("minecraft:bucket", -1)
	return total
end

function utils.getWaterBucketCount()
	-- lastSlot, leastModifier, total, slotData  = T:getItemSlot(item, useDamage)
	local lastSlot, leastModifier, total, slotData = T:getItemSlot("minecraft:water_bucket", -1)
	return total
end

function utils.getWaterStatus()
	--[[ Usage:
	local inWater, onWater = utils.getWaterStatus() -- returns turtle position near water
	utils.startWaterFunction(onWater, inWater, 2, true) -- move INTO water max 2 blocks down
	utils.startWaterFunction(onWater, inWater, 5, false) -- move ABOVE water max 5 blocks down
	]]
	local onWater = false
	local inWater = false
	for i = 1, 4 do
		if T:getBlockType("forward"):find("water") ~= nil  or T:getBlockType("forward"):find("bubble") ~= nil then
			inWater = true
		end
		T:turnRight(1)
	end
	if T:getBlockType("down"):find("water") ~= nil or T:getBlockType("down"):find("bubble") ~= nil then
		onWater = true
	end
	return inWater, onWater
end

function utils.getSize(clear, prompt, lowerLimit, upperLimit, default)
	local retValue = bedrock - 1
	while tonumber(retValue) < lowerLimit or  tonumber(retValue) > upperLimit do
		if clear then
			T:clear()
		end
		if type(prompt) == "table" then
			for i = 1, #prompt do
				if i < #prompt then
					print(prompt[i])
				else
					if prompt[i]:find(": ") == nil then
						prompt[i] = prompt[i]..": "
					end
					term.write(prompt[i])
				end
			end
		else
			if prompt:find(": ") == nil then
				prompt = prompt..": "
			end
			term.write(prompt)
		end
		retValue = read()
		if tonumber(retValue) == nil then -- eg enter or non-numeric input
			if default ~= nil then
				retValue = default
			else
				retValue = 0
			end
		end
		clear = true
	end
	return tonumber(retValue)
end

function utils.goBack()
	local success = true
	if not turtle.back() then
		success = false
		T:go("R2F1R2")
	end
	
	return success
end

local function attack(onPerch) -- 47
	local totalHitsF = 0
	local totalHitsU = 0
	local totalHitsD = 0
	if onPerch then
		turtle.digUp()
	end
	while true do
		local hitF = false
		local hitU = false
		local hitD = false
		if turtle.attackUp() then
			hitU = true
			totalHitsU = totalHitsU + 1
		end
		if onPerch then
			turtle.turnRight()
		else
			if turtle.attackDown() then
				hitD = true
				totalHitsD = totalHitsD + 1
			end
			if turtle.attack() then
				hitF = true
				totalHitsF = totalHitsF + 1
			end
		end
		if hitF or hitU or hitD then
			print("hits forward: "..totalHitsF..", up: "..totalHitsU..", down: "..totalHitsD)
		end
	end
end

local function clearAndReplantTrees() -- 27
	--[[ clear all trees in a rectangle area defined by walls, fences or non-dirt blocks
	replant with same type of sapling. If original tree 2 blocks wide, replant 4 if possible. ]]
	
	local lib = {}
	
	function lib.getSaplingFromLogType(log)
		--[[ get type of sapling to plant from log type ]]
		if log:find("oak") ~= nil then
			return "minecraft:oak_sapling"
		elseif log:find("spruce") ~= nil then
			return "minecraft:spruce_sapling"
		elseif log:find("birch") ~= nil then
			return "minecraft:birch_sapling"
		elseif log:find("jungle") ~= nil then
			return "minecraft:jungle_sapling"
		elseif log:find("acacia") ~= nil then
			return "minecraft:acacia_sapling"
		elseif log:find("dark_oak") ~= nil then
			return "minecraft:dark_oak_sapling"
		end
		return "sapling"
	end
	
	function lib.plantSapling(sapling, double)
		--[[ plant sapling(s) ]]
		if sapling == "" or sapling == nil then sapling = "sapling" end
		T:up(1)
		lib.suck()
		if double then	-- check if enough saplings
			--slotData.lastSlot, slotData.leastModifier, total, slotData = T:getItemSlot(sapling, -1)
			local a, b, total, _ = T:getItemSlot(sapling, -1)
			if total >= 4 then
				for i = 1, 4 do
					T:place(sapling, -1, "down")
					T:go("F1R1")
				end
				T:forward(1)		-- above pre-planted sapling
			else
				if not T:place(sapling, -1, "down") then
					T:place("sapling", -1, "down")
				end
			end
		else
			if not T:place(sapling, -1, "down") then
				T:place("sapling", -1, "down")
			end
		end
		turtle.select(1)
	end
		
	function lib.suck()
		--[[ Collect saplings, sticks and apples ]]
		turtle.select(1)
		turtle.suck()
		turtle.suckUp()
		turtle.suckDown()
	end
	
	function lib.turn(direction)
		--[[ change direction and return new value for direction ]]
		if direction == "r" then
			T:turnRight(1)
			direction = "l"
		else
			T:turnLeft(1)
			direction = "r"
		end
		return direction	-- will only change direction variable if return value is used
	end
	
	function lib.emptyInventory(blockTypeD)
		--[[ Empty all except 32 of each sapling and 1 chest ]]
		if blockTypeD == nil then
			blockTypeD = T:getBlockType("down")
		end
		if blockTypeD:find("chest") ~= nil or blockTypeD:find("barrel") ~= nil then
			-- empty logs, apples, sticks and all but 1 stack of each sapling type
			T:emptyInventorySelection("down", {"chest", "oak_sapling", "birch_sapling", "spruce_sapling", "acacia_sapling", "jungle_sapling","dark_oak_sapling"},{1, 32, 32, 32, 32, 32, 32})
			return true
		else
			return false
		end
	end
	
	function lib.moveDown(blockTypeD)
		--[[ move down until hit ground. Break leaves and continue ]]
		if blockTypeD == nil then
			blockTypeD = T:getBlockType("down")
		end
		while blockTypeD == "" or blockTypeD:find("leaves") ~= nil do	-- move down, breaking leavse
			T:down(1)
			lib.suck()
			blockTypeD = T:getBlockType("down")
		end
		return blockTypeD
	end
	
	function lib.moveForward()
		--[[ Move forward 1 block only, go down to ground while air or leaves below ]]
		local blockTypeF = T:getBlockType("forward")
		local blockTypeD = T:getBlockType("down")
		if blockTypeF == "" or blockTypeF:find("leaves") ~= nil then	-- air or leaves ahead
			T:forward(1)												-- move forward, breaking leaves
			T:dig("up")													-- remove leaves / low branches above to allow space for player
			lib.suck()
			blockTypeD = lib.moveDown()
			if not lib.emptyInventory(blockTypeD) then					-- check if above a corner chest / barrel
				if lib.isBorder(blockTypeD) then						-- not above chest so check if above border
					return false, blockTypeD							-- above a border block so stop
				end
			end
			blockTypeF = T:getBlockType("forward")
			return true, blockTypeF										-- moved ok, could be air or block in front
		end
		return false, blockTypeF 										-- did not move, obstacle in front NOT leaves or air
	end
	
	function lib.moveUp(blockTypeF)
		--[[ Move up until air in front (dig leaves / harvest tree) ]]
		if blockTypeF == nil then
			blockTypeF = T:getBlockType("forward")
		end
		while blockTypeF:find("dirt") ~= nil or
			  blockTypeF:find("grass_block") ~= nil or
			  T:isVegetation(blockTypeF) do	-- go up while dirt, grass-block or any vegetation in front
			T:up(1)
			blockTypeF = T:getBlockType("forward")
			if blockTypeF:find("log") ~= nil then
				lib.harvestTree(blockTypeF)
				return T:getBlockType("forward")
			elseif blockTypeF:find("leaves") ~= nil then
				T:dig("forward")
				return ""
			end
		end
		return blockTypeF	-- should be "" (air) or any border block
	end
	
	function lib.harvestTree(blockTypeF)
		--[[ Fell tree, returns true if double size ]]
		-- clsTurtle.harvestTree(extend, craftChest, direction)
		local saplingType = lib.getSaplingFromLogType(blockTypeF)
		local double = T:harvestTree(false, false, "forward")	-- assume single tree, will auto-discover
		lib.plantSapling(saplingType, double)
	end
	
	function lib.safeMove()
		--[[ move forward until border reached. loop breaks at that point ]]
		local blockTypeF = ""
		local success = true
		while success do
			success, blockTypeF = lib.moveForward()				-- move forward 1 block, return block type ahead
			if not success then 								-- did not move forwards, block in the way: either log, dirt/grass, border block or vegetation
				if blockTypeF:find("log") then 					-- tree found
					lib.harvestTree(blockTypeF)
					success = true								-- block (log) removed, try again
				else
					success = not lib.isBorder(blockTypeF)		-- Is at border?: if is at border success = false so loop stops
					if success then								-- Not at border. Dirt/grass vegetation in front
						blockTypeF = lib.moveUp(blockTypeF)		-- move up until leaves/log/air
						success = not lib.isBorder(blockTypeF)	-- Is at border?: if is at border success = false so loop stops
						if success then							-- keep moving forward
							if blockTypeF:find("log") then 		-- tree found
								lib.harvestTree(blockTypeF)	
							end
																-- else blockTypeF is air/leaves  border has been checked
						end
					end
				end
			end													-- else success = true, 1 block moved so continue
		end
	end
	
	function lib.isBorder(blockType)
		--[[ Is the block log, dirt, grass_block, vegetation: non-border, or other:border]]
		if blockType == nil then 					-- not passed as parameter
			blockType = T:getBlockType("forward")
		end
		if blockType == "" then 					-- air ahead: not border
			return false, ""
		else										-- could be border or other
			if blockType:find("dirt") ~= nil or blockType:find("grass_block") ~= nil or blockType:find("log") ~= nil then -- either dirt, grass block or log
				return false, blockType				-- dirt, grass, log: not border
			end
			if T:isVegetation(blockType) then 		-- vegetation found: not border
				return false, blockType
			end
		end
		return true, blockType						-- dirt, grass_block, log and vegetation eliminated:must be border
	end
	
	function lib.inPosition()
		--[[ check if in lower left corner ]]
		local inPosition = true 		-- assume correct
		if not turtle.detectDown() then	-- hanging in mid-air
			return false
		end
		T:turnLeft(1)
		if lib.isBorder() then
			-- so far so good
			T:turnLeft(1)
			if not lib.isBorder() then 	-- not in correct place
				inPosition = false
			end
			T:turnRight(2) 				-- return to original position
		else
			inPosition = false
			T:turnRight(1) 				-- return to original position
		end
		return inPosition
	end
	
	function lib.findBorder()
		--[[ assume started after reset. if log above harvest tree else return to ground. Find starting corner]]
		local blockType = T:getBlockType("up")					-- dig any logs above, return to ground
		local log = "sapling"
		if blockType:find("log") ~= nil then					-- originally felling a tree so complete it
			log = lib.getSaplingFromLogType(blockType)
			local double = T:harvestTree(false, false, "up")	-- assume single tree, will auto-discover
			lib.plantSapling(log, double)
		else													-- no log above so go downm
			blockType = lib.moveDown()							-- return to ground (or vegetation)
		end
		lib.safeMove()											-- move forward until border reached
		T:turnRight(1)
		lib.safeMove()											-- move forward until second border reached
		T:turnRight(1)											-- should now be in correct position
		lib.emptyInventory()									-- empty inventory if above a chest
	end
	
	local direction = "r"
	local blockTypeF = ""
	local success = false
	if not lib.inPosition() then 
		lib.findBorder()
	end
	local secondBorderFound = false
	while not secondBorderFound do
		lib.safeMove()														-- moves forward until reaches border forward or below
		lib.turn(direction)													-- turn r or l. direction is not changed
		success, blockTypeF = lib.isBorder()								-- no blockType passed as parameter so will return current block in new forward direction
		if success then
			secondBorderFound = true										-- game over
		elseif blockTypeF:find("log") ~= nil then							-- tree in front
			lib.harvestTree(blockTypeF)
		elseif blockTypeF == "" or blockTypeF:find("leaves") ~= nil then	-- air or leaves in front
			T:forward(1)													-- move forward 1 block
			lib.moveDown()													-- go down if required
		elseif	blockTypeF:find("dirt") ~= nil or
				blockTypeF:find("grass_block") ~= nil or
				T:isVegetation(blockTypeF) then								-- dirt, grass_block or vegetation in front
			blockTypeF = lib.moveUp(blockTypeF)								-- move up until air or border ahead.
			if lib.isBorder(blockTypeF) then								-- border ahead
				secondBorderFound = true
			else															-- air ahead									
				T:forward(1)												-- move forward 1 block
			end
		end
		direction = lib.turn(direction)										-- turn r or l. direction is changed to opposite
	end
	lib.moveDown()															-- return to ground level
	lib.emptyInventory()
	return {}
end

local function clearArea(R, useDirt) -- 71
	if useDirt == nil then
		useDirt = true
	end
	local evenWidth = false
	local evenHeight = false
	local loopWidth
	-- go(path, useTorch, torchInterval, leaveExisting)
	if R.width % 2 == 0 then
		evenWidth = true
		loopWidth = R.width / 2
	else
		loopWidth = math.ceil(R.width / 2)
	end
	if R.length % 2 == 0 then
		evenHeight = true
	end
	turtle.select(1)
	-- clear an area between 2 x 4 and 32 x 32
	-- if R.width is even no, then complete the up/down run
	-- if R.width odd no then finish at top of up run and reverse
	-- should be on flat ground, check voids below, harvest trees
	for x = 1, loopWidth do
		-- Clear first column (up)
		for y = 1, R.length do
			if useDirt then
				if not turtle.detectDown() then
					T:place("minecraft:dirt", -1, "down", true)
				else --if not water, dirt, grass , stone then replace with dirt
					blockType, blockModifier = T:getBlockType("down")
					if blockType ~= "" then
						if blockType ~= "minecraft:dirt" and blockType ~= "minecraft:grass_block" then
							turtle.digDown()
							T:place("minecraft:dirt", -1, "down", true)
						end
					end
				end
			end
			if y < R.length then
				T:go("F1+1", false,0,false)
			end
		end
		-- clear second column (down)
		if x < loopWidth or (x == loopWidth and evenWidth) then -- go down if on R.width 2,4,6,8 etc
			T:go("R1F1+1R1", false,0,false)
			for y = 1, R.length do
				if useDirt then
					if not turtle.detectDown() then
						T:place("minecraft:dirt", -1, "down", true)
					else
						blockType, blockModifier = T:getBlockType("down")
						if blockType ~= "" then
							if blockType ~= "minecraft:dirt" and blockType ~= "minecraft:grass_block" then
								turtle.digDown()
								T:place("minecraft:dirt", -1, "down", true)
							end
						end
					end
				end
				if y < R.length then
					T:go("F1+1", false, 0, false)
				end
			end
			if x < loopWidth then 
				T:go("L1F1+1L1", false,0,false)
			else
				T:turnRight(1)
				T:forward(R.width - 1)
				T:turnRight(1)
			end
		else -- equals R.width but is 1,3,5,7 etc
			T:turnLeft(2) --turn round 180
			T:forward(R.length - 1)
			T:turnRight(1)
			T:forward(R.width - 1)
			T:turnRight(1)
		end
	end
	return {}
end

local function clearRectangle(R) -- 72
	--local function clearRectangle(width, length, up, down)
	-- height = 0: one level, 1 = +up, 2 = +down, 3 = +up/down
	local lib = {}
	function lib.UpDown(length)
		for l = 1, length do
			T:go("x0x2F1x0x2")
		end
	end
	
	function lib.Up(length)
		for l = 1, length do
			T:go("x0F1x0")
		end
	end
	
	function lib.Down(length)
		for l = 1, length do
			T:go("x2F1x2")
		end
	end
	
	function lib.Forward(length)
		T:forward(length)
	end
	
	-- could be 1 wide x xx R.length (trench) R.up and return
	-- could be 2+ x 2+
	-- even no of runs return after last run
	-- odd no of runs forward, back, forward, reverse and return
	turtle.select(1)
	if R.width == 1 then 					-- single block trench ahead only
		if R.up and R.down then				-- single block wide trench dig R.up and R.down = 3 blocks deep
			lib.UpDown(R.length - 1)
		elseif R.up then					-- single block wide trench dig R.up = 2 blocks deep
			lib.Up(R.length - 1)
		elseif R.down then				-- single block wide trench dig R.down = 2 blocks deep
			lib.Down(R.length - 1)
		else 							-- single block wide = 1 block deep
			lib.Forward(R.length - 1)
		end
		T:turnRight(2)					-- turn at the top of the run
		T:forward(R.length - 1)			-- return to start
		T:turnRight(2)					-- turn round to original position
	else 								-- R.width 2 or more blocks
		local iterations = 0 			-- R.width = 2, 4, 6, 8 etc
		if R.width % 2 == 1 then  		-- R.width = 3, 5, 7, 9 eg R.width 7
			iterations = (R.width - 1) / 2 -- iterations 1, 2, 3, 4 for widths 3, 5, 7, 9
		else
			iterations = R.width / 2		-- iterations 1, 2, 3, 4 for widths 2, 4, 6, 8
		end
		for i = 1, iterations do 		-- eg 3 blocks wide, iterations = 1
			if R.up and R.down then							-- dig R.up and R.down
				lib.UpDown(R.length - 1)
				T:go("x0x2R1F1x0x2R1x0x2")				-- turn round
				lib.UpDown(R.length - 1)
			elseif R.up then								-- dig R.up
				lib.Up(R.length - 1)
				T:go("x0R1F1x0R1x0")
				lib.Up(R.length - 1)
			elseif R.down then							-- dig R.down
				lib.Down(R.length - 1)
				T:go("x2R1F1x2R1x2")
				lib.Down(R.length - 1)
			else										-- no digging R.up or R.down
				lib.Forward(R.length - 1)
				T:go("R1F1R1")
				lib.Forward(R.length - 1)
			end
			-- if 1 less than end, reposition for next run
			if i < iterations then
				T:go("L1F1L1", false, 0, false)
			end
		end
		if R.width % 2 == 1 then  -- additional run and return to base needed
			T:go("L1F1L1", false, 0, false)
			if R.up and R.down then
				lib.UpDown(R.length - 1)
			elseif R.up then
				lib.Up(R.length - 1)
			elseif R.down then
				lib.Down(R.length - 1)
			else
				lib.Forward(R.length - 1)
			end
			T:turnRight(2)
			T:forward(R.length - 1)
		end
		T:go("R1F"..R.width - 1 .."R1", false, 0, false)
	end
	return {}
end

local function clearPerimeter(R) -- 74
	local lib = {}
	function lib.UpDown(length)
		for l = 1, length do
			T:go("x0x2F1x0x2")
		end
	end
	
	function lib.Up(length)
		for l = 1, length do
			T:go("x0F1x0")
		end
	end
	
	function lib.Down(length)
		for l = 1, length do
			T:go("x2F1x2")
		end
	end
	
	function lib.Forward(length)
		T:forward(length)
	end
	
	if R.up and R.down then
		for i = 1, 2 do
			lib.UpDown(R.length - 1)
			T:turnRight(1)
			lib.UpDown(R.width - 1)
			T:turnRight(1)
		end
	elseif R.up then
		for i = 1, 2 do
			lib.Up(R.length - 1)
			T:turnRight(1)
			lib.Up(R.width - 1)
			T:turnRight(1)
		end
	elseif R.down then
		for i = 1, 2 do
			lib.Down(R.length - 1)
			T:turnRight(1)
			lib.Down(R.width - 1)
			T:turnRight(1)
		end
	else
		for i = 1, 2 do
			lib.Forward(R.length - 1)
			T:turnRight(1)
			lib.Forward(R.width - 1)
			T:turnRight(1)
		end
	end
	return {}
end

local function clearBuilding(R, withCeiling, withFloor) -- 75
	--[[
	Clear the outer shell of a building, leaving inside untouched. Optional floor/ceiling removal
	clearBuilding(R, withCeiling, withFloor) -- R.subChoice is 0-'up' or 1-'down'
	]]
	local lib = {}
	
	function lib.detectPosition(direction)
		--[[
			If going up check if has block in front and above else forward 1
			If going down chech has block in front and below els go down 1
		]]
		if direction == "up" then
			if not turtle.detectUp() then -- no block above so must be in front of area to be cleared
				local response = menu.getBoolean("Am I outside clearing volume (y/n)?")
				if response then
					T:forward(1)
				end
			end
		else
			if not turtle.detect() then -- no block ahead so must be sitting on top
				local response = menu.getBoolean("Am I above clearing volume (y/n)?")
				if response then
					T:down(1)
				end
			end
		end
	end
	
	function lib.move(direction, blocks, reverse)
		if reverse == nil then
			reverse = false
		end
		if reverse then
			if direction == "down" then -- reverse direction
				T:up(blocks)
			else
				T:down(blocks)
			end
		else
			if direction == "up" then
				T:up(blocks)
			else
				T:down(blocks)
			end
		end
		return blocks
	end
	
	local remaining = R.height -- eg 5
	lib.detectPosition(R.data) -- moves down / forward if required

	if R.height <= 3 then --1-3 layers only
		if R.height == 1 then 			--one layer only
			R.up = false
			R.down = false
			if withFloor or withCeiling then	-- only one layer, so clearRectangle
				clearRectangle(R)
			else
				clearPerimeter(R)
			end
		elseif R.height == 2 then --2 layers only current + dig up/down
			if withFloor or withCeiling then
				R.up = withCeiling
				R.down = withFloor
				clearRectangle(R)
			else
				if R.data == "up" then
					R.up = true
					R.down = false
				else
					R.up = false
					R.down = true
				end
				clearPerimeter(R)
			end
		elseif R.height == 3 then --3 layers only current + dig up/down
			lib.move(R.data, 1)
			R.up = true
			R.down = true
			clearPerimeter(R)
		end
	else -- 4 or more levels
		while remaining > 3 do
			if remaining == R.height then-- first iteration
				R.up = false
				R.down = false
				if (R.data == "up" and withFloor) or (R.data == "down" and withCeiling) then
					clearRectangle(R)
				else -- just the perimeter
					clearPerimeter(R)
				end
				lib.move(R.data, 2)
			end
			remaining = remaining - 4 -- eg 1st of height = 5 : 1 remaining. 2nd iteration remaining = 1
			R.up = true
			R.down = true
			clearPerimeter(R)
		end
		if remaining == 3 then
			lib.move(R.data, 3)
			R.up = true
			R.down = true
			clearPerimeter(R)
			if (R.data == "up" and withCeiling) or (R.data == "down" and withFloor) then
				lib.move(R.data, 1)
				R.up = false
				R.down = false
				clearRectangle(R)
			end
		elseif remaining == 2 then
			if R.data == "up" then
				if withCeiling then
					lib.move(R.data, 2)
					R.up = true
					R.down = false
					clearPerimeter(R)
					lib.move(R.data, 1)
					R.up = false
					clearRectangle(R)
				else
					lib.move(R.data, 3)
					R.up = true
					R.down = false
					clearPerimeter(R)
				end
			else
				if withFloor then
					lib.move(R.data, 2)
					R.up = true
					R.down = false
					clearPerimeter(R)
					lib.move(R.data, 1)
					R.up = false
					clearRectangle(R)
				else
					lib.move(R.data, 3)
					R.up = true
					R.down = false
					clearPerimeter(R)
				end
			end
		elseif remaining == 1 then
			lib.move(R.data, 2)
			R.up = false
			R.down = false
			if (R.data == "up" and withCeiling) or (R.data == "down" and withFloor) then
				clearRectangle(R)
			else
				clearPerimeter(R)
			end
		end
	end
	
	lib.move(R.data, R.height - 1, true) -- reverse direction
	
	return {}
end

local function clearMineshaft(equippedRight, equippedLeft, inInventory) -- 16
	local lib = {}
	function lib.checkCobweb(direction, inInventory)
		if inInventory == "minecraft:diamond_sword" then -- using a sword
			local side = "left"
			local item = T:getBlockType(direction)
			if item == "minecraft:cobweb" then
				--clsTurtle.equip(self, side, useItem, useDamage)
				if equippedRight == "minecraft:diamond_pickaxe" then
					side = "right"
				end
				T:equip(side, "minecraft:diamond_sword")
				T:dig(direction)
				T:equip(side, "minecraft:diamond_pickaxe")
			else
				T:dig(direction)
			end
		else
			T:dig(direction)
		end
	end

	-- check position by rotating until facing away from wall
	length = 0
	torch = 0
	turns = 0
	while not turtle.detect() do
		T:turnRight(1)
		turns = turns + 1
		if turns > 4 then
			return {"I am not facing a wall. Unable to continue"}
		end
	end
	T:turnRight(2)
	-- move forward until obstructed, digging up/down. place torches
	while not turtle.detect() do
		lib.checkCobweb("up", inInventory) -- dig cobweb or any other block up
		lib.checkCobweb("down", inInventory) -- dig cobweb or any other block down
		length = length + 1
		torch = torch + 1
		if torch == 8 then
			torch = 0
			T:place("minecraft:torch", -1, "down", false) ---(self, blockType, damageNo, direction, leaveExisting, signText)
		end
		lib.checkCobweb("forward", inInventory) -- dig cobweb or any other block in front
		T:forward(1)
	end
	-- turn right, forward, right, return to start with up/down dig
	
	T:go("R1F1R1")
	for i = 1, length, 1 do
		lib.checkCobweb("up", inInventory) -- dig cobweb or any other block up
		lib.checkCobweb("down", inInventory) -- dig cobweb or any other block down
		lib.checkCobweb("forward", inInventory) -- dig cobweb or any other block in front
		T:forward(1)
	end
	-- move to other wall and repeat.
	T:go("R1F2R1")
	for i = 1, length, 1 do
		lib.checkCobweb("up", inInventory) -- dig cobweb or any other block up
		lib.checkCobweb("down", inInventory) -- dig cobweb or any other block down
		lib.checkCobweb("forward", inInventory) -- dig cobweb or any other block in front
		T:forward(1)
	end
	lib.checkCobweb("up", inInventory) -- dig cobweb or any other block up
	lib.checkCobweb("down", inInventory) -- dig cobweb or any other block down
	
	return {}
end

local function clearMonumentLayer(R) -- 85
	R.up = true
	R.down = true
	R.silent = true
	if R.subChoice == 0 then
		R.up = false
		R.down = false
	end
	-- send turtle down until it hits bottom
	-- then clear rectangle of given size
	-- start above water, usually on cobble scaffold above monument
	if T:detect("down") then -- in case not over wall
		T:forward(1)
	end
	local height = 1
	-- go down until solid block detected
	while utils.clearVegetation("down") do
		T:down(1)
		height = height + 1
	end
	T:down(1)
	height = height + 1
	clearRectangle(R)
	T:up(height - 1)
	
	return {}
end

local function clearWaterPlants(R) -- 87
	local lib = {}
	
	function lib.getLength()
		local length = 1
		print("Checking water length")
		while utils.clearVegetation("forward") do
			T:forward(1)
			length = length + 1
		end
		for i = 1, length do
			turtle.back()
		end
		return length
	end
	
	function lib.clearDown(D)
		while utils.clearVegetation("down") do
			T:down(1)
			D.depth = D.depth + 1
		end
		-- if slab at bottom, replace with solid block
		D.blockType = T:getBlockType("down")
		if D.blockType:find("slab") ~= nil then
			T:go("C2")
		end
		if D.depth > D.maxDepth then
			D.maxDepth = D.depth
		end
		
		return D
	end
	
	function lib.clearLength(D)
		local moves = 0
		local blockHeight = 1
		D.floorLength = 0 -- reset
		while moves < D.length - 1 do
			if utils.clearVegetation("forward") then
				T:forward(1)
				moves = moves + 1 
				if turtle.detectUp() then -- could be on monument going under arch, or faulty monument floor
					if not D.monumentArchesClear then
						D = lib.checkArches(D)
					end
				end
				local temp = D.depth
				D = lib.clearDown(D) -- go down if in water/air
				if blockHeight == 4 and D.depth - temp == 3 then -- could be just gone over 3 block high column in ocean monument
					if not D.monumentTopClear then
						D = lib.checkTop(D)
					end
					blockHeight = 1
				end
				if D.useBlockType == "prismarine" then
					if D.blockType:find("prismarine") == nil then
						-- on monument floor so restrict forward movement to 8 blocks
						D.floorLength = D.floorLength + 1
						if D.floorLength == 8 then
							D.blockType = T:getBlockType("forward")
							while D.blockType:find("prismarine") == nil do
								T:up(1)
								D.blockType = T:getBlockType("forward")
							end
							D.floorLength = 0
						end
					end
				end
				if moves >= D.length - 1 then
					return D
				end
			else -- block in front
				blockHeight = 1
				local waterAbove = utils.clearVegetation("up")
				local waterAhead = utils.clearVegetation("forward") -- true if air/water in front
				while not waterAhead do 	-- solid block in front
					if waterAbove then 		-- move up
						T:up(1)
						D.depth = D.depth - 1
						blockHeight = blockHeight + 1
						if D.depth < 1 then
							return D
						end
					else 					-- block above so go back
						while not waterAbove do
							utils.goBack()	--  returns true if no object behind, but moves anyway
							waterAbove = utils.clearVegetation("up")
							moves = moves - 1
						end
					end
					waterAbove = utils.clearVegetation("up")
					waterAhead = utils.clearVegetation("forward")
				end
			end
		end
		D.width = D.width + 1	-- another length completed so increase width
		D.maxDepth = D.maxDepth + 1 -- +1 to allow for starting pos in top layer
		
		return D 
	end
	
	function lib.checkArches(D)
		-- gone under a block so could be monument arch (6)
		if T:getBlockType("up"):find("prismarine") ~= nil then -- confirm on monument, not previously cleared
			local direction = "" 	-- initialise direction
			T:go("B1U2F1R1")
			if T:getBlockType("forward"):find("prismarine") ~= nil then -- correct guess
				direction = "R"
			else	-- wrong direction. turn round and check other side
				T:go("R2")
				if T:getBlockType("forward"):find("prismarine") ~= nil then
					direction = "L"
				end
			end
			local path = "U1F1 U1F3 D1F1 D1R2 U2F5 D2"
			--for i = 1, 6 do
			T:go(path) -- clears arch top 1 and returns
			T:go(direction.."1F6"..direction.."1")
			T:go(path) -- clears arch top 2 and returns
			T:go(direction.."1F6"..direction.."1")
			T:go(path) -- clears arch top 3 and returns
			T:go(direction.."1F9"..direction.."1")
			T:go(path) -- clears arch top 4 and returns
			T:go(direction.."1F6"..direction.."1")
			T:go(path) -- clears arch top 5 and returns
			T:go(direction.."1F6"..direction.."1")
			T:go(path) -- clears arch top 6 and returns
			
			T:go(direction.."3F34"..direction.."2D2F1")
			D.monumentArchesClear =  true
		end
		return D
	end
	
	function lib.checkTop(D)
		-- gone over 3 block column so could be at the top of ocean monument
		if T:getBlockType("down"):find("prismarine") ~= nil then -- confirm on monument, not previously cleared
			local direction = "" 	-- initialise direction
			T:go("U3R1")			-- up to top of column and try right side
			if T:getBlockType("forward"):find("prismarine") ~= nil then -- correct guess
				direction = "L"
			else	-- wrong direction. turn round and check other side
				T:go("R2")
				if T:getBlockType("forward"):find("prismarine") ~= nil then
					direction = "R"
				end
			end
			if direction ~= "" then -- facing single block on layer 2
				T:go("U1F6"..direction.."1F5".. direction.."1F5"..direction.."1F5"..direction.."1") -- clear 4 single blocks
				T:go("F1U1"..direction.."1F1"..direction.."3") -- on top of monument
				T:go("F3".. direction.."1F3"..direction.."1F3"..direction.."1F3"..direction.."3") -- clear top, face return
				T:go("F2D5"..direction.."3B1")
			end
			D.monumentTopClear = true
		end
		return D
	end
	
	function lib.findBlockTypeEnd(D)
		D.blockType = "" -- reset
		repeat
			if utils.clearVegetation("forward") then
				T:forward(1)
				D = lib.clearDown(D) -- go down if in water/air, D.blockType is updated with floor type
			else -- block in front
				local waterAbove = utils.clearVegetation("up")
				local waterAhead = utils.clearVegetation("forward") -- true if air/water in front
				while not waterAhead do 	-- solid block in front
					if waterAbove then 		-- move up
						T:up(1)
					else 					-- block above so go back
						while not waterAbove do
							utils.goBack()	--  returns true if no object behind, but moves anyway
							waterAbove = utils.clearVegetation("up")
						end
					end
					waterAbove = utils.clearVegetation("up")
					waterAhead = utils.clearVegetation("forward")
				end
			end
		until D.blockType:find(D.useBlockType) == nil
		-- now above a non-prismarine block, facing away from monument
		T:turnRight(2) -- facing monument
		D.blockType = T:getBlockType("forward")
		while D.blockType:find(D.useBlockType) ~= nil do
			T:up(1)
			D.blockType = T:getBlockType("forward")
		end
		T:go("F1L1")
		D.blockType = T:getBlockType("down")
		while D.blockType:find(D.useBlockType) ~= nil do
			T:forward(1)
			D.blockType = T:getBlockType("down")
		end
		turtle.back()
		-- should now be at end of monument base
	end
	
	function lib.turn(D)
		local direction = "R"
		if not D.facingForward then
			direction = "L"
		end
		T:go(direction.. 1)
		if utils.clearVegetation("forward") then
			T:forward(1)
			--D.depth = D.depth + lib.clearDown(depth)
			D = lib.clearDown(D)
		else
			while not utils.clearVegetation("forward") do
				T:up(1)
				D.depth = D.depth - 1
			end
		end
		T:go(direction.. 1)
		D.facingForward = not D.facingForward 
		
		return D
	end

	local D = {}
	D.depth = 0
	D.maxDepth = 0
	D.blockType = ""
	D.useBlockType = R.useBlockType -- "" or "prismarine"
	D.length = 0	-- copy of R.length used in lib.clearLength
	D.width = 0		-- increased every 
	D.facingForward = true
	D.monumentTopClear = false
	D.monumentArchesClear = false
	D.inWater = false
	D.onWater = false
	D.inWater, D.onWater = utils.getWaterStatus()
	D.floorLength = 0 -- used on monument floor
	
	if R.data == "clearWaterPlants" then -- NOT monument corner discovery
		D.inWater, D.onWater = utils.startWaterFunction(D.onWater, D.inWater, 2, true) -- move into water
		if R.length == 0 then
			R.length = lib.getLength()
		end
		if R.width == 0 then
			T:turnRight(1)
			R.width = lib.getLength()
			T:turnLeft(1)
		end
	end
	
	D.length = R.length
	D = lib.clearDown(D) -- go down to floor, set depth, maxDepth, blockType
	if R.data == "clearWaterPlants" then -- NOT monument corner discovery
		while D.width < R.width do -- D.width starts at 0
			-- now on floor, move along sea/river bed following contour
			D = lib.clearLength(D) --D.width also increased
			-- now turn and repeat
			if D.width < R.width then	
				D = lib.turn(D)
			end
		end
		-- finished so return to surface
		T:up(1) -- up 1 to check for water below
		while T:isWater("down") do
			T:up(1)
		end
		T:down(1) -- return to surface
	elseif R.data == "oceanMonumentColumns" then -- monument corner discovery
		-- this function used to find edge of monument base
		if D.blockType:find(D.useBlockType) ~= nil then
			lib.findBlockTypeEnd(D)
			return ""
		else
			T:up(D.depth)
			return "Prismarine not found on ocean floor"
		end
	end
	if R.silent then
		return {D.maxDepth}
	else
		return {""}
	end
end

local function clearMountainSide(R) -- 78
	local lib = {}
	
	function lib.excavate(blocksFromOrigin, going, length, digDown)
		local firstUp = 0
		for i = 1, length do
			-- record first block dug above
			if turtle.digUp() then
				if firstUp == 0 then
					firstUp = i -- will record first successful dig up
				end
			end
			if digDown then
				turtle.digDown()
			end
			T:forward(1)
			if going then
				blocksFromOrigin = blocksFromOrigin + 1
			else
				blocksFromOrigin = blocksFromOrigin - 1
			end
		end
		
		return blocksFromOrigin, firstUp
	end
	
	function lib.cutSection(blocksFromOrigin, going, length, firstUp)
		local height = 0
		local digDown = false
		blocksFromOrigin, firstUp = lib.excavate(blocksFromOrigin, going, length, digDown)
		-- while at least 1 block dug above do
		while firstUp > 0 do
			if digDown then
				turtle.digDown()
			else
				digDown = true
			end
			T:go("R2U1x1U1x1U1x1x0") -- go up 3 turn round
			going = not going
			height = height + 3
			if firstUp > 1 then
				length = length - firstUp + 1
			end
			-- go forward R.length digging up/down
			blocksFromOrigin, firstUp = lib.excavate(blocksFromOrigin, going, length,  true)
		end
		T:down(height)
		
		return blocksFromOrigin, going
	end
	
	local originalLength = R.length
	local going = true
	local firstUp = 0
	local blocksFromOrigin = 0
	--T:forward(1) -- get into position
	blocksFromOrigin, going = lib.cutSection(blocksFromOrigin, going, R.length, firstUp)
	if R.width > 1 then --move left/right and repeat
		for i = 2, R.width do
			if going then
				T:turnRight(2)			
			end
			if blocksFromOrigin > 0 then
				T:forward(blocksFromOrigin)
			end
			T:turnRight(2)
			blocksFromOrigin = 0
			if R.subChoice == 0 then --Left <- Right
				T:go("L1F1R1")
			else
				T:go("R1F1L1")
			end
			going = true
			blocksFromOrigin, going = lib.cutSection(blocksFromOrigin, going, R.length, firstUp)
		end
	end
	return {}
end

local function clearSandWall(R) -- 81
	--dig down while on top of sand/red_sand/soul_sand
	local lib = {}
	
	function lib.checkAbove(height)
		if turtle.detectUp() then -- moved under a ledge
			T:go("B1U1")
			height = height - 1
		end
		return height
	end
	
	function lib.moveDown(height)
		blockType = T:getBlockType("down")
		while blockType:find("sand") ~= nil do
			T:down(1)
			height = height + 1
			blockType = T:getBlockType("down")
		end
		return height
	end
	
	function lib.moveForward(length)
		lib.digForward()
		T:forward(1)
		length = length + 1
		local blockType = T:getBlockType("forward")
		return length, blockType
	end
	
	
	function lib.digForward()
		while T:dig("forward") do
			while T:suck("forward") do end
			while T:suck("up") do end
		end
	end
	
	local height = 0
	local length = 0
	local search = 0
	local reverse = false
	local blockType = T:getBlockType("down")
	
	print("Checking for sand below")
	while blockType:find("sand") == nil do --move forward until sand detected or 3 moves
		T:forward(1)
		search = search + 1
		blockType = T:getBlockType("down")
		if search > 3 then
			T:go("B"..search)
			return {"Unable to locate sand"}
		end
	end
	-- must be sand below
	height = lib.moveDown(height)	-- go down if sand below
	-- repeat until height == 0
	repeat -- starts at bottom of sand wall
		blockType = T:getBlockType("forward")
		if blockType:find("sand") ~= nil then -- sand in front
			length, blockType = lib.moveForward(length) -- move forward 1 and dig sand
			if blockType == "" or  blockType:find("sand") ~= nil then -- sand or nothing in front
				height = lib.moveDown(height)	-- go down if sand below
			end
		else -- solid block, air or water, not sand so move up
			if turtle.detect() then -- block in front
				T:up(1)
				height = height - 1
			else -- air/water in front so move forward
				if length < 60 then -- in case missing wall and in open ocean
					length, blockType = lib.moveForward(length) -- move forward 1 and dig sand
					height = lib.checkAbove(height)
				else -- already > monument length of 56
					T:up(1)
					height = height - 1
				end
			end
		end
	until height == 0
	-- stay at end of cleared wall unless user chose to return
	if R.data == "return" then
		T:go("R2F"..length.."R2")
	end
	
	return {}
end

local function clearSolid(R) -- 76
	--[[ direction = R.data = "up" or "down"
	Assume if going up T is inside the area
	If going down T is on top of the area ready to go
	ex1 hollow a cube top to bottom 20 wide, 20 long, 18 deep
	]]
	
	local lib = {}
	
	function lib.detectPosition(direction)
		--[[
			If going up check if has block in front AND above else forward 1
			If going down chech has block in front AND below else go down 1
		]]
		if direction == "up" then
			if not turtle.detectUp() then -- no block above so must be in front of area to be cleared
				local response = menu.getBoolean("Am I outside clearing area (y/n)?")
				if response then
					T:forward(1)
				end
			end
		else
			if not turtle.detect() then -- no block ahead so must be sitting on top
				local response = menu.getBoolean("Am I above clearing area (y/n)?")
				if response then
					T:down(1)
				end
			end
		end
	end
	
	function lib.move(direction, blocks, reverse)
		--[[ Move up or down by blocks count ]]
		if reverse == nil then
			reverse = false
		end
		if reverse then
			if direction == "down" then -- reverse direction
				T:up(blocks)
			else
				T:down(blocks)
			end
		else
			if direction == "up" then
				T:up(blocks)
			else
				T:down(blocks)
			end
		end
		return blocks
	end
	
	function lib.reset(R)
		R.up = false
		R.down = false
		return R
	end
	
	function lib.set(R)
		R.up = true
		R.down = true
		return R
	end
		
	local remaining = R.height -- eg 5
	if not R.silent then	-- normal mode, not being called from another function
		lib.detectPosition(R.data)
	end
	if R.height <= 0 then -- user entered -1 or 0:move up until no more solid
		-- starts on level 1
		R = lib.set(R)
		lib.move(R.data, 1)
		local itemsOnBoard = T:getTotalItemCount()
		repeat
			clearRectangle(R) -- up and or down preset by R.up and R.down
			T:sortInventory()
			lib.move(R.data, 3)
			R.height = R.height + 3
		until T:getFirstEmptySlot() == 0  or T:getTotalItemCount() == itemsOnBoard-- nothing collected or full inventory
	elseif R.height <= 3 then --1-3 layers only
		R = lib.reset(R)					-- not digging up or down (default for R.height = 1)
		if R.height == 2 then				-- dig up or down as well
			if R.data == "up" then
				R.up = true
			elseif R.data == "down" then
				R.down = true
			end
		elseif R.height == 3 then 			--3 layers only current + dig up/down
			lib.move(R.data, 1)
			R = lib.set(R)
			remaining = 2 -- allows movement back up/down to start position
		end
		
		clearRectangle(R) -- up and or down preset by R.up and R.down
	else -- 4 or more levels
		while remaining > 3 do
			R = lib.set(R)
			if remaining == R.height then	-- first iteration
				lib.move(R.data, 1)			-- move up / down 1 block
			else
				lib.move(R.data, 3)			-- move up / down 3 blocks
			end
			remaining = remaining - 3 -- eg 1st of height = 5 : 4 remaining. 2nd iteration remaining = 1
			clearRectangle(R) -- up and or down preset by R.up and R.down
		end
		if remaining == 3 then
			R = lib.set(R)
			lib.move(R.data, 2)
		elseif remaining == 2 then
			lib.move(R.data, 2)
			R = lib.reset(R)
			if R.data == "up" then -- going up
				R.up = true
			else -- going down
				R.down = true
			end
		elseif remaining == 1 then
			lib.move(R.data, 2)
			R = lib.reset(R)
		end
		clearRectangle(R) -- up and or down preset by R.up and R.down
	end
	lib.move(R.data, R.height - remaining, true) -- reverse R.data
	
	return {}
end

local function clearSandCube(R) -- 81
	--go down to bottom of sand
	turtle.select(1)
	while T:getBlockType("down") == "minecraft:sand" do
		T:down(1)
	end
	clearSolid(R)
end

local function clearWall(R) -- 73
	local lib = {}
	
	function lib.detectPosition(direction)
		--[[
			If going up check if has block in front AND above else forward 1
			If going down chech has block in front AND below else go down 1
		]]
		if direction == "up" then
			if not turtle.detectUp() then -- no block above so must be in front of area to be cleared
				local response = menu.getBoolean("Am I outside clearing area (y/n)?")
				if response then
					T:forward(1)
				end
			end
		else
			if not turtle.detect() then -- no block ahead so must be sitting on top
				local response = menu.getBoolean("Am I above clearing area (y/n)?")
				if response then
					T:down(1)
				end
			end
		end
	end
	
	function lib.move(direction, blocks, reverse)
		--[[ Move up or down by blocks count ]]
		if reverse == nil then
			reverse = false
		end
		if reverse then
			if direction == "down" then -- reverse direction
				T:up(blocks)
			else
				T:down(blocks)
			end
		else
			if direction == "up" then
				T:up(blocks)
			else
				T:down(blocks)
			end
		end
		return blocks
	end
	
	function lib.singleLayer(length)
		T:go("F"..length - 1)
	end
	
	function lib.doubleLayer(modifier, length)
		for i = 1, length do
			if i < length then
				T:go("x"..modifier.."F1")
			else
				T:go("x"..modifier)
			end
		end
	end
	
	function lib.tripleLayer(direction, length)
		for i = 1, length do
			if i < length then
				T:go("x0x2F1")
			else
				T:go("x0x2")
			end
		end
	end
	
	
	-- R.width preset to 1
	-- R.data = "up" or "down"
	lib.detectPosition(R.data)
	-- dig along and up/down for specified R.length
	local modifier = "0"
	local direction = "U"
	local outbound = true
	local moved = 0
	if R.data == "down" then
		 modifier = "2"
		 direction = "D"
	end
	if R.height == 1 then -- single block so dig and return
		lib.singleLayer(R.length)
	elseif R.height == 2 then
		lib.doubleLayer(modifier, R.length)
	elseif R.height == 3 then
		T:go(direction.."1")
		lib.tripleLayer(direction, R.length)
		moved = 1
	else
		-- 4 blocks or more. start with bulk 3 blocks
		local remaining = R.height
		local start = true
		while remaining >= 3 do 
			if start then
				T:go(direction.."1")
				moved = moved + 1
				start = false
			else
				T:go(direction.."3")
				moved = moved + 3
			end
			for i = 1, R.length do
				if i < R.length then
					T:go("x0x2F1")
				else
					T:go("x0x2")
				end
			end
			T:go("R2")
			outbound = not outbound
			remaining = remaining - 3
		end
		-- 0, 1 or 2 layers left
		if remaining == 1 then
			T:go(direction.."2")
			moved = moved + 2
			lib.singleLayer(R.length)
			--outbound = not outbound
		elseif remaining == 2 then
			T:go(direction.."2")
			moved = moved + 2
			lib.doubleLayer(modifier, R.length)
			--outbound = not outbound
		end
	end
	if outbound then
		T:go("R2F"..R.length)
	end
	direction = "D" -- reverse direction
	if R.data == "down" then
		 direction = "U"
	end
	T:go(direction..moved.."R2")
	
	return {}
end

local function convertWater(R) -- 88
	--[[
	if dry need enough buckets to place along (width + length - 1) / 2
	use 12 buckets
	start on floor + 1
	place slab down and water up along 2 edges. stay on this level
	return round same 2 edges removing slabs and and placing them 1 above
	placeUp water onto slabs on both edges
	repeat recover slabs, place 1 above , placeUp water
	
	for sloping water, place full area with slabs
	place sloping water on top of slabs
	remove slabs
	
	]]
	local lib = {}
	
	function lib.checkStartPosition()
		--[[
		0 T             -- T=turtle, W=wall, S=source, F=flowing
		1 W|S|F|F|F|F|F -- sloping flowing water
		2 W|F|F|F|F|F|F -- blocks removed after placing flowing water above
		3 W|S|S|S|S|S|S -- original sources
		4 W|?|?|?|?|?|? -- may be sources
		]]
		-- need to be on floor or R.height if specified
		local depth = 0
		local blockType = T:getBlockType("down")
		local isWaterUp, isSourceUp = T:isWater("up")
		local isWaterForward, isSourceForward = T:isWater("forward")
		local isWaterDown, isSourceDown = T:isWater("down")
		print("Block below is "..blockType)
		print("Water above is "..tostring(isWaterUp))
		print("Water forward is "..tostring(isWaterForward))
		print("Water below is "..tostring(isWaterDown))
		if blockType:find("water") == nil then -- on at least level 0
			print("Moving forward in 2 seconds...")
			sleep(2)
			T:forward(1)
			blockType = T:getBlockType("down")
			if blockType:find("water") ~= nil then
				print("Water found. Going down to floor")
				depth = -1
			else
				T:down(1)
				blockType = T:getBlockType("down")
				if blockType:find("water") ~= nil then
					depth = -2
				else
					return 0, "Not close to water. Aborting..."
				end
			end
		end
		while turtle.down() do
			depth = depth + 1
		end
		local emptyBuckets = utils.getEmptyBucketCount()
		for i = depth, 0, -1 do
			if emptyBuckets > 0 then
				lib.fillBuckets()
				emptyBuckets = utils.getEmptyBucketCount()
			end
			turtle.up()
		end
		
		return depth, ""
	end
	
	function lib.fillBuckets()
		local emptyBuckets = utils.getEmptyBucketCount()
		local direction = "forward"-- start with forward
		local isWater, isSource, isIce = T:isWater(direction)
		if emptyBuckets > 0 then
			if not isSource then
				direction = "down"
				isWater, isSource, isIce = T:isWater(direction)
				if not isSource then
					direction = "up"
					isWater, isSource, isIce = T:isWater(direction)
					if not isSource then
						direction = ""
					end
				end
			end
			if direction == "" then
				print("Unable to locate water source")
			else
				for i = 1, emptyBuckets do
					if utils.fillBucket(direction) then
						print("Bucket filled "..direction)
						sleep(0.3)
					else
						print("Unable to fill bucket ".. i .." / "..emptyBuckets)
					end
				end
			end
		end
		return utils.getWaterBucketCount()
	end
	
	function lib.placeSlabs(length)
		for i = 1, length do
			T:place("slab", -1, "down", false)
			if i < length then
				T:forward(1)
			end
		end
	end
	
	function lib.placeSources(length, place)
		local moves = 1
		local waterBuckets = utils.getWaterBucketCount()
		-- place sources alternate positions + start and finish
		while moves < length do
			if place then
				if T:place("minecraft:water_bucket", -1, "up") then
					print("Placed source up")
					waterBuckets = waterBuckets - 1
				end
			end
			place = not place
			if moves < length then
				T:forward(1)
				moves = moves + 1
			end
			if waterBuckets == 0 then
				T:down(1) -- break the slab below
				waterBuckets = lib.fillBuckets()
				T:up(1)
				T:place("slab", -1, "down", false)
			end
		end
		if T:place("minecraft:water_bucket", -1, "up") then -- end of length
			print("Placed final source up")
		end
		return place
	end
	
	function lib.moveSlabs(length)
		for i = 1, length do
			T:dig("down")
			T:up(1)
			T:place("slab", -1, "down", true)
			if i < length then
				T:forward(1)
				T:down(1)
			end
		end
	end
	
	function lib.recoverSlabs(length)
		for i = 1, length do
			T:dig("down")
			if i < length then
				T:forward(1)
			end
		end
	end
	
	local depth, message = lib.checkStartPosition()
	if message ~= "" then
		return {message}
	end
	local maxDepth = R.height
	local buckets = utils.getWaterBucketCount()
	R = utils.calculateDimensions(R) -- if R.width or R.length == 0
	T:down(depth)
	lib.placeSlabs(R.length)
	T:go("R1")
	lib.placeSlabs(R.width)
	T:go("R2")
	
	while depth > 0 do
		local place = true
		lib.fillBuckets()
		place = lib.placeSources(R.width, place)
		T:go("L1")
		place = lib.placeSources(R.length, place)
		lib.fillBuckets()
		T:go("R2")
		lib.moveSlabs(R.length) -- dig slab from below, move up and replace below
		T:go("R1F1D1")
		lib.moveSlabs(R.width - 1)
		T:go("R2") -- now moved up 1 layer
		depth = depth - 1
		if depth == 0 then
			place = lib.placeSources(R.width, true)
			T:go("L1")
			place = lib.placeSources(R.length, place)
			T:go("R2")
			lib.recoverSlabs(R.length)
			T:go("R1")
			lib.recoverSlabs(R.width)
		end
	end
	
	return {}
end

local function createAutoTreeFarm() -- 25
	local lib = {}
	
	function lib.fillWaterBuckets()
		T:place("minecraft:bucket", -1, "down", false)
		sleep(0.5)
		T:place("minecraft:bucket", -1, "down", false)
	end
	
	utils.createWaterSource(1)
	-- clsTurtle.go(path, useTorch, torchInterval, leaveExisting)
	-- place chest and hopper	
	T:go("x0F1x0F1x0F1x0F1R1")
	for i = 1, 4 do
		T:go("D1R1C1R1C1R1C1R1")
	end
	T:up(1)
	T:place("minecraft:chest", -1, "down", false)
	T:go("F1x0D1F1x0R2", false, 0, true)
	T:place("minecraft:hopper", -1, "forward", false)
	-- dig trench and ensure base is solid
	T:go("U1R2X7U1", false, 0, true)
	T:place("minecraft:water_bucket", -1, "down", false) -- collection stream
	T:go("F1X7U1", false, 0, true)
	T:place("minecraft:water_bucket", -1, "down", false) -- upper collection stream
	T:go("U1F1R1C2F1R1C2") --now on corner
	for i = 1, 14 do --place cobble
		T:go("F1C2", false, 0, false)
	end
	T:go("F4R1F2C2R2C1R2")
	for i = 1, 8 do --place cobble
		T:go("F1C2", false, 0, false)
	end
	T:turnRight(1)
	for i = 1, 18 do --place cobble
		T:go("F1C2", false, 0, false)
	end
	T:turnRight(1)
	for i = 1, 8 do --place cobble
		T:go("F1C2", false, 0, false)
	end
	T:go("R1F1R1D1") -- ready to clear ground inside cobble wall
	for i = 1, 17 do
		T:go("C2F1C2F1C2F1C2F1C2F1C2F1C2F1C2", false, 0, true)
		if i < 17 then
			if i % 2 == 1 then -- odd no
				T:go("L1F1L1")
			else
				T:go("R1F1R1")
			end
		end
	end
	T:go("U1R2F10R2") -- over pond
	lib.fillWaterBuckets()
	for i = 0, 16, 2 do
		T:go("F10R1")
		if i > 0 then
			T:go("F"..i)
		end
		T:place("minecraft:water_bucket", -1, "down", false)
		T:go("F1R2")
		if i < 16 then
			T:place("minecraft:water_bucket", -1, "down", false)
		end
		T:go("F"..i + 1 .."L1")
		T:go("F10R2")
		lib.fillWaterBuckets()
	end
	-- place dirt/torch/sapling
	T:go("F1U1R1F1L1")
	for i = 1, 7 do
		T:go("F6R1F1L1")
		for j = 1, 3 do
			T:place("minecraft:dirt", -1, "forward", false)
			T:up(1)
			T:place("sapling", -1, "forward", false)
			T:down(1)
			turtle.back()
			T:place("minecraft:torch", -1, "forward", false)
			turtle.back()
		end
		if i < 7 then
			T:go("R1F1L1")
		end
	end
	T:go("L1F12")
	T:place("minecraft:chest", -1, "up", false)
	T:go("R1F1L1")
	T:place("minecraft:chest", -1, "up", false)
	T:go("F1U1R1F1R1F1L1")
	T:clear()
	print("Auto TreeFarm completed")
	print("\nDO NOT PLACE ANY TORCHES OR OTHER")
	print("BLOCKS ON THE COBBLE PERIMETER!")
	print("\nUse option 5 Manage Auto Tree farm")
	print("to setup monitoring\n\nEnter to continue")
	read()
	return {}
end

local function createBoatLift(state, side, height) -- 59 state:0=new, size:1=extend, side:0=left, 1=right
	--[[ Legacy version (turtle deletes water source)
	Place turtles on canal floor, with sources ahead
	facing back wall preferred, but not essential
	1.14 + (turtle can be waterlogged)
	Place same as legacy but inside source blocks
	R.subChoice =
	1 New lift on left side
	2 New lift on right side
	3 Extend lift on left side
	4 Extend lift on right side
	]]
	local lib ={}
	
	function lib.checkSource()
		local isWater = false
		local isSource = false
		T:dig("forward")						-- break frozen source block
		isWater, isSource = T:isWater("forward")
		return isSource
	end
	
	function lib.findPartner()
		local block = T:getBlockType("forward")
		while block:find("turtle") == nil do -- not found partner
			 if side == 0 then
				turtle.turnRight()
			 else
				turtle.turnLeft()
			 end
			 sleep(0.5)
			 block = T:getBlockType("forward")
		end
	end
	
	function lib.returnToWork(level)
		if level > 0 then
			for i = 1, level do
				T:place("minecraft:water_bucket", -1, "down")
				sleep(0.5)
				local _, isSource = T:isWater("down")
				while not isSource do
					print("Waiting for source...")
					sleep(0.5)
					_, isSource = T:isWater("down")
				end
				T:place("minecraft:bucket", -1, "down")
				T:up(1)
			end
		end
	end
	
	function lib.getToWater()
		local level = 0
		local isWater, isSource, isIce = T:isWater("down")
		while not isSource and isWater do -- water but not source
			T:down(1)
			level = level + 1
			isWater, isSource, isIce = T:isWater("down")
		end
		if isIce then T:dig("down")	end									-- break frozen source block
		if not isWater then
			isWater, isSource, isIce = T:isWater("up")
			if isSource then
				T:place("minecraft:bucket", -1, "up")
			end
		else
			T:place("minecraft:bucket", -1, "down")
		end
		lib.returnToWork(level)
	end
	
	function lib.refill()
		local s1, s2, buckets = T:getItemSlot("minecraft:bucket", -1) 	-- slotData.lastSlot, slotData.leastModifier, total, slotData
		local level = 0
		if buckets > 0 then												-- at least 1 empty bucket
			local isWater, isSource, isIce = T:isWater("down")
			if isIce then T:dig("down")	end								-- break frozen source block
			if T:place("minecraft:bucket", -1, "down") then				-- get water from below.
				sleep(0.5)
			else
				lib.getToWater()
			end
		end
		s1, s2, buckets = T:getItemSlot("minecraft:bucket", -1)
		if buckets > 0 then	-- at least 1 empty bucket
			if isIce then T:dig("down")	end								-- break frozen source block
			if not T:place("minecraft:bucket", -1, "down") then			-- get water from below
				lib.getToWater()
			end
		end
	end
	
	function lib.reset()
		redstone.setAnalogueOutput("front", 0)
		redstone.setOutput("front", false)
	end
	
	function lib.sendSignal()
		-- wait until turtle detected in front
		-- if detected set signal to 15 and pause 0.5 secs
		-- if recieves 15 from other turtle, continue
		-- if recieves 7 from other turtle, job done
		local block = T:getBlockType("forward")
		if block:find("turtle") == nil then -- not found partner
			print("Waiting for partner turtle...")
			print("If not facing towards partner")
			print("please restart this program")
			sleep(1)
		else
			redstone.setAnalogueOutput("front", 0)
			redstone.setOutput("front", false)
			if redstone.getAnalogueInput("front") == 15 then
				redstone.setOutput("front", true)
				print("Binary sent to partner turtle...")
				sleep(0.5)
				return true
			else
				print("Signal 15 sent to partner turtle...")
				redstone.setAnalogueOutput("front", 15)
				sleep(0.5)
			end
			redstone.setAnalogueOutput("front", 0)
			if redstone.getInput("front")  or redstone.getAnalogueInput("front") == 15 then
				 return true
			end
			return false
		end
		return false
	end
	
	function lib.legacyLeft(layer)
		lib.refill()
		T:go("U1")	
		T:place("minecraft:water_bucket", -1, "down")	-- place below. facing partner
		T:go("L1F1")									-- move to back, facing back
		T:place("minecraft:water_bucket", -1, "down")	-- place water below
		T:go("C1")										-- facing back, build back wall
		T:go("L1C1")									-- facing side, build side
		T:go("L1F1R1C1")								-- move towards front, build side wall
		if layer == 1 then								-- do not replace slab on layer 1
			T:go("L2")
		else
			T:go("L1C1L1")								-- build front wall, turn to face partner
		end
	end
	
	function lib.left(layer)
		lib.refill()
		T:go("D1")	
		T:place("minecraft:water_bucket", -1, "up")	-- place above. facing partner
		T:go("L1F1")								-- move to back, facing back
		T:place("minecraft:water_bucket", -1, "up")	-- place water above
		lib.refill()
		T:go("U2C1")								-- up 2;facing back, build back wall
		T:go("L1C1")								-- facing side, build side
		T:go("L1F1R1C1")							-- move towards front, build side wall
		if layer == 1 then							-- do not replace slab on layer 1
			T:go("L2")
		else
			T:go("L1C1L1")							-- build front wall, turn to face partner
		end
		local _, isSource, isIce = T:isWater("down")
		if isIce then T:dig("down")	end				-- break frozen source block
		if not isSource then
			lib.getToWater()
		end
	end
	
	function lib.right(layer)
		lib.refill()
		T:go("D1")	
		T:place("minecraft:water_bucket", -1, "up")	-- place above. facing partner
		T:go("R1F1")								-- move to back, facing back
		T:place("minecraft:water_bucket", -1, "up")	-- place water above
		lib.refill()
		T:go("U2C1")								-- up 2;facing back, build back wall
		T:go("R1C1")								-- facing side, build side
		T:go("R1F1L1C1")							-- move towards front, build side wall
		if layer == 1 then							-- do not replace slab on layer 1
			T:go("R2")
		else
			T:go("R1C1R1")							-- build front wall, turn to face partner
		end	
		local _, isSource, isIce = T:isWater("down")
		if isIce then T:dig("down")	end				-- break frozen source block
		if not isSource then
			lib.getToWater()
		end
	end
	
	function lib.legacyRight(layer)
		lib.refill()
		T:go("U1")	
		T:place("minecraft:water_bucket", -1, "down")	-- place below. facing partner
		T:go("R1F1")									-- move to back, facing back
		T:place("minecraft:water_bucket", -1, "down")	-- place water below
		T:go("C1")										-- facing back, build back wall
		T:go("R1C1")									-- facing side, build side
		T:go("R1F1L1C1")								-- move towards front, build side wall
		if layer == 1 then								-- do not replace slab on layer 1
			T:go("R2")
		else
			T:go("R1C1R1")								-- build front wall, turn to face partner
		end												-- up 1;turn to face partner
	end
	
	function lib.top(height)
		if side == 0 then --left side
			T:go("x0L1F1x0L2 F2R1C1C0 D1C1") -- place side block; block above, move down; side block
			T:place("sign", -1, "up", true, "Lift Exit\n<--\n<--\nEnjoy the ride...") 
			T:go("L1F1L2C1 U2x1x0 L2F1x0L2")
		else
			T:go("x0R1F1x0R2 F2L1C1C0 D1C1") -- place side block, move up
			T:place("sign", -1, "up", true, "Lift Exit\n-->\n-->\nEnjoy the ride...") 
			T:go("R1F1R2C1 U2x1x0 R2F1x0R2")
		end
		for i = height, 1, -1 do
			T:go("x1D1")
		end
	end
	
	local A = "R"
	local B = "L"
	local side = 0
	if R.subChoice == 2 or R.subChoice == 4 then -- right side turtle
		A = "L"
		B = "R"
		side = 1
	end
	lib.findPartner()
	T:go(B.."1")
	if not lib.checkSource() then
		print("No water source ahead.\nReposition or add source")
		error()
	end
	T:go(A.."1")
	lib.reset()
	while not lib.sendSignal() do end
	lib.reset()
	-- confirmed opposite and active
	if R.subChoice == 1 or R.subChoice == 2 then -- new lift
		if side == 0 then
			T:turnLeft(1)						-- face back
		else
			T:turnRight(1)						-- face back
		end
		T:go(B.."2F1U1"..A.."1C1") 				-- face front;forward 1;up 1; :face side ready for sign and slab placement
		T:place("slab", -1, "up")				-- slab above
		T:go("D1")								-- down 1
		T:place("sign", -1, "up", true, "Lift Entrance\nKeep pressing\nforward key!") 
		T:go(A.."1F1"..A.."2") 					-- face back; forward 1; :face front
		T:place("slab", -1, "forward") 			-- slab on ground at entrance
		T:go(A.."1")							-- face side
		T:place("minecraft:soul_sand", -1, "down", false) -- replace block below with soul sand
		T:go("C1"..A.."1F1C1"..B.."1C1") 		-- block to side; forward, block at back; block to side :face side
		T:place("minecraft:soul_sand", -1, "down", false) -- replace block below with soul sand
		T:go("U1C1"..A.."1C1"..A.."2F1"..A.."1C1"..A.."2") -- up 1; block to side; forward; block to side :face other turtle
		local isWater, isSource, isIce = T:isWater("down")
		if not isSource then -- no source below
			T:place("minecraft:water_bucket", -1, "down") 	-- refill source
			T:go(B.."1F1"..B.."2")
			T:place("minecraft:water_bucket", -1, "down") 	-- refill source
			T:go("F1"..B.."1")
			sleep(0.5)
			isWater, isSource = T:isWater("down")
			if isSource then
				if isIce then
					T:dig("down")								-- break frozen source block
				end
				T:place("minecraft:bucket", -1, "down") 		-- refill bucket
				sleep(0.5)
				T:place("minecraft:bucket", -1, "down") 		-- refill bucket
			end
		end
		lib.reset()
		while not lib.sendSignal() do end
		lib.reset()
		-- on layer 1  1 x source blocks below
		for layer = 1, R.height do
			if side == 0 then --left side
				if deletesWater then
					lib.legacyLeft(layer)
				else
					lib.left(layer)
				end
			else
				if deletesWater then
					lib.legacyRight(layer)
				else
					lib.right(layer)
				end
			end
			lib.reset()
			while not lib.sendSignal() do end
			lib.reset()
		end
		lib.top(R.height)	
	else -- extend lift
		-- turtles should be at front, facing back of lift
		-- signs behind them, water sources below
		-- will face each other on startup, exactly as if finished new lift
		for layer = 1, R.height do
			for layer = 1, R.height do
				if side == 0 then --left side
					if deletesWater then
						lib.legacyLeft(layer)
					else
						lib.left(layer)
					end
				else
					if deletesWater then
						lib.legacyRight(layer)
					else
						lib.right(layer)
					end
				end
				lib.reset()
				while not lib.sendSignal() do end
				lib.reset()
			end
		end
		lib.top(R.height + 1)	-- drop to below existing lift
		while turtle.down() do end -- drop to base canal
	end
	return {}
end

local function createBridge(R) -- 53
	--[[ R.choice = 53]]
	for i = 1, R.length do
		T:go("m1", false, 0, true)
	end
	T:go("R1F1R1", false, 0, true)
	for i = 1, R.length do
		T:go("m1", false, 0, true)
	end
	return {}
end

local function createBubbleLift(R) -- 15
	local lib = {}
	
	function lib.addLayer()
		T:go("F2 L1C1R1C1R1C1L1", false, 0, true)
		turtle.back()
		T:place("minecraft:water_bucket", -1, "forward")
		T:dig("up")	-- clear block above so completed lift can be found
		turtle.back()
		T:dig("up")	-- clear block above so completed lift can be found
		T:place("stone", -1, "forward")
	end
	
	function lib.addSign()
		turtle.back()
		T:place("minecraft:water_bucket", -1, "forward")
		T:go("L1B1")
		T:place("sign", -1, "forward")
	end
	
	function lib.buildLift(toHeight)
		local built = lib.goToWater() 		-- returns lift blocks already placed, total height of drop from starting point
		local toBuild = toHeight - built 	-- no of blocks remaining to increase lift size
		local water = 0
		while toBuild > 0 do 				-- at least 1 block height remaining
			water = lib.fillBuckets(toBuild, false) -- no of water buckets onboard (could be more than required)
			if water > toBuild then			-- more water than required
				water = toBuild				-- reduce to correct amount
			end
			while turtle.detect() do 		-- climb to top of existing lift
				turtle.up()
			end
			while water > 0 do
				lib.addLayer()
				water = water - 1
				T:up(1)
				toBuild = toBuild - 1
			end
			-- may still be some height to complete, but needs refill
			if toBuild > 0 then
				built = lib.goToWater() --return to source
				toBuild = toHeight - built
				--lib.fillBuckets(toBuild)
			end
		end
	end
	
	function lib.cleanUp(fromHeight)
		local plug = false
		T:turnRight(2)
		for i = 1, fromHeight do
			plug = false
			if turtle.detect() then
				plug = true
			end
			turtle.down()
			if plug then
				T:place("stone", -1, "up")
			end
		end
	end
	
	function lib.fillBuckets(toBuild, withSort)
		local emptySlots, water = lib.stackBuckets(withSort)-- gets no of empty slots + no of water buckets
		if water < toBuild then 					-- no of water buckets onboard less than required quantity
			for i = 1, toBuild do 					-- fill required no of buckets up to max space in inventory
				if emptySlots == 0 then 			-- inventory full
					break
				else
					if T:place("minecraft:bucket", -1, "down", false) then
						water = water + 1
						sleep(0.5)
					end
				end
				emptySlots = lib.getEmptySlots()
			end
		end
		
		return water
	end
	
	function lib.getEmptySlots()
		local empty = 0
		for i = 1, 16 do
			if turtle.getItemCount(i) == 0 then
				empty = empty + 1
			end
		end
		return empty
	end
	
	function lib.goToWater()
		local built = 0 -- measures completed lift height
		while turtle.down() do -- takes turtle to bottom of water source
			--height = height + 1
			if turtle.detect() then
				built = built + 1
			end
		end
		T:up(1) -- above watersource assuming it is 1-1.5 blocks deep
		-- height = height - 1
		-- built = built - 1 not required as next block is water source: not detected
		return built -- , height
	end
	
	function lib.stackBuckets(withSort)
		if withSort == nil then withSort = false end
		local data = {}
		local bucketSlot = 0
		local emptySlots = 0
		local water = 0
		if withSort then
			T:sortInventory()
		end
		for i = 1, 16 do
			-- find first empty bucket
			if turtle.getItemCount(i) > 0 then
				data = turtle.getItemDetail(i)
				if data.name == "minecraft:bucket" then
					if bucketSlot == 0 then
						bucketSlot = i
					else
						turtle.select(i)
						turtle.transferTo(bucketSlot)
					end
				elseif data.name == "minecraft:water_bucket" then
					water = water + 1
				end
			else
				emptySlots = emptySlots + 1
			end
		end
		return emptySlots, water
	end
	
	-- go(path, useTorch, torchInterval, leaveExisting, preferredBlock)
	-- create water source
	T:go("D1 R2F1 D1C2 R1C1 R1C1 R1C1 R1", false, 0, true)	-- down 1, turn round 1 block away from stairs, down 1. blocks forward, down, left and right, face backwards
	T:go("F1C2 L1C1 R2C1 L1", false, 0, true) 				-- prepare centre of water source: blocks down , left, right
	T:go("F1C2 L1C1 R1C1 R1C1 R1F1", false, 0, true)		-- prepare end of water source, move to centre, facing forward
	T:place("minecraft:water_bucket", -1, "forward")
	T:turnRight(2)											-- facing backward
	T:place("minecraft:water_bucket", -1, "forward")
	T:go("R2U1F1") -- facing forward
	T:place("minecraft:soul_sand", -1, "forward", false) 	-- placed at end of water source
	turtle.back()											-- above centre of water source
	T:place("stone", -1, "forward")
	-- fill buckets and build first 2 levels
	lib.fillBuckets(R.height, true)	-- fill as many buckets as required or until inventory full, sort inventory as well
	T:go("U1F2 L1C1R1C1R1C1L1", false, 0, true)		-- prepare layer 1
	lib.addSign()
	T:go("U1F1R1F1 L1C1R1C1R1C1L1", false, 0, true)	-- prepare layer 2
	lib.addSign()
	T:go("L1F1 R1F1R1", false, 0, true)	 -- above source, level 2
	lib.buildLift(R.height)
	lib.cleanUp(R.height)
	
	return {"Bubble lift created", "Check correct operation", "Check exit before using" }
end

local function createBubbleTrap(R) -- 34
	--[[
	Replace floor of existing volume of water with soulsand
	Used in river biome for squid farm. Area should be enclosed
	with solid walls surface to floor.
	Usually 7 blocks wide
	]]
	local lib = {}
	
	function lib.clearDown(depth)
		while utils.clearVegetation("down") do
			T:down(1)
			depth = depth + 1
		end
		T:place("soul_sand", -1, "down", false)
		return depth
	end
	
	function lib.clearLength(length, depth)
		local moves = 0
		while moves < length - 1 do
			if utils.clearVegetation("forward") then
				T:forward(1)
				moves = moves + 1 
				depth = lib.clearDown(depth) -- go down if in water/air
				if moves >= length - 1 then
					return depth
				end
			else -- block in front
				local waterAhead = utils.clearVegetation("forward") -- true if air/water in front
				while not waterAhead do 	-- solid block in front
					T:up(1)
					depth = depth - 1
					if depth < 1 then
						return 0
					end
					waterAhead = utils.clearVegetation("forward")
				end
			end
		end

		return depth
	end
	
	function lib.turn(facingForward, depth)
		local direction = "R"
		if not facingForward then
			direction = "L"
		end
		T:go(direction.. 1)
		if utils.clearVegetation("forward") then
			T:forward(1)
			depth = depth + lib.clearDown(depth)
		else
			while not utils.clearVegetation("forward") do
				T:up(1)
				depth = depth - 1
			end
		end
		T:go(direction.. 1)
		
		return depth
	end
	
	local depth = 0
	local length = 0
	local width = 0
	local outbound = true
	local facingForward = true
	local inWater, onWater = utils.getWaterStatus()
	inWater, onWater = utils.startWaterFunction(onWater, inWater, 2 ,true) -- move into water, max descent 2
	if R.length == 0 then
		R.length = lib.getLength()
	end
	if R.width == 0 then
		T:turnRight(1)
		R.width = lib.getLength()
		T:turnLeft(1)
	end
	-- go down to floor
	depth = lib.clearDown(depth)
	while width < R.width do
		-- now on floor, move along sea/river bed following contour
		depth = lib.clearLength(R.length, depth)
		width = width + 1
		-- now turn and repeat
		if width < R.width then	
			depth = lib.turn(facingForward, depth)
			facingForward = not facingForward
		end
	end
	-- finished so return to surface
	T:up(1) -- up 1 to check for water below
	while T:isWater("down") do
		T:up(1)
	end
	
	return {}
end

local function createDragonAttack() -- 46
	--[[
	  X 0 0 0 X    	X = exit site				 (y = 63)
	X E O O O E X	0 = bedrock on layer above   (y = 63)
	0 O O O O O 0	O = bedrock on working layer (y = 62)
	0 O O O O O 0	E = starting position		 (y = 62)
	0 O O O O O 0
	X E O O O E X
	  X 0 0 0 X
	]]
	local lib = {}
	
	function lib.upToBedrock()
		local blockTypeU = T:getBlockType("up")
		while blockTypeU ~= "minecraft:bedrock" do
			T:up(1)
			blockTypeU = T:getBlockType("up")
		end
	end
	
	function lib.toEdgeOfBedrock()
		local distance = 0
		local blockTypeU = T:getBlockType("up")
		while blockTypeU == "minecraft:bedrock" do
			T:forward(1)
			distance = distance + 1
			blockTypeU = T:getBlockType("up")
		end
		return distance
	end
	
	function lib.findStart()
		lib.toEdgeOfBedrock()				-- go outside bedrock area
		T:go("R2F1") 						-- turn round, forward 1, under bedrock again
		local width = lib.toEdgeOfBedrock()	-- ended outside bedrock

		if width == 5 then 					-- origin in main section
			T:go("R2F3L1") 					-- now in centre of 1 axis, turned left
			width = lib.toEdgeOfBedrock()	-- ended outside bedrock, width should be 1 to 4 depending on start pos
			T:go("R2F1L1") 					-- move back under bedrock edge (3 blocks)
			lib.toEdgeOfBedrock()			-- move to corner of bedrock
		--  elseif width == 3 then 			-- on outer strip of 3
		end
	end
	
	function lib.buildWall(length)
		for i = 1, length do
			if i < length then
				T:go("C2F1", false, 0, true)
			else
				T:go("C2", false, 0, true)
			end
		end
	end
	
	function lib.addCeiling(length)
		for i = 1, length do
			if i < length then
				T:go("C0F1", false, 0, true)
			else
				T:go("C0", false, 0, true)
			end
		end
	end
	
	lib.upToBedrock()						-- go up until hit bedrock
	lib.findStart()							-- should be on position 'E'
	T:go("F1U2L1")							-- forward to any 'X' up 2, turn left
	local blockTypeF = T:getBlockType("forward")
	if blockTypeF == "minecraft:bedrock" then	-- exit not correct
		T:turnRight(2)	-- face correct direction
	else
		T:turnRight(1)	-- return to original direction
	end
	T:go("U2F1 L1F2L2") -- on corner outside bedrock, ready to build wall
	for i = 1, 4 do
		lib.buildWall(9)
		T:turnRight(1)
	end
	T:up(1)
	for i = 1, 4 do
		lib.buildWall(9)
		T:turnRight(1)
	end
	T:go("F1R1F1L1D1")
	-- add ceiling
	lib.addCeiling(7)
	T:go("R1F1R1")
	lib.addCeiling(7)
	T:go("L1F1L1")
	lib.addCeiling(7)
	T:go("R1F1R1")
	lib.addCeiling(3)
	T:go("L2F2")
	T:go("R1F1R1")
	lib.addCeiling(7)
	T:go("L1F1L1")
	lib.addCeiling(7)
	T:go("R1F1R1")
	lib.addCeiling(7)
	T:go("R1F3R1")
	lib.addCeiling(3)
	T:dig("up")
	attack(true)
	return {}
end

local function createDragonTrap() -- 49
	-- build up 145 blocks with ladders
	for i = 1, 145 do
		T:go("U1C2")
		turtle.back()
		T:place("minecraft:ladder", -1, "down")
		turtle.forward()
	end
	T:go("R2F1C1 L1C1 L2C1 R1")
	for i = 1, 100 do
		T:go("F1C2")
	end
	T:forward(1)
	T:place("minecraft:obsidian", -1, "down")
	T:go("R2F1x2R2")
	T:place("minecraft:water_bucket", -1, "forward")
	T:go("R2F6R2")
	attack(false)
	return {}
end

local function createPath(R) -- 51
	local numBlocks = 0
	local continue = true
	for i = 1, 2 do
		T:fillVoid("down", {}, false)
		T:forward(1)
		numBlocks = numBlocks + 1
	end
	local place = utils.clearVegetation("down")
	while place do -- while air, water, normal ice, bubble column or lava below
		if T:fillVoid("down", {}, false) then -- false if out of blocks
			T:forward(1)
			numBlocks = numBlocks + 1
			if numBlocks % 8 == 0 then
				if T:getItemSlot("minecraft:torch", -1) > 0 then
					T:turnRight(2)
					T:place("minecraft:torch", -1, "forward", false)
					T:turnRight(2)
				end
			end
		else
			break
		end
		if R.length > 0 and numBlocks >= R.length then -- not infinite path (length = 0)
			break
		end
		place = utils.clearVegetation("down")
	end
	return {numBlocks}
end
	
local function createCanal(R) -- 55
	-- go(path, useTorch, torchInterval, leaveExisting)
	-- if height = 0 then already at correct height on canal floor
		-- check block below, block to left and block above, move forward tunnelling
		-- if entering water then move up, onto canal wall and continue pathway
		-- if 55 and tunnelling then flood canal
	-- else height = 1 then above water and on path across
		-- move forward, checking for water below
		-- if water finishes, move into canal, drop down and continue tunnelling
	local lib = {}
	
	function lib.pause()
		local waiting = true
		local isWater =  false
		local isSource = false
		while waiting do -- wait until either turtle or water is in front
			--print("Waiting for other turtle")
			if turtle.detect() then --block to side, check is not turtle
				if T:getBlockType("forward"):find("turtle") ~= nil then -- turtle next door
					waiting = false
				end
			else
				isWater, isSource = T:isWater("forward")
				if isSource then --either already in water or partner turtle has placed water
					waiting = false
				end
			end
			sleep(0.2)
		end
	end
	
	function lib.side(side, length, maxLength, height)
		local turnA = "R"
		local turnB = "L"
		local isWater = false
		local isSource = false
		local onWater = false
		local numBlocks = 0
		local doContinue = true
		if side == 1 then -- right 
			turnA = "L"
			turnB = "R"
		end
		-- if starting on wall, probably already on water
		if height == 1 then -- if on wall, move to floor, turn to face opposite canal wall
			T:forward(1)
			isWater, isSource = T:isWater("down")
			if isSource then --on river/ocean so just construct walkway
				onWater = true
				numBlocks = createPath(length - 1)[1]
				if numBlocks < maxLength then -- continue with canal
					T:go(turnA.."1F1D1"..turnA.."1")
				else
					doContinue = false
				end
			else
				T:go(turnA.."1F1D1")
			end
		else -- on canal floor, but could be open water
			isWater, isSource = T:isWater("forward")
			if isSource then -- water source ahead. Assume on open water	
				T:go(turnB.."1U1F1"..turnA.."1")
				onWater = true
				numBlocks = createPath(length - 1)[1]
				if numBlocks < maxLength then -- continue with canal
					T:go(turnA.."1F1D1"..turnA.."1")
				else
					doContinue = false
				end
			else
				T:go(turnA.."1")
			end		
		end
		if not onWater then
			lib.pause()
			T:go(turnA.."1")
			-- facing canal start wall
			if turtle.detect() then -- solid block behind: at start of canal	
				T:go(turnB.."2C2F1"..turnB.."1C1"..turnB.."1C2x0", false, 0, true) --move forward and check base/side, face start
				T:place("minecraft:water_bucket", -1, "forward")
			else -- air or water behind
				-- check if water already present behind. if not create source
				isWater, isSource = T:isWater("forward")
				if not isSource then
					T:place("minecraft:water_bucket", -1, "forward")
				end
			end
		end
		-- could be over water, just need walls
		--print("Loop starting. Enter")
		--read()
		local blockType, modifier
		local torch = 0
		local sourceCount = 0
		--loop from here. Facing backwards over existing canal/start
		while doContinue and numBlocks < maxLength do
			isWater, isSource = T:isWater("forward")
			while not isSource do
				sleep(10)
				print("waiting for water...")
				isWater, isSource = T:isWater("forward")
			end
			T:place("minecraft:bucket", -1, "forward") -- take water from source
			-- move forward check canal wall for block, below for block
			--T:go(turnA.."2F1C2"..turnB.."1C1", false, 0, true) -- face canal wall, repair if req
			T:go(turnA.."2F1C2", false, 0, true) --move forward, close floor
			isWater, isSource = T:isWater("forward")
			--print("Source in front: "..tostring(isSource).." Enter")
			--read()
			if isSource then --now on open water. move up and continue
				sourceCount = sourceCount + 1
				if sourceCount > 3 then
					sourceCount = 0
					T:go(turnB.."1U1F1"..turnA.."1")
					numBlocks = numBlocks +  createPath(length - numBlocks)[1] -- eg done 20/64 blocks createPath(44)
					if numBlocks < maxLength then -- continue with canal
						T:go(turnA.."1F1D1"..turnA.."1x1"..turnA.."2") --return to canal bottom, break any block behind
					else
						doContinue = false
					end
				end
			end
			T:go(turnB.."1C1", false, 0, true) -- face canal wall, repair if req
			--print("facing wall. Enter")
			--read()
			T:go("U1x1") --go up and remove any block
			torch = torch + 1
			numBlocks = numBlocks + 1
			if turtle.detectUp() then -- block above
				T:go("U1x1")
				if torch == 8 then
					torch = 0
					T:place("minecraft:torch", -1, "forward")
				end
				T:down(1)
			end
			if torch == 8 then
				torch = 0
				T:place("minecraft:torch", -1, "forward")
			end
			T:down(1) -- on canal floor facing wall
			T:go(turnB.."1", false, 0, true)
			-- place water behind if some water is present
			isWater, isSource = T:isWater("forward")
			if not isWater then --no flowing water behind so deploy both sources
				T:forward(1)
				T:place("minecraft:water_bucket", -1, "forward")
				turtle.back()
			end
			T:place("minecraft:water_bucket", -1, "forward")
			-- check opposite canal wall
			T:go(turnB.."1")
			lib.pause()
			T:go(turnA.."1")
		end
	end
	
	function lib.leftSideLegacy(side, length, maxLength, height)
		local doContinue = true
		local numBlocks  = 0
		local doTunnel = false
		local requestTunnel = false
		local blockType, modifier
		while doContinue and numBlocks < maxLength do
			if height == 0 then -- canal floor
				blockType, modifier = T:getBlockType("down")
				if blockType == "" or blockType == "minecraft:lava" then -- air or lava below, so place block
					T:place("minecraft:cobblestone", -1, "down", false)
				end
				-- place side block
				T:go("L1C1R1", false , 0, true)
				-- check above
				blockType, modifier = T:getBlockType("up")
				--if blockType == "minecraft:log" or blockType == "minecraft:log2" then
				if blockType ~= "" then
					if string.find(blockType, "log") ~= nil then
						T:harvestTree(false, false, "up")
					elseif blockType == "minecraft:lava" or blockType == "minecraft:water" then
						T:up(1)
						T:place("minecraft:cobblestone", -1, "up", false)
						T:down(1)
					else --solid block or air above
						if blockType ~= "" then
							T:dig("up")
						end
					end
				end
				-- check if block in front is water source
				blockType, modifier = T:getBlockType("forward")
				--if block:find("water") ~= nil then
				if blockType == "minecraft:water" and modifier == 0 then -- source block in front could be lake/ocean
					-- move up, to left and continue as height = 1
					T:go("U1L1F1R1", false, 0, true)
					height = 1
				else
					T:forward(1, true)
					numBlocks = numBlocks + 1
				end
			else -- height = 1, on canal wall
				numBlocks = numBlocks + createPath(0)[1]
				-- if path finished, then move back to canal floor and continue tunnelling
				T:go("R1F1D1L1", false, 0, true)
				height = 0
			end
		end
	end
	
	function lib.rightSideLegacy(side, length, maxLength, height)
		-- assume left side already under construction
		local doContinue = true
		local numBlocks  = 0
		local doTunnel = false
		local requestTunnel = false
		local blockType, modifier
		local poolCreated = false
		while doContinue and numBlocks < maxLength do
			if height == 0 then-- canal floor
				-- create first infinity pool
				if not poolCreated then
					T:up(1)
					T:place("minecraft:water_bucket", -1, "down", false)
					T:go("L1F1R1", false, 0, true)
					T:place("minecraft:water_bucket", -1, "down", false)
					T:forward(1)
					T:place("minecraft:water_bucket", -1, "down", false)
					T:back(1)
					-- refill buckets
					for j = 1, 3 do
						T:place("minecraft:bucket", -1, "down", false)
						sleep(0,5)
					end
					T:go("R1F1L1F2", false , 0, true)
					T:down(1)
					poolCreated = true
				end
				blockType, modifier = T:getBlockType("down")
				if blockType == "" or blockType == "minecraft:lava" 
				   or blockType == "minecraft:water" or blockType == "minecraft:flowing_water" then -- air, water or lava below, so place block
					T:place("minecraft:cobblestone", -1, "down", false)
				end
				-- place side block
				T:go("R1C1L1", false , 0, true)
				T:up(1)
				blockType, modifier = T:getBlockType("up")
				if blockType == "minecraft:log" or blockType == "minecraft:log2" then
					T:harvestTree(false, false, "up")
				elseif blockType == "minecraft:lava" or blockType == "minecraft:water" then
					T:place("minecraft:cobblestone", -1, "up", false)
				end
				T:place("minecraft:water_bucket", -1, "down", false)
				for j = 1, 2 do
					T:forward(1)
					blockType, modifier = T:getBlockType("up")
					--if blockType == "minecraft:log" or blockType == "minecraft:log2" then
					if blockType ~= "" then
						if string.find(blockType, "log") ~= nil then
							T:harvestTree(false, false, "up")
						elseif blockType == "minecraft:lava" or blockType == "minecraft:water" then
							T:place("minecraft:cobblestone", -1, "up", false)
						end
					end
					-- at ceiling level
					T:go("D1R1C1L1", false, 0, true)
					blockType, modifier = T:getBlockType("down")
					if blockType == "" or blockType == "minecraft:lava" 
					   or blockType == "minecraft:water" or blockType == "minecraft:flowing_water" then -- air, water or lava below, so place block
						T:place("minecraft:cobblestone", -1, "down", false)
					end
					-- check if block in front is water source
					blockType, modifier = T:getBlockType("forward")
					T:up(1)
					T:place("minecraft:water_bucket", -1, "down", false)
					if blockType == "minecraft:water" and modifier == 0 then -- source block in front could be lake/ocean
						-- move to right and continue as height = 1
						T:go("R1F1L1", false, 0, true)
						height = 1
						break	
					end
				end
				if height == 0 then
					T:back(2)
					for j = 1, 3 do
						T:place("minecraft:bucket", -1, "down", false)
						sleep(0,5)
					end
					T:go("F3D1", false, 0, true)
				end
			else -- height = 1: on wall 
				numBlocks = numBlocks + createPath(0)[1]
				-- if path finished, then move back to canal floor and continue tunnelling
				T:go("L1F1L1F1", false, 0, true) -- facing backwards, collect water
				for j = 1, 3 do
					T:place("minecraft:bucket", -1, "down", false)
					sleep(0,5)
				end
				T:go("R2F1D1", false, 0, true) --canal floor
				height = 0
			end
		end
	end
	
	-- side = 0/1: left/right side
	-- length = 0-1024 0 = continuous
	-- height = 0/1 0 = floor, 1 = wall
	-- T:place(blockType, damageNo, direction, leaveExisting)
	-- T:go(path, useTorch, torchInterval, leaveExisting)
	
	local maxLength = 1024
	if R.length ~= 0 then
		maxLength = R.length
	end
	if R.subChoice == 0 then -- left side
		if deletesWater then -- legacy version
			lib.leftSideLegacy(R.side, R.length, maxLength, R.height)
		else -- new version
			lib.side(R.side, R.length, maxLength, R.height)
		end
	else -- right side (1)
		if deletesWater then -- legacy version
			lib.rightSideLegacy(R.side, R.length, maxLength, R.height)
		else -- new version
			lib.side(R.side, R.length, maxLength, R.height)
		end
	end
	return {}
end

local function createCorridor(R) -- 52
	local lib = {}
	
	function lib.placeTorch(R, torchSpaces, totalSteps)
		if R.torchInterval > 0 then -- torches onboard
			if torchSpaces == R.torchInterval then -- time to place another torch
				if totalSteps < R.length then -- not at end of run
					if T:getItemSlot("minecraft:torch") > 0 then
						T:place("minecraft:torch", -1, "down")
					end
					torchSpaces = 1
				end
			end
		end
		return torchSpaces -- original value or 1
	end
	
	local currentSteps = 0					-- counter for infinite length. pause every 64 blocks
	local totalSteps = 0					-- counter for all steps so far
	local torchSpaces = R.torchInterval					-- if torches present, counter to place with 8 blocks between
	if T:getItemSlot("minecraft:torch") == 0 then
		R.torchInterval = 0 -- set to default 9 in getTask()
	end
	for steps = 1, R.length do
		if not R.silent then
			if currentSteps >= 64 and R.length == 0 then
				-- request permission to continue if infinite
				T:clear()
				print("Completed "..totalSteps..". Ready for 64 more")
				print("Do you want to continue? (y/n)")
				response = read()
				if response:lower() ~= "y" then
					break
				end
				currentSteps = 0
			end
		end
		T:go("C2U1C0", false, 0, true)
		torchSpaces = lib.placeTorch(R, torchSpaces, totalSteps) -- original value or 1 if torch placed
		T:go("F1D1", false, 0, true)
		currentSteps = currentSteps + 1
		totalSteps = totalSteps + 1
		torchSpaces = torchSpaces + 1
	end
	return {}
end

local function createRectanglePath(R) -- 83
	-- allow user to control length / width of each path
	-- T:go(path, useTorch, torchInterval, leaveExisting, preferredBlock)
	local lib = {}
	
	function lib.forward(R)
		if R.subChoice == 1 then
			for i = 1, R.length do
				T:go("F1x0C2", false, 0, true)
			end
		else
			for i = 1, R.length do
				T:go("F1U1C0D1C2", false, 0, true)
			end
		end
	end
	
	function lib.back(R)
		for i = 1, R.length do
			turtle.back()
		end
	end
	
	function lib.left(R)
		T:turnLeft(R.length)
	end
	
	function lib.right(R)
		T:turnRight(R.length)
	end
	
	function lib.up(R)
		if R.subChoice == 1 then
			T:go("U2R2 x1R2 D1C2", false, 0, true)
		else
			T:go("U2R2 x1R2C0 D1C2", false, 0, true)
		end
	end
	
	function lib.down()
		T:go("D1C2", false, 0, true)
	end
	
	if R.data == "menu" then
		local width = 0
		local length = 0
		local choices =
		{
			"Forward 1 block",
			"Forward # blocks: Type '2 #' Enter",
			"Back 1 block",
			"Back # blocks: Type '4 #' Enter",
			"Turn Right",
			"Turn Left",
			"Up 1 block",
			"Down 1 block",
			"Quit"
		}
		local choice, modifier
		while choice ~= 9 do
			choice, modifier = menu.new("Choose next step", choices)
			if modifier == "q" then
				return{"User has quit application"}
			end
			if choice == 1 then
				R.length = 1
				lib.forward(R)
			elseif choice == 2 then
				if modifier == nil then
					print("\nIncorrect entry. Use 2 <space> number")
					sleep(2)
				else
					R.length = modifier
					lib.forward(R)
				end
			elseif choice == 3 then
				R.length = 1
				lib.back(R)
			elseif choice == 4 then
				if modifier == nil then
					print("\nIncorrect entry. Use 4 <space> number")
					sleep(2)
				else
					R.length = modifier
					lib.back(R)
				end
			elseif choice == 5 then
				R.length = 1
				lib.right(R)
			elseif choice == 6 then
				R.length = 1
				lib.left(R)
			elseif choice == 7 then
				lib.up(R)
			elseif choice == 8 then
				lib.down()
			end
		end
	else
		local instructions = "f, b, l, r, u, d + num blocks\neg 'f' = forward 1, 'f10' = forward 10\nq to quit"
		local cmd = ""
		while cmd ~= "q" do
			T:clear()
			print(instructions)
			input = menu.getString("cmd: ", false, 1, 5):lower()
			-- remove spaces
			input = input:gsub( " ", "")
			cmd = input:sub(1,1)
			R.length = 1
			if #input > 1 then
				R.length = tonumber(input:sub(2))
			end
			if cmd == "q" then
				return{"User has quit application"}
			end
			if cmd == "f" then
				lib.forward(R)
			elseif cmd == "b" then
				lib.back(R)
			elseif cmd == "l" then
				lib.left(R)
			elseif cmd == "r" then
				lib.right(R)
			elseif cmd == "u" then
				lib.up(R)
			elseif cmd == "d" then
				lib.down()
			end
		end
	end
	return {}
end

local function createEnderTower(stage) -- 66
	--[[ lower base = stage 1, upper base = 2, tower = 3 ]]
	local lib = {}
	--[[ go(path, useTorch, torchInterval, leaveExisting, preferredBlock) ]]
	function lib.getEmptySlots()
		local empty = 0
		for i = 1, 16 do
			if turtle.getItemCount(i) == 0 then
				empty = empty + 1
			end
		end
		return empty
	end

	function lib.getStone(direction, stacks)
		--[[ get block user wants to use ]]
		local suck = turtle.suck	
		if direction == "down" then
			suck = turtle.suckDown
		end
		if T:getBlockType(direction) == "minecraft:chest" then
			T:sortInventory()
			local slot = T:getFirstEmptySlot() --find spare slot
			if slot > 0 then --empty slot found
				turtle.select(1)
				if stacks == 0 then
					while suck() do end
				else
					for i = 1, stacks do -- get # stacks of stone from chest
						suck()
					end
				end
				if T:getSlotContains(slot) == "" then
					return T:getMostItem()				-- empty chest
				else
					return T:getSlotContains(slot) 		-- use this as default building block
				end
			else
				return T:getMostItem()				-- full inventory
			end
		else
			return T:getMostItem()				-- no chest
		end
	end
	
	function lib.stackBuckets()
		local data = {}
		local bucketSlot = 0
		local emptySlots = 0
		local water = 0
		T:sortInventory()
		for i = 1, 16 do
			-- find first empty bucket
			if turtle.getItemCount(i) > 0 then
				data = turtle.getItemDetail(i)
				if data.name == "minecraft:bucket" then
					if bucketSlot == 0 then
						bucketSlot = i
					else
						turtle.select(i)
						turtle.transferTo(bucketSlot)
					end
				elseif data.name == "minecraft:water_bucket" then
					water = water + 1
				end
			else
				emptySlots = emptySlots + 1
			end
		end
		return emptySlots, water
	end
	
	function lib.countWaterBuckets()
		local data = {}
		local buckets = 0
		for i = 1, 16 do
			data = turtle.getItemDetail(i)
			if data.name == "minecraft:water_bucket" then
				buckets = buckets + 1
			end
		end
		return buckets
	end
	
	function lib.baseRun(preferredBlock, count, turn)
		for i = 1, count do
			T:go("C2F1", false, 0, false, preferredBlock)
		end
		T:go("C2"..turn, false, 0, false, preferredBlock)
	end
	
	function lib.outsideRun(preferredBlock)
		T:place("fence", -1, "down", false)
		T:forward(1)
		T:place(preferredBlock, -1, "down", false)
		T:forward(1)
		T:place(preferredBlock, -1, "down", false)
		T:forward(2)
		T:place(preferredBlock, -1, "down", false)
	end
	
	function lib.signRun(preferredBlock ,message)
		T:place(preferredBlock, -1, "down", false)
		T:forward(4)
		T:place(preferredBlock, -1, "down", false)
		turtle.back()
		turtle.back()
		T:down(1)
		T:place("sign", -1, "forward", false, message)
		T:go("U1F2")
	end
	
	function lib.goToWater(height)
		local built = 0 -- measures completed lift height
		while turtle.down() do -- takes turtle to bottom of water source
			height = height + 1
			if turtle.detect() then
				built = built + 1
			end
		end
		T:up(1) -- above watersource assuming it is 1-1.5 blocks deep
		height = height - 1
		-- built = built - 1 not required as next block is water source: not detected
		return built, height
	end
	
	function lib.fillBuckets(toBuild)
		local emptySlots, water = lib.stackBuckets() -- gets no of empty slots + no of water buckets
		if water < toBuild then -- no of water buckets onboard less than required quantity
			for i = 1, toBuild do -- fill required no of buckets up to max space in inventory
				emptySlots = lib.getEmptySlots()
				if emptySlots == 0 then -- inventory full
					break
				else
					if T:place("minecraft:bucket", -1, "down", false) then
						water = water + 1
						sleep(0.5)
					end
				end
			end
		end
		
		return water
	end
	
	function lib.buildLift(preferredBlock)
		local built = 0 -- measures completed lift height
		local height = 0 -- measures total height from starting position
		built, height = lib.goToWater(height) -- returns lift blocks already placed, total height of drop from starting point
		local toBuild = height - built -- no of blocks to increase lift size
		while toBuild > 0 do -- at least 1 block height remaining
			local water = lib.fillBuckets(toBuild) -- no of water buckets onboard (could be more than required)
			if water > toBuild then
				water = toBuild
			end
			while turtle.detect() do -- climb to top of existing lift
				turtle.up()
				height = height - 1
			end
			T:forward(1)
			for i = 1, water do -- build lift by no of water buckets
				if T:place("minecraft:water_bucket", -1, "forward", false) then
					T:up(1)
					height = height - 1
					toBuild = toBuild - 1
					T:place(preferredBlock, -1, "down", false)
				end
			end
			turtle.back()
			-- may still be some height to complete, but needs refill
			if toBuild > 0 then
				lib.goToWater(0) --return to source
				lib.fillBuckets(toBuild)
			end
		end
		if height > 0 then -- if any remaining distance
			T:up(height)
		end
		
	end
	
	function lib.buildSection(preferredBlock, solid)
		-- builds a section without any blocks in the centre
		-- second layer of each section end walls have fence posts
		T:go("F1C2 F2C2 F1R1", false, 0, false, preferredBlock) -- first side solid row
		if solid then -- first layer of each section
			T:go("F1C2 F1R1", false, 0, false, preferredBlock) -- top side solid row
		else
			T:go("F1") -- top side solid row
			if not T:place("fence", -1, "down", false) then-- first side
				T:place(preferredBlock, -1, "down", false)
			end
			T:go("F1R1") -- top side solid row
		end
		T:go("F1C2 F2C2 F1R1", false, 0, false, preferredBlock) -- far side solid row
		T:go("F1C2 F1R1U1", false, 0, false, preferredBlock) -- bottom side solid row
	end	
	--[[
		clsTurtle methods:
		clsTurtle.place(self, blockType, damageNo, direction, leaveExisting)
		clsTurtle.go(self, path, useTorch, torchInterval, leaveExisting, preferredBlock)
	]]
	-- remove 1 stack stone from chest
	local preferredBlock = lib.getStone("down", 1) -- use this as default building block
	if stage == 1 then
		-- build base floor
		--T:go("R2F2R1F3R1", false, 0, false, preferredBlock)
		T:go("R2F1C2R1F1C2F1C2F1C2R1", false, 0, false, preferredBlock)
		for i = 1, 2 do
			lib.baseRun(preferredBlock, 8, "R1F1R1")
			lib.baseRun(preferredBlock, 8, "L1F1L1")
			lib.baseRun(preferredBlock, 8, "R1F4R1")
		end
		-- move back to centre, build water source, with soul sand at base of first source
		--T:go("R1F3L1C2F1C2F2D1", false, 0, false, preferredBlock) --just behind chest, 1 below ground level
		T:go("R1F3L1F2C2F1D1", false, 0, false, preferredBlock) --1 block behind chest, 1 below ground level
		T:place("minecraft:soul_sand", -1, "down", false) -- over block 1 of water source
		T:go("F1C2F1C2", false, 0, false, preferredBlock) -- over block 2 of water source
		T:go("F1C2U1C2", false, 0, false, preferredBlock) -- over block 4 of water source
		T:go("F1C2F1C2R2F5R2", false, 0, false, preferredBlock) -- over block 1 of water source
		T:place("minecraft:water_bucket", -1, "down", false)
		T:forward(2) -- over block 3 of water source
		T:place("minecraft:water_bucket", -1, "down", false)
		turtle.back() -- over block 2 of water source
		T:place("minecraft:bucket", -1, "down", false)
		T:go("F2D1R2C2") -- over block 4 of water source
		T:go("U1", false, 0, false, preferredBlock)
		T:place("minecraft:water_bucket", -1, "down", false)
		T:forward(4)
		lib.stackBuckets() -- put all buckets in same slot
		T:dropItem("minecraft:dirt", "up", 0) -- drop dirt up:  clsTurtle.dropItem(self, item, direction, keepAmount)
		preferredBlock = lib.getStone("down", 6)
		T:go("R1F2R1U1") -- move to start position
		for i = 1, 2 do
			-- build first level of tower: 2 x outside run, 2 x sign run
			lib.outsideRun(preferredBlock)
			if i == 1 then -- place door
				T:go("L1F1L1F1L1D1")
				T:place("door", -1, "forward", false)
				T:go("U1L1F1R1F1L1")
			end
			T:go("R1F1R1")
			lib.signRun(preferredBlock, "Pint size\nzombies\nProhibited")
			T:go("L1F1L1C2", false, 0, false, preferredBlock)
			T:forward(4) -- miss out centre block
			T:place(preferredBlock, -1, "down", false)
			T:go("R1F1R1")
			lib.signRun(preferredBlock, "Pint size\nzombies\nProhibited")
			T:go("L1F1L1")
			lib.outsideRun(preferredBlock)
			if i == 1 then -- layer 1
				T:go("R1F1R1F1R1D1") -- place door
				T:place("door", -1, "forward", false)
				T:go("U1 R1F1 L1F5 L1U1 F2D1  F2R2 U1") -- go over door
			else -- layer 2
				T:go("L1F5L1F6R2U1") -- over corner of lower platform
			end
		end
		for i = 1, 2 do -- build both sides of platform, leave centre missing
			lib.baseRun(preferredBlock, 8, "R1F1R1")
			lib.baseRun(preferredBlock, 8, "L1F1L1")
			lib.baseRun(preferredBlock, 8, "R1F4R1")
		end
		T:go("R1F3L1C2F1C2F1C2F4C2F1C2F1C2", false, 0, false, preferredBlock) --fill in centre row
		--T:go("R2F6R1F1R1U1") -- go to start of tower base
		T:go("R2F7R2D3") -- go to start on top of chest
		T:sortInventory()
	elseif stage == 2 then
		-- start on top of chest, should have sufficient stone in inventory
		T:go("U3L1F1R1F1U1") -- go to start of tower base
		for i = 1, 7 do -- build 14 block high tower
			lib.buildSection(preferredBlock, false)
			lib.buildSection(preferredBlock, true)
		end
		T:go("R2F4R1F4R1", false, 0, false, preferredBlock) -- build upper platform (154 blocks remaining)
		for i = 1, 2 do -- build both sides of upper platform, leave centre missing
			lib.baseRun(preferredBlock, 12, "R1F1R1")
			lib.baseRun(preferredBlock, 12, "L1F1L1")
			lib.baseRun(preferredBlock, 12, "R1F1R1")
			lib.baseRun(preferredBlock, 12, "L1F1L1")
			lib.baseRun(preferredBlock, 12, "R1F6R1")
		end
		T:go("R1F5 L1C2 F1C2 F1C2 F1C2 F1C2 F4C2 F1C2 F1C2 F1C2 F1C2 ", false, 0, false, preferredBlock) --fill in centre row
		T:go("R2F5") -- return to drop area
		lib.buildLift(preferredBlock) -- build bubble lift
		T:go("F3R1F1R1U1") -- go to start of tower base
		T:go("C2F4 C2R1F1R1", false, 0, false, preferredBlock) 		-- left side layer 21
		T:go("F2C2 F2C2 L1F1L1", false, 0, false, preferredBlock) 	-- centre layer 21
		T:go("C2F4 C2R2U1", false, 0, false, preferredBlock) 		-- right side layer 21
		T:go("C2F4 C2R1F1R1", false, 0, false, preferredBlock) 		-- right side layer 22
		T:place("fence", -1, "down", false)							-- fence centre of bottom side layer 22
		T:go("F2C2 F2L1F1L1", false, 0, false, preferredBlock)		-- centre layer 22
		T:go("C2F4 C2R2F2L1F1R2D2", false, 0, false, preferredBlock) --ready to place ladder
		T:place("ladder", -1, "forward", false)
		T:up(1)
		T:place("ladder", -1, "forward", false)
		--T:go("U2R1F4R1F1R1") -- ready to make upper part of tower base
		T:go("U2R1F4R1F1R1") -- ready to make upper part of tower base
		for i = 1, 2 do -- build both sides of platform, leave centre missing
			lib.baseRun(preferredBlock, 8, "R1F1R1")
			lib.baseRun(preferredBlock, 8, "L1F1L1")
			lib.baseRun(preferredBlock, 8, "R1F4R1")
		end
		T:go("R1F3 L1C2 F1C2 F1C2 F1", false, 0, false, preferredBlock) --fill in centre row
		T:place("minecraft:soul_sand", -1, "down", false) 
		T:go("F1C2 F2C2 F1C2 F1C2", false, 0, false, preferredBlock)
		T:go("R2F6R1F1R1U1") -- go to start of tower base
		-- build 2 levels, finish signs and ladders
		T:go("C2F2 R1D2 U1", false, 0, false, preferredBlock)
		T:place("ladder", -1, "down", false)
		T:turnRight(1)
		T:place("sign", -1, "forward", false, "UP\n^\n|\n|")
		T:go("U1R2F2C2 R1F2C2 R1", false, 0, false, preferredBlock) --top right corner
		T:go("F4C2B2D1", false, 0, false, preferredBlock)
		T:place("sign", -1, "forward", false, "UP\n^\n|\n|")
		T:go("U1F2R1F1C2F1R1U1", false, 0, false, preferredBlock) --ready for second level
		T:go("C2F2 R2D1", false, 0, false, preferredBlock)
		T:place("sign", -1, "forward", false, "UP\n^\n|\n|")
		T:go("U1R2F2C2R1", false, 0, false, preferredBlock) --top left corner
		T:go("F1R1C2F4C2", false, 0, false, preferredBlock) --mid bottom row
		T:go("L1F1L1C2", false, 0, false, preferredBlock) -- bottom right corner
		T:go("F2R2D1", false, 0, false, preferredBlock)
		T:place("sign", -1, "forward", false, "UP\n^\n|\n|")
		T:go("U1R2F2C2", false, 0, false, preferredBlock) -- top right corner
		-- return to chest
		T:go("L1F1L1 F5D23R2", false, 0, false, preferredBlock) -- return to chest
		T:sortInventory()
	elseif stage == 3 then
		--[[ move to top of structure
		| 4 |
		|3 5|
		| X |
		|2 6|
		| 1 |
		]]
		local towerHeight = 128 -- even no only suggest 128
		while turtle.detect() do
			turtle.up()
		end
		T:go("F1U1", false, 0, false, preferredBlock) -- return to finish tower
		for i = 1, towerHeight do -- 1
			T:go("C2U1", false, 0, false, preferredBlock)
		end
		T:go("F1L1F1R1D2")
		while turtle.down() do -- 2
			T:fillVoid("up", {preferredBlock})
		end
		T:go("F1R2C1R2F1D1", false, 0, false, preferredBlock)
		for i = 1, towerHeight / 2 do -- 3
			T:go("U2C2", false, 0, false, preferredBlock)
		end
		T:go("U1F1R1F1R1D1", false, 0, false, preferredBlock) -- back of tower facing front
		local deviate = false
		while turtle.down() do -- 4
			T:place("fence", -1, "up", false)
			if turtle.down() then
				T:fillVoid("up", {preferredBlock})
			else
				T:go("F1R2C1R1F1R1D1", false, 0, false, preferredBlock)
				deviate = true
				break
			end
		end
		if not deviate then
			T:go("F1L1F1R1D1", false, 0, false, preferredBlock)
		end
		for i = 1, towerHeight / 2 do -- 5
			T:go("U2C2", false, 0, false, preferredBlock)
		end
		T:go("F2R2", false, 0, false, preferredBlock) -- facing back of tower
		while turtle.down() do -- 6
			T:fillVoid("up", {preferredBlock}) --layer 129
		end
		T:go("F1L2C1U"..towerHeight)
		T:go("F4R1F3R1U1", false, 0, false, preferredBlock)
		-- add small platform at the top
		lib.baseRun(preferredBlock, 8, "R1F1R1")
		lib.baseRun(preferredBlock, 8, "L1F3L1")
		lib.baseRun(preferredBlock, 8, "L1F1L1")
		lib.baseRun(preferredBlock, 8, "R1F1R1")
		T:go("C2 F1C2 F1C2 F4C2 F1C2 F1C2 R2F3", false, 0, false, preferredBlock) --fill in centre row
		lib.buildLift(preferredBlock) -- build bubble lift
	end
	return {}
end

local function createFarm(extend) -- 31
	-- if extend ~= nil then this has been called from createFarmExtension()
	-- 
	lib = {}
	function lib.addWaterSource(pattern)
		-- pattern = {"d","c","c","d"} t = place crafting  instead of dirt
		-- place(self, blockType, damageNo, direction, leaveExisting, signText)
		T:go("D1x2C2")
		for i = 1, 4 do
			T:dig("forward")
			if pattern[i] == "d" then
				T:place("dirt", -1, "forward", false)
			elseif pattern[i] == "t" then
				if not T:place("minecraft:crafting_table", -1, "forward", false) then
					T:place("dirt", -1, "forward", false) -- dirt if no crafting table
				end
			else
				T:place("stone", -1, "forward", false)
			end
			T:turnRight(1)
		end
		T:up(1)
		T:place("minecraft:water_bucket", -1, "down")
	end
	
	function lib.placeDirt(count, atCurrent)
		if atCurrent then
			local blockType = T:getBlockType("down")
			if blockType:find("dirt") == nil and blockType:find("grass_block") == nil then
				T:place("dirt", -1, "down", false)
			end
		end
		for  i = 1, count do
			T:forward(1)
			T:dig("up")
			local blockType = T:getBlockType("down")
			if blockType:find("dirt") == nil and blockType:find("grass_block") == nil then
				T:place("dirt", -1, "down", false)
			end
		end
	end
	
	-- extend "", "right" or "forward". only adds a single new farm.
	-- right adds farm and checks for existing front extensions, dealt with separately
	-- clsTurtle.place(blockType, damageNo, direction, leaveExisting)
	if extend == nil then
		extend = ""
	end
	local blockType = ""
	-- extend = "right": placed on cobble corner of existing farm facing right side
	-- extend = "front": placed on cobble corner of existing farm facing front
	-- else placed on ground at corner of potential new farm facing front
	
	-- step 1 dig ditch round perimeter wall
	if extend == "right" then
		-- move to front corner ground ready for ditch
		T:go("F1L1F12D1R1")
		-- cut ditch round new farm extension
		for i = 1, 12 do
			T:go("x0F1")
		end
		T:go("R1x0")
		for i = 1, 13 do
			T:go("x0F1")
		end
		T:go("R1x0")
		-- now at lower right corner. if extension below, do not cut ditch
		blockType = T:getBlockType("forward")
		if blockType:find("stone") ~= nil then -- already a farm extension on left side
			-- return to start for adding chests and walls
			T:go("U1R1F1L1F12")
		else -- finish ditch
			for i = 1, 12 do
				T:go("x0F1")
			end
			T:go("R1U1F1") -- on corner of new extension
		end
	elseif extend == "forward" then
		T:go("L1F2R1D1")
		-- cut ditch round new farm extension
		for i = 1, 12 do
			T:go("x0F1")
		end
		T:go("R1x0")
		for i = 1, 13 do
			T:go("x0F1")
		end
		T:go("R1x0")
		for i = 1, 11 do
			T:go("x0F1")
		end
		T:go("U1x0F1R1F12R1") -- on corner of new extension
	else -- new farm. cut a groove round the entire farm base
		-- move to left side of intended wall
		T:go("L1F1x0R1")
		for j = 1, 4 do
			for i = 1, 12 do
				T:go("x0F1")
			end
			T:go("R1x0F1")
		end
		T:go("R1F1L1U1")
	end
	-- stage 2 place sapling and double chest
	T:dig("down") --remove cobble if present
	T:place("dirt", -1, "down", false)
	T:go("F1R2")
	T:place("sapling", -1, "forward", false) -- plant sapling
	T:go("L1")
	T:dig("down")
	T:place("minecraft:chest", -1, "down", false)-- place chest below
	T:go("L1F1R1")
	T:dig("down")
	T:place("minecraft:chest", -1, "down", false) -- place chest 2 below
	T:turnLeft(1)
	if extend == "right" then -- cobble wall exists so go forward to its end
		T:forward(9)
	else -- new farm or extend forward
		for i = 1, 9 do -- complete left wall to end of farm
			T:go("F1x0x2C2")
		end
	end
	T:go("R1F1R1x0x2C2F1D1")-- turn round ready for first dirt col
	lib.addWaterSource({"d","c","c","d"}) -- water at top of farm
	lib.placeDirt(9, false) -- place dirt back to start
	lib.addWaterSource({"c","c","t","d"}) -- water source next to chests, includes crafting table
	T:go("U1F1R2")
	if T:getBlockType("down") ~= "minecraft:chest" then
		T:dig("down")
		T:place("minecraft:chest", -1, "down", false)
	end
	T:go("R1F1L1")
	if T:getBlockType("down") ~= "minecraft:chest" then
		T:dig("down")
		T:place("minecraft:chest", -1, "down", false)
	end
	T:go("F1D1")
	lib.placeDirt(9, true)
	local turn = "R"
	for i = 1, 7 do
		T:go("F1U1x0C2"..turn.."1F1"..turn.."1x0x2C2F1D1")
		lib.placeDirt(9, true)
		if turn == "R" then
			turn = "L"
		else
			turn = "R"
		end
	end
	T:go("F1U1x0C2"..turn.."1F1"..turn.."1x0x2C2F1D1")
	lib.addWaterSource({"d","c","c","d"})
	lib.placeDirt(9, false)
	lib.addWaterSource({"c","c","d","d"})
	T:go("F1U1R1C2x0F1x0x2C2R1")
	for i = 1, 11 do
		T:go("F1x0x2C2")
	end
	-- add chest to any existing farm extension to the right
	T:go("L1F1L1")
	if T:getBlockType("down") ~= "minecraft:cobblestone" then -- farm extension already exists to right
		T:place("minecraft:chest", -1, "down", false) --single chest marks this as an extension
	end
	T:go("L1F11")
	return {}
end

local function createFarmExtension(R) -- 32
	-- assume inventory contains 4 chests, 64 cobble, 128 dirt, 4 water, 1 sapling
	-- check position by rotating to face tree/sapling
	local doContinue = true
	local treePresent = false
	local blockType = T:getBlockType("down")
	local extend = "right" -- default
	if R.subChoice == 1 then
		extend = "forward"
	end
	if blockType ~= "minecraft:chest" then
		return
		{
			"Chest not present below\n",
			"Unable to calculate position",
			"Move me next to/front of the tree/sapling",
			"lower left corner of the existing farm."
		}
	else
		for i = 1, 4 do
			blockType = T:getBlockType("forward")
			if blockType:find("log") ~= nil or blockType:find("sapling") ~= nil then
				treePresent = true
				break
			end
			T:turnRight()
		end
		if not treePresent then
			return
			{
				"Unable to locate tree or sapling",
				"Plant a sapling on the lower left",
				"corner of the farm, or move me there"
			}
		end
	end
	if doContinue then -- facing tree. check if on front or l side of farm
		if extend == "forward" then
			T:go("R1F11") -- to other side of farm. may be stone or chest below
			blockType = T:getBlockType("down")
			if blockType:find("chest") ~= nil then
				doContinue = false
			end
		else
			T:go("R2F9") -- to right of farm, may be sapling/tree in front
			blockType = T:getBlockType("forward")
			if blockType:find("log") ~= nil or blockType:find("sapling") ~= nil then
				doContinue = false
			end
		end
		if doContinue then -- extend farm.
			createFarm(extend)
		else
			return
			{
				"This farm has already been extended",
				"Move me next to/front of the tree / sapling",
				"of the last extension in this direction."
			}
		end
	end
	return {"Mob Farm Extended"}
end

local function createFloorCeiling(R) -- 79 size integer 1 to 4
	--[[
	R.up = true for ceiling
	R.down = true for floor
	R.height = 0 for normal
	R.height combined with R.up/R.down used for remote access
	]]
	
	local useBlock = T:getSlotContains(1)
	print("Using ".. useBlock)
	local direction = "down"
	if R.up then
		direction = "up"
	end
	if R.height > 0 then -- remote placing. go up/down R.height first
		R.silent = true
		local depth = 0
		if R.down then -- floor could be under water
			while turtle.down() do
				depth = depth + 1
			end
		elseif R.up then
			while turtle.up() do
				depth = depth + 1
				if depth > R.height + 3 then
					break
				end
			end
		end
		if not(R.height - depth <= 2 or depth - R.height <= 2) then
			T:up(depth)
			return {"Measured depth/height of "..depth.." > setting: "..R.height}
		end
		-- not returned so depth acceptable
	end
	-- check if block above/below
	local blockBelow = turtle.detectDown()
	local blockAbove = turtle.detectUp()
	if R.subChoice == 2 then -- New floor over existing
		-- if no block below, assume in correct position and continue
		-- else move up 1 and continue
		if blockBelow then T:up(1) end
	elseif R.subChoice == 4 then -- New ceiling under existing
		-- if no block above, assume in correct position and continue
		-- else move down 1 and continue
		if blockAbove then T:down(1) end
	end
	
	local evenWidth = false
	local evenHeight = false
	local loopWidth
	-- go(path, useTorch, torchInterval, leaveExisting)
	if R.width % 2 == 0 then
		evenWidth = true
		loopWidth = R.width / 2
	else
		loopWidth = math.ceil(R.width / 2)
	end
	if R.length % 2 == 0 then
		evenHeight = true
	end
	-- if R.width is even no, then complete the up/down run
	-- if R.width odd no then finish at top of up run and reverse
	for x = 1, loopWidth do
		-- Clear first column (up)
		local tAvailable = T:getStock(useBlock, -1)
		if tAvailable.total < R.length and not R.silent then
			return {"Insufficient resources to complete current row"}
		end
		for y = 1, R.length do
			T:place(useBlock, -1, direction, false) -- leaveExisting = false
			if y < R.length then
				T:go("F1", false, 0, false)
			end
		end
		-- clear second column (down)
		if x < loopWidth or (x == loopWidth and evenWidth) then -- go down if on R.width 2,4,6,8 etc
			T:go("R1F1R1", false,0,false)
			tAvailable = T:getStock(useBlock, -1)
			if tAvailable.total < R.length and not R.silent then
				return {"Insufficient resources to complete current row"}
			end
			for y = 1, R.length do
				T:place(useBlock, -1, direction, false) -- leaveExisting = false
				if y < R.length then
					T:go("F1", false, 0, false)
				end
			end
			if x < loopWidth then 
				T:go("L1F1L1", false,0,false)
			else
				T:turnRight(1)
				T:forward(R.width - 1)
				T:turnRight(1)
			end
		else -- equals R.width but is 1,3,5,7 etc
			T:turnLeft(2) --turn round 180
			T:forward(R.length - 1)
			T:turnRight(1)
			T:forward(R.width - 1)
			T:turnRight(1)
		end
	end
	return {}
end

local function createIceCanal(R) -- 56
	-- R.subChoice = 1:towpath with torces, 2:ice canal, 3:3 block air space, 4:towpath without torches
	local lib = {}
	
	function lib.iceCanalTowpath(side, length, withTorch)
		-- assume on ground level start
		-- side = R or L
		local level = lib.getLevel() -- ground level: 1, eye level 2
		redstone.setOutput("bottom", true)
		-- move forward placing slabs etc
		local facing = "forward"
		local success = true
		if withTorch then
			local torchBlocks = 9
			local addTorch = true
			for i = 1, length do
				success, facing, level = lib.iceCanalEdge(level, facing, side, addTorch)
				if not success then
					return {"Out of resources"}
				end
				torchBlocks = torchBlocks - 1
				addTorch = false
				if torchBlocks == 0 then
					torchBlocks = 9
					addTorch = true
				end
			end
		else
			for i = 1, length do
				success, facing, level = lib.iceCanalEdge(level, facing, side)
				if not success then
					return {"Out of resources"}
				end
			end
		end
		if facing == "back" then
			T:turnRight(2)
		end
		return {}
	end
	
	function lib.iceCanalEdge(level, facing, side, addTorch)
		local success = false
		local turn = side
		local turnBack = ""
		if side == "R" then turnBack = "L" end
		if side == "L" then turnBack = "R" end
		
		local blockType = T:getBlockType("down")	-- ? at ground/water level or on top of existing slab/trapdoor
		if level == 1 then
			T:dig("up")
		elseif level == 2 then
			T:down(1)
			level = 1
		end
		
		-- level 2 if on top of slab/trapdoor
		if blockType:find("slab") == nil and blockType:find("trapdoor") == nil then -- no existing path created
			utils.clearVegetation("down")
			local isWater, isSource, isIce = T:isWater("down")
			if isWater or blockType == "" then -- on air/water, so move forward, turn round, place slab
				if facing == "back" then	-- already facing backwards from last slab placement
					if not turtle.back() then -- air/water below, but unable to move back eg block present
						T:go("R2F1R2")
					end
				elseif facing == "forward" then
					facing = "back"
					T:go("F1R2")
				end
				if addTorch then
					T:place("stone", -1, "forward", true)
					if T:getItemSlot("minecraft:torch", -1) > 0 then
						T:up(1)
						T:place("torch", -1, "forward", false)
						T:down(1)
					end
					success = true
				else
					if T:place("slab", -1, "forward", false) then
						success = true
					else
						turtle.forward()
					end
				end
				level = 1
			else -- solid block so place slab/trapdoor
				if facing == "back" then
					T:turnRight(2)
					facing = "forward"
				end
				T:up(1)	-- now at eye level(2)
				local ceiling = turtle.detectUp()
				if ceiling then
					T:go(turn.."1x2")
					if T:place("trapdoor", -1, "down", false) then-- add trapdoors to canal towpath and activate them
						success = true
					end
					T:go(turnBack.."1")
				else
					if T:place("slab", -1, "down", false) then
						success = true
					end
				end
				if addTorch then
					T:go("R2")
					if T:place("torch", -1, "forward", false) then
						T:go("R2F1")
					else
						if ceiling then
							T:go("R2F1")
						else
							-- go(path, useTorch, torchInterval, leaveExisting, preferredBlock)
							T:go("C2U1R2", false, 0, false)
							T:place("torch", -1, "down", false)
							T:go("F1D1")
						end
					end
				else
					T:go("F1")
				end
				level = 2
			end
		else -- do nothing as slab/trapdoor already present
			T:forward(1)
		end
		
		return success, facing, level
	end
	
	function lib.iceCanalCentreLeft(length)
		local placeIce = true
		local iceOnBoard = true
		local isWater, isSource, isIce = T:isWater("forward")
		if isWater then -- user put turtle inside canal water
			T:up(1)
		end
		-- place ice on alternate blocks until length reached, run out of ice or hit a solid block.
		
		for i = 1, length do
			if T:getBlockType("down"):find("ice") == nil then -- no ice below
				if placeIce then
					if not T:place("ice", -1, "down", true) then -- out of ice
						break
					end
					if i == length - 1 then
						break
					end
				else
					T:dig("down") -- remove any other block
				end
			else -- ice already below
				placeIce = true
			end
			if turtle.digUp() then
				T:go("U1x0D1")
			end
			T:forward(1)
			placeIce = not placeIce -- reverse action
		end
	end
	
	function lib.iceCanalCentreRight(length)
		-- dig up/down/forward to clear space
		for i = 1, length do
			if turtle.digUp() then
				T:go("U1x0D1")
			end
			T:go("x2F1")
		end
	end
	
	function lib.getLevel()
		local blockType = T:getBlockType("down")
		if blockType:find("slab") ~= nil or blockType:find("trapdoor") ~= nil then
			return 2
		elseif blockType:find("water") ~= nil or blockType:find("ice") ~= nil or blockType == "" then
			return 1
		end
	end
	
	function lib.initialise()
		utils.clearVegetation("down")
		local isWater, isSource, isIce = T:isWater("down")
		while not isWater and not isIce do
			if not turtle.down() then
				break
			end -- move to ground/water: canal edge / slab / trapdoor
			isWater, isSource, isIce = T:isWater("down")
		end
	end
	
	if R.length == 0 then R.length = 1024 end
	
	if R.subChoice == 1 then
		lib.initialise()
		return lib.iceCanalTowpath("R", R.length, true)	-- left side, with torches
	elseif R.subChoice == 2 then
		lib.iceCanalCentreLeft(R.length)			-- place ice
	elseif R.subChoice == 3 then
		lib.iceCanalCentreRight(R.length)			-- clear 3 high area
	elseif R.subChoice == 4 then
		lib.initialise()
		return lib.iceCanalTowpath("L", R.length, false)	-- right side, no torches
	end
	
	return {}
end

local function createIceCanalBorder(R) -- 510
	--[[ Used to convert water canal to ice with trapdoor / slab margin on one side ]]
	-- position gained from setup left = 0, right = 1
	local lib = {}
	
	function lib.placeTrapdoor()
		if T:getBlockType("down"):find("trapdoor") == nil then
			T:place("trapdoor", -1, "down", false) -- add trapdoors to canal towpath and activate them
		end
		return false
	end
	
	function lib.placeSlab()
		if T:getBlockType("down"):find("slab") == nil then
			T:place("slab", -1, "down", false)
		end
		return true
	end
	
	function lib.placeTorch(torchBlocks, onWater)
		if T:getItemSlot("minecraft:torch", -1) > 0 then
			if torchBlocks == 8 and onWater then
				-- T:fillVoid(direction, tblPreferredBlock, leaveExisting)
				T:fillVoid("down", {}, false)
				T:up(1)
				T:place("minecraft:torch", -1, "down", false)
				T:go("F1D1")
				torchBlocks = 0
			elseif torchBlocks == 9 and not onWater then
				T:go("R2")
				T:place("minecraft:torch", -1, "forward", false)
				T:go("L2")
				torchBlocks = 0
			end
		end
		return torchBlocks
	end
	
	local A = "R"
	local B = "L"
	if R.subChoice == 1 then
		A = "L"
		B = "R"
	end
	-- check position. Should be facing down canal with wall on same side
	-- so wall will be detected on i = 4 (if present)
	local turns = 0
	--local wallFound = false
	local numBlocks = 0
	if R.length == 0 then
		R.length = 2048
	end
	local isWater, isSource, isIce = T:isWater("down")
	while not isWater and not isIce do
		if not turtle.down() then
			break
		end -- move to ground -- canal edge / slab / trapdoor
		isWater, isSource, isIce = T:isWater("down")
	end
	local onWater = false
	local torchBlocks = 8	-- force torch placed on first block
	-- check if slab / trapdoor below
	blockType = T:getBlockType("down")
	if blockType:find("slab") ~= nil then
		onWater = true
	elseif blockType:find("trapdoor") ~= nil then
		onWater = false
		torchBlocks = 9
	elseif blockType:find("slab") == nil and blockType:find("trapdoor") == nil then -- not on existing slab / trapdoor
		T:up(1)
		if turtle.detectUp() then -- ceiling present: tunnel
			torchBlocks = 9
		else
			onWater = true
		end
	end
	redstone.setOutput("bottom", true)
	-- add trapdoors to canal towpath and activate them
	for i = 1, R.length do
		if torchBlocks >= 8 then
			torchBlocks = lib.placeTorch(torchBlocks, onWater)
		end
		--T:go(A.."1x2")
		if turtle.detectUp() then -- ceiling present: inside tunnel
			T:go(A.."1x2")
			onWater = lib.placeTrapdoor()
			T:go(B.."1F1")
		else
			onWater = lib.placeSlab()
			T:forward(1)
		end
		--T:go(B.."1F1")
		numBlocks = numBlocks + 1
		torchBlocks = torchBlocks + 1
		if T:getItemSlot("trapdoor", -1) == 0 or T:getItemSlot("slab", -1) == 0 then
			print("Out of slabs / trapdoors")
			break
		end
	end
	return {numBlocks}
end

local function createLadder(destination, level, destLevel) -- 12
	-- createLadder("bedrock", 70, -48)
	-- go(path, useTorch, torchInterval, leaveExisting)
	-- place(blockType, damageNo, direction, leaveExisting)
	local retValue = {}
	local function placeLadder(direction, ledge)
		-- 1 check both sides and behind
		local fluid = false
		local block = T:isWaterOrLava("forward", ledge)
		if block:find("water") ~= nil or block:find("lava") ~= nil then
			--[[ surround 2 block shaft with blocks ]]
			T:go("R1C1R1C1R1C1R1F1L1C1R1C1R1C1R1C1F1R2C1x1")
		else
			--[[ no water/lava so prepare ladder site]]
			T:go("F1L1C1R1C1R1C1L1B1", false, 0, true)
		end
		if not T:place("minecraft:ladder", -1, "forward", false) then
			print("Out of ladders")
			turtle.forward()
			error()
		end
		-- 3 check if ledge, torch
		if ledge == 0 then
			T:place("common", -1, direction, false) -- any common block
		elseif ledge == 1 then
			T:place("minecraft:torch", -1, direction, false)
		elseif ledge == 2 then
			ledge = -1
		end
		return ledge
	end
	
	local ledge = 0
	local height = math.abs(destLevel - level) --height of ladder
	if destination == "surface" then -- create ladder from current level to height specified
		-- check if extending an existing ladder
		for i = 1, height do -- go up, place ladder as you go
			ledge = placeLadder("down", ledge)
			T:up(1)
			ledge = ledge + 1
		end		
	else -- ladder towards bedrock		
		local success = true
		local numBlocks, errorMsg
		for i = 1, height do -- go down, place ladder as you go
			ledge = placeLadder("up", ledge)
			--success, blocksMoved, errorMsg, blockType = clsTurtle.down(self, steps, getBlockType)
			success, numBlocks, errorMsg, blockType = T:down(1, true)
			ledge = ledge + 1
			-- if looking for stronghold then check for stone_bricks 
			if blockType:find("stone_bricks") ~= nil then
				table.insert(retValue, "Stronghold discovered")
				break
			end
		end
		if not success then --success = false when hits bedrock
			-- test to check if on safe level immediately above tallest bedrock
			table.insert(retValue, "Bedrock reached")
			T:findBedrockTop(0)
			-- In shaft, facing start direction, on lowest safe level
			-- create a square space round shaft base, end facing original shaft, 1 space back
			T:go("L1n1R1n3R1n2R1n3R1n1", false, 0, true)
			T:go("U1Q1R1Q3R1Q2R1Q3R1Q1", false, 0, true)
		end
		
	end
	
	return retValue
end

local function createLadderToWater() -- 86
	-- go down to water/lava with alternaate solid/open layers
	-- create a working area at the base
	-- Return to surface facing towards player placing ladders
	local inAir = true
	local numBlocks, errorMsg
	local block, blockType
	local height = 2
	T:go("R2D2", false, 0, true) -- face player, go down 2
	while inAir do --success = false when hits water/lava
		T:go("C1R1C1R2C1R1", false, 0, true)
		T:go("D1C1", false, 0, true)
		height = height + 1
		block, blockType = T:isWaterOrLava("down")
		if string.find(block, "water") ~= nil or string.find(block, "lava") ~= nil then
			inAir = false
		else
			T:down(1)
			height = height + 1
		end
	end
	-- In shaft, facing opposite start direction, on water/lava
	-- create a square space round shaft base, end facing original shaft, 1 space back
	T:go("R2C2F1C2F1C2R1", false, 0, true)
	T:go("F1C2F1C2R1", false, 0, true)
	T:go("F1C2F1C2F1C2F1C2R1", false, 0, true)
	T:go("F1C2F1C2F1C2F1C2R1", false, 0, true)
	T:go("F1C2F1C2F1C2F1C2R1", false, 0, true)
	T:go("F2R1F1", false, 0, true) -- under the upward pillar

	for i = height, 0, -1 do
		T:go("C2e1U1")
	end
	T:down(1)
	return {}
end

local function createMine() -- 11
	-- go(path, useTorch, torchInterval, leaveExisting, preferredBlock)
	T:clear()	
	T:go("m32U1R2M16", true, 8, true) -- mine ground level, go up, reverse and mine ceiling to mid-point
	T:go("U2D2") -- create space for chest
	T:place("minecraft:chest", -1, "up", false)
	T:emptyTrash("up")
	T:go("D1R1m16U1R2M16", true, 8, true) -- mine floor/ceiling of right side branch
	T:emptyTrash("up")
	T:go("D1m16U1R2M16", true, 8, true) -- mine floor/ceiling of left side branch
	T:emptyTrash("up")
	T:go("L1M15F1R1D1", true, 8, true) -- mine ceiling of entry coridoor, turn right
	T:go("F1x0F1x0n14R1n32R1n32R1n32R1n14F1x0F1U1", true, 8, true)-- mine floor of 36 x 36 square coridoor
	T:go("R1F16R2") --return to centre
	T:emptyTrash("up")
	T:go("F16R1") --return to entry shaft
	T:go("F2Q14R1Q32R1Q32R1Q32R1Q14F2R1", true, 8, true) --mine ceiling of 36x36 square coridoor. return to entry shaft + 1
	T:go("F16R2") --return to centre
	T:emptyTrash("up")
	-- get rid of any remaining torches
	while T:getItemSlot("minecraft:torch", -1) > 0 do
		turtle.select(T:getItemSlot("minecraft:torch", -1))
		turtle.dropUp()
	end
	T:go("F16R1F1R1") --return to shaft + 1
	for i = 1, 8 do
		T:go("N32L1F1L1", true, 8, true)
		T:go("N16L1F"..(i * 2).."R2", true, 8, true)
		T:emptyTrash("up")
		if i < 8 then
			T:go("F"..(i * 2).."L1N16R1F1R1", true, 8, true)
		else
			T:go("F"..(i * 2).."L1N16L1", true, 8, true)
		end
	end
	T:go("F17L1") -- close gap in wall, return to ladder + 1
	for i = 1, 8 do
		T:go("N32R1F1R1", true, 8, true)
		T:go("N16R1F"..(i * 2).."R2", true, 8, true)
		T:emptyTrash("up")
		if i < 8 then
			T:go("F"..(i * 2).."R1N16L1F1L1", true, 8, true)
		else
			T:go("F"..(i * 2).."R1N16R1", true, 8, true)
		end
	end
	T:go("F16R1")
	T:clear()
	return{"Mining operation complete"}
end

local function createMineBase()
	T:clear()
	-- check ladder:
	T:turnRight(2)
	local blockType, modifier = T:getBlockType("forward")
	while blockType == "" do
		T:forward(1)
		blockType, modifier = T:getBlockType("forward")
	end
	if blockType ~= "minecraft:ladder" then -- in correct position
		-- no ladder, move back 1
		T:back(1)
	end
	-- build pond:
	T:go("R1F1x0L1F1x0F1x0R1") -- at side wall
	T:go("F1n4R2n4U1R2Q4R2Q4R2") -- cut pond 3x1
	T:go("C2F4C2R2F1")
	T:place("minecraft:water_bucket", 0, "down", false)
	T:forward(2)
	T:place("minecraft:water_bucket", 0, "down", false)
	T:go("F2L1F2R1F1L1") -- at start position
	--[[
	T:go("m32U1R2M16D1", true, 8) -- mine ground level, go up, reverse and mine ceiling to mid-point, drop to ground
	T:go("U1R1A15D1R2m15", false, 0) -- Create roof of coridoor, turn and create lower wall + floor
	T:go("U1A15D1R2m15U1x0", false, 0) -- Create roof of coridoor, turn and create lower wall + floor
	T:place("minecraft:chest", -1, "up", false) --place chest in ceiling
	T:emptyTrash("up")
	T:go("L1M15F1R1D1", true, 8) -- mine ceiling of entry coridoor, turn right, drop down
	T:go("F2n14R1n15", true, 8)-- mine floor of first quarter of square
	T:go("L1F1x0C1R1 F1x0L1C1R1 F1x0L1C1R1C1R1 F1x0C1L1") -- make alcove
	T:go("F1x0n14R1n32R1n15", true, 8)
	T:go("L1F1x0C1R1 F1x0L1C1R1 F1x0L1C1R1C1R1 F1x0C1L1") -- make alcove
	T:go("F1x0n14R1n14F2", true, 8)-- mine floor of last quarter of square
	
	T:go("U1R1F16R2D1") --return to centre
	T:emptyTrash("up")
	T:go("U1F16R1") --return to entry shaft
	T:go("F2Q14R1Q15", true, 8) -- mine ceiling of first quarter
	T:go("L1F1C1R1 F1L1C1R1 F1L1C1R1C1R1 F1C1L1") -- make alcove
	T:go("C0F1Q14R1Q32R1Q15", true, 8) --mine ceiling of second half
	T:go("L1F1C1R1 F1L1C1R1 F1L1C1R1C1R1 F1C1L1") -- make alcove
	T:go("C0F1Q14R1Q14F2R1", true, 8) -- mine ceiling of last quarter
	T:go("F16D1") --return to centre
	T:emptyTrash("up")
	-- get rid of any remaining torches
	while T:getItemSlot("minecraft:torch", -1) > 0 do
		turtle.select(T:getItemSlot("minecraft:torch", -1))
		turtle.dropUp()
	end
	
	for i = 1, 8 do
		T:go("N32L1F1L1", true)
		T:go("N16L1F"..(i * 2).."R2", true)
		T:emptyTrash("up")
		T:go("F"..(i * 2).."L1N16R1F1R1", true)
	end
	T:go("L1F17L1") -- close gap in wall, return to ladder + 1
	for i = 1, 8 do
		T:go("N32R1F1R1", true)
		T:go("N16R1F"..(i * 2).."R2", true)
		T:emptyTrash("up")
		T:go("F"..(i * 2).."R1N16L1F1L1", true)
	end
	-- fill water buckets
	-- return to centre
	T:go("R1F16R1")]] 
	
	T:clear()
	return {"Mining operation complete"}
end

local function createMineEnhanced()
	T:clear()	
	T:go("m32U1R2M16D1x2", true, 8) -- mine ground level, go up, reverse and mine ceiling to mid-point, drop to ground, excavate
	T:emptyTrash("down")
	T:go("U1R1A15D1R2E13m2x2", false, 0) -- Create roof of coridoor, turn and create lower wall + remove floor
	T:emptyTrash("down")
	T:go("U1A15D1R2E13m2x2", false, 0) -- Create roof of coridoor, turn and create lower wall + remove floor
	T:emptyTrash("down")
	T:go("U1L1M15F1R1D1", true, 8) -- mine ceiling of entry coridoor, turn right, drop down
	T:go("F2n14R1n15", true, 8)-- mine floor of first quarter of square
	
	T:go("L1F1x0C1R1 F1x0L1C1R1 F1x0L1C1R1C1R1 F1x0C1L1") -- make alcove
	T:go("F1x0n14R1n32R1n15", true, 8)
	T:go("L1F1x0C1R1 F1x0L1C1R1 F1x0L1C1R1C1R1 F1x0C1L1") -- make alcove
	T:go("F1x0n14R1n14F2", true, 8)-- mine floor of last quarter of square
	T:go("U1R1F16R2D1") --return to centre
	T:emptyTrash("down")
	T:go("U1F16R1") --return to entry shaft
	T:go("F2Q14R1Q15", true, 8) -- mine ceiling of first quarter
	T:go("L1F1C1R1 F1L1C1R1 F1L1C1R1C1R1 F1C1L1") -- make alcove
	T:go("C0F1Q14R1Q32R1Q15", true, 8) --mine ceiling of second half
	T:go("L1F1C1R1 F1L1C1R1 F1L1C1R1C1R1 F1C1L1") -- make alcove
	T:go("C0F1Q14R1Q14F2R1", true, 8) -- mine ceiling of last quarter
	T:go("F16D1") --return to centre
	T:emptyTrash("down")
	-- get rid of any remaining torches
	while T:getItemSlot("minecraft:torch", -1) > 0 do
		turtle.select(T:getItemSlot("minecraft:torch", -1))
		turtle.dropDown()
	end
	--cut access coridoors
	T:go("U1F2R1F1Q14F1 R1F1L1F1R1F2R1F1L1F1R1 F1Q14F2Q14F1 R1F1L1F1R1F2R1F1L1F1R1F1 Q14F1D1") --ceiling
	T:go("F1n14F1 R1F1L1F1R1F2R1F1L1F1R1 F1n14F2n14F1 R1F1L1F1R1F2R1F1L1F1R1F1 n14F1U1") --floor, then up
	T:go("R1F2D1")
	T:go("R1F1C1B1C1L1C1L1F1C1B1C1L1C1L2")
	T:emptyTrash("down")
	T:go("U1F16R1F1R1") --return to entry shaft + 1

	for i = 1, 8 do
		T:go("N32L1F1L1", true)
		if i == 1 then
			T:go("N16L1F2R2", true)
			T:emptyTrash("down")
			T:go("F2L1N16R1F1R1", true)
		elseif i == 8 then
			T:go("L1F1R1N16", true)
			T:emptyTrash("down")
			T:go("N16R1F1R1", true)
		else
			T:go("N16", true)
			T:emptyTrash("down")
			T:go("N16R1F1R1", true)
		end
	end
	T:go("L1F16L1") -- return to shaft + 1
	for i = 1, 8 do
		T:go("N32R1F1R1", true)
		if i == 1 then
			T:go("N16R1F2R2", true)
			T:emptyTrash("down")
			T:go("F2R1N16L1F1L1", true)
		elseif i == 8 then
			T:go("R1F1L1N16", true)
			T:emptyTrash("down")
			T:go("N16R1F1R1", true)
		else
			T:go("N16", true)
			T:emptyTrash("down")
			T:go("N16L1F1L1", true)
		end	
	end
	T:go("L1F15R1") -- return
	T:clear()
	return {"Mining operation complete"}
end

local function createMobFarmCube(R, blaze, continue) -- 61, 62
	--[[
	Part 1 / 3 Mob Spawner Farm
	blaze = true: blaze spawner in nether
	R.subChoice is set to:
	1 = on spawner
	2 = bottom left corner
	3 = top left corner
	4 = bottom right, corner
	5 = top right corner
	R.width / R.length set by player (external size)
	]]
	if blaze == nil then blaze = false end
	if continue == nil then continue = false end
	R.direction = "clock"		-- starting on right side
	if not blaze then
		print("R.width: "..tostring(R.width))
		R.width = R.width - 2		-- internal width
		R.length = R.length - 2		-- internal length
		
		if R.subChoice == 2 or R.subChoice == 3 then
			R.direction = "anticlock"
		end
	end
	-- continue allows for 2-part operation 1 = main cube, 2 = rails etc
	T:clear()
	print("Begin: blaze="..tostring(blaze).." continue="..tostring(continue))
	local lib = {}
	
	function lib.wallSection()
		for i = 1, 4 do
			for j = 1, 11 do
				T:go("C0C2", false, 0, false)
				if j < 11 then
					T:forward(1)
				else
					T:turnRight(1)
				end
				T:go("R2C1L2", false, 0, false)
			end
		end
	end
	
	function lib.ceiling()
		-- T:go(path, useTorch, torchInterval, leaveExisting, preferredBlock)
		-- all outer walls complete, now for remaining 9x9 ceiling
		for i = 1, 9 do
			for j = 1, 9 do
				T:go("C0x2", false, 0, true)
				if j < 9 then
					T:forward(1)
				else
					if i%2 == 1 then -- odd numbers 1,3,5,7,9
						if i < 9 then
							T:go("R1F1R1C0x2", false, 0, true)
						end
					else
						T:go("L1F1L1C0x2", false, 0, true)
					end
				end
			end
		end
	end
	
	function lib.clearWall(length)
		for i = 1, 4 do
			for j = 1, length do 
				if j < length then
					T:go("x0x2F1")
				else
					T:go("x0x2R1")
				end
			end
		end
	end
	
	function lib.isSpawner()
		local found = false
		local position = ""
		
		local blockType = T:getBlockType("down")
		if blockType:find("spawner") ~= nil then
			position = "top"
			found = true
		end
		if position == "" then
			blockType = T:getBlockType("up")
			if blockType:find("spawner") ~= nil then
				position = "bottom"
				found = true
			end
		end
		if position == "" then
			blockType = T:getBlockType("forward")
			if blockType:find("spawner") ~= nil then
				position = "forward"
				found = true
			end
		end
		return found, position
	end
	
	function lib.placeFloor(width, length, blockType)
		-- T:place(blockType, damageNo, direction, leaveExisting, signText)
		for i = 1, width do				
			for j = 1, length do
				T:place(blockType, -1, "down", false)
				if j < length then
					T:forward(1)
				else
					if i%2 == 1 then -- odd numbers 1,3,5,7,9
						if i < width then
							T:go("R1F1R1", false, 0, true)
						end
					else
						T:go("L1F1L1", false, 0, true)
					end
				end
			end
		end
	end
	
	function lib.searchStrip(distance)
		--go forward until hit either a wall or a chest
		local blocks = 1
		print("Searching strip, distance = "..distance)
		while blocks < distance do
			if turtle.forward() then
				blocks = blocks + 1
			else
				print("Checking for chest")
				if lib.isChest("forward") then
					if turtle.forward() then
						blocks = blocks + 1
					end
				else
					break
				end
			end
		end
	end
	
	function lib.findChests(R)
		for i = 1, 4 do
			print("Searching wall "..i)
			if i == 1 or i == 3 then
				lib.searchStrip(R.width) 	-- find and empty chests along width
			else
				lib.searchStrip(R.length) 	-- find and empty chests along length
			end
			if R.direction == "clock" then
				T:turnRight(1)
			else
				T:turnLeft(1)
			end
		end

		-- checked all walls
		T:go("F".. math.floor(R.width / 2)) -- now at mid-dungeon, next to wall
		if T:getItemSlot("chest") > 0 then
			if R.direction == "clock" then
				T:turnLeft(1)
			else
				T:turnRight(1)
			end
			-- now at mid-dungeon, facing wall
			-- deposit chest outside the dungeon
			while turtle.back() do end -- backing spawner
			T:go("F6x0x1x2")
			-- place(self, blockType, damageNo, direction, leaveExisting, signText)
			T:place("chest", -1, "forward", false)
			-- empty out all except stone and slab
			T:emptyInventorySelection("forward", {"cobble", "tuff", "slab", "granite", "andesite", "diorite" }, {0,0,0,0,0,0})
			T:turnLeft(2)
			while turtle.forward() do end -- facing spawner
		else
			if R.direction == "clock" then
				T:turnRight(1)
			else
				T:turnLeft(1)
			end
		end -- now at mid-dungeon, facing spawner
	end
	
	function lib.enterDungeon(R)
		--[[ find and empty any chests, return to dungeon wall ]]
		print("Entering dungeon")
		local blockType = T:getBlockType("forward")
		if blockType == "" then -- nothing in front.Error
			return false, "No block in front: Check position."
		else -- attempt entry into dungeon wall
			if R.subChoice == 2 then 	-- bottom left
				T:go("R1F1L1U2F2R1")
			elseif R.subChoice == 3 then	-- top left
				T:go("R1F1L1D1F2R1")
			elseif R.subChoice == 4 then	-- bottom right
				T:go("L1F1L1U2F2L1")
			elseif R.subChoice == 5 then	-- top right
				T:go("L1F1L1D1F2L1")
			end
			while turtle.down() do end -- either on floor or chest
			if lib.isChest("down") then
				turtle.down()
			end
			print("Searching for chests")
			lib.findChests(R)	-- go round inside walls  emptying chests. Finish mid-wall
		end
		return true, ""-- success, message
	end
	
	function lib.isChest(direction)
		direction = direction or "forward"
		local found = false
		local blockType = T:getBlockType(direction)
		if blockType:find("chest") ~= nil then -- chest found. early stages so empty and break it
			print("Chest found")
			found = true
			while T:suck(direction) do end
			T:dig(direction, false) -- false prevents checking for chests
		end
		return found
	end
		
	function lib.findSpawner(blaze)
		-- assume turtle placed on centre of inside spawner wall in front of spawner
		-- or as close as possible in Nether
		print("Checking if next to spawner")
		local found, position = lib.isSpawner() -- true/false, top/bottom/nil
		if not found then -- move forward towards spawner
			print("Not close to spawner")
			while turtle.forward() do end
			found, position = lib.isSpawner() -- true/false, top/bottom/nil
			if not found then
				if blaze then -- could be behind a wall
					print("Assuming blaze spawner behind a wall")
					T:forward(1)
					while turtle.forward() do end
					found, position = lib.isSpawner() -- true/false, top/bottom/nil
					if not found then
						return {"Unable to locate spawner"}
					end
				else
					return {"Unable to locate spawner"}
				end
			end
		end
		
		return found, position
	end
	
	function lib.rail(move, isPowered, count)
		if move ~= "" then
			T:go(move)
		end
		for i = 1, count do
			if isPowered then
				if not T:place("minecraft:powered_rail", -1, "down", false) then
					T:place("minecraft:golden_rail", -1, "down", false)
				end
			else
				T:place("minecraft:rail", -1, "down", false)
			end
			if i < count then
				T:forward(1)
			end
		end
	end
	
	if not continue then -- new mob cube either dungeon or blaze
		-- clsTurtle.go(self, path, useTorch, torchInterval, leaveExisting, preferredBlock)
		-- determine spawner position level 4, move to top of spawner (level 6)
		print("Checking if already at spawner")
		local found, position = lib.isSpawner() -- already on spawner?
		print("result: found="..tostring(found)..", position="..position)
		if not blaze then -- go to bottom of dungeon and empty chests
			if not found then --outside dungeon
				local success, message = lib.enterDungeon(R)
				if not success then
					return {message}
				end
				found, position = lib.findSpawner(blaze) -- is spawner in front / above / below?
			end 
		end
		
		if found then -- true: move to correct starting position
			--[[
			1 |c|c|c|c|c|c|c|c|c|c|c|
			2 |w| | | | | | | | | |w|
			3 |w| | | | | | | | | |w|
			4 |w| | | | | | | | | |w|
			5 |w| | | | | | | | | |w|
			6 |w| | | | |s| | | | |w|
			7 |w| | | | | | | | | |w|
			8 |w| | | | | | | | | |w|
			9 |w| | | | | | | | | |w|
		   10 |w| | | | | | | | | |w| exit level for overworld
		   11 |f|f|f|f|f|f|f|f|f|f|f|
		   12 |f|f|f|f|f|f|f|f|f|f|f| sub floor for overworld
			   1 2 3 4 5 6 7 8 9 1 1
			                     0 1
			]]
			-- T:go(path, useTorch, torchInterval, leaveExisting, preferredBlock)
			if position == "bottom" then
				T:go("B1U2F1")
			elseif position == "forward" then
				T:go("U1F1")
			end
			
			T:up(1)
			T:place("slab", -1, "down", true) -- place slab on top T:place(blockType, damageNo, direction, leaveExisting)
			-- go up 2 blocks, forward 5, right, forward 5, right
			T:go("U2F5R1F5R1") 		-- Level 2: now placed 1 below ceiling inside wall, top right corner of new dungeon
			lib.wallSection() 		-- fix layers 1, 2, 3 including ceiling margin turtle at Level 2
			T:go("F1R1F1R2C1R1", false, 0, false) -- exit wall, repair behind, still Level 2: fix ceiling
			lib.ceiling()			-- end opposite corner to start
			T:go("R2D3")			-- clear the inner walls inside original dungeon
			lib.clearWall(9)		-- clear the 9 x 9 area around the spawner
			T:go("F1R1F1L1")
			lib.clearWall(7)		-- clear the 7 x 7 area around the spawner
			--if blaze then			-- blaze spawners surrounded by nether bricks/ fence
				T:go("F1R1F1L1")
				lib.clearWall(5)	-- clear the 5 x 5 area around the spawner. Also needed for cave spiders
				T:go("R2F1R1F1R1")
			--end
			T:go("F7R1 F8L1F1R2", false, 0, false)	-- return from ceiling, enter wall below previous section: Level 5
			lib.wallSection() 						-- deal with areas from spawner level up (4,5,6). walls only
			T:go("F1R1F1R2C1R1D3", false, 0, false) -- exit wall, repair behind, embed 1 below original floor: Level 8
			clearRectangle({width = 9, length = 9, up = true, down = true}) -- clear levels 7,8,9
			T:go("L1F1L1F1L2", false, 0, false) 	-- ready for next wall section
			lib.wallSection() 						-- deal with walls on levels 7,8,9
			T:go("F1R1F1R2C1R1D3", false, 0, false) -- exit wall, repair behind, embed 4 below original floor: Level 11
			--print("Check: about to clear 3 floors 3 below spawner")
			--read()
			clearRectangle({width = 9, length = 9, up = true, down = true}) -- clear levels 10,11,12 
			T:go("L1F1L1F1L2", false, 0, false) -- ready for next wall section
			--print("Check: level 11, 5 north, 5 east")
			--read()
			if blaze then		-- blaze has rails placed on floor, second floor on top so walls not required
				clearPerimeter({width = 11, length = 11, up = true, down = true})
				T:go("F1R1F1L1U1", false, 0, false) -- exit wall, Level 10, facing entry point top right corner
				-- start in top right corner. border is made of slabs placed up
				-- fill in floor 9x9 rectangle below	
				lib.placeFloor(9, 9, "brick") -- ends facing wall on entrance side
				-- move to starting point in front of spawner,
				-- outside retaining wall' facing in, and ask for supplies
				T:go("L1F4 R1U6 F2R2")
				continue = true -- script continues below for blaze farm
			else	-- not blaze
				
				lib.wallSection() 	-- wall on layers 10,11,12
				T:go("F1R1F1R2C1R1U1", false, 0, false) -- exit wall, repair behind: Level 10, facing entry point top right corner
				T:down(1)
				lib.placeFloor(9, 9, "stone") -- ends facing wall on entrance side
				T:go("U1R2")
				lib.placeFloor(9, 9, "stone") -- ends facing wall on opposite side
				-- return to mid-point front
				T:go("R2F8 R1F4 L1F2")	-- exit at bottom of dungeon
				T:go("x1U1x1U1x1U1x1D3R2") -- rise to chest, then return ready for next stage
			end
		else
			return
			{
				"Spawner not found. Place me on top,",
				"immediately below, or facing it.",
				"\nEnter to quit"
			}
		end
	end
	if continue then
		T:sortInventory()
		T:turnRight(2)
		T:emptyTrashItem("forward", "minecraft:netherrack", 0)
		T:emptyTrashItem("forward", brick, 128)
		T:emptyTrashItem("forward", "fence", 0)
		T:turnRight(2)
		--clsTurtle.getItemSlot(self, item, useDamage): return slotData.lastSlot, slotData.leastModifier, total, slotData
		local a, b, numBricks = T:getItemSlot(brick)
		if numBricks < 81 then -- enough for floor
			T:checkInventoryForItem({brick, "stone"}, {81 - numBricks, 81 - numBricks})
		end
		T:checkInventoryForItem({"stone"}, {339})
		T:checkInventoryForItem({"slab"}, {36})
		T:checkInventoryForItem({"minecraft:powered_rail", "minecraft:golden_rail"}, {8, 8})
		T:checkInventoryForItem({"minecraft:rail"}, {64})
		T:checkInventoryForItem({"minecraft:redstone_torch"}, {2})
		T:checkInventoryForItem({"minecraft:hopper_minecart"}, {1})
		T:checkInventoryForItem({"minecraft:stone_button"}, {1})
		print("Stand clear. Starting in 2 secs")
		os.sleep(2)    -- pause for 2 secs to allow time to press esc
		-- return to starting point. rail laid first, bricks placed over rails
		T:go("F2L1D5F4R1")
		lib.rail("", true, 2) -- lay 2 plain rail at start
		lib.rail("F1", false, 1) -- lay 1 plain rail
		lib.rail("F1", true, 3) -- lay 3 powered rail
		T:go("L1F1")
		T:place("minecraft:redstone_torch", -1, "down", false) --place redstone torch
		lib.rail("R2F1L1F1", false, 3)
		lib.rail("R1F1R1", false, 8)
		lib.rail("L1F1L1", false, 7)
		lib.rail("R1F1R1", false, 8)
		lib.rail("L1F1L1", false, 9)
		lib.rail("R1F1R1", false, 8)
		lib.rail("L1F1L1", false, 7)
		lib.rail("R1F1R1", false, 8)
		lib.rail("L1F1L1", false, 5) -- final strip
		lib.rail("F1", true, 3)
		T:go("F1C2R1F1R1F1")
		T:place("minecraft:redstone_torch", -1, "down", false)
		T:go("R2F1L1F1L1U1")
		-- lay floor 9 x 9 rectangle filling below
		for i = 2, 10 do -- repeat 9x
			T:go("m8", false, 0, false, brick)
			if i < 10 then
				if i % 2 == 0 then
					T:go("R1F1R1", false, 0, false, brick)
				else
					T:go("L1F1L1", false, 0, false, brick)
				end
			end
		end
		-- replace first rail with cobble and button
		T:go("R1F1R2D2x1C1B1", false, 0, false)
		T:place("minecraft:stone_button", -1, "forward", false)
		T:go("U2F2L1F1x2")
		T:place("minecraft:hopper_minecart", -1, "down", false)
		T:go("L1F1D1R2C1", false, 0, false, brick) -- cover minecart
		T:go("U1R1F2L1C0F1",false, 0, false)
		-- place slabs
		for j = 1, 4 do
			for i = 1, 9 do
				T:place("slab", -1, "up", false)
				T:forward(1)
			end
			if j < 4 then
				T:go("L1C0F1")
			end
		end
		T:go("L1F1L2") -- get in position
		-- build outer edge
		for j = 1, 4 do
			for i = 1, 9 do
				turtle.back()
				T:place("stone", -1, "forward", false)
			end
			if j < 4 then
				T:turnLeft(1)
				turtle.back()
				T:place("stone", -1, "forward", false)
			end
		end
		T:go("L1F1R2C1L1U1")
		for j = 1, 4 do
			for i = 1, 11 do
				T:go("C0x2F1")
			end
			T:go("C0x2R1F1")
		end
		T:go("R2F2R1F1R1")
		T:go("R2C1R2Q14R1Q14R1Q14R1Q13R1D1", false, 0, false)
		T:go("L1F1R1")
		T:go("R2C1R2n14R1n14R1n14R1n13R1", false, 0, false)	-- now facing in on top of outer walkway
		T:go("R1 C1U1x0 F1C1U1x0 F1C1U1x0 F1C2 F1C2 F1C2 F1C2 U1L1F1") -- back at original entrance
	end
	return {}
end

local function floodMobFarm() -- 63
	-- Part 2 / 3 Mob Spawner Farm
	-- turtle on floor, pointing towards water source wall
	-- move forward until hit wall
	while turtle.forward() do end
	-- turn left, move forward until hit wall
	T:turnLeft(1)
	while turtle.forward() do end
	-- back 1, place water
	turtle.back()
	T:place("minecraft:water_bucket", -1, "forward", true)
	-- turn round go forward 7, place water
	T:turnLeft(2)
	while turtle.forward() do end
	-- back 1, place water
	turtle.back()
	T:place("minecraft:water_bucket", -1, "forward", true)
	
	-- turn round, go forward 3 (centre of wall), turn left, forward 4 (centre of chamber)
	T:go("L2F3L1F4")
	-- go down, left, forward, turn round
	T:go("D1L1F1R2")
	for i = 3, 9, 2 do
		-- check down, dig forward, go forward, check down (i blocks)
		T:go("m"..i-1, false, 0, true)
		if i == 3 or i == 7 then
			-- left, forward, right, forward, turn round
			T:go("L1F1R1F1R2")
		elseif i < 9 then
			T:go("R1F1L1F1R2")
			-- right, forward, left, forward, turn round
		end
	end
	-- right, forward, right, check down / forward 9 x
	T:go("R1F1R1m8R2F4R1") -- now facing bubble lift, next to wall
	-- go down 2, check floor, up 1, place fence
	T:go("D2C2U1", false, 0, true)
	T:place("fence", -1, "down", false)
	T:go("F1D1C2U1", false, 0, true)
	T:place("fence", -1, "down", false)
	T:go("F1U1R2", false, 0, true)
	T:go("F1R1U1")
	T:place("sign", -1, "down", false)
	T:go("U1C0D1")
	T:place("slab", -1, "up", false)
	T:go("R2F1R2")
	T:place("sign", -1, "forward", false)
	T:go("R1F1R2C1R1F1D1L1") --sitting on soul sand/dirt facing spawner
	if not T:place("minecraft:soul_sand", -1, "down", false) then
		T:place("minecraft:dirt", -1, "down", false)
	end
	return {}
end

local function createMobBubbleLift(R) -- 64
	-- Part 3 / 3 Mob Spawner Farm
	-- R.subChoice = 1 or 2 (left/right)
	local lib = {}
		
	function lib.down()
		local moves = 0
		while turtle.down() do
			moves = moves + 1
		end
		return moves
	end
	
	function lib.up()
		local moves = 0
		while turtle.up() do
			moves = moves + 1
		end
		return moves
	end
	-- check if dirt or soulsand below
	local turn = "R"
	if R.subChoice == 1 then
		turn = "L"
	end
	local blockType = T:getBlockType("down")
	if blockType ~= "minecraft:soul_sand" then
		T:dig("down")
		if not T:place("minecraft:soul_sand", -1, "down", false) then
			return {"Unable to find or place soulsand."}
		end
	end
	-- check facing sign, rotate if not
	blockType = T:getBlockType("forward")
	local turns = 0
	while blockType:find("sign") == nil do
		T:turnRight(1)
		turns = turns + 1
		if turns == 4 then
			return {"Unable to find sign."}
		end
		blockType = T:getBlockType("forward")
	end
	for i = 1, 3 do
		-- fill in back and one side, go up
		if turn == "R" then
			T:go("R1C1R1C1R1x1R1U1", false, 0, true)
		else
			T:go("L1C1L1C1L1x1L1U1", false, 0, true)
		end
	end
	for i = 1, 17 do
		-- tunnel up, filling 3 sides
		if turn == "R" then
			T:go("R1C1R1C1R1x1R1C1U1", false, 0, true)
		else
			T:go("L1C1L1C1L1x1L1C1U1", false, 0, true)
		end
	end
	-- move either left/right 8 blocks, repairing ceiling and sides
	if turn == "R" then
		T:go("C0R2C1R1F1C0C1R1C1R2C1L1F1A8", false, 0, true) -- fill top of column
	else
		T:go("C0L2C1L1F1C0C1L1C1L2C1R1F1A8", false, 0, true) -- fill top of column
	end
	-- turn round, go down 1, forward 7 blocks repairing bottom and sides
	T:go("D1C1R2X7", false, 0, true)
	-- turn round, go up, place cobble, forward 4, place cobble
	T:go("R2U1C2F4C2", false, 0, true)
	-- turn round forward 1 place water, forward 2, place water
	T:go("R2F1", false, 0, true)
	T:place("minecraft:water_bucket", -1, "down", false)
	T:forward(2)
	T:place("minecraft:water_bucket", -1, "down", false)
	T:go("R2F1")
	repeat
		-- refill both buckets
		T:place("minecraft:bucket", -1, "down", false)
		sleep(0.5)
		T:place("minecraft:bucket", -1, "down", false)
		-- back 4, down to solid, place water,
		for i = 1, 4 do
			turtle.back()
		end
		local moves = lib.down() -- returns no of blocks descent 0 to 19
		if moves > 0 then
			T:place("minecraft:water_bucket", -1, "forward", false)
			T:go("U1C2")
			if moves > 1 then
				T:place("minecraft:water_bucket", -1, "forward", false)
				T:go("U1C2")
			end
		end
		lib.up() -- 0 - 19
		T:forward(4)
	until moves <= 1
	-- delete water sources and remove cobble
	T:go("R2F3C1R2F1")
	for i = 1, 7 do -- go to end of run placing cobble
		T:go("C2F1")
	end
	T:turnRight(2)
	for i = 1, 7 do -- go to end of run, down 2
		T:go("x2F1x2")
	end
	T:go("R2F7D2")
	for i = 1, 18 do
		-- tunnel down, filling all 4 sides
		T:go("R1C1R1C1R1C1R1C1D1", false, 0, true)
	end
	-- block below, turn round, tunnel forward 6 blocks
	T:go("C2R2U1")
	for i = 1, 6 do
		T:go("R1C1L2C1R1")
		if i < 6 then
			T:forward(1)
		end
	end
	T:go("R2D1") -- drop down return to far wall
	for i = 1, 6 do	-- leave opening for player attack
		if turn == "R" then
			T:go("L1C1R2x1L1")
		else
			T:go("R1C1L2x1R1")
		end
		if i < 6 then
			T:forward(1)
		end
	end
	T:go("R2F1 D1C2 R1C1 L2C1 R1U1")
	T:place("water", -1, "down")
	T:go("F1D1")
	for i = 1, 5 do
		T:go("C2R1C1L2C1R1")
		if i < 5 then
			T:forward(1)
		end
	end
	if turn == "R" then
		T:go("L1F1C2F1C2U1R1")
	else
		T:go("R1F1C2F1C2U1L1")
	end
	return {}
end

local function createPlatform(R) -- 57
	local forward = true
	for w = 1, R.width do
		for l = 1, R.length do
			T:go("x2C2", false, 0, true)
			if l < R.length then
				T:go("F1", false, 0, true)
			end
		end
		if w < R.width then
			if forward then
				T:go("R1F1R1", false, 0, true)
			else
				T:go("L1F1L1", false, 0, true)
			end
		end
		forward = not forward
	end
	return {}
end

local function createPortal(R) -- 42
	T:go("D1x1", false, 0, true)
	T:place("stone", -1, "forward", true)
	for i = 1, R.height - 1 do
		T:go("U1x1", false, 0, true)
		T:place("minecraft:obsidian", 0, "forward", true)
	end
	T:go("U1x1", false, 0, true)
	T:place("stone", -1, "forward", true)
	for i = 1, R.width - 1  do
		T:go("R1F1L1x1")
		T:place("minecraft:obsidian", 0, "forward", true)
	end
	T:go("R1F1L1x1", false, 0, true)
	T:place("stone", -1, "forward", true)
	for i = 1, R.height - 1 do
		T:go("D1x1")
		T:place("minecraft:obsidian", 0, "forward", true)
	end
	T:go("D1x1", false, 0, true)
	T:place("stone", -1, "forward", true)
	for i = 1, R.width - 1 do
		T:go("L1F1R1x1")
		T:place("minecraft:obsidian", 0, "forward", true)
	end
	T:go("U1L1F1R1", false, 0, true)
	return {}
end

local function createPortalPlatform() -- 48
	--[[ Used in End World to use minecarts to carry player through portal ]]
	local lib ={}
	
	function lib.findPortal()
		local found = false
		local onSide = false
		for i = 1, 64 do
			if not turtle.up() then -- hit block above
				found = true
				break
			end
		end
		if found then
			-- are we under the centre block, or one of the sides?
			if turtle.detect() then -- under a side
				onSide = true
			else	-- nothing in front, probably under centre, or facing wrong direction so check
				for i = 1, 4 do
					turtle.turnRight()
					if turtle.detect() then
						onSide = true
						break
					end
				end
			end
			if onSide then-- move to centre
				T:go("D1F1")
			end
		end
		local height = 3 -- allows for 2 bedrock + starting space
		while turtle.down() do
			height = height + 1
		end
		return found, height
	end
	
	function lib.addFloor(length)
		for i = 1, length do
			if i < length then
				T:go("C2F1", false, 0, true)
			else
				T:go("C2", false, 0, true)
			end
		end
	end
	
	function lib.buildLadder(height)
		for i = 1, height do
			T:go("F1C1 R1C1 L2C1 L1F1L2", false, 0, true)
			if i > 3 then
				T:go("C2")
			end
			T:place("minecraft:ladder", 0, "forward", true)
			T:up(1)
		end
	end
	
	local found, height = lib.findPortal()
	if found then	-- position under centre of beacon
		-- build ladder up and create platform
		T:go("L1F1L1F2L2")
		T:checkInventoryForItem({"minecraft:ladder"},{height})
		T:checkInventoryForItem({"stone"},{height * 4 + 40})
		lib.buildLadder(height)

		T:go("F1R1F4R2")			-- turn right, forward 4, reverse
		for i = 1, 5 do				-- build 7 x 5 platform
			lib.addFloor(7)			-- forward place block above to 7 blocks
			if i == 1 or i % 2 == 1 then -- 1,3,5,7
				T:go("L1F1L1")
			else
				T:go("R1F1R1")
			end
		end
		T:go("F3L1F4")			-- facing portal entrance, 1 block short
		T:place("minecraft:rail", -1, "forward", false)
		T:go("U1R2")
		T:place("minecraft:rail", -1, "down", false)
		T:forward(1)
		if not T:place("minecraft:powered_rail", -1, "down", false) then
			T:place("minecraft:golden_rail", -1, "down", false)
		end
		T:go("F1C2 U1R2C2 F1")
		T:place("minecraft:minecart", -1, "down", false)
		T:go("F1R2D1")
		T:place("minecraft:stone_button", -1, "forward", false)
	else
		return {"Portal not found. Move me under","the centre if possible.", "wait for purple beacon."}
	end
	return {}
end

local function createRailwayDown(drop) -- 93
	-- go(path, useTorch, torchInterval, leaveExisting, preferredBlock)
	if drop == 0 then
		local blockTypeD = T:getBlockType("down")
		while blockTypeD == "" do
			T:go("F1D1", false, 0, true)
			blockTypeD = T:getBlockType("down")
			if blockTypeD == "" then
				T:go("C2", false, 0, true)
			end
		end
	else
		for i = 1, drop - 1 do
			T:go("F1D1C2", false, 0, false)
		end
	end
	return {}
end

local function createRailwayUp(up) -- 94
	for i = 1, up do
		T:go("C1U1F1", false, 0, false)
	end
	return {}
end

local function createRetainingWall(R, topInPlace) -- 34, 82
	-- facing direction wall will take
	-- will need to rotate 180 to build
	-- if R.height > 0 then build to specified depth
	-- topInPlace = true already a path across the water eg monument rectangle
	local lib = {}
		
	function lib.checkFloor()
		local newDepth = 0
		place = utils.clearVegetation("down") -- in case col in front is deeper
		while place do -- loop will be entered at least once
			T:down(1)
			newDepth = newDepth + 1
			place = utils.clearVegetation("down")
		end
		if newDepth > 0 then
			for j = 1, newDepth do	-- go up until column base is met
				T:go("U1C2")
			end
		end
	end
	
	function lib.patchMissingBlock()
		if turtle.back() then
			T:go("C1")
		else
			T:go("B1C1")
		end
	end
	
	function lib.placeSingle(height)
		local y = 0
		if height > 0 then
			T:go("D"..height)
			y = height
		else
			local place = utils.clearVegetation("down")
			while place do -- loop will be entered at least once
				place = utils.clearVegetation("down")
				if place then
					T:down(1)
					y = y + 1
				end
			end
		end
		-- return to surface, placing below
		for i = 1, y do
			T:go("U1C2", false, 0, true)
		end
	end
	
	function lib.placeDouble(height)
		--T:go(path, useTorch, torchInterval, leaveExisting, preferredBlock)
		local y = 0
		if not turtle.back() then
			T:go("B1")
		end
		if height > 0 then
			for i = 1, height do
				T:go("C1D1", false, 0, true, false)
			end
			T:go("C1", false, 0, true, false)
			y = height
		else
			local place = utils.clearVegetation("down")
			-- build back column
			while place do -- loop will be entered at least once
				place = utils.clearVegetation("down")
				if place then
					T:go("C1D1", false, 0, true, false)
					y = y + 1
				end
			end
			-- reached bottom. floor in front could drop down
			T:go("F1") -- move under first column
			lib.checkFloor()
			turtle.back() -- back at starting point
			T:go("C1", false, 0, true) 
		end
		-- return to surface, placing below
		for i = 1, y do
			T:go("U1C2", false, 0, true)
		end
	end
		
	function lib.placeTriple(height)
		--T:go(path, useTorch, torchInterval, leaveExisting, preferredBlock)
		local y = 0
		if turtle.back() then
			T:go("C1")
		else
			T:go("B1C1")
		end
		if height > 0 then
			for i = 1, height do
				T:go("C1D1", false, 0, true, false)
			end
			for i = 1, height do
				T:go("C1D1", false, 0, true, false)
			end
			T:go("C1R2C1", false, 0, true, false) --fill last block, then turn 180 to build opposite side
			y = height
		else
			local place = utils.clearVegetation("down")
			-- build back column
			while place do -- loop will be entered at least once
				place = utils.clearVegetation("down")
				if place then
					T:go("C1D1", false, 0, true, false)
					y = y + 1
				end
			end
			-- reached bottom. floor in front could drop down
			T:go("F1") -- move under first column
			lib.checkFloor()
			T:go("B1C1R2F1", false, 0, true) 
			lib.checkFloor()
			T:go("B1C1")
			-- return to surface , placing below and to front
		end
		for i = 1, y do
			T:go("C1U1C2", false, 0, true)
		end
		T:go("F1R2C1", false, 0, true)
		-- facing back again inside edge of col 3
		return y -- depth of this run
	end
	
	if topInPlace == nil then topInPlace = false end 
	local place = false
	local inWater = false
	local onWater = false
	if not topInPlace then
		if R.length > 1 then
			inWater, onWater = utils.getWaterStatus()
		end
	end
	
	local maxDepth = 5 --initial estimated value
	-- start at surface, move back 1 block
	-- each iteration completes 3 columns
	local numBlocks = T:getSolidBlockCount()
	print("Solid blocks in inventory: "..numBlocks)
	
	if R.length == 1 then -- single column down to water bed
		lib.placeSingle(R.height)
	elseif R.length == 2 then--down then up: 2 cols
		inWater, onWater = utils.startWaterFunction(onWater, inWater, 2, true) -- move into water
		T:go("R2") -- move to face player
		lib.placeDouble(R.height)
		if not inWater then
			T:go("U1C2", false, 0, true, false)
		end
	else -- R.length 3 or more
		if topInPlace then
			T:down(1) -- break through top
		else
			inWater, onWater = utils.startWaterFunction(onWater, inWater, 2, true) -- move into water
		end
		T:go("R2") -- move to face player
		-- now at water surface
		local remain = R.length
		while remain >= 3 do
			numBlocks = T:getSolidBlockCount()
			print("Iventory blocks: "..numBlocks.." depth: "..maxDepth)
			if numBlocks < maxDepth * 3 then
				--ask player for more
				T:checkInventoryForItem({"stone"}, {maxDepth * remain}, false)
			end
			local y = lib.placeTriple(R.height) -- moves back, places col in front, centre and behind. R.height = 0 for auto depth
			if y > maxDepth then
				maxDepth = y
			end
			remain = remain - 3
			if remain > 1 then
				lib.patchMissingBlock()
			end
		end
		if remain == 1 then -- 1 more column
			lib.patchMissingBlock()
			lib.placeSingle(R.height)
		elseif remain == 2 then -- 2 cols
			lib.placeDouble(R.height)
		end
		T:go("U1C2") -- above surface
	end
	return {}
end

local function createSafeDrop(R) -- 14
	-- dig down height blocks, checking for blocks on all sides
	local drop = 0
	T:down(2)
	drop = 2
	for i = 1, R.height - 1 do
		for j = 1, 4 do
			-- go(path, useTorch, torchInterval, leaveExisting, preferredBlock)
			T:go("C1R1", false, 0, true)
		end
		if T:down(1) then
			 drop = drop + 1
		end
		if T:isWaterOrLava("up") ~= "" then
			T:go("C0x0", false, 0, false) -- delete water/ lava block
		end
	end
	T:go("U1R2x1")
	--place(blockType, damageNo, direction, leaveExisting, signText)
	T:place("minecraft:water_bucket", -1, "down", false)
	T:go("U1x1")
	T:up(drop - 2)
	
	return {"Safe drop completed "..drop .. " blocks"}
end

local function createSlopingWater(R) -- 34, 89
	--[[
	creates a sloping water area above existing lake/river/ocean
	R.width is usually 7 with an existing wall on 8th row
	R.length  is user choice
	Places slabs into existing surface, places row of sources
	Removes slabs
	]]
	local lib = {}
	
	function lib.fillBuckets()
		local emptyBuckets = utils.getEmptyBucketCount()
		for i = 1, emptyBuckets do
			if utils.fillBucket("down") then
				print("Bucket filled down")
				sleep(0.3)
			else
				print("Unable to fill bucket ".. i .." / "..emptyBuckets)
			end
		end
		return utils.getWaterBucketCount()
	end
	
	local outbound = true
	local inWater, onWater = utils.getWaterStatus()
	inWater, onWater = utils.startWaterFunction(onWater, inWater, 2 ,false) -- move above water, max descent 2
	local waterBuckets = lib.fillBuckets()
	for w = 1, R.width do
		for l = 1, R.length do
			T:place("slab", -1, "down", false)
			if l < R.length then
				T:forward(1)
			end
		end
		if w < R.width then
			if outbound then
				T:go("R1F1R1")
			else
				T:go("L1F1L1")
			end
			outbound = not outbound
		end
	end
	if outbound then
		T:go("L1F"..R.width - 1 .."L1")
	else
		T:go("R1F"..R.width - 1 .."R1")
	end
	T:place("water", -1, "up", true) -- place in corner
	local move = true
	while move do
		move = turtle.forward()
		move = turtle.forward() -- false if at end of run
		T:place("water", -1, "up", true) -- alternate positions + end of run
	end
	T:go("R2D1")
	for w = 1, R.width do
		for l = 1, R.length do
			if l < R.length then
				T:forward(1)
			end
		end
		if w < R.width then
			if outbound then
				T:go("R1F1R1")
			else
				T:go("L1F1L1")
			end
			outbound = not outbound
		end
	end
	if outbound then
		T:go("L1F"..R.width - 1 .."L1")
	else
		T:go("R1F"..R.width - 1 .."R1")
	end
	T:go("U2")
	
	return {}
end

local function createSquidFarmBase(R) -- 34
	-- dig down to y=45. assume starting at water level (64)
	local depth = 0
	local message =
[[Place the turtle under the grid
left corner above current pit
opening.
It will descend to the base and
continue to level y=45.

Enter to continue...
]]
	read()
	while turtle.down()do
		depth = depth + 1
	end
	T:down(1)
	R.height = 21 - depth
	R.width = 15
	R.length = 15
	R.silent = true
	R.data = "down"
	clearSolid(R)
	T:up(depth + 4)
	return {}
end

local function createSquidFarmGrid(R) -- 34
	local lib = {}
	
	function lib.placeDirt()
		for i = 1, 15 do
			T:place("dirt", -1, "down")
			if i < 15 then
				T:forward(1)
			end
		end
	end
	
	function lib.placeHoles()
		for i = 1, 3 do
			T:place("dirt", -1, "down")
			T:forward(1)
		end
		for i = 1, 5 do
			T:forward(1)
			T:place("dirt", -1, "down")
			T:forward(1)
		end
		T:place("dirt", -1, "down")
		T:forward(1)
		T:place("dirt", -1, "down")
	end
	
	function lib.left()
		T:go("L1F1L1")
	end
	
	local message =
	[[Make sure the turtle is placed
above the water at level 64 for an
area of 15 x 15 blocks in river
biome.
(Usually eye level at water edge)
Check biome using F3.
	
The platform starts at the lower
left corner.
	
Enter to start
	]]
	
	print(message)
	read()
	-- place 15x15 dirt grid above
	-- leave 25 holes
	T:up(1)
	lib.placeDirt() -- col 1
	T:go("R1F1R1")
	lib.placeDirt() -- col 2
	T:go("L1F1L1")
	lib.placeDirt() -- col 3
	for i = 1, 9 do
		if i % 2 == 0 then -- 2,4,6,8
			T:go("L1F1L1")
			lib.placeDirt() -- col 5, 7, 9, 11
		else
			T:go("R1F1R1")
			lib.placeHoles() -- col 4, 6, 8, 10
		end
	end
	T:go("L1F1L1")
	lib.placeDirt() -- col 1
	T:go("R1F1R1")
	lib.placeDirt() -- col 2
	T:go("L1F1L1")
	lib.placeDirt() -- col 3
	T:go("L1F14 L1F14 L1U1")
	
	-- build water reservoir
	
	T:go("C2F1C2F1C2F1C2F1C2")
	T:go("L1F1C2F1C2")
	T:go("L1F1C2F1C2F1C2F1C2")
	T:go("L1F1C2L1F1")
	
	T:place("water", -1, "down")
	T:forward(2)
	T:place("water", -1, "down")
	T:go("R1F2R1F4R1D3")
	return {}
end

local function createSquidFarmGateTraps(R) -- 34
	local lib = {}
	
	function lib.placeUpperGates()
		T:go("L1")
		T:place("gate", -1, "forward", false)
		T:go("L1")
		T:place("gate", -1, "forward", false)
		T:go("L1")
		T:place("gate", -1, "forward", false)
		T:go("L1")
	end
	
	function lib.placeGates()
		for i = 1, 5 do
			T:place("gate", -1, "down", false)
			lib.placeUpperGates()
			if i < 5 then
				T:forward(2)
			else
				T:place("gate", -1, "forward", false)
			end
		end
	end
	
	function lib.getWater()
		for i = 1, 5 do
			T:place("minecraft:bucket", -1, "down", false)
			sleep(0.5)
		end
	end
	
	function lib.placeWater()
		for i = 1, 5 do
			T:down(1)
			T:place("water", -1, "down", false)
			T:up(1)
			if i < 5 then
				T:forward(2)
			end
		end
	end
	
	local message =
[[Place the turtle above the grid
left corner of water source.

It will place open gates at y = 42/43.
then drop water through the grid.

Enter to continue...
]]
	print(message)
	read()
	T:go("F3R1F3D1L1")
	if turtle.detectDown() then
		return {"Incorrect turtle position","Should now be above a grid hole"}
	end
	--rs.setAnalogueOutput("bottom", 15)
	--rs.setAnalogueOutput("front", 15)
	T:down(20)
	lib.placeGates() -- place 1st 5 gates
	T:go("U1R1 F2D1R1")
	lib.placeGates() -- place 2nd 5 gates
	T:go("U1L1 F2D1L1")
	lib.placeGates() -- place 3rd 5 gates
	T:go("U1R1 F2D1R1")
	lib.placeGates() -- place 4th 5 gates
	T:go("U1L1 F2D1L1")
	lib.placeGates() -- place 5th 5 gates
	
	T:go("U21L1 F8L1 F10R1 F1R2") -- above water source
	
	for i = 1, 9 , 2 do -- 1,3,5,7,9
		lib.getWater()
		T:go("F"..i.."L1F2 D1")
		lib.placeWater()
		T:go("U1R2 F10R1 F"..i.."R2")
	end
		
	return {}
end

local function createSquidFarmEnclosure(R) -- 34
	local lib = {}
	
	function lib.createEnclosure(length, width)
		lib.placeWall(length)
		T:turnRight(1)
		lib.placeWall(width)
		T:turnRight(1)
		lib.placeWall(length)
		T:turnRight(1)
		lib.placeWall(width)
		T:turnRight(1)
	end
	
	function lib.placeWall(length)
		for i = 1, length do
		-- T:go(path, useTorch, torchInterval, leaveExisting, preferredBlock)
			if i < length then
				T:go("C2F1", false, 0, true)
			else
				T:go("C2")
			end
		end
	end
	R.width = 17
	R.length = 17
	R.data = "squid"
	R.height = 15 -- estimated. Loop should break when no more water
	-- create a 17 x 17 wall below the grid platform
	lib.createEnclosure(R.width, R.length)
	T:go("F1R1F1L1")
	-- make the enclosing wall
	R.width = 15
	R.length = 15
	utils.drainWaterLava(R)
	-- drain the water away
	-- repeat until no more water
	return {}
end

local function createSandWall(R) -- 81
	local success = true
	--move above water
	local maxMove = 2
	while turtle.detectDown() and maxMove > 0 do
		T:forward(1)
		maxMove = maxMove - 1
	end
	if R.length > 0 then
		for i = 1, R.length - 1 do
			success = utils.dropSand()
			T:forward(1, false)
		end
		success = utils.dropSand()
	else
		while not turtle.detectDown() do -- over water
			while not turtle.detectDown() do -- nested to allow forward movement
				success = utils.dropSand() -- drops sand and checks supplies
			end
			if success then
				T:forward(1, false)
			else -- out of sand
				break
			end
		end
	end
	return {}
end

local function createSinkingPlatform(R) -- 58
	local lib = {}
	function lib.stage1a()
		for l = 1, length do 
			if l == 1 then
				T:go("L1C1R1C2U1C2D1F1C2", false, 0, true)
			elseif l < length then
				T:go("L1C1R1C2F1C2", false, 0, true)
			else
				T:go("L1C1R1C2C1U1C2D1", false, 0, true)
			end
		end
	end
	
	function lib.stage1b()
		for l = 1, length do 
			if l == 1 then
				T:go("R1C1L1C2U1C2D1F1C2", false, 0, true)
			elseif l < length then
				T:go("R1C1L1C2F1C2", false, 0, true)
			else
				T:go("R1C1L1C2C1U1C2D1", false, 0, true)
			end
		end
	end
	
	function lib.stage2(forward)
		if forward then
			T:go("C1R1F1L1C1R2", false, 0, true)
		else
			T:go("C1L1F1R1C1L2", false, 0, true)
		end
	end
		
	local forward = true
	local goingRight = true
	for h = 1, R.height do
		T:down(1) -- move down into existing platform
		if goingRight then -- first side
			if forward then
				-- complete left side
				T:go("R2C1L2", false, 0, true) -- block 1, 1
				lib.stage1a()
				-- turn ready for next side
				T:go("R1F1L1C1R2C2")
			else
				T:go("L2C1R2", false, 0, true) -- block 1, 1
				lib.stage1b()
				-- turn ready for next side
				T:go("L1F1R1C1L2C2")
			end
		else -- on right side so different approach
			if forward then
				T:go("L2C1R2", false, 0, true) -- block 1, 1
				lib.stage1b()
				-- turn ready for next side
				T:go("C1L1F1R1C1L2C2")
			else
				-- complete left side
				T:go("R2C1L2", false, 0, true) -- block 1, 1
				lib.stage1a()
				-- turn ready for next side
				T:go("C1R1F1L1C1R2C2")
			end
		end
		forward = not forward
		-- continue strips across until at far edge
		for w = 1, R.width - 2 do
			for l = 1, R.length do
				if l < R.length then
					T:go("C2F1", false, 0, true)
				else
					T:go("C2", false, 0, true)
				end
			end
			if goingRight then
				lib.stage2(forward)
			else
				lib.stage2(not forward)
			end
			forward = not forward
		end
		-- far side
		if goingRight then
			if forward then
				lib.stage1b()
			else
				lib.stage1a()
			end
		else
			if forward then
				lib.stage1a()
			else
				lib.stage1b()
			end
		end
		goingRight = not goingRight
		T:turnRight(2)
		forward = not forward
	end
	return {}
end

local function createStaircase(destination, currentLevel, destLevel) -- 13
	-- R# L# F# B# U# D# +0 -0 = Right, Left, Forward, Back, Up, Down, up while detect and return, down while not detect
	-- dig:			  x0,x1,x2 (up/fwd/down)
	-- suck:		  s0,s1,s2
	-- place chest:   H0,H1,H2 
	-- place sapling: S0,S1,S2
	-- place Torch:   T0,T1,T2
	-- place Hopper:  P0,P1,P2
	-- mine floor:	  m# = mine # blocks above and below, checking for valuable items below, and filling space with cobble or dirt
	-- mine ceiling:  M# = mine # blocks, checking for valuable items above, and filling space with cobble or dirt
	-- mine ceiling:  N# same as M but not mining block below unless valuable
	-- place:		  C,H,r,S,T,P,^ = Cobble / cHest / DIrT / Sapling / Torch / hoPper /stair in direction 0/1/2 (up/fwd/down) eg C2 = place cobble down
	
	-- 3| |B| |
	--   - - - 
	-- 2|A| |C|
	--   - - - 
	-- 1|^|D| |
	--   - - - 
	--   1 2 3 
	local function checkFluids()
		local isFluid = false
		-- check if water or lava present
		for i = 1, 4 do
			blockType = T:isWaterOrLava("forward")
			if blockType:find("lava") ~= nil or blockType:find("water") ~= nil then
				isFluid = true
			end
		end
		return isFluid
	end
	
	local function createStaircaseSection(onGround)
		-- start 1,1,1, n
		-- stage A
		local isFluid = checkFluids()
		local blockType = ""
		local data = T:getStock("stairs")
		if data.total == 0 then
			T:craft('stairs', 4)
		end
		if onGround and isFluid then
			-- add right side and block entrance
			T:go("R1C1R1C1R2")
		end
		if isFluid then
			T:go("L1C1 R1F1C2 L1C1 R1x1 R1C1 L1C2B1 C1x1 ^1C2", false, 0, true) --start:1,1,1,n stairs A on level 1, going back to 1,1,1,n
		else
			T:go("F1x1 R1C1 L1C2B1 ^1C2", false, 0, true)
		end
		if not onGround then
			-- stage A1
			T:go("L2C1L2", false, 0, true) -- start 1,1,1,n fix corner on level 1 end: 1,1,1,n
		end
		-- stage B
		T:go("U1L1", false, 0, true) -- end  1,1,1,w layer 2
		isFluid = checkFluids()
		if isFluid then
			T:go("C1", false, 0, true) -- end  1,1,1,w layer 2
		end
		if not onGround then
			if isFluid then
				T:go("L1C1R1", false, 0, true) -- end  1,1,1,w layer 2
			end
		end
		-- stage C1
		if isFluid then
			T:go("R1C1F1C1x1 L1C1 R2C1 L1B1", false, 0, true)
		else
			T:go("R1F1 R1C1 L1B1", false, 0, true)
		end
		-- stage C2
		T:go("U1")
		isFluid = checkFluids()
		if isFluid then
			T:go("L1C1L1 C1L2 C1F1L1 C1R2 C1L1 B1C2D1", false, 0, true) -- end 1,1,2,n
		else
			T:go("F1R1 C1L1 B1D1", false, 0, true) -- end 1,1,2,n
		end
		onGround = false
		-- stage D
		isFluid = checkFluids()
		if isFluid then
			T:go("C1F1C1F1C1x1L1 C1R1 C1R1", false, 0, true) -- 3,1,2,e
		else
			T:go("F2 C1R1", false, 0, true) -- 3,1,2,e
		end
		
		return onGround
	end

	--local height = currentLevel -- eg 64 at top or 5 at bedrock
	local data = T:getStock("stairs")
	--{rt.total, rt.mostSlot, rt.leastSlot, rt.mostCount, rt.leastCount}
	local numStairs = data.total
	local range = math.abs(destLevel - currentLevel)
	local numStairsNeeded = range
	numStairsNeeded = numStairsNeeded - numStairs
	if numStairsNeeded > 40 then
		print('crafting '..numStairsNeeded..' : '..numStairs.. ' in stock')
		T:craft('stairs', 40)	-- max 40 so repeat
		data = T:getStock("stairs")
		if data.total == 0 then
			data = T:getStock("stairs")
		end
		numStairs = data.total
		numStairsNeeded = numStairsNeeded - numStairs
	end
	if numStairsNeeded >  0 then
		T:craft('stairs', numStairsNeeded)
	end
	local height = 0
	if destination == "bedrock" then -- go down towards bedrock
		local atBedrock = false
		for i = 1, range do
			height = height	- 1
			if not T:down() then
				atBedrock = true
				break
			end
		end
		if atBedrock then -- hit bedrock so get to level 5 / -59
			height = T:findBedrockTop(height)
			T:go("R1F1R1", false, 0, true)
		end
	end
	local onGround = true
	height = 0
	while height < range do
		for x = 1, 4 do
			onGround = createStaircaseSection(onGround)
		end
		height = height + 4
	end
	
	return{"Staircase completed"}
end

local function createTreefarm(R) -- 22
	local blockType
	local blockModifier
	
	if R.subChoice == 1 then
		R.length = 11
		R.width = 6
		clearArea(11, 11)
	else
		R.length = 19
		R.width = 10
		clearArea(19, 19)
	end
	-- now place dirt blocks and torches
	T:go("F2R1F2L1U1", false, 0, true)
	for x = 1, (R.width - 2) / 2 do
		for y = 1, (R.length - 3) / 2 do
			T:place("minecraft:dirt", -1, "down", false)
			if y < (R.length - 3) / 2 then
				T:forward(1)
				T:place("minecraft:torch", -1, "down", false)
				T:forward(1)
			end
		end
		T:go("R1F2R1", false, 0, true)
		for y = 1, (R.length - 3) / 2 do
			T:place("minecraft:dirt", -1, "down", false)
			if y < (R.length - 3) / 2 then
				T:forward(1)
				T:place("minecraft:torch", -1, "down", false)
				T:forward(1)
			end
		end
		if x < (R.width - 2) / 2 then
			T:go("L1F2L1", false, 0, true)
		else
			T:go("R1F6", false, 0, true)
			if R.subChoice == 2 then
				T:go("F8", false, 0, true)
			end
			T:go("R1B1", false, 0, true)
		end
	end
	return {}
end

local function createWalkway(R) -- 54
	--[[ 
	R.choice = 52. 
	Build a path with covering blocks above, ideal for nether
	]]
	if R.length == 0 or R.length == nil then
		R.length = 2048
	end
	-- clsTurtle.fillVoid(self, direction, tblPreferredBlock, leaveExisting)
	local placed, noBlocks
	local moves = 0
	for i = 1, R.length / 2 do
		placed, noBlocks = T:fillVoid("down", {}, true) 	-- place floor
		T:forward(1)										-- move forward
		moves = moves + 1
		placed, noBlocks = T:fillVoid("down", {}, true)	-- place next floor
		T:up(1)												-- move up
		placed, noBlocks = T:fillVoid("up", {}, true)		-- place ceiling
		if moves >= 8 then									-- place torch down every 8 blocks
			moves = 0
			T:place("minecraft:torch", 0, "down", true)
		end
		T:forward(1)										-- move forward
		moves = moves + 1
		placed, noBlocks = T:fillVoid("up", {}, true)		-- place next ceiling
		T:down(1)											-- ready to start again
		if noBlocks then									-- quit if out of blocks
			break
		end
	end
	return {}
end

local function decapitateBuilding(width, length) -- 81
	--clearRectangle with sand drop
	-- could be 1 wide x xx length (trench) up and return
	-- could be 2+ x 2+
	-- even no of runs return after last run
	-- odd no of runs forward, back, forward, reverse and return
	local success
	local directReturn = true
	if width % 2 == 1 then
		directReturn = false
	end
	if width == 1 then -- trench ahead, so fill then return
		for i = 1, length - 1 do
			success = utils.dropSand()
			T:forward(1, false)
		end
		success = utils.dropSand()
		T:go("R2F"..(length - 1).."R2", false, 0, false)
	else --2 or more columns
		if directReturn then -- width = 2,4,6,8 etc
			for i = 1, width, 2 do -- i = 1,3,5,7 etc
				-- move along length, dropping sand
				for j = 1, length - 1 do
					success = utils.dropSand()
					T:forward(1, false)
				end
				success = utils.dropSand()
				T:go("R1F1R1") --turn right and return on next column
				for j = 1, length - 1 do
					success = utils.dropSand()
					T:forward(1, false)
				end
				success = utils.dropSand()
				if i < width - 2 then -- eg width = 8, i compares with 6: 1, 3, 5, 7
					T:go("L1F1L1")
				end
			end
			T:go("R1F"..width - 1 .."R1") --return home
		else
			for i = 1, width, 2 do -- i = 1,3,5,7 etc
				-- move along length, dropping sand
				for j = 1, length - 1 do
					success = utils.dropSand()
					T:forward(1, false)
				end
				success = utils.dropSand()
				T:go("R1F1R1") --turn right and return on next column
				for j = 1, length - 1 do
					success = utils.dropSand()
					T:forward(1, false)
				end
				success = utils.dropSand()
				T:go("L1F1L1")
			end
			-- one more run then return
			for j = 1, length - 1 do
				success = utils.dropSand()
				T:forward(1, false)
			end
			success = utils.dropSand()
			T:go("R2F"..length.."R1F"..width - 1 .."R1")
		end
	end
	return {}
end

local function deactivateDragonTower() -- 45
	-- go up centre of tower to bedrock
	local height = 0
	--numBlocksMoved, errorMsg = clsTurtle.doMoves(self, numBlocksRequested, direction)
	local numBlocks, message = T:doMoves(1, "up")
	while message == nil do
		numBlocks, message = T:doMoves(1, "up")
		height = height + 1
	end
	-- go round bedrock and destroy crystal
	T:go("F1R2U2x1U1x1")
	-- return to start
	T:down(height + 5)
	return {}
end

local function undermineDragonTowers() -- 44
	--[[
	        -13, -40....12, -40						NNW (4)   	NNE (5)
			
	    -34, -25............33, -25				NWW	(2)				NEE (9)
		
	-42, -1....................42, 0		W (1)						E (8)
	
	     -34, 24............33,24				SWW	(3)				SEE (10)
		 
		      -13,39....12, 39						SSW	(7)		SSE (6)
	
	North towers centres 25 blocks apart, 40 blocks north of axis
	Mid-North towers 67 blocks apart, 25 blocks north of axis
	W-E centres 84 blocks apart, on 0 axis
	Mid-south towers 67 blocks apart, 24 blocks south of axis
	South towers centres 25 blocks apart, 39 blocks south of axis
	]]
	
	local lib = {}
	function lib.findNextTower(maxDistance, withMarker)
		local distance = 0
		local blockTypeF = T:getBlockType("forward")
		local blockTypeD = T:getBlockType("down")
		for i = 1, maxDistance do
			if blockTypeF ~= "minecraft:obsidian" and blockTypeD ~= "minecraft:obsidian" then -- not in a tower
				if withMarker then -- used to mark 0 coordinate
					T:place("cobble", -1, "down", false) -- place cobblestone or cobbled deepslate to mark zero coordinate
				end
			else	-- obsidian found, could still be in an earlier tower
				if i > 10 then
					break
				end
			end
			T:go("F1x0")
			distance = distance + 1
			blockTypeF = T:getBlockType("forward")
			blockTypeD = T:getBlockType("down")
		end
		if distance == maxDistance then -- obsidian not found ? wrong place/ direction
			print("Obsidian not found")
			error()
		end
		-- will now be at side of a tower
		lib.findCentre() -- move into tower to find the other side
		return distance
	end
	
	function lib.findCentre()
		local width = 0
		-- while obsidian in front or below (previously entered tower) measure width and return to centre
		local blockTypeF = T:getBlockType("forward")
		local blockTypeD = T:getBlockType("down")
		while blockTypeF == "minecraft:obsidian" or blockTypeD == "minecraft:obsidian" do
			T:go("F1x0")
			width = width + 1
			blockTypeF = T:getBlockType("forward")
			blockTypeD = T:getBlockType("down")
		end
		-- will always go outside the tower 1 block. width of 5 block tower = 6
		T:go("R2F"..math.ceil(width / 2)) --return to centre of tower
		T:turnLeft(1) -- now find another edge of the tower, dig forward until out of obsidian
		for i = 1, math.ceil(width) do  -- give additional loops if missed centre
			blockTypeF = T:getBlockType("forward")
			blockTypeD = T:getBlockType("down")
			if blockTypeF == "minecraft:obsidian" or blockTypeD == "minecraft:obsidian" then
				T:go("F1x0")
			else
				break
			end
		end
		-- now outside different edge of the tower
		-- reverse and move width/2, dig up + 1 to mark centre, face original direction
		T:go("L2F"..math.ceil(width / 2).."R1U2x1")
		T:place("minecraft:end_stone", -1, "forward", false) -- place endstone to mark facing direction
		T:down(2)
	end
	
	function lib.findPath(maxLength)
		local blockTypeD = T:getBlockType("down")
		local distance = 0
		while blockTypeD:find("cobble") == nil and distance < maxLength do
			T:go("F1x0")							-- return to 0 axis, 
			distance = distance + 1
			blockTypeD = T:getBlockType("down")
		end
		return distance
	end
	
	-- start at 0,y,0, facing West
	T:dig("up")									-- in case not already done
	local maxLength = 0
	local blockTypeD
	local distance = lib.findNextTower(45, true)-- find W tower (1) and mark trail with cobble
	T:turnRight(2)						
	for i = 1, 8 do								-- head back East 8 blocks, turn left (facing north)
		T:go("F1x0")							-- this path may be off-axis, so dig double height
	end
	T:turnLeft(1)
	lib.findNextTower(30)						-- find NWW tower (2)
	T:turnRight(2)
	distance = lib.findPath(30)
	distance = distance + lib.findNextTower(30)	-- find SWW tower (3)
	T:turnRight(2)
	distance = lib.findPath(30)
	T:turnRight(1) 								-- should be on cobble path
	for i = 1, 21 do							-- move East 21 blocks, turn left facing North
		T:go("F1x0")
	end
	T:turnLeft(1)
	
	distance = lib.findNextTower(45)		-- find NNW tower (4)
	T:turnRight(1)							
	distance = lib.findNextTower(30)		-- find NNE tower (5)
	T:turnRight(1)
	distance = lib.findNextTower(85)		-- find SSE tower (6)
	T:turnRight(1)

	distance = lib.findNextTower(30)		-- find SSW tower (7)
	T:turnRight(1)
	distance = lib.findPath(40)				-- head North to 0 axis
	T:go("R1F13") 							-- return to 0,0 facing East
	distance = lib.findNextTower(45, true)	-- find E tower (8)
	
	T:turnRight(2)						
	for i = 1, 9 do
		T:go("F1x0")						-- this path may be off-axis, so dig double height
	end
	T:turnRight(1)
	
	distance = lib.findNextTower(30)		-- find NEE tower (9)
	T:turnRight(2)
	distance = lib.findPath(30) -- return to 0 axis
	distance = lib.findNextTower(30)		-- find SEE tower (10)
	T:turnRight(2)
	distance = lib.findPath(30) 			-- return to 0 axis
	T:go("L1F33")							-- return to 0, 0
	return {}
end

local function demolishPortal(R) -- 43
	for i = 1, R.height do
		T:dig("forward")
		if i < R.height then
			T:up(1)
		end
	end
	for i = 1, R.width do
		if i < R.width then
			T:go("R1F1L1x1")
		end
	end
	for i = 1, R.height do
		T:dig("forward")
		if i < R.height then
			T:down(1)
		end
	end
	for i = 1, R.width do
		if i < R.width then
			T:go("L1F1R1x1")
		end
	end
	return {}
end

local function digMobTrench(R) -- 65
	local blockType
	-- go down 1 layer at a time height x, move forward length, fill voids
	if R.length == 0 then
		R.length = 8 --common length
	end
	-- check if already facing the wall
	if turtle.detect() then
		T:turnRight(2)
	end
	for i = 1, R.height do
		T:down(1)
		-- tunnel bottom: E# fill voids both sides, remove floor
		T:go("E"..R.length - 1 .."R2", false, 0 , true)
	end
	T:up(R.height)
	if R.height % 2 == 1 then
		T:forward(R.length - 1)
	end
	
	return {}
end

local function digTrench(R) -- 77
	local blockType
	-- go down R.height, move forward
	if R.length == 0 then
		R.length = 4096 -- will go out of loaded chunks and stop or max 4096 on a server
	end
	for i = 1, R.length, 2 do
		local count = 0
		for down = 1, R.height do
			blockType = T:isWaterOrLava("down") 
			-- go down only if no water or lava below
			if string.find(blockType, "water") == nil and string.find(blockType, "lava") == nil then
				T:down(1)
				count = count + 1
			end 
		end
		-- return to surface, continue if block above
		T:go("U"..count)
		-- go up while block in front
		while turtle.detect() do
			blockType = T:getBlockType("forward")
			--print("Ahead: "..blockType)
			if T:isVegetation(blockType) then
				T:dig("forward")
				break
			elseif blockType:find("log") ~= nil then
				T:harvestTree("forward", false)
			else
				T:up(1)
			end
		end
		-- move forward
		T:forward(1)
		-- go down until block detected
		while not turtle.detectDown() do
			blockType = T:isWaterOrLava("down") 
			if string.find(blockType, "water") == nil and string.find(blockType, "lava") == nil then
				T:down(1)
			else
				break
			end
		end
	-- repeat
	end
	return {}
end

local function harvestRun(runLength)
	local blockType
	local blockModifier

	for i = 1, runLength do
		blockType, blockModifier = T:getBlockType("forward") -- store information about the block in front in a table
		if blockType ~= "" then
			if blockType:find("log") ~= nil then
				T:harvestTree(true, false)
			else
				T:forward(1)			
			end	
		else
			T:forward(1)
		end
	end
end	

local function harvestTreeFarm(R) -- 24
	local lib = {}
	
	function lib.getLogCount()
		local count = 0
		for i = 1,16 do
			local item, itemCount = T:getSlotContains(i)
			if item:find("log") ~= nil then
				count = count + itemCount
			end
		end
		
		return count
	end
	
	function lib.initialise()
		local blockType = T:getBlockType("forward")
		local logType = ""
		local startHeight = 0
		local range = 0
		if blockType == "" then
			while turtle.forward() do
				range = range + 1
				if range == 3 then
					break
				end
			end
		end
		blockType = T:getBlockType("forward")
		if blockType:find("dirt") ~= nil then
			T:up(1)
			startHeight = 1
		else
			if blockType:find("log") ~= nil or blockType:find("sapling") ~= nil then
				logType = blockType
			end
		end
		
		return logType, startHeight
	end
		
	local treeType, startHeight = lib.initialise() -- possible ID tree type + move to correct position 1 above dirt
	
	T:forward(1)	-- dig first log/sapling/ air if not planted
	clearRectangle({width = 7, length = 7, up = true, down = true})
	T:go("L1F2L1F2R2")
	local height = 0
	local pastLogCount = -1
	local currentLogCount = lib.getLogCount()
	while currentLogCount ~= pastLogCount do
		T:up(3)
		height = height + 3
		pastLogCount = currentLogCount -- 0 when loop starts
		clearRectangle({width = 12, length = 12, up = true, down = true})
		currentLogCount = lib.getLogCount() -- eg 20 logs from first round
	end	
	T:down(height + startHeight)
	T:go("R1F2R1F2R2")
	
	return {}
end

local function harvestObsidian(R) -- 41
	local heightParts = math.floor(R.length / 8) -- eg 12/8 = 1
	local lastPart = R.length - (heightParts * 8) -- eg 12 - (1 * 8) = 4
	if R.width % 2 ~= 0 then
		R.width = R.width + 1
	end
	for y = 1, R.width do
		print("Mining column "..tostring(y).." of "..tostring(R.width))
		for j = 1, heightParts do
			T:go("m8")
		end
		if lastPart > 0 then
			T:go("m"..tostring(lastPart)) -- eg m4
		end
		-- R.width = tonumber(R.width)
		if y < R.width then
			if y % 2 == 0 then
				T:go("L1F1L1")
			else
				T:go("R1F1R1")
			end
		end
	end
	return {}
end

local function manageFarm()
	local lib = {}
	
	function lib.checkPosition()
		--[[ first function called on start]]
		local atHome = false
		local blockType = T:getBlockType("down")
		print("Checking position\n"..blockType.. " below")
		if blockType:find("water") ~= nil then -- over water
			if T:getBlockType("forward") == "minecraft:chest" then -- atHome, but facing to right of crops
				atHome = true
				T:turnRight(1)
				if T:getBlockType("forward") == "minecraft:chest" then -- confirms in correct position, back to crops
					T:turnRight(2)
				else -- facing crafting table
					T:turnRight(1)
				end
			else -- not a chest: facing crops or crafting table
				T:turnRight(1)
				if T:getBlockType("forward"):find("chest") ~= nil then -- confirms was facing crops
					atHome = true
					T:turnLeft(1)
				end
			end
			-- should now be facing crops. may be crafting table to left
		end
		return atHome-- now facing crops
	end
	
	function lib.crossFarm()
		-- used with goHome to find starting point
		local blockType = ""
		local isReady, cropType, status = lib.isCropReady("down")
		-- will go forward until chest or cobble detected below
		-- if detected within 1 move, this is ignored
		local numMoves = 0
		local endOfPath = false
		while not endOfPath do
			blockType = T:getBlockType("down", -1)
			if blockType == "" or cropType ~= "" then --crops or nothing below
				turtle.forward()
			elseif blockType:find("chest") ~= nil or blockType:find("cobble") ~= nil then
				endOfPath = true
			end
			numMoves = numMoves + 1
		end
		return blockType -- either chest or cobble
	end
	
	function lib.farmInFront()
		--[[ facing crops on first farm. move to next farm in front ]]
		T:go("U1L1F11D1R1")						-- on next farm, facing crops
		local crop = lib.manageTree()			-- refuel, gather seeds and other crops
		local isFarmToRight, _ = lib.harvest(crop)	-- harvest field, store crops
		return isFarmToRight
	end
	
	function lib.farmToRight()
		--[[ facing crops on first farm. move to next farm on right side ]]
		T:go("U1F11D1")		-- on next farm, facing crops
		local crop = lib.manageTree()	-- refuel, gather seeds and other crops
		lib.harvest(crop)		-- harvest field, store crops
	end
	
	function lib.getCrops()
		T:turnRight(1)
		if T:getBlockType("forward") == "minecraft:chest" then
			lib.getSeeds("forward")
		end
		T:turnRight(1)
		if T:getBlockType("forward") == "minecraft:chest" then
			lib.getVeg("forward")
		end
		T:turnRight(2)
	end
	
	function lib.getSaplings(direction)
		--[[ get a single sapling from the chest ]]
		if direction == nil then
			direction = "forward"
		end
		while T:suck(direction, 1) do end -- remove saplings/ seeds

		T:dropItem("sapling", direction, 1) -- drop all but 1 saplings
		T:dropItem("seeds", direction, 0) -- drop all seeds
		
		return T:getItemSlot("sapling", -1)
	end
	
	function lib.getSeeds(direction)
		--[[ get 1 stack of wheat seeds or 1 stack of beetroot seeds ]]
		-- current position facing crops	
		print("Collecting seeds from storage")
		T:go("R1")
		while T:suck(direction, 1) do end -- remove saplings/ seeds
		T:dropItem("sapling", direction, 0) -- drop all saplings
		T:dropItem("minecraft:wheat_seeds", direction, 64) -- drop all but 64 seeds
		T:dropItem("minecraft:beetroot_seeds", direction, 64)
		T:go("L1") -- return to face crops
		local crop = ""
		if T:getItemSlot("minecraft:wheat_seeds", -1) > 0 then
			crop = "wheat"
			print("Field crop = "..crop)
		elseif T:getItemSlot("minecraft:beetroot_seeds", -1) > 0 then
			crop = "beetroot"
			print("Field crop = "..crop)
		end
		
		return crop
	end
	
	function lib.getToolSlots()
		local tools = {}
		local logSlot = 0
		local slot = T:getItemSlot("minecraft:diamond_hoe")
		if slot > 0 then
			table.insert(tools, slot)
		end
		slot = T:getItemSlot("minecraft:diamond_pickaxe")
		if slot > 0 then
			table.insert(tools, slot)
		end
		slot = T:getItemSlot("minecraft:crafting_table")
		if slot > 0 then
			table.insert(tools, slot)
		end
		slot = T:getItemSlot("log", -1)
		if slot > 0 then
			table.insert(tools, slot)
			logSlot = slot
		end
		
		return tools, logSlot -- empty table or list of important slots
	end
	
	function lib.getVeg(direction)
		-- assume only one type of crop per field
		print("Collecting crops from storage")
		direction = direction or "forward"
		while T:suck(direction, 1) do end -- remove carrots / potatoes / wheat / beetroot
		--clsTurtle.dropItem(self, item, direction, keepAmount)
		T:dropItem("wheat", direction, 0)		-- drop all wheat
		T:dropItem("beetroot", direction, 0)	-- drop all beetroot
		T:dropItem("carrot", direction, 64)		-- drop all but 64 carrots
		T:dropItem("potato", direction, 64)		-- drop all but 64 potato
		local crop = ""
		if T:getItemSlot("potato", -1) > 0 then
			crop = "potato"
			print("Field crop = "..crop)
		elseif T:getItemSlot("carrot", -1) > 0 then
			crop = "carrot"
			print("Field crop = "..crop)
		end
		
		T:turnRight(2) -- face crops
		return crop
	end
	
	function lib.goHome()
		-- after a re-boot go to start
		local success = false
		local onTree = false
		local onWater = false
		local onChest = false
		local onCobble = false
		local onField = false

		-- is tree above or in front
		-- check if log in front
		if T:getBlockType("forward"):find("log") ~= nil then -- about to harvest tree
			lib.harvestTree("forward")
			onTree = true
		elseif T:getBlockType("up"):find("log") ~= nil then -- harvesting tree
			lib.harvestTree("up")
			onTree = true
		elseif T:getItemSlot("log", -1) > 0 then -- tree just harvested 
			onTree = true
			turtle.up()
			if T:getBlockType("up"):find("log") ~= nil then -- harvesting tree
				lib.harvestTree("up")
			else
				while turtle.down() do end
			end
		end
		
		if onTree then -- tree harvested, but direction unknown
			local blockType = ""
			local turns = 0
			
			blockType = T:getBlockType("down")
			if blockType:find("chest") ~= nil  then -- probably on seed chest
				onChest = true
			end
			while not onChest do
				if turtle.forward() then
					blockType = T:getBlockType("down")
					if blockType:find("chest") ~= nil  then
						onChest = true
					else
						turtle.back()
					end
				end
				if not onChest then
					T:turnRight(1)
					turns = turns + 1
				end
				if turns == 4 then
					break
				end
			end -- should be on chest. If not should be over water
			if not onChest then
				atHome = lib.checkPosition()
			end
			if atHome then
				return true -- exit function
			end
		else
			while turtle.down() do end -- no tree around, no logs onboard
		end
		if not onChest then -- no sign of tree harvest
			local blockType = T:getBlockType("down")
			if blockType:find("water") ~= nil then
				onWater = true
			elseif blockType:find("cobble") ~= nil then
				onCobble = true
			elseif blockType == "minecraft:dirt" or blockType == "minecraft:grass_block" then --on field after call to go down
				T:up(1)
				onField = true
			else
				--check for crops below
				local isReady, cropType, status = lib.isCropReady("down")
				if cropType ~= "" then
					onField = true
				end
			end
		end
		
		if onField then
			--[[ continue across until detect cobble or chest below ]]
			local cobble = -1
			local endBlock = lib.crossFarm()
			if endBlock:find("cobble") ~= nil then
				onCobble = true
			elseif endBlock:find("chest") ~= nil then
				onChest = true
			end
			onField = false
		end
		-- check now for onWater, onCobble, onChest
		if onWater then -- must be on non-start water
			--[[0 chests near = top right / top left on single farm / bottom right on single farm
				1 chest near = top left on extended farm/ bottom right on extended farm
				crop,crop,chest,cobble = bottom right extended
				crop,crop,cobble,chest = top left extended farm
				]]
			-- turn until facing either cobble or chest
			local cobbleInFront = false
			local chestInFront = false
			local blockType = ""
			for i = 1, 4 do
				blockType = T:getBlockType("forward")
				if blockType:find("chest") ~= nil then
					onChest = true
				end
				if blockType:find("cobble") ~= nil then
					onCobble = true
				end
				if onChest or onCobble then
					T:go("U1F1")
					break
				else
					T:turnRight(1)
				end
			end
		end
		if onCobble then -- if onCobble find chest
			-- check which direction cobble continues
			for i = 1, 4 do
				if turtle.forward() then -- no obstruction
					local blockType = T:getBlockType("down")
					if blockType:find("cobble") ~= nil then --continue this route
						break
					elseif blockType == "minecraft:chest" then --stay here and exit loop
						onChest = true
						break
					end
				else -- blocked ? tree/sapling
					local blockType = T:getBlockType("forward")
					if blockType:find("log") ~= nil or blockType:find("sapling") ~= nil then
						-- next to tree/sapling, but not on chest, must be behind extended farm tree
						T:go("R2F9") -- turn round and continue forwards to first farm tree
						blockType = T:getBlockType("down")
						if blockType == "minecraft:chest" then --stay here and exit loop
							onChest = true
							break
						end
					end
				end
				if not onChest then
					turtle.back()
					T:turnLeft(1)
				end
			end
			if not onChest then -- still on cobble, facing wall length
				-- move forward until cobble runs out-- will be over retaining wall, or on chest
				while T:getBlockType("down"):find("cobble") ~= nil do
					if not turtle.forward() then -- movement obstructed, must be tree/sapling
						local blockType = T:getBlockType("forward")
						if blockType:find("log") ~= nil or blockType:find("sapling") ~= nil then
							-- next to tree/sapling, but not on chest, must be behind extended farm
							T:go("R2F9") -- turn round and continue forwards
							blockType = T:getBlockType("down")
							if blockType == "minecraft:chest" then --stay here and exit loop
								onChest = true
								break
							end
						end
					end
				end
				-- moved over last of cobble without obstruction = outside farm
				-- no longer on cobble, could be a chest
				if  T:getBlockType("down") == "minecraft:chest" then
					onChest = true
				else
					-- turn round and continue back along cobble until reach other end
					T:go("R2")
					while T:getBlockType("down"):find("cobble") ~= nil do
						if not turtle.forward() then -- movement obstructed, must be tree/sapling
							local blockType = T:getBlockType("forward")
							if blockType:find("log") ~= nil or blockType:find("sapling") ~= nil then
								-- next to tree/sapling
								blockType = T:getBlockType("down")
								if blockType == "minecraft:chest" then --stay here and exit loop
									onChest = true
									break
								end
							end
						end
					end
				end
			end
			-- cobble ended, over edge of wall, on tree base with no sapling, or on chest
		end
		
		if onChest then -- if onChest find water
			-- check if next block is a chest
			for i = 1, 4 do
				if turtle.forward() then -- no obstruction
					local blockType = T:getBlockType("down")
					if blockType == "minecraft:dirt" or blockType == "minecraft:grass_block" then -- on tree base
						turtle.back()
						break
					elseif blockType == "minecraft:chest" then --stay here and exit loop
						onChest = true
						break
					end
				else -- blocked ? tree/sapling
					local blockType = T:getBlockType("forward")
					if blockType:find("log") ~= nil or blockType:find("sapling") ~= nil then
						-- next to tree/sapling
						break
					end
				end
				turtle.back()
				T:turnLeft(1)
			end
			-- now on chest next to tree
			T:go("R1F1D1")
			blockType = T:getBlockType("down")
			if blockType:find("water") ~= nil then
				return lib.checkPosition()
			else -- no water so return to other side of chest
				T:go("R2U1F2D1")
				blockType = T:getBlockType("down")
				if blockType:find("water") ~= nil then
					return lib.checkPosition()
				end
			end
		end
			
		return success
	end
	
	function lib.gotoTree()
		-- assume facing crops
		T:turnRight(1)
		print("Extracting saplings from storage")
		lib.getSaplings("forward") -- gets one sapling only (if present)
		print("Moving to tree position")
		T:go("U1F1R1")
		lib.harvestTree("forward") -- fell tree or plant sapling, ends facing tree / dirt / sapling
		T:go("R1F1D1") -- return to base, facing crafting table
	end
	
	function lib.harvest(crop)
		--[[
		cover the field in a set pattern.
		harvest crops if ripe
		till soil and plant new ones
		place seeds / harvest in chests
		return farm(s) to right / front
		]]
		T:go("U1") --ready to farm field
		local isFarmToRight = false
		local isFarmToFront = false
		local width = 9
		local length = 10
		local toRight = true
		for l = 1, length do
			for w = 1, width do
				isReady, blockType, _ = lib.isCropReady("down")
				turtle.select(1)
				if blockType == "" and crop ~= "" then -- ? untilled soil or air above water
					turtle.digDown()
					turtle.digDown()
					lib.plantCrop(crop, "down")
				elseif isReady then
					if crop == "" then
						crop = lib.setCrop(blockType)
					end
					lib.plantCrop(blockType, "down")
				end
				T:forward(1)
				if l == 1 and w == width then -- last block of first row at front of farm
					T:forward(1)
					if T:getBlockType("down"):find("chest") ~= nil then
						isFarmToRight = true
					end
					turtle.back()
				end
			end
			-- end of the row: change direction
			if l < length then -- do not turn at final row
				lib.plantCrop(crop, "down")
				if toRight then
					T:go("L1F1L1")
				else
					T:go("R1F1R1")
				end	
			end
			toRight = not toRight
		end
		T:go("R1F1") -- goes over chest/cobble on top wall
		if T:getBlockType("down"):find("chest") ~= nil then
			isFarmToFront = true
		end
		T:go("R2F"..length.."D1L1") -- go straight across to seed chest 10 blocks, facing crops
		lib.storeCrops() -- rotates from start to deposit seeds and crops, ends facing crops
		return isFarmToRight, isFarmToFront
	end	
	
	function lib.harvestTree(direction)
		--[[
			start in front of / during tree harvest
			Check if sapling present
			Harvest tree if present, replant sapling
			Dispose of apples. Use sticks as fuel
			Return to base
		]]
		direction = direction or "forward"
		local inFront = T:getBlockType("forward")
		print("Checking tree")
		if inFront == "" then -- no tree or sapling
			print("No sapling: panting sapling")
			T:place("sapling", -1, "forward", false)
		elseif inFront:find("log") ~= nil or direction == "up" then -- tree above or in front
			-- clsTurtle.harvestTree(self, extend, craftChest, direction)
			print("Harvesting tree")
			T:harvestTree(false, false, direction) --do not investigate side branches in case chunk unloaded
			T:go("R2F1R2") -- face dirt
			-- place(self, blockType, damageNo, direction, leaveExisting, signText)
			T:place("sapling", -1, "forward", false)
		end
		print("Dropping saplings into storage")
		T:dropItem("sapling", "down", 0) -- drop all saplings down into chest
		print("Disposing of apples")
		T:dropItem("apple", "up", 0) -- drop any apples
		local slot = T:getItemSlot("minecraft:stick") 
		if slot > 0 then -- use any sticks to refuel
			turtle.select(slot)
			turtle.refuel()
		end
		-- ends facing tree/sapling/dirt
	end
	
	function lib.manageTree()
		--[[ starting position facing crops ]]
		local crop = ""
		print("Running Tree Manager")
		lib.gotoTree() 			-- check for sapling or harvest tree, retuns to start, ends facing crafting table
		lib.refuelWithLogs() 	-- use any logs for fuel, ends facing crops
		crop = lib.getSeeds("forward") -- get 1 stack of beetroot / wheat seeds, ends facing crops
		if crop == "" then
			print("No seeds available. Checking root veg")
			T:turnRight(2)					-- face crop chests
			crop = lib.getVeg("forward")	-- gets any carrots / potatoes, ends facing crops
		end
		print("Sorting inventory")
		T:sortInventory()
		return crop
	end
	
	function lib.initialise() 
		--[[ ensure pickaxe on left and crafting table on right are equipped ]]
		T:setEquipment()
		T:checkInventoryForItem({"minecraft:diamond_hoe"}, {1}, true) -- if already in place will continue
		-- equip hoe, swapping out crafting chest
		if T:equip("right", "minecraft:diamond_hoe", 0) then
			return true
		end
		return false
	end
	
	function lib.isCropReady(direction)
		local isReady = false
		local status = ""
		local blockType = ""
		local success = false
		local data = {}

		direction = direction or "forward"

		if direction == "down" then
			success, data = turtle.inspectDown()
		else
			success, data = turtle.inspect()
		end
		if success then
			blockType = data.name
			if data.name == "minecraft:carrots" then
				status = data.state.age.." / 7"
				if data.state.age == 7 then
					isReady = true
				end
			elseif data.name == "minecraft:potatoes" then
				status = data.state.age.." / 7"
				if data.state.age == 7 then
					isReady = true
				end
			elseif data.name == "minecraft:wheat" then
				status = data.state.age.." / 7"
				if data.state.age == 7 then
					isReady = true
				end
			elseif data.name == "minecraft:beetroots" then
				status = data.state.age.." / 3"
				if data.state.age == 3 then
					isReady = true
				end
			end
		end
		return isReady, blockType, status
	end
		
	function lib.plantCrop(crop, direction)
		local planted = false
		turtle.digDown() -- harvest existing and till soil
		if crop:find("potato") ~= nil then
			T:dropItem("poison", "up", 0)
		end
		planted = T:place("carrot", -1, direction)
		if not planted then
			planted = T:place("potato", -1, direction)
		end
		if not planted then
			planted = T:place("beetroot_seeds", -1, direction)
		end
		if not planted then
			planted = T:place("wheat_seeds", -1, direction)
		end
	end
	
	function lib.refuelWithLogs()
		-- assume positioned in front of crafting table, saplings already dropped, apples dumped, sticks refuelled
		print("Checking for logs")
		local tools, logSlot = lib.getToolSlots() 			-- empty table or slots with hoe, axe, crafting table, logs
		if logSlot > 0 then 								-- logs onboard so need to craft to planks
			print("Logs found: crafting to planks")
			T:go("F1L1") 									-- move to buried crafting chest facing crop chest
			if T:getBlockType("down"):find("crafting") ~= nil then
				local toolSlot = T:getFirstEmptySlot() 		-- find an empty slot in the inventory
				turtle.select(toolSlot)						-- select empty slot
				T:dig("down", false, toolSlot)				-- dig crafting table to empty slot
				if T:equip("right", "minecraft:crafting_table") then -- swap equipment on right side
					slot = T:getFirstEmptySlot() 			-- find an empty slot in the inventory
					T:suck("forward", slot, 64) 			-- take first item from crop chest into empty slot eg wheat / carrots etc
					T:drop("down", slot)					-- drop crops down
					T:drop("forward", toolSlot)				-- drop hoe/axe into chest
					turtle.craft()							-- craft logs to planks
					turtle.refuel()							-- refuel using planks
					T:suck("forward", toolSlot)				-- recover hoe / axe
					-- local cropSlot = T:getFirstEmptySlot() 	-- find an empty slot in the inventory
					T:suck("down", 1)						-- recover crops from hole	
					
					--local item = T:getSlotContains(toolSlot)-- find what was recovered
					if T:equip("right", "minecraft:diamond_hoe") then			-- re-equip and return crafting table
						T:place("minecraft:crafting_table", -1, "down")			-- replace crafting table into hole
					elseif T:equip("right", "minecraft:diamond_pickaxe") then	-- re-equip and return crafting table
						T:place("minecraft:crafting_table", -1, "down")			-- replace crafting table into hole
					end
					while turtle.drop() do end				-- replace crops into chest
				end
			else -- no crafting table
				turtle.select(logSlot)
				turtle.refuel()
			end
			T:go("L1F1L1")									-- facing crops
		else -- no logs so no need for crafting table
			T:go("R1") 										-- facing crops
		end
	end
	
	function lib.returnToBack()
		--[[ move from farm at front back to starting farm ]]
		T:go("U1R1F11D1L1")
	end
	
	function lib.returnToLeft()
		--[[ move from farm on right back to starting farm ]]
		T:go("U1R2F11D1R2")
	end
	
	function lib.setCrop(blockType)
		if blockType:find("carrot") ~= nil then
			return "carrot"
		end
		if blockType:find("potato") ~= nil then
			return "potato"
		end
		if blockType:find("beetroot") ~= nil then
			return "beetroot"
		end
		if blockType:find("wheat") ~= nil then
			return "wheat"
		end
	end
	
	function lib.storeCrops()
		-- place crops and seeds into chests
		T:turnRight(1)
		if T:getBlockType("forward") == "minecraft:chest" then
			lib.storeSeeds("forward")
		end
		T:turnRight(1)
		if T:getBlockType("forward") == "minecraft:chest" then
			lib.storeVeg("forward")
		end
		T:turnRight(2) -- facing crops again
	end
	
	function lib.storeSeeds(direction)
		direction = direction or "forward"
		if T:getBlockType(direction):find("chest") ~= nil then -- chest exists
			T:dropItem("minecraft:wheat_seeds", direction, 0) -- drop all wheat seeds
			T:dropItem("minecraft:beetroot_seeds", direction, 0) -- drop all beetroot seeds
		end
	end
	
	function lib.storeVeg(direction)
		direction = direction or "forward"
		T:dropItem("apple", "up", 0) -- drop all apples
		T:dropItem("poison", "up", 0) -- drop all poison potatoes
		if T:getBlockType(direction):find("chest") ~= nil then
			T:dropItem("carrot", direction, 0) -- drop carrots
			T:dropItem("potato", direction, 0) -- drop potato
			T:dropItem("minecraft:wheat", direction, 0) -- drop all wheat
			T:dropItem("minecraft:beetroot", direction, 0) -- drop all beetroot
		end
	end
	
	function lib.watchFarm()
		--[[
		check status of crops in front of turtle.
		call lib.harvest when ripe
		return farm(s) found in front or to the right
		]]
		local isReady = false
		local blockType, status
		-- check state of crop in front. Harvest if ripe
		while not isReady do
			isReady, blockType, status = lib.isCropReady("forward")
			if not isReady then
				if blockType == "" then
					print("No crops found in front")
					print("Plant seeds, carrots, potatoes")
				else
					print("Waiting for "..blockType.." status: "..status)
				end
				sleep(60)
			end
		end
		print("Local crops ripe")
		
		return lib.manageTree() -- "" or collected seeds / root crops
	end
	
	--[[
		called from args on start, or from user choice
		farm already built, needs planting and/or harvesting
		needs both pickaxe and hoe
		may start in any position if chunk unloaded while running
	]]
	local atHome = lib.checkPosition()
	if atHome then --already at home
		if not lib.initialise() then -- false if missing hoe
			return {"Unable to equip hoe."}
		end
	else
		if not lib.goHome() then -- try to find home
			return
			{
				"Unable to determine my position.\n",
				"Place me in the lower left corner",
				"over water, facing the crops",
				"with chests to my right and behind"
			}
		end
	end
	
	while true do -- start infinite loop of watching crops, farming all modules
		local crop = lib.watchFarm() --waits if required, returns crop type when ripe
		print("Beginning "..crop.." harvest")
		local isFarmToRight, isFarmToFront = lib.harvest(crop)
		if isFarmToRight then
			lib.farmToRight() -- no action if no farmToRight
			lib.returnToLeft() -- return home and continue with front
			isFarmToRight = false
		end
		
		if isFarmToFront then
			isFarmToRight = lib.farmInFront()
			if isFarmToRight then
				lib.farmToRight() -- no action if no farmToRight
				lib.returnToLeft() -- return home 
			end
			lib.returnToBack()
		end
	end
	return {}
end

local function manageFarmSetup(farmType) -- 26, 33
	-- check if startup.lua exists
	T:clear()
	if fs.exists("start.txt") then
		print("This turtle has been configured to")
		print("start automatically and run the farm")
		print("management program.\n")
		print("Do you want to disable this? (y/n)")
		response = string.lower(read())
		if response == "y" then
			fs.delete("start.txt")
		else
			if farmType == "farm" then
				manageFarm()
			else
				manageTreeFarm()
			end
		end
	else
		print("This turtle can be configured")
		print("to be a dedicated farm manager.")
		print("It will start automatically and")
		print("monitor the farm complex, harvesting")
		print("and replanting automatically.\n")
		if farmType == "farm" then
			print("You must provide a diamond hoe")
			print("and place me over the water source")
		else
			print("Place me between the chest and")
			print("first sapling / tree")
		end
		print("\nAre you ready? (y/n)")
		local response = string.lower(read())
		if response == "y" then
			if not fs.exists("startup.lua") then
				local h = fs.open("startup.lua", "w")
				h.writeLine('function main()')
				h.writeLine('	if fs.exists("start.txt") then')
				h.writeLine('		local handle = fs.open("start.txt", "r")')
				h.writeLine('		local cmd = handle.readLine()')
				h.writeLine('		handle.close()')
				h.writeLine('		shell.run("tk.lua "..cmd)')
				h.writeLine('	end')
				h.writeLine('end')
				h.writeLine('main()')
				h.close()
			end
			local h = fs.open("start.txt", "w")
			if farmType == "farm" then
				h.writeLine('farm')
			else
				h.writeLine('tree')
			end
			h.close()
		end
		T:clear()
		print("Startup files written")
		if farmType == "farm" then
			print("Press Enter to check equipment")
			read()
			local equippedRight, equippedLeft = T:setEquipment()
			if equippedRight ~= "minecraft:crafting_table" then
				T:checkInventoryForItem({"minecraft:crafting_table"}, {1})
				local equippedRight, equippedLeft = T:setEquipment()
			end
			T:checkInventoryForItem({"minecraft:diamond_hoe"}, {1})
			print("Place oak, birch, spruce saplings in")
			print("the chest on the right of the tree")
			print("Also wheat and beetroot seeds.\n")
			print("Place carrots and potatoes in")
			print("the chest on the left of the tree\n")
		else
			print("Drop saplings into the water")
			print("if none are planted")
		end
		print("Do you want to start now? (y/n)")
		local response = string.lower(read())
		if response == "y" then
			if farmType == "farm" then
				return manageFarm()
			else
				return manageTreeFarm()
			end
		end
	end
	return {}
end

local function manageTreeFarm()
	local lib = {}
	
	function lib.emptyLogs()
		for i = 1, 16 do
			if turtle.getItemCount(i) > 0 then
				turtle.select(i)
				local name = T:getItemName(i)
				if name:find("sapling") ~= nil then
					turtle.dropDown()
				elseif name:find("apple") ~= nil then
					turtle.drop()
				elseif name:find("stick") ~= nil then
					turtle.refuel()
				end
			end
		end
		T:sortInventory()
		-- convert 6 logs-->planks-->360 fuel
		local logsKept = false
		local logSlot = 0
		for i = 1, 16 do
			if turtle.getItemCount(i) > 0 then
				if T:getSlotContains(i):find("log") ~= nil and turtle.getItemCount(i) > 10 then -- 10+ logs in this slot
					turtle.select(i)
					if not logsKept then
						turtle.drop(turtle.getItemCount(i) - 10)
						logsKept = true
						logSlot = i
					else
						turtle.drop()
					end
				else
					turtle.drop()
				end
			end
		end
		if logsKept then
			T:sortInventory()
			turtle.select(16)
			turtle.craft()
			turtle.refuel()
		end
	end
	
	function lib.initialise()
		local ready = false
		local blockType = ""
		local chest = false
		for i = 1, 4 do -- check if in starting position with chests on 2 sides
			blockType = T:getBlockType("forward")
			if blockType == "minecraft:chest" then
				chest = true
				break
			end
			T:turnRight(1)
		end
		if chest then	-- in starting position
			T:turnRight(2)
			ready = true
		else	-- stopped in random place around the farm, so return to start
			-- allow 10 secs to stop else find start position
			local countDown = 10
			for i = countDown, 1, -1 do
				T:clear()
				print("Hit Ctrl+T to terminate program")
				print("Starting in "..i.." seconds...")
			end
			if lib.goHome() then
				ready = true
			end
		end
		return ready
	end
	
	function lib.getSaplings()
		T:go("L1F2L1F1R1D5F1R2") -- over sapling chest, facing water
		turtle.select(1)
		while turtle.suckDown() do end
		local saplingsKept = false
		for i = 1, 16 do
			if turtle.getItemCount(i) > 0 then
				-- slotContains, slotCount, slotDamage
				item = T:getSlotContains(i)
				if item == "minecraft:stick" then
					turtle.select(i)
					turtle.refuel()
				elseif item:find("sapling") == nil then -- not saplings
					turtle.select(i)
					turtle.dropDown()
				elseif item:find("sapling") ~= nil then --saplings
					if saplingsKept then
						turtle.select(i)
						turtle.dropDown()
					else
						saplingsKept = true
					end
				end
			end
		end
		-- max one stack of saplings, sticks used for fuel, others returned
		T:sortInventory()
		T:go("F1U5L1F1R1F2L1")
	end
	
	function lib.goHome()
		local atHome = false
		local onCobble = false
		local hitCobble = false
		local onChest = false
		local onWater = false
		-- find starting position
		-- not at home as lib.initialise failed
		-- ? tree above
		local blockType = T:getBlockType("up")
		if blockType:find("log") ~= nil then -- tree above
			T:harvestTree(false, false, "up")
		end
		-- ? chest/hopper below
		blockType = T:getBlockType("down")
		if blockType == "minecraft:chest" then --over sapling chest
			while turtle.detect() do
				turtle.turnRight()
				onChest = true
			end
		elseif blockType == "minecraft:hopper" then --over hopper 
			for i = 1, 4 do
				if turtle.forward() then
					if T:getBlockType("down") == "minecraft:chest" then
						T:turnRight(2)
						onChest = true
						break
					else
						turtle.back()
					end
				end
				turtle.turnRight()
			end
		end
		if onChest then
			T:go("F1U5L1F1R1F2L1")
			if lib.initialise() then
				atHome = true
			end
		else
			-- ? in the treetops
			blockType = T:getBlockType("down")
			if blockType == "" or blockType:find("leaves") ~= nil then
				while blockType == "" or blockType:find("leaves") ~= nil do
					T:down(1)
					blockType = T:getBlockType("down")
				end
			end
			blockType = T:getBlockType("down")
			if blockType:find("sapling") ~= nil then
				T:go("F1D1")
				blockType = T:getBlockType("down")
			end
			if blockType:find("torch") ~= nil or
			   blockType == "minecraft:dirt" or 
			   blockType == "minecraft:grass_block" then
			
				for i = 1, 4 do
					if turtle.forward() then
						if T:getBlockType("down") == "" then
							T:down(2)
							onWater = true
							break
						end
						turtle.back()
					end
					T:turnRight(1)
				end
			elseif blockType == "minecraft:cobblestone" then
				onCobble = true
			elseif blockType:find("water") ~= nil then
				onWater = true
			end
			if onWater then --move to cobble
				while T:getBlockType("down"):find("water") ~= nil do
					if not turtle.forward() then
						--hit the one cobble block above sapling chest
						hitCobble = true
						break
					end
				end
				if not hitCobble then
					-- now not over water: should be cobble or over ditch to hopper
					if T:getBlockType("down") == "minecraft:cobblestone" then
						onCobble = true
					else
						T:forward(1)
						if T:getBlockType("down") == "minecraft:cobblestone" then
							onCobble = true
						end
					end
				end
			end
			if onCobble then -- find home
				-- find cobble direction
				onCobble = false
				for i = 1, 4 do
					T:go("L1F1")
					if T:getBlockType("down") == "minecraft:cobblestone" then
						onCobble = true
						break
					end
					turtle.back()
				end
				-- continue on cobble until hitCobble
				while not hitCobble do
					while T:getBlockType("down") == "minecraft:cobblestone" do
						if not turtle.forward() then
							if T:getBlockType("forward") == "minecraft:cobblestone" then
								hitCobble = true
								break
							end
						end
					end
					if not hitCobble then
						-- not cobble below, on corner
						turtle.back()
						T:turnLeft(1)
					end
				end
			end
			if hitCobble then -- find home
				hitCobble = false
				-- probably hit from widest cobble path. look for space under cobble block
				if T:getBlockType("down") == "" then --could be over hopper
					T:down(1)
					if T:getBlockType("forward") == "" then
						hitCobble = true
					end
				else -- not over hopper
					T:go("L1F1R1F1R1D1")
					if T:getBlockType("forward") == "" then
						hitCobble = true
					else
						T:go("U2F2D2")
						if T:getBlockType("forward") == "" then
							hitCobble = true
						end
					end
				end
				if hitCobble then-- now over hopper column
					T:go("R2U3L1F1R1F2R1")
					blockType = T:getBlockType("forward")
					if blockType == "minecraft:chest" then
						atHome = true
						lib.emptyLogs()
					end
					T:turnRight(2)
				end
			end
		end
		
		return atHome
	end
	
	function lib.harvest()
		-- started from manageTreeFarm as first sapling grown
		local success = true
		local blockType
		local firstDirt = true
		for  j = 1, 7 do
			for i = 1, 3 do
				blockType = T:getBlockType("forward")
				if blockType == "" then --nothing ahead, so plant sapling
					if firstDirt then
						firstDirt = false
						T:forward(2)
					else
						T:go("U1F1")
						local saplingSlot, name, count = T:getSaplingSlot("sapling")
						if count > 1 then
							T:place("sapling", -1, "down", false)
						end
						T:go("F1D1")
					end
				else -- block ahead, sapling or tree
					if string.find(blockType, "log") ~= nil then
						-- clsTurtle.harvestTree(extend, craftChest, direction)
						T:harvestTree(true, false, "forward")
						if firstDirt then
							firstDirt = false
							T:forward(1)
						else
							turtle.up()
							local saplingSlot, name, count = T:getSaplingSlot("sapling")
							if count > 1 then
								T:place("sapling", -1, "down", false)
							end
							T:go("F1D1")
						end
					elseif  string.find(blockType, "sapling") ~= nil then
						T:go("U1F2D1")
					end	
				end
			end
			if j % 2 == 1 then --odd 1,3,5,7
				T:go("R1F2R1")
			else
				T:go("L1F2L1")
			end
		end
		T:go("F6R1F14L1") --facing chest
		blockType = T:getBlockType("forward")
		if blockType == "minecraft:chest" then -- back home
			T:turnRight(2)
			blockType = T:getBlockType("forward")
			if blockType == "" then --nothing ahead, so plant sapling
				T:place("sapling", -1, "forward", false)
			end
			T:turnRight(2)
			lib.emptyLogs()
			T:turnRight(2)
		else
			success = false
		end
		return success
	end
	
	if lib.initialise() then
		while true do
			local blockType = ""
			local waiting = true
			local needsPlanting = false
			local hasSaplings = false
			-- check state of sapling in front. Harvest if changed to log
			while waiting do
				blockType = T:getBlockType("forward")
				if blockType == "" then --no sapling or log
					needsPlanting = true
					break
				elseif blockType:find("log") ~= nil then
					waiting = false
				else --sapling
					print("Waiting for "..blockType)
					sleep(60)
				end
			end
			lib.getSaplings()
			if T:getItemSlot("sapling", -1) > 0 then
				hasSaplings = true
			end
			if (hasSaplings and needsPlanting) or not waiting then
				if not lib.harvest() then-- harvest trees and plant saplings
					break
				end
			end
		end
	end
		
	return {}
end

local function measure(R) -- 101
	-- measure height/ depth / length
	local blocks = 0
	local message = ""
	if R.choice == 101 then		-- height
		if R.subChoice == 1 then		-- obstruction above
			while turtle.up() do
				blocks = blocks + 1
			end
		elseif R.subChoice == 2 then	-- end of wall ahead
			while turtle.detect() do
				if turtle.up() then
					blocks = blocks + 1
				else
					message = "Obstruction above stopped measurement"
					break
				end
			end
		end
		for i = 1, blocks do
			turtle.down()
		end
		return {"Height measured: ".. blocks, message}
	elseif R.choice == 102 then	-- depth
		if R.subChoice == 1 then		-- obstruction below
			while turtle.down() do
				blocks = blocks + 1
			end
		elseif R.subChoice == 2 then	-- end of wall in front
			while turtle.detect() do
				if turtle.down() then
					blocks = blocks + 1
				else
					message = "Obstruction below stopped measurement"
					break
				end
			end
		elseif R.subChoice == 3 then	-- water / lava below
			local blockType = T:getBlockType("down")
			while blockType == "" do
				if turtle.down() then
					blocks = blocks + 1
					blockType = T:getBlockType("down")
				else
					message = blockType.." below stopped measurement"
					break
				end
			end
			if blockType:find("lava") ~= nil or blockType:find("water") ~= nil then
				message = blockType.." found"
			end
		end
		for i = 1, blocks do
			turtle.up()
		end
		return {"Depth measured: ".. blocks, message}
	elseif R.choice == 103 then	-- length
		if R.subChoice == 1 then		-- obstruction ahead
			while turtle.forward() do
				blocks = blocks + 1
			end
		elseif R.subChoice == 2 then	-- end of ceiling above
			message = "Measured to end of ceiling"
			while turtle.detectUp() do
				if turtle.forward() then
					blocks = blocks + 1
				else
					message = "Obstruction ahead stopped measurement"
					break
				end
			end
		elseif R.subChoice == 3 then	-- end of floor below
			message = "Measured to end of floor"
			while turtle.detectDown() do
				if turtle.forward() then
					blocks = blocks + 1
				else
					message = "Obstruction ahead stopped measurement"
					break
				end
			end
		end
		T:turnRight(2)
		for i = 1, blocks do
			turtle.forward()
		end
		T:turnRight(2)
		return {"Length measured: ".. blocks .." from start point.", "Add 1 to compensate.", message}
	elseif R.choice == 104 then	-- depth of stretch of water
		--R.length = 0 to auto calculate
		R.width = 1
		R.silent = true
		R.useBlockType = ""
		R.data = "clearWaterPlants"
		R.height = clearWaterPlants(R)[1]
		return {"Greatest depth measured: ".. R.height}
	end
end

local function mineBedrockArea(width, length, leaveExposed) -- 19
	--[[ 
	Assume on level 5 or -59
	for 1, width do
		for 1, length do
			go down until bedrock, digging/replacing all directions
			return to 5 / -59
			move forward 1 blocks
		end
		turn right/ forward 2 turn right
	end
	]]	
	function clearColumn()
		local level = 0
		--T:go("L1x1R2x1L1")
		local success = T:down(1)
		while success do
			level = level + 1
			if leaveExposed then
				T:go("R1x1R1x1R1x1R1x1", false, 0, true)
			else
				T:go("R1C1R1C1R1C1R1C1", false, 0, true)
			end
			success = T:down(1)
		end
		if leaveExposed then
			T:go("U"..level)
		else
			T:go("U"..level.."C2")
		end
	end
	local goRight = true
	for i = 1, width do
		for j = 1, length do
			clearColumn()
			T:forward(1)
		end
		if goRight then
			T:go("R1F1R1")
		else
			T:go("L1F1L1")
		end
		goRight = not goRight
	end
	return {}
end

local function oceanMonumentColumns(R)
	-- utility to find corners and build columns to surface
	local lib = {}
	
	function lib.buildColumn()
		local depth = 0
		while T:isWater("forward") do
			T:go("U1C2")
			depth = depth + 1
		end
		return depth
	end
	
	function lib.buildTower()
		T:go("F1C2 F1C2 F1C2")
		T:go("L1F1 L1C2 F1C2 F1C2 F1C2")
		T:go("R1F1 R1C2 F1C2 F1C2 F1C2")
		T:go("L1F1 L1C2 F1C2 F1C2 F1C2")
		
		T:go("R2")
		for i = 1, 4 do
			T:go("U1C2")
			for j = 1, 4 do
				T:go("F1C2 F1C2 F1C2 R1")
			end
		end
	end
	
	R.silent = true
	local blockType = T:getBlockType("down")
	if blockType:find("water") == nil then
		T:down(1) -- if on a platform will break through
	end
	R.data = "clearWaterPlants"
	result = clearWaterPlants(R)[1]
	if result ~= "" then
		return {result}
	else
		--on corner of monument, facing out to ocean
		local depth = lib.buildColumn()
		-- now above surface, block below at surface level
		for i = 1, 4 do
			T:turnRight(1)
			R.length = 57
			createPath(R) -- roughly at next corner
			if i < 4 then
				T:down(depth-2) -- roughly at correct depth
				local waterBelow = utils.clearVegetation("down")
				while waterBelow do
					T:down(1)
					waterBelow = utils.clearVegetation("down")
				end
				blockType = T:getBlockType("down")
				while blockType:find("prismarine") ~= nil do
					T:forward(1)
					blockType = T:getBlockType("down")
				end
				turtle.back()
				depth = lib.buildColumn()
			end
		end
		-- completed retaining paths. Build small tower for easy access
		lib.buildTower()
	end
	
	return {}
end

local function placeRedstoneTorch(direction, userChoice) -- 91, 92
	if direction == "level" then
		T:go("R1F1D2L2F1R1")
		--clsTurtle.place(self, blockType, damageNo, direction, leaveExisting)
		T:place(userChoice, -1, "forward", false)
		T:back(1)
		T:place("minecraft:redstone_torch", -1, "forward", true)
		T:go("R1F1L1F1U2L1F1R1")
	elseif direction == "up" then
		T:go("R1F1D3R2F1L1")
		T:place("minecraft:redstone_torch", -1, "up", false)
		T:go("R1B1U3F1R1")
		T:place(userChoice, -1, "forward", false)
	end
	return {}
end

local function plantTreefarm(R) -- 23
	--T:place(blockType, damageNo, direction, leaveExisting, signText)
	local lib = {}
	
	function lib.checkSaplings(saplings, firstChoice, secondChoice)
		local saplingSlot, sapling, count = T:getSaplingSlot(firstChoice)
		if count < 4  and secondChoice ~= "" then
			saplingSlot, sapling, count = T:getSaplingSlot(secondChoice)
		end
		if count == 0 then
			sapling = ""
		end
		
		return sapling, count
	end
	
	function lib.getSaplingInventory()
		local saplings = {}
		saplings.oak_sapling = 0
		saplings.spruce_sapling = 0
		saplings.birch_sapling = 0
		saplings.jungle_sapling = 0
		saplings.acacia_sapling = 0
		saplings.dark_oak_sapling = 0

		local firstChoice = ""
		local firstCount = 0
		local secondChoice  = ""
		local secondCount = 0
		for i = 1, 16 do
			if turtle.getItemCount(i) > 0 then
				local data = turtle.getItemDetail(i)
				if data.name:find("sapling") ~= nil then
					local name = data.name:sub(11) -- removes "minecraft:"
					saplings[name] = saplings[name] + data.count
				end
			end
		end
		
		for sapling, count in pairs(saplings) do
			if count > firstCount then
				firstCount = count
				firstChoice = sapling
			else
				if count > secondCount then
					secondCount = count
					secondChoice = sapling
				end
			end
		end
		return saplings, firstChoice, secondChoice -- table, "oak_sapling", "dark_oak_sapling"
	end
	
	function lib.createIsland(sapling, count, exit)
		-- place 4 dirt with saplings on all 4 unless jungle
		-- sapling count/type already checked
		T:forward(2) -- assume starting outside planting area
		for i = 1, 4 do
			T:go("R1F1")
			T:place("dirt", -1, "down", false)
		end
		T:up(1)
		if count >= 4 then
			for i = 1, 4 do
				T:go("R1F1")
				T:place(sapling, -1, "down", false)
			end
		else
			if sapling:find("dark") == nil and sapling ~= "" then
				T:place(sapling, -1, "down", false)
			end
		end
		if exit == "forward" then
			T:go("F1D1")
		elseif exit == "right" then
			T:go("R1F2D1")
		elseif exit == "left" then
			T:go("L1F1D1")
		elseif exit == "back" then
			T:go("R2F2D1")
		end
	end
	
	function lib.createSingle(sapling, exit)
		-- place single dirt with sapling on top
		-- sapling count/type already checked
		T:place("dirt", -1, "down", false)
		T:up(1)
		if not T:place(sapling, -1, "down", false) then -- try specific sapling
			T:place("sapling", -1, "down", false)		-- any available sapling
		end
		if exit == "forward" then
			T:go("F1D1")
		elseif exit == "right" then
			T:go("R1F1D1")
		elseif exit == "left" then
			T:go("L1F1D1")
		elseif exit == "back" then
			T:go("R2F1D1")
		end
	end

	local saplings, firstChoice, secondChoice = lib.getSaplingInventory()

	if firstChoice ~= "" then
		print("first sapling choice: "..firstChoice .. " ("..saplings[firstChoice]..")")
	end
	if secondChoice ~= "" then
		print("second sapling choice: "..secondChoice .. " ("..saplings[secondChoice]..")")
	end

	-- check type/size of farm
	if R.subChoice == 1 then -- 16 single trees
		local sapling, count = lib.checkSaplings(saplings, firstChoice, secondChoice)
		T:go("U1F4") -- outside first area
		for i = 1, 3 do	-- column 1/4
			lib.createSingle(sapling, "forward")
			T:forward(1)
		end
		for i = 1, 2 do
			lib.createSingle(sapling, "right") -- place 4th dirt/saling and exit to right
			T:forward(1)
		end
		for i = 1, 2 do -- column 2/4
			lib.createSingle(sapling, "forward")
			T:forward(1)
		end
		for i = 1, 2 do
			lib.createSingle(sapling, "left") -- place 4th dirt/saling and exit to right
			T:forward(1)
		end
		for i = 1, 2 do -- column 3/4
			lib.createSingle(sapling, "forward")
			T:forward(1)
		end
		for i = 1, 2 do
			lib.createSingle(sapling, "right") -- place 4th dirt/saling and exit to right
			T:forward(1)
		end
		for i = 1, 3 do -- column 4/4
			lib.createSingle(sapling, "forward")
			T:forward(1)
		end
		T:go("R1F6L1F2R2D1")	
	elseif R.subChoice == 2 then -- 4 double trees (4 saplings)
		-- assume placed 4 blocks from start
		local sapling, count = lib.checkSaplings(mostName, secondMostName)
		
		if count >= 4 then
			T:go("U1F3") -- outside first area
			lib.createIsland(sapling, count, "forward")
			sapling, count = lib.checkSaplings(mostName, secondMostName)
			T:go("F2")
			lib.createIsland(sapling, count, "right")
			sapling, count = lib.checkSaplings(mostName, secondMostName)
			T:go("F2")
			lib.createIsland(sapling, count,  "right")
			sapling, count = lib.checkSaplings(mostName, secondMostName)
			T:go("F2")
			lib.createIsland(sapling, count, "forward")
			T:go("R1D1F6L1F3R2") -- outside first area
		else
			return {"Insufficient saplings to plant"}
		end
	end
	return {}
end

local function quickMine(R) -- 18
	--[[
	mine valuable blocks from specified area
	if R.up set or lava/water found, ceiling is formed
	if R.down is set, or lava/water found layer is kept 1 block high
	R.subChoice
	1 At mine area start, on the floor
	2 At mine area start, on the ceiling
	3 On floor, start 1 block ahead
	4 On ceiling, start 1 block ahead
	5 On floor diagonally to left"
	]]
	local lib = {}
	
	function lib.refuel(direction)
		if T:place("minecraft:bucket", -1, direction) then
			T:refuel(1000, false)
		end
	end
	
	function lib.mine(R)
		-- starts on ceiling
		local isValuable, blockType
		for i = 1, R.length do
			local fillUp = R.up
			local fillDown = R.down
			isValuable, blockType = T:isValuable("down")
			if isValuable then
				T:dig("down")
			elseif blockType:find("water") ~= nil then
				fillDown = true
			elseif blockType:find("lava") ~= nil then
				lib.refuel("down")
				fillDown = true
			end
			isValuable, blockType = T:isValuable("up")
			if isValuable then
				T:dig("up")
			elseif blockType:find("water") ~= nil then
				fillUp = true
			elseif blockType:find("lava") ~= nil then
				lib.refuel("up")
				fillUp = true
			end
			if not turtle.detectUp() and fillUp then
				T:fillVoid("up")
			end
			if not turtle.detectDown() and fillDown then
				T:fillVoid("down")
			end
			if i < R.length then 
				T:forward(1)
			end
		end
	end
	
	local outbound = true
	
	if R.subChoice == 1 then
		T:up(1)
	elseif R.subChoice == 3 then
		T:go("U1F1")
	elseif R.subChoice == 4 then
		T:go("F1")
	elseif R.subChoice == 5 then
		T:go("U1R1 F1L1 F1")
	end
	
	for w = 1, R.width do
		lib.mine(R)
		if w < R.width then
			if outbound then
				T:go("R1F1R1")
			else
				T:go("L1F1L1")
			end
			outbound = not outbound
		end
		if T:getFirstEmptySlot() == 0 then
			T:dumpRefuse("forward", 1)
		end
	end
	if outbound then
		T:go("L1F"..R.width - 1 .."L1F"..R.length - 1)
	else
		T:go("R1F"..R.width - 1 .."R1")
	end
	
	return {}
end

local function quickMineCorridor(R) -- 17
	--[[
	R.subChoice
	1: At corridoor start, on the floor
	2: At corridoor start, on the ceiling
	3: On floor, start 1 block ahead
	4: On ceiling, start 1 block ahead
	]]
	if R.subChoice == 2 then
		T:down(1)
	elseif R.subChoice == 3 then
		T:forward(1)
	elseif R.subChoice == 4 then
		T:go("D1F1")
	end
	local width = R.width - 1
	local length = R.length - 1
	R.silent = true
	R.length = length
	createCorridor(R, true) -- put floor and ceiling for R.length, place torch at start
	T:turnRight(1)
	R.length = width
	createCorridor(R, true)
	T:turnRight(1)
	R.length = length
	createCorridor(R, true)
	T:turnRight(1)
	R.length = width
	createCorridor(R, true)
	T:turnRight(1)
	
	return {}
end

local function repairWall(startAt, height, width, replaceWith)
	-- go up to startAt
	
	-- if width = 1
	
		-- for h = startAt, height, 1 do
		
			-- replace block with replaceWith ("" = any)
			
			-- move up
			
		--end
		
		-- move back to beginning
		
	-- else
	
		-- remain = height % 2
		
		-- for w = 1, width - remain do
		
			-- for h = startAt, height, 1 do
			
				-- replace block with replaceWith ("" = any)
				
				-- move up
				
			--end
			
			-- move to the right 1 block
			
			-- for i = height, startAt, -1 do
			
				-- replace block with replaceWith ("" = any)
				
				-- move down
				
			--end
			
		-- end
		
	-- end
	
end

local function getTaskItemsList()
	-- list of items required for each task
	local text = {}
	--MINING
	text[11] = {"24 torch (optional)", "1 bucket (optional)", "64 stone", "1 chest"} 			-- mine at this level
	text[12] = {"ladder from this level up / down","levels/4 torch (optional)","levels*4 stone"}-- ladder to bedrock
	text[13] = {"stairs from this level up / down", "6*levels stone", "1 chest"} 				-- stairs up/down
	text[14] = {"levels * 4 stone","water_bucket"} 												-- safe drop to water block
	text[15] = {"levels * 4 stone", "1 soul sand", "1 water bucket"} 							-- single column bubble lift
	text[16] = {"1 UNUSED diamond sword (optional)"}											-- salvage mineshaft
	text[17] = {"1 bucket (optional)", "64 stone"} 												-- quick mine
	text[18] = {"1 bucket (optional)", "64 stone"}												-- quick corridor
	text[19] = {"1 bucket (optional)"}															-- mine to bedrock

	-- FORESTRY
	text[21] = {"1 chest (optional)"}-- Fell Tree
	text[22] = {"64 dirt", "16 torch (optional)"} --Create treefarm
	text[23] = {"min 4 saplings", "16 dirt"} --plant treefarm
	text[24] = {} -- Harvest treefarm
	text[25] = {"3 chest","128 dirt","128 stone","2 water buckets","1 hopper","21 torch","21 saplings (optional)"}	-- Create Auto-TreeFarm
	text[26] = {} -- Manage Auto-TreeFarm
	text[27] = {"1 chest", "saplings"} -- harvest and replant walled rectangle of natural forest
				
	-- FARMING			
	text[31] = {"64 stone","128 dirt (optional)", "4 water buckets","4 chests","1 sapling (oak preferred"}-- Create modular crop farm
	text[32] = {"64 stone","128 dirt (optional)", "4 water buckets","5 chests","1 sapling (oak preferred"}-- extend farm
	text[33] = {} -- Manual harvest and auto setup

	-- OBSIDIAN
	text[41] = {"stone to cover area of obsidian"}	-- Harvest obsidian
	text[42] = {"10 obsidian", "8 stone"} -- build Nether portal
	text[43] = {}-- demolish Nether portal
	text[44] = {"84 stone or cobbled_deepslate"}-- undermine dragon towers
	text[45] = {} -- deactivate dragon tower
	text[46] = {} -- attack chamber
	text[47] = {} -- attack dragon
	text[48] = {"64 stone","1 rail","1 powered rail","1 minecart","1 button","ladders"}-- build end portal minecart
	text[49] = {"256 stone, 145 ladders, 1 obsidian, 1 water bucket"} -- dragon water trap
				
	--CANALS BRIDGES WALKWAYS
	text[51] = {"dirt or stone (optional)","torch (optional)"} -- single path
	text[52] = {"dirt or stone (optional)","torch (optional)"} -- 2 block coridoor
	text[53] = {"2 x length dirt or stone (optional)" } -- Bridge over void/water/lava
	text[54] = {"2 x length dirt or stone" } -- Covered walkway
	text[55] = {"256 stone or dirt","2 water buckets","length/8 torches (optional)"} -- left side of new/existing canal
	text[56] = {"Packed ice or blue ice","slabs","trapdoors","stone","torches"} 		-- Ice canal
	text[57] = {"width * length stone"} 							-- platform
	text[58] = {"width + 1 * length + 1 stone"} 					-- sinking platform
	text[59] = {"2 TURTLES!","2 x soul sand, 2 water buckets"} 		-- Boat bubble lift
	text[510]= {"wooden trapdoors"}
	
	-- MOB FARM
	text[61] = {"256 stone","1 slab"} -- 9x9 cube round spawner
	text[62] = {"640 stone","1 slab (blaze 37)","blaze 8 powered rail","blaze 64 rail","blaze 2 redstone torch","blaze 1 hopper minecart","blaze 1 stone button"} -- 9x9 cube round spawner
	text[63] = {"2 water buckets","2 fence","2 signs","1 slab","1 soul sand (or dirt as placeholder)"} -- flood spawner chamber	
	text[64] = {"128 stone","2 water buckets","1 soul sand"} 	
	text[65] = {"128 stone"} 
	text[66] = {"1856 stone, diorite etc (inc polished)","1 chest","10 empty buckets","2 water buckets","192 fence","8 signs","3 ladder","2 soul sand"} -- build endermen observation tower
				
	-- AREA CARVING
	text[71] = {"64 dirt"} -- Clear field
	text[72] = {} -- Clear rectangle width, length
	text[73] = {} -- Clear wall height, length
	text[74] = {} -- Clear rectangle perimeter only width, length
	text[75] = {} -- Clear structure floor/walls/ceiling
	text[76] = {}
	text[77] = {} -- Dig a trench
	text[78] = {} -- carve mountain
	text[79] = {"Any material suitable for floor or ceiling"} -- floor or ceiling
				
	-- LAVA WATER
	text[81] = {} -- sand based utilities
	text[82] = {} -- vertical wall from surface
	text[83] = {} -- player driven path construction
	text[84] = {} -- water clearing by repeated block deletion
	text[85] = {} -- ocean monument utilities
	text[86] = {"ladder to height","stone, dirt netherrack 4 X height"} -- ladder to water/lava
	text[87] = {} -- clear water plants
	text[88] = {} -- convert flowing water to source
	text[89] = {"6 buckets","slabs to cover area"} -- create sloping water
				
	-- RAILWAY
	text[91] = {"1 block of choice","1 redstone torch"} -- place redstone torch under current block
	text[92] = {"1 block of choice","1 redstone torch"} -- place redstone torch on upward slope
	text[93] = {"height x block of choice","height/3 x redstone torch"} -- build downward slope
	text[94] = {"height x block of choice","height/3 x redstone torch"} -- build upward slope
	return text
end

local function getTaskHelp(menuLevel, menuItem)
	-- display help about selected task
	-- terminal size = 39 x 13
	info = {}
	info.main = {}
	info.sub = {}
	table.insert(info.main,
	[[
MINING:
Can be used in over-world or nether.   
Create a pre-formatted 33 x 33 blocks  
mine at chosen level.                 
Ladders and stairs up/down    
Bubble lift and safe drop to water.     
Strip resources from abandoned mines.  
Faster version of 33x33 mine pattern   
using corridor and rectangle functions.
Mine bottom layer to bedrock (not worth
the fuel and time)
	]])
	table.insert(info.main,
	[[
FORESTRY:
Fell Tree can be used in Nether as well
for cutting any size tree / branches
Create a simple 16 single tree farm
or 4 double size (Dark oak or any type)
suitable for turtle harvesting.
Automatic treefarm can be created and
managed with dedicated automatic turtle.
Natural forest can be harvested and
replanted. (Must be walled off)
	]])
	table.insert(info.main,
	[[
FARMING:
Farm modules can be built to fixed size
and placed next to each other in linear
or rectangular pattern.
Whole farm is managed by a dedicated
turtle, which must be equipped with a
diamond hoe as well as pickaxe.
Fuel obtained from an oak tree placed
in the corner of each module.
Double chests store produce and seeds

	]])
	table.insert(info.main,
	[[
OBSIDIAN:
The turtle can extract obsidian from
lava areas safely.
Nether portals can be built or removed
without needing diamond pickaxes.
End World dragon towers can be
undermined ready for deactivating.
End world towers can have the crystals
destroyed.
The dragon can be attacked from below.
Minecart end portal stations built.
	]])
	table.insert(info.main,
	[[
PATHS, BRIDGES, CANALS:
Can be used in Nether and End.
Build pathways over air, water or lava
Optional roofed pathway for Nether use.
Tunnel through rock and place a floor
at the same time.
Build a canal with towpath, must use
two turtles operating simultaneously
Platform for use over air, water, lava
Sinking version is removed and replaced
1 block lower each time
	]])
	table.insert(info.main,
	[[
MOB FARMS:
Tools to create mob farms round
existing spawners. Special version
for Blaze farms uses rail collection
Choice of bubble lift mob dropper
or simple deep trench.
Enderman observation tower can be
built >128 above ground: is expensive.
Theoretically re-spawns new mobs when
used.
Suggest build only the base.
	]])
	table.insert(info.main,
	[[
AREA CLEARING AND REFORMING:
Tools to clear a field inc. trees,
rectangles, single walls, solid and
hollow structures.
Dig a trench, carve away side of a
mountain.
Place or replace floors and ceilings




	]])
	table.insert(info.main,
	[[
WATER AND LAVA TOOLS:
Used to drain ocean monuments and
shipwrecks. Can also be used to make
underwater base. Water is cleared using
sand dropping and recycling from 1.12.+
Alternative method uses solid block
placing and recycling.
Water plants can be removed without
damaging structures.
Tools to manipulate water areas.
	]])
	table.insert(info.main,
	[[
RAILWAY TOOLS:
Used to build diagonal block risers
and fallers for placing 45 deg rail 
tracks.
Placing Redstone torches under powered
rails when above ground level (viaduct)





	]])
	table.insert(info.main,
	[[
MEASURING TOOLS:
Used to measure height, depth or length










	]])
	
	if bedrock == 0 then	--pre 1.18
		info.sub[11] = 
[[Press F3 to check level. Look for 'Y'
Place at level 5, 8, 11 (11 nether)
]]-- Create mine at this level
	else
		info.sub[11] = 
[[Press F3 to check level. Look for 'Y'
Place at level -59, -56, -53 (11 nether)
]]-- Create mine at this level
	end
	info.sub[12] = 
[[Place me on the ground.
The ladder will start at this level
and go up or down on the space in front
of me.
If it reaches bedrock, a lava-proof
chamber will be built
]]-- Ladder up/down
	info.sub[13] = 
[[Place me on the ground. If stairs are
going down, the turtle will drop to
chosen level, then build upwards.
Stairs go to chosen level in a 5x5 block
]] -- Stairs up/down
	info.sub[14] = 
[[Place me on the ground. I will go down
to chosen level enclosing all sides of a
column. A water source will be placed at
the bottom. I will return here.
]] -- safe drop
	info.sub[15] = 
[[Place me on the ground. I will build a
3 x 1 water source and a single column
bubble lift to the chosen height.
]] -- single col bubble lift
	info.sub[16] = 
[[Place me on the end wall of a disused
mine in the centre block, 1 block above
the floor. Provide a diamond sword for
harvesting string from spider webs
]] -- salvage mineshaft
	info.sub[17] = 
[[Place me at eye height
Upper left corner of a rectangle
(1 block above the floor)
]] -- quick coridoor system
	info.sub[18] = info.sub[17] -- quick mine
	if bedrock == 0 then
		info.sub[19] = 
[[Place me level 5 on the floor to mine
into bedrock (slow and inefficient)
]] -- mine all blocks to bedrock
	else
		info.sub[19] = 
[[Place me level -59 on the floor to mine
into bedrock (slow and inefficient)
]] -- mine all blocks to bedrock
	end
	info.sub[21] = 
[[Place me in front of the tree
you want to fell. Fuel not required as
logs will be used if needed
]] -- Fell Tree
	info.sub[22] = 
[[Place me on grass, lower left corner
of a 13x13 square.
Trees to be grown on alternate blocks
in a square of 4x4 trees, with
a 3 block wide perimeter.
]] -- Create treefarm
	info.sub[23] = 
[[Place me in front of first tree dirt
on the lower left corner. (max 4 blocks
away). 4x4 trees square.
Provide 2 types of saplings for a
mixed tree farm.
For double trees place me 4 blocks from
left side of dirt. -Farms may be marked
Sapling number divisible by 4, max 16
]] -- Plant treefarm
	info.sub[24] = 
[[Place me in front of first tree dirt
potential position. (Dirt is placed)
Use lower left (EXACTLY 4 blocks away)
For double trees place me 4 blocks from
left side of dirt. -Farms may be marked
Fuel not required as logs will be used.
]] -- Harvest treefarm
	info.sub[25] = 
[[For a new Auto-TreeFarm:
Place me on left side of a 19 wide
x 14 long area
]] -- Create Auto-TreeFarm
	info.sub[26] = 
[[Place me in front of sapling
(or tree) with the chest behind me
]] -- Manage Auto-TreeFarm
	info.sub[27] = 
[[Place me in bottom left corner
of walled/ fenced rectangle of forest
]] -- clear and replant natural forest
	info.sub[28] = "No instructions required"
	info.sub[29] = "No instructions required"
	info.sub[31] = 
[[Place me on the ground lower left
of an area 14 x 14. A crop farm
12 x 12 with cobble wall will be
built forward and to the right
]] -- Create modular crop farm
	info.sub[32] = 
[[Place me next to the tree on
a chest, either left side of farm
or facing front wall to add a farm
in that direction.
]] -- Extend farm
	info.sub[33] = 
[[Place me over the water on the
left corner. There should be
chests on 2 sides. When the crop
I am facing ripens, harvest will
begin.
]] -- Manual harvest and auto setup
	info.sub[34] = "No instructions required"
	info.sub[35] = "No instructions required"
	info.sub[36] = "No instructions required"
	info.sub[37] = "No instructions required"
	info.sub[38] = "No instructions required"
	info.sub[39] = "No instructions required"
	info.sub[41] = 
[[Place me on any block
on the left side facing the
obsidian field.
]] -- Harvest obsidian
	info.sub[42] = 
[[Place me on the ground on the
left side of the portal base.
]] -- build Nether portal
	info.sub[43] = info.sub[42] -- Demolish Nether portal
	info.sub[44] = 
[[Place me on the ground at 0,y,0
(centre of the dragon arena)
facing West. IMPORTANT!
Double-check position / direction
]] -- Find dragon tower centres
	info.sub[45] = 
[[Place me in the ceiling pit in
centre of the obsidian tower
facing the endstone block.
This maximises success without
being destroyed!
]] -- deactivate dragon tower
	info.sub[46] = 
[[Place me under the bedrock of
the non-active escape portal in
the end World.
I will build a shield round the 
pre-portal and wait at the top
with attack() active.
REMOVE ME BEFORE DRAGON DIES!!
(Portal ignition destroys me)
]] -- build dragon attack chamber
	info.sub[47] = 
[[If not already there, place me
1 block down on the bedrock spire
where the dragon visits.
REMOVE ME BEFORE DRAGON DIES!!
(Portal ignition destroys me)
]] -- attack Dragon
	info.sub[48] = 
[[Place me on the ground under an
end world portal. (Centre marked by
beacon every couple of minutes)
I will build a ladder to a platform,
and minecart entry device.
]] -- build end portal minecart
	info.sub[49] = 
[[Place me on the ground at 0,49,100
on the end world spawn point.
(facing the dragon arena)
I will build a ladder column 145
blocks high, and place a water
source above the dragon perch
]] -- build dragon water trap
	info.sub[51] = 
[[Place me on the ground in front
of water, lava or air.
Follow and supply blocks as needed
]] -- Single path
	info.sub[52] = 
[[Place me on the ground at start
of coridoor.
]] -- 2 block coridoor
	info.sub[53] = 
[[Place me on the ground.
The double path will start in front,
continue for your chosen length
and return
]] -- Bridge over void/water/lava
	info.sub[54] = 
[[Place me on the ground.
The covered walkway will start in front,
(on the ceiling), continue for your
chosen length and return.
]] -- Covered walkway
	info.sub[55] = 
[[I should be on either an existing canal
or ready to start a new one.
If crossing water I should be on top
of a solid block making up the canal wall.
]] -- new/existing canal
	info.sub[56] = 
[[Convert an existing water canal or make
a new ice canal. 4 separate turtles ideal.
Left side towpath with slabs or trapdoors.
Left side alternate ice/air (packed/blue).
Right side air/air/water (or air).
Right towpath as left. Torches can be
placed either side, usually on the left
]] -- ice canal
	info.sub[57] = 
[[Place me any level in air, water or lava.
The platform will start on the left and
build forward and to the right.
]] -- Platform
	info.sub[58] = 
[[Place me on bottom left corner of an
existing platform. Enter same width and
length as existing
]] -- Sinking platform
	info.sub[59] = 
[[Place me in an existing canal or at the
back of 2x2 water source. MUST be source
in front.
Lift extension: place me in air in front
of exit signs, facing back of existing,
water source below.

ESSENTIAL to have a second turtle running
this script simultaneously.
Turtles must be FACING each other enabling
simultaneous start.
]] -- boat bubble lift
	info.sub[510] = 
[[place me next to the wall, above the
canal towpath, at eye level.
I will place trapdoors below, so they
can be raised to create a wall for boats
to travel on the ice blocks.
]] -- ice canal trapdoors
	info.sub[61] = 
[[NOT for Blaze spawners!
Creates a 9x9 hollow cube round
existing spawner.
1. Place on outside wall of dungeon
(away from edge, top to bottom)
2. Place me in contact with spawner
above/below/facing spawner block.
For Blaze spawners use that option.
]] -- 9x9 cube round spawner
	info.sub[62] = 
[[Place me in contact with Blaze spawner
above or facing spawner block to create
a safe killzone out of site of Blazes.
]] -- 9x9 cube round spawner with minecart collection
	info.sub[63] = 
[[Place me on the floor facing the wall
where the water sources will start
				
If you do not have soul sand, add dirt
as a temporary place marker.
Make sure you have an escape route!
]] -- Flood spawner chamber
	info.sub[64] = 
[[Place me on the soul sand/dirt block
at the flooded base of the spawner,
facing any direction.
]] -- Build bubble tower kill zone
	info.sub[65] = 
[[Place me at start of trench facing
required direction.
]] -- Dig kill trench for mobs
	info.sub[66] = 
[[This is a 3 stage process:
1.New tower lower base: place me on
flat ground in open plain.

2.Upper base: place me in front of
the existing chest at tower base.

3.Main tower, only needed to respawn
mobs. Expensive, not recommended.
Place me in front of chest in ground.
]] -- Build endermen observation tower
	info.sub[67] = "No instructions required"
	info.sub[68] = "No instructions required"
	info.sub[69] = "No instructions required"
	info.sub[71] = 
[[Place me on grass, lower left corner
of the area to be levelled and cleared.
Provide dirt to plug voids in the floor
]] -- Clear field
	info.sub[72] = 
[[Place me inside the left corner of the
rectangle to be cleared at the level to
be worked on.
This corner is included in the site.
]] -- Clear rectangle width, length
	info.sub[73] = 
[[Place me on top of wall,
or in front of bottom corner
of the wall to be cleared.
]] -- Clear wall height, length
	info.sub[74] = 
[[[Bottom -> Up
Place me INSIDE bottom left corner 
in the floor (included in the site.)
Top -> Down
Place me ON TOP of ceiling left corner
(Will dig down 1 before starting)
]] -- Clear rectangle perimeter only width, length
	info.sub[75] = 
[[Bottom -> Up
Place me INSIDE bottom left corner 
in the floor (included in the site.)
Top -> Down
Place me ON TOP of ceiling left corner
(Will dig down 1 before starting)
]] -- Clear structure floor/walls/ceiling
	info.sub[76] = info.sub[75]
	info.sub[77] = 
[[Place me on the ground facing the
trench direction.
]] -- Dig a trench
	info.sub[78] = 
[[Place me on the ground facing the
mountain side.
]] -- Carve mountain
	info.sub[79] = 
[[Place me inside top or bottom left
corner of existing floor or ceiling.

Remote access for deep water or high
ceilings is possible.

Next instruction checks add or replace.
]] -- (Re)place floor or ceiling
	info.sub[81] = 
[[1=Place me on the surface of water/lava
Sand  will be dropped DOWN and Forwards
2=Place me on top left corner of roof
Sand  will be dropped into the hollow
3=Place me on the surface of sand.
Sand will be mined DOWN then forwards.
Can be used for deserts as well.
4=Place me on top left corner of sand
Sand cleared down, then left to right.
Can be used for deserts as well.
]] -- Sand based utilities
	info.sub[82] = 
[[Place me on the surface facing 
direction the wall will go.
(usually away from player)

Turtle rotates 180 and goes backwards
and down.

for rectangle construction place on
existing wall facing direction of
new wall.
]] -- build wall from water or lava surface downwards 	
	info.sub[83] = 
[[Place me on lower left corner of area
to be enclosed with a wall
]] -- Create enclosed area"	
	info.sub[84] = 
[[Place me on the left corner at the top
of water or lava. If solid detected below
I will move forward 1 block first.
]] -- Clear volume of water
	info.sub[85] = 
[[Ocean monument drain or remove.
1=Place me above monument NOT in front
and NOT facing front (open area)
2=




]] -- Ocean monument utilities
	info.sub[86] = 
[[Place me on the ground.
The ladder will start here and drop to
water or lava below
]] -- Ladder to water/lava	
	info.sub[87] = 
[[Place me on the left corner of the top
of retaining wall facing water
]] -- Clear water plants from enclosed area
	info.sub[88] = 
[[Place me on the left corner of the top
of retaining wall facing water
]] -- Convert all water to source
	info.sub[89] = 
[[Place me on the left corner of the top
of retaining wall facing water.
The source blocks are placed ahead to
selected length
]] -- Create sloping water
	info.sub[91] = 
[[Place me on suspended railway stone
Redstone torch will go below me
]] -- Place redstone torch under block
	info.sub[92] = 
[[Place me on railway stone going up
Redstone torch will go below me
]] -- place redstone torch on upward slope 	
	info.sub[93] = 
[[Place me on last stone.
Track will go down from this point
]] -- build downward slope
	info.sub[94] = 
[[Place me on last stone.
Track will go up from this point
]] -- build upward slope
	info.sub[95] = "No instructions required"
	info.sub[96] = "No instructions required"
	info.sub[97] = "No instructions required"
	info.sub[98] = "No instructions required"
	info.sub[99] = "No instructions required"
	info.sub[101] = 
[[Place me on floor.
Height can be measured using overhead
obstruction, until no blocks detected
ahead or until a specific block type
is found.
]] -- measure height
	info.sub[102] = 
[[Place me on the edge above pit.
Depth can be measured via obstruction,
until no blocks detected ahead or
until a specific block type is found
below eg water or lava.
]] -- measure height
	info.sub[103] = 
[[Place me at chosen position.
Length can be measured using first
obstruction, until no blocks detected
above / below or until a specific block
type is found.
]] -- measure length
	info.sub[104] = 
[[Place me at water edge.
Deepest water will be recorded
and water plants removed as well.
]] -- measure deepest section of water

	if menuLevel == 1 then -- general help
		print(info.main[menuItem])
		term.write("Enter to continue ")
		return read()
	else -- item specific help
		print(info.sub[menuItem])
		term.setCursorPos(1, 13)
		term.write("Enter=exit, Any key + Enter=more ")
		return read()
	end
end

local function getTaskOptions()
	local options = {}
	options.main =
	{
		"Mining (includes Nether)",
		"Forestry",
		"Farming",
		"Obsidian, Nether & End Portal",
		"Canal, bridge and walkway",
		"Mob farm tools",
		"Area shaping and clearing",
		"Lava and Water",
		"Railway",
		"Measuring tools"
	}
	table.insert(options,
	{
		"Create mine at this level",
		"Ladder up or down",
		"Stairs up or down",
		"Safe drop to water block",
		"Single column bubble lift",
		"Rob disused mineshaft",
		"QuickMine coridoor system",
		"QuickMine rectangle",
		"Mine bedrock level"
	})
	table.insert(options,
	{
		"Fell Tree",
		"Create tree farm",
		"Plant tree farm",
		"Harvest tree farm",
		"Create Auto-treeFarm",
		"Manage Auto-treeFarm",
		"Harvest and replant forest"
	})
	table.insert(options,
	{
		"Create modular crop farm",
		"Extend modular crop farm",
		"Manage modular crop farm",
		"Create squid farm"
	})	
	table.insert(options,					
	{
		"Dig obsidian field",
		"Build Nether Portal",
		"Demolish Nether Portal",
		"Undermine Dragon Towers",
		"Deactivate Dragon Tower",
		"Build Dragon attack area",
		"Attack Dragon",
		"Build portal minecart station",
		"Build dragon water trap"
	})
	table.insert(options,
	{
		"Continuous path",
		"2 block high tunnel",
		"2 block wide over air/water/lava",
		"Covered walkway",
		"Water canal",
		"Ice canal (4 options)",
		"Platform",
		"Sinking platform for oceans",
		"Boat bubble lift",
		"Ice canal trapdoor border"
	})
	table.insert(options,
	{
		"Cube around spawner (NOT blaze)",
		"Cube around Blaze spawner",
		"Flood mob farm floor",
		"Create mob bubble lift",
		"Dig mob drop trench",
		"Build Endermen observation tower"
	})
	table.insert(options,
	{
		"Clear field (inc trees)",
		"Clear a rectangle (+ u/d opt)",
		"Clear single wall up/down",
		"Clear rectangular wall section",
		"Clear hollow structure up/down",
		"Clear solid structure up/down",
		"Dig a trench",
		"Carve mountain side",
		"Place a floor or ceiling"
	})
	--[[
		81 "Sand based utilities",
			R.subChoice=1 "Drop sand or gravel wall",
			R.subChoice=2 "Decapitate and fill with sand",
			R.subChoice=3 "Clear sand wall",
			R.subChoice=4 "Clear sand filled building",
		82 "Vertical wall from surface",
		83 "Create enclosed area",
		84 "Clear volume of water",
		85 "Clear monument layer",
		86 "Ladder down to water/lava",
		87 "Clear water plants"
		88 "convert flowing water to source"
		89 "create sloping water"
	]]
	table.insert(options,
	{
		"Sand based utilities",
		"Vertical wall from surface",
		"Create enclosed area",
		"Clear volume of water",
		"Ocean monument utilities",
		"Ladder down to water/lava",
		"Clear water plants",
		"Convert all water to source",
		"Create sloping water"
	})
	table.insert(options,
	{
		"Place Redstone:torch level track",
		"Place Redstone:torch upward track",
		"Build downward track",
		"Build upward track"
	})
	table.insert(options,
	{
		"Measure height",
		"Measure depth",
		"Measure length",
		"Measure greatest depth"
	})
	
	return options
end

local function getTask(R, itemsRequired)	
	--[[ 
		called from main()
		R = getTask(R, itemsRequired)
	]]
	local lib = {}
	
	function lib.getHelp(R, itemsRequired)
		listOfItems = itemsRequired[R.choice]
		local result = getTaskHelp(2, R.choice)
		if result ~= "" then
			T:clear()
			if next(listOfItems) ~= nil then
				print("Items required:")
				for k,v in pairs(listOfItems) do
					print("  "..v)
				end
			else
				print("No items required")
			end
			term.write("Enter to continue")
			read()
		end
		T:clear()
		local options ={"Continue with current task","Return to main menu","Quit application"}
		local choice = menu.new("Choose your option", options)
		if choice == 2 then
			R.choice = 0
		elseif choice == 3 then
			R.choice = -1
		end
		
		return R -- if R.choice reset to 0, then re-starts, -1 == quit
	end
	
	local modifier = ""
	local subChoice = 0
	local prompt = "Choose a task (add h for help eg 3h):"
	local options = getTaskOptions()
	
	while R.choice == 0 do
		-- menu returns choice=nil if user enters just q or h
		-- menu returns choice=2, modifier = "h" if 2h entered
		local mainChoice, modifier = menu.new(prompt, options.main) -- open main menu options
		if modifier == "q" then
			R.choice = -1
			return R -- quit application
		elseif modifier == "h" then -- get help on main menu items
			getTaskHelp(1, mainChoice)
			return R -- quit task system so it re-starts as help menu chosen R.choice = 0
		else
			subChoice, modifier = menu.new(prompt, options[mainChoice]) -- open submenu options
		end
		if subChoice ~= nil then
			if subChoice > 9 then -- need more than 9 sub-options
				R.choice = subChoice + (mainChoice * 100) -- 10 = 10 + 1000 = 1100
			else -- eg main option 1 (mining), sub-option 1 (create mine) = 1 + 10 = 11
				R.choice = subChoice + (mainChoice * 10) -- 9 = 9 + 9 * 10 = 99, 1 + 10*10 = 101
			end
		end
		-- eg chosen option 1 mining or option 10 measuring
		if modifier == "q" then
			R.choice = 0	-- return to root menu. change this to -1 if quit application preferred
			return R -- quit task system so it re-starts first menu
		elseif modifier == "h" then -- get help on main menu items
			R = lib.getHelp(R, itemsRequired) -- if R.choice reset to 0 then will continue
		end
	end
	T:clear()
	-- choice will be an integer, modifier will be empty string or "h"
		
	-- MINING (options 11-13 need no action)
	if R.choice == 14 then	-- safe drop to water
		local currentLevel = utils.getSize(true,"Current level (F3->Y coord)?_", bedrock + 5, ceiling)
		local destLevel = utils.getSize(true, "Go down to level? ("..currentLevel - 2 .." to "..bedrock + 5 ..")", bedrock + 5 , currentLevel - 2)
		R.height 	= math.abs(destLevel - currentLevel)
	elseif R.choice == 15 then	-- bubble lift
		local currentLevel = utils.getSize(true,"Current level (F3->Y coord)?_", bedrock + 5, ceiling)
		local destLevel = utils.getSize(true, "Go up to level? ("..currentLevel + 2 .." to "..ceiling ..")", currentLevel + 2, ceiling)
		R.height 	= math.abs(destLevel - currentLevel)
	elseif R.choice == 17 then -- create mining coridoor system default: square 17 x 17 
		R.width 	= utils.getSize(false, "Width (2-64 default 17)\n", 2, 64, 17)
		R.length  	= utils.getSize(false, "Length (2-64 default 17)\n", 2, 64, 17)
		local choices = {"At corridoor start, on the floor",
						 "At corridoor start, on the ceiling",
						 "On floor, start 1 block ahead",
						 "On ceiling, start 1 block ahead"}
		local userChoice, modifier = menu.new("Starting position?", choices) -- 1 to 4
		if modifier == "q" then -- quit chosen
			return "", R
		end
		R.torchInterval = 9 -- 8 spaces between torches
		if mcMajorVersion >= 1.18 then
			R.torchInterval = 17 -- 16 spaces between torches
		end
		R.subChoice = userChoice
	elseif R.choice == 18 then -- clear a rectangle, fill empty spaces above
		R.width 	= utils.getSize(false, "Width (2-64 default 15)\n", 2, 64, 15)
		R.length  	= utils.getSize(false, "Length (2-64 default 15)\n", 2, 64, 15)
		local choices = {"At mine area start, on the floor",
						 "At mine area start, on the ceiling",
						 "On floor, start 1 block ahead",
						 "On ceiling, start 1 block ahead",
						 "On floor diagonally to left"} -- just finished corridoor
		local userChoice, modifier = menu.new("Starting position?", choices) -- 1 to 4
		if modifier == "q" then -- quit chosen
			return "", R
		end
		R.subChoice = userChoice
	elseif R.choice == 19 then -- Mine bedrock area
		R.width 	= utils.getSize(false, "Width (2-64 default 15)\n", 2, 64, 15)
		R.length 	= utils.getSize(false, "Length (2-64 default 15)\n", 2, 64, 15)
		R.height 	= menu.getBoolean("Leave bedrock exposed? (y / n)")
		
	-- FORESTRY
	elseif R.choice == 22 then --Create treefarm
		local choices = {"4 x 4 trees(16)","8 x 8 trees(64)"}
		R.subChoice = menu.new(prompt, choices)
	elseif R.choice == 23 then -- plant treefarm
		choices 	= {"16 single trees", "4 double trees any type"}
		R.subChoice 		= menu.new(prompt, choices)
	elseif R.choice == 24 then -- Harvest treefarm
		-- no instructions
	elseif R.choice == 27 then -- Harvest and replant natural forest
		-- no instructions
		
	-- FARMING
	elseif R.choice == 31 then -- new crop farm
		-- no instructions
	elseif R.choice == 32 then -- extend crop farm
		choices 	= {"Add a farm at the back", "Add a farm to the right"}
		R.subChoice = menu.new(prompt, choices)
		
	elseif R.choice == 33 then -- manage crop farm
		-- no instructions
	elseif R.choice == 34 then -- create squid farm
		-- no instructions
	-- OBSIDIAN
	elseif R.choice == 41 then	-- Harvest obsidian
		R.width 	= utils.getSize(false, "Width of the area (1-64)\n", 1, 64)
		R.length  	= utils.getSize(false, "Length of the area (1-64)\n", 1, 64)
	elseif R.choice == 42 then -- build Nether portal
		R.width 	= utils.getSize(false, "Width of the portal\n", 1, 64, 4)
		R.height 	= utils.getSize(false, "Height of the portal\n", 1, 64, 5)
	elseif R.choice == 43 then -- demolish Nether portal
		R.width 	= utils.getSize(false, "Width of the portal\n", 1, 64, 4)
		R.height 	= utils.getSize(false, "Height of the portal\n", 1, 64, 5)
	elseif R.choice == 44 then -- undermine dragon towers
		-- no instructions
	elseif R.choice == 45 then -- deactivate dragon tower
		-- no instructions
	elseif R.choice == 46 then -- build dragon attack area
		-- no instructions
	elseif R.choice == 47 then -- attack dragon
		-- no instructions
	elseif R.choice == 48 then -- build end portal minecart station
		-- no instructions
	elseif R.choice == 49 then -- build dragon water trap
		-- no instructions
		
	-- CANAL BRIDGE
	elseif R.choice == 51 then	--single path
		R.length 	= utils.getSize(false, "Path length? 0 = continuous\n", 0, 1024, 64)
	elseif R.choice == 52 then	--2 block coridoor
		R.length 	= utils.getSize(false, "Corridor length? 0 = continuous\n", 0, 1024, 64)
	elseif R.choice == 53 then	--return Path over void/water/lava
		R.length 	= utils.getSize(false, "Length of the area (1-256)\n", 1, 256, 64)
	elseif R.choice == 54 then	--Covered walkway
		R.length 	= utils.getSize(false, "Length of the walk (1-256)\n", 1, 256, 64)
	elseif R.choice == 55 then	--left/right side of new/existing canal
		R.subChoice = utils.getSize(false, "Am I on the left(0) or right(1)?\n", 0, 1)
		R.length 	= utils.getSize(false, "Canal length? 0 = continuous\n", 0, 2048, 64)
		R.height 	= utils.getSize(false, "Am I on the floor(0) or wall(1)?\n", 0, 1)
	elseif R.choice == 56 then	--ice canal 4 sections: edge+torch, edge, centre+ice, centre no ice
		local choices = {"Towpath with torches (left)",
						 "Canal ice blocks (centre-left)",
						 "Canal air/water (centre-right)",
						 "Towpath without torches (right)"}
		local userChoice, modifier = menu.new("Which part of the canal?", choices) -- 1 to 5
		
		if modifier == "q" then -- quit chosen
			return "", R
		end
		if userChoice == 1 then
			R.torchInterval = 9 -- 8 spaces between torches
		end
		R.subChoice = userChoice
		R.length 	= utils.getSize(false, "Canal length? 0 = continuous\n", 0, 2048, 64)
	elseif R.choice == 57 then	--platform
		R.width 	= utils.getSize(false, "Platform width?\n", 1, 1024)
		R.length 	= utils.getSize(false, "Platform length?\n", 1, 1024 / R.width)
	elseif R.choice == 58 then	--sinking platform
		R.width 	= utils.getSize(false, "Width (excluding retaining wall)?\n", 1, 1024)
		R.length 	= utils.getSize(false, "Length (excluding retaining wall)?\n", 1, 1024 / R.width)
		R.height 	= utils.getSize(false, "Levels to go down?\n", 1, 1024 / R.width * R.length)
	elseif R.choice == 59 then	--boat bubble lift
		local choices = {"New lift on left side",
						 "New lift on right side",
						 "Extend lift on left side",
						 "Extend lift on right side"}
		local userChoice, modifier = menu.new("Select correct option", choices) -- 1 to 4
		if modifier == "q" then -- quit chosen
			return "", R
		end				 
		R.subChoice = userChoice
		R.height 	= utils.getSize(false, "Levels to go up?\n", 4, ceiling - 2)
	elseif R.choice == 510 then	--ice canal trapdoors
		R.subChoice = utils.getSize(false, "Am I on the left(0) or right(1)?\n", 0, 1)
		R.length 	= utils.getSize(false, "Canal length? 0 = continuous\n", 0, 2048, 64)
	-- MOB SPAWNER TOOLS
	elseif R.choice == 61 then -- create cube round mob spawner
		T:clear()
		print("Turtle placement options:\n\n"..
			  "1. On top or in front of the spawner\n"..
			  "   if cave spider OR no chests around\n"..
			  "2. Outside the dungeon at floor or\n"..
			  "   ceiling level facing the corner\n\n"..
			  "Make sure you have access to the block\n"..
			  "facing the spawner, as any chests\n"..
			  "found inside will be placed outside\n"..
			  "the new dungeon wall at this height.\n\n"..
			  "Enter to continue")
		read()
		local choices = {"Turtle on spawner (no chests)",
						 "Outside wall: left side, floor",
						 "Outside wall: left side, ceiling",
						 "Outside wall: right side, floor",
						 "Outside wall: right side, ceiling"}
		local userChoice, modifier = menu.new("Select turtle position", choices) -- 1 to 5
		
		if modifier == "q" then -- quit chosen
			return "", R
		end
		R.subChoice 	= userChoice
		if R.subChoice > 1 then -- get dungeon wall dimensions
			R.width 	= utils.getSize(true, "Dungeon external width\n", 0, 11, 11)
			R.length 	= utils.getSize(true, "Dungeon external length\n", 0, 11, 11)
		end
	elseif R.choice == 62 then -- Blaze spawner
		T:clear()
		print("Turtle placement options:\n\n"..
			  "1. On top of the spawner\n"..
			  "2. At the same level, directly\n"..
			  "in front or in a line in range\n"..
			  "of the spawner.\n"..
			  "eg behind a safety wall. (no hole\n"..
			  "required)\n\n"..
			  "Enter to continue")
		read()
	elseif R.choice == 64 then -- create bubble lift at mob spawner
		local choices = {"Dropzone on left", "Dropzone on right"}
		local userChoice = menu.new("Which side do you want the mobs?", choices)
		R.subChoice = userChoice -- 1 left, 2 right
	elseif R.choice == 65 then -- Mob trench
		R.length 	= utils.getSize(false, "Length of trench (1-256)\n", 1, 256)
		R.height 	= utils.getSize(false, "Depth of trench (1-50)\n", 1, 50)
	
	-- AREA CARVING
	elseif R.choice == 71 then --Clear field
		R.width 	= utils.getSize(false, "Width of the area (1-64)\n", 1, 64)
		R.length  	= utils.getSize(false, "Length of the area (1-64)\n", 1, 64)
	elseif R.choice == 72 then -- Clear solid rectangle R.width, R.length
		R.width 	= utils.getSize(false, "Rectangle width (1-256)\n", 1, 256)
		R.length  	= utils.getSize(false, "Rectangle length (1-256)\n", 1, 256)
		R.up 		= menu.getBoolean("Remove blocks above?")
		R.down 		= menu.getBoolean("Remove blocks below?")
	elseif R.choice == 73 then -- Clear wall R.height, R.length, direction
		local direction = menu.new("Which direction?", {"Bottom -> Top", "Top -> Bottom"}) -- open direction menu options
		if direction == 1 then
			R.data = "up"
		else
			R.data = "down"
		end
		R.width 	= 1
		R.length 	= utils.getSize(false, "Length of wall (1-256)\n", 1, 256)
		R.height 	= utils.getSize(false, "Height of wall (1-50)\n", 1, 50)
	elseif R.choice == 74 then -- Clear rectangle perimeter only R.width, R.length
		R.width 	= utils.getSize(false, "Walled area width (1-256)\n", 1, 256)
		R.length  	= utils.getSize(false, "Walled area length (1-256)\n", 1, 256)
		R.height 	= 1
	elseif R.choice == 75 then -- Clear hollow object floor/walls/ceiling
		local direction = menu.new("Which direction?", {"Bottom -> Top", "Top -> Bottom"}) -- open direction menu options
		if direction == 1 then
			R.data = "up"
		else
			R.data = "down"
		end
		R.width 	= utils.getSize(false, "Hollow object width (1-256)", 1, 256)
		R.length  	= utils.getSize(false, "Hollow object length (1-256)", 1, 256)
		R.height  	= utils.getSize(false, "Depth/Height (1-256)", 1, 256)
	elseif R.choice == 76 then -- clear solid object
		local direction = menu.new("Which direction?", {"Bottom -> Top", "Top -> Bottom"}) -- open direction menu options
		if direction == 1 then
			R.data = "up"
		else
			R.data = "down"
		end
		R.width 	= utils.getSize(false, "Solid object width (1-256)", 1, 256)
		R.length  	= utils.getSize(false, "Solid object length (1-256)", 1, 256)
		R.height  	= utils.getSize(false, "Depth/Height (1-256)", 1, 256)
	elseif R.choice == 77 then	-- Dig a trench
		R.height 	= utils.getSize(false, "Depth of the trench (1-64)", 1, 64)
		R.length 	= utils.getSize(false, "Trench length? 0 = continuous\n", 0, 1024)
	elseif R.choice == 78 then	-- Carve side of mountain
		R.subChoice = utils.getSize(false, "Left <- Right (0), Left -> Right(1)",0, 1)
		R.width 	= utils.getSize(false, "Width of area to remove?", 1, 1024)
		R.length 	= utils.getSize(false, "Length of area to remove?", 0, 1024)
	elseif R.choice == 79 then	-- Place a floor or ceiling
		local items = {	"Replacing current floor",
						"New floor over existing",
						"Replacing current ceiling",
						"New ceiling under existing"}
		R.subChoice = menu.new("Laying what?", items)
		R.height = utils.getSize(false, {"Enter 0 for on-site placement",
										 "If in deep water or above reach",
										 "Enter approx depth/height"}, 0, 64)
		if R.subChoice < 3 then
			R.down = true
			R.width 	= utils.getSize(false, "Width of floor (1-64)\n", 1, 64)
			R.length  	= utils.getSize(false, "Length of floor (1-64)\n", 1, 64)
		else
			R.up = true
			R.width 	= utils.getSize(false, "Width of ceiling (1-64)\n", 1, 64)
			R.length  	= utils.getSize(false, "Length of ceiling (1-64)\n", 1, 64)
		end
	-- WATER LAVA
	--[[
		81 "Sand based utilities",
			R.subChoice=1 "Drop sand or gravel wall",
			R.subChoice=2 "Decapitate and fill with sand",
			R.subChoice=3 "Clear sand wall",
			R.subChoice=4 "Clear sand filled building",
		82 "Vertical wall from surface",
		83 "Create enclosed area",
		84 "Clear volume of water",
		85 "Clear monument layer",
		86 "Ladder down to water/lava",
		87 "Clear water plants"
		88 "convert flowing water to source"
		89 "create sloping water"
	]]
	elseif R.choice == 81 then -- Sand based utilities
		local items	= 
		{
			"Drop sand or gravel wall",
			"Decapitate and fill with sand",
			"Clear sand wall",
			"Clear sand filled building"	
		}
		R.subChoice = menu.new("Which utility?", items)
		if R.subChoice == 1 then -- drop sand into water or lava surface until solid ground reached
			R.width	  = 1
			R.length  = utils.getSize(false, "Length of sand dam (0=to block)\n", 0, 60)
		elseif R.subChoice == 2 then	-- clear rectangle on top of building and fill with sand
			R.width   = utils.getSize(false, "Width of roof (<=30)\n", 1, 30)
			R.length  = utils.getSize(false, "Length of of roof (<=30)\n", 1, 30)
		elseif R.subChoice == 3 then	-- clear sand wall or harvest sand
			R.width   = 1
			R.length  = utils.getSize(false, "Length of sand (0=auto-detect)", 0, 60)
			choices = {"Stay at end of wall", "Return home"}
			userChoice = menu.new("Choose your preference", choices)
			if userChoice == 2 then
				R.data = "return"
			end
		elseif R.subChoice == 4 then	-- remove sand from cube. start at top
			R.width   = utils.getSize(false, "Width of sand (<=30)\n", 1, 30)
			R.length  = utils.getSize(false, "Length of of sand (<=30)\n", 1, 30)
			R.height  = 0
			R.data = "down" -- always starts at the top
		end
	elseif R.choice == 82 then -- build wall from water or lava surface downwards
		R.width 	= 1
		R.length 	= utils.getSize(false, "Length of the wall (1-60)\n", 1, 60)
		R.height 	= utils.getSize(false, "Fixed depth or 0 = to floor", 0, 60)
	elseif R.choice == 83 then -- create a rectangle path in water/lava
		local choices = {"Simple path", "Covered 2 block high path"}
		local userChoice = menu.new("Choose your path option", choices)
		R.subChoice	= userChoice -- 1 open, 2 covered
		choices = {"Menu driven", "Command driven"}
		userChoice = menu.new("Choose your preference", choices)
		if userChoice == 1 then
			R.data = "menu"
		else
			R.data = "cmd"
		end
	elseif R.choice == 84 then -- Clear area of water bounded by blocks
		R.width 	= utils.getSize(false, "Width of water (0=autodetect)\n", 0, 64)
		if R.width > 0 then
			R.length = utils.getSize(false, "Length of water", 1, 64)
		end
		R.height 	= utils.getSize(false, "Depth of water (0=autodetect)", 0, 64)
	elseif R.choice == 85 then -- ocean monument utilities
		local items	= 
		{
			"Build 4 corner marker columns",
			"Retaining wall beween 2 columns",
			"Clear plants pre sand draining",
			"Use sand draining",
			"Drain and remove structure"	
		}
		R.subChoice = menu.new("Which utility?", items)
		if R.subChoice == 1 then -- Build 4 corner marker columns
			T:clear()
			print([[Place me above the monument water
level facing either side or back.
Do NOT place over the open front
section, or facing that direction.
Ideal place is near the top centre
which is also closest to the surface.

Also any corner less than 12 blocks
from the edge

Press Enter to continue
]])
			read()
			R.useBlockType = "prismarine"
			R.data = "oceanMonumentColumns"
		elseif R.subChoice == 2 then -- Retaining wall beween 2 columns
			T:clear()
			print([[Place me on the top of the wall
one block away from any corner,
facing the length of the wall.

NOT on the corner block!

Fill the inventory with stone.
I will wait on the surface if more
stone is required

Press Enter to continue
]])
			read()
			R.length = 56
			T:clear()
			if not menu.getBoolean("Is wall length = 56?") then
				R.length = utils.getSize(false, "Wall length excluding corners", 1, 64)
			end
		elseif R.subChoice == 3 then -- Clear plants pre sand draining
			T:clear()
			print([[Place me on the top of the wall
on SIDE of monument only, facing water
NOT at front (arches) or closed back
otherwise turtle will get stuck.

Can be done in 1 operation or split
along the length as required
Default size is 56 x 56 blocks

Press Enter to continue
]])
			read()
			T:clear()
			R.useBlockType = "prismarine"
			R.data = "clearWaterPlants"
			R.silent = true
			R.width 	= utils.getSize(false, "water width (0=auto detect)", 0, 64)
			R.length  	= utils.getSize(false, "water length (0=auto detect)", 0, 64)
		elseif R.subChoice == 4 then -- Drain using sand utilities
		
		elseif R.subChoice == 5 then -- Drain and remove structure
		
		end
	elseif R.choice == 86 then -- Ladder to water/lava	
		R.height 	= utils.getSize(false, "est. height above (?F3)\n", 1, 256)
	elseif R.choice == 87 then -- Clear water plants from enclosed area
		R.width 	= utils.getSize(false, "water width (0=auto detect)", 0, 64)
		R.length  	= utils.getSize(false, "water length (0=auto detect)", 0, 64)
	elseif R.choice == 88 then -- convert flowing water to source
		R.width 	= utils.getSize(false, "water width  (0=auto detect)", 0, 64)
		if R.width > 0 then
			R.length = utils.getSize(false, "water length (0=auto detect)", 0, 64)
		end
		R.height 	= utils.getSize(false, "water depth (0=auto detect)", 0, 64)
	elseif R.choice == 89 then -- create sloping water
		R.width 	= utils.getSize(false, "water slope width (usually 7/8)", 1, 8)
		R.length 	= utils.getSize(false, "water slope length ", 1, 64)
	-- RAILWAY
	elseif R.choice == 93 then -- build downward slope
		R.height  	= utils.getSize(false, "How many blocks down (0=auto)?\n", 0, 256)
	elseif R.choice == 94 then -- build upward slope
		R.height  	= utils.getSize(false, "Go up by how many blocks?\n", 1, 256)
	
	-- MEASURING TOOLS
	elseif R.choice == 101 then -- measure height
		R.subChoice	= menu.new("Measure using?", {"Obstruction above", "No further blocks ahead"}) -- open direction menu options
		-- 1 = obstruction, 2 = wall height
	elseif R.choice == 102 then -- measure depth
		R.subChoice	= menu.new("Measure using?", {"Obstruction below", "No further blocks ahead", "water or lava below"}) -- open direction menu options
		-- 1 = obstruction, 2 = wall height, 3 = water/lava
	elseif R.choice == 103 then -- measure length
		R.subChoice	= menu.new("Measure using?", {"Obstruction ahead", "No further blocks above", "No further blocks below"}) -- open direction menu options
		-- 1 = obstruction, 2 = ceiling length, 3 = floor length
	elseif R.choice == 104 then -- measure greatest depth of water body
		R.subChoice	= menu.new("Measure using?", {"Player entered", "No further water below"}) -- open direction menu options
		-- 1 = player entry, 2 = water length
		if R.subChoice == 1 then
			R.length = utils.getSize(false, "water length (0=auto detect)", 0, 256)
		end
	end
	
	return R
end

local function getTaskInventoryTo30(R)
	local retValue = {}
	local thanks = "Thank you.\n\nPress the ESC key\n\nStand Back..\n"
	
	if R.choice == 0 then --Missing pickaxe
		T:checkInventoryForItem({"minecraft:diamond_pickaxe"}, {1})
		print("Diamond Pickaxe being tested...")
		T:setEquipment()
	elseif R.choice == 1 then --Missing crafting table
		T:checkInventoryForItem({"minecraft:crafting_table"}, {1}) -- 0 if not present
		print("Crafting table being tested...")
		T:setEquipment()
	elseif R.choice == 2 then --Missing chest
		T:checkInventoryForItem({"minecraft:chest"}, {1}) -- 0 if not present
		sleep(1.5)
		
	-- MINING
	elseif R.choice == 11 then --Create Mine at this level
		utils.checkFuelNeeded(960)
		T:checkInventoryForItem({"minecraft:torch"}, {24}, false)
		T:checkInventoryForItem({"minecraft:bucket"}, {1}, false)
		T:checkInventoryForItem({"stone"}, {64})
		T:checkInventoryForItem({"minecraft:chest"}, {1})
		sleep(2)
		print("CreateMine starting")
		retValue = createMine()
	elseif R.choice == 12 or R.choice == 13 then	-- ladder down / up / stairs down / stairs up
		local currentLevel = utils.getSize(true,"Current level (F3->Y coord)?_", bedrock + 5, ceiling)
		local destLevel = bedrock							-- default destination
		local destName = "bedrock"							-- default name
		local description = "Creating ladder going down"	-- default action description
		R.subChoice = utils.getSize(true,"Going down(0) or up(1)?", 0, 1)
		if R.subChoice == 0 then-- going down
			destLevel = utils.getSize(true, "Go down to level? ("..currentLevel - 2 .." to "..bedrock + 5 ..")", bedrock + 5 , currentLevel - 2)
			if R.choice == 13 then
				description = "Creating stairs going down"
			end
		else -- going up
			destLevel = utils.getSize(true, "Go up to level? ("..currentLevel + 2 .." to "..ceiling ..")", currentLevel + 2, ceiling)
			destName = "surface"
			if R.choice == 12 then
				description = "Creating ladder going up"
			else
				description = "Creating stairs going up"
			end
		end
		local inAir = menu.getBoolean("Are you in air or nether? (y/n)")
		--[[
		range examples
		-50 to -59 = -59 -(-50) = -9   down
		-59 to -50 = -50 -(-59) = 9    up
		 70 to -48 = -48 -   70 = -118 down
		  5 to  64 =  64 -   5  = 59   up
		]]
		local range = math.abs(destLevel - currentLevel)
		T:checkInventoryForItem({"minecraft:bucket"}, {1}, false)
		if R.choice == 12 then -- ladders
			utils.checkFuelNeeded(range * 2)
			T:checkInventoryForItem({"minecraft:ladder"}, {range})
			T:checkInventoryForItem({"minecraft:torch"}, {math.floor(range / 4)}, false)
			if inAir then
				range = range * 3 -- more blocks needed
			end
			T:checkInventoryForItem({"stone"}, {range})
		else -- stairs
			utils.checkFuelNeeded(range * 10) -- stairs: each layer needs 10 moves
			local numStairsNeeded = range
			local data = T:getStock("stairs")
			local numStairs = data.total
			local cobbleNeeded = math.min(range * 6, 256)
			if inAir then
				cobbleNeeded = range * 6 -- 5 blocks / layer unless in water or lava
			end
			if numStairs < numStairsNeeded then
				cobbleNeeded = cobbleNeeded + (math.floor((2 * (numStairsNeeded - numStairs)) / 3))
			end
			T:checkInventoryForItem({"stairs"}, {numStairsNeeded}, false)
			T:checkInventoryForItem({"minecraft:cobblestone","minecraft:cobbled_deepslate"}, {cobbleNeeded, cobbleNeeded})
			T:checkInventoryForItem({"minecraft:chest"}, {1}) 	-- needed for crafting
		end
		print(thanks)
		print(description)
		os.sleep(2)    -- pause for 2 secs to allow time to press esc
		if R.choice == 12 then
			retValue = createLadder(destName, currentLevel, destLevel) -- "bedrock", 70, -48
		else
			retValue = createStaircase(destName, currentLevel, destLevel)
		end
	elseif R.choice == 14 then	-- safe drop to water
		utils.checkFuelNeeded(R.height * 2)
		T:checkInventoryForItem({"minecraft:water_bucket"}, {1})
		T:checkInventoryForItem({"stone"}, {R.height * 2}, false) -- estimate only partial cloaking needed
		print(thanks)
		print("Creating safe drop ".. R.height.. " blocks deep")
		print("Wait for my return!")
		os.sleep(2)    -- pause for 2 secs to allow time to press esc
		retValue = createSafeDrop(R)
	elseif R.choice == 15 then	-- single column bubble lift
		utils.checkFuelNeeded(R.height * 6)
		T:checkInventoryForItem({"minecraft:water_bucket"}, {2})
		T:checkInventoryForItem({"minecraft:bucket"}, {14}, false, "More buckets for speed!")
		T:checkInventoryForItem({"minecraft:soul_sand"}, {1})
		T:checkInventoryForItem({"sign"}, {2})
		T:checkInventoryForItem({"stone"}, {R.height * 2}, false) -- estimate only partial cloaking needed
		print(thanks)
		print("Creating bubble lift ".. R.height.. " blocks high")
		print("Wait for my return!")
		os.sleep(2)    -- pause for 2 secs to allow time to press esc
		retValue = createBubbleLift(R)
	elseif R.choice == 16 then	-- salvage mineshaft
		equippedRight, equippedLeft, inInventory = T:setEquipment() -- check for crafting table, sword, pickaxe, Put sword in spare slot
		if equippedLeft ~= "minecraft:diamond_pickaxe" and equippedRight ~= "minecraft:diamond_pickaxe" then
			T:checkInventoryForItem({"minecraft:diamond_pickaxe"}, {1}, true)
			equippedRight, equippedLeft, inInventory = T:setEquipment() -- check for crafting table, sword, pickaxe, Put sword in spare slot
		end
		if inInventory ~= "minecraft:diamond_sword" then
			returned = T:checkInventoryForItem({"minecraft:diamond_sword"}, {1}, false, "To harvest spider webs\n you need a diamond sword.") --checkInventoryForItem(self, items, quantities, required, message, name)
			if returned ~= nil then
				inInventory = "minecraft:diamond_sword"
			end
		end
		T:checkInventoryForItem({"minecraft:torch"}, {8}, false)
		if inInventory == "minecraft:diamond_sword" then
			print("Clearing Mineshaft and cobwebs")
		else
			print("Clearing Mineshaft")
		end
		retValue = clearMineshaft(equippedRight, equippedLeft, inInventory) -- pass whether the sword is present
	elseif R.choice == 17 then --QuickMine coridoor
		utils.checkFuelNeeded((R.width * 2 + R.length * 2) * 2)
		T:checkInventoryForItem({"stone"}, {R.width * 2 + R.length * 2}, false)
		T:checkInventoryForItem({"minecraft:torch"}, {math.floor((R.width * 2 + R.length * 2) / R.torchInterval)}, false)
		T:checkInventoryForItem({"minecraft:bucket"}, {1}, false)
		print("QuickMine coridoor: R.subChoice "..R.width.. " x "..R.length)
		retValue = quickMineCorridor(R)
	elseif R.choice == 18 then --QuickMine
		utils.checkFuelNeeded(R.width * R.length)
		T:checkInventoryForItem({"stone"}, {64})
		T:checkInventoryForItem({"minecraft:bucket"}, {1}, false)
		print("QuickMine rectangle: R.subChoice "..R.width.. " x "..R.length)
		retValue = quickMine(R)
	elseif R.choice == 19 then --Mine bedrock area
		utils.checkFuelNeeded(R.width * R.length)
		T:checkInventoryForItem({"stone"}, {64})
		T:checkInventoryForItem({"minecraft:bucket"}, {1}, false)
		retValue = mineBedrockArea(R.width, R.length, R.height) -- R.height = bool leaveExposed
		
	-- FORESTRY
	elseif R.choice == 21 then	-- Fell tree
		if T:isLog("forward") then
			T:checkInventoryForItem({"minecraft:chest"}, {1}, false)
			if turtle.getFuelLevel() >= 30 then -- is fuel at least 30?
				T:forward(1)
			else -- assume new empty turtle
				turtle.select(1)
				T:dig("forward")
				T:craft("planks", 4)
				T:refuel()
				T:forward(1)
				T:up(2)
				T:craft("chest", 1)
			end
			print("Press esc within 2 seconds!")
			os.sleep(2)    -- pause for 2 secs to allow time to press esc
			print("Felling tree")
			T:harvestWholeTree("up")
			while turtle.down() do end
			retValue = {"Tree Harvested"}
		else
			retValue =
			{
				"No log in front..",
				"Move me in front of a tree!"
			}
		end
	elseif R.choice == 22 then --Create treefarm
		if R.subChoice == 1 then
			utils.checkFuelNeeded(300)
		else
			utils.checkFuelNeeded(900)
		end
		T:checkInventoryForItem({"minecraft:dirt"}, {64})
		if R.subChoice == 1 then
			T:checkInventoryForItem({"minecraft:torch"}, {16}, false)
		else
			T:checkInventoryForItem({"minecraft:torch"}, {64}, false)
		end
		print(thanks)
		sleep(2)
		print("CreateTreefarm starting: size "..R.subChoice)
		retValue = createTreefarm(R)
	elseif R.choice == 23 then -- Plant treefarm
		if R.subChoice == 1 then
			utils.checkFuelNeeded(180)
			T:checkInventoryForItem({"dirt"}, {16})
			T:checkInventoryForItem({"sapling"}, {4}, "Max 16. NOT dark oak")
		elseif R.subChoice == 3 then
			utils.checkFuelNeeded(180)
			T:checkInventoryForItem({"dirt"}, {16})
			T:checkInventoryForItem({"sapling"}, {4}, "Max 16. 4 saplings / tree")
		end
		print(thanks)
		print("plantTreefarm starting: size "..R.subChoice)
		retValue = plantTreefarm(R)
	elseif R.choice == 24 then	-- Harvest treefarm
		print(thanks)
		os.sleep(2)
		print("Harvesting treefarm starting")
		retValue = harvestTreeFarm(R)
	elseif R.choice == 25 then -- create auto tree farm
		utils.checkFuelNeeded(1000)
		T:checkInventoryForItem({"minecraft:chest"}, {3})
		T:checkInventoryForItem({"minecraft:dirt"}, {128})
		T:checkInventoryForItem({"minecraft:cobblestone"}, {128})
		T:checkInventoryForItem({"minecraft:water_bucket"}, {2})
		T:checkInventoryForItem({"minecraft:hopper"}, {1})
		T:checkInventoryForItem({"minecraft:torch"}, {21})
		T:checkInventoryForItem({"sapling"}, {21}, false)
		print(thanks)
		os.sleep(2)    -- pause for 2 secs to allow time to press esc
		print("Creating automatic tree farm...")
		retValue = createAutoTreeFarm()
	elseif R.choice == 26 then	-- Manage auto-treefarm
		retValue = manageFarmSetup("tree")
	elseif R.choice == 27 then	-- clear natural forest
		T:checkInventoryForItem({"minecraft:chest"}, {1})
		T:checkInventoryForItem({"sapling"}, {64}, false)
		print(thanks)
		print("Clearing and replanting trees")
		os.sleep(2)    -- pause for 2 secs to allow time to press esc
		retValue = clearAndReplantTrees()
	end
	return retValue
end

local function getTaskInventoryTo70(R)
	local retValue = {}
	local thanks = "Thank you.\n\nPress the ESC key\n\nStand Back..\n"
	-- FARMING
	if R.choice == 31 then	-- Create modular farm
		utils.checkFuelNeeded(300)
		T:checkInventoryForItem({"stone"}, {64})
		T:checkInventoryForItem({"dirt"}, {128}, false)
		T:checkInventoryForItem({"minecraft:water_bucket"}, {4})
		T:checkInventoryForItem({"minecraft:chest"}, {4})
		T:checkInventoryForItem({"sapling"}, {1})
		T:checkInventoryForItem({"minecraft:crafting_chest"}, {1})
		print(thanks)
		os.sleep(2)    -- pause for 2 secs to allow time to press esc
		print("Creating modular wheat farm")
		retValue = createFarm()
	elseif R.choice == 32 then	-- Extend modular farm
		utils.checkFuelNeeded(300)
		T:checkInventoryForItem({"stone"}, {64})
		T:checkInventoryForItem({"dirt"}, {128}, false)
		T:checkInventoryForItem({"minecraft:water_bucket"}, {4})
		T:checkInventoryForItem({"minecraft:chest"}, {4})
		T:checkInventoryForItem({"sapling"}, {1})
		T:checkInventoryForItem({"minecraft:crafting_chest"}, {1})
		print("Checking position...\n")
		os.sleep(2)    -- pause for 2 secs to allow time to press esc
		retValue = createFarmExtension(R) -- subChoice = 1 for ahead, 2 for to the right
	elseif R.choice == 33 then	-- manage modular farm
		retValue = manageFarmSetup("farm")
	elseif R.choice == 34 then	-- create squid farm
		local choices = {"Grid of water columns","Bubble trap in river"}
		local choice = menu.new("Choose farm type", choices)
		if choice == 1 then
			choices = {"Create platform above river","Create walls to river bed","Dig shaft to base","Add gate traps"}
			choice = menu.new("Choose farm stage", choices)
			if choice == 1 then
				utils.checkFuelNeeded(400)
				T:checkInventoryForItem({"dirt"}, {225}, false)
				T:checkInventoryForItem({"minecraft:water_bucket"}, {2})
				retValue = createSquidFarmGrid()
			elseif choice == 2 then
				utils.checkFuelNeeded(4000)
				T:checkInventoryForItem({"stone"}, {640}, true)
				retValue = createSquidFarmEnclosure(R)
			elseif choice == 3 then
				utils.checkFuelNeeded(4000)
				T:checkInventoryForItem({"stone"}, {128}, false)
				retValue = createSquidFarmBase(R)
			elseif choice == 4 then
				utils.checkFuelNeeded(1000)
				T:checkInventoryForItem({"gate"}, {80}, true)
				T:checkInventoryForItem({"bucket"}, {5}, true)
				retValue = createSquidFarmGateTraps(R)
			end
		else
			choices = {"Build dam across river","Place soulsand on river bed","Create sloping water"}
			choice = menu.new("Choose bubble trap stage", choices)
			if choice == 1 then -- Build dam across river
				R.width = 1
				R.length = utils.getSize(false, "Length of the wall (1-64)", 1, 64)
				R.height = utils.getSize(false, "Fixed depth or 0 = to floor", 0, 60)
				utils.checkFuelNeeded(R.length * R.length)
				local depth = R.height
				if depth == 0 then
					depth = 5
				end
				T:checkInventoryForItem({"stone"}, {R.length * depth}, false)
				print("Building retaining wall in water. length "..R.length)
				retValue = createRetainingWall(R)		
			elseif choice == 2 then
				R.width = utils.getSize(false, "water width (1 to 64)", 1, 64)
				R.length = utils.getSize(false, "water length (1 to 62)", 1, 64)
				utils.checkFuelNeeded(R.length * R.width * 4)
				T:checkInventoryForItem({"soul_sand"}, {R.length * R.width})
				print("Placing soul sand. length: "..R.length.." width: "..R.width)
				retValue = createBubbleTrap(R)
			elseif choice == 3 then
				R.width = utils.getSize(false, "water slope width (usually 7/8)", 1, 8)
				R.length = utils.getSize(false, "water slope length ", 1, 64)
				utils.checkFuelNeeded(R.length * R.width * 3)
				local buckets = math.floor(R.length / 2) + 1
				T:checkInventoryForItem({"water_bucket", "bucket"}, {buckets, buckets})
				T:checkInventoryForItem({"slab"}, {R.length * R.width})
				print("Creating sloping water field "..R.width.." x "..R.length.." x ".. R.height)
				retValue = createSlopingWater(R)
			end
		end
	
	-- OBSIDIAN
	elseif R.choice == 41 then --harvest obsidian
		utils.checkFuelNeeded(R.width * R.length * 3)
		T:checkInventoryForItem({"stone"}, {R.width * R.length})
		print(thanks)
		sleep(2)
		print("Harvesting obsidian area: size "..R.width.. " x "..R.length)
		retValue = harvestObsidian(R)
	elseif R.choice == 42 then --build nether portal
		utils.checkFuelNeeded(20)
		T:checkInventoryForItem({"minecraft:obsidian"}, {R.width * R.height})
		T:checkInventoryForItem({"stone"}, {R.width + 4})
		print(thanks)
		sleep(2)
		print("Building Nether portal")
		retValue = createPortal(R)
	elseif R.choice == 43 then --demolish nether portal
		utils.checkFuelNeeded(20)
		print("Demolishing Nether portal")
		retValue = demolishPortal(R)
	elseif R.choice == 44 then --undermine dragon towers
		local help = getTaskHelp(2, 44) -- compulsory help display
		if help == "" then -- Enter only pressed
			utils.checkFuelNeeded(500)
			T:checkInventoryForItem({"minecraft:cobblestone", "minecraft:cobbled_deepslate"}, {84, 84})
			print("Undermining dragon towers")
			retValue = undermineDragonTowers()
		end
	elseif R.choice == 45 then --deactivate dragon tower
		local help = getTaskHelp(2, 45) -- compulsory help display
		if help == "" then -- Enter only pressed
			utils.checkFuelNeeded(50)
			print("Deactivating dragon tower")
			retValue = deactivateDragonTower()
		end
	elseif R.choice == 46 then --build dragon attack area
		local help = getTaskHelp(2, 46) -- compulsory help display
		if help == "" then -- Enter only pressed
			utils.checkFuelNeeded(200)
			T:checkInventoryForItem({"stone"}, {128})
			print("Building dragon attack area")
			retValue = createDragonAttack()
		end
	elseif R.choice == 47 then -- attack dragon
		if menu.getBoolean("Near the Dragon perch? (y/n)") then
			local help = getTaskHelp(2, 47) -- compulsory help display
			if help == "" then -- Enter only pressed
				attack(true)
			end
		else
			attack(false) -- used for shulkers or in dragon water trap
		end
	elseif R.choice == 48 then --build portal minecart station
		local help = getTaskHelp(2, 48) -- compulsory help display
		if help == "" then -- Enter only pressed
			utils.checkFuelNeeded(200)
			T:checkInventoryForItem({"stone"}, {64})
			T:checkInventoryForItem({"minecraft:powered_rail", "minecraft:golden_rail"}, {1, 1}, false)
			T:checkInventoryForItem({"minecraft:rail"}, {2}, false)
			T:checkInventoryForItem({"minecraft:minecart"}, {1}, false)
			T:checkInventoryForItem({"minecraft:stone_button"}, {1}, false)
			T:checkInventoryForItem({"minecraft:ladder"}, {10}, false)
			print("Building portal platform")
			retValue = createPortalPlatform()
		end
	elseif R.choice == 49 then --build dragon water trap
		local help = getTaskHelp(2, 49) -- compulsory help display
		if help == "" then -- Enter only pressed
			utils.checkFuelNeeded(256)
			T:checkInventoryForItem({"stone"}, {256})
			T:checkInventoryForItem({"minecraft:obsidian"}, {1})
			T:checkInventoryForItem({"minecraft:ladder"}, {145})
			T:checkInventoryForItem({"minecraft:water_bucket"}, {1})
			print("Building dragon water trap")
			retValue = createDragonTrap()
		end
		
	-- CANAL BRIDGE
	elseif R.choice == 51 then	-- continuous path over void/water/lava
		utils.checkFuelNeeded(512) -- allow for 512 R.length
		T:checkInventoryForItem({"stone"}, {R.length}, false)
		--T:checkInventoryForItem({"minecraft:cobblestone",  "minecraft:dirt"}, {64, 64}, false)
		T:checkInventoryForItem({"minecraft:torch"}, {math.floor(R.length/8)}, false)
		print(thanks)
		os.sleep(2)    -- pause for 2 secs to allow time to press esc
		print("Building continuous path")
		retValue = createPath(R)
	elseif R.choice == 52 then	-- simple 2 block coridoor
		utils.checkFuelNeeded(R.length)
		T:checkInventoryForItem({"stone"}, {R.length * 2}, false)
		T:checkInventoryForItem({"minecraft:torch"}, {math.floor(R.length * 2 / 8)}, false)
		print(thanks)
		os.sleep(2)    -- pause for 2 secs to allow time to press esc
		print("Building simple coridoor")
		retValue = createCorridor(R)
	elseif R.choice == 53 then	-- bridge over void/water/lava
		utils.checkFuelNeeded((R.length + 1) * 2)
		T:checkInventoryForItem({"stone"}, {R.length * 2})
		print(thanks)
		os.sleep(2)    -- pause for 2 secs to allow time to press esc
		print("Building bridge ".. R.length.." blocks")
		retValue = createBridge(R)
	elseif R.choice == 54 then	-- covered walkway
		utils.checkFuelNeeded((R.length + 1) * 2)
		T:checkInventoryForItem({"stone"}, {R.length * 2})
		T:checkInventoryForItem({"minecraft:torch"}, {math.ceil(R.length / 8)}, false)
		print(thanks)
		os.sleep(2)    -- pause for 2 secs to allow time to press esc
		print("Building covered walkway ".. R.length.." blocks")
		retValue = createWalkway(R)
	elseif R.choice == 55 then	-- canal management
		getTaskHelp(2, 55) -- compulsory help display
		read() -- pause until user ready
		local torches = 64
		if R.length > 0 then
			utils.checkFuelNeeded(R.length * 4) -- allow for 1024 R.length
			torches = math.floor(R.length / 8)
		else
			utils.checkFuelNeeded(2048) -- allow for 1024 R.length
		end
		T:checkInventoryForItem({"stone"}, {256})
		T:checkInventoryForItem({"minecraft:water_bucket"}, {2})
		T:checkInventoryForItem({"minecraft:torch"}, {torches}, false)
		print(thanks)
		os.sleep(2)    -- pause for 2 secs to allow time to press esc
		print("Building canal")
		retValue = createCanal(R) -- eg 0, 312, 1 = complete a canal 312 blocks long on top of the wall
	elseif R.choice == 56 then	-- ice canal
		--getTaskHelp(2, 56) -- compulsory help display
		--read() -- pause until user ready
		local default = R.length
		if R.length > 0 then
			utils.checkFuelNeeded(R.length)
		else
			default = 64
			utils.checkFuelNeeded(default * 2) -- allow for 128 min R.length
		end
		--R.subChoice = 1,2,3,4 edge+torch, ice canal, air, edge no torch
		if R.subChoice == 1 then	-- towpath with torches
			T:checkInventoryForItem({"trapdoor"}, {default})
			T:checkInventoryForItem({"slab"}, {default})
			T:checkInventoryForItem({"stone"}, {math.ceil(default / 8)})
			T:checkInventoryForItem({"torch"}, {math.ceil(default / 8)}, false)
		elseif R.subChoice == 2 then	-- ice canal with 2 spaces above
			T:checkInventoryForItem({"minecraft:packed_ice", "minecraft:blue_ice"}, {math.ceil(R.length / 2), math.ceil(R.length / 2)}, false)
		elseif R.subChoice == 3 then -- 3 block high space
			-- no special instructions
		elseif R.subChoice == 4 then	-- towpath without torches
			T:checkInventoryForItem({"trapdoor"}, {default})
			T:checkInventoryForItem({"slab"}, {default})
		end
		print(thanks)
		os.sleep(2)    -- pause for 2 secs to allow time to press esc
		print("Building ice canal")
		retValue = createIceCanal(R)
	elseif R.choice == 57 then -- platform
		local volume = R.width * R.length
		utils.checkFuelNeeded(volume)
		T:checkInventoryForItem({"stone", "dirt"}, {volume, volume})
		print(thanks)
		os.sleep(2)    -- pause for 2 secs to allow time to press esc
		print("Building platform")
		retValue = createPlatform(R)
	elseif R.choice == 58 then -- sinking platform
		local volume = (R.width + 1) * (R.length + 1) 
		utils.checkFuelNeeded(volume * (R.height + 1))
		T:checkInventoryForItem({"stone"}, {volume})
		print(thanks)
		os.sleep(2)    -- pause for 2 secs to allow time to press esc
		print("Building sinking platform")
		retValue = createSinkingPlatform(R)
	elseif R.choice == 59 then -- boat bubble lift
		getTaskHelp(2, 59) -- compulsory help display
		read() -- pause until user ready
		utils.checkFuelNeeded(R.height * 6)
		T:checkInventoryForItem({"minecraft:water_bucket"}, {2})
		T:checkInventoryForItem({"stone"}, {R.height * 4 + 8})
		T:checkInventoryForItem({"sign"}, {2})
		if R.subChoice == 0 then -- new lift
			T:checkInventoryForItem({"minecraft:soul_sand"}, {2})
			T:checkInventoryForItem({"slab"}, {2})
		end
		print(thanks)
		os.sleep(2)    -- pause for 2 secs to allow time to press esc
		print("Building boat bubble lift")
		retValue = createBoatLift(R) -- R.subChoice:0=new, R.subChoice:1=extend, R.length:0=left, 1=right
	elseif R.choice == 510 then	-- ice canal borders with trapdoors/slabs
		local default = R.length
		if R.length > 0 then
			utils.checkFuelNeeded(R.length)
		else
			default = 64
			utils.checkFuelNeeded(default * 2) -- allow for 128 min R.length
		end
		T:checkInventoryForItem({"trapdoor"}, {default})
		T:checkInventoryForItem({"slab"}, {default})
		T:checkInventoryForItem({"stone"}, {math.ceil(default / 8)})
		T:checkInventoryForItem({"torch"}, {math.ceil(default / 8)}, false)
		print(thanks)
		os.sleep(2)    -- pause for 2 secs to allow time to press esc
		print("Building ice canal barrier")
		retValue = createIceCanalBorder(R) -- 0 R.length = continue while supplies last
	-- MOB SPAWNER
	elseif R.choice == 61 then	--  9x9 hollow cube cobble lined
		utils.checkFuelNeeded(600) -- allow for 600 moves
		T:checkInventoryForItem({"stone"}, {256}, false, "Full cube uses ~700 blocks\nEstimate your requirements")
		T:checkInventoryForItem({"slab"}, {1})
		print(thanks)
		os.sleep(2)    -- pause for 2 secs to allow time to press esc
		retValue = createMobFarmCube(R, false, false) -- not blaze, not contiuation of blaze
	elseif R.choice == 62 then	-- Blaze spawner
		utils.checkFuelNeeded(2500) -- allow for 2500 moves
		local continue = menu.getBoolean("Is this a new spawner? (y/n)\n('n' if building blaze killzone)")
		continue = not continue -- answered y to new spawner: not continuing!
		if not continue then
			T:checkInventoryForItem({"stone"}, {640})
			T:checkInventoryForItem({"slab"}, {1})
			print("You will be asked for more assets later\n")
			os.sleep(2)    -- pause for 2 secs to allow time to press esc
		end
		retValue = createMobFarmCube(R, true, continue)	
	elseif R.choice == 63 then	--  flood mob spawner
		utils.checkFuelNeeded(60) -- allow for 60 moves
		T:checkInventoryForItem({"minecraft:water_bucket"}, {2})
		T:checkInventoryForItem({"fence"}, {2})
		T:checkInventoryForItem({"sign"}, {2})
		T:checkInventoryForItem({"slab"}, {1})
		T:checkInventoryForItem({"minecraft:soul_sand", "minecraft:dirt"}, {1, 1}, true)
		print(thanks)
		os.sleep(2)    -- pause for 2 secs to allow time to press esc
		retValue = floodMobFarm()
	elseif R.choice == 64 then -- build bubble lift on top of soul sand
		utils.checkFuelNeeded(200) -- allow for 200 moves
		T:checkInventoryForItem({"minecraft:water_bucket"}, {2})
		T:checkInventoryForItem({"stone"}, {128})
		if T:getBlockType("down") ~= "minecraft:soul_sand" then
			T:checkInventoryForItem({"minecraft:soul_sand"}, {1})
		end
		print(thanks)
		os.sleep(2)    -- pause for 2 secs to allow time to press esc
		retValue = createMobBubbleLift(R)
	elseif R.choice == 65 then -- dig mob trench
		utils.checkFuelNeeded(R.length * R.height) -- allow for 600 moves
		T:checkInventoryForItem({"stone"}, {128})
		print(thanks)
		os.sleep(2)    -- pause for 2 secs to allow time to press esc
		retValue = digMobTrench(R)
	elseif R.choice == 66 then -- build endermen tower
		-- build in 3 sections, base, tower, top
		getTaskHelp(2, 66) -- compulsory help display
		read() -- pause until user ready
		local numFuel = 700
		local choices = 
		{
			"New tower lower base",
			"Add tower upper base + killzone",
			"128 block tower to existing base"
		}
		local option, modifier = menu.new("Select build stage:", choices)
		if option == 1 then --lower base
			T:checkInventoryForItem({"minecraft:chest"}, {1})
			T:place("chest", -1, "down", false)
			T:emptyInventory("up")
			utils.checkFuelNeeded(320) -- allow for 320 moves
			T:checkInventoryForItem({"stone"}, {144}) -- <3 stacks
			T:checkInventoryForItem({"minecraft:water_bucket"}, {2})
			T:checkInventoryForItem({"fence"}, {4})
			T:checkInventoryForItem({"sign"}, {4})
			T:checkInventoryForItem({"door"}, {2})
			T:checkInventoryForItem({"minecraft:soul_sand"}, {1})
		elseif option == 2 then -- upper base
			utils.checkFuelNeeded(710) -- allow for 703 moves
			T:checkInventoryForItem({"stone"}, {384}) -- 6 stacks
			T:checkInventoryForItem({"minecraft:bucket"}, {4})
			T:checkInventoryForItem({"fence"}, {15})
			T:checkInventoryForItem({"sign"}, {4})
			T:checkInventoryForItem({"ladder"}, {3})
			T:checkInventoryForItem({"minecraft:soul_sand"}, {1})
		else -- main tower
			utils.checkFuelNeeded(3000) -- allow for 3000 moves
			if T:getBlockType("down") ~= "minecraft:chest" then
				T:checkInventoryForItem({"minecraft:chest"}, {1})
				T:place("chest", -1, "down", false)
			end
			T:checkInventoryForItem({"stone"}, {768}) -- 12 stacks
			T:checkInventoryForItem({"minecraft:bucket"}, {10})
			T:checkInventoryForItem({"fence"}, {64})	-- 1 stacks		
		end
		print(thanks)
		os.sleep(2)    -- pause for 2 secs to allow time to press esc
		retValue = createEnderTower(option) -- 1, 2, or 3
	end
	return retValue
end

local function getTaskInventory(R)
	-- run this loop 2x per second to check if player has put anything in the inventory
	-- fuel 1 coal = 60 = 4 planks. 64 planks = 16 coal = 960 units
	local retValue = {}
	local thanks = "Thank you.\n\nPress the ESC key\n\nStand Back..\n"
	
	if R.choice < 31 then 
		return getTaskInventoryTo30(R) -- Mining, Forestry
	elseif R.choice < 71 then
		return getTaskInventoryTo70(R) -- Farming, Obsidian, Canal / Bridge
	elseif R.choice > 500 and R.choice < 700 then
		return getTaskInventoryTo70(R)
	else -- Area carving, Lava/Water, Railway
		-- AREA CARVING
		if R.choice == 71 then--Clear area
			utils.checkFuelNeeded(R.width * R.length * 3)
			T:checkInventoryForItem({"minecraft:dirt"}, {64})
			print(thanks)
			sleep(2)
			print("Clearing area: size "..R.width.. " x "..R.length)
			retValue = clearArea(R, true)
		elseif R.choice == 72 then --Clear rectangle
			-- R.choice, R.width(R.subChoice), R.length(R.width), up(R.length), down(R.height) from getTask()
			utils.checkFuelNeeded(R.width * R.length)
			print("Clearing rectangle: size "..R.width.. " x "..R.length)
			retValue = clearRectangle(R)
		elseif R.choice == 73 then --Clear wall
			utils.checkFuelNeeded(R.length * R.height)
			print("Removing wall "..R.length.." long x "..R.height.." high")
			R.width = 1 -- single block
			retValue = clearWall(R)
		elseif R.choice == 74 then --Clear single R.height perimeter wall
			utils.checkFuelNeeded((R.width + R.length) * 2)
			print("Recycling wall section "..R.width.." x "..R.length)
			R.up = false
			R.down = false
			retValue = clearPerimeter(R)
		elseif R.choice == 75 then --Clear hollow structure
			local withCeiling = true
			local withFloor = true
			local withCeiling = menu.getBoolean("Remove ceiling? (y/n)")
			local withFloor = menu.getBoolean("Remove floor? (y/n)")
			utils.checkFuelNeeded((R.width * R.length) + ((R.width + R.length) * R.height))
			print("Recycling hollow object "..R.width.." x "..R.length.." height: "..R.height)
			retValue = clearBuilding(R, withCeiling, withFloor)
		elseif R.choice == 76 then --Clear solid structure / extend water pool
			utils.checkFuelNeeded((R.width * R.length) + ((R.width + R.length) * R.height))
			print("Recycling solid object w:"..R.width..", l:"..R.length..", h:"..R.height)
			retValue = clearSolid(R)
		elseif R.choice == 77 then	-- Dig trench
			utils.checkFuelNeeded(R.height * R.length * 2)
			print(thanks)
			os.sleep(2)    -- pause for 2 secs to allow time to press esc
			if R.length == 0 then
				print("Digging continuous trench "..R.height.." blocks deep")
			else
				print("Digging trench "..R.length.." blocks long, "..R.height.." blocks deep")
			end
			retValue = digTrench(R)
		elseif R.choice == 78 then --Carve mountain
			utils.checkFuelNeeded(R.length * R.width * 10)
			print("Carving mountain side "..R.width.." x "..R.length)
			retValue = clearMountainSide(R)
		elseif R.choice == 79 then -- Place floor or Ceiling
			utils.checkFuelNeeded(R.width * R.length)
			T:clear()
			print("IMPORTANT!\n\nRemove any items not used to create\nthe floor or ceiling.")
			print("\n\nAdd at least "..R.width * R.length.." any blocks\nstarting in slot 1\n\n")
			term.write("Next -> Enter")
			read()
			retValue = createFloorCeiling(R) -- R.subChoice integer 1 to 4
			
		-- LAVA WATER
		--[[
			81 "Sand based utilities",
				R.subChoice=1 "Drop sand or gravel wall",
				R.subChoice=2 "Decapitate and fill with sand",
				R.subChoice=3 "Clear sand wall",
				R.subChoice=4 "Clear sand filled building",
			82 "Vertical wall from surface",
			83 "Create enclosed area",
			84 "Clear volume of water",
			85 "Clear monument layer",
			86 "Ladder down to water/lava",
			87 "Clear water plants"
			88 "Convert all water to source
			89 "Create sloping water"
		]]
		elseif R.choice == 81 then -- Sand based utilities
			if R.subChoice == 1 then	-- Drop sand or gravel wall
				utils.checkFuelNeeded(100)
				T:checkInventoryForItem({"sand", "gravel"}, {1024, 1024}, false)
				if R.length == 0 then
					print("Building sand wall. Auto length: ")
				else
					print("Building sand wall. length: "..R.length)
				end
				retValue = createSandWall(R)
			elseif R.subChoice == 2 then	-- Decapitate and fill with sand
				utils.checkFuelNeeded(R.length * R.width)
				T:checkInventoryForItem({"minecraft:sand"}, {768}, false)
				print("Decapiating structure. length: "..R.length.." width: "..R.width)
				retValue = decapitateBuilding(R)
			elseif R.subChoice == 3 then -- Clear sand wall
				utils.checkFuelNeeded(100)
				if R.length == 0 then
					print("Digging sand. Auto length")
				else
					print("Digging sand. length: "..R.length)
				end
				retValue = clearSandWall(R)
			elseif R.subChoice == 4 then	-- Clear sand filled building
				utils.checkFuelNeeded(R.length * R.width * 4)
				print("Removing sand cube. length: "..R.length.." width: "..R.width)
				retValue = clearSandCube(R)
			end
		
		elseif R.choice == 82 then --build containing wall in water or lava
			utils.checkFuelNeeded(R.length * R.length)
			local depth = R.height
			if depth == 0 then
				depth = 5
			end
			T:checkInventoryForItem({"stone"}, {R.length * depth}, false)
			print("Building retaining wall in lava/water. length "..R.length)
			retValue = createRetainingWall(R)			
		elseif R.choice == 83 then -- create a rectangle path in water/lava
			utils.checkFuelNeeded(200)
			createRectanglePath(R)
		elseif  R.choice == 84 then -- Delete water/lava
			if R.width == 0 then
				utils.checkFuelNeeded(2000)
				T:checkInventoryForItem({"stone"}, {256}, false)
				print("Deleting water using auto-detection")
			else
				utils.checkFuelNeeded(R.width * R.length * R.height)
				T:checkInventoryForItem({"stone"}, {math.max(R.length, R.width) * 2}, false)
				print("Deleting enclosed water "..R.width.." x "..R.length.." x ".. R.height)
			end
			retValue = utils.drainWaterLava(R)
		elseif R.choice == 85 then --clear monument layer
			--[[
			1 Build 4 corner marker columns
			2 Retaining wall beween 2 columns
			3 Clear plants pre sand draining
			4 Use sand draining
			5 Drain and remove structure
			]]
			if R.subChoice == 1 then	-- 4 corners
				T:checkInventoryForItem({"stone"}, {448})
				retValue = oceanMonumentColumns(R)
			elseif R.subChoice == 2 then	-- 
				T:checkInventoryForItem({"stone"}, {1024})
				retValue = createRetainingWall(R, true)
			elseif R.subChoice == 3 then	-- 
				retValue = clearWaterPlants(R)
			elseif R.subChoice == 4 then	-- 
				retValue = {"Not available yet","Still under construction"}
			elseif R.subChoice == 5 then	-- 
				retValue = {"Not available yet","Still under construction"}
			end
		elseif R.choice == 86 then --ladder to water/lava
			utils.checkFuelNeeded(R.height * 2)
			T:checkInventoryForItem({"minecraft:ladder"}, {R.height})
			local cobble = R.height * 3 + 10
			T:checkInventoryForItem({"stone"}, {cobble})
			print(thanks)
			os.sleep(2)    -- pause for 2 secs to allow time to press esc
			print("Creating ladder to bedrock")
			retValue = createLadderToWater()
		elseif R.choice == 87 then --remove plants
			utils.checkFuelNeeded(R.length * R.width * 4)
			T:checkInventoryForItem({"sand", "stone"}, {64, 64})
			local width = R.width
			local length = R.length
			if width == 0 then
				width = "auto"
			end
			if length == 0 then
				length = "auto"
			end
			print("Removing water plants. length: "..length.." width: "..width)
			retValue = clearWaterPlants(R)
		elseif R.choice == 88 then -- convert flowing water to source
			--utils.checkFuelNeeded(R.length * R.width * 4) -- unknown as size not calculated
			T:checkInventoryForItem({"water_bucket", "bucket"}, {12, 12})
			T:checkInventoryForItem({"slab"}, {128})
			print("Converting water to source "..R.width.." x "..R.length.." x ".. R.height)
			retValue = convertWater(R)
		elseif R.choice == 89 then -- create sloping water
			utils.checkFuelNeeded(R.length * R.width * 3)
			local buckets = math.floor(R.length / 2) + 1
			T:checkInventoryForItem({"water_bucket", "bucket"}, {buckets, buckets})
			T:checkInventoryForItem({"slab"}, {R.length * R.width})
			print("Creating sloping water field "..R.width.." x "..R.length.." x ".. R.height)
			retValue = createSlopingWater(R)
		-- RAILWAY
		elseif R.choice == 91 then --place redstone torch level or downward slope
			utils.checkFuelNeeded(10)
			local userChoice = T:checkInventoryForItem({"stone"}, {1})
			T:checkInventoryForItem({"minecraft:redstone_torch"}, {1})
			print("Placing redstone torch on ".. userChoice)
			retValue = placeRedstoneTorch("level", userChoice)
		elseif R.choice == 92 then --place redstone torch on upward slope
			utils.checkFuelNeeded(10)
			local userChoice = T:checkInventoryForItem({"stone"}, {1})
			T:checkInventoryForItem({"minecraft:redstone_torch"}, {1})
			print("Placing redstone torch and ".. userChoice)
			retValue = placeRedstoneTorch("up", userChoice)
		elseif R.choice == 93 then --build downward slope
			utils.checkFuelNeeded(R.height * 2)
			T:checkInventoryForItem({"stone"}, {R.height})
			--T:checkInventoryForItem({"minecraft:redstone_torch"}, {math.ceil(R.height / 3)}, false)
			print("Building downward slope")
			retValue = createRailwayDown(R.height)
		elseif R.choice == 94 then --build upward slope
			utils.checkFuelNeeded(R.height * 2)
			T:checkInventoryForItem({"stone"}, {R.height + math.ceil(R.height / 3)})
			--T:checkInventoryForItem({"minecraft:redstone_torch"}, {math.ceil(R.height / 3)}, false)
			print("Building upward slope")
			retValue = createRailwayUp(R.height)
		elseif R.choice == 101 or R.choice == 102 or R.choice == 103 or R.choice == 104 then -- measure height/depth/length
			retValue = measure(R)
		end
	end
	return retValue
end

local function main()
	local lib = {}
	
	function lib.checkLabel()
		if os.getComputerLabel() == nil then
			os.setComputerLabel("toolkit")
			print("Computer label set to "..os.getComputerLabel())
		end
	end
	
	function lib.checkLibs(libDir, filename)
		local fileExists = false
		if fs.exists(libDir) then
			if not fs.isDir(libDir) then
				fs.move(libDir, libDir.."Renamed")
				fs.makeDir(libDir)
			end
		else
			fs.makeDir(libDir)
		end
		if fs.exists(fs.combine(libDir, filename)) or fs.exists(fs.combine(libDir, filename..".lua")) then
			fileExists = true
		end
		return fileExists
	end
	
	local doContinue = true
	lib.checkLabel() -- make sure turtle label is set
	--check if lib folder exists
	if not lib.checkLibs("lib", "clsTurtle") then
		-- use pastebin get to download clsTurtle to libs folder
		print("Missing clsTurtle.lua in libs directory")
		print("Attempting to obtain from Pastebin...")
		if shell.run("pastebin","get","tvfj90gK","lib/clsTurtle.lua") then
			print("clsTurtle.lua installed from Pastebin")
		else
			print("failed to install clsTurtle.lua from Pastebin")
			doContinue = false
		end
	end
	if not lib.checkLibs("lib", "menu") then
		-- use pastebin get to download menu.lua to libs folder
		print("Missing menu.lua in libs directory")
		print("Attempting to obtain from Pastebin...")
		if shell.run("pastebin","get","BhjbYsw4","lib/menu.lua") then
			print("menu.lua installed from Pastebin")
		else
			print("failed to install menu.lua from Pastebin")
			doContinue = false
		end
	end
	if doContinue then
		local result = {}
		menu = require("lib.menu")
		T = require("lib.clsTurtle").new(false) -- true enables logfile to log.txt note dot NOT colon
		T:clear()
		if args[1] ~= nil then
			if args[1] == "farm" then
				manageFarm()
			elseif args[1] == "tree" then
				manageTreeFarm() -- use file to read status
			elseif args[1] == "help" then
				-- missing turtle
				T:setUseLog(true)
				T:setLogFileName("locate.txt")
				T:appendLine("Booting succeeded")
				T:appendLine("Block ahead: "..T:getBlockType("forward"))
				T:appendLine("Block above: "..T:getBlockType("up"))
				T:appendLine("Block below: "..T:getBlockType("down"))
			end
		else
			print("Minecraft major version: "..mcMajorVersion)
			print("Bedrock level: "..bedrock)
			if T:getUseLog() then
				print("Logging enabled")
			else
				print("Logging disabled")
			end	
			sleep(1)
			local R =
			{
				choice = 0,
				subChoice = 0,
				size = 0,
				width = 0,
				length = 0,
				height = 0,
				up = false,
				down = false,
				silent = false,
				data = "",
				torchInterval = 0,
				useBlockType = ""
			}
			local itemsRequired = getTaskItemsList()
			while R.choice <= 0 do
				R = getTask(R, itemsRequired)
				if R.choice == -1 then -- "q" chosen
					break
				elseif R.choice > 0 then
					result = getTaskInventory(R) -- table of comments
					-- return choice, width(size), length(width), up(length), down(height) from clearRectangle
					break	-- run once only
				end
			end
		end
		T:clear()
		table.insert(result, "\nThank you for using 'survival toolkit'")
		for _, value in ipairs(result) do
			print(value)
		end
	else
		print("Add missing files and restart")
	end
end

main()