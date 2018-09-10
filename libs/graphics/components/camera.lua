--Made by Luuk van Oijen
--Started on 20-08-2018
--Uses LML, my personal math library
--Last update: 20-08-2018

local cam = {_TYPE="Component", _SUBTYPE="Camera", _NAME="Camera"}
cam.__index = cam

function cam:create()
  local c = {}
  setmetatable(c, cam)
  c.pos = vec3(0,0,0)
  c.look = vec3(0,0,1)
  c.roll = 0
  c.renderer = require("libs.graphics.renderer"):create()
  c.renderer:setPosition(c.pos)
  c.renderer:setLookDir(c.look)
  c.renderer:setRoll(c.roll)
  c.renderer:setDrawTarget(0,0, love.graphics.getWidth(), love.graphics.getHeight())
  return c
end

function cam:setPosition(v) --v means vector
  self.pos = v
  self.renderer:setPosition(self.pos)
end

function cam:setLookDir(v) --v means vector
  self.look = v
  self.renderer:setLookDir(cam.look)
end

function cam:setRoll(f) --f means float
  self.roll = f
  self.renderer:setRoll(cam.roll)
end

function cam:render()
  self.renderer:draw()
end

cam.__call = function(...) return cam:create(...) end
return cam
