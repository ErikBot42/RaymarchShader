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
       
        [Header(Variant toggles)]
        // toggles TEST_A_ON
        //[Toggle(TEST_A_ON)] _TestA("Test a?", Int) = 0

        [KeywordEnum(None, Mandelbulb, Mandelbox, Feather, Demoscene)] _SDF ("SDF", Float) = 0
        [KeywordEnum(None, ColorXYZ, ColorHSV_sphere, ColorHSV_cube)] _MTRANS ("Material transform", Float) = 0
        [KeywordEnum(None, Twist, Rotate, Repeat)] _PTRANS ("Position transform", Float) = 0
        [KeywordEnum(World, Object)] _SPACE ("Space", Float) = 0
        [KeywordEnum(On, Off)] _ANIMATE("Animate", Float) = 0

        [Header(general live sliders and toggles)]
        _Slider_SDF ("SDF slider", Range(-1,1)) = 0
        _Slider_Transform ("Transform slider", Range(-1,1)) = 0

        //[Toggle(ANIMATE_SDF_ON)] _AnimateSDF("Animate SDF", Int) = 0
        //[Toggle(ANIMATE_TRANFORM_ON)] _AnimateSDF("Animate Transform", Int) = 0

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        Cull Off
        LOD 100

        Pass
        {

			/*TODO:
			[ ] calc things on demand.
			[ ] first step should use simpler sdf.

			*/	
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            
            #pragma multi_compile _SDF_NONE _SDF_MANDELBULB _SDF_MANDELBOX _SDF_DEMOSCENE _SDF_FEATHER
            #pragma multi_compile _MTRANS_NONE _MTRANS_COLORXYZ _MTRANS_COLORHSV_SPHERE _MTRANS_COLORHSV_CUBE
            #pragma multi_compile _PTRANS_NONE _PTRANS_TWIST _PTRANS_ROTATE
            #pragma multi_compile _SPACE_WORLD _SPACE_OBJECT
            #pragma multi_compile _ANIMATE_ON _ANIMATE_OFF

            #ifdef _SPACE_WORLD
                #define USE_WORLD_SPACE
                #define REPEAT_SPACE
            #endif

            //#define USE_DYNAMIC_QUALITY
            //#define CONSTRAIN_TO_MESH
            //#define DISCARD_ON_MISS
            //#define USE_REFLECTIONS
            //#define MAX_REFLECTIONS 3

            // precompile performance options

            #ifdef _SDF_MANDELBULB
				#define EXTREME_AO
                #define MAX_STEPS 100

                //#define MAX_STEPS 200
                #define FUNGE_FACTOR 0.6

                //This DOUBLES the framerate:
                #define CONSTRAIN_TO_MESH
            #elif _SDF_MANDELBOX
                //#define MAX_STEPS 500
                #define FUNGE_FACTOR 0.5

                #define CONSTRAIN_TO_MESH
                //#define STEP_FACTOR 1
            #endif

            #ifndef MAX_DIST
                #define MAX_DIST 20
            #endif 

            float _FoldingLimit;

            #include "RayMarchLib.cginc"

            
            float3 _SunPos;
            float _Scale;

            float _MinRadius;
            float _FixedRadius;
            float _ScaleFactor;
            
            float _Slider_SDF;

            float _Slider_Transform;

            inline material applyColorTransform(float3 p, in material mat)
            {
                #ifdef _MTRANS_COLORHSV_SPHERE  
                    mat.col = HSV(frac(length(p)*0.5 + _Time.x), 1, 1);
                #elif _MTRANS_COLORHSV_CUBE
                    mat.col = HSV(frac(max(abs(p.x),max(abs(p.y),abs(p.z)))*2 + _Time.x), 1, 1);
                #elif _MTRANS_COLORXYZ
                    float factor = 0.2;
                    mat.col.x = p.x*factor+factor;
                    mat.col.y = p.y*factor+factor;
                    mat.col.z = p.z*factor+factor;
                #else 
                    // do nothing
                #endif
                return mat;    
            }


            inline void applyPositionTransform(inout float3 p)
            {
				//return;
                #ifdef REPEAT_SPACE
                    float r=2;
                    /*p.y = fmod(abs(p.y + 4), 8) - 4;
                    p.x = fmod(abs(p.x + 4), 8) - 4;
                    p.z = fmod(abs(p.z + 4), 8) - 4;*/

                    p = repXYZUnsigned(p,r);
                    //p = repXYZ(p,8);
                #endif
                #ifdef _PTRANS_TWIST 
                    p = rotZ(p, p.z*_Slider_Transform*2);
                #elif _PTRANS_ROTATE
                    //o = fmod(abs(p + r/2.0), r) - r/2.0;
                    //p.z = fmod(p.z,8);
                    //p = rotZ(p, _Slider_Transform);
                    p = rotZ(p, _Time.x);
                #else
                    // do nothing
                #endif
            }

            #define COLTRANS o.mat = applyColorTransform(p, o.mat)
            
            //#define STEP_FACTOR 1
            //#define FUNGE_FACTOR 1

            sdfData scene(float3 p)
            {

                #ifdef _ANIMATE_OFF
                float sdfSlider = _Slider_SDF;
                #else
                float sdfSlider = sin(_Time.x*0.5);
                #endif

                sdfData o = {0,DEFMAT};



                p/=_Scale;

                applyPositionTransform(p); 

                //////////////////////////////////////////////////////////////////////
                // all of these should fit in a 1x1x1 cube or sphere 
                // with radius 1, when scaling is set to 1.
                //
                // DE should be stable enough to be viewed from 20 units away
                // (in world space)
                //////////////////////////////////////////////////////////////////////

                // TODO: precompile quality settings, add color transform option, add pre transform
                // Color time, transform time, sdf time


                //////////////////////////////////////////////////////////////////////
                //
                // Mandelbulb * The baseline sdf
                //
                //////////////////////////////////////////////////////////////////////
                #ifdef _SDF_MANDELBULB
                //#define FUNGE_FACTOR _FoldingLimit

                float scale = 0.4;
                p/=scale;
                
                #define COLTRANS_DONE
                o.mat = applyColorTransform(p, o.mat); 

                o.dist = fracMandelbulb(p).dist;
                o.dist*=scale;

                //////////////////////////////////////////////////////////////////////
                //
                // Mandelbox 
                //
                //////////////////////////////////////////////////////////////////////
                #elif _SDF_MANDELBOX
                

                #define COLTRANS_DONE

                float scaleFactor = sdfSlider*3;
                //float scaleFactor = _SinTime.y*3;

                //float scale = 0.5;
                float scale = 0.15;
                //_SurfDist = 0.0001;
                if (scaleFactor>0) 
                {
                    //scaleFactor+=1;
                    scaleFactor+=2;
                    scale/=1*(scaleFactor+1)/(scaleFactor-1);
                    //_SurfDist=scale*0.0001;
                }
                else
                {
                    scaleFactor-=1;
                }

                o.mat = applyColorTransform(p, o.mat); 
                p/=scale;



                o.dist = fracMandelbox(p, scaleFactor).dist;
                //o = fracMandelbox2(rotZ(p/scale, 0), _FoldingLimit, _MinRadius, _FixedRadius, _ScaleFactor);
                //p.x +=_SinTime.z*4;

                float3 dim = float3(2,2,2)/scale;
                o = sdfInter(p, sdfBox(p,dim,0), o);

                o.dist*=scale;


                //////////////////////////////////////////////////////////////////////
                //
                // None
                //
                //////////////////////////////////////////////////////////////////////
                #elif _SDF_NONE
                o = sdfSphere(p, 1);

                //////////////////////////////////////////////////////////////////////
                //
                // Feather
                //
                //////////////////////////////////////////////////////////////////////
                #elif _SDF_FEATHER
                #define FUNGE_FACTOR 0.5
                //p = dot(p,p)*10;
                //float3 p_shifted = p; p_shifted.x+=_Time.x;
                o = fracFeather(p);
                float3 dim = float3(1,1,1);
                o = sdfInter(p, sdfBox(p,dim,0), o);

                //////////////////////////////////////////////////////////////////////
                //
                // Demoscene
                //
                //////////////////////////////////////////////////////////////////////
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

                #ifndef COLTRANS_DONE
                o.mat = applyColorTransform(p, o.mat); 
                #endif

                // if DE over/undershoots
                #ifdef FUNGE_FACTOR
                o.dist*=FUNGE_FACTOR;
                #endif

                o.dist*=_Scale;
                return o;
            }

            fixed4 lightPoint(rayData ray)
            {
                #ifndef STEP_FACTOR
                #define STEP_FACTOR 1
                #endif

                #ifndef FUNGE_FACTOR
                #define FUNGE_FACTOR 1
                #endif
				
				

                fixed4 glowColor = fixed4(1,1,1,1);
                //fixed4 glowColor = ray.mat.col;
                glowColor = glowColor*(0.01/ray.minDist)*FUNGE_FACTOR;
                //glowColor = glowColor*(0.3/ray.minDist)*FUNGE_FACTOR;

                //fixed4 glowColor = fixed4(1,1,1,1)*(0.1/ray.minDist)*FUNGE_FACTOR;
                //fixed4 glowColor = 0;
                glowColor = saturate(glowColor);


                fixed4 cFog = 0;

                //cFog = lightFog(glowColor, cFog, ray.distToMinDist, 0, MAX_DIST);

                fixed4 col = 0;
                if (ray.bMissed)
                {
                    //fixed4 cFog = fixed4(.0,.0,.0,.0);
                    //col = glowColor;
                    //col = cFog;
                    //col = 10 * glowColor/ray.iSteps;
                    //col = 10 * glowColor/ray.distToMinDist;
                    //cFog = glowColor;
                }
                else
                {
    				//fixed3 vNorm;
                    col = ray.mat.col*glowColor;
					//float colorFactor = dot(float4(ray.vNorm,1),V_Y);
					//colorFactor = max(0,colorFactor)*0.1;
					 
					//float colorFactor = STEP_FACTOR/FUNGE_FACTOR;
					col *= STEP_FACTOR/FUNGE_FACTOR;
					#ifdef EXTREME_AO
                    col *= (100.0/(ray.iSteps*ray.iSteps));
					#else
                    col *= (10.0/ray.iSteps);
					#endif
                    //col *= (1000.0/(ray.iSteps*ray.iSteps*ray.iSteps))*STEP_FACTOR/FUNGE_FACTOR;
                    //col += glowColor;
                    //fixed4 cFog = glowColor;
                    //col *= colorFactor*glowColor;
					return col;
                    //col = lightFog(col, cFog, ray.dist, 0, MAX_DIST);
                }


                //return 0.01*fixed4(1,1,1,1)*ray.iSteps;
                return col;
            }
            
//            // defined per scene:
//            // in: point
//            // out:
//            // normal offset/rotate
//            // material  
//
//            /*
//
//            fixed4 lightPoint(rayData ray)
//            {
//                #ifndef STEP_FACTOR
//                #define STEP_FACTOR 1
//                #endif
//
//                #ifndef FUNGE_FACTOR
//                #define FUNGE_FACTOR 1
//                #endif
//
//
//                fixed4 glowColor = fixed4(1,1,1,1)*(0.01/ray.minDist)*FUNGE_FACTOR;
//
//
//                float3 vSunDir = normalize(_SunPos);
//
//                fixed4 col = 0;
//                if (ray.bMissed)
//                {
//                    //return col;
//                    //col = fixed4(1,1,1,0);
//                    //col = sky(ray.vRayDir);
//                    //col += (ray.iSteps/200.0);
//
//                    fixed4 cFog = fixed4(.0,.0,.0,.0);
//
//
//                    // Glow
//                    col += glowColor;
//
//                    col = lightFog(col, cFog, ray.dist, 0, MAX_DIST);
//                    //if (col.x<0.01) discard; //"dynamic" discard
//                }
//                else
//                {
//
//                    //float3 norm = getNorm(ray.vHit, ray.dist);
//                    //col.x=norm.x; 
//                    //col.y=norm.y; 
//                    //col.z=norm.z; 
//
//                    col = ray.mat.col;
//
//
//                    //col = applyColorTransform(ray.vHit, ray.mat).col;
//                    //col = fixed4(1,1,1,1);
//                    //col = HSV(frac(length(ray.vHit.x)*1.0 + _Time.x), 1, 1);
//                    //col = HSV(frac(length(ray.vHit)/3.0), 1, 1);
//                    //col.x = sin(length(ray.vHit)*5.0 + _Time.y);
//                    //col.y = sin(length(ray.vHit)*5.0 + _Time.y + degrees(120));
//                    //col.z = sin(length(ray.vHit)*5.0 + _Time.y + degrees(240));
//                    /*col.x = sin(ray.vHit.x);
//                    col.y = sin(ray.vHit.y);
//                    col.z = sin(ray.vHit.z);*/
//                    //col = ray.mat.col;// * (lightSun(ray.vNorm, vSunDir));
//
//                    //#ifdef _OVERLAY_ADD
//                    //col *= (ray.iSteps/100.0);
//                    col *= (20.0/ray.iSteps)*STEP_FACTOR/FUNGE_FACTOR;
//                    //#endif
//
//
//                    //col = ray.mat.col;
//
//
//                    //col *= lightShadow(ray.vHit, vSunDir, 50);
//                    //col += ray.mat.col * lightSky(ray.vNorm, 1);
//                    //col *= lightAO(ray.vHit, ray.vNorm);
//                    //col = pow(col, 0.5);
//                    //col = 0.5;
//                    
//                    // TODO: "free" Effects
//                    // glow: min of DE, blend other color/brighten
//                    // ambient occlusion: number of steps, darken
//                    // fog: 
//                    
//                    fixed4 cFog = glowColor;
//
//                    col = lightFog(col, cFog, ray.dist, 0, MAX_DIST);
//                }
//
//
//
//                return col;
//            }
//            */
            

            ENDCG
        }
    }
}
