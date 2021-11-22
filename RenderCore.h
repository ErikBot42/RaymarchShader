
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



// wrapper for psudorecursive
rendererCalculateColorOut_t rendererCalculateColor(vec3 ro, vec3 rd, float startDist, int numLevels);


// iteration
// sumcol, prodcol, currentdist(for tolerance/fog), ro, rd, numlevels
// sumcol, prodcol, currentdist(for tolerance/fog), ro, rd, numlevels


typedef struct rendererIterationOut
{
    col3 sumCol;
    vec3 hitPos;
} rendererIterationOut_t;


rendererIterationOut_t rendrerIteration(rendererIterationOut_t i);


#endif
