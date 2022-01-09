#ifndef RAYMARCHLIB_CGINC
#define RAYMARCHLIB_CGINC


// TODO: noise/random/hash in separate file.
// TODO: file reorganize, split into 
//       renderer + api to allow for raytrace &
//       more importantly force a split of the 
//       code into more logical parts.
// TODO: gamma apply/revert functions.
// TODO: refraction
// TODO: SS glow
// TODO: fix norm to make it slightly cheaper, tetrahedron?
// TODO: step back fix: reflect + light
// TODO: fog based glow / foggy objects with refraction?
// TODO: emmision
// glow?
// soft shadows logic with k
// TODO: make potentially compatible with any game engine
// TODO: make psudo-compatible with other shading languages
//       or port to another more general shading language
// TODO: figure out how to calculate fragment tolerance
// TODO: light max dist
// TODO: procedural textures


#include "UnityCG.cginc"
#include "RayMarchLib.h"
#include "SdfFunctions.cginc"
#include "SdfMath.cginc"
#include "Transforms.cginc"
#include "FastMath.cginc"
#include "RayMarchUtil.cginc"
#include "Noise.cginc"
#include "RayTraceFunctions.cginc"
#include "Lighting.cginc"

#include "RenderCore.h"

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

fragOut frag (v2f i)
{
    fragOut o;
	vSdfConfig = i.vSdfConfig;

    float3 vRayDir = normalize(i.vHitPos - i.vCamPos);
	float3 vRayStart = i.vCamPos;	

	float startDist = 0;

	float3 vHitPos;
	o.col = multiSampledRendererCalculateColor(vRayStart, vRayDir, vHitPos, startDist, 2);
	o.col.w = 1;

	#ifdef VERTEX_DEBUG_COLORS
	o.col.b = 1;
	o.col.g = o.col.w;
	o.col.w = 1;
	o.col.r = 1/i.distEstimate;
	#endif

	#ifdef USE_VERTEX_COLOR
	o.col = i.color;
	#endif

	// writing to depth buffer is very cheap but not free
	//float4 zPoint = float4(vHitPos,1);
	//#ifndef USE_WORLD_SPACE
	//zPoint = mul(unity_ObjectToWorld, zPoint);
	//#endif 
	//float4 vClipPos = mul(UNITY_MATRIX_VP, zPoint);
	//o.depth = (vClipPos.z / vClipPos.w + 1.0) * 0.5;
   	
    return o;
}

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
// TODO: MOVE
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

#define ZERO (_Time.x<0)

// simplified and optimized raycast
// should not contain any branching that isn't absolutely nessesary
rayDataMinimal castRayMinimal(float3 ro, float3 rd, float startDist=0, float startDistToleranceOffset=0, float maxDist = MAX_DIST)
{

	rayDataMinimal data;
	int i;
    int st = MAX_STEPS;
	float t = startDist;
	float tol = 0;
	[loop] for (i=0; i<(MAX_STEPS+ZERO); i++)
	{
        [branch] if (t>maxDist) {st = min(st, i); break;}
		float3 pos = ro + rd*t;
		float h = sdf(pos, tol);
		t+=h;

		tol = TOLERANCE((t+startDistToleranceOffset));

		data.fLastDist = h;
		data.fLastTolerance = tol;
		[branch] if (abs(h)<tol) {st = min(st, i); break;}
	}
    data.iSteps=st;//i
	data.bMissed = t>maxDist;
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
    //return lightSun(dir, normalize(float3(-8,4,2)));
    //return sky(dir);
    //return pow(dot(dir, normalize(float3(1,1,1))),9);
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

light createDirectionalLight(float3 pos, float3 dir, fixed3 col, float intensity = 1, float dist = 3, float k=20)
{
	light l; l.dir = dir; l.col = col; l.k = k; l.intensity = intensity; l.dist = dist;
	#ifndef USE_WORLD_SPACE
	l.dir = mul(unity_WorldToObject,l.dir);
	#endif
	//l.intensity*=max(0.0,dot(pos, l.dir));
	return l;
}

light createPointLight(float3 pos, float3 p, fixed3 col, float intensity = 1, float k = 5)
{
	light l; l.col = col; l.k = k; l.intensity = intensity;
	l.dir = normalize(p-pos);

	float maxDist = 2;//.4;//.2;//.8;//.4;
	float innerRadius = maxDist/8.0/8;


	float dist = max(0,length(pos-p));

	l.dist = dist - innerRadius;
	if (dist > maxDist) 
	{
		l.intensity = 0;
	}
	else if (dist > innerRadius)
	{
		float inverseSquaredInnerRadius = 1.0/(innerRadius*innerRadius);
		float inverseSquaredMaxDist = 1.0/(maxDist*maxDist);
		float inverseSquaredDist = 1.0/(dist*dist);

		l.intensity*=(inverseSquaredDist-inverseSquaredMaxDist)/(inverseSquaredInnerRadius-inverseSquaredMaxDist);
	}
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

fixed3 lightToColor(light l, float3 ro, float3 rd, float3 nor, bool realLight = false, bool useNorm = false)
{
	float diffuse = 0;
	float specular = 0;
	float lightAmount = 1;
	if (l.intensity <= 0) return 0;

	if (realLight && l.dist>0)
	{
		lightAmount = lightSoftShadow3(ro, l.dir, /*.01*/ 0.001*10, l.dist, l.k);
        //lightAmount = lightSoftShadow4(ro, rd, 0.001, l.dist, 0.001);
	}
	lightAmount*=l.intensity*2;

	//return l.col*lightAmount*0.2;
    if (useNorm)
    {
        specular = lightAmount*pow(saturate(dot(normalize(l.dir - rd),nor)),50);
        diffuse = lightAmount*saturate(dot(nor,l.dir));
        return l.col * (specular*2 + diffuse);
    }
    else
    {
        return l.col*lightAmount;
    }
}

fixed3 severalLightToCol(const light lights[2], const int numLights, float3 pos, float3 dir, float3 nor)
{
    fixed3 col = 0;
    for (int i = 0; i<numLights; i++)
    {
        col += lightToColor(lights[i], pos, dir, nor, true, true);
    }
    return col;
}

// calc the direct light a point recives (including shadows)
fixed3 worldApplyLighting(in float3 pos, in float3 dir, in float3 nor, in float AOfactor = 1, bool useNorm = true, float stepBack = 0.001, float tolerance=0.001)
{

	light l;
    fixed3 sunCol = fixed3(237.0/255.0, 213.0/255.0, 158.0/255.0);
	fixed3 ambientColor = fixed3(135.0/255.0, 206.0/255.0, 235/255.0);
	fixed3 glowColor = HSV(length(pos)*2,1,1);
	fixed3 col = 0;
	
	#ifndef RENDER_WITH_GI
	col += .5*ambientColor*.4*AOfactor;// "ambient"
	#endif

	//col += 3*(1-AOfactor)*glowColor;
	//return col;

#if 0
    //float3 ldir = normalize(float3(-.5,-.5,.5));
    //l = createDirectionalLight(pos, ldir, sunCol, 1.3); //side
    //l = createDirectionalLight(pos, normalize(float3(-.15,1,.1)), sunCol, 1.3); //above
    //l = createDirectionalLight(pos, normalize(float3(0,1,.8)), sunCol, 1.3); 
    //l = createDirectionalLight(pos, normalize(float3(0.3,.5,1)), sunCol, 1.3); //side
    //l = createDirectionalLight(pos, normalize(float3(0.2,1,.3)), sunCol, 1.3); 
    
    l = createDirectionalLight(pos, normalize(float3(_SinTime.z,_SinTime.x/2+1.5,abs(_CosTime.z))), sunCol, 1.3); 
    //l = createDirectionalLight(pos, normalize(float3(_SinTime.z,1,_CosTime.z)), sunCol, 1.3); 
    col += lightToColor(l, pos, dir, nor, true, useNorm);
#elif 1
    //l = createPointLight(pos, float3(0,0,0), sunCol, 10*5);
    const int numLights = 2;
    float lightOffset   = .14;

    light lights[numLights];
    float time = _Time.x;
    const float off = (PI*2.0)/3.0;

    float I = 10.0*5.0;
    float facSat = 0.05;
    lights[0] = createPointLight(pos, float3(0,  lightOffset, 0), fixed3(1,      facSat, facSat), I);
    lights[1] = createPointLight(pos, -float3(0, lightOffset, 0), fixed3(facSat, facSat, 1),      I);
    //lights[0] = createPointLight(pos, lightOffset*float3(sin(time),cos(time),0), fixed3(1,   facSat, facSat), I);
    //lights[1] = createPointLight(pos, -lightOffset*float3(sin(time), cos(time),0), fixed3(facSat, facSat, 1),   I);

    //const float off = (PI*2.0)/3.0;
    //lights[0] = createPointLight(pos, lightOffset*float3(sin(time),cos(time),0), fixed3(1,   0.2, 0.2), I);
    //lights[1] = createPointLight(pos, lightOffset*float3(sin(time+off), cos(time+off),0), fixed3(0.2, 1,   0.2), I);
    //lights[2] = createPointLight(pos, lightOffset*float3(sin(time+off*2), cos(time+off*2),0), fixed3(0.2, 0.2, 1),   I);

    col += severalLightToCol(lights, numLights, pos, dir, nor);
    //col += lightToColor(lights[0], pos, dir, nor, true, useNorm);
    //col += lightToColor(lights[1], pos, dir, nor, true, useNorm);
#elif 1
    l = createPointLight(pos, float3(0,0,0), sunCol, 10*5);
    col += lightToColor(l, pos, dir, nor, true, useNorm);
#endif
    return col;
	
	//float3 reflected = reflect(dir, nor);
	//float time = _Time.z*.05;//123.543254626;
	//float3 p = float3(sin(time), 0, cos(time))*0.25;

	//float pi = 3.1415*2;
	//float amplitude = .5;//.4;
	//float innerAmplitude = .2*amplitude;

	//float brightness = 1*7;

	//
	//const int maxJ = 1;
	//const int numlights = 10;
	//brightness/=float(numlights);
	//
	//for (int i = 0; i<numlights; i++)
	//{
	//	float prop = float(i)/float(numlights);
	//	float t = time*4 + pi*prop;
	//	//if (false || sin(6*time*i+numlights)>0) 
	//	if (sin(t + 64*time)>0)
	//	{
	//		for (int j = 0; j<maxJ; j++)
	//		{	
	//			float intensity = j==0 ? 1 : .3;
	//			float jProp = (float(j)+.5)/float(maxJ);
	//			float totalProp = prop + jProp/float(numlights);
	//			float jHeight = .8*sin(jProp*pi);
	//			float propID = 2+sin(30*(prop + jProp + 1));
	//			float a = .25;//amplitude * (1-pow(.5 +.5*sin(propID*time*2),4));
	//			l = createPointLight(pos, normalize(float3(sin(t), jHeight, cos(t)))*a, HSV(prop, 1, brightness*intensity));
	//			col += lightToColor(l, pos, dir, nor, false);
	//		}
	//	}
	//}
	//
	//return col;
}




// Given that there is no stack/recursion, both reflection and refraction 
// cannot both be done at one time. Solution might be to not do recursive 
// refraction
// Specular = reflective/smooth
// Diffuse = non reflective/random reflection
// Fresnel = more reflective at a greater angle towards the normal.

#define USE_OLD_RENDERER

// With ray point and dir, calc color
// ro - ray origin
// rd - ray direction
// this is a recursive algorithm in an iterative form.
fixed4 rendererCalculateColor(float3 ro, float3 rd, out float3 vHitPos, float startDist, int numLevels)
{
	numLevels = 10;//4;//3;
	#ifdef RENDER_WITH_GI
	//numLevels = max(numLevels,4);
	numLevels = max(numLevels,4);
	#endif
    
    //#ifndef USE_OLD_RENDERER
    //#endif
	

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
				dcol = pow(fixed4(worldGetBackground(rd),1),2.2/1.0); 
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

		float fAOfactor = smoothSSAO(ray.iSteps, MAX_STEPS, ray.fLastDist, ray.fLastTolerance, 100); // agressive AO

		dcol = 1*worldApplyLighting(pos, rd, nor, fAOfactor);

		fixed3 surfCol = calcMaterial(pos, sdf(pos).yzw).col.rgb; // surface color

		prodCol*=surfCol;

		sumCol += prodCol*dcol;
		
		// get new ray dir for next iteration
#ifdef RENDER_WITH_GI
		rd = worldGetBRDFRay(ro, rd, nor);
#else
		rd = reflect(rd, nor);
#endif
		
		ro = pos + nor*TOLERANCE(currentDist-startDist)*2.5; // margin to prevent hitting object again
	}
	return fixed4(sumCol,1);
}

fixed4 multiSampledRendererCalculateColor(float3 ro, float3 rd, out float3 vHitPos, float startDist, int numLevels)
{
    bool useNew = true;
#ifndef RENDER_WITH_GI
    fixed4 col;
    if (!useNew)
    {
        col = rendererCalculateColor(ro, rd, vHitPos, startDist, numLevels);
    }
    else
    {
        rendererCalculateColorOut_t o = rendererCalculateColor(ro, rd, startDist, numLevels);
        vHitPos = ro;//o.hitPos;
        col = fixed4(o.col, 0);
        //col = 0;
    }
#else
	int3 q = rd*324789.789345;
    //q.x+=_Time.x*123879;
    int off = ihash(_Time.x*234.34798);
	srand(ihash(q.x + ihash(q.y + ihash(q.x+off))));

	int numSamples = 1;//20;//10;
	fixed4 col = 0;
	[loop] for (int i = 0; i<numSamples; i++)
	{
		float3 rd_new = normalize(rd+float3(frand(),frand(),frand())*TOLERANCE(.2));
        if (!useNew)
        {
            col += rendererCalculateColor(ro, rd_new, vHitPos, startDist, numLevels)/numSamples;
        }
        else
        {
            rendererCalculateColorOut_t o = rendererCalculateColor(ro, rd, startDist, numLevels);
            vHitPos = ro;//o.hitPos;
            col+=fixed4(o.col,1)/numSamples;
        }

		startDist = length(ro-vHitPos);
		startDist -= TOLERANCE(startDist);
	}
#endif
	return pow(col, 1.0/2.2);//gamma correction
    return col;
	//sumCol = pow(sumCol, fixed3(3.0/2.0, 4.0/5.0, 3.0/2.0)); // "matrix" colors
}

#include "RenderCore.cginc"

#endif
