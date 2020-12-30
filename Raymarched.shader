Shader "Raymarched/Raymarched"
{
    Properties
    {
        [Header(Raymarcher Properties)]
            _MaxSteps ("Max steps", Int) = 256
                _MaxDist ("Max distance", Float) = 100
                _SurfDist ("Surface distance threshold", Range(0.00001, 0.05)) = 0.001
                _Scale ("Scale", Range(0.1, 16)) = 1
                [Header(Lighting)]
                _SunPos ("Sun position", Vector) = (8, 4, 2)
                    _SkyColor ("Sky color", color) = (0.7, 0.75, 0.8, 1)
                    _bWorldSpace ("Use world space", int) = 0
                    _fDebug1 ("fDebug1", Range(0,10)) = 2
                    _iDebug1 ("iDebug1", Range(0,10)) = 2

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" 
            "LightMode"="ForwardBase" }//light stuff
        Cull Off// make stuff render even when camera is inside object
            LOD 100

            Pass
            {
                CGPROGRAM
#pragma vertex vert
#pragma fragment frag

#define vec3 float3
#define vec4 float4

#include "UnityCG.cginc"
#include "UnityLightingCommon.cginc" // for light stuff
#include "sdf.cginc"
#include "noise.cginc"

                    struct appdata
                    {
                        float4 vertex : POSITION;
                    };

                struct v2f
                {
                    float4 vertex : SV_POSITION;
                    float3 ro : TEXCOORD1;
                    float3 hitPos : TEXCOORD2;
                };

                struct rayData
                {
                    float3 color;
                    float dist;
                    int steps;
                };

                int _MaxSteps;
                float _MaxDist;
                float _SurfDist;
                float _Scale;
                float3 _SunPos;
                float4 _SkyColor;
                bool _bWorldSpace;
                float _fDebug1;
                int _iDebug1;

                v2f vert (appdata v)
                {
                    v2f o;
                    o.vertex = UnityObjectToClipPos(v.vertex);

                    if (_bWorldSpace!=0)
                    {
                        // world space
                        o.ro = _WorldSpaceCameraPos;
                        o.hitPos = mul(unity_ObjectToWorld, v.vertex);
                    }
                    else 
                    {
                        // object space
                        o.ro = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
                        o.hitPos = v.vertex;
                    }
                    return o;
                }

                //***** RAYMARCH STUFF *****

                //#define Iterations 7
                //#define Scale 1.4
#define MAX_ARR_SIZE 8

                float de_tetrahedron(vec3 p, float r) 
                {
                    float md = max(max(-p.x - p.y - p.z, p.x + p.y - p.z),
                            max(-p.x + p.y + p.z, p.x - p.y + p.z));
                    return (md - r) / (sqrt(3.0));
                }

                // DE fractal polyhedron from given points,
                // creates tetrahedron on 4 points.
                // it works by finding the closest vertex of the fractal polyhedron, O(n)
                float DE_Polyhedron(float3 z, 
                        float3 p[MAX_ARR_SIZE], 
                        int iPoints, 
                        float fScale = 2,
                        int iIterations = 2)
                {
                    float3 z0 = z;
                    //return sdSphere(z, 0, 0.02);
                    float3 closest;//current closest point

                    float fDist = 0;//current fDist to closest
                    float d = 0;

                    for (int n = 0; n < iIterations; n++) 
                    {
                        closest = p[0]; 
                        fDist = length(z-p[0]);

                        for (int i = 1; i<iPoints; i++)
                        {
                            d = length(z-p[i]);
                            if (d < fDist)
                            {
                                closest = p[i];
                                fDist = d;
                            }
                        }

                        z = fScale*z-closest*(fScale-1.0);
                    }
                    z *= pow(fScale, -n);
                    //return length(z);//sdSphere(z, 0, 0.02);
                    return de_tetrahedron(z, pow(fScale, -n)*0.2);
                }

                // Get light position 
                // max 4 for some reason >:(
                float3 getLight(int iIndex)
                {
                   float3 vPos;
                   vPos.x = unity_4LightPosX0[iIndex];
                   vPos.y = unity_4LightPosY0[iIndex];
                   vPos.z = unity_4LightPosZ0[iIndex];
                   return vPos;
                }

                // to find stuff that the raymarch can read.
                float DE_lights(float3 z)
                {
                    float d = sdSphere(z, 0, 1);
                    for (int i = 0; i<1; i++)
                    {
                        //float wp = getLight(i);
                        float3 vPos = getLight(i);
                        float d2 = sdSphere(z, vPos, 1);
                        d = smin(d,d2,0.2);
                    }
                    return d;
                }

                float DE_tetrahedronMerge(float3 z)
                {
                    //return sdSphere(z, 0, 0.5);
                    float3 p[MAX_ARR_SIZE];
                    float Spread = 0.2;
                    int nPoints = 0;
                    p[nPoints++] = float3(1,1,1) * Spread;
                    p[nPoints++] = float3(-1,1,-1) * Spread;
                    p[nPoints++] = float3(1,-1,-1) * Spread;
                    p[nPoints++] = float3(-1,-1,1) * Spread;
                    //nPoints--;
                    float d = DE_Polyhedron(z, p, nPoints,_fDebug1,_iDebug1);
                    return d;
                    float d2 = DE_Polyhedron(z + sin(_Time*0.3)/4, p, nPoints);
                    return smin(d,d2,0.02);


                }

                float DE_main(float3 z)
                {
                    //return sdTorus(z, 0, 5, 1);
                    //return sdPyramid(z, 0.5);
                    //return de_tetrahedron(z,0.2);
                    //return DE_tetrahedronMerge(z);
                    return DE_lights(z);


                }

                // Marches a ray through the scene
                rayData castRay(float3 ro, float3 rd)
                {
                    float3 mat = 0.2;
                    float rayLen = 0;// total distance marched / distance from origin
                    float dist; // distance from the raymarched scene
                    for (int i = 0; i < _MaxSteps; i++)
                    {
                        //position = origin + distance * direction
                        float3 p = (ro + rayLen * rd)/_Scale;

                        dist = DE_main(p);

                        rayLen += dist;// move forward

                        if (dist < _SurfDist) break;
                        if (rayLen > _MaxDist) break;
                    }
                    if (rayLen > _MaxDist) rayLen = -1;

                    rayData data;
                    data.dist = rayLen;
                    data.steps = i;
                    data.color = mat;

                    return data; 
                }


                float3 getNormal(float3 p)
                {
                    float2 e = float2(0.0001, 0);
                    float3 n = DE_main(p) - float3(
                            DE_main(p-e.xyy),
                            DE_main(p-e.yxy),
                            DE_main(p-e.yyx));
                    return normalize(n);
                }

                fixed4 frag (v2f i) : SV_Target
                {
                    _SunPos = float4(getLight(0),0);

                    float3 ro = i.ro;
                    float3 rd = normalize(i.hitPos - ro);

                    rayData ret;
                    ret = castRay(ro, rd);
                    fixed3 col = 1;

                    float dist = ret.dist;// raymarch total dist
                    int steps = ret.steps;// raymarch steps

                    // Sky color/background
                    if (dist < 0)
                    {
                        //return _SkyColor -rd.y*0.5;
                        discard;
                    }

                    float3 p = ro + rd * dist;// collision position
                    p /= _Scale;
                    float3 n = getNormal(p);// normal
                    
                    

                    // Sunlight
                    float sun_dif = clamp(dot(n, normalize(_SunPos)), 0, 1); 
                    float sun_sha = step(castRay(_Scale*(p+n*0.01), normalize(_SunPos)).dist, 0.0);
                    // Sky light from direcly above
                    float sky_dif = clamp(0.5 + 0.5 * dot(n, float3(0, 1, 0)), 0, 1);

                    //float bou_dif = clamp(0.5 + 0.5 * dot(n, float3(0, -1, 0)), 0, 1);

                    // Colors
                    float3 sun_col = float3(7, 4.5, 3);
                    float3 sky_col = float3(0.5, 0.8, 0.9);
                    float3 bou_col = float3(0.7, 0.3, 0.2);

                    //float br = 100.0/float(steps)/100;

                    //col = float3(br,br,br);
                    //col.rgb = dot(n, normalize(float3(1,0.5,1)));
                    col = ret.color * sun_dif * sun_sha * sun_col;
                    col += ret.color* sky_dif * sky_col;
                    //col += mat * bou_dif * bou_col;

                    return fixed4(col,1); 
                }

                ENDCG
            }

    }

}
