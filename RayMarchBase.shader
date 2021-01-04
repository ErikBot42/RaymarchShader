Shader "Custom/RaymarchBase"
{
    Properties
    {
        [Header(Lighting)]
        _SunPos ("Sun position", Vector) = (8, 4, 2)

        [Header(Raymarcher Properties)]
        _MaxSteps ("Max steps", Int) = 256
        _MaxDist ("Max distance", Float) = 256
        _SurfDist ("Surface distance threshold", Range(0.00001, 0.05)) = 0.001
        
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

            #define USE_WORLD_SPACE
            #define DYNAMIC_QUALITY
            #include "RayMarchLib.cginc"
            
            float3 _SunPos;

            sdfData scene(float3 p)
            {
                sdfData o;
                o = sdfPlane(p, -.5, C_GREEN * 0.15);
                o = sdfInter(p, o, sdfSphere(p, 9, col(0.18, 0.05, 0.02)), 0.5);

                const fixed4 cBlue = col(0.05, 0.1, 0.2);
                o = sdfAdd(p, o, sdfSphere(p, 2, cBlue), 0.3);
                o = sdfAdd(p, o, sdfTorus(p, 5,0.5), 0.2);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 vRayStart = i.vCamPos;
                float3 vRayDir = normalize(i.vHitPos - vRayStart);
                rayData ray_data = castRay(vRayStart, vRayDir);

                float3 vSunDir = normalize(_SunPos);
                
                if (ray_data.dist < 0)
                {
                    return skyBox(vRayDir, vSunDir);
                    //discard;
                }

                //calculate hit point
                float3 vPos = vRayStart + vRayDir * ray_data.dist;
                //get normal
                float3 vNorm = getNormal(vPos);

                //colour init
                fixed4 col = 0;
                fixed4 cMat = ray_data.col;

                col = cMat * lightSun(vNorm, vSunDir) * lightShadow(vPos, vSunDir);
                col += cMat * lightSky(vNorm);  
                col *= lightAO(vPos, vNorm);

                //brighten up
                col = pow(col, 0.5);

                return col;
            }
            ENDCG
        }
    }
}
