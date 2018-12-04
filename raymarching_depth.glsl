#define PI 3.14159265359
#define saturate(x) clamp(x, 0.0, 1.0)

struct Object {
  int type; //Type of object
  vec3 pos; //Position of object
  vec3 size; //Only uses x in case of sphere
};

struct Camera {
  vec3 pos;
  vec3 dir;
  float roll;
};

struct MAP_RES {
  float dist;
  int id;
};

struct RAY_RES {
  Object obj;
  float dist;
};

uniform Object object;

uniform sampler2D hmap;
uniform vec3 hmap_res; //Z is scale

uniform Camera cam;
uniform vec2 res;

uniform sampler2D depth_map;

float rand(vec2 co)
{
  return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

vec2 vmod(vec2 a, vec2 b)
{
  //x - y * floor(x/y)
  return vec2(
    a.x - b.x * floor(a.x / b.x),
    a.y - b.y * floor(a.y / b.y)
    );
}

float getHMapHeight(vec2 p)
{
  vec2 uv = vmod(((p + hmap_res.xy / vec2(2.0)) / hmap_res.xy), vec2(1.0));
  //if (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0)
  //  return 0.0;
  return Texel(hmap, uv).r * hmap_res.z;
}

float sdPlane(vec3 p)
{
  return p.y;
}

float sdTerrain(vec3 p)
{
  //return p.y - getHMapHeight(p.xz);
  vec3 tpos = vec3(p.x, getHMapHeight(p.xz), p.z);
  return distance(tpos, p);
}

float sdBox(vec3 p, vec3 b)
{
  vec3 d = abs(p) - b;
  return min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
}

float sdSphere(vec3 p, float s)
{
  return length(p)-s;
}

float sdAll(vec3 ray_pos, Object obj)
{
  if (obj.type == 0) //Plane
    return sdPlane(ray_pos - obj.pos);
  if (obj.type == 1) //Sphere
    return sdSphere(ray_pos - obj.pos, obj.size.x / 2.0);
  if (obj.type == 2)
    return sdTerrain(ray_pos - obj.pos);
  if (obj.type == 3)
    return sdBox(ray_pos - obj.pos, obj.size);
  return -1.0;
}

//Function opU:
//Boolean operation: union. Combines 2 distance fields.
//From http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
//Edited to fit our code
MAP_RES opU(MAP_RES d1, MAP_RES d2)
{
	return (d1.dist<d2.dist) ? d1 : d2;
}

//Function opS:
//Boolean operation: subtraction. Subtracts distance field d2 from d1.
//From http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
float opS(float d1, float d2)
{
  return max(-d1,d2);
}

//Function opI:
//Boolean operation: intersection. Intersection between distance field d1 and d2.
//From http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
float opI(float d1, float d2)
{
  return max(d1,d2);
}

//setCamera is a function to get the camera's rotation matrix.
//ro is the ray's origin.
//ta is the ray's direction.
//cr is the ray's rotation around the camera's direction (roll).
mat3 setCamera(in vec3 ro, in vec3 ta, float cr)
{
	vec3 cw = normalize(ta-ro);
	vec3 cp = vec3(sin(cr), cos(cr),0.0);
	vec3 cu = normalize( cross(cw,cp) );
	vec3 cv = normalize( cross(cu,cw) );
  return mat3( cu, cv, cw );
}

float map(vec3 pos)
{
  return sdAll(pos, object);
}

//Calculates the normal by sampling the scene multiple times with small offsets.
//Using the values it can determine the surface normal.
//MAGIC//
vec3 calcNormal( in vec3 pos )
{
  vec2 e = vec2(1.0,-1.0)*0.5773*0.0005;
  return normalize( e.xyy*map( pos + e.xyy ) +
				  e.yyx*map( pos + e.yyx ) +
				  e.yxy*map( pos + e.yxy ) +
				  e.xxx*map( pos + e.xxx ) );
}

RAY_RES castRay(vec3 ro, vec3 rd, int samples)
{
  vec3 col = vec3(0.7, 0.9, 1.0) + rd.y*0.8;

  float t = 0.02;
  float K = 0.001;
  for (int i=0; i<samples; i++) {
    float dist = map(ro + rd * t);
    if (dist < K * t && dist >= 0.0) {
      //return vec3(r.y);
      RAY_RES res;
      res.obj = object;
      res.dist = t;
      return res;
    }
    t += dist;
  }

  RAY_RES sky_res;
  sky_res.dist = 128.0;

  return sky_res;
}

vec4 effect(vec4 color, sampler2D tex, vec2 uv, vec2 screen_coords)
{
  //if (mod(screen_coords.x + mod(screen_coords.y, 2.0), 2.0) == 0.0)
  //  return vec4(0.0, 0.0, 0.0, 1.0);
  //Camera matrix calculation
  mat3 cam_mat = setCamera(cam.pos, cam.pos + cam.dir, cam.roll);

  float depth = Texel(depth_map, uv).r;

  //UV and stuff
  vec2 fc = vec2(1.0 - uv.x, 1.0 - uv.y) * res; //fc = fragCoord, uv * res for the calculation of p
  vec2 p = (-res + 2.0*fc)/res.y;

  //Ray direction
  vec3 rd = cam_mat * normalize(vec3(p.xy, 2.0));

  RAY_RES res = castRay(cam.pos, rd, 128);
  //return vec4(vec3(res.dist / 64.0), 1.0);

  //vec3 pos = cam.pos + rd * res.dist;
  //vec3 nor = calcNormal(pos);
  //vec3 col;

  if (depth * 128.0 == 0.0) return vec4(vec3(res.dist / 128.0), 1.0);

  //if (res.dist >= 128.0) return vec4(vec3(depth), 1.0);

  if ((res.dist / 128.0) > depth) return vec4(vec3(depth), 1.0);

  //if (res.dist < 0.0) return vec4(1.0);

  //return vec4((nor + vec3(1.0)) / vec3(2.0), 1.0);

  return vec4(vec3(res.dist / 128.0), 1.0);
}
