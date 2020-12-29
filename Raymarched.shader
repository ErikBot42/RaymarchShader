Shader "Unlit/Raymarched"
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

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Cull Off
            LOD 100

            Pass
            {
                CGPROGRAM
#pragma vertex vert
#pragma fragment frag

#include "UnityCG.cginc"

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

                float noise3(float a, float b, float c);

                v2f vert (appdata v)
                {//TODO: Setting in material
                    v2f o;
                    o.vertex = UnityObjectToClipPos(v.vertex);
                    //object space
                    o.ro = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));
                    o.hitPos = v.vertex;
                    //world space
                    //o.ro = _WorldSpaceCameraPos;
                    //o.hitPos = mul(unity_ObjectToWorld, v.vertex);
                    return o;
                }

                //***** RAYMARCH STUFF *****

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


#define Iterations 30
#define Scale 2
#define MAX_ARR_SIZE 8


                // DE fractal polyhedron from given points,
                // creates tetrahedron on 4 points.
                // it works by finding the closest vertex of the fractal polyhedron, O(n)
                float DE_Polyhedron(float3 z, float3 p[MAX_ARR_SIZE], int numPoints)
                {
                    float3 closest;//current closest point

                    float dist = 0;//current dist to closest
                    float d = 0;

                    for (int n = 0; n < Iterations; n++) 
                    {
                        closest = p[0]; 
                        dist = length(z-p[0]);

                        for (int i = 1; i<numPoints; i++)
                        {
                            d = length(z-p[i]);
                            if (d < dist)
                            {
                                closest = p[i];
                                dist = d;
                            }
                        }

                        z = Scale*z-closest*(Scale-1.0);
                    }
                    return length(z) * pow(Scale, -n);
                }

                float DE_main(float3 z)
                {
                    //return sdSphere(z, 0, 1);
                     float3 p[MAX_ARR_SIZE];
                       float Spread = 0.2;
                       p[0] = float3(1,1,1) * Spread;
                       p[1] = float3(-1,-1,1) * Spread;
                       p[2] = float3(1,-1,-1) * Spread;
                       p[3] = float3(-1,1,-1) * Spread;
                       p[4] = float3(-1,-1,-1) * Spread;
                       return DE_Polyhedron(z, p, 5);


                }

                //marches a ray through the scene
                // OUT: number of steps and total distance
                rayData castRay(float3 ro, float3 rd)
                {
                    float3 mat = 0.2;
                    float rayLen = 0;// total distance marched / distance from origin
                    float dist; // distance from the raymarched scene
                    for (int i = 0; i < _MaxSteps; i++)
                    {
                        //position = origin + distance * direction
                        float3 p = ro + rayLen * rd;
                        
                        dist = DE_main(p);

                        rayLen += dist;// move forward

                        if (dist < _SurfDist) break;
                        if (rayLen > _MaxDist) break;
                    }
                    if (rayLen > _MaxDist) rayLen = -1;

                    rayData data;
                    data.dist = rayLen;
                    data.steps = i;
                    //data.color = mat;

                    return data; 
                }


                float3 getNormal(float3 p)
                {
                    float2 e = float2(0.001, 0);
                    float3 n = DE_main(p) - float3(
                            DE_main(p-e.xyy),
                            DE_main(p-e.yxy),
                            DE_main(p-e.yyx));
                    return normalize(n);
                }

                fixed4 frag (v2f i) : SV_Target
                {
                    float3 ro = i.ro;
                    float3 rd = normalize(i.hitPos - ro);

                    rayData ret;
                    ret = castRay(ro, rd);
                    float d = ret.dist;
                    int numSteps = ret.steps;
                    fixed4 col = 1;

                    if (d < 0)
                    {
                        discard;
                    }
                    float3 p = ro + rd * d;
                    float3 n = getNormal(p);

                    float br = 100.0/float(numSteps)/100;

                    col.rgb = float3(br,br,br);
                    //col.rgb = dot(n, normalize(float3(1,0.5,1)));

                    return col; 
                }

                // ***** NOISE *************************************************
                // ***** NOISE *************************************************
                // ***** NOISE *************************************************
                // ***** NOISE *************************************************
                // ***** NOISE *************************************************
                // ***** NOISE *************************************************
                float3 mod289(float3 x) {
                    return x - floor(x * (1.0 / 289.0)) * 289.0;
                }

                float4 mod289(float4 x) {
                    return x - floor(x * (1.0 / 289.0)) * 289.0;
                }

                float4 permute(float4 x) {
                    return mod289(((x*34.0)+1.0)*x);
                }

                float4 taylorInvSqrt(float4 r)
                {
                    return 1.79284291400159 - 0.85373472095314 * r;
                }

                float snoise(float3 v)
                { 
                    const float2  C = float2(1.0/6.0, 1.0/3.0) ;
                    const float4  D = float4(0.0, 0.5, 1.0, 2.0);

                    // First corner
                    float3 i  = floor(v + dot(v, C.yyy) );
                    float3 x0 =   v - i + dot(i, C.xxx) ;

                    // Other corners
                    float3 g = step(x0.yzx, x0.xyz);
                    float3 l = 1.0 - g;
                    float3 i1 = min( g.xyz, l.zxy );
                    float3 i2 = max( g.xyz, l.zxy );

                    //   x0 = x0 - 0.0 + 0.0 * C.xxx;
                    //   x1 = x0 - i1  + 1.0 * C.xxx;
                    //   x2 = x0 - i2  + 2.0 * C.xxx;
                    //   x3 = x0 - 1.0 + 3.0 * C.xxx;
                    float3 x1 = x0 - i1 + C.xxx;
                    float3 x2 = x0 - i2 + C.yyy; // 2.0*C.x = 1/3 = C.y
                    float3 x3 = x0 - D.yyy;      // -1.0+3.0*C.x = -0.5 = -D.y

                    // Permutations
                    i = mod289(i); 
                    float4 p = permute( permute( permute( 
                                    i.z + float4(0.0, i1.z, i2.z, 1.0 ))
                                + i.y + float4(0.0, i1.y, i2.y, 1.0 )) 
                            + i.x + float4(0.0, i1.x, i2.x, 1.0 ));

                    // Gradients: 7x7 points over a square, mapped onto an octahedron.
                    // The ring size 17*17 = 289 is close to a multiple of 49 (49*6 = 294)
                    float n_ = 0.142857142857; // 1.0/7.0
                    float3  ns = n_ * D.wyz - D.xzx;

                    float4 j = p - 49.0 * floor(p * ns.z * ns.z);  //  fmod(p,7*7)

                    float4 x_ = floor(j * ns.z);
                    float4 y_ = floor(j - 7.0 * x_ );    // fmod(j,N)

                    float4 x = x_ *ns.x + ns.yyyy;
                    float4 y = y_ *ns.x + ns.yyyy;
                    float4 h = 1.0 - abs(x) - abs(y);

                    float4 b0 = float4( x.xy, y.xy );
                    float4 b1 = float4( x.zw, y.zw );

                    //float4 s0 = float4(lessThan(b0,0.0))*2.0 - 1.0;
                    //float4 s1 = float4(lessThan(b1,0.0))*2.0 - 1.0;
                    float4 s0 = floor(b0)*2.0 + 1.0;
                    float4 s1 = floor(b1)*2.0 + 1.0;
                    float4 sh = -step(h, float4(0,0,0,0));

                    float4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
                    float4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;

                    float3 p0 = float3(a0.xy,h.x);
                    float3 p1 = float3(a0.zw,h.y);
                    float3 p2 = float3(a1.xy,h.z);
                    float3 p3 = float3(a1.zw,h.w);

                    //Normalise gradients
                    float4 norm = taylorInvSqrt(float4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
                    p0 *= norm.x;
                    p1 *= norm.y;
                    p2 *= norm.z;
                    p3 *= norm.w;

                    // Mix final noise value
                    float4 m = max(0.6 - float4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
                    m = m * m;
                    return 42.0 * dot( m*m, float4( dot(p0,x0), dot(p1,x1), 
                                dot(p2,x2), dot(p3,x3) ) );
                }

                float noise3(float a, float b, float c)
                {
                    return snoise(float3(a,b,c));
                }

                ENDCG
            }
    }




}
