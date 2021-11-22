#ifndef SCENECORE_H
#define SCENECORE_H
#include "RenderCore.h"
// defines a scene

// sdf
// worldgetlighting

// fast function to get upper bound for 
// dist and to check if it is likely 
// that the main object is hit
typedef struct sceneEstimateHitOut
{
    bool hit;
    float startDist;
    float maxDist;
} sceneEstimateHitOut_t;

sceneEstimateHitOut_t SceneEstimateHit(vec3 ro, vec3 rd);


#endif
