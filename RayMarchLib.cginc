//double include guard
#ifndef RAY_MARCH_LIB_INCLUDED
#define RAY_MARCH_LIB_INCLUDED

#include "UnityCG.cginc"

// Multi compile stuff

#define V_X  float3(1, 0, 0)
#define V_Y  float3(0, 1, 0)
#define V_Z  float3(0, 0, 1)
#define V_XZ float3(1, 0, 1)
#define V_XY float3(1, 1, 0)
#define V_YZ float3(0, 1, 1)

//ambient occlusion quality
#ifndef AO_STEPS
#define AO_STEPS 5
#endif

//normals for lighting
#ifndef NORMAL_DELTA
#define NORMAL_DELTA 0.001
#endif
//normals for reflection angles
#ifndef REFL_NORMAL_DELTA
#define REFL_NORMAL_DELTA 0.001
#endif

#ifndef MAX_REFLECTIONS
#define MAX_REFLECTIONS 2
#endif

#ifdef USE_DYNAMIC_QUALITY//quality settings as unity material properties
int _MaxSteps = 100;
float _MaxDist = 100;
float _SurfDist = 0.00001;
#else//pre compile quality settings
#ifndef MAX_STEPS
#define MAX_STEPS 256
#endif
#ifndef MAX_DIST
#define MAX_DIST 128
#endif
#ifndef SURF_DIST
#define SURF_DIST 0.00001
#endif
#endif


#define col(r, g, b) fixed4(r, g, b, 1)

/*enum class Ray
{

}*/

struct appdata
{
    float4 vertex : POSITION;
};

struct v2f
{
    float4 vertex : SV_POSITION;
    float3 vCamPos : TEXCOORD1;
    float3 vHitPos : TEXCOORD2;
};

struct fragOut
{
    fixed4 col : SV_Target;
    float depth : SV_Depth;
};

typedef struct material
{
    fixed4 col;
    fixed fRough;
} material_t;

#define DEFMAT {fixed4(.2,.2,.2,1), 1}

#define M_RED       {fixed4(0.2, 0.001, 0.001, 1), 1}
#define M_ORANGE    {fixed4(0.2, 0.1, 0.001, 1), 1}
#define M_YELLOW    {fixed4(0.2, 0.2, 0.001, 1), 1}
#define M_GREEN     {fixed4(0.001, 0.2, 0.001, 1), 1}
#define M_BLUE      {fixed4(0.001, 0.001, 0.2, 1), 1}
#define M_LIGHT_BLUE{fixed4(0.001, 0.05, 0.2, 1), 1}
#define M_MAGENTA   {fixed4(0.2, 0.001, 0.2, 1), 1}
#define M_PURPLE    {fixed4(0.05, 0.001, 0.2, 1), 1}
#define M_WHITE     {fixed4(0.5, 0.5, 0.5, 1), 1}
#define M_MIRROR    {fixed4(0.1, 0.1, 0.1, 1), 0}

inline material mat(float r, float g, float b, float fRough = 1)
{
    material m = {fixed4(r, g, b, 1), fRough};
    return m;
}

inline material mat(float3 rgb, float fRough = 1)
{
    material m = {fixed4(rgb, 1), fRough};
    return m;
}

//used for lighting a point
struct rayData
{
    float dist;
    int iSteps;
    material mat;
    float3 vRayStart;
    float3 vRayDir;
    float3 vHit;
    fixed3 vNorm;
    bool bMissed;
    float minDist;
    float distToMinDist;
};

//returned from distance functions, including main scene
struct sdfData
{
    float dist;
    material mat;
};


sdfData scene(float3 p);
fixed4 lightPoint(rayData r);
fixed4 rayMarch(float3 p, float3 d);
rayData castRay(float3 p, float3 d, float startDist = 0);


v2f vert (appdata v)
{
    v2f o;
    o.vertex = UnityObjectToClipPos(v.vertex);
#ifdef USE_WORLD_SPACE
    o.vCamPos = _WorldSpaceCameraPos;
    o.vHitPos = mul(unity_ObjectToWorld, v.vertex);
#else
    o.vCamPos = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
    o.vHitPos = v.vertex;
#endif
    return o;
}


#ifdef USE_REFLECTIONS
fragOut frag (v2f i)
{

    float fRayLen = 0;//since last bounce

    #ifdef CONSTRAIN_TO_MESH
    float3 vLastBounce = i.vHitPos;
    fRayLen += length(i.vHitPos - i.vCamPos);
    #else
    float3 vLastBounce = i.vCamPos;
    #endif
    float3 vRayDir = normalize(i.vHitPos - i.vCamPos);//current direction
    sdfData point_data;
    rayData ray;

    fixed4 col;
    float colUsed = 0;// what amount of the final colour has been calculated
    float prevRough = 0;

    float3 vFirstHit;

    for (int i = 0; i < MAX_REFLECTIONS+1; i++)
    {
        ray = castRay(vLastBounce, vRayDir);
        if (i == 0)
        {//before any bounces
            col = lightPoint(ray);
            vFirstHit = ray.vHit;
        }
        else
        {
            float colAmt = colUsed + (prevRough * (1-colUsed));
            col = lerp(lightPoint(ray), col, colAmt);
            colUsed = colAmt;
        }
        if (ray.bMissed || ray.mat.fRough > 0.99)
        {
            break;
        }
        prevRough = ray.mat.fRough;
        vRayDir = reflect(vRayDir, ray.vNorm);
        vLastBounce = ray.vHit + vRayDir * 0.01;
    }
    #ifdef DISCARD_ON_MISS
    if (ray.bMissed && i == 0) discard;
    #endif
    fragOut o;
    o.col = col;
    
    #ifdef USE_WORLD_SPACE
        float4 vClipPos = mul(UNITY_MATRIX_VP, float4(vFirstHit, 1));
    #else
        float4 vClipPos = mul(UNITY_MATRIX_VP, mul(unity_ObjectToWorld, float4(vFirstHit, 1)));
    #endif

    o.depth = (vClipPos.z / vClipPos.w + 1.0) * 0.5;
    return o;
}
#else
fragOut frag (v2f i)
{
    float3 vRayDir = normalize(i.vHitPos - i.vCamPos);
    #ifdef CONSTRAIN_TO_MESH
    //rayData ray = castRay(i.vHitPos, vRayDir, length(i.vHitPos-i.vCamPos));
    rayData ray = castRay(i.vCamPos, vRayDir, length(i.vHitPos-i.vCamPos));
    //rayData ray = castRay(i.vCamPos, vRayDir, 1);
    //rayData ray = castRay(i.vCamPos, vRayDir, 0);

    #else
    rayData ray = castRay(i.vCamPos, vRayDir);
    #endif
    #ifdef DISCARD_ON_MISS
    if (ray.bMissed) discard;
    #endif
    fragOut o;
    o.col = lightPoint(ray);
    
    #ifdef USE_WORLD_SPACE
        float4 vClipPos = mul(UNITY_MATRIX_VP, float4(ray.vHit, 1));
    #else
        float4 vClipPos = mul(UNITY_MATRIX_VP, mul(unity_ObjectToWorld, float4(ray.vHit, 1)));
    #endif
    
    o.depth = (vClipPos.z / vClipPos.w + 1.0) * 0.5;
    return o;
}
#endif

//gets normal of a point
inline float3 getNormFull(float3 vPos, float fEpsilon = 0.001)
{
    ////if epsilon is smaller than 0.001, there are often artifacts
    const float2 e = float2(fEpsilon, 0);
    float3 n = scene(vPos).dist - float3(
            scene(vPos - e.xyy).dist,
            scene(vPos - e.yxy).dist,
            scene(vPos - e.yyx).dist);
    return normalize(n);
}
//gets normal, provided you have the distance for pos (1 less call to scene())
inline float3 getNorm(float3 vPos, float fPointDist, float fEpsilon = 0.001)
{
    ////if epilon is smaller than 0.001, there are often artifacts
    const float2 e = float2(fEpsilon, 0);
    float3 n = fPointDist - float3(
            scene(vPos - e.xyy).dist,
            scene(vPos - e.yxy).dist,
            scene(vPos - e.yyx).dist);
    return normalize(n);
}

//marches a ray through the scene once
rayData castRay(float3 vRayStart, float3 vRayDir, float startDist)
{
    float fRayLen = startDist;//startDist;// total distance marched / distance from camera

    float3 vPos;
    sdfData sdf_data;

    rayData ray;
    ray.vRayDir = vRayDir;
    ray.vRayStart = vRayStart;
    ray.minDist = 30000.0;// budget "infinity"
    ray.distToMinDist = 0;

    #ifdef USE_DYNAMIC_QUALITY
    for (int i = 0; i < _MaxSteps; i++)
    #else
    for (int i = 0; i < MAX_STEPS; i++)
    #endif
    {
        vPos = vRayStart + fRayLen * vRayDir;
        sdf_data = scene(vPos);

        #ifdef USE_DYNAMIC_QUALITY
        if (abs(sdf_data.dist) < _SurfDist) break;
        #else
        if (abs(sdf_data.dist) < SURF_DIST) break;
        #endif

        fRayLen += sdf_data.dist;// move forward

        if (ray.minDist>sdf_data.dist) 
        {
            ray.minDist = sdf_data.dist;
            ray.distToMinDist = fRayLen;
        }
        
        #ifdef USE_DYNAMIC_QUALITY
        if (fRayLen > _MaxDist) {ray.bMissed = true; break;}//flag this as transparent/sky
        #else
        if (fRayLen > MAX_DIST) {ray.bMissed = true; break;}//flag this as transparent/sky
        #endif
    }

    ray.dist   = fRayLen;
    ray.iSteps = i;
    ray.mat    = sdf_data.mat;
    ray.vHit   = vPos;
    ray.vNorm  = getNorm(vPos, sdf_data.dist);
    return ray;
}


//////////////////////////////////////////////////////////////////////
//
// Lighting
//
//////////////////////////////////////////////////////////////////////


//generates a skybox, use when ray didn't hit anything (ray_data.bMissed)
inline fixed4 sky(float3 vRayDir)
{
    float4 cRenderedSun = max(0, pow(dot(vRayDir, normalize(float3(8,4,2))) + 0.4, 10)-28) * float4(.8,.4,0,1);
    return fixed4(0.7, 0.75, 0.8, 1) - abs(vRayDir.y) * 0.5 + cRenderedSun;
}

//calculate sun light based on normal
fixed4 lightSun(float3 vNorm, float3 vSunDir = float3(8, 4, 2), fixed4 cSunCol = fixed4(7.0, 5.5, 3.0, 1))
{
    float fSunLight = max(dot(vNorm, vSunDir), 0);
    return fSunLight * cSunCol;
}

//calculate shadow from sun
float lightShadow(float3 vPos, float3 vSunDir, float fSharpness = 8)
{
    float fShadow = 1;
    #ifdef USE_DYNAMIC_QUALITY
    for (float fRayLen = 0.001; fRayLen < _MaxDist/2.0;)
    #else
    for (float fRayLen = 0.001; fRayLen < MAX_DIST/2.0;)
    #endif
    {
        float dist = scene(vPos + vSunDir * fRayLen).dist;

        #ifdef USE_DYNAMIC_QUALITY
        if (dist < _SurfDist) return 0;
        #else
        if (dist < SURF_DIST) return 0;
        #endif

        fShadow = min(fShadow, fSharpness * dist/fRayLen);
        fRayLen += dist;
    }
    return fShadow;
}

//calculate sky light
inline fixed4 lightSky(float3 vNorm, fixed4 cSkyCol = fixed4(0.5, 0.8, 0.9, 1))
{
    return cSkyCol * (0.5 + 0.5 * vNorm.y);
}

//bad ambient occlusion (screen space) based on steps
float lightSSAO(rayData ray_data, float fDarkenFactor = 2)
{
    #ifdef USE_DYNAMIC_QUALITY
    return pow(1 - float(ray_data.iSteps) / _MaxSteps, fDarkenFactor);
    #else
    return pow(1 - float(ray_data.iSteps) / MAX_STEPS, fDarkenFactor);
    #endif
}

//ambient occlusion
float lightAO(float3 vPos, float3 vNorm, float fEpsilon = 0.05)
{
    float ao = 0;
    for (int i = 0; i < AO_STEPS; i++)
    {
        float fOffset = i * fEpsilon;
        float fDist = scene(vPos + vNorm * fOffset).dist;
        ao += 1/pow(2, i) * (fOffset - fDist);
    }
    ao = 1 - AO_STEPS * ao;
    return ao;
}

inline fixed4 lightFog(fixed4 col, fixed4 cFog, float fDist, float fStart=16, float fFull=32)
{
    if (fDist < 0) return cFog;
    return lerp(col, cFog, smoothstep(fStart, fFull, fDist));
}

//a light pass for debugging
fixed4 lightOnly(float3 vPos, float3 vNorm, float3 vSunDir)
{
    float fLight = lightSun(vNorm, vSunDir, 1);
    float fAO = lightAO(vPos, vNorm);
    float fShadow = lightShadow(vPos, vSunDir);
    return fLight * fAO * fShadow;
}


//////////////////////////////////////////////////////////////////////
//
// Interpolation
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
// SDF shapes
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
    int iterations = 8;

    float maxRThreshold = 2;

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

void sphereFold(inout float3 p, inout float dz, float minRadius, float fixedRadius);
void boxFold(inout float3 p, float dz, float foldingLimit);

// Mandelbox
sdfData fracMandelbox(float3 p, float scaleFactor, material mat = DEFMAT)
{
    // http://blog.hvidtfeldts.net/index.php/2011/11/distance-estimated-3d-fractals-vi-the-mandelbox/

    float3 offset = p;
    float dr = 0;
   
    // Parameters
    int iterations = 15;
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
    int iterations = 8;
    //float cx = 2.0 + _SinTime.z*0.1;
    float cx = 2.0;
    float cy = 2.7;
    float cz = 1.4;
    float cw = 0.1;
    float dx = 1.5;// + _FoldingLimit-0.5;
    
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

//////////////////////////////////////////////////////////////////////
//
// Transforms
//
//////////////////////////////////////////////////////////////////////


// rotate point p around origin, a radians
float3 rotX(float3 p, float a)
{
    return mul(float3x3(1, 0, 0, 0, cos(a), -sin(a), 0, sin(a), cos(a)), p);
}

// rotate point p around origin, a radians
float3 rotY(float3 p, float a)
{
    return mul(float3x3(cos(a), 0, sin(a), 0, 1, 0, -sin(a), 0, cos(a)), p);
}

// rotate point p around origin, a radians
float3 rotZ(float3 p, float a)
{
    return mul(float3x3(cos(a), -sin(a), 0, sin(a), cos(a), 0, 0, 0, 1), p);
}

// repeats space every r units, centered on the origin
inline float3 repXYZ(float3 p, float3 r)
{
    float3 o = p;
    o = fmod(abs(p + r/2.0), r) - r/2.0;
    o *= sign(o);
    return o;
}

// repeats space every r units, centered on the origin, no sign
inline float3 repXYZUnsigned(float3 p, float3 r)
{
    return fmod(abs(p + r/2.0), r) - r/2.0;
}

// repeats space every r units, centered on the origin
inline float3 repXZ(float3 p, float x, float z)
{
    float3 o = p;
    o.x = fmod(abs(p.x) + x/2.0, x) - x/2.0;
    o.x *= sign(p.x);
    o.z = fmod(abs(p.z) + z/2.0, z) - z/2.0;
    o.z *= sign(p.z);
    return o;
}

// Reflect point if inside/outside sphere
void sphereFold(
    inout float3 p, 
    inout float dz, 
    float minRadius, 
    float fixedRadius)
{
    float r2 = dot(p,p);
    float r = length(p);
    if (r<minRadius)
    {
        // Inner scaling linear
        float factor = fixedRadius/minRadius;
        p *= factor;
        dz *= factor;
    }
    else if (r2<fixedRadius)
    {
        // Sphere inversion
        float factor = fixedRadius/r2;
        p *= factor;
        dz *= factor;
    }
    // else no transform
}

// Reflect if outside box
void boxFold(inout float3 p, 
    float dz, 
    float foldingLimit)
{
    p = clamp(p, -foldingLimit, foldingLimit) * 2.0 - p;
    //p = clamp(p, -foldingLimit, foldingLimit) * 2.0 - p;
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

#endif //RAY_MARCH_LIB_INCLUDED
