require "libs.lml"

_G["render_queu"] = {} --A global render queu, accessible from everywhere
_G["dir_light_queu"] = {} --Directional light queu
_G["point_light_queu"] = {} --Point light queu
_G["material_list"] = {} --List of materials
_G["material_queu"] = {} --New materials get added to this queu, so the shader can recieve them

local scene = require("libs.general.scene"):create()

local cam = require("libs.general.object"):create()
cam:addComponent("libs.graphics.components.camera")

--Create object
local plane = require("libs.general.object"):create("Plane 1")
plane:addComponent("libs.general.components.transform")
plane.components["Transform"]:setPosition(vec3(0, -1, 0))
--Add SDF
plane:addComponent("libs.graphics.components.SDF")
plane.components["SDF"]:setType("sdPlane")
--Add Material
plane:addComponent("libs.graphics.components.material")
plane.components["Material"].metallic = 1
plane.components["Material"].roughness = 0
plane.components["SDF"].material = plane.components["Material"]
--Add SDF Render
plane:addComponent("libs.graphics.components.SDF_render")
plane.components["SDF Render"].sdf = plane.components["SDF"]
--Add to scene
scene:addObject(plane)

--Create object
local sphere = require("libs.general.object"):create("Sphere 1")
sphere:addComponent("libs.general.components.transform")
sphere.components["Transform"]:setPosition(vec3(-1, 1, 3))
--Add SDF
sphere:addComponent("libs.graphics.components.SDF")
sphere.components["SDF"]:setType("sdSphere")
--Add Material
sphere:addComponent("libs.graphics.components.material")
sphere.components["Material"].color = vec3(1,0,0)
sphere.components["SDF"].material = plane.components["Material"]
--Add SDF Render
sphere:addComponent("libs.graphics.components.SDF_render")
sphere.components["SDF Render"].sdf = sphere.components["SDF"]
--Add to scene
scene:addObject(sphere)

local light = require("libs.general.object"):create("Directional Light 1")
light:addComponent("libs.general.components.light")
light.components["Light"]:setType("directional")
light.components["Light"]:setDirection(vec3(0.5, 1, -0.5))
scene:addObject(light)

function love.draw()
  scene:draw()
  cam.components["Camera"]:render()
  love.graphics.print("MS: "..tostring(math.floor(love.timer.getDelta() * 100000)/100), 0,0)
  love.graphics.print("FPS: "..tostring(love.timer.getFPS()), 0,12)
end
