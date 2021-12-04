#ifndef RENDERCORE_C
#define RENDERCORE_C
#include "RenderCore.h"
#include "SceneCore.cginc"

// core rendering, may only use conjunction of the syntax of h/glsl and c
// A consequence of this is that all functions become pure.
// Multiple outputs are done with structs.
// primitive values are only: int, float, bool


// wrapper for psudorecursive (manual tail recursion and virtual stack using registers)
// This is the public interface to the entire rendering process.
rendererCalculateColorOut_t rendererCalculateColor(vec3 ro, vec3 rd, float startDist, int numLevels)
{
    numLevels = 1;
    rendererIterationData_t data;
    data.sumCol = 0;
    data.prodCol = 1;
    data.totalDist = startDist;
    data.ro = ro;
    data.rd = rd;
    data.missed = false;
    data.discardOnMiss = true;

    return rendererCalculateColor_it(data, numLevels);
}

rendererIterationData_t rendererIteration(rendererIterationData_t i)
{
    sceneEstimateHitOut_t eh = SceneEstimateHit(i.ro, i.rd);
    float startDist = eh.startDist; //distance ray can safetly start at
    float maxDist = eh.maxDist; //distance ray can safetly end at
    //rayDataMinimal ray = castRayMinimal(i.ro, i.rd, startDist, i.totalDist-startDist, maxDist);

    rayDataMinimal ray;
    if (eh.hit)
    {
        //ray = castRayMinimal(i.ro, i.rd, eh.startDist, i.totalDist-eh.maxDist);
        ray = castRayMinimal(i.ro, i.rd, startDist, i.totalDist-startDist, maxDist);
        //TODO: ray abstraction
        //TODO: interpret when the last iteration occurs
        //if (true)
        //{
        // Actual raymarch
        //}
        //else
        //{
        //    // Fake last reflection
        //    //i.prodCol   *= .5;
        //    ray.dist     = 0;
        //    ray.bMissed  = true;
        //}
    }
    else
    {
        i.prodCol   *= .5;
        ray.dist     = 0;
        ray.bMissed  = true;
    }
    i.totalDist += ray.dist + eh.startDist;
    i.missed     = ray.bMissed;

    vec3 pos     = i.ro + ray.dist*i.rd;
    col3 dcol; // direct incoming light for this point

    [flatten] if (ray.bMissed)
    {
        //i.prodCol=fixed3(.5,.5,.7);
        dcol = worldGetBackground(i.rd, 0); // missed = get background light
        //dcol = 0;
        i.sumCol += i.prodCol*dcol;
        return i;
    }

    //TODO: ray abstraction
    float tol        = ray.fLastTolerance;
    float3 nor         = getNormFull(pos, tol);
    //ray.iSteps = 30;
    //float fAOfactor  = smoothSSAO(ray.iSteps, MAX_STEPS, ray.fLastDist, ray.fLastTolerance, 100);
    float fAOfactor  = smoothSSAO(ray.iSteps, MAX_STEPS, ray.fLastDist, ray.fLastTolerance, 100);

	//dcol = 1;//saturate(dot(i.rd, nor))*(0.003/(length(pos)*length(pos)));
    dcol             = worldApplyLighting(pos, i.rd, nor, fAOfactor);//ray.iSteps>10 ? 1 : 0;//0.01/length(pos);//

    //TODO: material abstraction
    // TODO: sumcol += emmision
    material mat      = calcMaterial(pos, sdf(pos).yzw);
    col3 surfCol      = mat.col.rgb;

    //surfCol = 1-fAOfactor;//ray.iSteps/(float)MAX_STEPS;;//dot(nor, float3(0,1,0));//sin(pos*100);
    //surfCol.r*=2;
    //surfCol*=.5;


    i.rd              = reflect(i.rd,nor);//rendererGetBRDFRay(i.rd, nor, mat);
    //i.ro            = pos + nor*tol*2.5; // TODO: make better
    i.ro = pos + nor*TOLERANCE(i.totalDist-eh.startDist)*2.5; 

    i.prodCol       *= surfCol;

    i.sumCol += i.prodCol*dcol;
    //i.sumCol = fixed3(1,1,1);
    //i.prodCol = fixed3(1,1,1);
    return i;
}

// branchless path trace, iterative
rendererCalculateColorOut_t rendererCalculateColor_it(rendererIterationData_t data, int numLevels)
{
    rendererCalculateColorOut_t o;
    //o.col = worldGetBackgroundLocalSpace(data.rd);
    //return o;
    for (int i = 0; i<numLevels; i++)
    {
        if (data.missed) break;// if the ray missed before this function.
        data = rendererIteration(data);
        if (i == 0) {
            o.hitPos = data.ro;
            if (data.missed)
            {
                discard;
                o.col = data.sumCol;
                return o;
            }

        }
    }

    o.col = data.sumCol;
	//o.col = pow(o.col, 1.0/2.2);//gamma correction
    return o;
}



// TODO: Toggleable BRDF using material properties
vec3 rendererGetBRDFRay(vec3 rd, vec3 nor, material mat)
{
    return worldGetBRDFRay(rd, rd, nor);
}



#endif
