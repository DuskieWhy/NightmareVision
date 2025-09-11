package funkin.game.shaders;

import flixel.system.FlxAssets.FlxShader;

class ChromaticAberrationShader extends FlxShader
{
	/**
	 * The red channel offset.
	 */
	public var red(default, set):Float = 0;
	
	/**
	 * The blue channel offset.
	 */
	public var blue(default, set):Float = 0;
	
	function set_red(value:Float):Float
	{
		return (this.u_red.value[0] = red = value);
	}
	
	function set_blue(value:Float):Float
	{
		return (this.u_blue.value[0] = blue = value);
	}
	
	@:glFragmentSource('
		#pragma header

		uniform float u_red;
		uniform float u_blue;

		void main()
		{
			vec4 tex = flixel_texture2D(bitmap, openfl_TextureCoordv);

			vec4 r = flixel_texture2D(bitmap, openfl_TextureCoordv - vec2(u_red, 0.0));
			vec4 b = flixel_texture2D(bitmap, openfl_TextureCoordv - vec2(u_blue, 0.0));
			tex.r = r.r;
			tex.b = b.b;

			gl_FragColor = tex;
		}
	')
	public function new()
	{
		super();
	}
	
	public function setChrom(offset:Float = 0.0)
	{
		red = offset;
		blue = -offset;
	}
}

class ScanlineShader extends FlxShader
{
	public var alphaLock(default, set):Bool = false;
	
	function set_alphaLock(value:Bool):Bool
	{
		return (this.u_alphaLock.value[0] = alphaLock = value);
	}
	
	@:glFragmentSource('
		#pragma header

		const float scale = 1.0;

		uniform bool u_alphaLock;

		void main()
		{
			if (mod(floor(openfl_TextureCoordv.y * openfl_TextureSize.y / scale), 2.0) == 0.0 )
			{
	
				vec4 texColor = texture2D(bitmap, openfl_TextureCoordv);

				float bitch = 1.0;

				if (u_alphaLock) bitch = texColor.a;

				gl_FragColor = vec4(0.0, 0.0, 0.0, bitch);
			}
			else
			{
				gl_FragColor = texture2D(bitmap, openfl_TextureCoordv);
			}
		}
	')
	public function new(alphaLock:Bool = false)
	{
		super();
		this.alphaLock = alphaLock;
	}
}

class Tiltshift extends FlxShader
{
	public var center(default, set):Float = 0;
	
	public var blur(default, set):Float = 0;
	
	function set_center(value:Float):Float
	{
		return (u_center.value[0] = center = value);
	}
	
	function set_blur(value:Float):Float
	{
		return (u_blur.value[0] = blur = value);
	}
	
	@:glFragmentSource('
		#pragma header

		// Modified version of a tilt shift shader from Martin Jonasson (http://grapefrukt.com/)
		// Read http://notes.underscorediscovery.com/ for context on shaders and this file
		// License : MIT
		 
			/*
				Take note that blurring in a single pass (the two for loops below) is more expensive than separating
				the x and the y blur into different passes. This was used where bleeding edge performance
				was not crucial and is to illustrate a point. 
		 
				The reason two passes is cheaper? 
				   texture2D is a fairly high cost call, sampling a texture.
		 
				   So, in a single pass, like below, there are 3 steps, per x and y. 
		 
				   That means a total of 9 "taps", it touches the texture to sample 9 times.
		 
				   Now imagine we apply this to some geometry, that is equal to 16 pixels on screen (tiny)
				   (16 * 16) * 9 = 2304 samples taken, for width * height number of pixels, * 9 taps
				   Now, if you split them up, it becomes 3 for x, and 3 for y, a total of 6 taps
				   (16 * 16) * 6 = 1536 samples
			
				   That\'s on a *tiny* sprite, let\'s scale that up to 128x128 sprite...
				   (128 * 128) * 9 = 147,456
				   (128 * 128) * 6 =  98,304
		 
				   That\'s 33.33..% cheaper for splitting them up.
				   That\'s with 3 steps, with higher steps (more taps per pass...)
		 
				   A really smooth, 6 steps, 6*6 = 36 taps for one pass, 12 taps for two pass
				   You will notice, the curve is not linear, at 12 steps it\'s 144 vs 24 taps
				   It becomes orders of magnitude slower to do single pass!
				   Therefore, you split them up into two passes, one for x, one for y.
			*/
		 
		// I am hardcoding the constants like a jerk
			
		uniform float u_blur;
		uniform float u_center;

		const float stepSize    = 0.004;
		const float steps       = 3.0;
		 
		const float minOffs     = (float(steps-1.0)) / -2.0;
		const float maxOffs     = (float(steps-1.0)) / +2.0;
		 
		void main() 
		{
			// Work out how much to blur based on the mid point 
			float amount = pow((openfl_TextureCoordv.y * u_center) * 2.0 - 1.0, 2.0) * u_blur;
				
			// This is the accumulation of color from the surrounding pixels in the texture
			vec4 blurred = vec4(0.0, 0.0, 0.0, 1.0);
				
			// From minimum offset to maximum offset
			for (float offsX = minOffs; offsX <= maxOffs; ++offsX) {
				for (float offsY = minOffs; offsY <= maxOffs; ++offsY) {
		 
					// copy the coord so we can mess with it
					vec2 temp_tcoord = openfl_TextureCoordv.xy;
		 
					//work out which uv we want to sample now
					temp_tcoord.x += offsX * amount * stepSize;
					temp_tcoord.y += offsY * amount * stepSize;
		 
					// accumulate the sample 
					blurred += texture2D(bitmap, temp_tcoord);
				}
			} 
				
			// because we are doing an average, we divide by the amount (x AND y, hence steps * steps)
			blurred /= float(steps * steps);
		 
			// return the final blurred color
			gl_FragColor = blurred;
		}
			
	')
	public function new(blur:Float = 0, center:Float = 0)
	{
		super();
		this.blur = blur;
		this.center = center;
	}
}

class GreyscaleShader extends FlxShader
{
	@:glFragmentSource('
		#pragma header
		void main() 
		{
			vec4 color = texture2D(bitmap, openfl_TextureCoordv);
			float gray = dot(color.rgb, vec3(0.299, 0.587, 0.114));
			gl_FragColor = vec4(vec3(gray), color.a);
		}
	')
	public function new()
	{
		super();
	}
}

class GrainAndChromaticAbberationShader extends FlxShader
{
	/**
	 * The red channel offset.
	 */
	public var red(default, set):Float = 0;
	
	/**
	 * The blue channel offset.
	 */
	public var blue(default, set):Float = 0;
	
	public var luminance(default, set):Float = 0;
	
	public var grainScale(default, set):Float = 0;
	
	public var alphaLock(default, set):Bool = false;
	
	function set_red(value:Float):Float
	{
		return (this.u_red.value[0] = red = value);
	}
	
	function set_blue(value:Float):Float
	{
		return (this.u_blue.value[0] = blue = value);
	}
	
	function set_luminance(value:Float):Float
	{
		return (lumamount.value[0] = luminance = value);
	}
	
	function set_grainScale(value:Float):Float
	{
		return (grainsize.value[0] = grainScale = value);
	}
	
	function set_alphaLock(value:Bool):Bool
	{
		return (this.lockAlpha.value[0] = alphaLock = value);
	}
	
	public function update(elapsed:Float)
	{
		uTime.value[0] += elapsed;
	}
	
	@:glFragmentSource('
		#pragma header

		uniform float u_red;
		uniform float u_blue;
		uniform float uTime;
		uniform float coloramount;
		uniform float grainsize; //grain particle size (1.5 - 2.5)
		uniform float lumamount;
		uniform bool lockAlpha;

		/*
		Film Grain post-process shader v1.1
		Martins Upitis (martinsh) devlog-martinsh.blogspot.com
		2013

		--------------------------
		This work is licensed under a Creative Commons Attribution 3.0 Unported License.
		So you are free to share, modify and adapt it for your needs, and even use it for commercial use.
		I would also love to hear about a project you are using it.

		Have fun,
		Martins
		--------------------------

		Perlin noise shader by toneburst:
		http://machinesdontcare.wordpress.com/2009/06/25/3d-perlin-noise-sphere-vertex-shader-sourcecode/
		*/


		const float permTexUnit = 1.0/256.0;        // Perm texture texel-size
		const float permTexUnitHalf = 0.5/256.0;    // Half perm texture texel-size

		float width = openfl_TextureSize.x;
		float height = openfl_TextureSize.y;

		const float grainamount = 0.05; //grain amount
		bool colored = false; //colored noise?


		//a random texture generator, but you can also use a pre-computed perturbation texture

		vec4 rnm(in vec2 tc)
		{
			float noise =  sin(dot(tc + vec2(uTime,uTime),vec2(12.9898,78.233))) * 43758.5453;

			float noiseR =  fract(noise)*2.0-1.0;
			float noiseG =  fract(noise*1.2154)*2.0-1.0;
			float noiseB =  fract(noise * 1.3453) * 2.0 - 1.0;
			
				
			float noiseA =  (fract(noise * 1.3647) * 2.0 - 1.0);

			return vec4(noiseR,noiseG,noiseB,noiseA);
		}

		float fade(in float t) {
			return t*t*t*(t*(t*6.0-15.0)+10.0);
		}

		float pnoise3D(in vec3 p)
		{
			vec3 pi = permTexUnit*floor(p)+permTexUnitHalf; // Integer part, scaled so +1 moves permTexUnit texel
			// and offset 1/2 texel to sample texel centers
			vec3 pf = fract(p);     // Fractional part for interpolation

			// Noise contributions from (x=0, y=0), z=0 and z=1
			float perm00 = rnm(pi.xy).a ;
			vec3  grad000 = rnm(vec2(perm00, pi.z)).rgb * 4.0 - 1.0;
			float n000 = dot(grad000, pf);
			vec3  grad001 = rnm(vec2(perm00, pi.z + permTexUnit)).rgb * 4.0 - 1.0;
			float n001 = dot(grad001, pf - vec3(0.0, 0.0, 1.0));

			// Noise contributions from (x=0, y=1), z=0 and z=1
			float perm01 = rnm(pi.xy + vec2(0.0, permTexUnit)).a ;
			vec3  grad010 = rnm(vec2(perm01, pi.z)).rgb * 4.0 - 1.0;
			float n010 = dot(grad010, pf - vec3(0.0, 1.0, 0.0));
			vec3  grad011 = rnm(vec2(perm01, pi.z + permTexUnit)).rgb * 4.0 - 1.0;
			float n011 = dot(grad011, pf - vec3(0.0, 1.0, 1.0));

			// Noise contributions from (x=1, y=0), z=0 and z=1
			float perm10 = rnm(pi.xy + vec2(permTexUnit, 0.0)).a ;
			vec3  grad100 = rnm(vec2(perm10, pi.z)).rgb * 4.0 - 1.0;
			float n100 = dot(grad100, pf - vec3(1.0, 0.0, 0.0));
			vec3  grad101 = rnm(vec2(perm10, pi.z + permTexUnit)).rgb * 4.0 - 1.0;
			float n101 = dot(grad101, pf - vec3(1.0, 0.0, 1.0));

			// Noise contributions from (x=1, y=1), z=0 and z=1
			float perm11 = rnm(pi.xy + vec2(permTexUnit, permTexUnit)).a ;
			vec3  grad110 = rnm(vec2(perm11, pi.z)).rgb * 4.0 - 1.0;
			float n110 = dot(grad110, pf - vec3(1.0, 1.0, 0.0));
			vec3  grad111 = rnm(vec2(perm11, pi.z + permTexUnit)).rgb * 4.0 - 1.0;
			float n111 = dot(grad111, pf - vec3(1.0, 1.0, 1.0));

			// Blend contributions along x
			vec4 n_x = mix(vec4(n000, n001, n010, n011), vec4(n100, n101, n110, n111), fade(pf.x));

			// Blend contributions along y
			vec2 n_xy = mix(n_x.xy, n_x.zw, fade(pf.y));

			// Blend contributions along z
			float n_xyz = mix(n_xy.x, n_xy.y, fade(pf.z));

			// We are done, return the final noise value.
			return n_xyz;
		}

		//2d coordinate orientation thing
		vec2 coordRot(in vec2 tc, in float angle)
		{
			float aspect = width/height;
			float rotX = ((tc.x*2.0-1.0)*aspect*cos(angle)) - ((tc.y*2.0-1.0)*sin(angle));
			float rotY = ((tc.y*2.0-1.0)*cos(angle)) + ((tc.x*2.0-1.0)*aspect*sin(angle));
			rotX = ((rotX/aspect)*0.5+0.5);
			rotY = rotY*0.5+0.5;
			return vec2(rotX,rotY);
		}

		void main()
		{
			vec4 col1 = texture2D(bitmap, openfl_TextureCoordv - vec2(u_red, 0.0));
			vec4 col3 = texture2D(bitmap, openfl_TextureCoordv - vec2(u_blue, 0.0));
			vec4 toUse = texture2D(bitmap, openfl_TextureCoordv);
			toUse.r = col1.r;
			toUse.b = col3.b;

			vec2 texCoord = openfl_TextureCoordv.st;

			vec3 rotOffset = vec3(1.425,3.892,5.835); //rotation offset values
			vec2 rotCoordsR = coordRot(texCoord, uTime + rotOffset.x);
			vec3 noise = vec3(pnoise3D(vec3(rotCoordsR*vec2(width/grainsize,height/grainsize),0.0)));

			if (colored)
			{
				vec2 rotCoordsG = coordRot(texCoord, uTime + rotOffset.y);
				vec2 rotCoordsB = coordRot(texCoord, uTime + rotOffset.z);
				noise.g = mix(noise.r,pnoise3D(vec3(rotCoordsG*vec2(width/grainsize,height/grainsize),1.0)),coloramount);
				noise.b = mix(noise.r,pnoise3D(vec3(rotCoordsB*vec2(width/grainsize,height/grainsize),2.0)),coloramount);
			}

			vec3 col = texture2D(bitmap, openfl_TextureCoordv).rgb;

			//noisiness response curve based on scene luminance
			vec3 lumcoeff = vec3(0.299,0.587,0.114);
			float luminance = mix(0.0,dot(col, lumcoeff),lumamount);
			float lum = smoothstep(0.2,0.0,luminance);
			lum += luminance;


			noise = mix(noise,vec3(0.0),pow(lum,4.0));
			col = col+noise*grainamount;

			float bitch = 1.0;
			vec4 texColor = texture2D(bitmap, openfl_TextureCoordv);
				if (lockAlpha) bitch = texColor.a;

				col.r = col1.r;
				col.g = col2.g;
				col.b = col3.b;

			gl_FragColor = vec4(col,bitch); 
		}

	')
	public function new()
	{
		super();
		uTime.value = [0];
	}
	
	public function setChrom(offset:Float = 0.0)
	{
		red = offset;
		blue = -offset;
	}
}

class Grain extends FlxShader
{
	public var luminance(default, set):Float = 0;
	
	public var grainScale(default, set):Float = 0;
	
	public var alphaLock(default, set):Bool = false;
	
	function set_luminance(value:Float):Float
	{
		return (lumamount.value[0] = luminance = value);
	}
	
	function set_grainScale(value:Float):Float
	{
		return (grainsize.value[0] = grainScale = value);
	}
	
	function set_alphaLock(value:Bool):Bool
	{
		return (this.lockAlpha.value[0] = alphaLock = value);
	}
	
	public function update(elapsed:Float)
	{
		uTime.value[0] += elapsed;
	}
	
	@:glFragmentSource('
		#pragma header

		/*
		Film Grain post-process shader v1.1
		Martins Upitis (martinsh) devlog-martinsh.blogspot.com
		2013

		--------------------------
		This work is licensed under a Creative Commons Attribution 3.0 Unported License.
		So you are free to share, modify and adapt it for your needs, and even use it for commercial use.
		I would also love to hear about a project you are using it.

		Have fun,
		Martins
		--------------------------

		Perlin noise shader by toneburst:
		http://machinesdontcare.wordpress.com/2009/06/25/3d-perlin-noise-sphere-vertex-shader-sourcecode/
		*/

		const float permTexUnit = 1.0/256.0;        // Perm texture texel-size
		const float permTexUnitHalf = 0.5/256.0;    // Half perm texture texel-size

		float width = openfl_TextureSize.x;
		float height = openfl_TextureSize.y;

		const float grainamount = 0.05; //grain amount
		bool colored = false; //colored noise?

		uniform float uTime;
		uniform float coloramount;
		uniform float grainsize; //grain particle size (1.5 - 2.5)
		uniform float lumamount;
		uniform bool lockAlpha;

		//a random texture generator, but you can also use a pre-computed perturbation texture
	
		vec4 rnm(in vec2 tc)
		{
			float noise =  sin(dot(tc + vec2(uTime,uTime),vec2(12.9898,78.233))) * 43758.5453;

			float noiseR =  fract(noise)*2.0-1.0;
			float noiseG =  fract(noise*1.2154)*2.0-1.0;
			float noiseB =  fract(noise * 1.3453) * 2.0 - 1.0;
			
				
			float noiseA =  (fract(noise * 1.3647) * 2.0 - 1.0);

			return vec4(noiseR,noiseG,noiseB,noiseA);
		}

		float fade(in float t) {
			return t*t*t*(t*(t*6.0-15.0)+10.0);
		}

		float pnoise3D(in vec3 p)
		{
			vec3 pi = permTexUnit*floor(p)+permTexUnitHalf; // Integer part, scaled so +1 moves permTexUnit texel
			// and offset 1/2 texel to sample texel centers
			vec3 pf = fract(p);     // Fractional part for interpolation

			// Noise contributions from (x=0, y=0), z=0 and z=1
			float perm00 = rnm(pi.xy).a ;
			vec3  grad000 = rnm(vec2(perm00, pi.z)).rgb * 4.0 - 1.0;
			float n000 = dot(grad000, pf);
			vec3  grad001 = rnm(vec2(perm00, pi.z + permTexUnit)).rgb * 4.0 - 1.0;
			float n001 = dot(grad001, pf - vec3(0.0, 0.0, 1.0));

			// Noise contributions from (x=0, y=1), z=0 and z=1
			float perm01 = rnm(pi.xy + vec2(0.0, permTexUnit)).a ;
			vec3  grad010 = rnm(vec2(perm01, pi.z)).rgb * 4.0 - 1.0;
			float n010 = dot(grad010, pf - vec3(0.0, 1.0, 0.0));
			vec3  grad011 = rnm(vec2(perm01, pi.z + permTexUnit)).rgb * 4.0 - 1.0;
			float n011 = dot(grad011, pf - vec3(0.0, 1.0, 1.0));

			// Noise contributions from (x=1, y=0), z=0 and z=1
			float perm10 = rnm(pi.xy + vec2(permTexUnit, 0.0)).a ;
			vec3  grad100 = rnm(vec2(perm10, pi.z)).rgb * 4.0 - 1.0;
			float n100 = dot(grad100, pf - vec3(1.0, 0.0, 0.0));
			vec3  grad101 = rnm(vec2(perm10, pi.z + permTexUnit)).rgb * 4.0 - 1.0;
			float n101 = dot(grad101, pf - vec3(1.0, 0.0, 1.0));

			// Noise contributions from (x=1, y=1), z=0 and z=1
			float perm11 = rnm(pi.xy + vec2(permTexUnit, permTexUnit)).a ;
			vec3  grad110 = rnm(vec2(perm11, pi.z)).rgb * 4.0 - 1.0;
			float n110 = dot(grad110, pf - vec3(1.0, 1.0, 0.0));
			vec3  grad111 = rnm(vec2(perm11, pi.z + permTexUnit)).rgb * 4.0 - 1.0;
			float n111 = dot(grad111, pf - vec3(1.0, 1.0, 1.0));

			// Blend contributions along x
			vec4 n_x = mix(vec4(n000, n001, n010, n011), vec4(n100, n101, n110, n111), fade(pf.x));

			// Blend contributions along y
			vec2 n_xy = mix(n_x.xy, n_x.zw, fade(pf.y));

			// Blend contributions along z
			float n_xyz = mix(n_xy.x, n_xy.y, fade(pf.z));

			// We are done, return the final noise value.
			return n_xyz;
		}

		//2d coordinate orientation thing
		vec2 coordRot(in vec2 tc, in float angle)
		{
			float aspect = width/height;
			float rotX = ((tc.x*2.0-1.0)*aspect*cos(angle)) - ((tc.y*2.0-1.0)*sin(angle));
			float rotY = ((tc.y*2.0-1.0)*cos(angle)) + ((tc.x*2.0-1.0)*aspect*sin(angle));
			rotX = ((rotX/aspect)*0.5+0.5);
			rotY = rotY*0.5+0.5;
			return vec2(rotX,rotY);
		}

		void main()
		{
			vec2 texCoord = openfl_TextureCoordv.st;

			vec3 rotOffset = vec3(1.425,3.892,5.835); //rotation offset values
			vec2 rotCoordsR = coordRot(texCoord, uTime + rotOffset.x);
			vec3 noise = vec3(pnoise3D(vec3(rotCoordsR*vec2(width/grainsize,height/grainsize),0.0)));

			if (colored)
			{
				vec2 rotCoordsG = coordRot(texCoord, uTime + rotOffset.y);
				vec2 rotCoordsB = coordRot(texCoord, uTime + rotOffset.z);
				noise.g = mix(noise.r,pnoise3D(vec3(rotCoordsG*vec2(width/grainsize,height/grainsize),1.0)),coloramount);
				noise.b = mix(noise.r,pnoise3D(vec3(rotCoordsB*vec2(width/grainsize,height/grainsize),2.0)),coloramount);
			}

			vec3 col = texture2D(bitmap, openfl_TextureCoordv).rgb;

			//noisiness response curve based on scene luminance
			vec3 lumcoeff = vec3(0.299,0.587,0.114);
			float luminance = mix(0.0,dot(col, lumcoeff),lumamount);
			float lum = smoothstep(0.2,0.0,luminance);
			lum += luminance;


			noise = mix(noise,vec3(0.0),pow(lum,4.0));
			col = col+noise*grainamount;

			vec4 texColor = texture2D(bitmap, openfl_TextureCoordv);

			float bitch = 1.0;
			if (lockAlpha) bitch = texColor.a;

			gl_FragColor = vec4(col,bitch);
		}
	')
	public function new(grainsize:Float = 0, lumamount:Float = 0, lockAlpha:Bool = false)
	{
		super();
		
		this.grainScale = grainsize;
		this.luminance = lumamount;
		this.alphaLock = lockAlpha;
		
		uTime.value = [0];
	}
}

class VCRDistortionShader extends FlxShader // https://www.shadertoy.com/view/ldjGzV and https://www.shadertoy.com/view/Ms23DR and https://www.shadertoy.com/view/MsXGD4 and https://www.shadertoy.com/view/Xtccz4
{
	public var showVignette(default, set):Bool = false;
	public var perspective(default, set):Bool = false;
	public var showDistortion(default, set):Bool = false;
	public var showScanlines(default, set):Bool = false;
	public var vignetteMoves(default, set):Bool = false;
	public var glitch(default, set):Float = 0;
	
	function set_showVignette(value:Bool):Bool
	{
		return (vignetteOn.value[0] = showVignette = value);
	}
	
	function set_glitch(value:Float):Float
	{
		return (glitchModifier.value[0] = glitch = value);
	}
	
	function set_vignetteMoves(value:Bool):Bool
	{
		return (vignetteMoving.value[0] = vignetteMoves = value);
	}
	
	function set_showScanlines(value:Bool):Bool
	{
		return (scanlinesOn.value[0] = showScanlines = value);
	}
	
	function set_showDistortion(value:Bool):Bool
	{
		return (distortionOn.value[0] = showDistortion = value);
	}
	
	function set_perspective(value:Bool):Bool
	{
		return (perspectiveOn.value[0] = perspective = value);
	}
	
	public function update(elapsed:Float)
	{
		iTime.value[0] += elapsed;
	}
	
	@:glFragmentSource('
		#pragma header

		uniform float iTime;
		uniform bool vignetteOn;
		uniform bool perspectiveOn;
		uniform bool distortionOn;
		uniform bool scanlinesOn;
		uniform bool vignetteMoving;
		uniform float glitchModifier;

		float onOff(float a, float b, float c)
		{
			return step(c, sin(iTime + a*cos(iTime*b)));
		}

		float ramp(float y, float start, float end)
		{
			float inside = step(start,y) - step(end,y);
			float fact = (y-start)/(end-start)*inside;
			return (1.0 - fact) * inside;

		}

		vec4 getVideo(vec2 uv)
		{
			vec2 look = uv;
			if(distortionOn)
			{
				float window = 1./(1.+20.*(look.y-mod(iTime/4.,1.))*(look.y-mod(iTime/4.,1.)));
				look.x = look.x + (sin(look.y*10. + iTime)/50.*onOff(4.,4.,.3)*(1.+cos(iTime*80.))*window)*(glitchModifier*2);
				float vShift = 0.4*onOff(2.,3.,.9)*(sin(iTime)*sin(iTime*20.) +
													(0.5 + 0.1*sin(iTime*200.)*cos(iTime)));
				look.y = mod(look.y + vShift*glitchModifier, 1.);
			}
			vec4 video = flixel_texture2D(bitmap,look);

			return video;
		}

		vec2 screenDistort(vec2 uv)
		{
			if(perspectiveOn)
			{
				uv = (uv - 0.5) * 2.0;
				uv *= 1.1;
				uv.x *= 1.0 + pow((abs(uv.y) / 5.0), 2.0);
				uv.y *= 1.0 + pow((abs(uv.x) / 4.0), 2.0);
				uv  = (uv / 2.0) + 0.5;
				uv =  uv *0.92 + 0.04;
				return uv;
			}

			return uv;
		}

		float random(vec2 uv)
		{
			return fract(sin(dot(uv, vec2(15.5151, 42.2561))) * 12341.14122 * sin(iTime * 0.03));
		}

		float noise(vec2 uv)
		{
			vec2 i = floor(uv);
			vec2 f = fract(uv);

			float a = random(i);
			float b = random(i + vec2(1.0,0.0));
			float c = random(i + vec2(0.0, 1.0));
			float d = random(i + vec2(1.0));

			vec2 u = smoothstep(0.0, 1.0, f);

			return mix(a,b, u.x) + (c - a) * u.y * (1. - u.x) + (d - b) * u.x * u.y;

		}

		vec2 scandistort(vec2 uv) 
		{
			float scan1 = clamp(cos(uv.y * 2.0 + iTime), 0.0, 1.0);
			float scan2 = clamp(cos(uv.y * 2.0 + iTime + 4.0) * 10.0, 0.0, 1.0);
			float amount = scan1 * scan2 * uv.x;

			//uv.x -= 0.05 * mix(flixel_texture2D(noiseTex, vec2(uv.x, amount)).r * amount, amount, 0.9);

			return uv;
		}

		void main()
		{
			vec2 uv = openfl_TextureCoordv;
			vec2 curUV = screenDistort(uv);
			uv = scandistort(curUV);
			vec4 video = getVideo(uv);
			float vigAmt = 1.0;
			float x =  0.0;


			video.r = getVideo(vec2(x+uv.x+0.001,uv.y+0.001)).x+0.05;
			video.g = getVideo(vec2(x+uv.x+0.000,uv.y-0.002)).y+0.05;
			video.b = getVideo(vec2(x+uv.x-0.002,uv.y+0.000)).z+0.05;
			video.r += 0.08*getVideo(0.75*vec2(x+0.025, -0.027)+vec2(uv.x+0.001,uv.y+0.001)).x;
			video.g += 0.05*getVideo(0.75*vec2(x+-0.022, -0.02)+vec2(uv.x+0.000,uv.y-0.002)).y;
			video.b += 0.08*getVideo(0.75*vec2(x+-0.02, -0.018)+vec2(uv.x-0.002,uv.y+0.000)).z;

			video = clamp(video*0.6+0.4*video*video*1.0,0.0,1.0);
			if(vignetteMoving)
				vigAmt = 3.0 + 0.3 * sin(iTime + 5.0 * cos(iTime*5.0));

			float vignette = (1.0 - vigAmt * (uv.y-0.5)*(uv.y-0.5)) * (1.0 - vigAmt * (uv.x - 0.5) * (uv.x - 0.5));

			if(vignetteOn)
				video *= vignette;


			gl_FragColor = mix(video, vec4(noise(uv * 75.0)), 0.05);

			if(curUV.x < 0.0 || curUV.x > 1.0 || curUV.y < 0.0 || curUV.y > 1.0)
			{
				gl_FragColor = vec4(0.0);
			}

		}

  	')
	public function new()
	{
		super();
		iTime.value = [0];
	}
}

// coding is like hitting on women, you never start with the number
//               -naether
class ThreeDShader extends FlxShader
{
	public var rotationX(default, set):Float = 0;
	
	public var rotationY(default, set):Float = 0;
	
	public var rotationZ(default, set):Float = 0;
	
	public var depth(default, set):Float = 0;
	
	function set_rotationX(value:Float):Float
	{
		return (xrot.value[0] = rotationX = value);
	}
	
	function set_rotationY(value:Float):Float
	{
		return (yrot.value[0] = rotationY = value);
	}
	
	function set_rotationZ(value:Float):Float
	{
		return (zrot.value[0] = rotationZ = value);
	}
	
	function set_depth(value:Float):Float
	{
		return (dept.value[0] = depth = value);
	}
	
	@:glFragmentSource('
		#pragma header

		uniform float xrot;
		uniform float yrot;
		uniform float zrot;
		uniform float dept;

		float alph = 0.0;

		float plane( in vec3 norm, in vec3 po, in vec3 ro, in vec3 rd ) 
		{
			float de = dot(norm, rd);
			de = sign(de)*max( abs(de), 0.001);
			return dot(norm, po-ro)/de;
		}

		vec2 raytraceTexturedQuad(in vec3 rayOrigin, in vec3 rayDirection, in vec3 quadCenter, in vec3 quadRotation, in vec2 quadDimensions) {
			//Rotations ------------------
			float a = sin(quadRotation.x); float b = cos(quadRotation.x); 
			float c = sin(quadRotation.y); float d = cos(quadRotation.y); 
			float e = sin(quadRotation.z); float f = cos(quadRotation.z); 
			float ac = a*c;   float bc = b*c;
			
			mat3 RotationMatrix  = 
					mat3(	  d*f,      d*e,  -c,
						ac*f-b*e, ac*e+b*f, a*d,
						bc*f+a*e, bc*e-a*f, b*d );
			//--------------------------------------
			
			vec3 right = RotationMatrix * vec3(quadDimensions.x, 0.0, 0.0);
			vec3 up = RotationMatrix * vec3(0.0, quadDimensions.y, 0.0);
			vec3 normal = cross(right, up);
			normal /= length(normal);
			
			//Find the plane hit point in space
			vec3 pos = (rayDirection * plane(normal, quadCenter, rayOrigin, rayDirection)) - quadCenter;
			
			//Find the texture UV by projecting the hit point along the plane dirs
			return vec2(dot(pos, right) / dot(right, right),
						dot(pos, up)    / dot(up,    up)) + 0.5;
		}

		void main() 
		{
			vec4 texColor = texture2D(bitmap, openfl_TextureCoordv);
			//Screen UV goes from 0 - 1 along each axis
			vec2 screenUV = openfl_TextureCoordv;
			vec2 p = (2.0 * screenUV) - 1.0;
			float screenAspect = 1280.0/720.0;
			p.x *= screenAspect;
			
			//Normalized Ray Dir
			vec3 dir = vec3(p.x, p.y, 1.0);
			dir /= length(dir);
			
			//Define the plane
			vec3 planePosition = vec3(0.0, 0.0, dept);
			vec3 planeRotation = vec3(xrot, yrot, zrot);//this the shit you needa change
			vec2 planeDimension = vec2(-screenAspect, 1.0);
			
			vec2 uv = raytraceTexturedQuad(vec3(0.0), dir, planePosition, planeRotation, planeDimension);
			
			//If we hit the rectangle, sample the texture
			if (abs(uv.x - 0.5) < 0.5 && abs(uv.y - 0.5) < 0.5) {
				
				vec3 tex = flixel_texture2D(bitmap, uv).xyz;
				float bitch = 1.0;
				if (tex.z == 0.0){
					bitch = 0.0;
				}
				
				gl_FragColor = vec4(flixel_texture2D(bitmap, uv).xyz, bitch);
			}
		}


	')
	public function new(xrotation:Float = 0, yrotation:Float = 0, zrotation:Float = 0, depth:Float = 0)
	{
		super();
		
		this.rotationX = xrotation;
		this.rotationY = yrotation;
		this.rotationZ = zrotation;
		this.depth = depth;
	}
}

// Boing! by ThaeHan
class TriangleShader extends FlxShader
{
	public var rotationX(default, set):Float = 0;
	
	public var rotationY(default, set):Float = 0;
	
	function set_rotationX(value:Float):Float
	{
		return (u_rotX.value[0] = rotationX = value);
	}
	
	function set_rotationY(value:Float):Float
	{
		return (u_rotY.value[0] = rotationY = value);
	}
	
	@:glFragmentSource('
	
		#pragma header

		uniform float u_rotX;
		uniform float u_rotY;
			
		const vec3 vertices[18] = vec3[18] (
			vec3(-0.5, 0.0, -0.5),
			vec3( 0.5, 0.0, -0.5),
			vec3(-0.5, 0.0,  0.5),
			
			vec3(-0.5, 0.0,  0.5),
			vec3( 0.5, 0.0, -0.5),
			vec3( 0.5, 0.0,  0.5),
			
			vec3(-0.5, 0.0, -0.5),
			vec3( 0.5, 0.0, -0.5),
			vec3( 0.0, 1.0,  0.0),
			
			vec3(-0.5, 0.0,  0.5),
			vec3( 0.5, 0.0,  0.5),
			vec3( 0.0, 1.0,  0.0),
			
			vec3(-0.5, 0.0, -0.5),
			vec3(-0.5, 0.0,  0.5),
			vec3( 0.0, 1.0,  0.0),
			
			vec3( 0.5, 0.0, -0.5),
			vec3( 0.5, 0.0,  0.5),
			vec3( 0.0, 1.0,  0.0)
		);

		const vec2 texCoords[18] = vec2[18] (
			vec2(0.0, 1.0),
			vec2(1.0, 1.0),
			vec2(0.0, 0.0),
			
			vec2(0.0, 0.0),
			vec2(1.0, 1.0),
			vec2(1.0, 0.0),
			
			vec2(0.0, 1.0),
			vec2(1.0, 1.0),
			vec2(0.5, 0.0),
			
			vec2(0.0, 1.0),
			vec2(1.0, 1.0),
			vec2(0.5, 0.0),
			
			vec2(0.0, 1.0),
			vec2(1.0, 1.0),
			vec2(0.5, 0.0),
			
			vec2(0.0, 1.0),
			vec2(1.0, 1.0),
			vec2(0.5, 0.0)
		);

		vec4 vertexShader(in vec3 vertex, in mat4 transform) {
			return transform * vec4(vertex, 1.0);
		}

		const float fov  = 70.0;
		const float near = 0.1;
		const float far  = 10.0;

		const vec3 cameraPos = vec3(0.0, 0.3, 2.0);

		vec4 pixel(in vec2 ndc, in float aspect, inout float depth, in int vertexIndex) 
		{

			mat4 proj  = perspective(fov, aspect, near, far);
			mat4 view  = translate(-cameraPos);
			mat4 model = rotateX(u_rotX) * rotateY(u_rotY);
			
			mat4 mvp  = proj * view * model;

			vec4 v0 = vertexShader(vertices[vertexIndex  ], mvp);
			vec4 v1 = vertexShader(vertices[vertexIndex+1], mvp);
			vec4 v2 = vertexShader(vertices[vertexIndex+2], mvp);
			
			vec2 t0 = texCoords[vertexIndex  ] / v0.w; float oow0 = 1.0 / v0.w;
			vec2 t1 = texCoords[vertexIndex+1] / v1.w; float oow1 = 1.0 / v1.w;
			vec2 t2 = texCoords[vertexIndex+2] / v2.w; float oow2 = 1.0 / v2.w;
			
			v0 /= v0.w;
			v1 /= v1.w;
			v2 /= v2.w;
			
			vec3 tri = bary(v0.xy, v1.xy, v2.xy, ndc);
			
			if(tri.x < 0.0 || tri.x > 1.0 || tri.y < 0.0 || tri.y > 1.0 || tri.z < 0.0 || tri.z > 1.0) {
				return vec4(0.0);
			}
			
			float triDepth = baryLerp(v0.z, v1.z, v2.z, tri);
			if(triDepth > depth || triDepth < -1.0 || triDepth > 1.0) {
				return vec4(0.0);
			}
			
			depth = triDepth;
			
			float oneOverW = baryLerp(oow0, oow1, oow2, tri);
			vec2 uv = uvLerp(t0, t1, t2, tri) / oneOverW;
			return flixel_texture2D(bitmap, uv);

		}


		void main()
		{
			vec2 ndc = ((gl_FragCoord.xy * 2.0) / openfl_TextureSize.xy) - vec2(1.0);
			float aspect = openfl_TextureSize.x / openfl_TextureSize.y;
			vec3 outColor = vec3(0.4,0.6,0.9);
			
			float depth = 1.0;
			for(int i = 0; i < 18; i += 3) 
			{
				vec4 tri = pixel(ndc, aspect, depth, i);
				outColor = mix(outColor.rgb, tri.rgb, tri.a);
			}
			
			gl_FragColor = vec4(outColor, 1.0);
		}
	
	')
	public function new(rotX:Float = 0, rotY:Float = 0)
	{
		super();
		
		rotationX = rotX;
		rotationY = rotY;
	}
}

class BloomShader extends FlxShader
{
	public var blurDistance(default, set):Float = 0.0;
	
	public var blurIntensity(default, set):Float = 0.0;
	
	function set_blurDistance(value:Float):Float
	{
		return (u_blur.value[0] = blurDistance = value);
	}
	
	function set_blurIntensity(value:Float):Float
	{
		return (u_intensity.value[0] = blurIntensity = value);
	}
	
	@:glFragmentSource('
	
		#pragma header
		
		uniform float u_intensity;
		uniform float u_blur;
		
		void main()
		{
			vec4 sum = vec4(0.0);
			vec2 uv = openfl_TextureCoordv;

			//thank you! http://www.gamerendering.com/2008/10/11/gaussian-blur-filter-shader/ for the 
			//blur tutorial
			// blur in y (vertical)
			// take nine samples, with the distance blurSize between them
			sum += flixel_texture2D(bitmap, vec2(uv.x - 4.0 * u_blur, uv.y)) * 0.05;
			sum += flixel_texture2D(bitmap, vec2(uv.x - 3.0 * u_blur, uv.y)) * 0.09;
			sum += flixel_texture2D(bitmap, vec2(uv.x - 2.0 * u_blur, uv.y)) * 0.12;
			sum += flixel_texture2D(bitmap, vec2(uv.x - u_blur, uv.y)) * 0.15;
			sum += flixel_texture2D(bitmap, vec2(uv.x, uv.y)) * 0.16;
			sum += flixel_texture2D(bitmap, vec2(uv.x + u_blur, uv.y)) * 0.15;
			sum += flixel_texture2D(bitmap, vec2(uv.x + 2.0 * u_blur, uv.y)) * 0.12;
			sum += flixel_texture2D(bitmap, vec2(uv.x + 3.0 * u_blur, uv.y)) * 0.09;
			sum += flixel_texture2D(bitmap, vec2(uv.x + 4.0 * u_blur, uv.y)) * 0.05;
				
			// blur in y (vertical)
			// take nine samples, with the distance blurSize between them
			sum += flixel_texture2D(bitmap, vec2(uv.x, uv.y - 4.0 * u_blur)) * 0.05;
			sum += flixel_texture2D(bitmap, vec2(uv.x, uv.y - 3.0 * u_blur)) * 0.09;
			sum += flixel_texture2D(bitmap, vec2(uv.x, uv.y - 2.0 * u_blur)) * 0.12;
			sum += flixel_texture2D(bitmap, vec2(uv.x, uv.y - u_blur)) * 0.15;
			sum += flixel_texture2D(bitmap, vec2(uv.x, uv.y)) * 0.16;
			sum += flixel_texture2D(bitmap, vec2(uv.x, uv.y + u_blur)) * 0.15;
			sum += flixel_texture2D(bitmap, vec2(uv.x, uv.y + 2.0 * u_blur)) * 0.12;
			sum += flixel_texture2D(bitmap, vec2(uv.x, uv.y + 3.0 * u_blur)) * 0.09;
			sum += flixel_texture2D(bitmap, vec2(uv.x, uv.y + 4.0 * u_blur)) * 0.05;

			//increase blur with intensity!
			gl_FragColor = sum * u_intensity + flixel_texture2D(bitmap, uv); 

		}
	
	')
	public function new(blur:Float = 0, intensity:Float = 0)
	{
		super();
		
		blurDistance = blur;
		blurIntensity = intensity;
	}
}

/*STOLE FROM DAVE AND BAMBI

	I LOVE BANUUU I LOVE BANUUU
	  ________
	 /        \
	_/__________\_
	||  o||  o||
	|//--  --//|
	 \____O___/
	  |      |
	  |______|
	  |   |  |
	  |___|__|
		

 */
class GlitchShader extends FlxShader
{
	public var waveSpeed(default, set):Float = 0;
	public var waveFrequency(default, set):Float = 0;
	public var waveAmplitude(default, set):Float = 0;
	
	public function update(elapsed:Float):Void
	{
		uTime.value[0] += elapsed;
	}
	
	function set_waveSpeed(value:Float):Float
	{
		return (uSpeed.value[0] = waveSpeed = value);
	}
	
	function set_waveFrequency(value:Float):Float
	{
		return (uFrequency.value[0] = waveFrequency = value);
	}
	
	function set_waveAmplitude(value:Float):Float
	{
		return (uWaveAmplitude.value[0] = waveAmplitude = value);
	}
	
	@:glFragmentSource('
		#pragma header
		//uniform float tx, ty; // x,y waves phase

		//modified version of the wave shader to create weird garbled corruption like messes
		uniform float uTime;
		
		/**
		 * How fast the waves move over time
		 */
		uniform float uSpeed;
		
		/**
		 * Number of waves over time
		 */
		uniform float uFrequency;
		
		/**
		 * How much the pixels are going to stretch over the waves
		 */
		uniform float uWaveAmplitude;

		vec2 sineWave(vec2 pt)
		{
			float x = 0.0;
			float y = 0.0;
			
			float offsetX = sin(pt.y * uFrequency + uTime * uSpeed) * (uWaveAmplitude / pt.x * pt.y);
			float offsetY = sin(pt.x * uFrequency - uTime * uSpeed) * (uWaveAmplitude / pt.y * pt.x);
			pt.x += offsetX; // * (pt.y - 1.0); // <- Uncomment to stop bottom part of the screen from moving
			pt.y += offsetY;

			return vec2(pt.x + x, pt.y + y);
		}

		void main()
		{
			vec2 uv = sineWave(openfl_TextureCoordv);
			gl_FragColor = texture2D(bitmap, uv);
		}
		
	')
	public function new(waveSpeed:Float = 0, waveFrequency:Float = 0, waveAmplitude:Float = 0):Void
	{
		super();
		
		this.waveSpeed = waveSpeed;
		this.waveFrequency = waveFrequency;
		this.waveAmplitude = waveAmplitude;
		
		uTime.value = [0];
	}
}

class InvertShader extends FlxShader
{
	@:glFragmentSource('
		#pragma header
		
		vec4 sineWave(vec4 pt)
		{
			return vec4(1.0 - pt.x, 1.0 - pt.y, 1.0 - pt.z, pt.w);
		}

		void main()
		{
			vec2 uv = openfl_TextureCoordv;
			gl_FragColor = sineWave(texture2D(bitmap, uv));
			gl_FragColor.a = 1.0 - gl_FragColor.a;
		}
		
	')
	public function new()
	{
		super();
	}
}

class PulseShader extends FlxShader
{
	public var waveSpeed(default, set):Float = 0;
	public var waveFrequency(default, set):Float = 0;
	public var waveAmplitude(default, set):Float = 0;
	public var enabled(default, set):Bool = false;
	
	public function update(elapsed:Float):Void
	{
		uTime.value[0] += elapsed;
	}
	
	function set_waveSpeed(value:Float):Float
	{
		return (uSpeed.value[0] = waveSpeed = value);
	}
	
	function set_enabled(value:Bool):Bool
	{
		return (uEnabled.value[0] = enabled = value);
	}
	
	function set_waveFrequency(value:Float):Float
	{
		return (uFrequency.value[0] = waveFrequency = value);
	}
	
	function set_waveAmplitude(value:Float):Float
	{
		return (uWaveAmplitude.value[0] = waveAmplitude = value);
	}
	
	@:glFragmentSource('
		#pragma header
		uniform float uampmul;

		//modified version of the wave shader to create weird garbled corruption like messes
		uniform float uTime;
		
		/**
		 * How fast the waves move over time
		 */
		uniform float uSpeed;
		
		/**
		 * Number of waves over time
		 */
		uniform float uFrequency;

		uniform bool uEnabled;
		
		/**
		 * How much the pixels are going to stretch over the waves
		 */
		uniform float uWaveAmplitude;

		vec4 sineWave(vec4 pt, vec2 pos)
		{
			if (uampmul > 0.0)
			{
				float offsetX = sin(pt.y * uFrequency + uTime * uSpeed);
				float offsetY = sin(pt.x * (uFrequency * 2.0) - (uTime / 2.0) * uSpeed);
				float offsetZ = sin(pt.z * (uFrequency / 2.0) + (uTime / 3.0) * uSpeed);
				pt.x = mix(pt.x,sin(pt.x / 2.0 * pt.y + (5.0 * offsetX) * pt.z),uWaveAmplitude * uampmul);
				pt.y = mix(pt.y,sin(pt.y / 3.0 * pt.z + (2.0 * offsetZ) - pt.x),uWaveAmplitude * uampmul);
				pt.z = mix(pt.z,sin(pt.z / 6.0 * (pt.x * offsetY) - (50.0 * offsetZ) * (pt.z * offsetX)),uWaveAmplitude * uampmul);
			}

			return vec4(pt.x, pt.y, pt.z, pt.w);
		}

		void main()
		{
			vec2 uv = openfl_TextureCoordv;
			gl_FragColor = sineWave(texture2D(bitmap, uv),uv);
		}
		
	')
	public function new(waveSpeed:Float = 0, waveFrequency:Float = 0, waveAmplitude:Float = 0)
	{
		super();
		
		this.waveSpeed = waveSpeed;
		this.waveFrequency = waveFrequency;
		this.waveAmplitude = waveAmplitude;
		
		this.enabled = false;
		
		uTime.value = [0];
		uampmul.value = [0];
	}
}
