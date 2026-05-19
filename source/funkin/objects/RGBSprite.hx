package funkin.objects;

import funkin.game.shaders.RGBShader.RGBGraphics;

/**
 * Simple sprite object to have a custom batched object
 */
class RGBSprite extends FunkinSprite
{
	public var rgbGraphics:RGBGraphics = new RGBGraphics();
	
	override function drawSimple(camera:FlxCamera)
	{
		super.drawSimple(camera);
		rgbGraphics?.pushQuad(camera);
	}
	
	override function drawComplex(camera:FlxCamera)
	{
		super.drawComplex(camera);
		rgbGraphics?.pushQuad(camera);
	}
}
