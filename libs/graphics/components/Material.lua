--Made by Luuk van Oijen
--Started on 07-09-2018
--Uses LML, my personal math library
--Last update: 07-09-2018

--TODO: Figure out if we need to use a queu for updating materials, because constantly
--      sending all materials to the shader might use up a lot of bandwidth

local mat = {_TYPE="Component", _SUBTYPE="Material", _NAME="Material"}
mat.__index = mat

function mat:create()
  local t = {}
  setmetatable(t, mat)
  t.color = vec3(1,1,1)
  t.opacity = 1
  table.insert(_G["material_list"], t) --Add to this queu, so the renderer knows it exists
  t.id = #_G["material_list"]
  --table.insert(_G["material_queu"], t) --Add to this queu, so the renderer can update the shader
  return t
end

function mat:setColor(v) --TODO: Check type
  self.color = v
  --table.insert(_G["material_queu"], t)
end

mat.__call = function(...) return mat:create(...) end
return mat
