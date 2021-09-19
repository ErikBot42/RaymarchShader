#ifndef RAYMARCHLIB_CGINC
#define RAYMARCHLIB_CGINC

#include "UnityCG.cginc"
#include "RayMarchLib.h"
#include "SdfFunctions.cginc"
#include "SdfMath.cginc"
#include "Transforms.cginc"
#include "FastMath.cginc"
#include "RayMarchUtil.cginc"

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

#ifdef USE_REFLECTIONS
#define CALC_NORM
fragOut frag (v2f i)
{

    float fRayLen = 0;//since last bounce

    #ifdef CONSTRAIN_TO_MESH
    float3 vLastBounce = i.vHitPos;
    fRayLen += length(i.vHitPos - i.vCamPos);
    #else
    float3 vLastBounce = i.vCamPos;
    #endif
    float3 vRayDir = normalize(i.vHitPos - i.vCamPos);//current direction
    sdfData point_data;
    rayData ray;

    fixed4 col;
    float colUsed = 0;// what amount of the final colour has been calculated
    float prevRough = 0;

    float3 vFirstHit;

    for (int i = 0; i < MAX_REFLECTIONS+1; i++)
    {
        ray = castRay(vLastBounce, vRayDir);
        if (i == 0)
        {//before any bounces
            col = lightPoint(ray);
            vFirstHit = ray.vHit;
        }
        else
        {
            float colAmt = colUsed + (prevRough * (1-colUsed));
            col = lerp(lightPoint(ray), col, colAmt);
            colUsed = colAmt;
        }
        if (ray.bMissed || ray.mat.fRough > 0.99)
        {
            break;
        }
        prevRough = ray.mat.fRough;
        vRayDir = reflect(vRayDir, ray.vNorm);
        vLastBounce = ray.vHit + vRayDir * 0.01;
    }
    #ifdef DISCARD_ON_MISS
    if (ray.bMissed && i == 0) discard;
    #endif
    fragOut o;
    o.col = col;
    
    #ifdef USE_WORLD_SPACE
        float4 vClipPos = mul(UNITY_MATRIX_VP, float4(vFirstHit, 1));
    #else
        float4 vClipPos = mul(UNITY_MATRIX_VP, mul(unity_ObjectToWorld, float4(vFirstHit, 1)));
    #endif

    o.depth = (vClipPos.z / vClipPos.w + 1.0) * 0.5;
    return o;
}
#else
fragOut frag (v2f i)
{
    float3 vRayDir = normalize(i.vHitPos - i.vCamPos);
    #ifdef CONSTRAIN_TO_MESH
    //rayData ray = castRay(i.vHitPos, vRayDir, length(i.vHitPos-i.vCamPos));
    rayData ray = castRay(i.vCamPos, vRayDir, length(i.vHitPos-i.vCamPos));
    //rayData ray = castRay(i.vCamPos, vRayDir, 1);
    //rayData ray = castRay(i.vCamPos, vRayDir, 0);

    #else
    rayData ray = castRay(i.vCamPos, vRayDir);
    #endif
    #ifdef DISCARD_ON_MISS
    if (ray.bMissed) discard;
    #endif
    fragOut o;
    o.col = lightPoint(ray);

	// writing to depth buffer costs about 1-2 frames at 4k
    #ifdef USE_WORLD_SPACE
        float4 vClipPos = mul(UNITY_MATRIX_VP, float4(ray.vHit, 1));
    #else
        float4 vClipPos = mul(UNITY_MATRIX_VP, mul(unity_ObjectToWorld, float4(ray.vHit, 1)));
    #endif
    
    o.depth = (vClipPos.z / vClipPos.w + 1.0) * 0.5;
    return o;
}
#endif

//gets normal of a point
inline float3 getNormFull(float3 vPos, float fEpsilon = 0.001)
{
    //if epsilon is smaller than 0.001, there are often artifacts
    const float2 e = float2(fEpsilon, 0);
    float3 n = scene(vPos).dist - float3(
            scene(vPos - e.xyy).dist,
            scene(vPos - e.yxy).dist,
            scene(vPos - e.yyx).dist);
    return normalize(n);
}
//gets normal, provided you have the distance for pos (1 less call to scene())
inline float3 getNorm(float3 vPos, float fPointDist, float fEpsilon = 0.001)
{
    ////if epilon is smaller than 0.001, there are often artifacts
    const float2 e = float2(fEpsilon, 0);
    float3 n = fPointDist - float3(
            scene(vPos - e.xyy).dist,
            scene(vPos - e.yxy).dist,
            scene(vPos - e.yyx).dist);
    return normalize(n);
}

//marches a ray through the scene once
rayData castRay(float3 vRayStart, float3 vRayDir, float startDist)
{
    float fRayLen = startDist;//startDist;// total distance marched / distance from camera

    float3 vPos;
    sdfData sdf_data;

    rayData ray;
    ray.vRayDir = vRayDir;
    ray.vRayStart = vRayStart;
    ray.minDist = 30000.0;// budget "infinity"
    ray.distToMinDist = 0;

    #ifdef USE_DYNAMIC_QUALITY
    for (int i = 0; i < _MaxSteps; i++)
    #else
    for (int i = 0; i < MAX_STEPS; i++)
    #endif
    {
        vPos = vRayStart + fRayLen * vRayDir;
        sdf_data = scene(vPos);

        #ifdef USE_DYNAMIC_QUALITY
        if (abs(sdf_data.dist) < _SurfDist) break;
        #else
        if (abs(sdf_data.dist) < SURF_DIST) break;
        #endif

        fRayLen += sdf_data.dist;// move forward

        if (ray.minDist>sdf_data.dist) 
        {
            ray.minDist = sdf_data.dist;
            ray.distToMinDist = fRayLen;
        }
        
        #ifdef USE_DYNAMIC_QUALITY
        if (fRayLen > _MaxDist) {ray.bMissed = true; break;}//flag this as transparent/sky
        #else
        if (fRayLen > MAX_DIST) {ray.bMissed = true; break;}//flag this as transparent/sky
        #endif
    }

    ray.dist   = fRayLen;
    ray.iSteps = i;
    ray.mat    = sdf_data.mat;
    ray.vHit   = vPos;
	#ifdef CALC_NORM
    ray.vNorm  = getNorm(vPos, sdf_data.dist);
	#endif
    return ray;
}

#endif
