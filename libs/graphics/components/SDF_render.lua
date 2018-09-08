--Made by Luuk van Oijen
--Started on 27-08-2018
--Uses LML, my personal math library
--Last update: 27-08-2018

local sdf_render = {_TYPE="Component", _SUBTYPE="SDF Render", _NAME="SDF Render"}
sdf_render.__index = sdf_render

function sdf_render:create()
  local t = {}
  setmetatable(t, sdf_render)
  t.sdf = nil
  t.material = nil
  return t
end

function sdf_render:setSDF(p)
  if p._TYPE and p._TYPE == "Component" and p._SUBTYPE == "SDF" then
    self.sdf = p
  end
end

function sdf_render:setMaterial(p)
  if p._TYPE and p._TYPE == "Component" and p._SUBTYPE == "Material" then
    self.material = p
  end
end

sdf_render.__call = function(...) return sdf_render:create(...) end
return sdf_render
