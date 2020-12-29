Shader "Unlit/Raymarched"
{
    Properties
    {
        [Header(Raymarcher Properties)]
        _MaxSteps ("Max steps", Int) = 256
        _MaxDist ("Max distance", Float) = 100
        _SurfDist ("Surface distance threshold", Range(0.00001, 0.05)) = 0.001
        _Thing ("thing distance threshold", Range(0, 1)) = 1
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

                struct rayReturn
                {
                    float dist;
                    int steps;
                };

                int _MaxSteps;
                float _MaxDist;
                float _SurfDist;
                float _Thing;

                float noise3(float a, float b, float c);



                v2f vert (appdata v)
                {
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

                float smoothMin(float a, float b, float k)
                {
                    return min(a, b) - pow(max(k - abs(a-b), 0), 3)/(6*k*k);
                }

                float sdSphere(float3 p, float3 o, float r) {
                    return length(p - o) - r;
                }

                float sdBox(float3 p, float3 dim)
                {
                    return length(float3(
                                max(abs(p.x) - dim.x/2.0, 0),
                                max(abs(p.y) - dim.y/2.0, 0),
                                max(abs(p.z) - dim.z/2.0, 0)));
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

                float GetDist(float3 z)
                {
                    float3 p[MAX_ARR_SIZE];

                    float Spread = 0.5;
                    p[0] = float3(1,1,1) * Spread;
                    p[1] = float3(-1,-1,1) * Spread;
                    p[2] = float3(1,-1,-1) * Spread;
                    p[3] = float3(-1,1,-1) * Spread;
                    p[4] = float3(-1,-1,-1) * Spread;
                    
                    return DE_Polyhedron(z, p, 5);
 

                    /*float d = 0;
                    //float r = pow(sin(40*_Time), 2)*0.08;
                    float r = 0.05;
                    float ox = 0.2;
                    p.x = fmod(p.x+ox*3,ox*3);
                    p.y = fmod(p.y+ox*3,ox*3);
                    p.z = fmod(p.z+ox*3,ox*3);
                    d = sdSphere(p, float3(ox, ox, ox), r);


                    //d = min(d, sdBox(p, float3(0.2, 0.2, 0.2)) - 0.00);//0.05

                    //d = min(d, sdSphere(p, float3(0.2, 0.14, 0), r));//0.2
                    return d;*/

                    float t = _Time;//sin(_Time);

                    Spread = 0.5;
                    float3 a1 = float3(1,1,1) * Spread;
                    float3 a2 = float3(-1,-1,1) * Spread;
                    float3 a3 = float3(1,-1,-1) * Spread;
                    float3 a4 = float3(-1,1,-1) * Spread;
                    //float3 a5 = float3(-1,-1,-1) * Spread;
                    int q; 
                    /*
                       float3 a1 = float3(-1,-1,-1) * Spread;
                       float3 a2 = float3(-1,-1,1) * Spread;
                       float3 a3 = float3(-1,1,-1) * Spread;
                       float3 a4 = float3(-1,1,1) * Spread;
                       float3 a5 = float3(1,-1,-1) * Spread;
                       float3 a6 = float3(1,-1,1) * Spread;
                       float3 a7 = float3(1,1,-1) * Spread;
                       float3 a8 = float3(1,1,1) * Spread;
                     */


                    /*q=500; float3 a1 = Spread*normalize(float3(noise3(t,q,100)*Spread,noise3(t,q,200)*Spread,noise3(t,q,300)*Spread));
                      q=600; float3 a2 = Spread*normalize(float3(noise3(t,q,100)*Spread,noise3(t,q,200)*Spread,noise3(t,q,300)*Spread));
                      q=700; float3 a3 = Spread*normalize(float3(noise3(t,q,100)*Spread,noise3(t,q,200)*Spread,noise3(t,q,300)*Spread));
                      q=800; float3 a4 = Spread*normalize(float3(noise3(t,q,100)*Spread,noise3(t,q,200)*Spread,noise3(t,q,300)*Spread));
                      q=900; float3 a5 = Spread*normalize(float3(noise3(t,q,100)*Spread,noise3(t,q,200)*Spread,noise3(t,q,300)*Spread));
                     */
                    float3 closest;

                    float dist = 0;
                    float d = 0;

                    for (int n = 0; n < Iterations; n++) 
                    {
                        closest = a1; 
                        dist = length(z-a1);

                        d = length(z-a2); 
                        if (d < dist) { closest = a2; dist=d; }

                        d = length(z-a3); 
                        if (d < dist) { closest = a3; dist=d; }

                        d = length(z-a4); 
                        if (d < dist) { closest = a4; dist=d; }

                        /*d = length(z-a5); 
                          if (d < dist) { closest = a5; dist=d; }

                          d = length(z-a6); 
                          if (d < dist) { closest = a6; dist=d; }

                          d = length(z-a7); 
                          if (d < dist) { closest = a7; dist=d; }

                          d = length(z-a8); 
                          if (d < dist) { closest = a8; dist=d; }*/





                        //closest = a4;

                        z = Scale*z-closest*(Scale-1.0);
                    }

                    return length(z) * pow(Scale, -n);

                }

                //marches a ray through the scene
                // OUT: number of steps and total distance
                rayReturn Raymarch(float3 ro, float3 rd)
                {
                    float rayLen = 0;// total distance marched / distance from origin
                    float dist; // distance from the raymarched scene

                    int i;
                    for (i = 0; i < _MaxSteps; i++)
                    {
                        //position = origin + distance * direction
                        float3 p = ro + rayLen * rd;
                        dist = GetDist(p);
                        rayLen += dist;// move forward
                        if (dist < _SurfDist || rayLen > _MaxDist) {
                            break;
                        }
                    }

                    rayReturn ret;
                    ret.dist = rayLen;
                    ret.steps = i;

                    return ret;
                }

                float3 GetNormal(float3 p)
                {
                    float2 e = float2(0.001, 0);
                    float3 n = GetDist(p) - float3(
                            GetDist(p-e.xyy),
                            GetDist(p-e.yxy),
                            GetDist(p-e.yyx));
                    return normalize(n);
                }

                fixed4 frag (v2f i) : SV_Target
                {
                    float3 ro = i.ro;
                    float3 rd = normalize(i.hitPos - ro);

                    rayReturn ret;
                    ret = Raymarch(ro, rd);
                    float d = ret.dist;
                    int numSteps = ret.steps;
                    fixed4 col = 1;

                    if (d >= _MaxDist)
                    {
                        discard;
                    }
                    float3 p = ro + rd * d;
                    float3 n = GetNormal(p);

                    float br = 100.0/float(numSteps)/100;

                    col.rgb = float3(br,br,br);
                    //col.rgb = dot(n, normalize(float3(1,0.5,1)));

                    return col;
                }

                // ***** NOISE *****
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
