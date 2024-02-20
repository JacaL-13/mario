--[[
    GD50
    -- Super Mario Bros. Remake --

    Author: Colton Ogden
    cogden@cs50.harvard.edu
]] GameObject = Class {}

function GameObject:init(def)
    self.id = def.id or '0'
    self.x = def.x
    self.y = def.y
    self.texture = def.texture
    self.width = def.width
    self.height = def.height
    self.frame = def.frame
    self.solid = def.solid
    self.collidable = def.collidable
    self.consumable = def.consumable
    self.onCollide = def.onCollide
    self.onConsume = def.onConsume
    self.hit = def.hit

    if self.id == 'flag' then
        Timer.every(1, function()
            if self.frame ~= 28 then
				local animFrame = self.frame % 3

				if animFrame == 1 then
					self.frame = self.frame + 1
				else
					self.frame = self.frame - 1
				end
            end
        end)
    end
end

function GameObject:collides(target)
    return
        not (target.x + HITBOX_X_OFFSET > self.x + self.width or self.x > target.x + target.width - HITBOX_X_OFFSET or
            target.y > self.y + self.height or self.y > target.y + target.height)
end

function GameObject:update(dt)

end

function GameObject:render()
    love.graphics.draw(gTextures[self.texture], gFrames[self.texture][self.frame], self.x, self.y)
end
