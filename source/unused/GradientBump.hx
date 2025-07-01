package funkin.objects;

import flixel.FlxSprite;

class GradientBump extends FlxSprite
{
	public var originalY:Float;
	public var originalHeight:Int = 400;
	public var intendedAlpha:Float = 1;
	
	public function new(x:Float, y:Float)
	{
		super(x, y);
		originalY = y;
		
		loadGraphic(Paths.image('gradient'));
		scrollFactor.set(0, 1);
		setGraphicSize(3000, originalHeight);
		updateHitbox();
	}
	
	override function update(elapsed:Float)
	{
		var newHeight:Int = Math.round(height - 1000 * elapsed);
		if (newHeight > 0)
		{
			alpha = intendedAlpha;
			setGraphicSize(3000, newHeight);
			updateHitbox();
			y = originalY + (originalHeight - height);
		}
		else
		{
			alpha = 0;
			y = -5000;
		}
		
		super.update(elapsed);
	}
	
	public function bop()
	{
		setGraphicSize(3000, originalHeight);
		updateHitbox();
		y = originalY;
		alpha = intendedAlpha;
	}
}
