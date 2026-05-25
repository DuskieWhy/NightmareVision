package funkin.game.shaders;

import funkin.data.NoteSkin.ColorList;

import flixel.system.FlxAssets.FlxShader;
import flixel.graphics.tile.FlxDrawBaseItem;

import funkin.objects.note.Note;

using funkin.utils.tools.ArrayTools;

@:access(flixel.FlxCamera._currentDrawItem)
class RGBGraphics
{
	static inline var VERTICES_PER_QUAD = 4;
	
	public var enabled:Bool;
	
	public var r:FlxColor;
	public var g:FlxColor;
	public var b:FlxColor;
	
	public var mult:Float;
	public var alpha:Float;
	public var flash:Float;
	
	public function new(?r:FlxColor, ?g:FlxColor, ?b:FlxColor, mult:Float = 1.0)
	{
		enabled = true;
		reset(r, g, b, mult);
	}
	
	public function setColors(colors:Array<FlxColor>)
	{
		reset(colors[0], colors[1], colors[2], mult, alpha, flash);
	}
	
	public function getColors()
	{
		return [r, g, b];
	}
	
	public function copyFrom(graphics:RGBGraphics)
	{
		reset(graphics.r, graphics.g, graphics.b, graphics.mult, graphics.alpha, graphics.flash);
	}
	
	public function reset(?r:FlxColor, ?g:FlxColor, ?b:FlxColor, mult:Float = 1.0, alpha:Float = 1.0, flash:Float = 0.0)
	{
		this.r = r ?? FlxColor.RED;
		this.g = g ?? FlxColor.GREEN;
		this.b = b ?? FlxColor.BLUE;
		
		this.mult = mult;
		this.alpha = alpha;
		this.flash = flash;
	}
	
	public function pushQuad(camera:FlxCamera)
	{
		if (!FlxG.renderBlit) push(getDrawItem(camera), VERTICES_PER_QUAD);
	}
	
	public function pushTriangles(camera:FlxCamera, indicesLength:Int)
	{
		if (!FlxG.renderBlit) push(getDrawItem(camera), indicesLength);
	}
	
	function getDrawItem(camera:FlxCamera)
	{
		final item = camera._currentDrawItem;
		item.graphics.rgbShader ??= new BackendRGB();
		item.rgbShader = item.graphics.rgbShader;
		return item;
	}
	
	inline function pushColor(param:Array<Float>, color:FlxColor)
	{
		param.push(color.redFloat);
		param.push(color.greenFloat);
		param.push(color.blueFloat);
	}
	
	inline function push<T>(drawItem:FlxDrawBaseItem<T>, indicesLength:Int)
	{
		for (_ in 0...indicesLength)
		{
			pushColor(drawItem.rgbR, enabled ? r : 0xFFFF0000);
			pushColor(drawItem.rgbG, enabled ? g : 0xFF00FF00);
			pushColor(drawItem.rgbB, enabled ? b : 0xFF0000FF);
			
			drawItem.rgbMult.push(enabled ? mult : 0);
			
			drawItem.rgbAlpha.push(alpha);
			drawItem.rgbFlash.push(flash);
		}
	}
}

// modified version of the RGBShader that is only used by the backend
// user friendly version is down below
class BackendRGB extends FlxShader
{
	@:glVertexSource('
		#pragma header
	
		attribute vec3 r;
		attribute vec3 g;
		attribute vec3 b;
		attribute float mult;

		attribute float a_alpha;
		attribute float a_flash;
	
		out vec3 _r;
		out vec3 _g;
		out vec3 _b;
        out float _mult;

        out float _a_alpha;
        out float _a_flash;

		void main()
		{
			#pragma body
			_r = r;
			_g = g;
			_b = b;
            _mult = mult;
            _a_alpha = a_alpha;
            _a_flash = a_flash;
		}
	')
	@:glFragmentHeader('
		#pragma header

        in vec3 _r;
		in vec3 _g;
		in vec3 _b;
        in float _mult;

        in float _a_alpha;
        in float _a_flash;

		vec4 flixel_texture2DCustom(sampler2D bitmap, vec2 coord) 
		{
			vec4 color = flixel_texture2D(bitmap, coord);
			if (!hasTransform || color.a == 0.0 || _mult == 0.0) 
			{
				return color;
			}

			vec4 newColor = color;
			newColor.rgb = min(color.r * _r + color.g * _g + color.b * _b, vec3(1.0));
			newColor.a = color.a;
			
			color = mix(color, newColor, _mult);
			
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

			
			if (_a_flash != 0.0)
			{
				texOutput = mix(texOutput,vec4(1.0,1.0,1.0,1.0),_a_flash) * texOutput.a;
			}

			texOutput *= _a_alpha;

			gl_FragColor = texOutput;
		}
	')
	public function new()
	{
		super();
	}
}

// user friendly version woohoo!
// same shader, just able to be easily used in modding

class RGBShader
{
    public var shader:UserRGB;
    
    public var r(default, set):FlxColor;
    public var g(default, set):FlxColor;
    public var b(default, set):FlxColor;
    public var mult(default, set):Float;
    public var alpha(default, set):Float;
    public var flash(default, set):Float;
    public var enabled(default, set):Bool;
    
    public function new(r:FlxColor = 0xFFFF0000, g:FlxColor = 0xFF00FF00, b:FlxColor = 0xFF0000FF, mult:Float = 1.0, alpha:Float = 1.0, flash:Float = 0.0)
    {
        shader = new UserRGB();
        
        // Initialize the uniform values explicitly so OpenFL creates the arrays
        shader.data.r.value = [0.0, 0.0, 0.0];
        shader.data.g.value = [0.0, 0.0, 0.0];
        shader.data.b.value = [0.0, 0.0, 0.0];
        shader.data.mult.value = [1.0];
        shader.data.u_alpha.value = [1.0];
        shader.data.u_flash.value = [0.0];
        shader.data.u_enabled.value = [true];

        this.r = r;
        this.g = g;
        this.b = b;
        this.mult = mult;
        this.alpha = alpha;
        this.flash = flash;
        this.enabled = true;
    }
    
    public function getColors():Array<FlxColor>
    {
        return [r, g, b];
    }
    
    public function setColors(colors:Array<FlxColor>)
    {
        r = colors[0];
        g = colors[1];
        b = colors[2];
    }
    
    private function set_r(value:FlxColor):FlxColor
    {
        r = value;
        // Extract components and normalize to 0.0 - 1.0 range
        shader.data.r.value = [value.redFloat, value.greenFloat, value.blueFloat];
        return value;
    }
    
    private function set_g(value:FlxColor):FlxColor
    {
        g = value;
        shader.data.g.value = [value.redFloat, value.greenFloat, value.blueFloat];
        return value;
    }
    
    private function set_b(value:FlxColor):FlxColor
    {
        b = value;
        shader.data.b.value = [value.redFloat, value.greenFloat, value.blueFloat];
        return value;
    }
    
    private function set_mult(value:Float):Float
    {
        mult = value;
        shader.data.mult.value = [mult];
        return value;
    }
    
    private function set_alpha(value:Float):Float
    {
        alpha = value;
        shader.data.u_alpha.value = [alpha];
        return value;
    }
    
    private function set_flash(value:Float):Float
    {
        flash = value;
        shader.data.u_flash.value = [flash];
        return value;
    }

    private function set_enabled(value:Bool):Bool
    {
        enabled = value;
        shader.data.u_enabled.value = [enabled];
        return value;
    }
}

class UserRGB extends FlxShader
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
