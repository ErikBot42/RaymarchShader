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
	o.normal = normal;

	o.vDir = normalize(o.vHitPos - o.vCamPos);
	o.vCamPos *=1;

	// Random vector calc
	o.vSdfConfig = getNoise4(_Time.x*1);

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
    fragOut o;
	vSdfConfig = i.vSdfConfig;


    float3 vRayDir = normalize(i.vHitPos - i.vCamPos);
	//bool useStartDist = i.distEstimate.x>0;//dot(i.normal, vRayDir)<0;
	float3 vRayStart = i.vCamPos;	
	//float3 vRayStart = i.vHitPos;
	//float3 vRayStart = useStartDist ? i.vHitPos : i.vCamPos;	

	//float distEstimate;
	//bool estimateHit = RayTraceSphere(distEstimate, vRayStart, vRayDir, .5, 0);
	//if (!estimateHit) discard;
	//bool useStartDist = estimateHit;

	float startDist = 0;//distEstimate;
	//if(useStartDist) startDist = length(i.vHitPos-i.vCamPos);

	//o.col = fixed4(distEstimate, 0,0,1);
	//return o;

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
    //o.col = lightPoint(ray);
	float3 vHitPos;
	o.col = rendererCalculateColor(vRayStart, vRayDir, vHitPos, startDist, 2);

	#ifdef VERTEX_DEBUG_COLORS
	o.col.b = 1;
	o.col.g = o.col.w;
	o.col.w = 1;
	o.col.r = 1/i.distEstimate;
	#endif

	#ifdef USE_VERTEX_COLOR
	o.col = i.color;
	#endif
	//o.col.rgb = useStartDist? fixed3(1,0,0) : fixed3(0,0,1);

	// writing to depth buffer costs about 1-2 frames at 4k -> very cheap
	float4 zPoint = float4(vHitPos,1);
	#ifndef USE_WORLD_SPACE
	zPoint = mul(unity_ObjectToWorld, zPoint);
	#endif 
	float4 vClipPos = mul(UNITY_MATRIX_VP, zPoint);
	o.depth = (vClipPos.z / vClipPos.w + 1.0) * 0.5;
	//o.depth = 0.5;

	
	//o.col.b = o.depth/2.0;
	//o.col.r = 1-o.depth/2.0;

	//#ifndef ENABLE_TRANSPARENCY
	//o.col *= o.col.w;
	//o.col.w = 1;
	//#endif
   	
    return o;
}
#endif

//gets normal of a point
inline float3 getNormFull(float3 vPos, float fEpsilon = 0.001)
{
    //if epsilon is smaller than 0.001, there are often artifacts
    const float2 e = float2(fEpsilon, 0);
    float3 n = sdf(vPos).x - float3(
            sdf(vPos - e.xyy).x,
            sdf(vPos - e.yxy).x,
            sdf(vPos - e.yyx).x);
    return normalize(n);
}
//gets normal, provided you have the distance for pos (1 less call to sdf())
inline float3 getNorm(float3 vPos, float fPointDist, float fEpsilon = 0.001)
{
    //if epilon is smaller than 0.001, there are often artifacts
    const float2 e = float2(fEpsilon, 0);
    float3 n = fPointDist - float3(
            sdf(vPos - e.xyy).x,
            sdf(vPos - e.yxy).x,
            sdf(vPos - e.yyx).x);
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

// simplified and optimized raycast
// should not contain any branching that isn't absolutely nessesary
rayDataMinimal castRayMinimal(float3 ro, float3 rd, float startDist=0, float startDistToleranceOffset=0, float maxDist = MAX_DIST)
{
	rayDataMinimal data;
	int i;
	float t = startDist;
	for (i=0; i<MAX_STEPS && t<maxDist; i++)
	{
		float3 pos = ro + rd*t;
		float h = sdf(pos);
		t+=h;

		float tol = TOLERANCE((t+startDistToleranceOffset));

		data.fLastDist = h;
		data.fLastTolerance = tol;

		if (abs(h)<tol) break;
	}
	data.bMissed = t>maxDist;
	data.iSteps = i;
	data.dist = t;
	return data;
}

// Raycast inside object (sdf MUST be signed for this to work).
// Max dist irrelevant since inside object.
// Will probably work well if the number of steps is low since 
// only the normal of this is relevant later.
// Start length should be >> 0 to make sure ray starts inside object
// Return dist.
float insideCastRay(in float3 vRayStart, const float3 vDir, const int iSteps, const float fSurfaceDist, const float fStartLength=0)
{
	float fRayLen = fStartLength;
	int i;
	for(i = 0; i<iSteps; i++)
	{
		float3 vPos = vDir*fRayLen;
        float dist = -sdf(vPos); // -sdf = inside object
		if (dist < fSurfaceDist) break;
        fRayLen += dist;
	}
	return i;
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


// get background light from dir.
fixed3 worldGetBackground( in float3 dir, in float rough = 0.0)
{
	// https://stackoverflow.com/questions/53910092/how-can-i-get-the-lighting-information-from-a-skybox
	fixed3 col = DecodeHDR(UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, dir, rough*6), unity_SpecCube0_HDR);
	//return col;
	//col += smoothstep(0.85,1.01,dot(dir, light2))*float4(light2_col,1);
	//col += smoothstep(0.98,1.02,dot(dir, light2))*float4(light2_col,1);
	//col += 0.5*smoothstep(0.9995,0.999958816,dot(dir, light2))*float4(light2_col,1);
	//col += 0.5*smoothstep(0.9995,0.999958816,dot(dir, light2))*float4(1,1,1,1);
	//col += smoothstep(-0.0,-0.8,dir.y)*fixed4(1,0,1,1)*0.4;
	return col;
	//fixed4 light1_col = fixed4(0.3,0.7,0.9,1);
	//float fac=0.3;
	//fixed4 col = light1_col * min(1,dir.y+0.2);
	//col += fixed4(0.9,0.7,0.2,1)*max(0,dir.y-0.8)*3;
	//return col;
	//return lightSky2(dir);//*(1-fac+fac*snoise(dir*10));
}

// get background light, transformed
fixed3 worldGetBackgroundLocalSpace( in float3 rd, in float rough = 0.0)
{
	#ifndef USE_WORLD_SPACE
	rd = mul(unity_ObjectToWorld, rd);
	#endif
	return worldGetBackground(rd, rough);
}

light createDirectionalLight(float3 pos, float3 dir, fixed3 col, float intensity = 1, float dist = 2, float k=20)
{
	light l; l.dir = dir; l.col = col; l.k = k; l.intensity = intensity; l.dist = dist;
	//l.intensity*=max(0.0,dot(pos, dir));
	#ifndef USE_WORLD_SPACE
	l.dir = mul(unity_WorldToObject,l.dir);
	#endif
	return l;
}

light createPointLight(float3 pos, float3 p, fixed3 col, float intensity = 1, float k = 5)
{
	light l; l.col = col; l.k = k; l.intensity = intensity;
	l.dir = normalize(p-pos);
	//#ifndef USE_WORLD_SPACE
	//l.dir = mul(unity_WorldToObject,l.dir);
	//#endif
	l.dist = max(0,length(pos-p));
	float maxDist = .4;//.4;
	l.intensity = .02*(1/(l.dist*l.dist)-1/(maxDist*maxDist));
	return l;
}




light getMainLight(float3 pos)
{	
	fixed3 col = fixed3(237.0/255.0, 213.0/255.0, 158.0/255.0);
	//return createDirectionalLight(pos, float3(0,1,0), col);
	float3 p = 0;//vSdfConfig.xyz*0.2;
	return createPointLight(pos, p, col);
	
	light l;
	#if 0
	//centered point light
	l.k = 10;
	float t = 0;//_Time.z*1;
	float radius = .0;//0.05;
	l.dir = normalize(p-pos);
	l.dist = max(0,length(pos-p)-radius);
	//l.col*=0.1/pow(l.dist+radius,1);
	l.col*=0.03/pow(l.dist+radius,2);
	#else
	l.col*=.5;
	#endif

	
	//int i = 0;
	//l.dir = float3(unity_4LightPosX0[i], unity_4LightPosY0[i], unity_4LightPosZ0[i]);
	return l;
}

fixed3 lightToColor(light l, float3 ro, float3 rd, float3 nor)
{
	bool realLight = false;

	float diffuse = 0;
	float specular = 0;
	float lightAmount = 1;
	if (l.intensity <= 0) return 0;

	if (realLight && l.dist>0)
	{
		lightAmount = lightSoftShadow3(ro, l.dir, .05, l.dist, l.k);
	}
	lightAmount*=l.intensity*2;

	//return l.col*lightAmount*0.2;

	//specular = lightAmount*pow(saturate(dot(normalize(l.dir - rd),nor)),41);
	diffuse = lightAmount*saturate(dot(nor,l.dir));
	return l.col * (specular + diffuse);
}

// calc the direct light a point recives (including shadows)
fixed3 worldApplyLighting(in float3 pos, in float3 nor, in float3 dir, in float AOfactor = 1, float stepBack = 0.001, float tolerance=0.001)
{
	//float light1_angle = 0.1;
	//light l = getMainLight(pos);

	light l;
    fixed3 sunCol = fixed3(237.0/255.0, 213.0/255.0, 158.0/255.0);
	fixed3 ambientColor = fixed3(135.0/255.0, 206.0/255.0, 235/255.0);
	fixed3 glowColor = HSV(length(pos)*2,1,1);
	fixed3 col = 0;

	col += .1*ambientColor*.4*AOfactor;// "ambient"
	//col += 3*(1-AOfactor)*glowColor;

	//l = createDirectionalLight(pos, float3(0,1,0), sunCol); 
	//l = createPointLight(pos, float3(0,0,0), float3(1,1,1));
	
	//col += light1_col * lightSoftShadow(newStartPoint, light1);
	//col += light1_col * lightSoftShadow(newStartPoint, light1, 20);
	//col += light2_col * lightSoftShadow(newStartPoint, light2, 20);
	
	float3 reflected = reflect(dir, nor);
	float time = _Time.z*.05;//123.543254626;
	float3 p = float3(sin(time), 0, cos(time))*0.25;

	float pi = 3.1415*2;
	float amplitude = .4;
	float innerAmplitude = .2*amplitude;

	float brightness = 1;


	
	const int maxJ = 2;
	const int numlights = 4;
	brightness/=float(numlights);
	
	//for (int j = 0; j<numlights; j++)
	float3 lightsCol = 0;
	for (int i = 0; i<numlights; i++)
	{
		if (true || sin(2*time*i+numlights)>0) 
		{
			float prop = float(i)/float(numlights);
			for (int j = 0; j<maxJ; j++)
			{	
				float intensity = j==0 ? 1 : .3;
				float t = time*4 + pi*prop;
				float jProp = (float(j)+.5)/float(maxJ);
				float totalProp = prop + jProp/float(numlights);
				float jHeight = .8*sin(jProp*pi);
				float propID = 2+sin(30*(prop + jProp + 1));
				float a = amplitude * (1-pow(.5 +.5*sin(propID*time*2),4));
				l = createPointLight(pos, normalize(float3(sin(t), jHeight, cos(t)))*a, HSV(prop, 1, brightness*intensity));
				lightsCol += lightToColor(l, pos, dir, nor);
			}
		}
	}
	col += lightsCol;
	
	//glowColor = lightsCol;


	//if (sin(time*1)>0) {l = createPointLight(pos, float3(sin(time+pi*0.00),  1, cos(time+pi*0.00))*amplitude, HSV(0,     1, brightness)); col += lightToColor(l, pos, dir, nor);}
	//if (sin(time*2)>0) {l = createPointLight(pos, float3(sin(time+pi*0.25),  1, cos(time+pi*0.25))*amplitude, HSV(0.25,  1, brightness)); col += lightToColor(l, pos, dir, nor);}
	//if (sin(time*3)>0) {l = createPointLight(pos, float3(sin(time+pi*0.5 ),  1, cos(time+pi*0.5 ))*amplitude, HSV(0.5,   1, brightness)); col += lightToColor(l, pos, dir, nor);}
	//if (sin(time*4)>0) {l = createPointLight(pos, float3(sin(time+pi*0.75),  1, cos(time+pi*0.75))*amplitude, HSV(0.75,  1, brightness)); col += lightToColor(l, pos, dir, nor);}
	//if (sin(time*5)>0) {l = createPointLight(pos, float3(sin(time+pi*0.00), -1, cos(time+pi*0.00))*amplitude, HSV(0.125, 1, brightness)); col += lightToColor(l, pos, dir, nor);}
	//if (sin(time*6)>0) {l = createPointLight(pos, float3(sin(time+pi*0.25), -1, cos(time+pi*0.25))*amplitude, HSV(0.375, 1, brightness)); col += lightToColor(l, pos, dir, nor);}
	//if (sin(time*7)>0) {l = createPointLight(pos, float3(sin(time+pi*0.5 ), -1, cos(time+pi*0.5 ))*amplitude, HSV(0.625, 1, brightness)); col += lightToColor(l, pos, dir, nor);}
	//if (sin(time*8)>0) {l = createPointLight(pos, float3(sin(time+pi*0.75), -1, cos(time+pi*0.75))*amplitude, HSV(0.875, 1, brightness)); col += lightToColor(l, pos, dir, nor);}
	return col;
#if 1
	//col += light1_col * lightSoftShadow2(newStartPoint, light1, k);
	//col += light2_col * lightSoftShadow2(newStartPoint, light2, k) * max(0, dot(light2, nor));

	//#ifndef USE_WORLD_SPACE
	//l.dir = mul(unity_WorldToObject,l.dir);
	//#endif
	//col += 1.0*light2_col * max(0, dot(light2, nor)+0.6);//* 1 * max(dot(pos, light2)+0.3-0.3,0);

	//col += 1*l.col * lightSoftShadow2(newStartPoint, l.dir, k, tolerance) * (pow(saturate(dot(normalize(l.dir - dir),nor)),50)*2 + saturate(dot(nor,l.dir)));
	float3 diffuse;
	float3 specular;
	float lightAmount = 1;
	if (false && l.dist>0)
	{
		//float3 newStartPoint = pos + nor*stepBack;
	 	//lightAmount = lightSoftShadow2(newStartPoint, l.dir, k, tolerance, l.dist);
		lightAmount = lightSoftShadow3(pos, l.dir, .001, l.dist, l.k);
	}
	lightAmount*=l.intensity;

	specular = l.col*lightAmount*pow(saturate(dot(normalize(l.dir - dir),nor)),200)*2;
	diffuse = l.col*2*lightAmount*saturate(dot(nor,l.dir));

	//col += (l.col * diffuse + fixed3(1,1,1)*specular);
	col += (diffuse + specular);
	
	//col += 1*l.col * lightSoftShadow2(newStartPoint, l.dir, k, tolerance,l.dist) * (pow(saturate(dot(normalize(l.dir - dir),nor)),50)*2 + saturate(dot(nor,l.dir)));
	//col += 2*light2_col * lightSoftShadow2(newStartPoint, light2, k, tolerance);
	//col += worldGetBackground(reflected);
	//col += worldGetBackground(nor);
#else

	float minLight = 0.0;
	//col += (max(minLight,dot(nor, light1))-minLight)*light1_col*10;
	//col += (max(minLight,dot(nor, light2))-minLight)*light2_col*10;
	//col += (max(minLight,dot(nor, light3))-minLight)*light3_col*10;
	
	float refFactor = 1;//dot(dir, -nor)*2;

	col += worldGetBackground(reflected, 1)*refFactor;
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
	
	return col;
}

//TODO: emmision, reflections
// glow?
// soft shadows



fixed4 lightPoint(rayData ray)
{
	return fixed4(1,1,1,1);
//	fixed4 col;
//	fixed4 skyColor = fixed4(worldGetBackground(ray.vRayDir),1);
//	fixed4 fogColor = skyColor;//, unity_FogColor);
//
//	// TODO: MAKE PROPER RECURSIVE REFLECTION MODEL!!!
//	if (ray.bMissed)
//	{
//		col = skyColor;
//	}
//	else
//	{
//		float3 normal = getNormFull(ray.vHit);//+snoise(ray.vHit*50)*0.2;
//		col = ray.mat.col*0.2;
//
//		fixed3 directLighting = worldApplyLighting(ray.vHit, normal, ray.vRayDir);
//		float3 reflected = reflect(ray.vRayDir, normal);
//
//		//float3 reflected2 = normalize(reflected+rand3dTo1d(ray.vHit*100)*0.01);
//		float3 reflected2 = reflected;
//
//		rayData ray2 = castRay(ray.vHit+normal*0.001,reflect(ray.vRayDir, normal));
//
//		float3 normal2 = getNormFull(ray.vHit);
//		//if (!ray2.bMissed)
//		//{
//		//	normal2 = getNormFull(ray.vHit);
//		//	ray2 = castRay(ray2.vHit+normal2*0.001,reflect(ray2.vRayDir, normal));
//		//}
//
//		//if (!ray2.bMissed)
//		//{
//		//	normal2 = getNormFull(ray.vHit);
//		//	ray2 = castRay(ray2.vHit+normal2*0.001,reflect(ray2.vRayDir, normal));
//		//}
//
//		fixed4 indirectLighting = ray2.bMissed ? fixed4(worldGetBackground(ray2.vRayDir),1) : ray2.mat.col*worldApplyLighting(ray2.vHit, normal2, ray2.vRayDir);
//		
//		float fac = .5;//1-ray.mat.fSmoothness;//0.3;
//		fixed4 lighting = 1*directLighting*fac + indirectLighting*(1-fac);
//
//		//lighting *= 0.6+lightSSAO(ray, 5);
//		//lighting += 0*0.1*lightAO(ray.vHit, normal, 0.01);
//		//lighting = fixed4(1,1,1,1)*0.3;
//		// Hack to make bottom darker
//		//lighting = lightFog(lighting, skyColor, ray.vHit.y+positiveOffset, 0.4+positiveOffset, -0.4+positiveOffset);
//
//
//		col *= lighting*4;
//		
//
//		//col.xyz *= lightAO(ray.vHit, normal, 0.01);
//		//col.xyz*=lightSSAO(ray, 30)*5;
//		//col = fixed4(1,1,1,1);
//		//col *= dot(light1,normal);
//		
//		//col.g = (ray.vHit.y+0.5);
//
//		//col = pow(col, 1.0/2.2);//gamma
//		//col = lightFog(col, skyColor, ray.dist, MAX_DIST*0.0, MAX_DIST);
//	}
//
//		//lighting = lightFog(lighting, fixed4(0,0,0,0), -ray.vHit.y, 0.5, 1);
//	//col = lightFog(col, skyColor, ray.vHit.y+10, 0.4+10, -0.4+10);
//	return col;
//
//	//float fGlow;
//	//if(ray.bMissed)
//	//{
//	//	return skyColor;
//	//	//col = fixed4(0,0,0,1); // black
//	//	//fGlow = 0.1/ray.minDist;
//	//	//col = lightFog(col, fogColor, ray.dist, MAX_DIST*0.5, MAX_DIST);
//	//}
//	//else
//	//{
//	//	//col = fixed4(ray.vNorm,1);
//	//	//return col;
//	//	//fGlow=0;
//	//	float3 reflected = reflect(ray.vRayDir, ray.vNorm);
//	//	rayData ray2 = castRay(ray.vHit/*+ ray.vNorm*/, reflected);
//	//	
//
//	//	col = simpleLightPoint(ray);
//	//	fixed4 col2 = simpleLightPoint(ray2);
//	//	float fac = 0.5;
//	//	col=(col*(1-fac)+col2*fac);
//	//	//col = col*col2*2;
//
//	//	//float3 vSunDir = normalize(float3(8,4,2));
//	//	float3 vSunDir = ObjSpaceLightDir(float4(ray.vHit,1));
//	//	float4 vLightColor = _LightColor0;
//
//	//	// AO based on normal
//	//	//col.xyz *= -dot(ray.vNorm, ray.vRayDir);	
//	//	//col.xyz*=lightSSAO(ray, 4);
//	//	//col.xyz*=lightSun(ray.vNorm, float3(8,4,2), vLightColor);
//	//	//col.xyz*=lightSky(reflected);
//
//	//	col.xyz*=0.9;
//	//	//col.xyz*= lightShadow(ray.vHit+ray.vNorm*0.01, vSunDir, 50);
//
//	//	//rayData ray2 = castRay(ray.vHit, vSunDir, 0);
//	//	//float fSunLight = max(dot(ray.vNorm, vSunDir), 0);
//	//	//col*=fSunLight;
//	//	//col*=lightAO(ray.vHit, ray.vNorm);
//	//	col = lightFog(col, fogColor, ray.dist, MAX_DIST*0.5, MAX_DIST);
//	//}
//	////fogColor.xyz *= fGlow;
//
//
//
//	//// Base on "sunlight" direction
//	////col.xyz *= dot(ray.vNorm, vSunDir);	
//
//	//return col;
}


// TODO: Subpixel ray split could be done.
// TODO: Fix tolerance based on dist (should be based on total dist)
// TODO: Dynamic max dist to force all bounces to be inside area.
// Given that there is no stack/recursion, both reflection and refraction 
// cannot both be done at one time. Solution might be to not do recursive 
// refraction
// Specular = reflective/smooth
// Diffuse = non reflective/random reflection
// Fresnel = more reflective at a greater angle towards the normal.

// With ray point and dir, calc color
// ro - ray origin
// rd - ray direction
// this is a recursive algorithm in an iterative form.
fixed4 rendererCalculateColor(float3 ro, float3 rd, out float3 vHitPos, float startDist, int numLevels)
{
	numLevels = 1;//3;
	fixed3 sumCol = fixed3(0,0,0); // Running sum of light*color for the final color output.
	fixed3 prodCol = fixed3(1,1,1); // Product of all colors (without light)
	float currentDist = startDist;

	bool fakeLastReflection = false;
	if (fakeLastReflection) numLevels += 1;

	for (int i=0; i<numLevels; i++)	
	{
		rayDataMinimal ray;
		
		// Raycast prediction to get start dist and max dist
		float maxDist;
		bool estimateHit = RayTraceSphere(startDist, maxDist, ro, rd, .5, 0);

		if (estimateHit)
		{
			// Actual raymarch
			if (i!=(numLevels-1) || i == 0 || (!fakeLastReflection))
				ray = castRayMinimal(ro, rd, startDist, currentDist-startDist, maxDist);//, float startDist=0, float startDistToleranceOffset=0)
			else
			{
				//ray.iSteps = MAX_STEPS;
				prodCol*=0.5;
				ray.dist=0;
				ray.bMissed=true;
			}
		}
		else
		{
			ray.dist = 0;
			ray.bMissed=true;
		}

		float3 pos = ro + ray.dist*rd;
		if (i==0) 
		{
			vHitPos = pos; 
			startDist = 0;
		}
		currentDist += ray.dist;
		
		fixed3 dcol;// = fixed3(1,1,1) * 0.0; // direct lighting color

		material mat = calcMaterial(pos); // surface material
		
		if (ray.bMissed) // missed -> loop should exit.
		{
			#ifndef USE_WORLD_SPACE
			rd = mul(unity_ObjectToWorld,rd);
			#endif
			if (i==0) // never interacted with object
			{
				dcol = fixed4(worldGetBackground(rd),1); 
				discard; // optional
			}
			else
			{
				dcol = fixed4(worldGetBackground(rd, 1-mat.fSmoothness),1);
			}
			sumCol += prodCol*dcol;
			break;
		}

		float tol = ray.fLastTolerance;

		float3 nor = getNormFull(pos, tol);

		//float fAOfactor = lightSSAO(ray.iSteps, MAX_STEPS, 3);
		float fAOfactor = smoothSSAO(ray.iSteps, MAX_STEPS, ray.fLastDist, ray.fLastTolerance, 4);

		dcol = 1*worldApplyLighting(pos, nor, rd, fAOfactor);
		//dcol = 1*worldApplyLighting(pos, nor, rd, .5);

		fixed3 surfCol = calcMaterial(pos, sdf(pos).yzw).col.rgb; // surface color
		
		const float nIndex = 1.5;//1.5;

		//fixed3 refracted = refract(rd, nor, 1/nIndex);
		//dcol = worldGetBackgroundLocalSpace(refracted,.0);//*fAOfactor*2;//*surfCol;
		//return fixed4(dcol,1);


		prodCol*=surfCol;

		sumCol += prodCol*dcol;




		
		// get new ray dir for next iteration
		rd = reflect(rd, nor);
		
		//TODO: rd>>nor fix linear algebra and stuff.
		ro = pos + nor*TOLERANCE(currentDist-startDist)*1.5; // margin to prevent hitting object again



		//col += worldGetBackground(rd)*
		//if (1)
		//else
		//rd = refract(rd, nor, 1.0/1.3);
		 
		/*float fac = 0.5*_SinTime.z;
		float fac2 = 1;
		float n_r = fac2*(1.520-fac);
		float n_g = 1.2;//2.4168;//fac2*(1.526);
		float n_b = fac2*(1.531+fac);

		float fakeDist;

		float3 rd_r = refractLightFakeSphere(rd, nor, fakeDist, n_r);
		float3 rd_g = refractLightFakeSphere(rd, nor, fakeDist, n_g);
		float3 rd_b = refractLightFakeSphere(rd, nor, fakeDist, n_b);

		#if 0
		fixed4 refracted = fixed4(
			worldGetBackground(rd_r, 1-mat.fSmoothness).r,
			worldGetBackground(rd_g, 1-mat.fSmoothness).g,
			worldGetBackground(rd_b, 1-mat.fSmoothness).b,
			1
		);
		#else
		fixed4 refracted = worldGetBackground(rd_g, 1-mat.fSmoothness);
		#endif

		float3 rd_reflected = reflect(rd, nor);

		fixed4 reflected = worldGetBackground(rd_reflected, 1-mat.fSmoothness)*fixed4(1,1,1,1);

		//float reflectance_r = calcReflectance(dot(rd_reflected, nor), 1, n_r);
		float reflectance_g = calcReflectance(dot(rd_reflected, nor), 1, n_g);
		//float reflectance_b = calcReflectance(dot(rd_reflected, nor), 1, n_b);
		
		#if 0
		fixed4 col = fixed4(
			reflected.r*reflectance_r + refracted.r*(1-reflectance_r),
			reflected.g*reflectance_g + refracted.g*(1-reflectance_g),
			reflected.b*reflectance_b + refracted.b*(1-reflectance_b),
			1);

		#else
		fixed4 col = reflected*reflectance_g + refracted*(1-reflectance_g);
		#endif

		return col;
		*/	

		//ro += -nor*0.001;
		//float insideDist = insideCastRay(ro, rd, 1000, 0.0001, 0);
		//ro += insideDist*rd*1;

		//fixed4 col = fixed4(1,1,1,1);
		//float fac = 50;
		//col.r = max(0,sdf(ro))*fac;
		//col.b = max(0,-sdf(ro))*fac;

		////return col;

		//nor = getNormFull(ro);

		//rd = refract(rd, nor, 1.0/1.52);
		//if (length(rd)<0.9) return fixed4(1,0,0,1);
		//rd = refractionWithTotalReflection(rd, nor, 0.8);

		//return worldGetBackground(rd_r, 1-mat.fSmoothness);
		//return worldGetBackground(rd, 1-mat.fSmoothness);
		//float3 thing = pos*40;
		//float shift = 100;
		//rd = normalize(rd+0.3*float3(snoise(thing),snoise(pos + shift),snoise(pos + shift*2)));

		//fcol *= scol;
		//tcol += fcol*dcol;
		//tcol = fcol*dcol;
		//return mat.col*lighting;

	}

	return fixed4(sumCol,1);
}

#endif
