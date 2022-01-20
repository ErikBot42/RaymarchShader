#ifndef SCENECORE_C
#define SCENECORE_C
#include "SceneCore.h"
sceneEstimateHitOut_t SceneEstimateHit(vec3 ro, vec3 rd)
{
    sceneEstimateHitOut_t eh;
    //eh.hit = true;
    //eh.startDist = 0;
    //eh.maxDist = 1000;

    float startDist = 0;
    float maxDist = 0;

    eh.hit = RayTraceSphere(startDist, maxDist, ro, rd, .5, 0);

    eh.startDist = startDist;
    eh.maxDist = maxDist;
    return eh;
}

vec3 sceneGetBRDFRay(vec3 rd, vec3 nor, material mat)
{
    return reflect(rd, nor); 
}


float fogAmountAtPos(vec3 ro)
{
    return 1;//max(0,-ro.y*3+.3);
}

col3 blendColor(col3 startCol, col3 endCol, float curr, float start, float end)
{
    if (curr < start) return startCol;
    if (curr > end) return endCol;
    return lerp(startCol, endCol, smoothstep(start, end, curr));
}

// rd is end POINT
// apply fog assuming fog gradient is linear.
col3 sceneApplyFogLinear(vec3 ro, vec3 rd, col3 original, col3 fogCol)
{
    float fogAmount = length(ro-rd)*(fogAmountAtPos(ro) + fogAmountAtPos(rd))/2;
    return blendColor(original, fogCol, fogAmount, 0, 3).rgb;
}

// my random attempt at making volumetrics (will probably look bad)
col3 sceneApplyFogVolumetric(vec3 ro, vec3 rd, col3 original, col3 fogCol)
{
    float fogAmount = length(ro-rd)*(fogAmountAtPos(ro) + fogAmountAtPos(rd))/2;

    float3 mid = (ro+rd)/2;
    float3 dir = normalize(rd-ro);

    fogCol*=worldApplyLighting(mid, dir, -dir, 0).rgb*80;
    return blendColor(original, fogCol, fogAmount, 0, 3).rgb;
}

col3 sceneApplyFog(vec3 ro, vec3 rd, col3 original)
{
    col3 fogCol = col3(1,.7,.9)*.1;
#if 1
    return original;
#elif 0
    return sceneApplyFogLinear(ro, rd, original, fogCol);
#elif 0
    return sceneApplyFogVolumetric(ro, rd, original, fogCol);
#endif
}

#ifndef OVERRIDE_TRANSFORM_CAMERA
// function to transform the camera.
sceneTransformCameraOut_t sceneTransformCamera(vec3 ro, vec3 rd)
{
    sceneTransformCameraOut_t o;
    o.ro = ro;//rotY(ro, _Time.x*2);
    o.rd = rd;//rotY(rd, _Time.x*2);
    return o;
}

sceneTransformCameraOut_t sceneInverseTransformCamera(vec3 ro, vec3 rd)
{
    sceneTransformCameraOut_t o;
    o.ro = ro;//rotY(ro, _Time.x*2);
    o.rd = rd;//rotY(rd, _Time.x*2);
    return o;
}

#endif

#endif
