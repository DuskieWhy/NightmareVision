package funkin.objects;

import flixel.util.FlxAxes;

@:nullSafety
class TextTracker extends FlxText
{
	public var sprTracker:Null<FlxSprite> = null;
	
	public var centerAlign:FlxAxes = NONE;
	
	public var xOffset:Float = 0;
	public var yOffset:Float = 0;
	
	public function new(text:String, xOffset:Float = 0, yOffset:Float = 0, size:Int = 32, fieldWidth:Float = 0, alignment:FlxTextAlign = LEFT, font:String = 'vcr.ttf')
	{
		super(0, 0, fieldWidth, text, size);
		this.xOffset = xOffset;
		this.yOffset = yOffset;
		antialiasing = false;
		setFormat(Paths.font(font), size, FlxColor.BLACK, alignment);
	}
	
	override function update(elapsed:Float)
	{
		if (sprTracker != null)
		{
			setPosition(sprTracker.x + xOffset, sprTracker.y + yOffset);
			
			if (centerAlign.x)
			{
				x = sprTracker.x + (sprTracker.width / 2) - (width / 2);
			}
			
			if (centerAlign.y)
			{
				y = sprTracker.y + (sprTracker.height / 2) - (height / 2);
			}
		}
		
		super.update(elapsed);
	}
}
