#ifndef SDFFUNCTIONS_CGINC
#define SDFFUNCTIONS_CGINC

#include "Transforms.cginc"
#include "FastMath.cginc"

//////////////////////////////////////////////////////////////////////
//
// SDF basic shapes
//
//////////////////////////////////////////////////////////////////////

//create sphere
sdfData sdfSphere(float3 p, float fRadius, material mat = DEFMAT)
{
    sdfData sdf;
    sdf.dist = length(p) - fRadius;
    sdf.mat = mat;
    return sdf;
}

//create plane pointing to positive Y
sdfData sdfPlane(float3 p, float fHeight, material mat = DEFMAT)
{
    sdfData sdf;
    sdf.dist = p.y - fHeight;
    sdf.mat = mat;
    return sdf;
}

//create plane with normal
sdfData sdfPlane(float3 p, float3 vNorm, float fHeight, material mat = DEFMAT)
{
    sdfData sdf;
    sdf.dist = dot(p, normalize(vNorm)) - fHeight;
    sdf.mat = mat;
    return sdf;
}

//create cuboid
sdfData sdfBox(float3 p, float3 vDim, material mat = DEFMAT)
{
    sdfData sdf;
    float3 q = abs(p) - vDim/2.0;
    sdf.dist = length(max(q, 0)) + min(max(q.x, max(q.y, q.z)), 0);
    sdf.mat = mat;
    return sdf;
}

//create cuboid
sdfData sdfBox(float3 p, float3 vDim, float fRound, material mat = DEFMAT)
{
    sdfData sdf;
    float3 q = abs(p) - vDim/2.0;
    sdf.dist = length(max(q, 0)) + min(max(q.x, max(q.y, q.z)), 0) - fRound;
    sdf.mat = mat;
    return sdf;
}

//create line segment
sdfData sdfLine(float3 p, float3 vStart, float3 vEnd, float fRadius, material mat = DEFMAT)
{
    sdfData sdf;
    float h = min(1, max(0, dot(p-vStart, vEnd-vStart) / dot(vEnd-vStart, vEnd-vStart)));
    sdf.dist = length(p-vStart-(vEnd-vStart)*h)-fRadius;
    sdf.mat = mat;
    return sdf;
}

//create cylinder
sdfData sdfCylinder(float3 p, float fRadius, float fHeight, material mat = DEFMAT)
{
    sdfData sdf;
    sdf.dist = max(abs(p.y) - fHeight/2.0, length(p.xz) - fRadius);
    sdf.mat = mat;
    return sdf;
}

//create cylinder
sdfData sdfCylinder(float3 p, float fRadius, float fHeight, float fRound, material mat = DEFMAT)
{
    sdfData sdf;
    sdf.dist = max(abs(p.y) - fHeight/2.0, length(p.xz) - fRadius) - fRound;
    sdf.mat = mat;
    return sdf;
}

//create torus
sdfData sdfTorus(float3 p, float fRadius, float fThickness, material mat = DEFMAT)
{
    sdfData sdf;
    float2 q = float2(length(p.xz) - fRadius, p.y);
    sdf.dist = length(q) - fThickness;
    sdf.mat = mat;
    return sdf;
}

//triangular prism (BOUND)
sdfData sdfTriPrism(float3 p, float fSide, float fDepth, material mat = DEFMAT)
{
    float3 q = abs(p);
    sdfData sdf;
    sdf.dist = max(q.z - fDepth, max(q.x * 0.866025 + p.y * 0.5, -p.y) - fSide * 0.5);
    sdf.mat = mat;
    return sdf;
}


//////////////////////////////////////////////////////////////////////
//
// Fractals, complex shapes and scenes  (frac prefix)
//
//////////////////////////////////////////////////////////////////////

//TODO: 
// complex :julia, 
// simple sierpinsky, menger

// Mandelbolb - OPTIMIZED AF, still a fractal but visually diffrent.
sdfData fracMandelbolb(float3 p, material mat = DEFMAT)
{
    // http://blog.hvidtfeldts.net/index.php/2011/09/distance-estimated-3d-fractals-v-the-mandelbulb-different-de-approximations/
    float3 pos;
    pos.x = p.x;
    pos.y = p.y;
    pos.z = p.z;

    float dr = 1.0;
    float r = 0;

    const int iterations = 4;

    const float maxRThreshold = 2;//2;

    const float Power = 16;
    for (int i = 0; i < iterations; i++)
    {
        r = length(p);
        if (r>maxRThreshold) break;

        // xyz -> polar
        //float theta = acos( p.z / r );
        float theta = acosFast4( p.z / r );
        //float phi = atan2( p.y, p.x );
        float phi = atanFast4_2( p.y, p.x );
        dr = pow( r, Power-1.0)*Power*dr + 1.0;

        // transform point
        float zr = pow( r, Power );
        theta = theta * Power;
        phi = phi * Power;

        // polar -> xyz
        p = zr*float3(sin(theta)*cos(phi), sin(phi)*sin(theta), cos(theta));
        p += pos;
    }

    sdfData sdf;
    sdf.mat = mat;
    sdf.dist = 0.5*log(r)*r/dr;
    return sdf;
}

// Mandelbulb
sdfData fracMandelbulb(float3 p, material mat = DEFMAT)
{
    // http://blog.hvidtfeldts.net/index.php/2011/09/distance-estimated-3d-fractals-v-the-mandelbulb-different-de-approximations/
    float3 pos;
    pos.x = p.x;
    pos.y = p.y;
    pos.z = p.z;

    float dr = 1.0;
    float r = 0;

    // Lowest number of iterations without loosing a significant amount of detail
    // Depends on maxRThreshold
    //int iterations = 1;
    //int iterations = 8;
    const int iterations = 5;

    //float maxRThreshold = 2;
    const float maxRThreshold = 2;

    // Z_(n+1) = Z(n)^?
    // float Power = 8 + 6 * sin(_Time.x); 
    float Power = 8;
    for (int i = 0; i < iterations; i++)
    {
        r = length(p);
        if (r>maxRThreshold) break;

        // xyz -> polar
        float theta = acos( p.z / r );
        float phi = atan2( p.y, p.x );
        dr = pow( r, Power-1.0)*Power*dr + 1.0;

        // transform point
        float zr = pow( r, Power );
        theta = theta * Power;
        phi = phi * Power;

        // polar -> xyz
        p = zr*float3(sin(theta)*cos(phi), sin(phi)*sin(theta), cos(theta));
        p += pos;
        

    }

    sdfData sdf;
    sdf.mat = mat;
    //sdf.mat.col.y = sin(p.x);
    //sdf.dist = sdfSphere(pos, 10).dist;
    //sdf.mat = mat;
    sdf.dist = 0.5*log(r)*r/dr;
    //sdf.mat = mat;

    return sdf;
}

// Mandelbox
sdfData fracMandelbox(float3 p, float scaleFactor, material mat = DEFMAT)
{
    // http://blog.hvidtfeldts.net/index.php/2011/11/distance-estimated-3d-fractals-vi-the-mandelbox/

    float3 offset = p;
    float dr = 0;
   
    // Parameters
    int iterations = 8;//20;//14;
    //scaleFactor = -2 + (_SinTime.x*4+2);
    float fixedRadius = 1.0;
    float minRadius = 0.5;
    /*float foldingLimit = 0.2 + _SinTime.x/4 + 0.25;
    float minRadius = 0.07;
    float fixedRadius = 0.2;*/
    
    //float scaleFactor = -0.8;
    

    /*float foldingLimit = _FoldingLimit;
    float minRadius = _MinRadius;
    float fixedRadius = _FixedRadius;*/
    

    for(int i=0; i<iterations; i++)
    {
        boxFold(p, dr, 1);
        sphereFold(p, dr, minRadius, fixedRadius);

        p = scaleFactor*p + offset;
        //dr = dr*abs(scaleFactor)+1.0;
        dr = dr*abs(scaleFactor)+1;
    }

    sdfData sdf;
    sdf.mat = mat;

    float r = length(p);
    sdf.dist = r/abs(dr);
    return sdf;
}

// Mandelbox alternate implementation, possibly faster
sdfData fracMandelbox2(float3 p, float foldingLimit, float minRadius, float fixedRadius, float scaleFactor, material mat = DEFMAT)
{
    // http://www.fractalforums.com/3d-fractal-generation/a-mandelbox-distance-estimate-formula/
    float scale = -2;

    int iterations = 10;
    float DEfactor;
    for (int i = 0; i<iterations; i++)
    {
        DEfactor = scale;

        fixedRadius = 1.0;
        float fR2 = fixedRadius*fixedRadius;
        minRadius = 0.5;
        float mR2 = minRadius*minRadius;

        // Box fold?
        if (p.x > 1.0)
            p.x = 2.0 - p.x;
        else if (p.x < -1.0) p.x = -2.0 - p.x;
        if (p.y > 1.0)
            p.y = 2.0 - p.y;
        else if (p.y < -1.0) p.y = -2.0 - p.y;
        if (p.z > 1.0)
            p.z = 2.0 - p.z;
        else if (p.z < -1.0) p.z = -2.0 - p.z;

        // radius squared
        float r2 = dot(p,p);

        if (r2 < mR2)
        {
            p*=(fR2/mR2);
            DEfactor*=(fR2/mR2);
        }
        else if (r2 < fR2)
        {
            p*=(fR2/r2);
            DEfactor*=(fR2/r2);
        }
        p=p*scale+1;
        DEfactor*=scale;
    }

    sdfData sdf;
    sdf.mat = mat;
    sdf.dist = length(p)/abs(DEfactor);
    return sdf;
}

// Feather
sdfData fracFeather(float3 p, material mat=DEFMAT)
{
    // https://fractalforums.org/index.php?action=gallery;sa=view;id=5732
    int iterations = 5;
    float cx = 2.0;
    float cy = 2.7;
    float cz = 1.4;
    float cw = 0.1;
    float dx = 1.5;
    
    float lp,r2,s = 1;
    float icy = 1.0 / cy;
    float3 p2,cy3 = float3(cy,cy,cy);

    for (int i=0; i<iterations; i++) {
        p -= cx * round(p / cx);
   
        p2 = pow(abs(p),cy3);
        lp = pow(p2.x + p2.y + p2.z, icy);
       
        r2 = dx / max( pow(lp,cz), cw);
        p *= r2;
        s *= r2;
    }
    
    sdfData o;
    o.mat = mat;
    o.dist = length(p)/s-.001;
    return o;

}

#endif
