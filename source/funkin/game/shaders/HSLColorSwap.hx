package funkin.game.shaders;

import flixel.FlxG;
import flixel.system.FlxAssets.FlxShader;

class HSLColorSwap
{
	public var shader:HSLColorSwapShader = new HSLColorSwapShader();
	public var hue(default, set):Float = 0;
	public var saturation(default, set):Float = 0;
	public var lightness(default, set):Float = 0;
	
	private function set_hue(value:Float)
	{
		if (value == hue) return hue;
		
		shader.hue.value[0] = value;
		return (hue = value);
	}
	
	private function set_saturation(value:Float)
	{
		if (value == saturation) return saturation;
		
		shader.saturation.value[0] = value;
		return (saturation = value);
	}
	
	private function set_lightness(value:Float)
	{
		if (value == lightness) return lightness;
		
		shader.lightness.value[0] = value;
		return (lightness = value);
	}
	
	public function new()
	{
		// all values are set in the shader so like
		// idk what to do here!!!
		// -neb
	}
}

class HSLColorSwapShader extends FlxShader
{
	@:glFragmentSource('
  #pragma header
  
  uniform float hue;
  uniform float saturation;
  uniform float lightness;

  vec3 rgb2hsl(vec3 color){
      vec3 hsl = vec3(0.);
      float maxColor = max(max(color.r, color.g), color.b);
      float minColor = min(min(color.r, color.g), color.b);
      float sum = maxColor + minColor;
      float range = maxColor - minColor;
      hsl.z = sum/2.;
      if(minColor==maxColor){
          hsl.x = 0.;
          hsl.y = 0.;
          return hsl;
      }
      if(hsl.z <= 0.5){
          hsl.y = range / sum;
      }else{
          hsl.y = range / (2.-sum);
      }

      float deltaR = (maxColor - color.r) / range;
      float deltaG = (maxColor - color.g) / range;
      float deltaB = (maxColor - color.b) / range;


      if(color.r == maxColor){
          hsl.x = deltaB - deltaG;
      }else if(color.g==maxColor){
          hsl.x = 2.0+deltaR-deltaB;
      }else{
          hsl.x = 4.0+deltaG-deltaR;
      }

      hsl.x = mod((hsl.x / 6.0), 1.0);

      return hsl;
  }

  float hue2clr(float m1, float m2, float hue){
      hue = mod(hue,1.0);

      if(hue < 1./6.){
          return m1 + (m2 - m1)*hue*6.0;
      }
      if(hue < 0.5){
          return m2;
      }
      if(hue < 2./3.){
          return m1 + (m2-m1)*((2./3.)-hue)*6.0;
      }
      return m1;
  }

  vec3 hsl2rgb(vec3 hsl){
      vec3 color = vec3(0.);
      float m2 = 0.;
      float m1 = 0.;

      float h = hsl.x;
      float s = hsl.y;
      float l = hsl.z;

      if(s == 0.){
          return vec3(l, l, l);
      }
      if(l<=0.5){
          m2 = l * (1.+s);
      }else{
          m2 = l + s - (l*s);
      }

      m1 = 2.0 * l - m2;
      color.r = hue2clr(m1, m2, h + (1.0/3.0));
      color.g = hue2clr(m1, m2, h);
      color.b = hue2clr(m1, m2, h - (1.0/3.0));
      return color;
  }


  void main()
  {
      // Normalized pixel coordinates (from 0 to 1)
      vec2 uv = openfl_TextureCoordv;
      vec4 oColor = flixel_texture2D(bitmap , uv);
      vec3 hsl = rgb2hsl(oColor.rgb);
      hsl.x = mod(hsl.x + hue, 1.0);
      hsl.y = clamp(hsl.y + saturation, 0.0, 1.0);
      hsl.z = clamp(hsl.z * (1.0 + lightness), 0.0, 1.0);
      vec4 color = vec4(hsl2rgb(hsl),oColor.a);
      // Output to screen
      gl_FragColor = color;
  }
  ')
	public function new()
	{
		super();
		hue.value = [0];
		saturation.value = [0];
		lightness.value = [0];
	}
}
