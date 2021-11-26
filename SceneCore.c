#ifndef SCENECORE_C
#define SCENECORE_C
sceneEstimateHitOut_t SceneEstimateHit(vec3 ro, vec3 rd)
{
    sceneEstimateHitOut_t eh;
    eh.hit = true;
    eh.startDist = 0;
    eh.maxDist = 1000;
    return eh;
}

sceneGetBRDFRay(vec3 rd, vec3 nor, material mat)
{
    return reflect(rd, nor); 
}


#endif
