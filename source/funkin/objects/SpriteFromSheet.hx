package funkin.objects;

// avoid using. kinda bad
class SpriteFromSheet extends FlxSprite
{
	var currentAnim:String = '';

	public function new(x:Float = 0, y:Float = 0, source:String, anim:String)
	{
		super(x, y);
		frames = Paths.getSparrowAtlas(source);
		animation.addByPrefix(anim, anim);
		animation.play(anim);
		currentAnim = anim;
		antialiasing = ClientPrefs.globalAntialiasing;
	}

	public function adjust(fps:Int = 24, loop:Bool = true, playNow:Bool = true)
	{
		animation.remove(currentAnim);
		animation.addByPrefix(currentAnim, currentAnim, fps, loop);
		if (playNow) animation.play(currentAnim, true);
	}

	public function play(forced:Bool = false, reversed:Bool = false, frame:Int = 0)
	{
		animation.play(currentAnim, reversed, frame);
	}
}
