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
#ifndef NUM_LIGHTS
#define NUM_LIGHTS 1
#endif
struct light_t
{
    col3 col;
    vec3 dir;
    float dist; // dist to light
    float intensity; // intensity fac, negative will disable
    bool real; // use actual calc instead of estimate
};

//TODO calc lights

col3 sceneApplyLighting(vec3 ro, vec3 rd, vec3 nor, float AOfactor, bool shaded = true);

col3 sceneApplyFog(vec3 ro, vec3 rd, col3 original);

sceneEstimateHitOut_t SceneEstimateHit(vec3 ro, vec3 rd);

vec3 sceneGetBRDFRay(vec3 rd, vec3 nor, material mat);


typedef struct sceneTransformCameraOut
{
    vec3 ro;
    vec3 rd;
} sceneTransformCameraOut_t;


sceneTransformCameraOut_t sceneTransformCamera(vec3 ro, vec3 rd);
sceneTransformCameraOut_t sceneInverseTransformCamera(vec3 ro, vec3 rd);

light_t[NUM_LIGHTS] sceneGetLights();

#endif
