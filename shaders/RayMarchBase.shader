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
            #define USE_REFLECTIONS
            #define MAX_REFLECTIONS 3
            //#include "../RayMarchLib.cginc"
            
            //float3 _SunPos;

			//float4 sdf(float3 p) {return float4(sdfSphere(p,0.1),1,1,1);}
			//material calcMaterial(float3 p) {
			//	material mat; 
			//	mat.col = fixed4 (1,1,1,1);
			//	return mat;
			//	}

            //sdfData scene(float3 p)
            //{
            //    sdfData o;
            //    material mGrass = mat(0.001, 0.15, 0.001, 0.5);
            //    o = sdfPlane(p, -.5, mGrass);
            //    material mDirt = mat(0.18, 0.05, 0.02, 1);
            //    o = sdfInter(p, o, sdfSphere(p, 9, mDirt), 0.5);
            //    
            //    o = sdfAdd(p, o, sdfSphere(p, 2, mat(0.1,0)), 0.3);
            //    material mBlue = mat(0.05, 0.1, 0.2, 1);
            //    o = sdfAdd(p, o, sdfTorus(p, 5, 0.5, mBlue), 0.2);
            //    return o;
            //}

            //fixed4 lightPoint(rayData ray)
            //{
            //    float3 vSunDir = normalize(_SunPos);

            //    if (ray.bMissed)
            //    {
            //        return sky(ray.vRayDir);
            //    }

            //    fixed4 col = 0;

            //    col = ray.mat.col * lightSun(ray.vNorm, vSunDir);
            //    col *= lightShadow(ray.vHit, vSunDir, 50);
            //    col += ray.mat.col * lightSky(ray.vNorm, 1);
            //    //col *= lightAO(ray.vHit, ray.vNorm);
            //    
            //    col = pow(col, 0.5);
            //    return col;
            //}
            ENDCG
        }
    }
}
