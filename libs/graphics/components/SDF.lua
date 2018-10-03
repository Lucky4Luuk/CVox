--Made by Luuk van Oijen
--Started on 27-08-2018
--Uses LML, my personal math library
--Last update: 27-08-2018

local SDF_type_lookup = {}
SDF_type_lookup["sdPlane"] = 0
SDF_type_lookup["sdSphere"] = 1
SDF_type_lookup["sdTerrain"] = 2

local sdf = {_TYPE="Component", _SUBTYPE="SDF", _NAME="SDF"}
sdf.__index = sdf

function sdf:create()
  local t = {}
  setmetatable(t, sdf)
  t.type = "sdSphere"
  t.type_num = SDF_type_lookup["sdSphere"]
  return t
end

function sdf:setType(t)
  if SDF_type_lookup[t] then
    self.type = t
    self.type_num = SDF_type_lookup[t]
  end
end

sdf.__call = function(...) return sdf:create(...) end
return sdf
