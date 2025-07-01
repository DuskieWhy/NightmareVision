package funkin.game.shaders;

import flixel.system.FlxAssets.FlxShader;

class ColorSwap
{
	public var shader(default, null):ColorSwapShader = new ColorSwapShader();
	public var hue(default, set):Float = 0;
	public var saturation(default, set):Float = 0;
	public var brightness(default, set):Float = 0;
	public var daAlpha(default, set):Float = 1;
	public var flash(default, set):Float = 0;
	
	private function set_daAlpha(value:Float)
	{
		if (value == daAlpha) return daAlpha;
		daAlpha = value;
		shader.u_alpha.value[0] = daAlpha;
		return daAlpha;
	}
	
	private function set_flash(value:Float)
	{
		if (value == flash) return flash;
		
		flash = value;
		shader.u_flash.value[0] = flash;
		return flash;
	}
	
	private function set_hue(value:Float)
	{
		if (value == hue) return hue;
		
		hue = value;
		shader.u_hue.value[0] = hue;
		return hue;
	}
	
	private function set_saturation(value:Float)
	{
		if (value == saturation) return saturation;
		
		saturation = value;
		shader.u_saturation.value[0] = saturation;
		return saturation;
	}
	
	private function set_brightness(value:Float)
	{
		if (value == brightness) return brightness;
		
		brightness = value;
		shader.u_brightness.value[0] = brightness;
		return brightness;
	}
	
	public function new()
	{
		shader.u_brightness.value = [0];
		shader.u_hue.value = [0];
		shader.u_saturation.value = [0];
		shader.u_alpha.value = [1];
		shader.u_flash.value = [0];
	}
}

class ColorSwapShader extends FlxShader
{
	@:glFragmentSource('
		#pragma header
		
		uniform float u_saturation;
	 	uniform float u_hue;
	 	uniform float u_brightness;

		uniform float u_alpha;
		uniform float u_flash;

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

		void main()
		{
			vec4 color = flixel_texture2D(bitmap, openfl_TextureCoordv);

			vec4 swagColor = vec4(rgb2hsv(vec3(color.rgb)), color.a);

			swagColor.r = swagColor.r + u_hue;
			swagColor.g = swagColor.g + clamp(u_saturation,0.0,1.0);
			swagColor.b = swagColor.b * (1.0 + u_brightness);
			
			color = vec4(hsv2rgb(vec3(swagColor.rgb)), swagColor.a);

			if(u_flash != 0.0){
				color = mix(color,vec4(1.0,1.0,1.0,1.0),u_flash) * color.a;
			}

			color *= u_alpha;
			gl_FragColor = color;
		}')
	public function new()
	{
		super();
	}
}
