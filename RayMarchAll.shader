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

        [KeywordEnum(None, Menger, Testing, Juliabulb, Mandelbulb, Mandelbolb, Mandelbox, Feather, Demoscene)] _SDF ("SDF", Float) = 0
        [KeywordEnum(None, ColorXYZ, ColorHSV_sphere, ColorHSV_cube)] _MTRANS ("Material transform", Float) = 0
        [KeywordEnum(None, Twist, Rotate, Repeat, MengerFold)] _PTRANS ("Position transform", Float) = 0
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

        Tags { "RenderType"="Opaque" "LightMode"="ForwardBase" }
        //Tags { "Queue"="Transparent" "RenderType"="Opaque" }
		//Tags { // transparent
		//	"Queue"="Transparent" 
		//		"RenderType"="Transparent" 
		//		"ForceNoShadowCasting"="True"
		//		"DisableBatching"="True" // batching can prevent access to object space
		//}
		//Blend SrcAlpha OneMinusSrcAlpha // enable transparency

        Cull Off
        LOD 100

        Pass
        {

            CGPROGRAM
			//#define DEBUG_COLOR_MODE
			//#define VERTEX_DEBUG_COLORS
			//#define ENABLE_TRANSPARENCY
			#define DISCARD_ON_MISS
            
			#pragma vertex vert
            #pragma fragment frag
			
            #pragma multi_compile _SDF_NONE _SDF_MENGER _SDF_TESTING _SDF_JULIABULB _SDF_MANDELBULB _SDF_MANDELBOLB _SDF_MANDELBOX _SDF_DEMOSCENE _SDF_FEATHER
            #pragma multi_compile _MTRANS_NONE _MTRANS_COLORXYZ _MTRANS_COLORHSV_SPHERE _MTRANS_COLORHSV_CUBE
            #pragma multi_compile _PTRANS_NONE _PTRANS_TWIST _PTRANS_ROTATE _PTRANS_MENGERFOLD
            #pragma multi_compile _SPACE_WORLD _SPACE_OBJECT
            #pragma multi_compile _ANIMATE_ON _ANIMATE_OFF
			//#define _MTRANS_COLORHSV_SPHERE
			//#define _PTRANS_NONE
			//#define _SPACE_OBJECT
			//#define _ANIMATE_OFF

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
			#define MAX_DIST 3
			//#define SURF_DIST 0.0001
			#define SURF_DIST 0.001
			//#define SURF_DIST 0.0005
            #if defined(_SDF_MANDELBULB) || defined(_SDF_MANDELBOLB) || defined(_SDF_JULIABULB)
				#define FUNGE_FACTOR 1
                //#define MAX_STEPS 228
                #define MAX_STEPS 100
                //#define MAX_STEPS 200

                //This DOUBLES the framerate:
                #define CONSTRAIN_TO_MESH
			//#elif _SDF_JULIABULB
				//#define MAX_STEPS 30
				//#define MAX_STEPS 50
                //#define CONSTRAIN_TO_MESH
            #elif _SDF_MANDELBOX
                //#define MAX_STEPS 50
                //#define MAX_STEPS 30
                #define MAX_STEPS 140
                //#define FUNGE_FACTOR 1
				//#define SURF_DIST 0.0001
				//#define SURF_DIST 0.00005
				//#define SURF_DIST 0.0002
				//#define SURF_DIST 0.0002
				//#define MAX_DIST 2000

                #define CONSTRAIN_TO_MESH
                //#define STEP_FACTOR 1
			#elif _SDF_FEATHER
				//#define MAX_STEPS 70
				#define MAX_STEPS 30
				//#define MAX_STEPS 30
				#define CONSTRAIN_TO_MESH
				#define FUNGE_FACTOR 0.9
			#elif defined(_SDF_TESTING) || defined(_SDF_MENGER)
				#define MAX_STEPS 100
                //#define CONSTRAIN_TO_MESH
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
                    mat.col = HSV(frac(length(p)*8 + _Time.x), 0.5, 1);
                #elif _MTRANS_COLORHSV_CUBE
                    mat.col = HSV(frac(max(abs(p.x),max(abs(p.y),abs(p.z)))*8 + _Time.x), .5, 1);
                #elif _MTRANS_COLORXYZ
                    float factor = 0.5;
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
                    //p = rotZ(p, p.z*_Slider_Transform*2);
					float3 n = normalize(vSdfConfig.xyz);
					float d = -0.2*length(n);
					tripplePlaneFold(p, n, d);
					tripplePlaneFold(p, -n, d*.5);
					//n = normalize(float3(_SinTime.z,_CosTime.z,_SinTime.y));
					//d = -0.1*length(n);
					//tripplePlaneFold(p, n, d);
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


            float sdf(float3 p)
            {

                #ifdef _ANIMATE_OFF
                float sdfSlider = _Slider_SDF;
                #else
                //float sdfSlider = sin(_Time.x*0.5);
                float sdfSlider = pingPong(_Time.x,.125);
                #endif

                //sdfData o = {0,DEFMAT};

				float dist;




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
                dist = fracMandelbulb(p);
                dist*=scale;

				#elif _SDF_MANDELBOLB

                float scale = 0.4;
                p/=scale;
                dist = fracMandelbolb(p);
                dist*=scale;

				#elif _SDF_TESTING


				float d1 = sdfSphere(p+float3(0,0.3,0),0.4);

				float x1 = length(float2(p.x,p.z));
				float y1 = p.y;

				d1 = abs(y1 - x1*x1)/sqrt(2*x1*2*x1+1)-0.0;
				d1 = y1>(x1*x1) ? d1 : 0;


				float d2 = sdfSphere(p,0.3);

				dist = max(d1,d2)-0.01;
				dist = min(dist, sdfSphere(p+float3(0,-0.25,0),0.1));

				#elif _SDF_MENGER

                //o.mat = applyColorTransform(p, o.mat); 

				//o.dist = 50.5*log(length(p))*length(p)*p.x;

                float scale = 0.2;
				p/=scale;
				dist = mengerSponge(p, vSdfConfig.xyz, _Slider_SDF);//-0.01*(1+_SinTime.z);
				//dist = sdfBox(p,float3(1,1,1));
				//int iterations = 3+int(_SinTime.z*1.9);

				////dist = sierpinski3(p);
				//float estSideLength = 1;
				//for (int k = 0; k<iterations; k++)
				//{
				//	absFold(p,0);
				//	mengerFold(p);
				//	scaleTranslate(p,3.0,float3(-2,-2,0));
				//	//scale/=3.5;
				//	//scale/=3.8;
				//	scale/=3.8;
				//	planeFold(p,float3(0,0,-1),-1);
				//	//planeFold(p,float3(0,_SinTime.x*0.3,-_SinTime.y*0.3-1),-_SinTime.z*0.3-1);
				//	dist = sdfBox(p,float3(1,1,1)*(2));
				//	//break;
				//	//if (dist/estSideLength>0.1) break;
				//	estSideLength/3;
				//}

                //o.dist = fracJuliabulb(p);
                //o.dist = fracMandelbulb(p);
				//o.dist = sdfSphere(p,1);
				//o.dist/=pow(3,iterations);
				//o.dist*=0.4;
				dist*=1.0;
                dist*=scale;

                //////////////////////////////////////////////////////////////////////
                //
                // Juliabulb
                //
                //////////////////////////////////////////////////////////////////////
				#elif _SDF_JULIABULB
                float scale = 0.35;
                p/=scale;
                dist = fracJuliabulb2(p, vSdfConfig.xyz*1.3);//, vSdfConfig.w*3+6);
                dist*=scale;

                //////////////////////////////////////////////////////////////////////
                //
                // Mandelbox 
                //
                //////////////////////////////////////////////////////////////////////
                #elif _SDF_MANDELBOX
                
                #define COLTRANS_DONE
				vSdfConfig.w = _SinTime.z;

                float scaleFactor = smoothstep(-1,1,vSdfConfig.w)*6-3;
				//float scale = 0.5;
				float scale = 0.15;
				//_SurfDist = 0.0001;

				p/=scale;
				dist = fracMandelbox4(p, vSdfConfig.w, vSdfConfig.xyz)*scale;

                //////////////////////////////////////////////////////////////////////
                //
                // None
                //
                //////////////////////////////////////////////////////////////////////
                #elif _SDF_NONE
				dist = sdfSphere(p, 0.25);
                //dist = sdfSphere(p+float3(-0.25,0,0), 0.2);
				//dist = min(dist, sdfSphere(p+float3(.25,0,0), 0.2));
				//dist = min(dist, sdfBox(p+float3(0,0.25,0), float3(1,1,1)*0.3));


				//if(dist<0.001)
				//{
				//	dist += snoise(p*100)*0.0005;
				//}
				//if (dist<0.1) 
				//{
				//	dist += snoise(p*5)*0.03;
				//	if (dist<0.01) 
				//	{
				//		dist += snoise(p*50)*0.003;
				//		if(dist<0.001)
				//		{
				//			dist += snoise(p*250)*0.0003;
				//		}
				//	}
				//}

                //////////////////////////////////////////////////////////////////////
                //
                // Feather
                //
                //////////////////////////////////////////////////////////////////////
                #elif _SDF_FEATHER
                //p = dot(p,p)*10;
                //float3 p_shifted = p; p_shifted.x+=_Time.x;
				//boxFold(p,0,1);
                dist = fracFeather(p);
                float3 dim = float3(1,1,1);
                dist = max(sdfBox(p,dim,0), dist);

                //////////////////////////////////////////////////////////////////////
                //
                // Demoscene
                //
                //////////////////////////////////////////////////////////////////////
                #elif _SDF_DEMOSCENE
                //material mGrass = mat(0.001, 0.15, 0.001, 0.5);
				float scale = 0.05;
				p/=scale;
                dist = sdfPlane(p, -.5);
                dist = max(dist, sdfSphere(p, 9));
                //
                dist = smin(sdfSphere(p, 2), dist, 0.3);
                dist = min(sdfSphere(p+float3(0,-6,0), 2), dist);
                dist = smin(sdfTorus(p, 5, 0.5), dist, 0.2);
                dist = smin(sdfTorus(p+float3(0,-6,0), 5, 0.5), dist, 0.2);
				dist*=scale;
                #else
                o = sdfCylinder(p, 1, 1);
				dist = o.dist;
                #endif 

                //#ifndef COLTRANS_DONE
                //o.mat = applyColorTransform(p, o.mat); 
                //#endif

                // if DE over/undershoots
                #ifdef FUNGE_FACTOR
                dist*=FUNGE_FACTOR;
                #endif

                dist*=_Scale;


                return dist;
            }

			material calcMaterial(float3 p)
			{
				material mat = DEFMAT;
				mat.col = fixed4(1,1,1,1)*0.6;
				mat.col.w = 1;
				mat.fSmoothness = 1;//0.5+0.5*sin(5*max(p.x,max(p.y,p.z)));
				//mat.fSmoothness = p.x>0 ? 0.3 : 0.7;//pow(sin(p.x+p.y+p.z),2);
				//applyPositionTransform(p);
				return applyColorTransform(p, mat);
			}

            //fixed4 lightPoint(rayData ray)
            //{
            //    #ifndef STEP_FACTOR
            //    #define STEP_FACTOR 1
            //    #endif

            //    #ifndef FUNGE_FACTOR
            //    #define FUNGE_FACTOR 1
            //    #endif

			//	
			//	#ifdef DEBUG_COLOR_MODE
			//	if(ray.bMissed)
			//	{
			//		return fixed4(10.0/ray.iSteps,1,0,1);
			//	}
			//	else
			//	{
			//		return fixed4(10.0/ray.iSteps,0,1,1);
			//	}
			//	#endif
			//	

            //    fixed4 glowColor = fixed4(1,1,1,1);
			//	//return glowColor;
            //    //fixed4 glowColor = ray.mat.col;
            //    glowColor = glowColor*(0.01/ray.minDist)*FUNGE_FACTOR;
            //    //glowColor = glowColor*(0.3/ray.minDist)*FUNGE_FACTOR;

            //    //fixed4 glowColor = fixed4(1,1,1,1)*(0.1/ray.minDist)*FUNGE_FACTOR;
            //    //fixed4 glowColor = 0;
            //    glowColor = saturate(glowColor);


            //    fixed4 cFog = 0;

            //    //cFog = lightFog(glowColor, cFog, ray.distToMinDist, 0, MAX_DIST);

            //    fixed4 col = 0;
            //    if (ray.bMissed)
            //    {
            //        //fixed4 cFog = fixed4(.0,.0,.0,.0);
            //        //col = glowColor;
            //        //col = cFog;
            //        //col = 10 * glowColor/ray.iSteps;
            //        //col = 10 * glowColor/ray.distToMinDist;
            //        //cFog = glowColor;
            //    }
            //    else
            //    {
    		//		//fixed3 vNorm;
            //        col = ray.mat.col*glowColor;
			//		//float colorFactor = dot(float4(ray.vNorm,1),V_Y);
			//		//colorFactor = max(0,colorFactor)*0.1;
			//		 
			//		//float colorFactor = STEP_FACTOR/FUNGE_FACTOR;
			//		col *= STEP_FACTOR/FUNGE_FACTOR;
			//		//#ifdef EXTREME_AO
            //        //col.w = (100.0/(ray.iSteps*ray.iSteps));
            //        //col *= (1000.0/(ray.iSteps*ray.iSteps*ray.iSteps));
			//		//#else
			//		//#endif

            //        col.w = 15.0*(1.0/ray.iSteps-(1.0/MAX_STEPS));
			//		// Linear:
            //        //col.w = 1.0*(1.0-float(ray.iSteps)/MAX_STEPS);
            //        //col *= (1000.0/(ray.iSteps*ray.iSteps*ray.iSteps))*STEP_FACTOR/FUNGE_FACTOR;
            //        //col += glowColor;
            //        //fixed4 cFog = glowColor;
            //        //col *= colorFactor*glowColor;
			//		//col.w = 0.2;
            //        //col = lightFog(col, cFog, ray.dist, 0, MAX_DIST);
			//		//col *= col.w;
            //    }
            //    //return 0.01*fixed4(1,1,1,1)*ray.iSteps;
            //    return col;
            //}
            
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
