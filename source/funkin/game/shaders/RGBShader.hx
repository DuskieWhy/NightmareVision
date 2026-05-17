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
	
	@:noCompletion
	static final __disabledGraphics:RGBGraphics = new RGBGraphics(FlxColor.RED, FlxColor.GREEN, FlxColor.BLUE, 0.0);
	
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
		item.graphics.rgbShader ??= new RGBShader();
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
		if (!enabled)
		{
			// simple way to push values that keep the original appearance of the sprite
			__disabledGraphics.push(drawItem, indicesLength);
			return;
		}
		for (_ in 0...indicesLength)
		{
			pushColor(drawItem.rgbR, r);
			pushColor(drawItem.rgbG, g);
			pushColor(drawItem.rgbB, b);
			
			drawItem.rgbMult.push(mult);
			
			drawItem.rgbAlpha.push(alpha);
			drawItem.rgbFlash.push(flash);
		}
	}
}

// imma adjust some thigns here later
class RGBShader extends FlxShader
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
