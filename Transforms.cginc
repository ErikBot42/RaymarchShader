// Transform functions

#ifndef TRANSFORMS_CGINC
#define TRANSFORMS_CGINC

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
    float r = length(p);
    if (r<minRadius)
    {
        // Inner scaling linear
        float factor = fixedRadius/minRadius;
        p *= factor;
        dz *= factor;
    }
    else {
    	float r2 = dot(p,p);
		if (r2<fixedRadius)
		{
			// Sphere inversion
			float factor = fixedRadius/r2;
			p *= factor;
			dz *= factor;
		}
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

#endif
