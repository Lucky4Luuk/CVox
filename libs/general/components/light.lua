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
  return t
end

function light:setPosition(v)
  self.pos = v
end

light.__call = function(...) return light:create(...) end
return light
