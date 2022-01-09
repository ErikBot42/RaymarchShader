#ifndef RAYMARCHCORE_C
#define RAYMARCHCORE_C
#include "RayMarchCore.h"

rayMarchOut_t rayCoreCastRay_0(vec3 ro, vec3 rd, float totalDist, float startDist, float maxDist)
{
    rayMarchOut_t o;
    int i;
    float t = startDist;
    float tol = 1;
    float lastDist = 0;
    float h = 0;

    for (int i = 0; i<MAX_STEPS && t<maxDist; i++)
    {
        h = sdf(ro + rd*t).x;
        t+=h;
        tol = TOLERANCE(t + totalDist);
        if (abs(h)<tol) break;
    }

    o.dist = t;
    o.tol = tol;
    o.missed = !(t<maxDist);
    o.steps = i + h/tol;

    o.ro = ro + o.dist*rd;
    o.rd = rd;
    return o;
}



rayMarchOut_t rayCoreCastRay_1(vec3 ro, vec3 rd, float totalDist, float startDist, float maxDist)
{
    rayMarchOut_t o;
    int i;
    float t = startDist;
    float tol = 1;
    float lastDist = 0;
    float h = 0;
    
    // variable during the iteration
    vec3 pos = ro + rd*t;
    vec3 dir = rd;

    for (int i = 0; i<MAX_STEPS && t<maxDist; i++)
    {
        h = sdf(pos).x;
        t+=h;
        
        // 1 = c
        int timesteps = 10;
        vec3 F;
        float mass = -0.1*(1+_SinTime.y);
        float timestep = h/timesteps;
        for (int j = 0; j<timesteps; j++)
        {
            vec3 r = pos - vec3(0,0,0);
            vec3 r2 = dot(r,r);
            F = timestep*mass*normalize(r)/r2;

            dir = normalize(F + dir);
            pos += dir*timestep;
        }
        //if (length(F)/timestep>6) {t=maxDist;break;}


        tol = TOLERANCE(t + totalDist);
        if (abs(h)<tol) break;
    }

    o.dist = t;
    o.tol = tol;
    o.missed = !(t<maxDist);
    o.steps = i + h/tol;

    o.ro = pos + h*dir;
    o.rd = dir;
    return o;
}


rayCoreCastRayOut_t rayCoreCastRay(vec3 ro, vec3 rd, float totalDist, float startDist, float maxDist)
{
    rayCoreCastRayOut_t o;
    
    rayMarchOut_t r = rayCoreCastRay_1(ro, rd, totalDist, startDist, maxDist);
    o.dist = r.dist;
    o.tol = r.tol;
    o.rd = r.rd;
    o.ro = r.ro;

    //TODO: add alternative for other AO models
    o.AOfactor = smoothSSAO(r.steps, MAX_STEPS, 0, 1, 20);
    o.missed = r.missed;
    if (!o.missed)
    {
        o.nor = getNormFull(o.ro, o.tol);
    }

    return o;
}


#endif
