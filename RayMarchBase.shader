Shader "Custom/RaymarchBase2"
{
    Properties
    {
        [Header(Raymarcher Properties)]
        _MaxSteps ("Max steps", Int) = 256
        _MaxDist ("Max distance", Float) = 256
        _SurfDist ("Surface distance threshold", Range(0.00001, 0.05)) = 0.001
        [Toggle] _UseObjectSpace ("Use Object Space", Float) = 0
        
        [Header(Lighting)]
        [Toggle] _UseSky ("Use sky as background", Float) = 0
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
            #include "RayMarchLib.cginc"
            
            bool _UseSky;
            float4 _SkyColor;
            float3 _SunPos;

            sdfData scene(float3 p)
            {
                sdfData o;
                o = sdfPlane(p, -.5, C_GREEN * 0.15);
                o = sdfInter(p, o, sdfSphere(p, 9, float3(0.18, 0.05, 0.02)), 0.5);
                o = sdfAdd(p, o, sdfSphere(p, 2), 0.3);
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
                fixed3 col = 0;
                float3 cMat = ray_data.col;

                col = cMat * lightSun(vNorm, vSunDir) * lightShadow(vPos, vSunDir);
                col += cMat * lightSky(vNorm);  
                col *= lightAO(vPos, vNorm);

                //brighten up
                col = pow(col, 0.5);

                //col = lightAO(vPos, vNorm);
                //col = lightOnly(vPos, vNorm, vSunDir);
                return float4(col, 1);
            }
            ENDCG
        }
    }
}
