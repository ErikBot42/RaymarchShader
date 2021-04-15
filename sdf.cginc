#include "UnityCG.cginc"

#define PI 3.14159265
#define TAU 6.28318531


//////////////////////////////////////////////////////////////////////
//
// Transforms and Manipulations
//
//////////////////////////////////////////////////////////////////////


//soft min of a and b with smoothing factor k
//use for smooth blending
float smin(float a, float b, float k)
{
    float h = max(k - abs(a-b), 0) / k;
    return min(a, b) - h*h*h*k * 1/6.0;
}

//soft max of a and b with smoothing factor k 
//use for smooth carving
float smax(float a, float b, float k)
{
    float h = max(k - abs(a-b), 0) / k;
    return max(a, b) + h*h*h*k * 1/6.0;
}

float3 rotX(float3 p, float a)
{
    return mul(float3x3(1, 0, 0, 0, cos(a), -sin(a), 0, sin(a), cos(a)), p);
}

float3 rotY(float3 p, float a)
{
    return mul(float3x3(cos(a), 0, sin(a), 0, 1, 0, -sin(a), 0, cos(a)), p);
}

float3 rotZ(float3 p, float a)
{
    return mul(float3x3(cos(a), -sin(a), 0, sin(a), cos(a), 0, 0, 0, 1), p);
}

//repeats space every r units, centered on the origin
float3 repDomain(float3 p, float3 r)
{
    return fmod(abs(p + r/2.0), r) - r/2.0;
}


//////////////////////////////////////////////////////////////////////
//
// Shapes
//
//////////////////////////////////////////////////////////////////////


//sphere with origin o and radius r
float sdSphere(float3 p, float3 o, float r) {
    return length(p - o) - r;
}

//cuboid with origin o and dimensions s
float sdBox(float3 p, float3 o, float3 s)
{
    return length(max(abs(p-o) - s/2.0, 0));
}

//line segment between point a and b with radius r
float sdLine(float3 p, float3 a, float3 b, float r)
{
    float h = min(1, max(0, dot(p-a, b-a) / dot(b-a, b-a)));
    return length(p-a-(b-a)*h)-r;
}

//cylinder with origin o, radius r and height h
float sdCylinder(float3 p, float3 o, float r, float h)
{
    return max(abs(p.y + o.y) - h/2.0, length(p.xz + o.xz) - r);
}

//horizontal plane at height h
float sdPlane(float3 p, float h)
{
    return p.y - h;
}

float sdBoxFrame(float3 p0, float3 o, float3 s, float e)
{
    float3 p = abs(p0 - o);
    float dx = sdBox(p, s * float3(0.25, 0.5, 0.5) - float3(0, e/2, e/2), float3(s.x/2, e, e));
    float dy = sdBox(p, s * float3(0.5, 0.25, 0.5) - float3(e/2, 0, e/2), float3(e, s.y/2, e));
    float dz = sdBox(p, s * float3(0.5, 0.5, 0.25) - float3(e/2, e/2, 0), float3(e, e, s.z/2));
    return min(min(dx, dy), dz);
}

//horizontal torus with origin o, radius r and thickness t
float sdTorus(float3 p, float3 o, float r, float t)
{
    float2 q = float2(length(p.xz - o.xz) - r, p.y - o.y);
    return length(q) - t;
}

// EXACT: pyramid, height h
float sdPyramid( float3 p, float h)
{
  float m2 = h*h + 0.25;

  p.xz = abs(p.xz);
  p.xz = (p.z>p.x) ? p.zx : p.xz;
  p.xz -= 0.5;

  float3 q = float3( p.z, h*p.y - 0.5*p.x, h*p.x + 0.5*p.y);

  float s = max(-q.x,0.0);
  float t = clamp( (q.y-0.5*p.z)/(m2+0.25), 0.0, 1.0 );

  float a = m2*(q.x+s)*(q.x+s) + q.y*q.y;
  float b = m2*(q.x+0.5*t)*(q.x+0.5*t) + (q.y-m2*t)*(q.y-m2*t);

  float d2 = min(q.y,-q.x*m2-q.y*0.5) > 0.0 ? 0.0 : min(a,b);

  return sqrt( (d2+q.z*q.z)/m2 ) * sign(max(q.z,-p.y));
}



