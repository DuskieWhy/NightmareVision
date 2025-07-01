package funkin.objects;

@:nullSafety
class TextTracker extends flixel.text.FlxText
{
	public var sprTracker:Null<FlxSprite> = null;
	
	public var centerX:Bool = false;
	public var centerY:Bool = false;
	public var offset_x:Float = 0;
	public var offset_y:Float = 0;
	
	public function new(text:String, xOffset:Float = 0, yOffset:Float = 0, size:Int = 32, textWidth:Float = 0, alignment:FlxTextAlign = LEFT, ?font:String = 'candy.otf')
	{
		super(0, 0, textWidth, text, size);
		offset_x = xOffset;
		offset_y = yOffset;
		antialiasing = false;
		setFormat(Paths.font(font), size, FlxColor.BLACK, alignment);
	}
	
	override function update(elapsed:Float)
	{
		if (sprTracker != null)
		{
			setPosition(sprTracker.x + offset_x, sprTracker.y + offset_y);
			if (centerX)
			{
				x = sprTracker.x + (sprTracker.width / 2) - (width / 2);
			}
			if (centerY)
			{
				y = sprTracker.y + (sprTracker.height / 2) - (height / 2);
			}
		}
		
		super.update(elapsed);
	}
}
