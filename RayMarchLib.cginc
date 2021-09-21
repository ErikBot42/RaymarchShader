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
	o.vDir = normalize(o.vHitPos - o.vCamPos);
	o.vCamPos *=1;// scaling
    

	//rayData ray = castRay(o.vCamPos, o.vDir);
	//o.distEstimate.x = ray.dist;
	float3 vDeltaPos = o.vHitPos - o.vCamPos; // constrain to mesh
	float fDeltaDist = length(vDeltaPos); // dist from camera to vertex

	float fEdgeLength = 0.02; // estimated distance between vertices.
	float fSurfDistPerMeter = fEdgeLength/fDeltaDist;

	//o.distEstimate.x = castRayEstimate(o.vCamPos, o.vDir, MAX_STEPS, MAX_DIST, 0.02, fDeltaDist);
	//o.distEstimate.x = castRayEstimate(o.vCamPos, o.vDir, MAX_STEPS, MAX_DIST, SURF_DIST, fDeltaDist, fSurfDistPerMeter);
	o.distEstimate.x = castRayEstimate(o.vCamPos, o.vDir, MAX_STEPS, MAX_DIST*0.9, SURF_DIST, fDeltaDist, fSurfDistPerMeter);
	//o.distEstimate.x = castRayEstimate(o.vCamPos, o.vDir, MAX_STEPS, MAX_DIST, 0.01, 0); // somehow WAY slower...
	
	//#define VERTEX_DEBUG_COLORS
    
    //o.color = lightPoint(ray);
    //o.color = fixed4(float(ray.iSteps)/MAX_STEPS,0,0,1);
	//o.color = fixed4(1,0,0,1);

	return o;
}

#ifdef USE_REFLECTIONS
#define CALC_NORM
fragOut frag (v2f i)
{

    //float fRayLen = 0;//since last bounce
	//float3 vRayDir = i.vDir;
    ////float3 vRayDir = normalize(i.vHitPos - i.vCamPos);//current direction

    //#ifdef CONSTRAIN_TO_MESH
	////float3 posDif = i.vHitPos - i.vCamPos;
	////if (dot(posDif,
    ////float3 vLastBounce = i.vHitPos;
    ////fRayLen += length;
    //float3 vLastBounce = i.vHitPos;
    //fRayLen += length(i.vHitPos - i.vCamPos);
    //#else
    //float3 vLastBounce = i.vCamPos;
    //#endif
    //sdfData point_data;
    //rayData ray;

    //fixed4 col;
    //float colUsed = 0;// what amount of the final colour has been calculated
    //float prevRough = 0;

    //float3 vFirstHit;

    //for (int i = 0; i < MAX_REFLECTIONS+1; i++)
    //{
    //    ray = castRay(vLastBounce, vRayDir);
    //    if (i == 0)
    //    {//before any bounces
    //        col = lightPoint(ray);
    //        vFirstHit = ray.vHit;
    //    }
    //    else
    //    {
    //        float colAmt = colUsed + (prevRough * (1-colUsed));
    //        col = lerp(lightPoint(ray), col, colAmt);
    //        colUsed = colAmt;
    //    }
    //    if (ray.bMissed || ray.mat.fRough > 0.99)
    //    {
    //        break;
    //    }
    //    prevRough = ray.mat.fRough;
    //    vRayDir = reflect(vRayDir, ray.vNorm);
    //    vLastBounce = ray.vHit + vRayDir * 0.01;
    //}
    //#ifdef DISCARD_ON_MISS
    //if (ray.bMissed && i == 0) discard;
    //#endif
    //fragOut o;
    //o.col = col;
    //
    //#ifdef USE_WORLD_SPACE
    //    float4 vClipPos = mul(UNITY_MATRIX_VP, float4(vFirstHit, 1));
    //#else
    //    float4 vClipPos = mul(UNITY_MATRIX_VP, mul(unity_ObjectToWorld, float4(vFirstHit, 1)));
    //#endif

    //o.depth = (vClipPos.z / vClipPos.w + 1.0) * 0.5;
    //return o;

	fragOut o;
	o.col = fixed4(1,1,1,1);
	return o;
}
#else
fragOut frag (v2f i)
{
	// TESTING VERTEX COLORING
	//fragOut qwe;
	//qwe.col = i.color;
	//return qwe;

    float3 vRayDir = normalize(i.vHitPos - i.vCamPos);
    //float3 vRayDir = i.vDir; // needs high vertex count to work
    #ifdef CONSTRAIN_TO_MESH
	//float len =length(i.vHitPos-i.vCamPos); 
	float len = i.distEstimate.x*1;
	rayData ray;
	{ray = castRay(i.vCamPos, vRayDir, len);}
	//{ray = castRay(i.vCamPos, vRayDir, length(i.vHitPos-i.vCamPos));}
	//{ray = castRay(i.vCamPos, vRayDir);}
    #else
    rayData ray = castRay(i.vCamPos, vRayDir);
    #endif
    #ifdef DISCARD_ON_MISS
    if (ray.bMissed) discard;
    #endif
    fragOut o;
    o.col = lightPoint(ray);
	//o.col = HSV(i.distEstimate, ray.dist, 1);//i.distEstimate/2.0;// TESTING
	#ifdef VERTEX_DEBUG_COLORS
	o.col.g = o.col.w;
	o.col.w = 1;
	o.col.r = 0.5/i.distEstimate;
	#endif

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
    float3 n = sdf(vPos) - float3(
            sdf(vPos - e.xyy),
            sdf(vPos - e.yxy),
            sdf(vPos - e.yyx));
    return normalize(n);
}
//gets normal, provided you have the distance for pos (1 less call to scene())
inline float3 getNorm(float3 vPos, float fPointDist, float fEpsilon = 0.001)
{
    ////if epilon is smaller than 0.001, there are often artifacts
    const float2 e = float2(fEpsilon, 0);
    float3 n = fPointDist - float3(
            sdf(vPos - e.xyy),
            sdf(vPos - e.yxy),
            sdf(vPos - e.yyx));
    return normalize(n);
}

//marches a ray through the scene once
rayData castRay(float3 vRayStart, float3 vRayDir, float startDist)
{
    float fRayLen = startDist;//startDist;// total distance marched / distance from camera

    float3 vPos;
	float dist;

    rayData ray;
	ray.bMissed = false;
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
        dist = sdf(vPos);

        #ifdef USE_DYNAMIC_QUALITY
        if (abs(dist) < _SurfDist) break;
        #else
        //if (abs(dist) < SURF_DIST) break;
        if (abs(dist) < (fRayLen * 0.0003)) break; //TESTING 8k
        //if (abs(dist) < (fRayLen * 0.0005)) break; //TESTING 1080p
        #endif

        fRayLen += dist;// move forward

        if (ray.minDist>dist) 
        {
            ray.minDist = dist;
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
    ray.mat    = calcMaterial(vPos);//sdf_data.mat;
    ray.vHit   = vPos;
	#ifdef CALC_NORM
    //ray.vNorm  = getNorm(vPos, dist);
	#endif
    return ray;
}

#endif

// start at vertex? 
// increase surfacedist with length?
// very simple lower estimate for length of ray.
float castRayEstimate(in float3 vRayStart, const float3 vDir, const int iSteps, const float fMaxDist, const float fSurfaceDist, const float fStartLength, const float fSurfaceDistPerMetre)
{
	float fRayLen = fStartLength;
	for(int i = 0; i<iSteps; i++)
	{
		float3 vPos = vRayStart + vDir*fRayLen;
        float dist = sdf(vPos);
		if (abs(dist) < (fSurfaceDist+fSurfaceDistPerMetre*fRayLen)) break;
        fRayLen += dist;
		if (fRayLen>fMaxDist) break;
	}
	return fRayLen;
}
