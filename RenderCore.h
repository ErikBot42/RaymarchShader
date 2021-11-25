
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
    vec3 hitPos;
} rendererCalculateColorOut_t;



// public: wrapper for psudorecursive
rendererCalculateColorOut_t rendererCalculateColor(vec3 ro, vec3 rd, float startDist, int numLevels);


// iteration
// sumcol, prodcol, currentdist(for tolerance/fog), ro, rd, numlevels
// sumcol, prodcol, currentdist(for tolerance/fog), ro, rd, numlevels

// input and output for render iteration
typedef struct rendererIterationData
{
    col3 sumCol;     // IO 
    col3 prodCol;    // IO 
    float totalDist; // IO
    vec3 ro;         // IO
    vec3 rd;         // IO
    bool missed;     // out
    int numLevels;   // meta
    // struct extradata
} rendererIterationData_t;


rendererIterationData_t rendrerIteration(rendererIterationOut_t i);


#endif
