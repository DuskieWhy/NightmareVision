package flxanimate;

import flxanimate.FlxAnimate.Settings;

class AnimateSprite extends FlxAnimate
{
	public function new(X:Float = 0, Y:Float = 0, ?Path:String, ?Settings:Settings)
	{
		super(X, Y, Path, Settings);
	}
	
	override function draw()
	{
		if (anim.curInstance == null || anim.curSymbol == null) return;
		super.draw();
	}
}
