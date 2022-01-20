#ifndef RENDERCORE_C
#define RENDERCORE_C
#include "RenderCore.h"
#include "SceneCore.cginc"
#include "RayCore.cginc"

// core rendering, may only use conjunction of the syntax of h/glsl and c
// A consequence of this is that all functions become pure.
// Multiple outputs are done with structs.
// primitive values are only: int, float, bool
// wrapper for psudorecursive (manual tail recursion and virtual stack using registers)
// This is the public interface to the entire rendering process.
rendererCalculateColorOut_t rendererCalculateColor(vec3 ro, vec3 rd, float startDist, int numLevels)
{
    #ifdef RENDER_WITH_GI
    numLevels = 5;
    #else
    numLevels = 1;
    #endif
    
    sceneTransformCameraOut_t cam = sceneTransformCamera(ro, rd);
    ro = cam.ro;
    rd = cam.rd;

    rendererIterationData_t data;
    data.sumCol = 0;
    data.prodCol = 1;
    data.totalDist = startDist;
    data.ro = ro;
    data.rd = rd;
    data.missed = false;
    data.firstBounce= true;

    return rendererCalculateColor_it(data, numLevels);
}

rendererIterationData_t rendererIteration(rendererIterationData_t i)
{
    sceneEstimateHitOut_t eh = SceneEstimateHit(i.ro, i.rd);
    eh.startDist = 0;
    eh.maxDist = MAX_DIST;
    eh.hit = true;
    //float startDist = eh.startDist; //distance ray can safetly start at
    //float maxDist = eh.maxDist; //distance ray can safetly end at

    rayCoreCastRayOut_t ray;
    if (eh.hit)
    {
        ray = rayCoreCastRay(i.ro, i.rd, i.totalDist, eh.startDist, eh.maxDist);
        //TODO: fake last reflection
    }
    else
    {
        i.prodCol   *= .5;
        ray.dist     = 0;
        ray.missed  = true;
    }
    i.totalDist   += ray.dist + eh.startDist;
    i.missed       = ray.missed;

    vec3 startPos  = i.ro + i.rd*eh.startDist;
    vec3 pos;
    if (!ray.missed) pos = ray.ro;
    else             pos = i.ro + eh.maxDist*i.rd;

    col3 dcol; // direct incoming light for this point

    [flatten] if (ray.missed)
    {
        //i.prodCol=fixed3(.5,.5,.7);
        dcol = worldGetBackground(ray.rd, 0); // missed = get background light
        if (i.firstBounce) dcol = pow(dcol, 2.2/1.0);//inverse gamma correction
        i.ro = pos;
        //dcol = 0;
        //i.sumCol += i.prodCol*dcol;

        // apply fog
        //i.sumCol = sceneApplyFog(startPos, pos, i.sumCol);
        //return i;
    }
    else
    {

        //TODO: ray abstraction
        float tol       = ray.tol;
        float3 nor      = ray.nor;
        float fAOfactor = ray.AOfactor;


        //TODO: material abstraction
        material mat = calcMaterial(pos, sdf(pos).yzw, tol/*dot(nor, i.rd)*/);
        col3 surfCol = mat.col.rgb;

        dcol  = worldApplyLighting(pos, i.rd, nor, fAOfactor);
        dcol += mat.emmision;


        i.rd = rendererGetBRDFRay(i.rd, nor, mat);
        i.ro = pos + nor*TOLERANCE(i.totalDist-eh.startDist)*2.5;

        i.prodCol *= surfCol;
    }
    i.sumCol  += i.prodCol*dcol;

    // apply fog
    i.sumCol   = sceneApplyFog(startPos, pos, i.sumCol);
    i.prodCol  = sceneApplyFog(startPos, pos, i.prodCol);
    i.firstBounce = false;
    return i;
}

// branchless path trace, iterative
rendererCalculateColorOut_t rendererCalculateColor_it(rendererIterationData_t data, int numLevels)
{
    rendererCalculateColorOut_t o;
    //o.col = worldGetBackgroundLocalSpace(data.rd);
    //return o;
    //sceneEstimateHitOut_t eh = SceneEstimateHit(data.ro, data.rd);
    vec3 oro = data.ro;// + eh.startDist*data.rd;
    vec3 ord = data.rd;

    for (int i = 0; i<numLevels; i++)
    {
        if (data.missed) break;// if the ray missed before this function.
        data = rendererIteration(data);
        if (i == 0) {
            o.hitPos = data.ro;
            if (data.missed)
            {
                discard;
                break;
            }

        }
    }

    o.col = data.sumCol;


    float distFirstBounce = length(o.hitPos-oro);

    
    //fixed4 fogCol = fixed4(1,0.05,1,1)*0.0;
    //o.col = lightFog(fixed4(o.col,1), fogCol, distFirstBounce, 0, MAX_DIST).xyz;
    
    // volumetrics
    #if 0
    // extinction (.1)
    o.col*=exp(-.5*distFirstBounce);


    col3 acc = 0;
    int samples = 10;
    float fogStrength = 2*16*1*.4;//.3;//*.1;
    //float fogStrength = 0.7/length(oro+ord*distFirstBounce);
    for (int i = 0; i<samples; i++)
    {
        // random point along ray path
        // 
        float t = distFirstBounce*frand();

        //acc += worldApplyLighting(oro+distFirstBounce*ord, ord, ord, 0);
        float3 pos = oro+t*ord;
        //float fogStrength = pow(max(0,-pos.y+.2),1.7)*3;
        //float fogStrength = 0.01/length(pos);
        acc += fogStrength*worldApplyLighting(pos, ord, ord, 0, false);
        //acc += 1*worldApplyLighting(pos, ord, ord, 0);
    }
    //o.col += 0.1*(acc/samples)*distFirstBounce;
    // 0.06

    col3 sunCol = col3(237.0/255.0, 213.0/255.0, 158.0/255.0);
    col3 fogCol = col3(1,.2,1);
    
    acc/=samples;
    //acc-=sunCol*.025;
    acc-=normalize(acc)*0.06/fogStrength;
    //acc-=normalize(acc)*0.1/fogStrength;
    acc.x = max(acc.x,0);
    acc.y = max(acc.y,0);
    acc.z = max(acc.z,0);
    //acc*=fogCol;
    o.col += 1*acc*distFirstBounce;
    #endif

	//o.col = pow(o.col, 1.0/2.2);//gamma correction
    //o.col = frand()*distFirstBounce;
    return o;
}



// TODO: Toggleable BRDF using material properties
vec3 rendererGetBRDFRay(vec3 rd, vec3 nor, material mat)
{
    return worldGetBRDFRay(rd, rd, nor);
}



#endif
