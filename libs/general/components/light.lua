--Made by Luuk van Oijen
--Started on 27-08-2018
--Uses LML, my personal math library
--Last update: 27-08-2018

local light = {_TYPE="Component", _SUBTYPE="Light", _NAME="Light"}
light.__index = light

function light:create()
  local t = {}
  setmetatable(t, light)
  t.type = "directional"
  t.intensity = 1
  t.color = vec3(1,1,1)
  t.pos = vec3(0,0,0)
  t.dir = vec3(0,0,0)
  return t
end

function light:setType(p)
  self.type = p
end

function light:setPosition(v)
  self.pos = v
end

function light:setDirection(v)
  self.dir = v
end

light.__call = function(...) return light:create(...) end
return light
