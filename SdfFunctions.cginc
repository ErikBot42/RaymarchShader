#ifndef SDFFUNCTIONS_CGINC
#define SDFFUNCTIONS_CGINC

#include "Transforms.cginc"
#include "FastMath.cginc"

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

float sdfBox(float2 p, float2 vDim)
{
	float2 d = abs(p)-vDim;
	return length(max(d,0)) + min(max(d.x,d.y),0);
}

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
		dz = 8.0*pow(m,3.5)*dz;
      	//dz = 8.0*pow(sqrt(m),7.0)*dz + 1.0;
      
        // z = z^8+z
		// xyz->polar->xyz
        float r = length(w);
        float b = 8.0*acos( w.y/r);
        float a = 8.0*atan2( w.x, w.z );
        w = c + pow(r,8.0) * float3( sin(b)*sin(a), cos(b), sin(b)*cos(a) );

        m = dot(w,w);
		if( m > 256.0 )
            break;
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
float fracMandelbox4(float3 p, float scaleFactor)
{

    float3 offset3 = p;
    //float dr = 1.0;
	float4 pdr = float4(p,1);
    int iterations = 15;//5;//10;
    //float fixedRadius = 1.0;
    //float minRadius = 1 + _SinTime.z*0.5-0.5;//0.5;
    float minRadius = 1;
    for(int i=0; i<iterations; i++)
    {
        boxFold2(pdr, 1);
    	//sphereFold2(pdr, minRadius*minRadius, fixedRadius*fixedRadius);
    	sphereFold2(pdr, minRadius);

        pdr.xyz = scaleFactor*pdr.xyz + offset3;
        pdr.w = pdr.w*abs(scaleFactor)+1;
    }

    float r = length(pdr.xyz);
    return r/abs(pdr.w);
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
float mengerSponge(float3 p, float slider=0)
{
	float d = sdfBox(p,float3(1,1,1)*(2+slider));
	//d = max(d,-sdfCross(p*3)/3);return d;

	float s = 1.0;
	int iterations = 4;
	for (int m=0; m<iterations; m++)
	{
		float fac = pow(4,iterations);
		float3 a = fmod(p*s+fac, 2.0)-1.0;
		s *= 3.0;
		float3 r = abs(1-3.0*abs(a));

		float c = sdfCross(r)/s;
		d = max(d,c);
	}
	
	return d;
}
#endif
