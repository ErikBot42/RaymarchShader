//double include guard
#ifndef RAY_MARCH_LIB_INCLUDED
#define RAY_MARCH_LIB_INCLUDED

#include "UnityCG.cginc"

#define PI UNITY_PI

#define V_UP float3(0, 1, 0)
#define V_X float3(1, 0, 0)
#define V_Y float3(0, 1, 0)
#define V_Z float3(0, 0, 1)
#define V_XZ float3(1, 0, 1)

#define C_RED   fixed4(1,0.001,0.001, 1)
#define C_GREEN fixed4(0.001, 1, 0.001, 1)
#define C_BLUE  fixed4(0.001, 0.001, 1, 1)
#define C_WHITE fixed4(1, 1, 1, 1)
#define C_GRAY  fixed4(0.2, 0.2, 0.2, 1)

#define DEFCOL fixed4(0.2, 0.2, 0.2, 1)

//ambient occlusion quality
#ifndef AO_STEPS
#define AO_STEPS 5
#endif

// to render nothing on the inside of objects (sky/transparent)
// use    #define ABS_DISTANCE
// this removes some artifacts when rendering distorted SDFs

#ifdef DYNAMIC_QUALITY//quality settings as material properties
int _MaxSteps = 100;
float _MaxDist = 100;
float _SurfDist = 0.00001;
#else//precompile quality settings
#   ifndef MAX_STEPS
#   define MAX_STEPS 256
#   endif
#   ifndef MAX_DIST
#   define MAX_DIST 128
#   endif
#   ifndef SURF_DIST
#   define SURF_DIST 0.00001
#   endif
#endif


#define col(r, g, b) fixed4(r, g, b, 1)

struct appdata
{
    float4 vertex : POSITION;
};

struct v2f
{
    float4 vertex : SV_POSITION;
    float3 vCamPos : TEXCOORD1;
    float3 vHitPos : TEXCOORD2;
};

//returned from casting a ray through the scene
struct rayData
{
    float dist;
    int iSteps;
    fixed4 col;
};

//returned from distance functions, including main scene
struct sdfData
{
    float dist;
    fixed4 col;
};

sdfData scene(float3 p);

v2f vert (appdata v)
{
    v2f o;
    o.vertex = UnityObjectToClipPos(v.vertex);
    #ifdef USE_WORLD_SPACE
    o.vCamPos = _WorldSpaceCameraPos;
    o.vHitPos = mul(unity_ObjectToWorld, v.vertex);
    #else
    o.vCamPos = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
    o.vHitPos = v.vertex;
    #endif
    return o;
}


//marches a ray through the scene
rayData castRay(float3 vRayStart, float3 vRayDir)
{
    float fRayLen = 0;// total distance marched / distance from camera
    sdfData sdf_data; // distance+color from the raymarched scene

    #ifdef DYNAMIC_QUALITY
    for (int i = 0; i < _MaxSteps; i++)
    #else
    for (int i = 0; i < MAX_STEPS; i++)
    #endif
    {
        float3 vPos = vRayStart + fRayLen * vRayDir;
        sdf_data = scene(vPos);

        #ifdef DYNAMIC_QUALITY
            #ifdef ABS_DISTANCE
        if (abs(sdf_data.dist) < _SurfDist) break;
            #else
        if (sdf_data.dist < _SurfDist) break;
            #endif
        #else
            #ifdef ABS_DISTANCE
        if (abs(sdf_data.dist) < SURF_DIST) break;
            #else
        if (sdf_data.dist < SURF_DIST) break;
            #endif
        #endif

        fRayLen += sdf_data.dist;// move forward
        
        #ifdef DYNAMIC_QUALITY
        if (fRayLen > _MaxDist) {fRayLen = -1; break;}//flag this as transparent/sky
        #else
        if (fRayLen > MAX_DIST) {fRayLen = -1; break;}//flag this as transparent/sky
        #endif
    }

    rayData data;
    data.dist = fRayLen;
    data.iSteps = i;
    data.col = sdf_data.col;
    return data; 
}


//gets normal of a point
float3 getNormal(float3 vPos, float fEpsilon = 0.001)
{
    ////if epilon is smaller than 0.001, there are often artifacts
    float2 e = float2(fEpsilon, 0);
    float3 n = scene(vPos).dist - float3(
            scene(vPos - e.xyy).dist,
            scene(vPos - e.yxy).dist,
            scene(vPos - e.yyx).dist);
    return normalize(n);
}

//more expensive and accurate
float3 getNormalAcc(float3 vPos, float fEpsilon = 0.001)
{
    float2 e = float2(fEpsilon, 0);
    return normalize(float3(scene(vPos + e.xyy).dist - scene(vPos - e.xyy).dist, 
            scene(vPos + e.yxy).dist - scene(vPos - e.yxy).dist,
            scene(vPos + e.yyx).dist - scene(vPos - e.yyx).dist));
}

//generates a skybox, use when ray didn't hit anything (ray_data.dist < 0)
inline float4 skyBox(float3 vRayDir, float3 vSunDir, fixed4 cSkyColor = fixed4(0.7, 0.75, 0.8, 1))
{
    float4 cRenderedSun = max(0, pow(dot(vRayDir, vSunDir) + 0.4, 10)-28) * float4(.8,.4,0,1);
    return cSkyColor - abs(vRayDir.y) * 0.5 + cRenderedSun;
}

//calculate sun light based on normal
fixed4 lightSun(float3 vNorm, float3 vSunDir = float3(8, 4, 2), fixed4 cSunCol = fixed4(7.0, 5.5, 3.0, 1))
{
    float fSunLight = max(dot(vNorm, vSunDir), 0);
    return fSunLight * cSunCol;
}

//calculate shadow from sun
float lightShadow(float3 vPos, float3 vSunDir, float fSharpness = 8)
{
    float fShadow = 1;
    #ifdef DYNAMIC_QUALITY
    for (float fRayLen = 0.001; fRayLen < _MaxDist/2.0;)
    #else
    for (float fRayLen = 0.001; fRayLen < MAX_DIST/2.0;)
    #endif
    {
        float dist = scene(vPos + vSunDir * fRayLen).dist;

        #ifdef DYNAMIC_QUALITY
        if (dist < _SurfDist) return 0;
        #else
        if (dist < SURF_DIST) return 0;
        #endif

        fShadow = min(fShadow, fSharpness * dist/fRayLen);
        fRayLen += dist;
    }
    return fShadow;
}

//cheaper shadow with hard edges
float lightShadowHard(float3 vPos, float3 vNorm, float3 vSunDir)
{
    return step(castRay(vPos + vNorm * 0.001, vSunDir).dist, 0.0);
}

//calculate sky light
inline fixed4 lightSky(float3 vNorm, fixed4 cSkyCol = fixed4(0.5, 0.8, 0.9, 1))
{
    return cSkyCol * (0.5 + 0.5 * vNorm.y);
}

//bad ambient occlusion (screen space) based on steps
float lightSSAO(rayData ray_data, float fDarkenFactor = 2)
{
    #ifdef DYNAMIC_QUALITY
    return pow(1 - float(ray_data.iSteps) / _MaxSteps, fDarkenFactor);
    #else
    return pow(1 - float(ray_data.iSteps) / MAX_STEPS, fDarkenFactor);
    #endif
}

//ambient occlusion
float lightAO(float3 vPos, float3 vNorm, float fEpsilon = 0.05)
{
    float ao = 0;
    for (int i = 0; i < AO_STEPS; i++)
    {
        float fOffset = i * fEpsilon;
        float fDist = scene(vPos + vNorm * fOffset).dist;
        ao += 1/pow(2, i) * (fOffset - fDist);
    }
    ao = 1 - AO_STEPS * ao;
    return ao;
}

//a light pass for debugging
float3 lightOnly(float3 vPos, float3 vNorm, float3 vSunDir)
{
    float fLight = lightSun(vNorm, vSunDir, 1);
    float fAO = lightAO(vPos, vNorm);
    float fShadow = lightShadow(vPos, vSunDir);
    return fLight * fShadow * fAO;
}

//soft min of a and b with smoothing factor k
inline float smin(float a, float b, float k) {
    float h = max(k - abs(a-b), 0) / k;
    return min(a, b) - h*h*h*k * 1/6.0;
}

//soft max of a and b with smoothing factor k 
inline float smax(float a, float b, float k) {
    float h = max(k - abs(a - b), 0) / k;
    return max(a, b) + h*h*h*k * 1/6.0;
}

//interpolate between the colours of 2 SDFs
inline fixed4 mixCol(sdfData sdfA, sdfData sdfB)
{
    return lerp(sdfA.col, sdfB.col, clamp(sdfA.dist/(sdfA.dist + sdfB.dist), 0, 1));
}

//union of SDF A and B
sdfData sdfAdd(float3 p, sdfData sA, sdfData sB)
{
    sdfData sC;
    sC.dist = min(sA.dist, sB.dist);
    sC.col = mixCol(sA, sB);
    return sC;
}

//union of SDF A and B, with smoothing
sdfData sdfAdd(float3 p, sdfData sA, sdfData sB, float fSmooth)
{
    sdfData sC;
    sC.dist = smin(sA.dist, sB.dist, fSmooth);
    sC.col = mixCol(sA, sB);
    return sC;
}

//remove the SDF B from A (colour is from A)
sdfData sdfSub(float3 p, sdfData sA, sdfData sB)
{
    sdfData sC;
    sC.dist = max(sA.dist, -sB.dist);
    sC.col = sA.col;
    return sC;
}

//remove the SDF B from A (colour is from A), with smoothing
sdfData sdfSub(float3 p, sdfData sA, sdfData sB, float fSmooth)
{
    sdfData sC;
    sC.dist = smax(sA.dist, -sB.dist, fSmooth);
    sC.col = sA.col;
    return sC;
}

//get intersection of 2 SDFs
sdfData sdfInter(float3 p, sdfData sA, sdfData sB)
{
    sdfData sC;
    sC.dist = max(sA.dist, sB.dist);
    sC.col = mixCol(sA, sB);
    return sC;
}

//get intersection of 2 SDFs, with smoothing
sdfData sdfInter(float3 p, sdfData sA, sdfData sB, float fSmooth)
{
    sdfData sC;
    sC.dist = smax(sA.dist, sB.dist, fSmooth);
    sC.col = mixCol(sA, sB);
    return sC;
}

//round edges of an SDF
sdfData sdfRound(float3 p, sdfData sdfIn, float fRadius)
{
    sdfData sdfOut = sdfIn;
    sdfOut.dist -= fRadius;
    return sdfOut;
}

//create sphere
sdfData sdfSphere(float3 p, float fRadius, fixed4 col = DEFCOL)
{
    sdfData sdf;
    sdf.dist = length(p) - fRadius;
    sdf.col = col;
    return sdf;
}

//create plane pointing to positive Y
sdfData sdfPlane(float3 p, float fHeight, fixed4 col = DEFCOL)
{
    sdfData sdf;
    sdf.col = col;
    sdf.dist = p.y - fHeight;
    return sdf;
}

//create plane with normal
sdfData sdfPlane(float3 p, float3 vNorm, float fHeight, fixed4 col = DEFCOL)
{
    sdfData sdf;
    sdf.col = col;
    sdf.dist = dot(p, normalize(vNorm)) - fHeight;
    return sdf;
}

//create cuboid
sdfData sdfBox(float3 p, float3 vDim, fixed4 col = DEFCOL, float fRound = 0) {
    sdfData sdf;
    float3 q = abs(p) - vDim/2.0;
    sdf.dist = length(max(q, 0)) + min(max(q.x, max(q.y, q.z)), 0) - fRound;
    sdf.col = col;
    return sdf;
}

//create line segment
sdfData sdfLine(float3 p, float3 vStart, float3 vEnd, float fRadius, fixed4 col = DEFCOL) {
    sdfData sdf;
    sdf.col = col;
    float h = min(1, max(0, dot(p-vStart, vEnd-vStart) / dot(vEnd-vStart, vEnd-vStart)));
    sdf.dist = length(p-vStart-(vEnd-vStart)*h)-fRadius;
    return sdf;
}

//create cylinder
sdfData sdfCylinder(float3 p, float fRadius, float fHeight, fixed4 col = DEFCOL, float fRound = 0) {
    sdfData sdf;
    sdf.col = col;
    sdf.dist = max(abs(p.y) - fHeight/2.0, length(p.xz) - fRadius) - fRound;
    return sdf;
}

//create torus
sdfData sdfTorus(float3 p, float fRadius, float fThickness, fixed4 col = DEFCOL) {
    sdfData sdf;
    sdf.col = col;
    float2 q = float2(length(p.xz) - fRadius, p.y);
    sdf.dist = length(q) - fThickness;
    return sdf;
}

//triangular prism (BOUND)
sdfData sdfTriPrism(float3 p, float fSide, float fDepth, fixed4 col = DEFCOL)
{
  float3 q = abs(p);
  sdfData sdf;
  sdf.col = col;
  sdf.dist = max(q.z - fDepth, max(q.x * 0.866025 + p.y * 0.5, -p.y) - fSide * 0.5);
  return sdf;
}

//rotate point p around origin, a radians
float3 rotX(float3 p, float a) {
    return mul(float3x3(1, 0, 0, 0, cos(a), -sin(a), 0, sin(a), cos(a)), p);
}

//rotate point p around origin, a radians
float3 rotY(float3 p, float a) {
    return mul(float3x3(cos(a), 0, sin(a), 0, 1, 0, -sin(a), 0, cos(a)), p);
}

//rotate point p around origin, a radians
float3 rotZ(float3 p, float a) {
    return mul(float3x3(cos(a), -sin(a), 0, sin(a), cos(a), 0, 0, 0, 1), p);
}

//repeats space every r units, centered on the origin
inline float3 repXYZ(float3 p, float3 r) {
    return fmod(abs(p + r/2.0), r) - r/2.0;
}

//repeats space every r units, centered on the origin
inline float3 repXZ(float3 p, float x, float z) {
    float3 o = p;
    o.x = fmod(abs(p.x) + x/2.0, x) - x/2.0;
    o.x *= sign(p.x);
    o.z = fmod(abs(p.z) + z/2.0, z) - z/2.0;
    o.z *= sign(p.z);
    return o;
}

#endif //RAY_MARCH_LIB_INCLUDED