--Made by Luuk van Oijen
--Started on 20-08-2018
--Uses LML, my personal math library
--Last update: 27-08-2018

local object = {_TYPE="Object", _NAME="Object"}
object.__index = object

function object:create(name)
  local obj = {}
  setmetatable(obj, object)
  obj.components = {}
  obj._NAME = name
  return obj
end

function object:addComponent(name)
  local c = require(name):create()
  if c._TYPE then
    if c._TYPE ~= "Component" then
      return --Not a component
    end
    self.components[c._NAME] = c
  end
  return --Can't index _TYPE
end

function object:draw()
  if self.components["SDF Render"] then
    table.insert(_G["render_queu"], self)
  end
end

object.__call = function(...) return object:create(...) end
return object
