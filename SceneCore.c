#ifndef SCENECORE_C
#define SCENECORE_C
#include "SceneCore.h"
sceneEstimateHitOut_t SceneEstimateHit(vec3 ro, vec3 rd)
{
    sceneEstimateHitOut_t eh;
    //eh.hit = true;
    //eh.startDist = 0;
    //eh.maxDist = 1000;
    
    eh.hit = RayTraceSphere(eh.startDist, eh.maxDist, ro, rd, .5, 0);
    return eh;
}

vec3 sceneGetBRDFRay(vec3 rd, vec3 nor, material mat)
{
    return reflect(rd, nor); 
}


#endif
