--Made by Luuk van Oijen
--Started on 27-08-2018
--Uses LML, my personal math library
--Last update: 27-08-2018

local transform = {_TYPE="Component", _SUBTYPE="Transform", _NAME="Transform"}
transform.__index = transform

function transform:create()
  local t = {}
  setmetatable(t, transform)
  t.pos = vec3(0,0,0)
  t.rot = vec3(0,0,0)
  t.scale = vec3(0,0,0)
  return t
end

function transform:setPosition(v)
  self.pos = v
end

transform.__call = function(...) return transform:create(...) end
return transform
