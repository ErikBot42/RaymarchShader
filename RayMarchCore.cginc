#ifndef RAYMARCHCORE_C
#define RAYMARCHCORE_C

rayCoreCastRayOut_t rayCoreCastRay(vec3 ro, vec3 rd, float totalDist, float startDist, float maxDist)
{
    rayCoreCastRayOut_t out;
    rayDataMinimal ray = castRayMinimal(ro, rd, startDist, totalDist-startDist, maxDist);
}

#endif
