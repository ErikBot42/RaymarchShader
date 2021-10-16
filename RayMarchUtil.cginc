// Helper functions for RayMarchLib

#ifndef RAYMARCHUTIL_CGINC
#define RAYMARCHUTIL_CGINC

#include "RayMarchLib.h"


inline material mat(float r, float g, float b, float fSmoothness=1, float fMetallic=0)
{
	material m = {fixed4(r, g, b, 1), fSmoothness, fMetallic};
	return m;
}

inline material mat(float3 rgb, float fSmoothness=1, float fMetallic=0)
{
    material m = {fixed4(rgb, 1), fSmoothness, fMetallic};
    return m;
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
    for (float fRayLen = 0.001; fRayLen < MAX_DIST/2.0;)
    {
        float dist = sdf(vPos + vSunDir * fRayLen);

        if (dist < SURF_DIST) return 0;

        fShadow = min(fShadow, fSharpness * dist/fRayLen);
        fRayLen += dist;
    }
    return fShadow;
}

// Calc soft shadow strength based on light angle [0..1]
float lightSoftShadow(float3 vStart, float3 vDir, float k)
{
	//float minDelta = 1;// "Angle" (dy/dx)
	//float fRayLen = 0;
	//
	//for (int i = 0; ; i++)
	//{
	//	float3 vPos = vStart + fRayLen*vDir;
	//	float dist = sdf(vPos);
	//	fRayLen+=dist;
	//	minDelta = min(minDelta, dist/fRayLen);
	//	if (abs(dist)<SURF_DIST || i == iterations) return 0;
	//	if (fRayLen>MAX_DIST) {break;}
	//}
	//return minDelta;
    float res = 1.0;
    float t = 0.0;
    for( int i=0; i<64; i++ )
    {
        float h = sdf(vStart + vDir*t);
        res = min( res, k*h/t );
        if( res<0.001 ) break;
        t += clamp( h, 0.01, 0.2 );
    }
    return clamp( res, 0.0, 1.0 );

}


float lightSoftShadow2(float3 vStart, float3 vDir, float k, float tolerance=0.001)
{
	float res = 1.0;
    float ph = 1e20;
	float mint = 0.001; float maxt = 1;
	int steps = 0;
	const int maxSteps = 40;
    for( float t=mint; t<maxt && steps<maxSteps; steps++)
    {
		float TOL = mint;//0.001;
        float h = sdf(vStart + vDir*t);
        if( h<TOL ) return 0.0;
        float y = h*h/(2.0*ph);
        float d = sqrt(h*h-y*y);
        res = min( res, k*d/max(0.0,t-y) );
        ph = h;
        t += h;
    }
	//if (steps==maxSteps) return res;
    return 1;//res;
}

//calculate sky light
inline fixed4 lightSky(float3 vNorm, fixed4 cSkyCol = fixed4(0.5, 0.8, 0.9, 1))
{
    return cSkyCol * (0.5 + 0.5 * vNorm.y);
}

inline fixed4 lightSky2(float3 vNorm, fixed4 cSkyCol = fixed4(0.5, 0.8, 0.9, 1))
{
    return cSkyCol * pow((0.5 + 0.5 * vNorm.y),5);
}

//ambient occlusion (screen space) based on steps
float lightSSAO(rayData ray_data, float fDarkenFactor = 2)
{
    #ifdef USE_DYNAMIC_QUALITY
    return pow(1 - float(ray_data.iSteps) / _MaxSteps, fDarkenFactor);
    #else
    return pow(1 - float(ray_data.iSteps) / MAX_STEPS, fDarkenFactor);
    #endif
}


//ambient occlusion (screen space) based on steps
float lightSSAO(int iSteps, int iMaxSteps, float fDarkenFactor)
{
	return pow(1.0 - float(iSteps) / float(iMaxSteps), fDarkenFactor);
}

// SSAO that tries to smoothly change between steps.
float smoothSSAO(float steps, float maxSteps, float lastDist, float tolerance, float darkenFactor)
{
	steps += (lastDist/tolerance);
	return pow(saturate(1.0 - steps/maxSteps), darkenFactor);
}


//ambient occlusion
float lightAO(float3 vPos, float3 vNorm, float fEpsilon = 0.05)
{
    float ao = 0;
    for (int i = 0; i < AO_STEPS; i++)
    {
        float fOffset = i * fEpsilon;
        float fDist = sdf(vPos + vNorm * fOffset);
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

// refraction but if angle is great enough it reflects, just like real light
float3 refractionWithTotalReflection(float3 rd, float3 nor, float rid)
{
	float3 refracted = refract(rd, nor, rid);
	return refracted == float3(0,0,0) ? reflect(rd,nor) : refracted;
}


// refract light entering and exiting, assuming it is a sphere.
// default n is for glass
float3 refractLightFakeSphere(float3 rd, float3 nor, out float distFactor, float3 n = 1.52)
{
	float3 rd_ref = refract(rd, nor, 1.0/n);
	float3 rd_nor = reflect(nor, rd_ref);
	distFactor = length(nor-rd_nor);
	return refract(rd_ref, -rd_nor, n/1.0);
}

// Approximation of the reflectance of a surface.
// cosAngle is the cosine of the angle relative to normal.
// that angle can efficiently be obtained by a dot product
// https://en.wikipedia.org/wiki/Schlick%27s_approximation
float calcReflectance(const float cosAngle, const float n1 = 1, const float n2 = 1.5)
{
	float R0 = (n1-n2)/(n1+n2);
	R0 = R0*R0;
	float oneMinusCos = 1-cosAngle;
	return R0 + (1-R0)*(oneMinusCos*oneMinusCos*oneMinusCos*oneMinusCos*oneMinusCos);
}


//a light pass for debugging
//fixed4 lightOnly(float3 vPos, float3 vNorm, float3 vSunDir)
//{
//    float fLight = lightSun(vNorm, vSunDir, 1);
//    float fAO = lightAO(vPos, vNorm);
//    float fShadow = lightShadow(vPos, vSunDir);
//    return fLight * fAO * fShadow;
//}

half ray_OneMinusReflectivityFromMetallic(half metallic)
{
    half oneMinusDielectricSpec = unity_ColorSpaceDielectricSpec.a;
    return oneMinusDielectricSpec - metallic * oneMinusDielectricSpec;
}

half3 ray_DiffuseAndSpecularFromMetallic (half3 albedo, half metallic, out half3 specColor, out half oneMinusReflectivity)
{
    specColor = lerp (unity_ColorSpaceDielectricSpec.rgb, albedo, metallic);
    oneMinusReflectivity = ray_OneMinusReflectivityFromMetallic(metallic);
    return albedo * oneMinusReflectivity;
}

// https://en.wikipedia.org/wiki/Blinn%E2%80%93Phong_reflection_model
fixed3 BlinnPhongLighting(light l, float3 rd, float3 normal, out fixed3 specular)
{
	// TODO: separate diffuse/specular color
	float intensity = saturate(dot(normal, l.dir));
	fixed3 diffuse = intensity*l.col;

	float3 H = normalize(-rd + l.dir);

	float NdotH = dot(normal, H);

	intensity = pow(saturate(NdotH), 500);
	
	specular = intensity*l.col;
	return diffuse;
}

#endif
