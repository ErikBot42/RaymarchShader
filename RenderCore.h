
#ifndef RENDERCORE_H
#define RENDERCORE_H


// TODO: move this to a "definitions" header
typedef float3 vec3; 
typedef fixed3 col3;

//typedef int integer;
//typedef float3 vec3;
//typedef fixed3 col3;
//

struct rendererCalculateColorOut_t
{
    col3 col;
    vec3 hitPos; // for z buffer
};

// public: wrapper for psudorecursive
rendererCalculateColorOut_t rendererCalculateColor(vec3 ro, vec3 rd, float startDist, int numLevels);

// private:


// iteration

// input and output for render iteration
struct rendererIterationData_t
{
    col3 sumCol;       // IO 
    col3 prodCol;      // IO 
    float totalDist;   // IO
    vec3 ro;           // IO
    vec3 rd;           // IO
    bool missed;       // out
    bool firstBounce;  // IO
    // ...
};


rendererIterationData_t rendererIteration(rendererIterationData_t i);
rendererCalculateColorOut_t rendererCalculateColor_it(rendererIterationData_t data, int numLevels);

vec3 rendererGetBRDFRay(vec3 rd, vec3 nor, material mat);

#endif
