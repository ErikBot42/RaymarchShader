#ifndef RAYMARCHLIB_CGINC
#define RAYMARCHLIB_CGINC


#include "UnityCG.cginc"
#include "RayMarchLib.h"
#include "SdfFunctions.cginc"
#include "SdfMath.cginc"
#include "Transforms.cginc"
#include "FastMath.cginc"
#include "RayMarchUtil.cginc"
#include "noise.cginc"

#include "Lighting.cginc"

v2f vert (appdata v)
{
    v2f o;
    o.vertex = UnityObjectToClipPos(v.vertex);
#ifdef USE_WORLD_SPACE
	float3 viewDir = WorldSpaceViewDir(v.vertex);
	float3 normal = UnityObjectToWorldNormal(v.normal);
    o.vCamPos = _WorldSpaceCameraPos;
    o.vHitPos = mul(unity_ObjectToWorld, v.vertex);
#else // Object space
	float3 viewDir = ObjSpaceViewDir(v.vertex);
	float3 normal = v.normal;
    o.vCamPos = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
    o.vHitPos = v.vertex; 
#endif
	viewDir = normalize(viewDir);
	normal = normalize(normal);

	o.vDir = normalize(o.vHitPos - o.vCamPos);
	o.vCamPos *=1;

	// Random vector calc
    //o.vSdfConfig = sin(float4(0.143346,0.1876434,0.12437,0.08867)*_Time.z+5);
	o.vSdfConfig = getNoise4(_Time.x*1);
    
	// Dist estimate calc
	float3 vDeltaPos = o.vHitPos - o.vCamPos; // constrain to mesh
	float fDeltaDist = length(vDeltaPos); // dist from camera to vertex

	float cosHeightVertex = abs(dot(normal, viewDir)); // assuming mesh is sphere with relatively equally spaced points.

	float fEdgeLength = cosHeightVertex*0.2;// DEFAULT_SPHERE: estimated distance between vertices from the perspective of an orthographic camera
	//float fEdgeLength = cosHeightVertex*0.02;// ICOSPHERE7: estimated distance between vertices from the perspective of an orthographic camera
	//float fEdgeLength = cosHeightVertex*0.13;// ICOSPHERE: estimated distance between vertices from the perspective of an orthographic camera
	//float fEdgeLength = 0.02; // estimated distance between vertices from the perspective of an orthographic camera
	float fSurfDistPerMeter = fEdgeLength/fDeltaDist;
    
	//o.distEstimate.x = vertexCastRay(o.vCamPos, o.vDir, MAX_STEPS, MAX_DIST, 0.02, fDeltaDist);
	//o.distEstimate.x = vertexCastRay(o.vCamPos, o.vDir, MAX_STEPS, MAX_DIST, SURF_DIST, fDeltaDist, fSurfDistPerMeter);
	o.distEstimate.x = vertexCastRay(o.vCamPos, o.vDir, MAX_STEPS, MAX_DIST*0.9, SURF_DIST, fDeltaDist, fSurfDistPerMeter);

	return o;
}

#ifdef USE_REFLECTIONS
#define CALC_NORM
fragOut frag (v2f i)
{

    //float fRayLen = 0;//since last bounce
	//float3 vRayDir = i.vDir;
    ////float3 vRayDir = normalize(i.vHitPos - i.vCamPos);//current direction

    //#ifdef CONSTRAIN_TO_MESH
	////float3 posDif = i.vHitPos - i.vCamPos;
	////if (dot(posDif,
    ////float3 vLastBounce = i.vHitPos;
    ////fRayLen += length;
    //float3 vLastBounce = i.vHitPos;
    //fRayLen += length(i.vHitPos - i.vCamPos);
    //#else
    //float3 vLastBounce = i.vCamPos;
    //#endif
    //sdfData point_data;
    //rayData ray;

    //fixed4 col;
    //float colUsed = 0;// what amount of the final colour has been calculated
    //float prevRough = 0;

    //float3 vFirstHit;

    //for (int i = 0; i < MAX_REFLECTIONS+1; i++)
    //{
    //    ray = castRay(vLastBounce, vRayDir);
    //    if (i == 0)
    //    {//before any bounces
    //        col = lightPoint(ray);
    //        vFirstHit = ray.vHit;
    //    }
    //    else
    //    {
    //        float colAmt = colUsed + (prevRough * (1-colUsed));
    //        col = lerp(lightPoint(ray), col, colAmt);
    //        colUsed = colAmt;
    //    }
    //    if (ray.bMissed || ray.mat.fRough > 0.99)
    //    {
    //        break;
    //    }
    //    prevRough = ray.mat.fRough;
    //    vRayDir = reflect(vRayDir, ray.vNorm);
    //    vLastBounce = ray.vHit + vRayDir * 0.01;
    //}
    //#ifdef DISCARD_ON_MISS
    //if (ray.bMissed && i == 0) discard;
    //#endif
    //fragOut o;
    //o.col = col;
    //
    //#ifdef USE_WORLD_SPACE
    //    float4 vClipPos = mul(UNITY_MATRIX_VP, float4(vFirstHit, 1));
    //#else
    //    float4 vClipPos = mul(UNITY_MATRIX_VP, mul(unity_ObjectToWorld, float4(vFirstHit, 1)));
    //#endif

    //o.depth = (vClipPos.z / vClipPos.w + 1.0) * 0.5;
    //return o;

	fragOut o;
	o.col = fixed4(1,1,1,1);
	return o;
}
#else
fragOut frag (v2f i)
{
	vSdfConfig = i.vSdfConfig;

    float3 vRayDir = normalize(i.vHitPos - i.vCamPos);
    //#ifdef CONSTRAIN_TO_MESH
	//float len = i.distEstimate.x*1; //length(i.vHitPos-i.vCamPos); 
	//rayData ray;
	//ray = castRay(i.vCamPos, vRayDir, len);
    //#else
    //rayData ray = castRay(i.vCamPos, vRayDir);
    //#endif

    #ifdef DISCARD_ON_MISS
    //if (ray.bMissed) discard;
    #endif
    fragOut o;
    //o.col = lightPoint(ray);
	o.col = rendererCalculateColor(i.vCamPos, vRayDir, 0, 2);

	#ifdef VERTEX_DEBUG_COLORS
	o.col.b = 1;
	o.col.g = o.col.w;
	o.col.w = 1;
	o.col.r = 1/i.distEstimate;
	#endif

	#ifdef USE_VERTEX_COLOR
	o.col = i.color;
	#endif

	// writing to depth buffer costs about 1-2 frames at 4k -> very cheap
	//#ifndef DISABLE_Z_WRITE
	//float4 zPoint = float4(ray.vHit,1);
	//#ifdef USE_WORLD_SPACE
	//	float4 vClipPos = mul(UNITY_MATRIX_VP, zPoint);
	//#else
	//	float4 vClipPos = mul(UNITY_MATRIX_VP, mul(unity_ObjectToWorld, zPoint));
	//#endif
	//	o.depth = (vClipPos.z / vClipPos.w + 1.0) * 0.5;
	//#endif

	#ifndef ENABLE_TRANSPARENCY
	o.col *= o.col.w;
	o.col.w = 1;
	#endif
    
    return o;
}
#endif

//gets normal of a point
inline float3 getNormFull(float3 vPos, float fEpsilon = 0.001)
{
    //if epsilon is smaller than 0.001, there are often artifacts
    const float2 e = float2(fEpsilon, 0);
    float3 n = sdf(vPos) - float3(
            sdf(vPos - e.xyy),
            sdf(vPos - e.yxy),
            sdf(vPos - e.yyx));
    return normalize(n);
}
//gets normal, provided you have the distance for pos (1 less call to sdf())
inline float3 getNorm(float3 vPos, float fPointDist, float fEpsilon = 0.001)
{
    //if epilon is smaller than 0.001, there are often artifacts
    const float2 e = float2(fEpsilon, 0);
    float3 n = fPointDist - float3(
            sdf(vPos - e.xyy),
            sdf(vPos - e.yxy),
            sdf(vPos - e.yyx));
    return normalize(n);
}

//marches a ray through the scene once
// TODO: REDUCE
rayData castRay(float3 vRayStart, float3 vRayDir, float startDist)
{
    float fRayLen = startDist;//startDist;// total distance marched / distance from camera

    float3 vPos;
	float dist;

    rayData ray;
	ray.bMissed = false;
    ray.vRayDir = vRayDir;
    ray.vRayStart = vRayStart;
    ray.minDist = 30000.0;// budget "infinity"
    ray.distToMinDist = 0;

	for (int i = 0; i < MAX_STEPS; i++)
    {
        vPos = vRayStart + fRayLen * vRayDir;
        dist = sdf(vPos);

		if (abs(dist) < TOLERANCE(fRayLen)) {break;}

        fRayLen += dist;// move forward

        if (ray.minDist>dist) 
        {
            ray.minDist = dist;
            ray.distToMinDist = fRayLen;
        }
        
        if (fRayLen > MAX_DIST) {ray.bMissed = true; break;}//flag this as transparent/sky
    }

	//ray.bMissed = fRayLen < MAX_DIST;

    ray.dist   = fRayLen;
    ray.iSteps = i;
    ray.mat    = calcMaterial(vPos);
    ray.vHit   = vPos;
    //ray.vNorm  = getNorm(vPos, dist);
    return ray;
}


// start at vertex? 
// increase surfacedist with length?
// very simple lower estimate for length of ray.
float vertexCastRay(in float3 vRayStart, const float3 vDir, const int iSteps, const float fMaxDist, const float fSurfaceDist, const float fStartLength, const float fSurfaceDistPerMetre)
{
	float fRayLen = fStartLength;
	for(int i = 0; i<iSteps; i++)
	{
		float3 vPos = vRayStart + vDir*fRayLen;
        float dist = sdf(vPos);
		if (abs(dist) < (fSurfaceDist+fSurfaceDistPerMetre*fRayLen)) break;
        fRayLen += dist;
		if (fRayLen>fMaxDist) break;
	}
	return fRayLen;
}


fixed4 simpleLightPoint(rayData ray)
{
	fixed4 fogColor = lightSky(ray.vRayDir);
	if (ray.bMissed)
	{
		return fogColor;	
	}
	else
	{
		material mat = calcMaterial(ray.vHit);
		fixed4 col = mat.col;
		col.xyz*=lightSSAO(ray, 4);
		return col;
	}
}

float rand3dTo1d(float3 value, float3 dotDir = float3(12.9898, 78.233, 37.719)){
	//make value smaller to avoid artefacts
	float3 smallValue = sin(value);
	//get scalar value from 3d vector
	float random = dot(smallValue, dotDir);
	//make value more random by making it bigger and then taking the factional part
	random = frac(sin(random) * 143758.5453);
	return random;
}

float3 rand3dTo3d(float3 value){
	return float3(
		rand3dTo1d(value, float3(12.989, 78.233, 37.719)),
		rand3dTo1d(value, float3(39.346, 11.135, 83.155)),
		rand3dTo1d(value, float3(73.156, 52.235, 09.151))
	);
}

float3 light1 = normalize(float3(0, 1, -0.1)); // sky
fixed4 light1_col = fixed4(0.3,0.7,0.9,1);

// get background light from dir.
fixed4 worldGetBackground( in float3 dir, in float rough = 0.0)
{

	float3 light2 = normalize(float3(0,1,2));//normalize(float3(-0.577, 0.577, 0.577)); // sun
	fixed3 light2_col = fixed3(1,0.8,0.4);

	// https://stackoverflow.com/questions/53910092/how-can-i-get-the-lighting-information-from-a-skybox
	//half rough = 0.5;
	//rough = 1.7 - 0.7 * rough;
	float4 reflData = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, dir, rough*6);
	fixed4 col = half4(DecodeHDR(reflData, unity_SpecCube0_HDR),1);
	col += smoothstep(0.85,1.01,dot(dir, light2))*float4(light2_col,1);
	col += smoothstep(-0.0,-0.8,dir.y)*fixed4(1,0,1,1)*0.4;
	return col;
	//half4 skyData = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, dir);
	//return half4(DecodeHDR(skyData, unity_SpecCube0_HDR), 1);
	

	//fixed4 light1_col = fixed4(0.3,0.7,0.9,1);
	//float fac=0.3;
	//fixed4 col = light1_col * min(1,dir.y+0.2);
	//col += fixed4(0.9,0.7,0.2,1)*max(0,dir.y-0.8)*3;
	//return col;
	//return lightSky2(dir);//*(1-fac+fac*snoise(dir*10));
}

// calc the direct light a point recives (including shadows)
fixed4 worldApplyLighting(in float3 pos, in float3 nor, in float3 dir)
{
	//float light1_angle = 0.1;

	float3 light2 = normalize(float3(0,1,2));//normalize(float3(-0.577, 0.577, 0.577)); // sun
	fixed3 light2_col = fixed3(1,0.8,0.4);
	//float light2_angle = 0.01;

	float3 light3 = light2; light3.x*=-1; light3.z*=-1; // sun, other dir
	fixed3 light3_col = light2_col*0.4;
	//light3_col.r = 0;
	//light3_col.g = 2;
	//light3_col.b = 2;

	fixed3 col = fixed3(1,1,1)*0.0;// "ambient"
	rayData ray;
	//col += light1_col*lightShadow(pos+nor*0.001, light1,20);
	float stepBack = 0.01;

	float3 newStartPoint = pos + nor*stepBack;
	
	//col += light1_col * lightSoftShadow(newStartPoint, light1);
	//col += light1_col * lightSoftShadow(newStartPoint, light1, 20);
	//col += light2_col * lightSoftShadow(newStartPoint, light2, 20);
	
	float3 reflected = reflect(dir, nor);
#if 1
	float k = 4;//100;
	//col += light1_col * lightSoftShadow2(newStartPoint, light1, k);
	col += light2_col * lightSoftShadow2(newStartPoint, light2, k) * max(0, dot(light2, nor));
	//col += light3_col * lightSoftShadow2(newStartPoint, light3, k);
	//col += worldGetBackground(reflected);
	//col += worldGetBackground(nor);
#else

	float minLight = 0.0;
	//col += (max(minLight,dot(nor, light1))-minLight)*light1_col*10;
	//col += (max(minLight,dot(nor, light2))-minLight)*light2_col*10;
	//col += (max(minLight,dot(nor, light3))-minLight)*light3_col*10;
	
	float refFactor = 1;//dot(dir, -nor)*2;

	col += worldGetBackground(reflected)*refFactor;
	//col += worldGetBackground(nor)*refFactor;
	float fac = 0.0;
	//col += max(dot(normalize(pos),light1),0)*light1_col*fac;
	//col += max(dot(normalize(pos),light2),0)*light2_col*fac;
	//col += max(dot(normalize(pos),light3),0)*light3_col*fac;

	//col += light2_col * max(0,dot(reflected, light2));
#endif

	//col = fixed3(1,1,1)*0.1;

	//col += worldGetBackground(reflected)*2;
	


	//float3 normal2 = getNormFull(ray.vHit);
	//fixed3 col2 = worldApplyLighting(ray2.vHit, normal2, ray2.vRayDir).xyz;
	//col += col2;
	//col=ray2.bMissed?worldGetBackground(reflected) : ray2.mat.col;

	//ray = castRay(pos + nor*stepBack, light1);
	//if (ray.bMissed) col += light1_col;

	//ray = castRay(pos + nor*stepBack, light2);
	//if (ray.bMissed) col += light2_col;
	
	return fixed4(col,1);
}

//TODO: emmision, reflections
// glow?
// soft shadows



fixed4 lightPoint(rayData ray)
{

	fixed4 col;
	fixed4 skyColor = worldGetBackground(ray.vRayDir);
	fixed4 fogColor = skyColor;//, unity_FogColor);

	// TODO: MAKE PROPER RECURSIVE REFLECTION MODEL!!!
	if (ray.bMissed)
	{
		col = skyColor;
	}
	else
	{
		float3 normal = getNormFull(ray.vHit);//+snoise(ray.vHit*50)*0.2;
		col = ray.mat.col*0.2;

		fixed4 directLighting = worldApplyLighting(ray.vHit, normal, ray.vRayDir);
		float3 reflected = reflect(ray.vRayDir, normal);

		//float3 reflected2 = normalize(reflected+rand3dTo1d(ray.vHit*100)*0.01);
		float3 reflected2 = reflected;

		rayData ray2 = castRay(ray.vHit+normal*0.001,reflect(ray.vRayDir, normal));

		float3 normal2 = getNormFull(ray.vHit);
		//if (!ray2.bMissed)
		//{
		//	normal2 = getNormFull(ray.vHit);
		//	ray2 = castRay(ray2.vHit+normal2*0.001,reflect(ray2.vRayDir, normal));
		//}

		//if (!ray2.bMissed)
		//{
		//	normal2 = getNormFull(ray.vHit);
		//	ray2 = castRay(ray2.vHit+normal2*0.001,reflect(ray2.vRayDir, normal));
		//}

		fixed4 indirectLighting = ray2.bMissed ? worldGetBackground(ray2.vRayDir) : ray2.mat.col*worldApplyLighting(ray2.vHit, normal2, ray2.vRayDir);
		
		float fac = .5;//1-ray.mat.fSmoothness;//0.3;
		fixed4 lighting = 1*directLighting*fac + indirectLighting*(1-fac);

		//lighting *= 0.6+lightSSAO(ray, 5);
		//lighting += 0*0.1*lightAO(ray.vHit, normal, 0.01);
		//lighting = fixed4(1,1,1,1)*0.3;
		// Hack to make bottom darker
		//lighting = lightFog(lighting, skyColor, ray.vHit.y+positiveOffset, 0.4+positiveOffset, -0.4+positiveOffset);


		col *= lighting*4;
		

		//col.xyz *= lightAO(ray.vHit, normal, 0.01);
		//col.xyz*=lightSSAO(ray, 30)*5;
		//col = fixed4(1,1,1,1);
		//col *= dot(light1,normal);
		
		//col.g = (ray.vHit.y+0.5);

		//col = pow(col, 1.0/2.2);//gamma
		//col = lightFog(col, skyColor, ray.dist, MAX_DIST*0.0, MAX_DIST);
	}

		//lighting = lightFog(lighting, fixed4(0,0,0,0), -ray.vHit.y, 0.5, 1);
	//col = lightFog(col, skyColor, ray.vHit.y+10, 0.4+10, -0.4+10);
	return col;

	//float fGlow;
	//if(ray.bMissed)
	//{
	//	return skyColor;
	//	//col = fixed4(0,0,0,1); // black
	//	//fGlow = 0.1/ray.minDist;
	//	//col = lightFog(col, fogColor, ray.dist, MAX_DIST*0.5, MAX_DIST);
	//}
	//else
	//{
	//	//col = fixed4(ray.vNorm,1);
	//	//return col;
	//	//fGlow=0;
	//	float3 reflected = reflect(ray.vRayDir, ray.vNorm);
	//	rayData ray2 = castRay(ray.vHit/*+ ray.vNorm*/, reflected);
	//	

	//	col = simpleLightPoint(ray);
	//	fixed4 col2 = simpleLightPoint(ray2);
	//	float fac = 0.5;
	//	col=(col*(1-fac)+col2*fac);
	//	//col = col*col2*2;

	//	//float3 vSunDir = normalize(float3(8,4,2));
	//	float3 vSunDir = ObjSpaceLightDir(float4(ray.vHit,1));
	//	float4 vLightColor = _LightColor0;

	//	// AO based on normal
	//	//col.xyz *= -dot(ray.vNorm, ray.vRayDir);	
	//	//col.xyz*=lightSSAO(ray, 4);
	//	//col.xyz*=lightSun(ray.vNorm, float3(8,4,2), vLightColor);
	//	//col.xyz*=lightSky(reflected);

	//	col.xyz*=0.9;
	//	//col.xyz*= lightShadow(ray.vHit+ray.vNorm*0.01, vSunDir, 50);

	//	//rayData ray2 = castRay(ray.vHit, vSunDir, 0);
	//	//float fSunLight = max(dot(ray.vNorm, vSunDir), 0);
	//	//col*=fSunLight;
	//	//col*=lightAO(ray.vHit, ray.vNorm);
	//	col = lightFog(col, fogColor, ray.dist, MAX_DIST*0.5, MAX_DIST);
	//}
	////fogColor.xyz *= fGlow;



	//// Base on "sunlight" direction
	////col.xyz *= dot(ray.vNorm, vSunDir);	

	//return col;
}

// TODO: Subpixel ray split could be done.

// With ray point and dir, calc color
// ro - ray origin
// rd - ray direction
// this is a recursive algorithm in an iterative form.
fixed4 rendererCalculateColor(float3 ro, float3 rd, float startDist, int numLevels)
{
	numLevels = 1;
	fixed4 sumCol = fixed4(0,0,0,0); // Running sum of light*color for the final color output.
	fixed4 prodCol = fixed4(1,1,1,1); // Product of all colors (without light)
	float currentDist = startDist;

	for (int i=0; i<numLevels; i++)	
	{
		rayData ray = castRay(ro, rd);
		float3 pos = ray.vHit;
		currentDist+=ray.dist;
		
		fixed4 dcol; // direct lighting color

		material mat = calcMaterial(pos); // surface material
		// missed -> loop should exit.
		if (ray.bMissed) 
		{
			if (i==0) // never interacted with object
			{
				dcol = worldGetBackground(rd); 
				//discard;
			}
			else
			{
				dcol = worldGetBackground(rd, 1-mat.fSmoothness);
			}
			//discard; // will possibly haunt me later
			sumCol += prodCol*dcol;
			break;
			//if (i == 0) {sumCol = dcol; break;}
			//else 
			//{
			//	sumCol += prodCol*dcol;
			//	break;
			//}
		}

		//return fixed4(smoothstep(0,2,ray.dist),0,1,1);

		float3 nor = getNormFull(pos);

		dcol = 1*worldApplyLighting(pos, nor, rd);

		fixed4 surfCol = calcMaterial(pos).col; // surface color

		prodCol*=surfCol;

		sumCol += prodCol*dcol;

		
		// get new ray dir for next iteration
		ro = pos;
		if (mat.fSmoothness>0.5)
			rd = reflect(rd, nor);
		else
			rd = refract(rd, nor, 0.90);
		//rd = refractionWithTotalReflection(rd, nor, 0.8);

		//return worldGetBackground(rd, 1-mat.fSmoothness);
		return worldGetBackground(rd, 0);
		//float3 thing = pos*40;
		//float shift = 100;
		//rd = normalize(rd+0.3*float3(snoise(thing),snoise(pos + shift),snoise(pos + shift*2)));

		//fcol *= scol;
		//tcol += fcol*dcol;
		//tcol = fcol*dcol;
		//return mat.col*lighting;

	}
	return sumCol;
}

#endif
