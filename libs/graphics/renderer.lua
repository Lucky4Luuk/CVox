--Made by Luuk van Oijen
--Started on 20-08-2018
--Uses LML, my personal math library
--Last updated: 08-09-2018

function send(shader, name, value)
  if shader:hasUniform(name) then
    shader:send(name, value)
  else
    --print(name, value)
  end
end

local r = {_TYPE="Renderer", _NAME="Renderer"}
r.__index = r

function r:create()
  local renderer = {}
  setmetatable(renderer, r)
  renderer.shader = love.graphics.newShader("raymarching.glsl") --TODO: Change this to nil, then use a function to set the shader, so this can also be used for post processing
  renderer.cam_pos = vec3(0,0,0)
  renderer.cam_look = vec3(0,0,1)
  renderer.cam_roll = 0
  renderer.target_mesh = love.graphics.newMesh({
    {0,0, 0,0, 1,1,1,1},
    {1,0, 1,0, 1,1,1,1},
    {1,1, 1,1, 1,1,1,1},
    {0,1, 0,1, 1,1,1,1}
  }, "strip", "static")
  return renderer
end

function r:setPosition(v)
  self.cam_pos = v
end

function r:setLookDir(v)
  self.cam_dir = v
end

function r:setRoll(f)
  self.cam_roll = f
end

function r:setDrawTarget(x,y,w,h)
  self.target_mesh = love.graphics.newMesh({
    {x  ,y  , 0,0, 1,1,1,1},
    {x+w,y  , 1,0, 1,1,1,1},
    {x+w,y+h, 1,1, 1,1,1,1},
    {x  ,y+h, 0,1, 1,1,1,1}
  }, "fan", "static")
  send(self.shader, "res", {w, h})
end

local function sendRenderQueu(s)
  for i=1, #_G["render_queu"] do
    local pre = "objects["..tostring(i-1).."]."
    local obj = _G["render_queu"][i]
    if obj.components["Material"] then
      send(s, pre.."mat_id", obj.components["Material"].id-1)
    end
    send(s, pre.."type", obj.components["SDF Render"].sdf.type_num)
    send(s, pre.."pos", obj.components["Transform"].pos:table())
    send(s, pre.."size", {1,1,1})
  end
  send(s, "obj_length", #_G["render_queu"])
  for i=1, #_G["material_list"] do
    local pre = "materials["..tostring(i-1).."]."
    local mat = _G["material_list"][i]
    send(s, pre.."color", mat.color:table())
    send(s, pre.."roughness", mat.roughness)
    send(s, pre.."metallic", mat.metallic)
  end
  for i=1, #_G["dir_light_queu"] do
    local pre = "dir_lights["..tostring(i-1).."]."
    local light = _G["dir_light_queu"][i].components["Light"]
    send(s, pre.."col", light.color:table())
    send(s, pre.."dir", light.dir:table())
  end
  send(s, "dir_light_length", #_G["dir_light_queu"])
end

function r:draw(x,y,w,h)
  love.graphics.push()
  love.graphics.setShader(self.shader)
  sendRenderQueu(self.shader)
  send(self.shader, "cam.pos", self.cam_pos:table())
  send(self.shader, "cam.dir", self.cam_look:table())
  send(self.shader, "cam.roll", self.cam_roll)
  love.graphics.setColor(1,1,1,1)
  love.graphics.draw(self.target_mesh,0,0)
  love.graphics.setShader() --TODO: Maybe completely unnecessary due to push/pop
  love.graphics.pop()
  _G["render_queu"] = {}
  _G["dir_light_queu"] = {}
end

r.__call = function(...) return r:create(...) end
return r
