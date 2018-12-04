--Made by Luuk van Oijen
--Started on 20-08-2018
--Uses LML, my personal math library
--Last updated: 08-09-2018

function texSizeSortX(a,b)
  return a.size.x < b.size.x
end

function texSizeSortY(a,b)
  return a.size.y < b.size.y
end

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
  renderer.depth_shader = love.graphics.newShader("raymarching_depth.glsl") --TODO: See line above
  renderer.cam_pos = vec3(0,0,0)
  renderer.cam_look = vec3(0,0,1)
  renderer.cam_roll = 0
  renderer.target_mesh = love.graphics.newMesh({
    {0,0, 0,0, 1,1,1,1},
    {1,0, 1,0, 1,1,1,1},
    {1,1, 1,1, 1,1,1,1},
    {0,1, 0,1, 1,1,1,1}
  }, "strip", "static")
  renderer.canvas = love.graphics.newCanvas(1,1)
  renderer.depth_canvas = love.graphics.newCanvas(1,1)
  --renderer.checker_shader = love.graphics.newShader("checker.glsl")
  return renderer
end

function r:setPosition(v)
  self.cam_pos = v
end

function r:setLookDir(v)
  self.cam_look = v
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
  send(self.depth_shader, "res", {w, h})
  self.canvas = love.graphics.newCanvas(w, h)
  self.depth_canvas = love.graphics.newCanvas(w, h)
end

local function sendMaterial(s, i)
  local pre = "material."
  local mat = _G["material_list"][i]
  send(s, pre.."color", mat.color:table())
  send(s, pre.."roughness", mat.roughness)
  send(s, pre.."metallic", mat.metallic)
  if mat.use_tex and mat.tex then
    send(s, "mat_tex", mat.tex)
    send(s, pre.."use_tex", 1)
  end
end

local function renderObjects(s, d, target_mesh, depth_map, src_map)
  love.graphics.setCanvas(depth_map)
  love.graphics.clear()
  love.graphics.setCanvas(src_map)
  love.graphics.clear()
  love.graphics.setCanvas()
  for i=1, #_G["dir_light_queu"] do
    local pre = "dir_lights["..tostring(i-1).."]."
    local light = _G["dir_light_queu"][i].components["Light"]
    send(s, pre.."col", light.color:table())
    send(s, pre.."dir", light.dir:table())
  end
  send(s, "dir_light_length", #_G["dir_light_queu"])

  if _G["HEIGHT_MAP"][1] then
    send(d, "hmap", _G["HEIGHT_MAP"][2])
    send(d, "hmap_res", _G["HEIGHT_MAP"][3])
    send(s, "hmap", _G["HEIGHT_MAP"][2])
    send(s, "hmap_res", _G["HEIGHT_MAP"][3])
  end

  for i=1, #_G["render_queu"] do
    local pre = "object."
    local obj = _G["render_queu"][i]
    if obj.components["Material"] then
      sendMaterial(s, obj.components["Material"].id)
    end
    send(d, pre.."type", obj.components["SDF Render"].sdf.type_num)
    send(d, pre.."pos", obj.components["Transform"].pos:table())
    send(d, pre.."size", {1,1,1})
    send(s, pre.."type", obj.components["SDF Render"].sdf.type_num)
    send(s, pre.."pos", obj.components["Transform"].pos:table())
    send(s, pre.."size", {1,1,1})

    love.graphics.setColor(1,1,1,1)
    love.graphics.setCanvas(src_map)
    love.graphics.setShader(s)
    send(s, "depth_map", depth_map)
    send(s, "src_map", src_map)
    love.graphics.draw(target_mesh,0,0)
    love.graphics.setShader(d)
    love.graphics.setCanvas(depth_map)
    send(d, "depth_map", depth_map)
    love.graphics.draw(target_mesh,0,0)
    love.graphics.setCanvas()
  end
  love.graphics.setShader()
  love.graphics.draw(src_map)
end

function r:draw(x,y,w,h)
  --love.graphics.push()
  --love.graphics.setCanvas(self.canvas)
 --love.graphics.setShader(self.shader)
  send(self.shader, "cam.pos", self.cam_pos:table())
  send(self.shader, "cam.dir", self.cam_look:table())
  send(self.shader, "cam.roll", self.cam_roll)
  send(self.depth_shader, "cam.pos", self.cam_pos:table())
  send(self.depth_shader, "cam.dir", self.cam_look:table())
  send(self.depth_shader, "cam.roll", self.cam_roll)
  renderObjects(self.shader, self.depth_shader, self.target_mesh, self.depth_canvas, self.canvas)
  --love.graphics.setShader() --TODO: Maybe completely unnecessary due to push/pop
  --love.graphics.setCanvas()
  --love.graphics.setShader(self.checker_shader)
  --love.graphics.draw(self.canvas, x,y)
  --love.graphics.setShader() --TODO: Maybe completely unnecessary due to push/pop
  --love.graphics.pop()
  --love.graphics.draw(self.depth_canvas)
  _G["render_queu"] = {}
  _G["dir_light_queu"] = {}
end

r.__call = function(...) return r:create(...) end
return r
