class('NPC').extends()

objectImgs = {}

function NPC:loadImg(imgName)
	if (containsKey(objectImgs, imgName)) then
		self.img = objectImgs[imgName]
	else
		objectImgs[imgName] = gfx.image.new("img/overworld/npc/" .. imgName)
		self.img = objectImgs[imgName]
	end
end

function NPC:init(name, x, y)
	self.name = name
	self.posX = x
	self.startX = x
	self.posY = y
	self.startY = y
	self.visDestX = (self.posX-1) * 40
	self.visDestY = (self.posY-1) * 40
	self.visX = self.visDestX
	self.visY = self.visDestY
	self.speed = 4
end

function NPC:updateVisualMotion()
	if self.visX ~= self.visDestX then
		if self.visX < self.visDestX then
			self.visX += self.speed
		elseif self.visX > self.visDestX then
			self.visX -= self.speed
		end
	end
	if self.visY ~= self.visDestY then
		if self.visY < self.visDestY then
			self.visY += self.speed
		elseif self.visY > self.visDestY then
			self.visY -= self.speed
		end
	end
end

function NPC:moveBy(x, y)
	if (x ~= 0 or y ~= 0) then
		self.posX += x
		self.posX += y
		self.visDestX = (self.posX-1) * 40
		self.visDestY = (self.posY-1) * 40
	end
end

function NPC:update()
	self:updateVisualMotion()
end

function NPC:render()
	if self.img ~= nil then
		if (cameraOffsetGridX <= self.posX+1 and cameraOffsetGridX + camWidth >= self.posX-1 and cameraOffsetGridY <= self.posY+1 and cameraOffsetGridY + camHeight >= self.posY-1) then
			self.img:draw(self.visX + cameraOffsetX, self.visY + cameraOffsetY)
		end
	end
end

function NPC:canMoveHere()
	return false
end

function NPC:onInteract()

end

function NPC:onOverlap()

end

function NPC:allowImmediateMovementAfterStep()
	return true
end

-- IMPORTS
import "npcs/signpost"
import "npcs/person"
import "npcs/door"



function loadNpc(info)
	local npcType = info[1]
	if npcType == "signpost" then
		table.insert(objs, Signpost(info[2], info[3], info[4]))
	elseif npcType == "person" then
		table.insert(objs, Person(info[2], info[3], info[4], info[5]))
	elseif npcType == "door" then
		table.insert(objs, Door(info[2], info[3], info[4], info[5]))
	end
end