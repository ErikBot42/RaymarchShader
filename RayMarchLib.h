// Definitions for raymarchlib.

#ifndef RAYMARCHLIB_H
#define RAYMARCHLIB_H


//ambient occlusion quality
#ifndef AO_STEPS
#define AO_STEPS 20
#endif

//normals for lighting
//#ifndef NORMAL_DELTA
//#define NORMAL_DELTA 0.001
//#endif

//normals for reflection angles
//#ifndef REFL_NORMAL_DELTA
//#define REFL_NORMAL_DELTA 0.001
//#endif

#ifndef MAX_REFLECTIONS
#define MAX_REFLECTIONS 2
#endif

#ifdef USE_DYNAMIC_QUALITY//quality settings as unity material properties

int _MaxSteps = 100;
#define MAX_STEPS _MaxSteps
float _MaxDist = 100;
#define MAX_DIST _MaxDist
float _SurfDist = 0.00001;
#define SURF_DIST _SurfDist

#else//pre compile quality settings
#ifndef MAX_STEPS
#define MAX_STEPS 256
#endif //256
#ifndef MAX_DIST
#define MAX_DIST 128
#endif //128
#ifndef SURF_DIST
//#define SURF_DIST 0.00001
//#define SURF_DIST 0.0001
#define SURF_DIST 0.001
#endif
#endif

#define TOLERANCE(t) ((t) * SURF_DIST) 

//#define DISCARD_ON_MISS

struct appdata
{
    float4 vertex : POSITION;
	float3 normal : NORMAL;
};

struct v2f
{
    float4 vertex : SV_POSITION;
	float3 vDir : TEXCOORD0;
    float3 vCamPos : TEXCOORD1;
    float3 vHitPos : TEXCOORD2;
	//float3 distEstimate : TEXCOORD3;
	float4 vSdfConfig : TANGENT;
    fixed4 color : COLOR;
	float3 normal : NORMAL;
};

struct fragOut
{
    fixed4 col : SV_Target;
    float depth : SV_Depth;
};

typedef struct material
{
    fixed4 col; 		// Albedo + transparency
    fixed fSmoothness;  // How much light should reflect
	fixed fMetallic;    // Something...
} material_t;

struct rayData // used for lighting a point
{
    float dist;
    int iSteps;
    material mat;
    float3 vRayStart;     // Ray start point
    float3 vRayDir;       // Direction of ray
    float3 vHit;          // Point that ray hit.
    fixed3 vNorm;         // Normal surface vector
    bool bMissed;         
    float minDist;   	   
    float distToMinDist;  // Smallest recorded distance to surface
};

// light data for a specific point.
struct light
{
	fixed3 col;
	float3 dir; // in local space.
	float dist; // dist to light
	float k; // "angle" for soft shadows
	float intensity; // light strength
};

struct rayDataMinimal // minimal data for rayMarch
{
	float dist;
	bool bMissed;
	int iSteps;
	float fLastTolerance;
	float fLastDist;
};

struct sdfData // returned from distance functions, including main scene
{
    float dist;
    material mat;
};

#define V_X  float3(1, 0, 0)
#define V_Y  float3(0, 1, 0)
#define V_Z  float3(0, 0, 1)
#define V_XZ float3(1, 0, 1)
#define V_XY float3(1, 1, 0)
#define V_YZ float3(0, 1, 1)

#define col(r, g, b) fixed4(r, g, b, 1)
#define DEFMAT {fixed4(.2,.2,.2,1), 1, 0}

// Implemented by shaderlab file.
float4 vSdfConfig;
inline float4 sdf(float3 p);
material calcMaterial(float3 p, float3 t = 0);
fixed4 rendererCalculateColor(float3 vStart, float3 vDir, out float3 vHitPos, float startDist=0, int numLevels=2);
//sdfData scene(float3 p)
//{
//	sdfData data;
//	data.dist = sdf(p);
//	material mat;
//	mat.col = fixed4(.2,.2,.2,1);
//	mat.fSmoothness = 1;
//	mat.fMetallic = 0;
//	data.mat = calcMaterial(p);
//	return data;
//}

fixed4 lightPoint(rayData r);
fixed4 rayMarch(float3 p, float3 d);
rayData castRay(float3 p, float3 d, float startDist = 0);
float vertexCastRay(in float3 vRayStart, const float3 vDir, const int iSteps, const float fMaxDist, const float fSurfaceDist, const float fStartLength=0, const float fSurfaceDistPerMetre=0);

#endif
