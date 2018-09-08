struct Object {
  int type; //Type of object
  vec3 pos; //Position of object
  vec3 size; //Only uses x in case of sphere
  int mat_id; //To index the material list
};

struct Material {
  vec3 color;
  float opacity;
};

struct DirectionalLight {
  vec3 dir;
  vec3 col;
  float intensity;
};

struct Camera {
  vec3 pos;
  vec3 dir;
  float roll;
};

uniform Object objects[512];
uniform Material materials[512];
uniform int obj_length;

uniform Camera cam;
uniform vec2 res;

float sdPlane(vec3 p)
{
  return p.y;
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
  return -1.0;
}

//Function opU:
//Boolean operation: union. Combines 2 distance fields.
//From http://iquilezles.org/www/articles/distfunctions/distfunctions.htm
//Edited to fit our code
vec2 opU(vec2 d1, vec2 d2)
{
	return (d1.x<d2.x) ? d1 : d2;
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

vec2 map(vec3 pos)
{
  vec2 res = vec2(sdAll(pos, objects[0]), 1.0);
  for (int i=1; i < 2048; i++) {
    if (i >= obj_length) break;
    res = opU(res, vec2(sdAll(pos, objects[i]), 1.0));
  }
  return res;
}

//Softshadow function.
//RO is the ray's origin, in this case the light's origin.
//RD is the ray's direction, in this case the light's direction.
//mint is the near plane value.
//tmax is the far plane value.
float softshadow( in vec3 ro, in vec3 rd, in float mint, in float tmax )
{
	float res = 1.0;
  float t = mint;
  for( int i=0; i<64; i++ )
  {
		float h = map( ro + rd*t ).x;
    res = min( res, 8.0*h/t );
    t += clamp( h, 0.02, 0.10 );
    if( h<0.001 || t>tmax ) break;
  }
  return clamp( res, 0.0, 1.0 );
}

//Calculates the normal by sampling the scene multiple times with small offsets.
//Using the values it can determine the surface normal.
//MAGIC//
vec3 calcNormal( in vec3 pos )
{
  vec2 e = vec2(1.0,-1.0)*0.5773*0.0005;
  return normalize( e.xyy*map( pos + e.xyy ).x +
				  e.yyx*map( pos + e.yyx ).x +
				  e.yxy*map( pos + e.yxy ).x +
				  e.xxx*map( pos + e.xxx ).x );
}

vec3 castRay(vec3 ro, vec3 rd, int samples)
{
  vec3 col = vec3(0.0); //TODO: Calculate the sky color here

  float t = 0.02;
  float K = 0.001;
  for (int i=0; i<samples; i++) {
    vec2 r = map(ro + rd * t);
    if (r.x < K * t) {
      return vec3(r.y);
    }
    t += r.x;
  }

  return col;
}

vec4 effect(vec4 color, sampler2D tex, vec2 uv, vec2 screen_coords)
{
  //Camera matrix calculation
  mat3 cam_mat = setCamera(cam.pos, cam.pos + cam.dir, cam.roll);

  //UV and stuff
  vec2 fc = vec2(uv.x, 1.0 - uv.y) * res; //fc = fragCoord, uv * res for the calculation of p
  vec2 p = (-res + 2.0*fc)/res.y;

  //Ray direction
  vec3 rd = cam_mat * normalize(vec3(p.xy, 2.0));

  vec3 col = castRay(cam.pos, rd, 64);

  return vec4(col, 1.0);
}
