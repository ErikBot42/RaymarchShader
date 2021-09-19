#ifndef RAYMARCHUTIL_CGINC
#define RAYMARCHUTIL_CGINC

#include "RayMarchLib.h"


inline material mat(float r, float g, float b, float fRough = 1)
{
    material m = {fixed4(r, g, b, 1), fRough};
    return m;
}

inline material mat(float3 rgb, float fRough = 1)
{
    material m = {fixed4(rgb, 1), fRough};
    return m;
}


//////////////////////////////////////////////////////////////////////
//
// Lighting
//
//////////////////////////////////////////////////////////////////////


//generates a skybox, use when ray didn't hit anything (ray_data.bMissed)
inline fixed4 sky(float3 vRayDir)
{
    float4 cRenderedSun = max(0, pow(dot(vRayDir, normalize(float3(8,4,2))) + 0.4, 10)-28) * float4(.8,.4,0,1);
    return fixed4(0.7, 0.75, 0.8, 1) - abs(vRayDir.y) * 0.5 + cRenderedSun;
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
    #ifdef USE_DYNAMIC_QUALITY
    for (float fRayLen = 0.001; fRayLen < _MaxDist/2.0;)
    #else
    for (float fRayLen = 0.001; fRayLen < MAX_DIST/2.0;)
    #endif
    {
        float dist = scene(vPos + vSunDir * fRayLen).dist;

        #ifdef USE_DYNAMIC_QUALITY
        if (dist < _SurfDist) return 0;
        #else
        if (dist < SURF_DIST) return 0;
        #endif

        fShadow = min(fShadow, fSharpness * dist/fRayLen);
        fRayLen += dist;
    }
    return fShadow;
}

//calculate sky light
inline fixed4 lightSky(float3 vNorm, fixed4 cSkyCol = fixed4(0.5, 0.8, 0.9, 1))
{
    return cSkyCol * (0.5 + 0.5 * vNorm.y);
}

//bad ambient occlusion (screen space) based on steps
float lightSSAO(rayData ray_data, float fDarkenFactor = 2)
{
    #ifdef USE_DYNAMIC_QUALITY
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

inline fixed4 lightFog(fixed4 col, fixed4 cFog, float fDist, float fStart=16, float fFull=32)
{
    if (fDist < 0) return cFog;
    return lerp(col, cFog, smoothstep(fStart, fFull, fDist));
}

//a light pass for debugging
fixed4 lightOnly(float3 vPos, float3 vNorm, float3 vSunDir)
{
    float fLight = lightSun(vNorm, vSunDir, 1);
    float fAO = lightAO(vPos, vNorm);
    float fShadow = lightShadow(vPos, vSunDir);
    return fLight * fAO * fShadow;
}


#endif
