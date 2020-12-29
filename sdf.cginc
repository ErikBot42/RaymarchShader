#include "UnityCG.cginc"

float smin(float a, float b, float k)
{
    float h = max(k - abs(a-b), 0) / k;
    return min(a, b) - h*h*h*k * 1/6.0;
}

float smax(float a, float b, float k)
{
    float h = max(k - abs(a-b), 0) / k;
    return max(a, b) + h*h*h*k * 1/6.0;
}

float sdSphere(float3 p, float3 o, float r) {
    return length(p - o) - r;
}

float sdBox(float3 p, float3 o, float3 r)
{
    return length(max(abs(p-o) - r/2.0, 0));
}

float3 repDomain(float3 p, float3 r)
{
    return fmod(abs(p + r/2.0), r) - r/2.0;
}

float sdLine(float3 p, float3 a, float3 b, float r)
{
    float h = min(1, max(0, dot(p-a, b-a) / dot(b-a, b-a)));
    return length(p-a-(b-a)*h)-r;
}