
#ifndef RENDERCORE_H
#define RENDERCORE_H
typedef float3 vec3; 
typedef fixed3 col3;

//typedef int integer;
//typedef float3 vec3;
//typedef fixed3 col3;
//
typedef struct rendererCalculateColorOut
{
    col3 col;
    vec3 hitPos; // for z buffer
} rendererCalculateColorOut_t;

// public: wrapper for psudorecursive
rendererCalculateColorOut_t rendererCalculateColor(vec3 ro, vec3 rd, float startDist, int numLevels);


// iteration

// input and output for render iteration
typedef struct rendererIterationData
{
    col3 sumCol;     // IO 
    col3 prodCol;    // IO 
    float totalDist; // IO
    vec3 ro;         // IO
    vec3 rd;         // IO
    bool missed;     // out
    // struct extradata
} rendererIterationData_t;


rendererIterationData_t rendrerIteration(rendererIterationOut_t i);

vec3 rendererGetBRDFRay(vec3 rd, vec3 nor, material mat);

#endif
