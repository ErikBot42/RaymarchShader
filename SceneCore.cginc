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
col3 sceneApplyFog(vec3 ro, vec3 rd, col3 original)
{
    //return original;
    float fogAmount = (fogAmountAtPos(ro) + fogAmountAtPos(rd))/2;
    return blendColor(original, col3(1,1,1)*0.1, fogAmount*length(ro-rd), 0, 2).rgb;
}



#endif
