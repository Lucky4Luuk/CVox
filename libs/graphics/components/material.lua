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
  t.roughness = 0.5
  t.metallic = 0
  t.use_tex = false
  table.insert(_G["material_list"], t) --Add to this queu, so the renderer knows it exists
  t.id = #_G["material_list"]
  --table.insert(_G["material_queu"], t) --Add to this queu, so the renderer can update the shader
  return t
end

function mat:loadTexture(i)
  self.use_tex = true
  local tex = love.graphics.newImage(i)
  local size = {x=tex:getWidth(), y=tex:getHeight()}
  table.insert(_G["texture_list"], {image=tex, size=size, mat_id=self.id})
end

mat.__call = function(...) return mat:create(...) end
return mat
