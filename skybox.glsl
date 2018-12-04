struct Camera {
  vec3 pos;
  vec3 dir;
  float roll;
};

uniform Camera cam;

vec4 effect(vec4 color, sampler2D tex, vec2 uv, vec2 screen_coords)
{
  
}
