package extensions.flixel;

import openfl.geom.ColorTransform;
import openfl.display.BlendMode;
import openfl.display.Graphics;
import openfl.display.BitmapData;

import flixel.math.FlxMatrix;
import flixel.math.FlxAngle;
import flixel.graphics.frames.FlxFrame;
import flixel.system.FlxAssets.FlxShader;

using flixel.util.FlxColorTransformUtil;

// memory leak fix
class FlxCameraEx extends FlxCamera
{
	override function fill(Color:FlxColor, BlendAlpha:Bool = true, FxAlpha:Float = 1.0, ?graphics:Graphics)
	{
		if (FlxG.renderBlit)
		{
			if (BlendAlpha)
			{
				_fill.fillRect(_flashRect, Color);
				buffer.copyPixels(_fill, _flashRect, _flashPoint, null, null, BlendAlpha);
			}
			else
			{
				buffer.fillRect(_flashRect, Color);
			}
		}
		else
		{
			final targetGraphics:Graphics = (graphics == null) ? canvas.graphics : graphics;
			
			targetGraphics.overrideBlendMode(null);
			targetGraphics.beginFill(Color, FxAlpha);
			// i'm drawing rect with these parameters to avoid light lines at the top and left of the camera,
			// which could appear while cameras fading
			targetGraphics.drawRect(viewMarginLeft - 1, viewMarginTop - 1, viewWidth + 2, viewHeight + 2);
			targetGraphics.endFill();
		}
	}
}
