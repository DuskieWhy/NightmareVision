package funkin.objects;

import flixel.FlxSprite;

@:nullSafety
class AttachedSprite extends FlxSprite
{
	public var sprTracker:Null<FlxSprite> = null;
	
	public var xAdd:Float = 0;
	public var yAdd:Float = 0;
	public var angleAdd:Float = 0;
	public var alphaMult:Float = 1;
	
	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;
	public var copyVisible:Bool = false;
	
	public function new(?file:String, ?anim:String, ?library:String, loop:Bool = false)
	{
		super();
		if (anim != null)
		{
			@:nullSafety(Off)
			frames = Paths.getSparrowAtlas(file, library);
			animation.addByPrefix('idle', anim, 24, loop);
			animation.play('idle');
		}
		else if (file != null)
		{
			@:nullSafety(Off)
			loadGraphic(Paths.image(file));
		}
		antialiasing = ClientPrefs.globalAntialiasing;
		scrollFactor.set();
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (sprTracker != null)
		{
			setPosition(sprTracker.x + xAdd, sprTracker.y + yAdd);
			scrollFactor.set(sprTracker.scrollFactor.x, sprTracker.scrollFactor.y);
			
			if (copyAngle) angle = sprTracker.angle + angleAdd;
			
			if (copyAlpha) alpha = sprTracker.alpha * alphaMult;
			
			if (copyVisible) visible = sprTracker.visible;
		}
	}
}
