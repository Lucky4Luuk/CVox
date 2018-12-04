uniform vec2 res;

vec4 effect(vec4 color, sampler2D tex, vec2 uv, vec2 screen_coords)
{
  if (mod(screen_coords.x + mod(screen_coords.y, 2.0), 2.0) == 0.0)
    return (Texel(tex, uv - vec2(1.0/res.x, 0.0)) + Texel(tex, uv + vec2(1.0/res.x, 0.0)) + Texel(tex, uv - vec2(0.0, 1.0/res.y)) + Texel(tex, uv + vec2(0.0, 1.0/res.y))) / 4;
  return Texel(tex, uv);
}
