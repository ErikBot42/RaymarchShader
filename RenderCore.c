#ifndef RENDERCORE_C
#define RENDERCORE_C
#include "RenderCore.h"

// core rendering, may only use conjunction of the syntax of h/glsl and c
// A consequence of this is that all functions become pure.
// Multiple outputs are done with structs.
// primitive values are only: int, float, bool


// wrapper for psudorecursive (manual tail recursion and virtual stack using registers)
rendererCalculateColorOut_t rendererCalculateColor(vec3 ro, vec3 rd, float startDist, int numLevels)
{
    //rendererCalculateColorOut_t out;
    //return out;
}


rendererIterationData_t rendrerIteration(rendererIterationOut_t i)
{
    sceneEstimateHitOut_t eh = SceneEstimateHit(i.ro, i.rd);
    
    rayDataMinimal ray;
    if (eh.hit)
    {
        //TODO: ray abstraction
        if (true)
        {
            // Actual raymarch
            ray = castRayMinimal(i.ro, i.rd, eh.startDist, i.totalDist-eh.maxDist);
        }
        else
        {
            // Fake last reflection
            prodCol*=.5;
            ray.dist=0;
            ray.bMissed=true;
        }
    }
    else
    {
        ray.dist=0;
        ray.bMissed=true
    }
    vec3 pos = i.ro + ray.dist*i.rd;
    //TODO: material abstraction
    material mat = calcMaterial(pos);
    col3 dcol;

    if (ray.bMissed)
    {
        //TODO: FINISH 
    }

    
    // TODO: move these to separate file.
    
}



#endif
