#ifndef SDFMATH_CGINC
#define SDFMATH_CGINC

#include "RayMarchLib.h"

//////////////////////////////////////////////////////////////////////
//
// Interpolation and Math
//
//////////////////////////////////////////////////////////////////////


//soft min of a and b with smoothing factor k
inline float smin(float a, float b, float k) 
{
    float h = max(k - abs(a-b), 0) / k;
    return min(a, b) - h*h*h*k * 1/6.0;
}

//soft max of a and b with smoothing factor k 
inline float smax(float a, float b, float k) 
{
    float h = max(k - abs(a - b), 0) / k;
    return max(a, b) + h*h*h*k * 1/6.0;
}

//interpolate between the colours of 2 SDFs
inline material mixMat(sdfData sdfA, sdfData sdfB)
{
    material m;
    float fac = clamp(sdfA.dist/(sdfA.dist + sdfB.dist), 0, 1);
    m.col = lerp(sdfA.mat.col, sdfB.mat.col, fac);
    m.fRough = lerp(sdfA.mat.fRough, sdfB.mat.fRough, fac);
    return m;
}

//interpolate between the colours of 2 SDFs
inline material mixMat(material a, material b, float fac)
{
    material m;
    m.col = lerp(a.col, b.col, fac);
    m.fRough = lerp(a.fRough, b.fRough, fac);
    return m;
}

//////////////////////////////////////////////////////////////////////
//
// SDF operations
//
//////////////////////////////////////////////////////////////////////


//union of SDF A and B
sdfData sdfAdd(float3 p, sdfData sA, sdfData sB)
{
    sdfData sC;
    sC.dist = min(sA.dist, sB.dist);
    sC.mat = mixMat(sA, sB);
    return sC;
}

//union of SDF A and B, with smoothing
sdfData sdfAdd(float3 p, sdfData sA, sdfData sB, float fSmooth)
{
    sdfData sC;
    sC.dist = smin(sA.dist, sB.dist, fSmooth);
    sC.mat = mixMat(sA, sB);
    return sC;
}

//remove the SDF B from A (colour is from A)
sdfData sdfSub(float3 p, sdfData sA, sdfData sB)
{
    sdfData sC;
    sC.dist = max(sA.dist, -sB.dist);
    sC.mat = sA.mat;
    return sC;
}

//remove the SDF B from A (colour is from A), with smoothing
sdfData sdfSub(float3 p, sdfData sA, sdfData sB, float fSmooth)
{
    sdfData sC;
    sC.dist = smax(sA.dist, -sB.dist, fSmooth);
    sC.mat = sA.mat;
    return sC;
}

//intersection of SDF A and B
sdfData sdfInter(float3 p, sdfData sA, sdfData sB)
{
    sdfData sC;
    sC.dist = max(sA.dist, sB.dist);
    sC.mat = mixMat(sA, sB);
    return sC;
}

//intersection of SDF A and B, with smoothing
sdfData sdfInter(float3 p, sdfData sA, sdfData sB, float fSmooth)
{
    sdfData sC;
    sC.dist = smax(sA.dist, sB.dist, fSmooth);
    sC.mat = mixMat(sA, sB);
    return sC;
}

//round edges of an SDF
sdfData sdfRound(float3 p, sdfData sdfIn, float fRadius)
{
    sdfData sdfOut = sdfIn;
    sdfOut.dist -= fRadius;
    return sdfOut;
}

//////////////////////////////////////////////////////////////////////
//
// Color transform
//
//////////////////////////////////////////////////////////////////////

fixed4 HSV (fixed h, fixed s, fixed v)
{
    h *= 6;
    fixed c = s * v;
    float x = c * (1 - abs(fmod(h, 2) - 1));
    float m = v-c;
    c += m;
    x += m;

    fixed4 colors[6] = {
        fixed4(c, x, m, 1),
        fixed4(x, c, m, 1),
        fixed4(m, c, x, 1),
        fixed4(m, x, c, 1),
        fixed4(x, m, c, 1),
        fixed4(c, m, x, 1)};

    return colors[int(h)];
}

#endif
