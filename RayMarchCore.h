#ifndef RAYMARCHCORE_H
#define RAYMARCHCORE_H
#include "RenderCore.h"

struct rayMarchOut_t
{
    float dist;
    float tol;
    bool missed;
    float steps;
    vec3 ro;
    vec3 rd;
};

#endif
