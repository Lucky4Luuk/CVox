--Made by Luuk van Oijen
--Started on 29-08-2018
--Uses LML, my personal math library
--Last update: 29-08-2018

local scene = {_TYPE="Scene", _NAME="Scene"}
scene.__index = scene

function scene:create()
  local sce = {}
  setmetatable(sce, scene)
  sce.objects = {}
  sce.objectCount = 0
  return sce
end

function scene:addObject(c)
  if c._TYPE then
    if c._TYPE ~= "Object" then
      return --Not a component
    end
    self.objects[c._NAME] = c
    self.objectCount = self.objectCount + 1
  end
  return --Can't index _TYPE
end

function scene:draw()
  for key,value in pairs(self.objects) do
    value:draw()
  end
end

function scene:getObjectCount()
  return self.objectCount
end

scene.__call = function(...) return scene:create(...) end
return scene
