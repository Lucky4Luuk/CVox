#define PI 3.14159265359
#define saturate(x) clamp(x, 0.0, 1.0)

struct Object {
  int type; //Type of object
  vec3 pos; //Position of object
  vec3 size; //Only uses x in case of sphere
  int mat_id; //To index the material list
};

struct Material {
  vec3 color; //Color
  float opacity; //Unused right win
  float roughness; //Roughness
  float metallicness; //Metallicness
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

struct MAP_RES {
  float dist;
  int id;
};

struct RAY_RES {
  Object obj;
  Material mat;
  float dist;
};

uniform Object objects[256];
uniform Material materials[256];
uniform DirectionalLight dir_lights[256];
uniform int obj_length;
uniform int dir_light_length;

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

MAP_RES map(vec3 pos)
{
  MAP_RES res;
  res.dist = sdAll(pos, objects[0]);
  res.id = 0;
  for (int i=1; i < 2048; i++) {
    if (i >= obj_length) break;
    MAP_RES r;
    r.dist = sdAll(pos, objects[i]);
    r.id = i;
    res = opU(res, r);
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
		float h = map( ro + rd*t ).dist;
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
  return normalize( e.xyy*map( pos + e.xyy ).dist +
				  e.yyx*map( pos + e.yyx ).dist +
				  e.yxy*map( pos + e.yxy ).dist +
				  e.xxx*map( pos + e.xxx ).dist );
}

RAY_RES castRay(vec3 ro, vec3 rd, int samples)
{
  vec3 col = vec3(0.7, 0.9, 1.0) + rd.y*0.8;

  float t = 0.02;
  float K = 0.001;
  for (int i=0; i<samples; i++) {
    MAP_RES r = map(ro + rd * t);
    if (r.dist < K * t) {
      //return vec3(r.y);
      Object o = objects[r.id];
      Material m = materials[o.mat_id];
      RAY_RES res;
      res.obj = o;
      res.mat = m;
      res.dist = t;
      return res;
    }
    t += r.dist;
  }

  RAY_RES sky_res;
  Material sky_mat;
  sky_mat.color = col;
  sky_res.mat = sky_mat;
  sky_res.dist = -1.0;

  return sky_res;
}

//------------------------------------------------------------------------------
// BRDF
//------------------------------------------------------------------------------

//This is where the real magic happens.
//Behold, the PBR lighting system.

float pow5(float x) {
    float x2 = x * x;
    return x2 * x2 * x;
}

float D_GGX(float linearRoughness, float NoH, const vec3 h) {
    // Walter et al. 2007, "Microfacet Models for Refraction through Rough Surfaces"
    float oneMinusNoHSquared = 1.0 - NoH * NoH;
    float a = NoH * linearRoughness;
    float k = linearRoughness / (oneMinusNoHSquared + a * a);
    float d = k * k * (1.0 / PI);
    return d;
}

float V_SmithGGXCorrelated(float linearRoughness, float NoV, float NoL) {
    // Heitz 2014, "Understanding the Masking-Shadowing Function in Microfacet-Based BRDFs"
    float a2 = linearRoughness * linearRoughness;
    float GGXV = NoL * sqrt((NoV - a2 * NoV) * NoV + a2);
    float GGXL = NoV * sqrt((NoL - a2 * NoL) * NoL + a2);
    return 0.5 / (GGXV + GGXL);
}

vec3 F_Schlick(const vec3 f0, float VoH) {
    // Schlick 1994, "An Inexpensive BRDF Model for Physically-Based Rendering"
    return f0 + (vec3(1.0) - f0) * pow5(1.0 - VoH);
}

float F_Schlick(float f0, float f90, float VoH) {
    return f0 + (f90 - f0) * pow5(1.0 - VoH);
}

float Fd_Burley(float linearRoughness, float NoV, float NoL, float LoH) {
    // Burley 2012, "Physically-Based Shading at Disney"
    float f90 = 0.5 + 2.0 * linearRoughness * LoH * LoH;
    float lightScatter = F_Schlick(1.0, f90, NoL);
    float viewScatter  = F_Schlick(1.0, f90, NoV);
    return lightScatter * viewScatter * (1.0 / PI);
}

float Fd_Lambert() {
    return 1.0 / PI;
}

//------------------------------------------------------------------------------
// Indirect lighting
//------------------------------------------------------------------------------

//MORE LIGHTING
//Handles indirect lighting. Not GI, but it does handle reflections.

vec3 Irradiance_SphericalHarmonics(const vec3 n) {
    // Irradiance from "Ditch River" IBL (http://www.hdrlabs.com/sibl/archive.html)
    return max(
          vec3( 0.754554516862612,  0.748542953903366,  0.790921515418539)
        + vec3(-0.083856548007422,  0.092533500963210,  0.322764661032516) * (n.y)
        + vec3( 0.308152705331738,  0.366796330467391,  0.466698181299906) * (n.z)
        + vec3(-0.188884931542396, -0.277402551592231, -0.377844212327557) * (n.x)
        , 0.0);
}

vec2 PrefilteredDFG_Karis(float roughness, float NoV) {
    // Karis 2014, "Physically Based Material on Mobile"
    const vec4 c0 = vec4(-1.0, -0.0275, -0.572,  0.022);
    const vec4 c1 = vec4( 1.0,  0.0425,  1.040, -0.040);

    vec4 r = roughness * c0 + c1;
    float a004 = min(r.x * r.x, exp2(-9.28 * NoV)) * r.x + r.y;

    return vec2(-1.04, 1.04) * a004 + r.zw;
}

//Oh boy.
//The final BRDF function that ties it all together.
//pos is the worldposition where the object was hit.
//n is the surface normal corresponding to pos.
//rd is the ray's direction.
//l is the current light's direction.
//lp is the current light's position.
//range is the light's range (not used for the directional light).
//baseColor is the object's base color.
//roughness is the object's roughness.
//metallic is the object's metallic value.
vec3 BRDF (vec3 pos, vec3 n, vec3 rd, vec3 l, vec3 lp, float range, vec3 baseColor, float roughness, float metallic)
{
	vec3 color = vec3(0.0);

	vec3 v = normalize(-rd);
	vec3 h = normalize(v + l);
	vec3 r = normalize(reflect(rd, n));

	float NoV = abs(dot(n, v)) + 1e-5;
	float NoL = saturate(dot(n, l));
	float NoH = saturate(dot(n, h));
	float LoH = saturate(dot(l, h));

	float intensity = 2.0; //Default: 2.0
	float indirectIntensity = 0.64; //Default: 0.64

	if (range > 0) { //This is probably the worst distance calculation possible. But it seems to work.
		intensity = 0.0;
		indirectIntensity = 0.0;
		intensity += clamp(range-distance(pos, lp),0.0,range);
		indirectIntensity += clamp(range-distance(pos, lp),0.0,range)/3.90625;
	}

	float linearRoughness = roughness * roughness;
	vec3 diffuseColor = (1.0 - metallic) * baseColor.rgb;
	vec3 f0 = 0.04 * (1.0 - metallic) + baseColor.rgb * metallic;

	float attenuation = softshadow(pos, l, 0.02, 25.0);

	indirectIntensity *= attenuation;

	//Specular BRDF
	float D = D_GGX(linearRoughness, NoH, h) * attenuation;
	float V = V_SmithGGXCorrelated(linearRoughness, NoV, NoL);
	vec3 F = F_Schlick(f0, LoH);
	vec3 Fr = (D * V) * F;

	//Diffuse BRDF
	vec3 Fd = diffuseColor * Fd_Burley(linearRoughness, NoV, NoL, LoH);

	color = Fd + Fr;
	color *= (intensity * attenuation * NoL) + vec3(0.98, 0.92, 0.89);

	//Diffuse Indirect
	vec3 indirectDiffuse = Irradiance_SphericalHarmonics(n) * Fd_Lambert();

	RAY_RES indirectHit = castRay(pos, r, 32);
  //vec3 tex_col = objects[indirectHit.id].avg_tex_col;
	vec3 indirectSpecular = indirectHit.mat.color;

	//Indirect Contribution
	vec2 dfg = PrefilteredDFG_Karis(roughness, NoV);
	vec3 specularColor = f0 * dfg.x + dfg.y;
	vec3 ibl = diffuseColor * indirectDiffuse + indirectSpecular * specularColor * attenuation;

	color += ibl * indirectIntensity;

	return color;
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

  RAY_RES res = castRay(cam.pos, rd, 64);
  if (res.dist < 0.0) return vec4(res.mat.color, 1.0);
  vec3 pos = cam.pos + rd * res.dist;
  vec3 nor = calcNormal(pos);
  vec3 col;

  for (int i=0; i<1024; i++) {
    if (i >= dir_light_length) break;
    vec3 lig = normalize(dir_lights[i].dir);
    col += BRDF(pos, nor, rd, lig, vec3(0.0), -1, res.mat.color, res.mat.roughness, res.mat.metallicness);
  }

  return vec4(col, 1.0);
}
