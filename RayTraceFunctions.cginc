#ifndef RAYTRACEFUNCTIONS_CGINC
#define RAYTRACEFUNCTIONS_CGINC


// Fast direct raytrace sphere estimate O(1)
// Handles case where camera is inside sphere.
// Takes the max of this and dist for the dist.
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

	dist = max(dist, min(t1,t0));
	maxDist = max(t1, t0);
	return true;
}

#endif // RAYTRACEFUNCTIONS_CGINC
