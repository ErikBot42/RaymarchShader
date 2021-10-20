#ifndef FASTMATH_CGINC
#define FASTMATH_CGINC


// from: https://github.com/michaldrobot/ShaderFastLibs/blob/master/ShaderFastMathLib.h
// modified to be more "optimized" (WAY worse approximations)
static const float fsl_PI = 3.1415926535897932384626433f;
static const float fsl_PI_half = fsl_PI/2;
inline float acosFast4(float inX)
{
	//return 1.57-inX;
	float x1 = abs(inX);
	float x2 = x1 * x1;
	float x3 = x2 * x1;
	float s;

	s = -0.2121144f * x1 + 1.5707288f;
	s = 0.0742610f * x2 + s;
	s = -0.0187293f * x3 + s;
	s = sqrt(1.0f - x1) * s;

	// acos function mirroring
	// check per platform if compiles to a selector - no branch neeeded
	return s;
	//return inX >= 0.0f ? s : fsl_PI - s;
}

// polynomial degree 2
// Tune for positive input [0, infinity] and provide output [0, PI/2]
inline float ATanPos(float x)
{
	const float C1 = 1.01991;
	const float C2 = -0.218891;
    float t0 = (x < 1.0f) ? x : 1.0f / x;
    float t1 = (C2 * t0 + C1) * t0; // p(x)
    return t1;//return (x < 1.0f) ? t1: fsl_PI_half - t1; // undo range reduction
} 
// Common function, ATanPos is implemented below
// input [-infinity, infinity] and output [-PI/2, PI/2]
inline float ATan(float x) 
{     
    float t0 = ATanPos(abs(x));     
    return t0;//(x < 0.0f) ? -t0: t0; // undo range reduction 
}

inline float atanFast4(float inX)
{
	//return atan(inX);
	return ATan(inX);
	float  x = inX;
	return x*(-0.1784f * abs(x) - 0.0663f * x * x + 1.0301f);
}

// https://en.wikipedia.org/wiki/Atan2#Definition_and_computation
inline float atanFast4_2(float y, float x)
{
	//return sign(x)*sign(x)*atanFast4(y/x)+((1-sign(x))/2)*(1-sign(y)-sign(y)*sign(y))*fsl_PI;
	return atanFast4(y/x)+(1-sign(x))*(sign(y))*fsl_PI/2;

}

// Triangle wave to [-magnitude,magnitude]
inline float pingPong(float curr, float speed = 1, float magnitude = 1)
{
	return (
		(
			abs(frac(curr * speed)-0.5)
		-0.25)*4)
		*magnitude;
}

// Fast direct raytrace sphere estimate O(1)
// Handles case where camera is inside sphere.
// s - start
// d - dir
// c - centre
// r - radius
bool RayTraceSphere(out float dist, out float maxDist, float3 s, float3 d, float r = 1, float3 c = 0)
{
	dist = 0;
	float3 v = s-c;
	float VD = dot(v,d);
	float underSqrt = VD*VD - (dot(v,v) - dot(r,r));
	if (underSqrt<0) return false;

	float plusMinus = sqrt(underSqrt);
	float t0 = max(-VD + plusMinus,0);
	float t1 = max(-VD - plusMinus,0);

	dist = min(t1,t0);
	maxDist = max(t1, t0);
	return true;
}


#endif

