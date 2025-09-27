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
// camera rotation functionality borrowed from cne https://github.com/CodenameCrew/cne-flixel/blob/dev/flixel/FlxCamera.hx
// big thanks to them
class FlxCameraEx extends FlxCamera
{
	/**
	 * Whenever the sprite should be rotated.
	 */
	public var rotateSprite(default, set):Bool = false;
	
	@:noCompletion
	var _sinAngle:Float = 0;
	
	@:noCompletion
	var _cosAngle:Float = 1;
	
	function set_rotateSprite(rotate:Bool)
	{
		rotateSprite = rotate;
		set_angle(angle);
		return rotateSprite;
	}
	
	override function set_angle(Angle:Float)
	{
		angle = Angle;
		flashSprite.rotation = rotateSprite ? Angle : 0;
		
		var radians:Float = angle * FlxAngle.TO_RAD;
		_sinAngle = Math.sin(radians);
		_cosAngle = Math.cos(radians);
		
		return angle;
	}
	
	override function drawPixels(?frame:FlxFrame, ?pixels:BitmapData, matrix:FlxMatrix, ?transform:ColorTransform, ?blend:BlendMode, ?smoothing:Bool = false, ?shader:FlxShader):Void
	{
		if (FlxG.renderBlit)
		{
			_helperMatrix.copyFrom(matrix);
			
			if (_useBlitMatrix)
			{
				_helperMatrix.concat(_blitMatrix);
				buffer.draw(pixels, _helperMatrix, null, null, null, (smoothing || antialiasing));
			}
			else
			{
				_helperMatrix.translate(-viewMarginLeft, -viewMarginTop);
				buffer.draw(pixels, _helperMatrix, null, blend, null, (smoothing || antialiasing));
			}
		}
		else
		{
			var isColored = (transform != null && transform.hasRGBMultipliers());
			var hasColorOffsets:Bool = (transform != null && transform.hasRGBAOffsets());
			
			if (!rotateSprite && angle != 0)
			{
				matrix.translate(-width / 2, -height / 2);
				matrix.rotateWithTrig(_cosAngle, _sinAngle);
				matrix.translate(width / 2, height / 2);
			}
			
			#if FLX_RENDER_TRIANGLE
			var drawItem:FlxDrawTrianglesItem = startTrianglesBatch(frame.parent, smoothing, isColored, blend);
			#else
			var drawItem = startQuadBatch(frame.parent, isColored, hasColorOffsets, blend, smoothing, shader);
			#end
			drawItem.addQuad(frame, matrix, transform);
		}
	}
	
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
