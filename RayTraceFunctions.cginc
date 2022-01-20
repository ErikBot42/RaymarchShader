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


bool RayTraceCube(out float dist, out float maxDist, float3 ro, float3 rd, float3 boxSize)
{
    dist = 0; maxDist = 0;

    float3 m = 1/rd;
    float3 n = m*ro;

    float3 k = abs(m)*boxSize;

    float3 t1 = -n-k;
    float3 t2 = -n+k;

    float tN = max( max( t1.x, t1.y ), t1.z );
    float tF = min( min( t2.x, t2.y ), t2.z );

    if( tN>tF || tF<0.0) return false;
    dist = max(dist, min(tN, tF));
    maxDist = max(tN, tF);
    return true;

}


#endif // RAYTRACEFUNCTIONS_CGINC
