#ifndef SDFFUNCTIONS_CGINC
#define SDFFUNCTIONS_CGINC

#include "Transforms.cginc"
#include "FastMath.cginc"
#include "Noise.cginc"

//////////////////////////////////////////////////////////////////////
//
// SDF basic shapes
//
//////////////////////////////////////////////////////////////////////

//create sphere
float sdfSphere(float3 p, float fRadius)
{
    return length(p) - fRadius;
}

//create plane pointing to positive Y
float sdfPlane(float3 p, float fHeight)
{
    return p.y - fHeight;
}

//create plane with normal
float sdfPlane(float3 p, float3 vNorm, float fHeight)
{
    return dot(p, normalize(vNorm)) - fHeight;
}

//create cuboid
float sdfBox(float3 p, float3 vDim)
{
    float3 q = abs(p) - vDim/2.0;
    return length(max(q, 0)) + min(max(q.x, max(q.y, q.z)), 0);
}
// alternate implementation
float sdfBox2(float3 p, float3 v)
{
    float3 di = abs(p)-v;
    float mc = max(di.x, max(di.y, di.z));
    return min(mc, length(max(di, 0)));
    
}

float sdfBox(float2 p, float2 vDim)
{
	float2 d = abs(p)-vDim;
	return length(max(d,0)) + min(max(d.x,d.y),0);
}


//float sdfBoxFrame(float3 p0, float3 o, float3 s, float e)
//{
//    float3 p = abs(p0 - o);
//    float dx = sdBox(p, s * float3(0.25, 0.5, 0.5) - float3(0, e/2, e/2), float3(s.x/2, e, e));
//    float dy = sdBox(p, s * float3(0.5, 0.25, 0.5) - float3(e/2, 0, e/2), float3(e, s.y/2, e));
//    float dz = sdBox(p, s * float3(0.5, 0.5, 0.25) - float3(e/2, e/2, 0), float3(e, e, s.z/2));
//    return min(min(dx, dy), dz);
//}

float max2(float2 v)
{return max(v.x,v.y);}
// create a infinite cross
float sdfCross(float3 p)
{
	//float da = sdfBox(p.xyz,float3(99999, 1.0, 1.0));
	//float db = sdfBox(p.yzx,float3(1.0, 99999, 1.0));
	//float dc = sdfBox(p.zxy,float3(1.0, 1.0, 99999));
	
	//float da = sdfBox(p.xy, float2(1,1));
	//float db = sdfBox(p.yz, float2(1,1));
	//float dc = sdfBox(p.zx, float2(1,1));
	
	float da = max2(abs(p.xy));
	float db = max2(abs(p.yz)); 
	float dc = max2(abs(p.zx)); 
	return min(da, min(db, dc))-1;
}

//create cuboid
float sdfBox(float3 p, float3 vDim, float fRound)
{
    float3 q = abs(p) - vDim/2.0;
    return length(max(q, 0)) + min(max(q.x, max(q.y, q.z)), 0) - fRound;
}

//create line segment
float sdfLine(float3 p, float3 vStart, float3 vEnd, float fRadius)
{
    float h = min(1, max(0, dot(p-vStart, vEnd-vStart) / dot(vEnd-vStart, vEnd-vStart)));
    return length(p-vStart-(vEnd-vStart)*h)-fRadius;
}

//create infinite cylinder
float sdfCylinder(float3 p, float fRadius)
{
    return length(p.xz)-fRadius;
}
//create cylinder
float sdfCylinder(float3 p, float fRadius, float fHeight)
{
    return max(abs(p.y) - fHeight/2.0, length(p.xz) - fRadius);
}

//create cylinder
float sdfCylinder(float3 p, float fRadius, float fHeight, float fRound)
{
    return max(abs(p.y) - fHeight/2.0, length(p.xz) - fRadius) - fRound;
}

//create torus
float sdfTorus(float3 p, float fRadius, float fThickness)
{
    float2 q = float2(length(p.xz) - fRadius, p.y);
    return length(q) - fThickness;
}

//triangular prism (BOUND)
float sdfTriPrism(float3 p, float fSide, float fDepth)
{
    float3 q = abs(p);
    return max(q.z - fDepth, max(q.x * 0.866025 + p.y * 0.5, -p.y) - fSide * 0.5);
}

// Octahedron (EXACT)
float sdfOctahedron(float3 p, float s)
{
  p = abs(p);
  float m = p.x+p.y+p.z-s;
  float3 q;
       if( 3.0*p.x < m ) q = p.xyz;
  else if( 3.0*p.y < m ) q = p.yzx;
  else if( 3.0*p.z < m ) q = p.zxy;
  else return m*0.57735027;
    
  float k = clamp(0.5*(q.z-q.y+s),0.0,s); 
  return length(float3(q.x,q.y-s+k,q.z-k)); 
}


// EXACT: pyramid, height h
float sdfPyramid( float3 p, float h)
{
  float m2 = h*h + 0.25;

  p.xz = abs(p.xz);
  p.xz = (p.z>p.x) ? p.zx : p.xz;
  p.xz -= 0.5;

  float3 q = float3( p.z, h*p.y - 0.5*p.x, h*p.x + 0.5*p.y);

  float s = max(-q.x,0.0);
  float t = clamp( (q.y-0.5*p.z)/(m2+0.25), 0.0, 1.0 );

  float a = m2*(q.x+s)*(q.x+s) + q.y*q.y;
  float b = m2*(q.x+0.5*t)*(q.x+0.5*t) + (q.y-m2*t)*(q.y-m2*t);

  float d2 = min(q.y,-q.x*m2-q.y*0.5) > 0.0 ? 0.0 : min(a,b);

  return sqrt( (d2+q.z*q.z)/m2 ) * sign(max(q.z,-p.y));
}


// https://iquilezles.org/www/articles/fbmsdf/fbmsdf.htm
// sphere of random size
float sph(int3 i, float3 p, int3 c)
{
	// random radius at grid vertex i+c
	// max of r is .5 so that spheres do not intersect->final shape more stable.
	float h = fhash(i+c);
	//float val = pow(fhash(i+c),.2);
	float val = h;//1.6*(h*h);
	//float r = 0.5*val;
	//float r = 0.70*val;
	float r = 0.65*val;
	return length(p-c)-r;
}
// sphere at random pos
float sph_pos(int3 i, float3 p, int3 c)
{
    float radius = 0;//.2;//.09;//.09;
    int o = 300;
    float3 off = float3(
        fhash(i+c+int3(o,0,0)),
        fhash(i+c+int3(0,o,0)),
        fhash(i+c+int3(0,0,o))
    );
    //off = (off + 1)/2;
    off*=2;//0.9;//(1+_SinTime.z);
    //off = 0;
	return length(p-c+off)-radius;
}


float sdfRandBase_pos (float3 p)
{
	float scale = 1.5;//1;
	p/=scale;
    float3 i = floor(p);
    float3 f = frac(p);
    
    return scale*min(min(min(sph_pos(i,f,int3(0,0,0)),
                             sph_pos(i,f,int3(0,0,1))),
                         min(sph_pos(i,f,int3(0,1,0)),
                             sph_pos(i,f,int3(0,1,1)))),
                     min(min(sph_pos(i,f,int3(1,0,0)),
                             sph_pos(i,f,int3(1,0,1))),
                         min(sph_pos(i,f,int3(1,1,0)),
                             sph_pos(i,f,int3(1,1,1)))));
}

float sdfRandBase (float3 p)
{
	float scale = 1.5;//1;
	p/=scale;
    float3 i = floor(p);
    float3 f = frac(p);
    
    return scale*min(min(min(sph(i,f,int3(0,0,0)),
                             sph(i,f,int3(0,0,1))),
                         min(sph(i,f,int3(0,1,0)),
                             sph(i,f,int3(0,1,1)))),
                     min(min(sph(i,f,int3(1,0,0)),
                             sph(i,f,int3(1,0,1))),
                         min(sph(i,f,int3(1,1,0)),
                             sph(i,f,int3(1,1,1)))));
}

// use wrapper functions instead of this when making your sdf
float sdfFbm(float3 p, float d, int iterations = 7, float tol = 0, bool add = true)
{
	//p+=vSdfConfig.xyz;//.xz+=5*float2(_SinTime.x,_CosTime.x);
	float t = .2*_Time.y;
	//float q = frac(t);
	//q = smoothstep(0,1,q);
	//q = smoothstep(0,1,q);
	//p.y+=3*(int(t)+q);
	//p = rotY(p,q*3.141592*2);

	float s = 1.0;
	float smoothFactor = .3;
	for (int i = 0; i<iterations; i++)
	{
		float n = s*sdfRandBase(p); // eval octave

		if (add)
		{ // add
			n = smax(n, d-0.1*s, smoothFactor*s);
			d = smin(n, d      , smoothFactor*s);
		}
		else
		{ // subtract
			d = smax(d, -n     , smoothFactor*s);
		}

        //s *= .6+.1*_SinTime.z;
        s *= .5;
		if (max(d,tol)>s) break; // doubles framerate, but makes the df slightly discontious
		//if (tol*0.001>abs(d)) break;
		// transform to make subgrids not aligned.
		p = mul(float3x3( 0.00, 1.60, 1.20,
                -1.60, 0.72,-0.96,
                -1.20,-0.96, 1.28 ),p);
		
	}
	return d;
}

// Additive roughness to sdf. 
// High iterations are expensive.
// Low scale is faster, and sometimes even looks more high fidelity 
// The more "bumpy" a surface is, the more steps a raymarch has to take
// if a high scale is needed, consider using a (filtered) normal texture instead.
// p - point
// d - original sdf distance at point
// scale - scale of noise
// tol - how much to care about small details
float sdfFbmAdd(float3 p, float d, float scale = 1, int iterations = 7, float tol = 0.001)
{
	return sdfFbm(p/scale, d/scale, iterations, (tol*1.0)/scale, false)*scale;
}

//////////////////////////////////////////////////////////////////////
//
// Fractals, complex shapes and scenes  (frac prefix)
//
//////////////////////////////////////////////////////////////////////

//TODO: 
// complex :julia, 
// simple sierpinsky, menger

// Mandelbolb - OPTIMIZED AF, still a fractal but visually diffrent.
float fracMandelbolb(float3 p)
{
    // http://blog.hvidtfeldts.net/index.php/2011/09/distance-estimated-3d-fractals-v-the-mandelbulb-different-de-approximations/
    float3 pos;
    pos.x = p.x;
    pos.y = p.y;
    pos.z = p.z;

    float dr = 1.0;
    float r = 0;

    const int iterations = 10;//4;

    const float maxRThreshold = 2;//2;

    const float Power = 8;//16;

	float dist;
	float fracScale = 1;
    for (int i = 0; ; i++)
    {
        r = length(p);
		dist = 0.5*log(r)*r/dr;

        if (r>maxRThreshold || (!(i < iterations)) || dist/fracScale>0.05) break;
		fracScale*=0.5;

        // xyz -> polar
        //float theta = acos( p.z / r );
        float theta = acosFast4( p.z / r );
        //float phi = atan2( p.y, p.x );
        float phi = atanFast4_2( p.y, p.x );
        dr = pow( r, Power-1.0)*Power*dr + 1.0;

        // transform point
        float zr = pow( r, Power );
        theta = theta * Power;
        phi = phi * Power;

        // polar -> xyz
        p = zr*float3(sin(theta)*cos(phi), sin(phi)*sin(theta), cos(theta));
        p += pos;
    }


    return dist;//0.5*log(r)*r/dr;
}

void pow3D(inout float3 p, in const float power, in const float r)
{
	// xyz -> zr,theta,phi
	float theta = acos( p.z / r );
	float phi = atan2( p.y, p.x );

	// scale and rotate
	// this is the generalized operation
	float zr = pow(r,power);
	theta = theta * power;
	phi = phi * power;

	// polar -> xyz
	p = zr*float3(sin(theta)*cos(phi), sin(phi)*sin(theta), cos(theta));

}

void pow3D_8(inout float3 p, in const float r)
{
	fixed power = 8;
	// xyz -> zr,theta,phi
	float theta = acos( p.z / r );
	float phi = atan2( p.y, p.x );

	// scale and rotate
	// this is the generalized operation
	float zr = pow(r,power);
	theta = theta * power;
	phi = phi * power;

	// polar -> xyz
	//p = zr*float3(sin(theta)*cos(phi), sin(phi)*sin(theta), cos(theta));
	p = zr*float3(sin(theta)*cos(phi), sin(phi)*sin(theta), cos(theta));

	//https://www.iquilezles.org/www/articles/mandelbulb/mandelbulb.htm

	//float x = p.x; float x2 = x*x; float x4 = x2*x2;
    //float y = p.y; float y2 = y*y; float y4 = y2*y2;
    //float z = p.z; float z2 = z*z; float z4 = z2*z2;

    //float k3 = x2 + z2;
    //float k2 = rsqrt( k3*k3*k3*k3*k3*k3*k3 );
    //float k1 = x4 + y4 + z4 - 6.0*y2*z2 - 6.0*x2*y2 + 2.0*z2*x2;
    //float k4 = x2 - y2 + z2;

    //p.x =  64.0*x*y*z*(x2-z2)*k4*(x4-6.0*x2*z2+z4)*k1*k2;
    //p.y = -16.0*y2*k3*k4*k4 + k1*k1;
    //p.z = -8.0*y*k4*(x4*x4 - 28.0*x4*x2*z2 + 70.0*x4*z4 - 28.0*x2*z2*z4 + z4*z4)*k1*k2;
}

// Mandelbulb
float fracMandelbulb(float3 p)
{
    // http://blog.hvidtfeldts.net/index.php/2011/09/distance-estimated-3d-fractals-v-the-mandelbulb-different-de-approximations/
    float3 c = p;
    float dr = 1.0;
    float r;

    const int iterations = 5;//8

    const float maxRThreshold = 2; //"infinity"

    float Power = 8; // Z_(n+1) = Z(n)^? + c
    for (int i = 0; i < iterations; i++)
    {
        r = length(p);
        if (r>maxRThreshold) break;

		dr = pow( r, Power-1.0)*Power*dr + 1.0;
		
		pow3D(p, Power, r);
        p += c;
    }
    return 0.5*log(r)*r/dr;
}

// Mandelbulb + orbit trap
float4 fracMandelbulb2(float3 p)
{
    // http://blog.hvidtfeldts.net/index.php/2011/09/distance-estimated-3d-fractals-v-the-mandelbulb-different-de-approximations/
    float3 c = p;
    float dr = 1.0;
    float r;

    const int iterations = 9;//5;//8

    const float maxRThreshold = 2; //"infinity"

    float Power = 8; // Z_(n+1) = Z(n)^? + c

	float minDist = 1e20;
	float3 origin = p;
	float3 closest = p;

    for (int i = 0; i < iterations; i++)
    {
        r = length(p);
        if (r>maxRThreshold) break;

		dr = pow( r, Power-1.0)*Power*dr + 1.0;
		
		pow3D(p, Power, r);
        p += c;

		if (length(p)<minDist) {minDist = length(p); closest = p;}
    }
    return float4(0.5*log(r)*r/dr, closest);
}

// Juliabulb
float fracJuliabulb(float3 p, float3 c = float3(1,1,1), float Power = 8)
{
    // http://blog.hvidtfeldts.net/index.php/2011/09/distance-estimated-3d-fractals-v-the-mandelbulb-different-de-approximations/
	float time = _Time.z*2;
    //float3 c = float3(sin(time*0.12354), sin(time*0.328432), sin(time*0.234723))*1;
    //float3 c = float3(sin(time),cos(time),sin(time*0.096234))*(sin(0.254*time)+1);
    float dr = 1.0;
    float r;


    const int iterations = 4;//10

    const float maxRThreshold = 1.5;//2; //"infinity"

    //float Power = 6;//8; // Z_(n+1) = Z(n)^? + c
    for (int i = 0; i < iterations; i++)
    {
        r = length(p);
        if (r>maxRThreshold) break;

		dr = pow( r, Power-1.0)*Power*dr;
		
		pow3D_8(p, r);
        p += c;
    }
    return 0.5*log(r)*r/dr;
}


float fracJuliabulb2(float3 p, float3 c = float3(1,1,1), float Power = 8)
{
    // http://blog.hvidtfeldts.net/index.php/2011/09/distance-estimated-3d-fractals-v-the-mandelbulb-different-de-approximations/
    float3 w = p;
	//float3 c = float3(1,1,1);
    float m = dot(w,w);

	float dz = 1.0;
    
	for( int i=0; i<4; i++ )
    {
        
        // dz = 8*z^7*dz
		//dz = 8.0*pow(m,3.5)*dz + 1.0;
		dz = Power*pow(m,(Power-1)/2)*dz;
      	//dz = 8.0*pow(sqrt(m),7.0)*dz + 1.0;
      
        // z = z^8+z
		// xyz->polar->xyz
        float r = length(w);
        float b = Power*acos( w.y/r);
        float a = Power*atan2( w.x, w.z );
        w = c + pow(r,Power) * float3( sin(b)*sin(a), cos(b), sin(b)*cos(a) );

        m = dot(w,w);
		if( m > 1024.0 ) break;
		//if( m > 256.0 ) break;
		//if( m > 16.0 ) break;
    }

    //resColor = vec4(m,trap.yzw);

    return 0.25*log(m)*sqrt(m)/dz;
}

// Mandelbox
float fracMandelbox(float3 p, float scaleFactor)
{
    // http://blog.hvidtfeldts.net/index.php/2011/11/distance-estimated-3d-fractals-vi-the-mandelbox/

    float3 offset3 = p;
    float dr = 1.0;//0;
   
    // Parameters
    int iterations = 10;//4;//20;//14;
    //scaleFactor = -2 + (_SinTime.x*4+2);
    float fixedRadius = 1.0;
    float minRadius = 0.5;
    /*float foldingLimit = 0.2 + _SinTime.x/4 + 0.25;
    float minRadius = 0.07;
    float fixedRadius = 0.2;*/
    
    //float scaleFactor = -0.8;
    

    /*float foldingLimit = _FoldingLimit;
    float minRadius = _MinRadius;
    float fixedRadius = _FixedRadius;*/
    

    for(int i=0; i<iterations; i++)
    {
        boxFold(p, dr, 1);
        sphereFold(p, dr, minRadius, fixedRadius);

        p = scaleFactor*p + offset3;
        //dr = dr*abs(scaleFactor)+1.0;
        dr = dr*abs(scaleFactor)+1;
    }


    float r = length(p);
    return r/abs(dr);
}

// Mandelbox with 4d float, possibly faster
float fracMandelbox3(float3 p, float scaleFactor)
{

    float3 offset3 = p;
    //float dr = 1.0;
	float4 pdr = float4(p,1);
    int iterations = 10;
    float fixedRadius = 1.0;
    float minRadius = 0.5;
    for(int i=0; i<iterations; i++)
    {
        boxFold2(pdr, 1);
        sphereFold2(pdr, minRadius*minRadius, fixedRadius*fixedRadius);

        pdr.xyz = scaleFactor*pdr.xyz + offset3;
        pdr.w = pdr.w*abs(scaleFactor)+1;
    }
    float r = length(pdr.xyz);
    return r/abs(pdr.w);
}

// Testing, definetly has things wrong about it.
// Looks similar, significantly cheaper.
// Breaks in the middle to save a few cycles
float fracMandelbox4(float3 p, float scaleFactor, float3 sdfConfig = 0)
{
	
	float scale = 1;
	if (scaleFactor>0) {scaleFactor+=2; scale/=(scaleFactor+1)/(scaleFactor-1);}
	else {scaleFactor-=1;}
	p/=scale;

    float3 offset3 = p;//+sdfConfig;
	

    //float dr = 1.0;
	float4 pdr = float4(p,1);
    int iterations = 10;//10;
	int iterationsPre = 5;
    //float fixedRadius = 1.0;
    //float minRadius = 1 + _SinTime.z*0.5-0.5;//0.5;
    //sphereFold2(pdr, minRadius*minRadius, fixedRadius*fixedRadius);
    float minRadius = 1;
    for(int i=0; i<iterationsPre; i++)
    {
        boxFold2(pdr, 1);
    	sphereFold2(pdr, minRadius*(1+.5*sdfConfig.x));

        pdr.xyz = scaleFactor*pdr.xyz + offset3;
        pdr.w = pdr.w*abs(scaleFactor)+1;
    }
	float dist = length(pdr.xyz)/abs(pdr.w);
	[branch] if (dist>0.019) return dist*scale;//0.02
    for(int i=0; i<iterations-iterationsPre; i++)
    {
        boxFold2(pdr, 1);
    	//sphereFold2(pdr, minRadius*(1+.5*sdfConfig.y));

        pdr.xyz = scaleFactor*pdr.xyz + offset3;
        pdr.w = pdr.w*abs(scaleFactor)+1;
    }
    
    return (length(pdr.xyz)/abs(pdr.w)-0.0001*1)*scale;
}

// Mandelbox alternate implementation, possibly faster
float fracMandelbox2(float3 p, float foldingLimit, float minRadius, float fixedRadius, float scaleFactor)
{
    // http://www.fractalforums.com/3d-fractal-generation/a-mandelbox-distance-estimate-formula/
    float scale = -2;

    int iterations = 10;
    float DEfactor;
    for (int i = 0; i<iterations; i++)
    {
        DEfactor = scale;

        fixedRadius = 1.0;
        float fR2 = fixedRadius*fixedRadius;
        minRadius = 0.5;
        float mR2 = minRadius*minRadius;

        // Box fold?
        if (p.x > 1.0)
            p.x = 2.0 - p.x;
        else if (p.x < -1.0) p.x = -2.0 - p.x;
        if (p.y > 1.0)
            p.y = 2.0 - p.y;
        else if (p.y < -1.0) p.y = -2.0 - p.y;
        if (p.z > 1.0)
            p.z = 2.0 - p.z;
        else if (p.z < -1.0) p.z = -2.0 - p.z;

        // radius squared
        float r2 = dot(p,p);

        if (r2 < mR2)
        {
            p*=(fR2/mR2);
            DEfactor*=(fR2/mR2);
        }
        else if (r2 < fR2)
        {
            p*=(fR2/r2);
            DEfactor*=(fR2/r2);
        }
        p=p*scale+1;
        DEfactor*=scale;
    }
    return length(p)/abs(DEfactor);
}

// Feather
float fracFeather(float3 p)
{
    // https://fractalforums.org/index.php?action=gallery;sa=view;id=5732
    int iterations = 5;
    float cx = 2.0;
    float cy = 2.7;
    float cz = 1.4;
    float cw = 0.1;
    float dx = 1.5;
    
    float lp,r2,s = 1;
    float icy = 1.0 / cy;
    float3 p2,cy3 = float3(cy,cy,cy);

    for (int i=0; i<iterations; i++) {
        p -= cx * round(p / cx);
   
        p2 = pow(abs(p),cy3);
        lp = pow(p2.x + p2.y + p2.z, icy);
       
        r2 = dx / max( pow(lp,cz), cw);
        p *= r2;
        s *= r2;
    }
    
    return length(p)/s-.001;
}

//https://github.com/pedrotrschneider/shader-fractals/blob/main/3D/MengerSponge.glsl
float sierpinski3 (in float3 z) {
  float iterations = 5.0;
  float Scale = 2.0 + (sin (_Time.z / 2.0) + 1.0);
  float3 _Offset = 3.0 * float3 (1.0, 1.0, 1.0);
  float bailout = 1000.0;

  float r = length (z);
  int n = 0;
  while (n < int (iterations) && r < bailout) {

    z.x = abs (z.x);
    z.y = abs (z.y);
    z.z = abs (z.z);

    if (z.x - z.y < 0.0) z.xy = z.yx; // fold 1
    if (z.x - z.z < 0.0) z.xz = z.zx; // fold 2
    if (z.y - z.z < 0.0) z.zy = z.yz; // fold 3

    z.x = z.x * Scale - _Offset.x * (Scale - 1.0);
    z.y = z.y * Scale - _Offset.y * (Scale - 1.0);
    z.z = z.z * Scale;

    if (z.z > 0.5 * _Offset.z * (Scale - 1.0)) {
      z.z -= _Offset.z * (Scale - 1.0);
    }

    r = length (z);

    n++;
  }

  return (length (z) - 2.0) * pow (Scale, -float (n));
}

// https://iquilezles.org/www/articles/menger/menger.htm
float mengerSponge(float3 p, float3 slider=0, float scaleSlider=0)
{
	slider = 0;
	float d;
	float scale = max(0.1,1+scaleSlider);

	p/=scale;

	//d = sdfBox(p,float3(2,2,2)/scale);
	d = sdfSphere(p,2/scale);

	//d = max(d, sdfCylinder(p, 1.5/scale));
	//float time = _Time.x;
	//d = sdfTorus(rotZ(p.xyz,time), 1.5/scale, 0.5/scale);
	//d = min(d, sdfTorus(rotZ(p.yzx,time), 1.5/scale, 0.5/scale));
	//d = min(d, sdfTorus(rotZ(p.zxy, time), 1.5/scale, 0.5/scale));
	//d = min(d, sdfSphere(p, 0.8/scale));
	//d = max(d,-sdfCross(p*3)/3);return d;
	

	float s = 1.0;
	const int iterations = 5;//4;
	const float fac = pow(4,iterations);
	for (int m=0; m<iterations; m++)
	{
		//p = rotX(p,slider.x*0.3);
		//p = rotY(p,slider.y*0.3);
		//p = rotZ(p,slider.z*0.3);
		float3 a = fmod(p*s+fac, 2.0)-1.0;
		s *= 3.0;
		float3 r = abs(1-3.0*abs(a));

		//float c = sdfCross(r)/(s);
		float c = sdfCross(r*(1+0.3*slider))/(s);
		d = max(d,c);
	}
	
	return d*scale;
}

float fracFlake(float3 p)
{	
	float r = .7;
	float4 q = vSdfConfig;//0;//vSdfConfig*0.7*r*(.5+.5*_SinTime.z);
	float r2 = r*.7;
	float scaleDiff = .4;
	float scale = 1*scaleDiff;
	for (int i = 0; i<4; i++)
	{
		p/=scaleDiff;
		p.y-=r*1.5;
		scale*=scaleDiff;
		planeFold(p, normalize(float3(1,  1,  0)), -r);
		planeFold(p, normalize(float3(0,  1,  1)), -r);
		planeFold(p, normalize(float3(-1, 1,  0)), -r);
		planeFold(p, normalize(float3(0,  1, -1)), -r);
		//planeFoldSmooth(p, normalize(float3(1,  1,  0)), -r, abs(q.w));
		//planeFoldSmooth(p, normalize(float3(0,  1,  1)), -r, abs(q.w));
		//planeFoldSmooth(p, normalize(float3(-1, 1,  0)), -r, abs(q.w));
		//planeFoldSmooth(p, normalize(float3(0,  1, -1)), -r, abs(q.w));
	}
	//p = rotX(p,q.x*20);
	//p = rotY(p,q.y*20);
	//p = rotZ(p,q.z*20);
	return sdfOctahedron(p, r2)*scale;
	//return sdfSphere(p, r)*scale;
}

#endif
