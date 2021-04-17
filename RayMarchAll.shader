Shader "Custom/RaymarchAll"
{
    Properties
    {
        [Header(Lighting)]
        _SunPos ("Sun position", Vector) = (8, 4, 2)

        [Header(Raymarcher Properties)]
        _MaxSteps ("Max steps", Int) = 40 
        _Scale ("Scale", Range(0.05, 2)) = 40 
        _MaxDist ("Max distance", Float) = 40
        _SurfDist ("Surface distance threshold", Range(0.00001, 0.05)) = 0.001

        [Header(Mandelbox debug)]
        _FoldingLimit ("FoldingLimit", Range(0.03, 2)) = 0.3 
        _MinRadius ("MinRadius", Range(0.03, 2)) = 0.07 
        _FixedRadius ("FixedRadius", Range(0.03, 2)) = 0.2 
        _ScaleFactor ("ScaleFactor", Range(-2, 0.03)) = -0.8 

        //https://docs.unity3d.com/ScriptReference/MaterialPropertyDrawer.html
        
        // toggles TEST_A_ON
        [Toggle(TEST_A_ON)] _TestA("Test a?", Int) = 0

        [KeywordEnum(None, Mandelbulb, Mandelcube, Demoscene)] _SDF ("SDF", Float) = 0
        
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

            #pragma multi_compile TEST_C_ON TEST_A_ON
            
            #pragma multi_compile _SDF_NONE _SDF_MANDELBULB _SDF_MANDELCUBE _SDF_DEMOSCENE
            //#pragma multi_compile _OVERLAY_NONE _OVERLAY_ADD _OVERLAY_MULTIPLY

            #define USE_WORLD_SPACE
            #define USE_DYNAMIC_QUALITY
            //#define DISCARD_ON_MISS
            //#define USE_REFLECTIONS
            //#define MAX_REFLECTIONS 3


            #include "RayMarchLib.cginc"
            
            float3 _SunPos;
            float _Scale;

            float _FoldingLimit;
            float _MinRadius;
            float _FixedRadius;
            float _ScaleFactor;

            sdfData scene(float3 p)
            {
                sdfData o;
                p/=_Scale;


                //////////////////////////////////////////////////////////////////////
                // all of these should fit in -1.0 to 1.0 
                // (a 2x2 cube or sphere with radius 1), 
                // when scaling is set to 1.
                //////////////////////////////////////////////////////////////////////


                #ifdef _SDF_MANDELBULB
                o = fracMandelbulb(rotZ(p/0.8, _Time.x));
                o.dist*=0.6;
                #elif _SDF_MANDELCUBE
                float scale = 2;
                o = fracMandelbox(rotZ(p/scale, 0), _FoldingLimit, _MinRadius, _FixedRadius, _ScaleFactor);
                o.dist*=scale;
                #elif _SDF_NONE
                o = sdfSphere(p, 1);
                #elif _SDF_DEMOSCENE
                //p/=0.5;
                //material mGrass = mat(0.001, 0.15, 0.001, 0.5);
                //o = sdfSphere(p, 2);
                material mGrass = mat(0.001, 0.15, 0.001, 0.5);
                o = sdfPlane(p, -.5, mGrass);
                material mDirt = mat(0.18, 0.05, 0.02, 1);
                o = sdfInter(p, o, sdfSphere(p, 9, mDirt), 0.5);
                
                o = sdfAdd(p, o, sdfSphere(p, 2, mat(0.1,0)), 0.3);
                material mBlue = mat(0.05, 0.1, 0.2, 1);
                o = sdfAdd(p, o, sdfTorus(p, 5, 0.5, mBlue), 0.2);
                #else
                o = sdfCylinder(p, 1, 1);
                #endif

                o.dist*=_Scale;
                return o;
            }

            fixed4 lightPoint(rayData ray)
            {
                float3 vSunDir = normalize(_SunPos);

                fixed4 col = 0;
                if (ray.bMissed)
                {
                    //col = fixed4(1,1,1,0);
                    //col = sky(ray.vRayDir);
                    //col += (ray.iSteps/200.0);
                    col += 0.01/ray.minDist;

                    if (col.x<0.1) discard; //"dynamic" discard
                    return col;
                }

                //float3 norm = getNorm(ray.vHit, ray.dist);
                //col.x=norm.x; 
                //col.y=norm.y; 
                //col.z=norm.z; 

                col = ray.mat.col;
                //col = fixed4(1,1,1,1);
                col = HSV(frac(length(ray.vHit)*1.0 + _Time.x), 1, 1);
                //col = HSV(frac(length(ray.vHit)/3.0), 1, 1);
                //col.x = sin(length(ray.vHit)*5.0 + _Time.y);
                //col.y = sin(length(ray.vHit)*5.0 + _Time.y + degrees(120));
                //col.z = sin(length(ray.vHit)*5.0 + _Time.y + degrees(240));
                /*col.x = sin(ray.vHit.x);
                col.y = sin(ray.vHit.y);
                col.z = sin(ray.vHit.z);*/
                //col = ray.mat.col;// * (lightSun(ray.vNorm, vSunDir));

                //#ifdef _OVERLAY_ADD
                //col *= (ray.iSteps/100.0);
                col *= (50.0/ray.iSteps);
                //#endif

                //col *= lightShadow(ray.vHit, vSunDir, 50);
                //col += ray.mat.col * lightSky(ray.vNorm, 1);
                //col *= lightAO(ray.vHit, ray.vNorm);
                //col = pow(col, 0.5);
                //col = 0.5;
                
                // TODO: "free" Effects
                // glow: min of DE, blend other color/brighten
                // ambient occlusion: number of steps, darken
                // fog: 

                return col;
            }
            ENDCG
        }
    }
}
