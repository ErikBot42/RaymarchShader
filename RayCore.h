#ifndef RAYCORE_H
#define RAYCORE_H

typedef struct rayCoreCastRayOut
{
    float dist; // dist traveled from ro
    float tol; // last tolerance for raymarch, (0 for raytrace)
    float AOfactor; // approximation for AO
    bool missed;
} rayCoreCastRayOut_t;

// runs ray cast functions depending if running in raymarch/trace mode.
rayCoreCastRayOut_t rayCoreCastRay(
        vec3 ro,
        vec3 rd,
        float totalDist     // current total dist from all bounces to ro
        float startDist,    // initial dist safe to move from ro
        float maxDist,      // max dist relative to ro
);

#endif
