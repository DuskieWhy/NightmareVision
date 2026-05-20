package funkin.game.shaders;

import flixel.system.FlxAssets.FlxShader;

import funkin.objects.note.Note;

// imma adjust some thigns here later

class RGBPalette
{
	public var shader(default, null):RGBPaletteShader = new RGBPaletteShader();
	public var r(default, set):FlxColor;
	public var g(default, set):FlxColor;
	public var b(default, set):FlxColor;
	
	public var alphaMult(default, set):Float;
	public var flash(default, set):Float;
	
	public var enabled(default, set):Bool;
	
	public var mult(default, set):Float;
	
	public function copyValues(tempShader:RGBPalette)
	{
		if (tempShader != null)
		{
			for (i in 0...3)
			{
				shader.r.value[i] = tempShader.shader.r.value[i];
				shader.g.value[i] = tempShader.shader.g.value[i];
				shader.b.value[i] = tempShader.shader.b.value[i];
			}
			shader.mult.value[0] = tempShader.shader.mult.value[0];
			shader.u_alpha.value[0] = tempShader.shader.u_alpha.value[0];
			shader.u_flash.value[0] = tempShader.shader.u_flash.value[0];
			shader.u_enabled.value[0] = tempShader.shader.u_enabled.value[0];
		}
		else shader.mult.value[0] = 0.0;
	}
	
	private function set_r(color:FlxColor)
	{
		r = color;
		shader.r.value = [color.redFloat, color.greenFloat, color.blueFloat];
		return color;
	}
	
	private function set_g(color:FlxColor)
	{
		g = color;
		shader.g.value = [color.redFloat, color.greenFloat, color.blueFloat];
		return color;
	}
	
	private function set_b(color:FlxColor)
	{
		b = color;
		shader.b.value = [color.redFloat, color.greenFloat, color.blueFloat];
		return color;
	}
	
	private function set_mult(value:Float)
	{
		mult = FlxMath.bound(value, 0, 1);
		shader.mult.value = [mult];
		return mult;
	}
	
	private function set_flash(value:Float):Float
	{
		flash = value;
		shader.u_flash.value = [value];
		return flash;
	}
	
	private function set_alphaMult(value:Float):Float
	{
		alphaMult = value;
		shader.u_alpha.value = [value];
		return alphaMult;
	}
	
	function set_enabled(value:Bool):Bool
	{
		enabled = value;
		shader.u_enabled.value = [value];
		return enabled;
	}
	
	public function setColors(colors:Array<FlxColor>)
	{
		while (colors.length < 3)
		{
			colors.push(FlxColor.WHITE); // use the rgb values later
		}
		r = colors[0];
		g = colors[1];
		b = colors[2];
	}
	
	public function new()
	{
		r = 0xFFFF0000;
		g = 0xFF00FF00;
		b = 0xFF0000FF;
		// setColors([0xFFFF0000, 0xFF00FF00, 0xFF0000FF]);
		mult = 1.0;
		flash = 0.0;
		alphaMult = 1.0;
		enabled = true;
	}
}

// automatic handler for easy usability
class RGBShaderReference
{
	public var r(default, set):FlxColor;
	public var g(default, set):FlxColor;
	public var b(default, set):FlxColor;

	// only for reading
	public var colorArray:Array<FlxColor> = [];
	
	public var mult(default, set):Float;
	public var alphaMult(default, set):Float;
	public var flash(default, set):Float;
	
	public var enabled(default, set):Bool = true;
	
	public var shader:FlxShader;
	
	public var parent:RGBPalette;
	
	private var _owner:FlxSprite;
	private var _original:RGBPalette;
	
	public function new(owner:FlxSprite, ref:RGBPalette)
	{
		parent = ref;
		_owner = owner;
		_original = ref;
		shader = ref.shader;
		
		@:bypassAccessor
		{
			r = parent.r;
			g = parent.g;
			b = parent.b;
			mult = parent.mult;
			alphaMult = parent.alphaMult;
			flash = parent.flash;
			enabled = parent.enabled;
		}
	}
	
	private function set_r(value:FlxColor)
	{
		if (allowNew && value != _original.r) cloneOriginal();
		return (r = parent.r = value);
	}
	
	private function set_g(value:FlxColor)
	{
		if (allowNew && value != _original.g) cloneOriginal();
		return (g = parent.g = value);
	}
	
	private function set_b(value:FlxColor)
	{
		if (allowNew && value != _original.b) cloneOriginal();
		return (b = parent.b = value);
	}
	
	private function set_mult(value:Float)
	{
		if (allowNew && value != _original.mult) cloneOriginal();
		return (mult = parent.mult = value);
	}
	
	function set_alphaMult(value:Float):Float
	{
		if (allowNew && value != _original.alphaMult) cloneOriginal();
		return (alphaMult = parent.alphaMult = value);
	}
	
	function set_flash(value:Float):Float
	{
		if (allowNew && value != _original.flash) cloneOriginal();
		return (flash = parent.flash = value);
	}
	
	private function set_enabled(value:Bool)
	{
		if (allowNew && value != _original.enabled) cloneOriginal();
		return (enabled = parent.enabled = value);
	}
	
	public function setColors(colors:Array<FlxColor>)
	{
		r = colors[0];
		g = colors[1];
		b = colors[2];

		colorArray = colors;
	}
	
	public var allowNew = true;
	
	private function cloneOriginal()
	{
		if (allowNew)
		{
			allowNew = false;
			if (_original != parent) return;
			
			parent = new RGBPalette();
			parent.r = _original.r;
			parent.g = _original.g;
			parent.b = _original.b;

			colorArray = [parent.r, parent.g, parent.b];
			// parent.setColors([_original.r, _original.g, _original.b]);
			parent.mult = _original.mult;
			
			parent.alphaMult = _original.alphaMult;
			parent.flash = _original.flash;
			parent.enabled = _original.enabled;
			
			_owner.shader = parent.shader;
		}
	}
}

class RGBPaletteShader extends FlxShader
{
	@:glFragmentHeader('
		#pragma header
		
		uniform vec3 r;
		uniform vec3 g;
		uniform vec3 b;
		uniform float mult;

		uniform float u_alpha;
		uniform float u_flash;

		uniform bool u_enabled;

		vec4 flixel_texture2DCustom(sampler2D bitmap, vec2 coord) 
		{
			vec4 color = flixel_texture2D(bitmap, coord);
			if (!u_enabled || !hasTransform || color.a == 0.0 || mult == 0.0) 
			{
				return color;
			}

			vec4 newColor = color;
			newColor.rgb = min(color.r * r + color.g * g + color.b * b, vec3(1.0));
			newColor.a = color.a;
			
			color = mix(color, newColor, mult);
			
			if(color.a > 0.0) 
			{
				return vec4(color.rgb, color.a);
			}
			return vec4(0.0, 0.0, 0.0, 0.0);
		}
            
    ')
	@:glFragmentSource('
		#pragma header

		void main() 
		{
			vec4 texOutput = flixel_texture2DCustom(bitmap, openfl_TextureCoordv);

			
			if (u_flash != 0.0)
			{
				texOutput = mix(texOutput,vec4(1.0,1.0,1.0,1.0),u_flash) * texOutput.a;
			}

			texOutput *= u_alpha;

			gl_FragColor = texOutput;
		}
			
	')
	public function new()
	{
		super();
	}
}
