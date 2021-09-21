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
    float r2 = dot(p,p);
    if (r<(minRadius*minRadius))
    {
        // Inner scaling linear
        float factor = (fixedRadius*fixedRadius)/(minRadius*minRadius);
        p *= factor;
        dz *= factor;
    }
	else if (r2<(fixedRadius*fixedRadius))
	{
		// Sphere inversion
		float factor = (fixedRadius*fixedRadius)/r2;
		p *= factor;
		dz *= factor;
	}
	// else no transform
}

// A optimized variant, requires dz to be stored in float4
void sphereFold2(
	inout float4 pdz,
	const float minRadius2,
	const float fixedRadius2
)
{
	float r = length(pdz.xyz);
	float r2 = dot(pdz.xyz, pdz.xyz);
	if (r<minRadius2)
	{
		float factor = fixedRadius2/minRadius2;
		pdz *= factor;
	}
	else if(r2<fixedRadius2)
	{
		float factor = fixedRadius2/r2;
		pdz *= factor;
	}
}

void sphereFold2(
	inout float4 pdz,
	const float R
)
{
	float r = length(pdz.xyz);
	//float r2 = dot(pdz.xyz, pdz.xyz);
	float R2 = R*R;
	if (r<R)
	{
		float factor = R2/(r*r);
		pdz *= factor;
	}
	//else if(r2<fixedRadius2)
	//{
	//	float factor = fixedRadius2/r2;
	//	pdz *= factor;
	//}
}

// Mengercube fold
void mengerFold(inout float3 p)
{
	float a = min(p.x-p.y,0.0);
	p.x -= a;
	p.y += a;
	a = min(p.x-p.z,0.0);
	p.x -= a;
	p.z += a;
	a = min(p.y-p.z,0.0);
	p.y -= a;
	p.z += a;
}
//void sphereFold(
//    inout float3 p, 
//    inout float dz, 
//    float minRadius, 
//    float fixedRadius)
//{
//    float r = length(p);
//    if (r<minRadius)
//    {
//        // Inner scaling linear
//        float factor = fixedRadius/minRadius;
//        p *= factor;
//        dz *= factor;
//    }
//    else {
//    	float r2 = dot(p,p);
//		if (r2<fixedRadius)
//		{
//			// Sphere inversion
//			float factor = fixedRadius/r2;
//			p *= factor;
//			dz *= factor;
//		}
//	}
//    // else no transform
//}


// Reflect if outside box
void boxFold(inout float3 p, 
    float dz, 
    float foldingLimit)
{
    p = clamp(p, -foldingLimit, foldingLimit) * 2.0 - p;
}

void boxFold2(inout float4 pdz, float foldingLimit)
{
    pdz.xyz = clamp(pdz.xyz, -foldingLimit, foldingLimit) * 2.0 - pdz.xyz;
}

// Abs fold
void absFold(inout float3 p, const float3 c)
{
	p = abs(p-c)+c;
}

void planeFold(inout float3 p, const float3 n, const float d)
{
	p -= 2.0 * min(0.0,dot(p,n)-d)*n;
}

void scaleTranslate(inout float3 p, const float scale, const float3 delta)
{
	p*=scale;
	p+=delta;
}

#endif
