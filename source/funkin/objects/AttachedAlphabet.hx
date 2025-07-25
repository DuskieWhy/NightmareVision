package funkin.objects;

import flixel.FlxSprite;

@:nullSafety
class AttachedAlphabet extends Alphabet
{
	public var sprTracker:Null<FlxSprite> = null;
	
	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var copyVisible:Bool = true;
	public var copyAlpha:Bool = false;
	
	public function new(text:String = "", offsetX:Float = 0, offsetY:Float = 0, bold = false, scale:Float = 1)
	{
		super(0, 0, text, bold, false, 0.05, scale);
		isMenuItem = false;
		this.offsetX = offsetX;
		this.offsetY = offsetY;
	}
	
	override function update(elapsed:Float)
	{
		if (sprTracker != null)
		{
			setPosition(sprTracker.x + offsetX, sprTracker.y + offsetY);
			if (copyVisible)
			{
				visible = sprTracker.visible;
			}
			if (copyAlpha)
			{
				alpha = sprTracker.alpha;
			}
		}
		
		super.update(elapsed);
	}
}
