#ifndef RENDERCORE_C
#define RENDERCORE_C
#include "RenderCore.h"

// core rendering, may only use conjunction of the syntax of h/glsl and c
// A consequence of this is that all functions become pure.
// Multiple outputs are done with structs.
// primitive values are only: int, float, bool


// wrapper for psudorecursive (manual tail recursion and virtual stack using registers)
// This is the public interface to the entire rendering process.
rendererCalculateColorOut_t rendererCalculateColor(vec3 ro, vec3 rd, float startDist, int numLevels)
{
    rendererIterationData_t data;
    data.sumCol = 0;
    data.prodCol = 1;
    data.totalDist = startDist;
    data.ro = ro;
    data.rd = rd;
    data.missed = false;

    return rendererCalculateColor_it(data, numLevels);
}

// branchless path trace, iterative
rendererCalculateColorOut_t rendererCalculateColor_it(rendererIterationData_t data, int numLevels)
{
    rendererCalculateColorOut_t out;
    out.col = 0;
    out.hitPos = 0;

    for (int i = 0; i<numLevels; i++)
    {
        if (data.missed) break;// if the ray missed before this function.
        data = rendererIteration(data);
        if (i == 0) out.hitPos = data.ro; 
    }

    out.col = data.sumCol;
    return out;
}


rendererIterationData_t rendrerIteration(rendererIterationOut_t i)
{
    sceneEstimateHitOut_t eh = SceneEstimateHit(i.ro, i.rd);
    float startDist          = eh.startDist;// distance ray can safetly start at
    float maxDist            = eh.maxDist;// distance ray can safetly end at

    rayDataMinimal ray;
    if (eh.hit)
    {
        //TODO: ray abstraction
        //TODO: interpret when the last iteration occurs
        if (true)
        {
            // Actual raymarch
            ray = castRayMinimal(i.ro, i.rd, eh.startDist, i.totalDist-eh.maxDist);
        }
        else
        {
            // Fake last reflection
            i.prodCol   *= .5;
            ray.dist     = 0;
            ray.bMissed  = true;
        }
    }
    else
    {
        ray.dist    = 0;
        ray.bMissed = true
    }
    i.totalDist += ray.dist + eh.startDist;
    i.missed     = ray.bMissed;

    vec3 pos     = i.ro + ray.dist*i.rd;
    col3 dcol; // direct incoming light for this point

    if (ray.bMissed)
    {
        dcol = worldGetBackground(rd); // missed = get background light
        // if <iterations> == 0 then discard; // non portable and optional
    }
    else
    {

        //TODO: ray abstraction
        float tol        = ray.fLastTolerance;
        vec3 nor         = getNormFull(pos, tol);
        float fAOfactor  = smoothSSAO(ray.iSteps, MAX_STEPS, ray.fLastDist, ray.fLastTolerance, 100);
        dcol             = worldApplyLighting(pos, rd, nor, fAOfactor);

        //TODO: material abstraction
        // TODO: sumcol += emmision
        material mat     = calcMaterial(pos, sdf(pos).yzw);
        col surfCol      = mat.col.rgb;


        i.rd             = rendererGetBRDFRay(i.ro, i.rd, nor, mat);
        i.ro             = pos + nor*tol*2.5; // TODO: make better

        i.prodCol       *= surfCol;
    } 
    i.sumCol += i.prodCol*dcol;
}

// TODO: Toggleable BRDF using material properties
rendererGetBRDFRay(vec3 rd, vec3 nor, material mat, bool simple)
{
    if (simple) return reflect(rd, nor);
    else return reflect(rd, nor);
}



#endif
