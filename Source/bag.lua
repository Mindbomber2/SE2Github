local BAG_SCREEN_EDGE_BUFFER <const> = 5
local BAG_SCREEN_WIDTH <const> = 400 - BAG_SCREEN_EDGE_BUFFER*2
local BAG_SCREEN_TAB_HEIGHT <const> = 30
local BAG_SCREEN_SELECTED_TAB_OFFSET <const> = 10
local BAG_VIEW_TAB_ICON_HEIGHT <const> = 10

normalItemTabImg = gfx.image.new("img/ui/bag/itemTabNormal")
keyItemTabImg = gfx.image.new("img/ui/bag/itemTabKey")

bagMenuChosenTab = 1
bagMenuIdx = 1

function openBag()
	curScreen = 4
	bagMenuIdx = 1
end

function drawBagViewScreen()
	drawNiceRect(BAG_SCREEN_EDGE_BUFFER, BAG_SCREEN_EDGE_BUFFER, BAG_SCREEN_WIDTH, fromBot(BAG_SCREEN_EDGE_BUFFER))

	if bagMenuChosenTab == 1 then
		drawNiceRect(BAG_SCREEN_EDGE_BUFFER, BAG_SCREEN_EDGE_BUFFER, BAG_SCREEN_WIDTH / 2, BAG_SCREEN_TAB_HEIGHT + BAG_SCREEN_SELECTED_TAB_OFFSET)
		normalItemTabImg:draw(BAG_SCREEN_EDGE_BUFFER + BAG_SCREEN_WIDTH / 4 - 30, BAG_VIEW_TAB_ICON_HEIGHT + (BAG_SCREEN_SELECTED_TAB_OFFSET / 2))
		gfx.setDitherPattern(0.5, gfx.image.kDitherTypeBayer8x8)
		gfx.fillRoundRect(BAG_SCREEN_EDGE_BUFFER + 1, BAG_SCREEN_EDGE_BUFFER + 1, BAG_SCREEN_WIDTH/2 - BOX_OUTLINE_SIZE, BAG_SCREEN_TAB_HEIGHT + BAG_SCREEN_SELECTED_TAB_OFFSET - BOX_OUTLINE_SIZE, BOX_OUTLINE_SIZE)
		gfx.setColor(gfx.kColorBlack)
	else
		drawNiceRect(BAG_SCREEN_EDGE_BUFFER, BAG_SCREEN_EDGE_BUFFER, BAG_SCREEN_WIDTH / 2, BAG_SCREEN_TAB_HEIGHT)
		normalItemTabImg:draw(BAG_SCREEN_EDGE_BUFFER + BAG_SCREEN_WIDTH / 4 - 30, BAG_VIEW_TAB_ICON_HEIGHT)
	end

	if bagMenuChosenTab == 2 then
		drawNiceRect(BAG_SCREEN_EDGE_BUFFER + (BAG_SCREEN_WIDTH/2), BAG_SCREEN_EDGE_BUFFER, BAG_SCREEN_WIDTH / 2, BAG_SCREEN_TAB_HEIGHT + BAG_SCREEN_SELECTED_TAB_OFFSET)
		keyItemTabImg:draw(BAG_SCREEN_EDGE_BUFFER + BAG_SCREEN_WIDTH / 4 - 30 + (BAG_SCREEN_WIDTH/2), BAG_VIEW_TAB_ICON_HEIGHT + (BAG_SCREEN_SELECTED_TAB_OFFSET / 2))
		gfx.setDitherPattern(0.5, gfx.image.kDitherTypeBayer8x8)
		gfx.fillRoundRect(BAG_SCREEN_EDGE_BUFFER + 1 + (BAG_SCREEN_WIDTH/2), BAG_SCREEN_EDGE_BUFFER + 1, BAG_SCREEN_WIDTH/2 - BOX_OUTLINE_SIZE, BAG_SCREEN_TAB_HEIGHT + BAG_SCREEN_SELECTED_TAB_OFFSET - BOX_OUTLINE_SIZE, BOX_OUTLINE_SIZE)
		gfx.setColor(gfx.kColorBlack)
	else
		drawNiceRect(BAG_SCREEN_EDGE_BUFFER+ (BAG_SCREEN_WIDTH/2), BAG_SCREEN_EDGE_BUFFER, BAG_SCREEN_WIDTH / 2, BAG_SCREEN_TAB_HEIGHT)
		keyItemTabImg:draw(BAG_SCREEN_EDGE_BUFFER + BAG_SCREEN_WIDTH / 4 - 30+ (BAG_SCREEN_WIDTH/2), BAG_VIEW_TAB_ICON_HEIGHT)
	end
end

function switchBagTab()
	if bagMenuChosenTab == 1 then
		bagMenuChosenTab = 2
	else
		bagMenuChosenTab = 1
	end
	bagMenuIdx = 1
end

function updateBagViewScreen()
	if playdate.buttonJustPressed(playdate.kButtonLeft) or playdate.buttonJustPressed(playdate.kButtonRight) then
		switchBagTab()
	end
	if playdate.buttonJustPressed(playdate.kButtonB ) then
		fadeOutTimer = 15
		fadeDest = 0
	end
end