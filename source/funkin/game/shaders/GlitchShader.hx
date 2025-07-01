package funkin.game.shaders;

import flixel.system.FlxAssets.FlxShader;

// https://www.shadertoy.com/view/MscGzl
class GlitchShaderA extends FlxShader
{
	@:isVar
	public var amount(get, set):Float = 0;
	
	function get_amount()
	{
		return GlitchAmount.value[0];
	}
	
	function set_amount(val:Float)
	{
		return GlitchAmount.value[0] = val;
	}
	
	@:glFragmentSource('
        #pragma header
        uniform vec2 iResolution;
        uniform float GlitchAmount;
        uniform float iTime;

        vec4 posterize(vec4 color, float numColors)
        {
            return floor(color * numColors - 0.5) / numColors;
        }

        vec2 quantize(vec2 v, float steps)
        {
            return floor(v * steps) / steps;
        }

        float dist(vec2 a, vec2 b)
        {
            return sqrt(pow(b.x - a.x, 2.0) + pow(b.y - a.y, 2.0));
        }

        void main()
        {   
            vec2 uv = openfl_TextureCoordv;
            float amount = pow(GlitchAmount, 2.0);
            vec2 pixel = 1.0 / iResolution.xy;    
            vec4 color = flixel_texture2D(bitmap, uv);
            float t = mod(mod(iTime, amount * 100.0 * (amount - 0.5)) * 109.0, 1.0);
            vec4 postColor = posterize(color, 16.0);
            vec4 a = posterize(flixel_texture2D(bitmap, quantize(uv, 64.0 * t) + pixel * (postColor.rb - vec2(.5)) * 100.0), 5.0).rbga;
            vec4 b = posterize(flixel_texture2D(bitmap, quantize(uv, 32.0 - t) + pixel * (postColor.rg - vec2(.5)) * 1000.0), 4.0).gbra;
            vec4 c = posterize(flixel_texture2D(bitmap, quantize(uv, 16.0 + t) + pixel * (postColor.rg - vec2(.5)) * 20.0), 16.0).bgra;
            gl_FragColor = mix(
                            flixel_texture2D(bitmap, 
                                    uv + amount * (quantize((a * t - b + c - (t + t / 2.0) / 10.0).rg, 16.0) - vec2(.5)) * pixel * 100.0),
                            (a + b + c) / 3.0,
                            (0.5 - (dot(color, postColor) - 1.5)) * amount);
        }
    ')
	public function new()
	{
		super();
		GlitchAmount.value = [0];
		iResolution.value = [0, 0];
		iTime.value = [0];
	}
}

// https://www.shadertoy.com/view/4dtGzl
class GlitchShaderB extends FlxShader
{
	@:isVar
	public var amount(get, set):Float = 0;
	
	function get_amount()
	{
		return Amount.value[0];
	}
	
	function set_amount(val:Float)
	{
		return Amount.value[0] = val;
	}
	
	@:glFragmentSource('
    #pragma header
    #define PI 3.14159265
#define TILE_SIZE 16.0

float wow;
uniform float iTime;
uniform vec2 iResolution;
uniform float Amount;

vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 posterize(vec3 color, float steps)
{
    return floor(color * steps) / steps;
}

float quantize(float n, float steps)
{
    return floor(n * steps) / steps;
}

vec4 downsample(sampler2D sampler, vec2 uv, float pixelSize)
{
    return flixel_texture2D(sampler, uv - mod(uv, vec2(pixelSize) / iResolution.xy));
}

float rand(float n)
{
    return fract(sin(n) * 43758.5453123);
}

float noise(float p)
{
    float fl = floor(p);
  	float fc = fract(p);
    return mix(rand(fl), rand(fl + 1.0), fc);
}

float rand(vec2 n) 
{ 
    return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}

float noise(vec2 p)
{
    vec2 ip = floor(p);
    vec2 u = fract(p);
    u = u * u * (3.0 - 2.0 * u);

    float res = mix(
        mix(rand(ip), rand(ip + vec2(1.0, 0.0)), u.x),
        mix(rand(ip + vec2(0.0,1.0)), rand(ip + vec2(1.0,1.0)), u.x), u.y);
    return res * res;
}

vec3 edge(sampler2D sampler, vec2 uv, float sampleSize)
{
    float dx = sampleSize / iResolution.x;
    float dy = sampleSize / iResolution.y;
    return (
    mix(downsample(sampler, uv - vec2(dx, 0.0), sampleSize), downsample(sampler, uv + vec2(dx, 0.0), sampleSize), mod(uv.x, dx) / dx) +
    mix(downsample(sampler, uv - vec2(0.0, dy), sampleSize), downsample(sampler, uv + vec2(0.0, dy), sampleSize), mod(uv.y, dy) / dy)    
    ).rgb / 2.0 - flixel_texture2D(sampler, uv).rgb;
}

vec4 distort(sampler2D sampler, vec2 uv, float edgeSize)
{
    vec2 pixel = vec2(1.0) / iResolution.xy;
    vec3 field = rgb2hsv(edge(sampler, uv, edgeSize));
    vec2 distort = pixel * sin((field.rb) * PI * 2.0);
    float shiftx = noise(vec2(quantize(uv.y + 31.5, iResolution.y / TILE_SIZE) * iTime, fract(iTime) * 300.0));
    float shifty = noise(vec2(quantize(uv.x + 11.5, iResolution.x / TILE_SIZE) * iTime, fract(iTime) * 100.0));
    vec4 col = flixel_texture2D(sampler, uv + (distort + (pixel - pixel / 2.0) * vec2(shiftx, shifty) * (50.0 + 100.0 * Amount)) * Amount);
    vec3 rgb = col.rgb;
    vec3 hsv = rgb2hsv(rgb);
    // hsv.y = mod(hsv.y + shifty * pow(Amount, 5.0) * 0.25, 1.0);
    return vec4(posterize(hsv2rgb(hsv), floor(mix(256.0, pow(1.0 - hsv.z - 0.5, 2.0) * 64.0 * shiftx + 4.0, 1.0 - pow(1.0 - Amount, 5.0)))), col.a);
}

void main()
{
	vec2 uv =  openfl_TextureCoordv;
    if(Amount <= 0){
        gl_FragColor = flixel_texture2D(bitmap, uv);
    }else{
        wow = clamp(mod(noise(iTime + uv.y), 1.0), 0.0, 1.0) * 2.0 - 1.0;    
        vec4 finalColor;
        finalColor += distort(bitmap, uv, 8.0);
        gl_FragColor = finalColor;
    }
}

    ')
	public function new()
	{
		super();
		Amount.value = [0];
		iTime.value = [0];
		iResolution.value = [0, 0];
	}
}

class Fuck extends FlxShader
{
	@:isVar
	public var amount(get, set):Float = 0;
	@:isVar
	public var speed(get, set):Float = 0;
	
	function get_amount()
	{
		return AMT.value[0];
	}
	
	function set_amount(val:Float)
	{
		return AMT.value[0] = val;
	}
	
	function get_speed()
	{
		return SPEED.value[0];
	}
	
	function set_speed(val:Float)
	{
		return SPEED.value[0] = val;
	}
	
	@:glFragmentSource('
    #pragma header
    //inputs
    uniform float AMT; //0 - 1 glitch amount
    uniform float SPEED; //0 - 1 speed
    uniform float iTime;
    //2D (returns 0 - 1)
float random2d(vec2 n) { 
    return fract(sin(dot(n, vec2(12.9898, 4.1414))) * 43758.5453);
}

float randomRange (in vec2 seed, in float min, in float max) {
		return min + random2d(seed) * (max - min);
}

// return 1 if v inside 1d range
float insideRange(float v, float bottom, float top) {
   return step(bottom, v) - step(top, v);
}


   
void main()
{
    
    float time = floor(iTime * SPEED * 60.0);    
	vec2 uv = openfl_TextureCoordv;
    
    //copy orig
    vec4 outCol = flixel_texture2D(bitmap, uv);
    
    //randomly offset slices horizontally
    float maxOffset = AMT/2.0;
    for (float i = 0.0; i < 10.0 * AMT; i += 1.0) {
        float sliceY = random2d(vec2(time , 2345.0 + float(i)));
        float sliceH = random2d(vec2(time , 9035.0 + float(i))) * 0.25;
        float hOffset = randomRange(vec2(time , 9625.0 + float(i)), -maxOffset, maxOffset);
        vec2 uvOff = uv;
        uvOff.x += hOffset;
        if (insideRange(uv.y, sliceY, fract(sliceY+sliceH)) == 1.0 ){
        	outCol = flixel_texture2D(bitmap, uvOff);
        }
    }
    
    //do slight offset on one entire channel
    float maxColOffset = AMT/6.0;
    float rnd = random2d(vec2(time , 9545.0));
    vec2 colOffset = vec2(randomRange(vec2(time , 9545.0),-maxColOffset,maxColOffset), 
                       randomRange(vec2(time , 7205.0),-maxColOffset,maxColOffset));
    if (rnd < 0.33){
        outCol.r = flixel_texture2D(bitmap, uv + colOffset).r;
        
    }else if (rnd < 0.66){
        outCol.g = flixel_texture2D(bitmap, uv + colOffset).g;
        
    } else{
        outCol.b = flixel_texture2D(bitmap, uv + colOffset).b;  
    }
       
	gl_FragColor = outCol;
}
')
	public function new()
	{
		super();
		AMT.value = [0];
		SPEED.value = [0.6];
		iTime.value = [0];
	}
}
