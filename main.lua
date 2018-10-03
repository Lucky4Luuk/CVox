require "libs.lml"

_G["DRAW_DEBUG"] = {
  FPS = true,
  SCENE_DEBUG = true
}

_G["render_queu"] = {} --A global render queu, accessible from everywhere
_G["dir_light_queu"] = {} --Directional light queu
_G["point_light_queu"] = {} --Point light queu
_G["material_list"] = {} --List of materials
_G["material_queu"] = {} --New materials get added to this queu, so the shader can recieve them
_G["HEIGHT_MAP"] = {false}

local scene = require("libs.general.scene"):create()

local cam = require("libs.general.object"):create()
cam:addComponent("libs.graphics.components.camera")
cam.components["Camera"]:setPosition(vec3(0,64,-1))
cam.components["Camera"]:setLookDir(vec3(0,-0,2):normalize())

--Create object
local plane = require("libs.general.object"):create("Plane 1")
plane:addComponent("libs.general.components.transform")
plane.components["Transform"]:setPosition(vec3(0, 0, 0))
--Add SDF
plane:addComponent("libs.graphics.components.SDF")
plane.components["SDF"]:setType("sdTerrain") --Uses the global heightmap. TODO: Make it per terrain lol, this is garbage (but not rn, texture atlases are boring)
_G["HEIGHT_MAP"] = {true, love.graphics.newImage("heightmap.png"), {1081, 1081, 32}}
--Add Material
plane:addComponent("libs.graphics.components.material")
plane.components["Material"].metallic = 0
plane.components["Material"].roughness = 0.5
plane.components["Material"].color = vec3(0.5,0.5,0.5)
plane.components["SDF"].material = plane.components["Material"]
--Add SDF Render
plane:addComponent("libs.graphics.components.SDF_render")
plane.components["SDF Render"].sdf = plane.components["SDF"]
--Add to scene
scene:addObject(plane)

--Create bunch of spheres
--[[
for x=0, 5 do
  for y=0, 5 do
    local sphere = require("libs.general.object"):create("Sphere "..tostring(x).."; "..tostring(y))
    sphere:addComponent("libs.general.components.transform")
    sphere.components["Transform"]:setPosition(vec3((x - 2.5) * 1.5, 0.5, y * 1.5 + 3))
    --Add SDF
    sphere:addComponent("libs.graphics.components.SDF")
    sphere.components["SDF"]:setType("sdSphere")
    --Add Material
    sphere:addComponent("libs.graphics.components.material")
    sphere.components["Material"].color = vec3(1, 0, 0)
    sphere.components["Material"].metallic = x / 6
    sphere.components["Material"].roughness = y / 6
    sphere.components["SDF"].material = plane.components["Material"]
    --Add SDF Render
    sphere:addComponent("libs.graphics.components.SDF_render")
    sphere.components["SDF Render"].sdf = sphere.components["SDF"]
    --Add to scene
    scene:addObject(sphere)
  end
end
]]--

local light = require("libs.general.object"):create("Directional Light 1")
light:addComponent("libs.general.components.light")
light.components["Light"]:setType("directional")
light.components["Light"]:setDirection(vec3(0.5, 1, -1))
scene:addObject(light)

function love.draw()
  scene:draw()
  cam.components["Camera"]:render()
  love.graphics.setColor(0,0,0,1)
  local dy = 0 --Debug print y
  if _G["DRAW_DEBUG"].FPS then
    love.graphics.print("MS: "..tostring(math.floor(love.timer.getDelta() * 100000)/100), 0,dy)
    dy = dy + 12
    love.graphics.print("FPS: "..tostring(love.timer.getFPS()), 0,dy)
    dy = dy + 12
  end
  if _G["DRAW_DEBUG"].SCENE_DEBUG then
    love.graphics.print("Objects: "..tostring(scene:getObjectCount()), 0,dy)
    dy = dy + 12
  end
end
