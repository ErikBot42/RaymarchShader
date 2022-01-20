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

        [Header(Transform)]

        _Transform_X ("Transform vector X", Vector) = (1,0,0,1)
        _Transform_Y ("Transform vector Y", Vector) = (0,1,0,1)
        _Transform_Z ("Transform vector Z", Vector) = (0,0,1,1)
        _Transform_W ("Transform vector W", Vector) = (0,0,0,1)

        //https://docs.unity3d.com/ScriptReference/MaterialPropertyDrawer.html
       
        [Header(Variant toggles)]
        // toggles TEST_A_ON
        //[Toggle(TEST_A_ON)] _TestA("Test a?", Int) = 0

        [KeywordEnum(None, Asteroid, Menger, Testing, Testing_alt, Testing_alt2, Juliabulb, Mandelbulb, Mandelbolb, Mandelbox, Feather, Demoscene)] _SDF ("SDF", Float) = 0
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

		// Force enable z-write
		ZWrite On 

		// Draw geometry that is in front.
		//ZTest LEqual
        LOD 100

        Pass
        {
            CGPROGRAM

            float4 _Transform_X;
            float4 _Transform_Y;
            float4 _Transform_Z;
            float4 _Transform_W;

			//#define DEBUG_COLOR_MODE
			//#define VERTEX_DEBUG_COLORS
			//#define ENABLE_TRANSPARENCY
			#define DISCARD_ON_MISS
            
			#pragma vertex vert
            #pragma fragment frag
			
            #pragma multi_compile _SDF_NONE _SDF_MENGER _SDF_TESTING_ALT _SDF_TESTING_ALT2 _SDF_TESTING _SDF_JULIABULB _SDF_MANDELBULB _SDF_MANDELBOLB _SDF_MANDELBOX _SDF_DEMOSCENE _SDF_FEATHER _SDF_ASTEROID
            #pragma multi_compile _MTRANS_NONE _MTRANS_COLORXYZ _MTRANS_COLORHSV_SPHERE _MTRANS_COLORHSV_CUBE
            //#define _MTRANS_NONE
            #pragma multi_compile _PTRANS_NONE _PTRANS_TWIST _PTRANS_ROTATE _PTRANS_REPEAT _PTRANS_MENGERFOLD
            //#define _PTRANS_REPEAT
            
            //#pragma multi_compile _SPACE_WORLD _SPACE_OBJECT
            #define _SPACE_WORLD

            //#pragma multi_compile _ANIMATE_ON _ANIMATE_OFF
			//#define _MTRANS_COLORHSV_SPHERE
			//#define _PTRANS_NONE
			//#define _SPACE_OBJECT
			//#define _ANIMATE_OFF

            #ifdef _SPACE_WORLD
                #define USE_WORLD_SPACE
                //#define REPEAT_SPACE
            #endif

				


            //#define USE_DYNAMIC_QUALITY
            //#define CONSTRAIN_TO_MESH
            //#define DISCARD_ON_MISS
            //#define USE_REFLECTIONS
            //#define MAX_REFLECTIONS 3

            // precompile performance options
			#define MAX_DIST 3
			//#define SURF_DIST 0.0001
			//#define SURF_DIST 0.001
			//#define SURF_DIST 0.0005


			#if 0
            // absurd testing
			#define SURF_DIST 0.0006
			#define MAX_STEPS 200
            #define RENDER_WITH_GI
            #endif
			#if 1
			// for typical resolution:			
			//#define SURF_DIST 0.004
			#define SURF_DIST 0.0004
			//#define SURF_DIST 0.0016
			//#define SURF_DIST 0.004
			//#define MAX_STEPS 200
			//#define MAX_STEPS 80
			#define MAX_STEPS 120
			#define MAX_STEPS 400
			//#define RENDER_WITH_GI
            #endif
			#if 0 
			// for absurd resolution:
			#define SURF_DIST 0.0004
			//#define MAX_STEPS 2000
			#define MAX_STEPS 500
			#define RENDER_WITH_GI
			#endif

            //#if defined(_SDF_MANDELBULB) || defined(_SDF_MANDELBOLB) || defined(_SDF_JULIABULB)
			//	#define FUNGE_FACTOR 0.8
            //    #define MAX_STEPS 100
            //    #define MAX_STEPS 200


            //#elif _SDF_MANDELBOX
            //    //#define MAX_STEPS 50
            //    //#define MAX_STEPS 30
            //    #define MAX_STEPS 140
            //    //#define FUNGE_FACTOR 1
			//	//#define SURF_DIST 0.0001
			//	//#define SURF_DIST 0.00005
			//	//#define SURF_DIST 0.0002
			//	//#define SURF_DIST 0.0002
			//	//#define MAX_DIST 2000

            //    //#define CONSTRAIN_TO_MESH
            //    //#define STEP_FACTOR 1
			//#elif _SDF_FEATHER
			//	//#define MAX_STEPS 70
			//	#define MAX_STEPS 30
			//	//#define MAX_STEPS 30
			//	//#define CONSTRAIN_TO_MESH
			//	#define FUNGE_FACTOR 0.9
			//#elif defined(_SDF_TESTING) || defined(_SDF_MENGER)
			//	//#define MAX_STEPS 100
            //    //#define CONSTRAIN_TO_MESH
            //#endif

            #ifndef MAX_DIST
                #define MAX_DIST 20
            #endif 

            float _FoldingLimit;

            //#define OVERRIDE_TRANSFORM_CAMERA

            #include "../RayMarchLib.cginc"

            
            float3 _SunPos;
            float _Scale;

            float _MinRadius;
            float _FixedRadius;
            float _ScaleFactor;
            
            float _Slider_SDF;

            float _Slider_Transform;


            //sceneTransformCameraOut_t sceneTransformCamera(vec3 ro, vec3 rd)
            //{
            //    sceneTransformCameraOut_t o;
            //    float4x4 mat = {_Transform_X,_Transform_Y,_Transform_Z,_Transform_W};
            //    float3 trans = {mat[0][3],mat[1][3],mat[2][3]};
            //    o.ro = mul(mat, ro)-trans;
            //    o.rd = normalize(mul(mat, rd));//mul(mat, rd+ro)-mul(mat, ro);
            //    return o;
            //}

            //sceneTransformCameraOut_t sceneInverseTransformCamera(vec3 ro, vec3 rd)
            //{
            //    sceneTransformCameraOut_t o;
            //    float4x4 mat = {_Transform_X,_Transform_Y,_Transform_Z,_Transform_W};
            //    float3 trans = {mat[0][3],mat[1][3],mat[2][3]};
            //    mat = transpose(mat); 
            //    o.ro = mul(mat, ro+trans);
            //    o.rd = normalize(mul(mat, rd));//mul(mat, rd+ro)-mul(mat, ro);
            //    return o;
            //}

            inline material applyColorTransform(float3 p, in material mat)
            {
				const float saturation = .4;//.3;
				const float len = 0.2/0.3333; // |col|
                #ifdef _MTRANS_COLORHSV_SPHERE  
                    mat.col = fixed4(len*normalize(HSV(frac(length(p)*8 + _Time.x), saturation, 1).rgb),1);
                #elif _MTRANS_COLORHSV_CUBE
                    mat.col = fixed4(len*normalize(HSV(frac(max(abs(p.x),max(abs(p.y),abs(p.z)))*8 + _Time.x), saturation, 1).rgb),1);
                #elif _MTRANS_COLORXYZ
                    float factor = 0.5;
                    mat.col.x = p.x*factor+factor;
                    mat.col.y = p.y*factor+factor;
                    mat.col.z = p.z*factor+factor;
                #else 
					mat.col = 1;
                    // do nothing
                #endif

                //float q = length(p);
                ////float maxq = 0.14;
                //float maxq = 0.09;
                ////#if 1
                ////q = q > maxq ? (q-maxq)/maxq : 0;
                //q = (q-maxq)/maxq;
                ////q = q > .3 ? q : 0;
                ////#else
                ////q = q > maxq ? 1 : 0;
                ////#endif
                //
                ////q += (snoise(p*30)-.5)*2;

                ////q = sin(q*3);

                //q = max(0,q);

                //mat.emmision = 20*fixed3(1,.5,.1)*q;

                return mat;    
            }


            inline void applyPositionTransform(inout float3 p)
            {
				//return;
                #if defined(REPEAT_SPACE) || defined(_PTRANS_REPEAT)
                    //p.y = fmod(abs(p.y + 4), 8) - 4;
                    //p.x = fmod(abs(p.x + 4), 8) - 4;
                    //p.z = fmod(abs(p.z + 4), 8) - 4;

                    //p = repXYZUnsigned(p,r);
                    p = repXYZ(p,1);
                #endif
                #ifdef _PTRANS_TWIST 
                    //p = rotZ(p, p.z*_Slider_Transform*2);
					float3 n = normalize(vSdfConfig.xyz);
					float d = 0;//-0.2*(length(vSdfConfig.xyz));
					tripplePlaneFold(p, n, d);
					//tripplePlaneFold(p, -n, d);
					//tripplePlaneFold(p, -n, d*.5);
					//float dz = 0;
					//float t = 2;
					//boxFold(p, dz,1*t);
					//boxFold(p, dz,.5*t);
					//n = normalize(float3(_SinTime.z,_CosTime.z,_SinTime.y));
					//d = -0.1*length(n);
					//tripplePlaneFold(p, n, d);
                #elif _PTRANS_ROTATE
                    //o = fmod(abs(p + r/2.0), r) - r/2.0;
                    //p.z = fmod(p.z,8);
                    //p = rotZ(p, _Slider_Transform);
                    p = rotZ(p, _Time.x);
				#elif _PTRANS_MENGERFOLD
					//mengerFold(p);
                #else
                    // do nothing
                #endif
            }

            #define COLTRANS o.mat = applyColorTransform(p, o.mat)
            
            //#define STEP_FACTOR 1
            //#define FUNGE_FACTOR 1



            float4 sdf(float3 p, float tol)
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
				float3 t = p;

                //////////////////////////////////////////////////////////////////////
                // all of these should fit in a 1x1x1 cube or sphere 
                // with radius 1, when scaling is set to 1.
                //
                // DE should be stable enough to be viewed from 20 units away
                // (in world space)
                //////////////////////////////////////////////////////////////////////

                // Color time, transform time, sdf time


                //////////////////////////////////////////////////////////////////////
                //
                // Mandelbulb * The baseline sdf
                //
                //////////////////////////////////////////////////////////////////////
                #ifdef _SDF_MANDELBULB
                //#define FUNGE_FACTOR _FoldingLimit
                t = 0;

                //t = min(0,sdfSphere(p, .3))*200;

                float scale = .4;
                p/=scale;
                



				float4 v = fracMandelbulb2(p);
                dist = v.x;

				//t = v.yzw/4;
                //t = max(0,-sin(length(v.yzw)*9))*2;
                t = v.yzw;//max(0,sin(length(v.yzw)*6.5)-.3)*10;
                //t = max(0,-sin(length(v.yzw)*7.3)-.9)*100;
                dist*=scale;

				#elif _SDF_MANDELBOLB
                t = 0;

                float scale = 0.4;
                p/=scale;
                dist = fracMandelbolb(p);
                dist*=scale;

				#elif _SDF_TESTING_ALT2
                


                float sc = 1;


                float scaleDown = 5;
                float3 shift = -1*float3(.1,.0,.2);

                float st = 1;
                t = 0;
                for (int i = 0; i<6; i++)
                {
                    p.xyz = abs(p.xyz);
                    st*=.5;
                    mengerFold(p);
                    //planeFold(p, -normalize(float3(1,-2,1)), -0.3*st);
                    p = rotZ(p,-0.8);
                    boxFold(p,0.5);
                    p = rotX(p,0.5);


                    p*=scaleDown; 
                    sc/=scaleDown;
                    p.xyz-=shift;
                    t = max(t, p.xyz);

                }
                //planeFold(p, normalize(float3(1,1,0)), 0);

                
                dist = sdfBox(p, float3(1,1,1)*8)*sc;
                
                //dist = sdfSphere(p,.1)*sc;
                
                //static bool use_big = true;

                //float d_sel = sdfBox(p,float3(.8,.8,1.8)*0.3);

                //if (d_sel < 0) use_big = false;
                //
                //float d1_out = sdfBox(p,float3(1,1,2)*0.3);
                //float d1_in = sdfBox(p,float3(.8,.8,3)*0.3);
                //float d1 = max(d1_out, -d1_in);
                //
                //float w = .5 + .5*_SinTime.z;

                //float d2_out = sdfBox(p,float3(1+w,1+w,2)*0.3);
                //float d2_in = sdfBox(p,float3(0.8+w,0.8+w,1.8)*0.3);
                //float d2 = max(d2_out, -d2_in);
                //d2 = max(d2, -d1_in);

                //if (use_big) 
                //{
                //    dist = d1;
                //}
                //else
                //{
                //    dist = d2;
                //    //dist = sdfBox(p,float3(2,.5,.5)*0.3);
                //}


				#elif _SDF_TESTING_ALT
                float scale = .2;
                p/=scale;
				//dist = mengerSponge(p, 0, 0);
                

                float amp = 0.01*4*4;//*(1+sin(_Time.x*10))*.5;


                vec3 s = vec3(1,1,1);
                vec3 h;
                
                float pw = 6;


                float time; 

                float d2 = 1.0/0.0;
                
                vec3 q = p;
                //q = repXYZLimited(q, 4, vec3(1,1,1));
                //planeFold(q, vec3(1,0,0), -2);
                //planeFold(q, vec3(0,1,0), -2);

                float timee0 = _Time.x/4;
                time = 2.23478+int(timee0);
                q = rotZ(q,time);
                q = rotY(q,time*0.83249);
                q = rotX(q,time*1.3278);

                vec3 o = vec3(1,1,1)*.5*.5;//*.5*.5;
                vec3 off;

                float w = .04*0;
                float timee1 = timee0+w;
                float timee2 = timee1+w;

                float timeen1 = timee0-w;
                float timeen2 = timeen1-w;

                
                // the centered
                h = s*amp*.5*pow((1-cos(timee0 *PI*2))*.5,pw);
                
                d2 = min(d2,sdfXYZPlane(q,h));q = elongate(q, h);
                #if 1
                for (int i = 1; i<4; i++)
                {
                    timeen1 = timee0 - w*i;

                    h = s*amp*.5*pow((1-cos(timeen1*PI*2))*.5,pw);
                    off = o*i;
                    q += off+h;
                    d2 = min(d2,sdfXYZPlane(q,h));q = elongate(q, h);
                    timeen1 = timee0 + w*i;
                    q -= off;

                    h = s*amp*.5*pow((1-cos(timeen1*PI*2))*.5,pw);
                    off = -o*i;
                    q += (off-h);
                    d2 = min(d2,sdfXYZPlane(q,h));q = elongate(q, h);
                    q -= off;
                }
                #else
                
                // +- 1
                h = s*amp*.5*pow((1-cos(timeen1*PI*2))*.5,pw);
                off = o*1;
                q += off+h;
                d2 = min(d2,sdfXYZPlane(q,h));q = elongate(q, h);
                q -= off;

                h = s*amp*.5*pow((1-cos(timeen1*PI*2))*.5,pw);
                off = -o*1;
                q += (off-h);
                d2 = min(d2,sdfXYZPlane(q,h));q = elongate(q, h);
                q -= off;

                // +- 2

                h = s*amp*.5*pow((1-cos(timeen2*PI*2))*.5,pw);
                off = o*2;
                q += off+h;
                d2 = min(d2,sdfXYZPlane(q,h));q = elongate(q, h);
                q -= off;
                
                h = s*amp*.5*pow((1-cos(timeen2*PI*2))*.5,pw);
                off = -o*2;
                q += (off-h);
                d2 = min(d2,sdfXYZPlane(q,h));q = elongate(q, h);
                q -= off;
                #endif

                q = rotX(q,-time*1.3278);
                q = rotY(q,-time*0.83249);
                q = rotZ(q,-time);

                //time = 2.893289+int(timee2);
                //h=h2;
                //q = rotZ(q,time);
                //q = rotX(q,time);
                //d2 = min(d2,sdfXYZPlane(q,h));
                //q = elongate(q, h);
                //q = rotX(q,-time);
                //q = rotZ(q,-time);

                //time = 2.123542+int(timee3);
                //h=h3;
                //q = rotZ(q,time);
                //q = rotX(q,time);
                //d2 = min(d2,sdfXYZPlane(q,h));
                //q = elongate(q, h);
                //q = rotX(q,-time);
                //q = rotZ(q,-time);





                //q = p;
                //time = 1.894358+int(timee2);
                //h = h2;
                //q = rotZ(q,time);
                //q = rotX(q,time);
                //d2 = min(d2,min(min(max(q.x-h.x, -h.x-q.x),
                //                   max(q.y-h.y, -h.y-q.y)),
                //                   max(q.z-h.z, -h.z-q.z)));
                //q = q - clamp( q, -h, h );
                //q = rotX(q,-time);
                //q = rotZ(q,-time);

                //time = 4.5463219+int(timee3);
                //h = h3;
                //q = rotZ(q,time);
                //q = rotX(q,time);
                //d2 = min(d2,min(min(max(q.x-h.x, -h.x-q.x),
                //                   max(q.y-h.y, -h.y-q.y)),
                //                   max(q.z-h.z, -h.z-q.z)));
                //q = q - clamp( q, -h, h );
                //q = rotX(q,-time);
                //q = rotZ(q,-time);

                vec3 u = vec3(1,1,1);

                dist = sdfBox2(q,u);
                t = q*scale;
                //dist = abs(dist)-0.05;
                float rad = .5;
                //dist = min(dist, sdfSphere(q+vec3(0,1,0), rad));
                //dist = min(dist, sdfSphere(q+vec3(0,-1-rad,0), rad));
                //dist = min(dist, sdfTorus(q+vec3(0,-1-rad,0), 1, rad/4));

                //dist = min(dist, sdfSphere(q+vec3(1,0,0), rad));
                //dist = min(dist, sdfSphere(q+vec3(-1,0,0), rad));
                //dist = min(dist, sdfSphere(q+vec3(0,0,1), rad));
                //dist = min(dist, sdfSphere(q+vec3(0,0,-1), rad));


                //dist = max(dist, -sdfBox2(q,u*.7));
                float acc= .5;//.05;

                //float fac = 2.2;

                //dist = abs(dist)-0.1;
                
                //float fac = 2.6;
                //for (int i = 0; i<6; i++)
                //{
                //    dist = abs(dist)-acc;acc/=fac;
                //}


                //t = max(0,-dist)*0.5;
                //max(0,-d2+0.05)*10*h_i;
				//dist = sdfFbmAdd(q, dist, 0.15*5, 2, tol); //!
                //t = max(0,-dist-.3)*2;
                //dist = min(dist, sdfTorus(q.xyz,2.5,.3));
                //dist = min(dist, sdfTorus(q.yzx,2.5,.3));
                //dist = min(dist, sdfTorus(q.zxy,2.5,.3));



				//dist = mengerSponge(q, vSdfConfig.xyz, _Slider_SDF);//-0.01*(1+_SinTime.z);
                
                //d2 = max(d2,sdfSphere(p,2));
                
                //dist = min(dist, d2);

                dist = max(dist, -d2);
                dist*=scale;

				#elif _SDF_TESTING
                t = 0;


                float scale = .5;
                p/=scale;
                
                #if 0
                float d = sdfBox2(p,vec3(1.0, 1.0, 1.0));
                float4 res = float4( d, 1.0, 0.0, 0.0 );

                float ani = 0;
                float off = 0;

                float s = 1.0;
                for( int m=0; m<4; m++ )
                {
                    //p = mix( p, ma*(p+off), ani );
                    vec3 a = fmod( p*s+pow(4, m), 2.0 )-1.0;

                    s *= 3.0;
                    vec3 r = abs(1.0 - 3.0*abs(a));
                    float da = max(r.x,r.y);
                    float db = max(r.y,r.z);
                    float dc = max(r.z,r.x);
                    float c = (min(da,min(db,dc))-1.0)/s;

                    if( c>d )
                    {
                        d = c;
                        res = float4( d, min(res.y,0.2*da*db*dc), (1.0+float(m))/4.0, 0.0 );
                    }
                }
                dist = res.x;
                #endif

                #if 0

                vec3 w = p;
                vec3 q = p;

                q.xz = fmod( q.xz+1.0+200, 2.0 ) -1.0;

                float d = sdfBox2(q,vec3(1.0, 1.0, 1.0));
                float s = 1.0;
                for( int m=0; m<7; m++ )//7
                {
                    // this could be *any* transformation,
                    // since the distance field is just offset
                    // (and rotated
                    //p = q.yzx - 0.5*sin( 1.5*p.x + 6.0 + p.y*3.0 + float(m)*5.0 + vec3(1.0,0.0,0.0));
                    //p = q.yzx - 0.5*cos(5 + p.x + 2*p.y + m*6);
                    //p = q.yzx;

                    vec3 a = fmod( p*s+pow(16, m), 2.0 )-1.0;
                    s *= 3.0;
                    vec3 r = abs(1.0 - 3.0*abs(a));

                    float da = max(r.x,r.y);
                    float db = max(r.y,r.z);
                    float dc = max(r.z,r.x);
                    float c = (min(da,min(db,dc))-1.0)/s;
                    d = max( c, d );
                }
                d*=.5;
                d*=.5;
                d*=.5;

                dist = d;
                //d = min(d, sdfSphere(w+vec3(-.2,0,0), .1));
                p = w;
                #endif

                #if 1

                float d;
                d = sdfSphere(p*scale, .49);

                float s = 1;
                const int iterations = 7;
                const float fac = pow(4, iterations);
                vec3 q = p;
                q.xz = fmod(q.xz+1+fac, 2.0)-1.0;
                for (int m=0; m<iterations; m++)
                {
                    //p = q.yzx - 0.5*cos(5 + p.x + p.z + 2*p.y + m*6);
                    p = q.yzx+sin(
                        p.y*.4
                        +p.z*.5
                        +0.0
                        +m*8
                        //+p.zxy*vec3(4.234,3.12,8.43)
                        //+vec3(3.4365,5.324,8.435)
                    );
                    vec3 a = fmod(p*s+fac, 2.0)-1.0;
                    s*=3.0;
                    vec3 r = abs(1-3.0*abs(a));
                    #if 1
		            float c = sdfCross(r)/(s);
                    #else
                    float da = max(r.x,r.y);
                    float db = max(r.y,r.z);
                    float dc = max(r.z,r.x);
                    float c = (min(da,min(db,dc))-1.0)/s;
                    #endif
                    d = max(d, c);
                }
                //d*=.5;

                dist = d;

                #endif

                dist*=scale;
                //dist = max(dist, sdfSphere(p*scale, .49));
                //dist = max(dist, -sdfSphere(p*scale, .3));

                #if 0
                //float scale = 0.4;
                //p/=scale;
                float sc = 0.04;
                //dist = sdfRandBase(p/sc)*sc;//sdfSphere(p,.3);
                dist = sdfRandBase_pos(p/sc)*sc;//sdfSphere(p,.3);
                dist = max(dist, sdfSphere(p,.4));
                t = max(0,-length(p)+.2);
                //dist*=scale;
                #endif

				#elif _SDF_ASTEROID
                float scale = 1;
                p/=scale;
				//p = rotY(p,_Time.x);
				float sfac = .3;
				float d = p.y;//sdfSphere(p,.5*.35);
				//d = smax(d,p.y,sfac);
				p=rotY(p, _Time.x*5);
                #if 0
                d = sdfSphere(p, .2);
				//d = min(d, sdfTorus(p.xyz, .25*0.8, .06));
				//d = min(d, sdfTorus(p.zxy, .25*0.8, .06));
				//d = min(d, sdfTorus(p.yzx, .25*0.8, .06));
                
                float3 p_rot = p;
                float r = 3.1415/4;
                p_rot = rotX(p_rot, r);
                p_rot = rotY(p_rot, r);
				d = min(d, sdfTorus(p_rot.xyz, .25*1.5, .1));
				d = min(d, sdfTorus(p_rot.zxy, .25*1.5, .1));
				d = min(d, sdfTorus(p_rot.yzx, .25*1.5, .1));
                #elif 0
                //d = sdfSphere(p, .13);
                d = sdfSphere(p, 0.1);
                d = min(d,max(sdfSphere(p, .49), -sdfSphere(p, .45)));
                d = min(d,max(sdfSphere(p, .40), -sdfSphere(p, .36)));
                d = min(d,max(sdfSphere(p, .31), -sdfSphere(p, .27)));
                d = min(d,max(sdfSphere(p, .22), -sdfSphere(p, .18)));
                float d2 = max(abs(p.y)-.05, length(p)-.49);
                d = min(d, d2);
                #else
                d = sdfSphere(p, 0.49);
                //d = max(d, -sdfSphere(p, 0.05));
                float rrr = .1;
                float rroff = 0.14;
                d = max(d, -sdfSphere(p+float3(0,rroff,0), rrr));
                d = max(d, -sdfSphere(p-float3(0,rroff,0), rrr));

                #endif


                //float d2 = length(p.xz)-crossRadius;
                //d2 = min(d2, length(p.zy)-crossRadius);
                //d2 = min(d2, length(p.xy)-crossRadius);
                //float3 p_rot = rotY(p,PI/4);
                //d2 = min(d2, length(p_rot.zy)-crossRadius);
                //d2 = min(d2, length(p_rot.xy)-crossRadius);


				//d = min(d, sdfTorus(p.xzy, .25,.1));
				//d = min(d, sdfTorus(p-float3(0,-.2,0), .25,.1));
				t = d;
                
                float sc = 0.008;
                //t = max(0,-sdfRandBase_pos(p/sc))*10;
                //t = max(0,-sdfRandBase_pos(p/sc)+.7*(1-1.6*length(p)))*100;
                t = 0;//max(0,-sdfSphere(p,.1))*200;
                //t = max(0,-sdfSphere(p,.19)*5);
				//d = smax(d,-sdfSphere(p-float3(0,0,0),.4),sfac);
				//float d = sdfBox(p,float3(1,1,1));
				//float dt = sdfFbm(p,d);
				//dist = max(d, sdfRandBase(p));
				//int m = 7;
				//int u = int(_Time.y*.3);
				//p.xy+=u;
				//dist = sdfFbmAdd(p, d, 0.15*1.5, /*8*/20, tol);
				

                //d = min(d,p.y+.1*.5); //!
                
				float3 q = p + float3(0,_Time.x,0);
				dist = d;


				//dist = sdfFbmAdd(q, d, 0.15*.5, 15, tol);
				//dist = sdfFbmAdd(q, d, 0.15*2, 15, tol);
				dist = sdfFbmAdd(q, d, 0.15*2, 15, tol); //!
                dist *=scale;

                //dist = min(dist, d+.08);


				//dist = sdfFbmAdd(q+float3(30,30,30), dist, 0.15*.5, 15, tol);
				//dist = min(dist, sdfTorus(p, .25,.02));
				//dist = max(dist,sdfSphere(p,.48)); //!




				#elif _SDF_MENGER
                t=0;//max(0,-sdfSphere(p,.25))*200;
                
                //float sc = 0.01;
                //t = max(0,-sdfRandBase_pos(p/sc)+.5*(1))*100;
                //o.mat = applyColorTransform(p, o.mat); 

				//o.dist = 50.5*log(length(p))*length(p)*p.x;

                float scale = 0.24;
				p/=scale;

				//mengerFold(p);
				//scale*=3.0;
				//scaleTranslate(p,3.0,float3(-2,-2,0));
				//planeFold(p,float3(0,0,-1),-1);
                
                //dist = sdfSphere(p, 1);
                //dist = max(dist, -(length(p.yx)-.4));
                //dist = smax(dist, -sdfCross(p*3)/3, .5);
                vec3 h = normalize(sin(vec3(3,4,5)*_Time.x)+vec3(1,1,1));//normalize(vec3(1,1,.5))*.5*(1+_SinTime.z);

                float time = 2.23478;//_Time.y;

                //p = rotZ(p,time);
                //p = rotX(p,time);
                //vec3 q = p - clamp( p, -h, h );
                //vec3 v = h;
                //float d2 = min(min(max(p.x-h.x, -h.x-p.x),
                //                   max(p.y-h.y, -h.y-p.y)),
                //                   max(p.z-h.z, -h.z-p.z));
                ////float d2 = max(p.x-h.x, -h.x-p.x);
                //q = rotX(q,-time);
                //q = rotZ(q,-time);

				dist = mengerSponge(p, vSdfConfig.xyz, _Slider_SDF);//-0.01*(1+_SinTime.z);
                t = 1;//t = sdfSphere(p, 0.1*(_SinTime.y));
                dist = min(dist, t.x);

                //float3 q = float3(1,0,0)*0.4;
                //q = rotY(q,_Time.y);
                //dist = min(dist, sdfSphere(p+q,.2));
                //dist = min(dist, sdfSphere(p-q,.2));
                
                //d2 = max(d2,sdfSphere(p,.5/scale));
                //dist = min(dist, d2);
                //dist = max(dist, -d2);

				//dist = mengerSponge(p, vSdfConfig.xyz, _Slider_SDF);//-0.01*(1+_SinTime.z);

				//dist = sdfFbmAdd(p, dist, 0.15*2, 3, tol); //!
				//dist = sdfFbmAdd(p, dist, 0.25, 14, tol);
				//dist = sdfFbmAdd(p, dist, 0.25, 3, tol);
				//dist = sdfFbmAdd(p, dist, 0.25*5, 15, tol);

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
                t = 0;
                float scale = 0.44;
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
                //vSdfConfig = 0;
				vSdfConfig.w = 1+vSdfConfig.z*0.5;//+0.5;//*_SinTime.x;
                float d = sdfSphere(p,.15);//sdfBox(p, .3);
                t = max(0,-d);
                //t = -0.1;//-.3;

                float scaleFactor = smoothstep(-1,1,vSdfConfig.w)*6-3;
				//float scale = 0.5;
				float scale = 0.15;
				//_SurfDist = 0.0001;


				p/=scale;
				dist = fracMandelbox4(p, vSdfConfig.w, vSdfConfig.xyz)*scale;
				//dist = fracMandelbox3(p, vSdfConfig.w)*scale;
                //dist = max(dist, -sdfSphere(p,.2/scale));
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


                return float4(dist,t);
            }

			material calcMaterial(float3 p, float3 t, float tol)
			{
				material mat = DEFMAT;
				mat.col = fixed4(1,1,1,1)*0.6;
				mat.col.w = 1;
                //mat.emmision = fixed3(1,.5,.1)*length(t);
				mat.fSmoothness = 1;//0.5+0.5*sin(5*max(p.x,max(p.y,p.z)));
				//mat.fSmoothness = p.x>0 ? 0.3 : 0.7;//pow(sin(p.x+p.y+p.z),2);
				//p*=0.4;
				//applyPositionTransform(p);
				//return applyColorTransform(p, mat);
				mat = applyColorTransform(p, mat);
                
                float3 colFac;
                colFac = 50*float3(10,20,30);
                //mat.col = float4(abs(t.x)*5,0.5,0,1);
                //t = t.x+t.y+t.z;//max(t.x,t.y)+max(t.y,t.z)+max(t.y,t.z);
                ////t.x+t.y+t.z;
                //t.y = t.x;
                //t.z = t.x;
                //t = (1+sin(t*colFac)
                //    *float3(1,1,1));
                
                float bfac = .2;
                float ifac = 1-bfac;

                //t.x = int(t.x)*ifac + bfac;
                //t.y = int(t.y)*ifac + bfac;
                //t.z = int(t.z)*ifac + bfac;
                //mat.col = float4(t,1); 
                
                //t *= 100;
                //t = (1+int(t.x)+int(t.y)+int(t.z))%2;
                //mat.col = float4(t,1);
                //colFac = float3(0.1,.2,.2);
                //mat.emmision = float4((.5+.5*sin(t*colFac)
                //    *float3(1,1,1)*0.05
                //),1);
                return mat;
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
