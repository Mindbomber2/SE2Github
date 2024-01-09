import "CoreLibs/sprites"
import "CoreLibs/graphics"
import "CoreLibs/object"
import "CoreLibs/crank"
import "CoreLibs/math"

gfx = playdate.graphics
sfx = playdate.sound

gameFont = gfx.font.new("font/Sasser Slab/Sasser-Slab-Bold")
gfx.setFont(gameFont)

import "helpers"
import "gameobject"
import "gamescript"
import "textscript"
import "motionscript"
import "mapchangescript"
import "npcs"
import "maps"
import "monster"
import "type"

-- CORE --
local gridSize <const> = 40
local gridWidth <const> = 400/40
local gridHeight <const> = 240/40

-- STUFF THAT ALWAYS IMPORTANT

guyImgN = gfx.image.new("img/guy-n")
guyImgE = gfx.image.new("img/guy-e")
guyImgS = gfx.image.new("img/guy-s")
guyImgW = gfx.image.new("img/guy-w")
globalBack = gfx.image.new("img/globalBack")

tilesets = {}
tileInfo = {}
overworldTiles = gfx.tilemap.new()
overworldTable = gfx.imagetable.new("img/overworld-table-40-40")
overworldTiles:setImageTable(overworldTable)
tilesets["overworld"] = overworldTiles
tileInfo["overworld"] = {3}
objs = {}

isCrankUp = false
isMenuUp = false
menuTimer = 0
showingMenu = false

local cameraHorizBuffer <const> = 6
local cameraVertBuffer <const> = 3
camWidth = 400/40
camHeight = 240/40

playerRenderPosX = 200
playerRenderPosY = 80
playerDestRenderPosX = playerRenderPosX
playerDestRenderPosY = playerRenderPosY

menuItems = {"Creatures", "Creaturedex", "Bag", "ID"}
menuIcons = {}
menuIcons["Creatures"] = gfx.image.new("img/creaturesMenuIcon")
menuIcons["Creaturedex"] = gfx.image.new("img/creaturedexMenuIcon")
menuIcons["Bag"] = gfx.image.new("img/bagMenuIcon")
menuIcons["ID"] = gfx.image.new("img/idCardMenuIcon")

function hardSetupCameraOffsets()
	cameraOffsetGridX = math.max(0, math.min(mapWidth - camWidth, playerX - cameraHorizBuffer))
	cameraOffsetGridY = math.max(0, math.min(mapHeight - camHeight, playerY - cameraVertBuffer))
	cameraOffsetX = cameraOffsetGridX * -40
	cameraOffsetY = cameraOffsetGridY * -40
	cameraDestOffsetX = cameraOffsetX
	cameraDestOffsetY = cameraOffsetY
	if (playerX < cameraHorizBuffer) then
		playerDestRenderPosX = (playerX-1) * 40
	elseif playerX > (mapWidth - (camWidth - cameraHorizBuffer)) then
		playerDestRenderPosX = (playerX - mapWidth + (camWidth) - 1) * 40
	else
		playerDestRenderPosX = (cameraHorizBuffer - 1) * 40
	end
	playerRenderPosX = playerDestRenderPosX

	if (playerY < cameraVertBuffer) then
		playerDestRenderPosY = (playerY - 1) * 40
	elseif playerY > (mapHeight - (camHeight - cameraVertBuffer)) then
		playerDestRenderPosY = (playerY - mapHeight + (camHeight) - 1) * 40
	else
		playerDestRenderPosY = (cameraVertBuffer- 1) * 40
	end
	playerRenderPosY = playerDestRenderPosY
end

function setupCameraOffset()
	if (playerX < cameraHorizBuffer or (playerX == cameraHorizBuffer and playerFacing == 1)) then
		playerDestRenderPosX = (playerX-1) * 40
	elseif playerX > (mapWidth - (camWidth - cameraHorizBuffer)) or (playerX == (mapWidth - (camWidth - cameraHorizBuffer)) and playerFacing == 3) then
		playerDestRenderPosX = (playerX - mapWidth + (camWidth) - 1) * 40
	else
		cameraOffsetGridX = (playerX - cameraHorizBuffer)
		cameraDestOffsetX = cameraOffsetGridX * -40
	end


	if (playerY < cameraVertBuffer or (playerY == cameraVertBuffer and playerFacing == 2)) then
		playerDestRenderPosY = (playerY - 1) * 40
	elseif playerY > (mapHeight - (camHeight - cameraVertBuffer)) or (playerY == (mapHeight - (camHeight - cameraVertBuffer)) and playerFacing == 0) then
		playerDestRenderPosY = (playerY - mapHeight + (camHeight) - 1) * 40
	else
		cameraOffsetGridY = (playerY - cameraVertBuffer)
		cameraDestOffsetY = cameraOffsetGridY * -40
	end

	movingCam = true
end

function setPlayerFacing(facing)
	playerFacing = facing
	if facing == 0 then
		playerImg = guyImgN
	elseif facing == 1 then
		playerImg = guyImgE
	elseif facing == 2 then
		playerImg = guyImgS
	elseif facing == 3 then
		playerImg = guyImgW
	end
end

-- VARIABLES THAT ALWAYS IMPORTANT
playerMonsters = {randomEncounterMonster("Palpillar"), randomEncounterMonster("Palpillar"), randomEncounterMonster("Palpillar")}
playerItems = {}

movingCam = false

textBoxText = ""
textBoxShown = false
textBoxScrollDone = false
textBoxTotalTime = 0
fadeOutTimer = 0
fadeInTimer = 0
fadeDest = 0
-- 1: Map
-- 2: Monsters Screen
-- 3: Individual Monster Screen

local lineThickness <const> = 2

scriptStack = {}

function nextScript()
	if #scriptStack == 0 then

	else
		local nextFound = table.remove(scriptStack, 1)
		nextFound:execute()
	end
end

function showTextBox(text)
	textBoxText = text
	textBoxDisplayedText = ""
	textBoxShown = true
	textBoxScrollDone = false
	textBoxLetterIndex = 0
end

function hideTextBox()
	textBoxShown = false
	nextScript()
end

function updateTextBox()
	if textBoxScrollDone then
		if playdate.buttonJustPressed(playdate.kButtonA) then
			hideTextBox()
		end
	else
		if playdate.buttonJustPressed(playdate.kButtonB) then
			textBoxDisplayedText = textBoxText
			textBoxScrollDone = true
		else
			local numLettersToAdd
			if playdate.buttonIsPressed(playdate.kButtonA) then
				numLettersToAdd = 2
			else
				numLettersToAdd = 1
			end
			for i=1, numLettersToAdd do
				textBoxDisplayedText = textBoxDisplayedText .. string.sub(textBoxText, textBoxLetterIndex, textBoxLetterIndex)
				textBoxLetterIndex += 1
				if textBoxLetterIndex > #textBoxText then
					textBoxScrollDone = true
				end
			end
		end
	end
end

function initialize()
	gfx.setLineWidth(lineThickness)
	loadMap("testtown", 1)
end

local textBoxOuterBuffer <const> = 10
local textBoxPosY <const> = 120
boxOutlineSize = 2
local textBoxTextBufferSize <const> = 4
local textBoxWidth <const> = 400 - (textBoxOuterBuffer * 2)
local textBoxHeight <const> = 240 - textBoxPosY - (textBoxOuterBuffer * 2)

menuIdx = 1
menuAngle = 0
local baseMenuItemOffset <const> = 180
local menuDistBetween <const> = (180/3)
local menuCrankDistBetween <const> = menuDistBetween/2
local offsetPerMenuItem <const> = menuDistBetween * -1
menuAngleToNext = 0
menuAngleToPrev = 0
local menuMaxAngle <const> = #menuItems * menuDistBetween - 35
local menuCircRadius <const> = 115
local numMenuPaddingFrames <const> = 5
menuPaddingFrames = 0

function resetMenu()
	menuAngle = menuDistBetween * (menuIdx-1)
	menuAngleToNext = 0
	menuAngleToPrev = 0
	menuPaddingFrames = 0
end

curScreen = 0
-- 0: main gameplay
-- 1: monster screen
-- 2: individual monster screen


monsterScreenSelectionIdx = 1

function openMonsterScreen()
	curScreen = 1
	monsterScreenSelectionIdx = 1
end

function openMainScreen()
	curScreen = 0
end

function updateInMenu()
	--print("next: " .. menuCrankDistBetween - menuAngleToNext)
	--print("prev: " .. menuCrankDistBetween - menuAngleToPrev)
	local change = playdate.getCrankChange() / 2
	if (change ~= 0) then
		--print("change: " .. change)
		menuPaddingFrames = numMenuPaddingFrames
		menuAngle += change
		if menuIdx < #menuItems and not (change < 0 and menuIdx == 1) then
			menuAngleToNext += change
		end
		if menuIdx > 1 and not (change > 0 and menuIdx == #menuItems) then
			menuAngleToPrev -= change
		end
		if (menuAngle < 0) then
			menuAngle = 0
		end
		if menuAngle > menuMaxAngle then
			menuAngle = menuMaxAngle
		end
		if (menuAngleToNext >= menuCrankDistBetween) then
			if (menuIdx < #menuItems) then
				--print("moved next")
				menuIdx += 1
				menuAngleToNext = 0
				menuAngleToPrev = 0
			end
		elseif menuAngleToPrev >= menuCrankDistBetween then
			if menuIdx > 1 then
				--print("moved prev")
				menuIdx -= 1
				menuAngleToNext = 0
				menuAngleToPrev = 0
			end
		end
	else
		if menuPaddingFrames > 0 then
			menuPaddingFrames -= 1
		else
			local destAngle = menuDistBetween * (menuIdx-1)
			if (menuAngle > destAngle) then
				menuAngle -= 2
				menuAngleToNext -= 2
				menuAngleToPrev += 2
				if (menuAngle <= destAngle) then
					menuAngle = destAngle
					menuAngleToNext = 0
					menuAngleToPrev = 0
				end
			elseif menuAngle < menuDistBetween * (menuIdx-1) then
				menuAngle += 2
				menuAngleToNext += 2
				menuAngleToPrev -= 2
				if menuAngle >= destAngle then
					menuAngle = destAngle
					menuAngleToNext = 0
					menuAngleToPrev = 0
				end
			end
		end
	end
	if playdate.isCrankDocked() and isCrankUp then
		isCrankUp = false
		closeMenu()
	end
	if playdate.buttonJustPressed(playdate.kButtonA) then
		local target = menuItems[menuIdx]
		if target == "Creatures" then
			fadeOutTimer = 15
			fadeDest = 2
		end
	end
end

function openSingleMonsterView()
	curScreen = 2
	monsterSingleViewSelection = 1
end

function onEndFadeOut()
	if fadeDest == 0 then
		openMainScreen()
	elseif fadeDest == 1 then
		loadMap(nextMap, nextTransloc)
	elseif fadeDest == 2 then
		openMonsterScreen()
	elseif fadeDest == 3 then
		openSingleMonsterView()
	end
end

function moveVertInPartyView()
	if monsterScreenSelectionIdx == 1 then
		if #playerMonsters >= 3 then
			monsterScreenSelectionIdx = 3
		else
			monsterScreenSelectionIdx = 2
		end
	elseif monsterScreenSelectionIdx == 2 then
		if #playerMonsters >= 4 then
			monsterScreenSelectionIdx = 4
		else
			monsterScreenSelectionIdx = 3
		end
	elseif monsterScreenSelectionIdx == 3 then
		monsterScreenSelectionIdx = 1
	elseif monsterScreenSelectionIdx == 4 then
		monsterScreenSelectionIdx = 2
	end
end

function moveHorizInPartyView()
	if monsterScreenSelectionIdx == 1 then
		if #playerMonsters >= 2 then
			monsterScreenSelectionIdx = 2
		end
	elseif monsterScreenSelectionIdx == 2 then
		monsterScreenSelectionIdx = 1
	elseif monsterScreenSelectionIdx == 3 then
		if #playerMonsters >= 4 then
			monsterScreenSelectionIdx = 4
		else
			monsterScreenSelectionIdx = 2
		end
	elseif monsterScreenSelectionIdx == 4 then
		monsterScreenSelectionIdx = 3
	end
end

function updatePartyViewMenu()
	if playdate.buttonJustPressed(playdate.kButtonB) then
		fadeOutTimer = 15
		fadeDest = 0
	end
	if playdate.buttonJustPressed(playdate.kButtonUp) then
		moveVertInPartyView()
	elseif playdate.buttonJustPressed(playdate.kButtonRight) then
		moveHorizInPartyView()
	elseif playdate.buttonJustPressed(playdate.kButtonDown) then
		moveVertInPartyView()
	elseif playdate.buttonJustPressed(playdate.kButtonLeft) then
		moveHorizInPartyView()
	end
	if playdate.buttonJustPressed(playdate.kButtonA) then
		singleViewMonster = playerMonsters[monsterScreenSelectionIdx]
		fadeOutTimer = 15
		fadeDest = 3
	end
end

function playdate.update()
	if (fadeOutTimer > 0 or fadeInTimer > 0) then
		if fadeOutTimer > 0 then
			fadeOutTimer -= 1
			if fadeOutTimer == 0 then
				onEndFadeOut()
				transitionImg = gfx.image.new(400, 240)
				gfx.pushContext(transitionImg)
				render()
				gfx.popContext()
				fadeInTimer = 15
			end
		elseif fadeInTimer > 0 then
			fadeInTimer -= 1
		end

		renderFade()
	else
		if curScreen == 0 then
			if (textBoxShown) then
				updateTextBox()
			else
				for i, v in ipairs(objs) do
					v:update()
				end

				if (movingCam) then
					updateCameraOffset()
				elseif (menuTimer > 0) then
					updateMenuTimer()
				elseif (isMenuUp) then
					updateInMenu()
				else
					checkMovement()
				end
			end
		elseif curScreen == 1 then
			updatePartyViewMenu()
		elseif curScreen == 2 then
			updateSingleMonsterViewMenu()
		end

		render()
	end
end


function updateMenuTimer()
	menuTimer -= 1
	if (menuTimer == 0) then
		isMenuUp = showingMenu
	end
end

function drawMenu()
	local circRadius
	if menuTimer > 0 then
		if showingMenu then
			circRadius = menuCircRadius * playdate.math.lerp(0, 1, (10-menuTimer)/10)
		else
			circRadius = menuCircRadius * playdate.math.lerp(0, 1, menuTimer/10)
		end
	else
		circRadius = menuCircRadius
	end
	gfx.setDitherPattern(0.5, gfx.image.kDitherTypeBayer8x8)
	gfx.fillCircleAtPoint(400, 120, circRadius)

	for i=menuIdx-2, menuIdx+2 do
		if i > 0 and i <= #menuItems then
			local destinationIndex = i-1
			local destDegrees = destinationIndex * offsetPerMenuItem + baseMenuItemOffset + menuAngle
			local destRads = toRadians(destDegrees)
			local menuIconDestX = circRadius * math.cos(destRads) + 400
			local menuIconDestY = circRadius * math.sin(destRads) + 120
			menuIcons[menuItems[i]]:draw(menuIconDestX - 33, menuIconDestY - 33)
		end
	end
	gfx.setColor(gfx.kColorBlack)
end

local monsterMenuOuterBuffer <const> = 3
local backBtnWidth, backBtnHeight = globalBack:getSize()
local globalBackX <const> = 400 - backBtnWidth - 1
local globalBackY <const> = 240 - backBtnHeight - 1

function drawBackButton()
	globalBack:draw(globalBackX, globalBackY)
end

local monsterInfoBoxWidth <const> = 195
local monsterInfoBoxHeight <const> = 110

local healthBarWidth <const> = 50
local healthBarHeight <const> = 10
local healthBarSquish <const> = 4

local hpText <const> = gfx.imageWithText("HP:", 100, 50)
local hpTextWidth, hpTextHeight = hpText:getSize()

function drawHealthBar(x, y, health, max)
	hpText:draw(x, y)
	gfx.fillRoundRect(x + hpTextWidth + healthBarSquish, y + hpTextHeight/6, healthBarWidth, healthBarHeight, healthBarSquish)
	gfx.setColor(gfx.kColorWhite)
	gfx.fillRoundRect(x + (healthBarSquish/2) + hpTextWidth+ healthBarSquish, y + (healthBarSquish/2)+ hpTextHeight/6, (healthBarWidth * playdate.math.lerp(0, 1, health/max)) - healthBarSquish, healthBarHeight - healthBarSquish, healthBarSquish)
	gfx.setColor(gfx.kColorBlack)
	gfx.drawText(health .. "/" .. max, x + hpTextWidth + healthBarSquish, y + hpTextHeight)
end

function drawMonsterInfoBox(monster, x, y, selected)
	if selected then
		drawSelectedRect(x, y, monsterInfoBoxWidth, monsterInfoBoxHeight)
	else
		drawNiceRect(x, y, monsterInfoBoxWidth, monsterInfoBoxHeight)
	end
	if monster ~= nil then
		monster.img:draw(x+5, y+5)
		gfx.drawText(monster.name, x + 110, y + 5)
		gfx.drawText("LV. " .. monster.level, x + 125, y+25)
		drawHealthBar(x + 105, y + 50, monster.curHp, monster.maxHp)
	end

end

function drawMonsterMenu()
	local index = 1
	for y=0, 1 do
		for x=0, 1 do
			drawMonsterInfoBox(playerMonsters[index],  monsterMenuOuterBuffer  + (x * (monsterInfoBoxWidth +  monsterMenuOuterBuffer )),  monsterMenuOuterBuffer  + (y * (monsterInfoBoxHeight +  monsterMenuOuterBuffer )), monsterScreenSelectionIdx == index)
			index += 1
		end
	end

	drawBackButton()
end

local singleViewImgDrawX <const> = 10
local singleViewImgDrawY <const> = 10

local singleViewNameDrawX <const> = 125
local singleViewNameDrawY <const> = 10

local singleViewLevelDrawX <const> = 125
local singleViewLevelDrawY <const> = 30

local singleViewHealthDrawX <const> = 125
local singleViewHealthDrawY <const> = 50

local singleViewTypesDrawX <const> = 225
local singleViewTypesDrawY <const> = 30

local singleViewStatsDrawX <const> = 10
local singleViewStatsDrawY <const> = 125
local singleViewSpaceBetweenStatsVert <const> = 30

local singleViewNatureDrawX <const> = 230
local singleViewNatureDrawY <const> = 60

function drawSingleMonsterView()
	singleViewMonster.img:draw(singleViewImgDrawX, singleViewImgDrawY)
	local nameDisplay = singleViewMonster.name
	if singleViewMonster.hasNickname then
		nameDisplay = nameDisplay .. " (" .. singleViewMonster.speciesName .. ")"
	end
	gfx.drawText(nameDisplay, singleViewNameDrawX, singleViewNameDrawY)
	gfx.drawText("LV. " .. singleViewMonster.level, singleViewLevelDrawX, singleViewLevelDrawY)
	drawHealthBar(singleViewHealthDrawX, singleViewHealthDrawY, singleViewMonster.curHp, singleViewMonster.maxHp)
	renderTypesHoriz(singleViewMonster.types, singleViewTypesDrawX, singleViewTypesDrawY)

	gfx.drawText("ATK: " .. singleViewMonster.attack, singleViewStatsDrawX, singleViewStatsDrawY)
	gfx.drawText("DEF: " .. singleViewMonster.defense, singleViewStatsDrawX, singleViewStatsDrawY + (singleViewSpaceBetweenStatsVert))
	gfx.drawText("SPD: " .. singleViewMonster.speed, singleViewStatsDrawX, singleViewStatsDrawY + (singleViewSpaceBetweenStatsVert*2))

	gfx.drawText("Acts " .. string.lower(singleViewMonster.nature) .. ".", singleViewNatureDrawX, singleViewNatureDrawY)

	drawBackButton()
end

function updateSingleMonsterViewMenu()
	if playdate.buttonJustPressed(playdate.kButtonB) then
		fadeOutTimer = 15
		fadeDest = 2
	end
	if playdate.buttonJustPressed(playdate.kButtonLeft) then
		monsterScreenSelectionIdx -= 1
		if monsterScreenSelectionIdx < 1 then
			monsterScreenSelectionIdx = #playerMonsters
		end
		singleViewMonster = playerMonsters[monsterScreenSelectionIdx]
	elseif playdate.buttonJustPressed(playdate.kButtonRight) then
		monsterScreenSelectionIdx += 1
		if monsterScreenSelectionIdx > #playerMonsters then
			monsterScreenSelectionIdx = 1
		end
		singleViewMonster = playerMonsters[monsterScreenSelectionIdx]
	end
end

function render()
	gfx.clear()

	if curScreen == 0 then
		overworldTiles:draw(cameraOffsetX, cameraOffsetY)

		for i, v in ipairs(objs) do
			v:render()
		end

		playerImg:draw(playerRenderPosX, playerRenderPosY)

		if menuTimer > 0 or isMenuUp then
			drawMenu()
		end

		if textBoxShown then
			drawNiceRect(textBoxOuterBuffer, textBoxPosY, textBoxWidth, textBoxHeight)
			gfx.drawTextInRect(textBoxDisplayedText, textBoxOuterBuffer + textBoxTextBufferSize, textBoxPosY + textBoxTextBufferSize, textBoxWidth - (textBoxTextBufferSize*2), textBoxHeight - (textBoxTextBufferSize*2))
			
			if textBoxScrollDone then
				gfx.fillTriangle(400 - (textBoxOuterBuffer * 4), textBoxPosY + (textBoxOuterBuffer * 8), 400 - (textBoxOuterBuffer * 3), textBoxPosY + (textBoxOuterBuffer * 8), 400 - (textBoxOuterBuffer * 3.5), textBoxPosY + (textBoxOuterBuffer * 9))
			end
		end
	elseif curScreen == 1 then
		drawMonsterMenu()
	elseif curScreen == 2 then
		drawSingleMonsterView()
	end
end

function canMoveThere(x, y) 
	if x < 1 or y < 1 or x > mapWidth or y > mapHeight then
		return false
	end
	local result = overworldTiles:getTileAtPosition(x, y)
	if (contains(impassables, result)) then
		return false
	end
	for i, v in ipairs(objs) do
		if (v.posX == x and v.posY == y and not v:canMoveHere()) then
			return false
		end
	end
	return true
end

local cameraMoveSpeed <const> = 5

function openMenu()
	menuTimer = 10
	showingMenu = true
	resetMenu()
end

function checkMovement() 
	if (playdate.buttonIsPressed(playdate.kButtonUp)) then
		setPlayerFacing(0)
		if (canMoveThere(playerX, playerY-1)) then
			playerMoveBy(0, -1)
			return
		end
	end
	if (playdate.buttonIsPressed(playdate.kButtonDown)) then
		setPlayerFacing(2)
		if (canMoveThere(playerX, playerY+1)) then
			playerMoveBy(0, 1)
			return
		end
	end
	if (playdate.buttonIsPressed(playdate.kButtonLeft)) then
		setPlayerFacing(3)
		if (canMoveThere(playerX - 1, playerY)) then
			playerMoveBy(-1, 0)
			return
		end
	end
	if (playdate.buttonIsPressed(playdate.kButtonRight)) then
		setPlayerFacing(1)
		if (canMoveThere(playerX + 1, playerY)) then
			playerMoveBy(1, 0)
			return
		end
	end
	if (playdate.buttonJustPressed(playdate.kButtonA)) then
		local tarX, tarY = getPlayerPointCoord()
		for i, v in ipairs(objs) do
			if (v.posX == tarX and v.posY == tarY) then
				v:onInteract()
			end
		end
	end
	if not playdate.isCrankDocked() and not isCrankUp then
		isCrankUp = true
		openMenu()
	end
end

function closeMenu()
	menuTimer = 10
	showingMenu = false
end

function playerMoveBy(x, y)
	if (x ~= 0 or y ~= 0) then
		playerX += x
		playerY += y
		setupCameraOffset()
	end
end

function getPlayerPointCoord()
	if (playerFacing == 0) then
		return playerX, playerY-1
	elseif (playerFacing == 1) then
		return playerX+1, playerY
	elseif (playerFacing == 2) then
		return playerX, playerY+1
	elseif (playerFacing == 3) then
		return playerX-1, playerY
	end
	return playerX, playerY-1
end

function updateCameraOffset()
	if playerRenderPosX == playerDestRenderPosX and playerRenderPosY == playerDestRenderPosY then
		if (cameraOffsetX > cameraDestOffsetX) then
			cameraOffsetX -= cameraMoveSpeed
			if (cameraOffsetX < cameraDestOffsetX) then
				cameraOffsetX = cameraDestOffsetX
			end
		elseif (cameraOffsetX < cameraDestOffsetX) then
			cameraOffsetX += cameraMoveSpeed
			if (cameraOffsetX > cameraDestOffsetX) then
				cameraOffsetX = cameraDestOffsetX
			end
		end
		if (cameraOffsetY > cameraDestOffsetY) then
			cameraOffsetY -= cameraMoveSpeed
			if (cameraOffsetY < cameraDestOffsetY) then
				cameraOffsetY = cameraDestOffsetY
			end
		elseif (cameraOffsetY < cameraDestOffsetY) then
			cameraOffsetY += cameraMoveSpeed
			if (cameraOffsetY > cameraDestOffsetY) then
				cameraOffsetY = cameraDestOffsetY
			end
		end
		if (cameraOffsetX == cameraDestOffsetX and cameraOffsetY == cameraDestOffsetY) then
			movingCam = false
			allowImmediateMovementCheck = true
			for k, v in ipairs(objs) do
				if v.posX == playerX and v.posY == playerY then
					v:onOverlap()
					if not v:allowImmediateMovementAfterStep() then
						allowImmediateMovementCheck = false
					end
				end
			end
			if allowImmediateMovementCheck then
				checkMovement()
			end
		end
	end

	if playerRenderPosX ~= playerDestRenderPosX or playerRenderPosY ~= playerDestRenderPosY then
		if (playerRenderPosX > playerDestRenderPosX) then
			playerRenderPosX -= cameraMoveSpeed
			if (playerRenderPosX < playerDestRenderPosX) then
				playerRenderPosX = playerDestRenderPosX
			end
		elseif playerRenderPosX < playerDestRenderPosX then
			playerRenderPosX += cameraMoveSpeed
			if (playerRenderPosX > playerDestRenderPosX) then
				playerRenderPosX = playerDestRenderPosX
			end
		end
		if (playerRenderPosY > playerDestRenderPosY) then
			playerRenderPosY -= cameraMoveSpeed
			if (playerRenderPosY < playerDestRenderPosY) then
				playerRenderPosY = playerDestRenderPosY
			end
		elseif playerRenderPosY < playerDestRenderPosY then
			playerRenderPosY += cameraMoveSpeed
			if (playerRenderPosY > playerDestRenderPosY) then
				playerRenderPosY = playerDestRenderPosY
			end
		end
		if (playerRenderPosX == playerDestRenderPosX and playerRenderPosY == playerDestRenderPosY) then
			movingCam = false
			allowImmediateMovementCheck = true
			for k, v in ipairs(objs) do
				if v.posX == playerX and v.posY == playerY then
					v:onOverlap()
					if not v:allowImmediateMovementAfterStep() then
						allowImmediateMovementCheck = false
					end
				end
			end
			if allowImmediateMovementCheck then
				checkMovement()
			end
		end
	end
end

local fadeCircEndpoint = math.sqrt(400^2 + 240^2)/2

function renderFade()
	if fadeOutTimer > 0 then
		gfx.fillCircleAtPoint(200, 120, playdate.math.lerp(0, 1, ((15-fadeOutTimer)/14)) * fadeCircEndpoint)
	elseif fadeInTimer > 0 then
		gfx.clear()
		transitionImg:draw(0, 0)
		gfx.fillCircleAtPoint(200, 120, playdate.math.lerp(1, 0, ((15-fadeInTimer)/14)) * fadeCircEndpoint)
	end
end

initialize()