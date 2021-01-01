#include "UnityCG.cginc"

#define PI 3.14159265

#define V_UP float3(0, 1, 0)
#define V_X float3(1, 0, 0)
#define V_Y float3(0, 1, 0)
#define V_Z float3(0, 0, 1)
#define V_XZ float3(1, 0, 1)

#define C_RED float3(1,0.001,0.001)
#define C_GREEN float3(0.001, 1, 0.001)
#define C_BLUE float3(0.001, 0.001, 1)
#define C_WHITE float3(1, 1, 1)
#define C_GRAY float3(0.2, 0.2, 0.2)

#define DEFCOL float3(0.2, 0.2, 0.2)

bool _UseObjectSpace;
int _MaxSteps = 100;
float _MaxDist = 100;
float _SurfDist = 0.00001;

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
    float3 col;
};

//returned from distance functions, including main scene
struct sdfData
{
    float dist;
    float3 col;
};

sdfData scene(float3 p);

v2f vert (appdata v)
{
    v2f o;
    o.vertex = UnityObjectToClipPos(v.vertex);
    if (_UseObjectSpace)
    {//object space
        o.vCamPos = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
        o.vHitPos = v.vertex;
    }
    else
    {//world space
        o.vCamPos = _WorldSpaceCameraPos;
        o.vHitPos = mul(unity_ObjectToWorld, v.vertex);
    }
    return o;
}

//marches a ray through the scene
rayData castRay(float3 vRayStart, float3 vRayDir)
{
    float fRayLen = 0;// total distance marched / distance from camera
    sdfData sdf_data; // distance+color from the raymarched scene

    for (int i = 0; i < _MaxSteps; i++)
    {
        float3 vPos = vRayStart + fRayLen * vRayDir;
        sdf_data = scene(vPos);

        if (sdf_data.dist < _SurfDist) break;
        fRayLen += sdf_data.dist;// move forward
        if (fRayLen > _MaxDist) break;
    }
    if (fRayLen > _MaxDist) fRayLen = -1;//flag this as transparent/sky

    rayData data;
    data.dist = fRayLen;
    data.iSteps = i;
    data.col = sdf_data.col;
    return data; 
}

float3 getNormal(float3 vPos, float fEpsilon = 0.001)
{
    //if epilon is smaller than 0.001, there are often artifacts
    float2 e = float2(fEpsilon, 0);
    float3 n = scene(vPos).dist - float3(
            scene(vPos - e.xyy).dist,
            scene(vPos - e.yxy).dist,
            scene(vPos - e.yyx).dist);
    return normalize(n);
}

float3 lightSun(float3 vNorm, float3 vSunDir = float3(8, 4, 2), float3 cSunCol = float3(7.0, 5.5, 3.0))
{
    float fSunLight = clamp(dot(vNorm, vSunDir), 0, 1);
    return fSunLight * cSunCol;
}

float lightShadowHard(float3 vPos, float3 vNorm, float3 vSunDir)
{
    return step(castRay(vPos + vNorm * 0.001, vSunDir).dist, 0.0);
}

float lightShadow(float3 vPos, float3 vSunDir, float fSharpness=8)
{
    float fShadow = 1;
    for (float fRayLen = 0.001; fRayLen < _MaxDist;)
    {
        float dist = scene(vPos + vSunDir * fRayLen).dist;
        if (dist < _SurfDist) return 0;
        fShadow = min(fShadow, fSharpness * dist/fRayLen);
        fRayLen += dist;
    }
    return fShadow;
}

float3 lightSky(float3 vNorm, float3 cSkyCol = float3(0.5, 0.8, 0.9))
{
    return cSkyCol * clamp(0.5 + 0.5 * dot(vNorm, float3(0, 1, 0)), 0, 1);
}

//bad ambient occlusion (screen space)
float lightSSAO(rayData ray_data, float fDarkenFactor = 2)
{
    return pow(1 - float(ray_data.iSteps) / _MaxSteps, fDarkenFactor);
}

float lightAO(float3 vPos, float3 vNorm, float fEpsilon = 0.05)
{
    float ao = 0;
    for (int i = 0; i < 5; i++)
    {
        float fOffset = i * fEpsilon;
        float fDist = scene(vPos + vNorm * fOffset).dist;
        ao += 1/pow(2, i) * (fOffset - fDist);
    }
    ao = 1 - 5 * ao;
    return ao;
}

float3 lightOnly(float3 vPos, float3 vNorm, float3 vSunDir)
{
    float fLight = lightSun(vNorm, vSunDir, 1);
    float fAO = lightAO(vPos, vNorm);
    float fShadow = lightShadow(vPos, vSunDir);
    return fLight * fShadow * fAO;
}

//soft min of a and b with smoothing factor k
float smin(float a, float b, float k) {
    float h = max(k - abs(a-b), 0) / k;
    return min(a, b) - h*h*h*k * 1/6.0;
}

//soft max of a and b with smoothing factor k 
float smax(float a, float b, float k) {
    float h = max(k - abs(a - b), 0) / k;
    return max(a, b) + h*h*h*k * 1/6.0;
}

float3 mixCol(sdfData sdfA, sdfData sdfB)
{
    return lerp(sdfA.col, sdfB.col, clamp(sdfA.dist/(sdfA.dist + sdfB.dist), 0, 1));
}

sdfData sdfAdd(float3 p, sdfData sA, sdfData sB)
{
    sdfData sC;
    sC.dist = min(sA.dist, sB.dist);
    sC.col = mixCol(sA, sB);
    return sC;
}

sdfData sdfAdd(float3 p, sdfData sA, sdfData sB, float fSmooth)
{
    sdfData sC;
    sC.dist = smin(sA.dist, sB.dist, fSmooth);
    sC.col = mixCol(sA, sB);
    return sC;
}

sdfData sdfSub(float3 p, sdfData sA, sdfData sB)
{
    sdfData sC;
    sC.dist = max(sA.dist, -sB.dist);
    sC.col = sA.col;
    return sC;
}

sdfData sdfSub(float3 p, sdfData sA, sdfData sB, float fSmooth)
{
    sdfData sC;
    sC.dist = smax(sA.dist, -sB.dist, fSmooth);
    sC.col = sA.col;
    return sC;
}

sdfData sdfInter(float3 p, sdfData sA, sdfData sB)
{
    sdfData sC;
    sC.dist = max(sA.dist, sB.dist);
    sC.col = mixCol(sA, sB);
    return sC;
}

sdfData sdfInter(float3 p, sdfData sA, sdfData sB, float fSmooth)
{
    sdfData sC;
    sC.dist = smax(sA.dist, sB.dist, fSmooth);
    sC.col = mixCol(sA, sB);
    return sC;
}

sdfData sdfRound(float3 p, sdfData sdfIn, float fRadius)
{
    sdfData sdfOut = sdfIn;
    sdfOut.dist -= fRadius;
    return sdfOut;
}

sdfData sdfSphere(float3 p, float fRadius, float3 col = DEFCOL)
{
    sdfData sdf;
    sdf.dist = length(p) - fRadius;
    sdf.col = col;
    return sdf;
}

sdfData sdfPlane(float3 p, float fHeight, float3 col = DEFCOL)
{
    sdfData sdf;
    sdf.col = col;
    sdf.dist = p.y - fHeight;
    return sdf;
}

sdfData sdfPlane(float3 p, float3 vNorm, float fHeight, float3 col = DEFCOL)
{
    sdfData sdf;
    sdf.col = col;
    sdf.dist = dot(p, normalize(vNorm)) - fHeight;
    return sdf;
}

sdfData sdfBox(float3 p, float3 vDim, float3 col = DEFCOL) {
    sdfData sdf;
    float3 q = abs(p) - vDim/2.0;
    sdf.dist = length(max(q, 0)) + min(max(q.x, max(q.y, q.z)), 0);
    sdf.col = col;
    return sdf;
}

sdfData sdfLine(float3 p, float3 vStart, float3 vEnd, float fRadius, float3 col = DEFCOL) {
    sdfData sdf;
    sdf.col = col;
    float h = min(1, max(0, dot(p-vStart, vEnd-vStart) / dot(vEnd-vStart, vEnd-vStart)));
    sdf.dist = length(p-vStart-(vEnd-vStart)*h)-fRadius;
    return sdf;
}

sdfData sdfCylinder(float3 p, float fRadius, float fHeight, float3 col = DEFCOL) {
    sdfData sdf;
    sdf.col = col;
    sdf.dist = max(abs(p.y) - fHeight/2.0, length(p.xz) - fRadius);
    return sdf;
}

sdfData sdfTorus(float3 p, float fRadius, float fThickness, float3 col = DEFCOL) {
    sdfData sdf;
    sdf.col = col;
    float2 q = float2(length(p.xz) - fRadius, p.y);
    sdf.dist = length(q) - fThickness;
    return sdf;
}

float3 rotX(float3 p, float a) {
    return mul(float3x3(1, 0, 0, 0, cos(a), -sin(a), 0, sin(a), cos(a)), p);
}

float3 rotY(float3 p, float a) {
    return mul(float3x3(cos(a), 0, sin(a), 0, 1, 0, -sin(a), 0, cos(a)), p);
}

float3 rotZ(float3 p, float a) {
    return mul(float3x3(cos(a), -sin(a), 0, sin(a), cos(a), 0, 0, 0, 1), p);
}

//repeats space every r units, centered on the origin
float3 repDomain(float3 p, float3 r) {
    return fmod(abs(p + r/2.0), r) - r/2.0;
}
