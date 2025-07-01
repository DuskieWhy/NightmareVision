package funkin.objects.character;

import flxanimate.FlxAnimateController;
import flxanimate.AnimateSprite;

class AnimateCharacter extends Character
{
	public var animate:AnimateSprite;
	
	public function new(x:Float = 0, y:Float = 0, character:String, isPlayer:Bool = false)
	{
		animate = new AnimateSprite(x, y);
		animate.showPivot = false;
		
		super(x, y, character, isPlayer);
	}
	
	override function playGhostAnim(ghostID:Int = 0, AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0) {}
	
	override public function loadGraphicFromType(path:String, type:String)
	{
		animation = new FlxAnimateController(animate);
		animate.loadAtlas(Paths.textureAtlas(path));
	}
	
	override function update(elapsed:Float)
	{
		animate.update(elapsed);
		super.update(elapsed);
	}
	
	override function draw()
	{
		animate.x = x;
		animate.y = y;
		animate.shader = shader;
		animate.alpha = alpha;
		animate.visible = visible;
		animate.angle = angle;
		animate.scrollFactor = scrollFactor;
		animate.antialiasing = antialiasing;
		animate.colorTransform = colorTransform;
		animate.color = color;
		animate.flipX = flipX;
		animate.flipY = flipY;
		animate.offset = offset;
		animate.cameras = cameras;
		animate.scale = scale;
		
		animate.draw();
	}
	
	override function destroy()
	{
		super.destroy();
		
		animate.destroy();
	}
	
	// sigh cant do everything within the controller due to curAnim so this is the way we get those vals //i might try some really weird shit sometime to do it ? maybe i think at that point im just overcomplicating it so prolly not
	
	override function getAnimName():String
	{
		@:privateAccess
		return (cast animation : FlxAnimateController)._prevPlayedAnim;
	}
	
	override function isAnimNull():Bool
	{
		return (animate.anim.curSymbol == null);
	}
	
	override function isAnimFinished():Bool
	{
		return isAnimNull() ? false : animate.anim.finished;
	}
	
	override function pauseAnim():Void
	{
		animate.anim.pause();
	}
	
	override function resumeAnim():Void
	{
		animate.anim.resume();
	}
	
	override function getAnimByName(name:String):Dynamic
	{
		return animate.anim.getByName(name);
	}
	
	override function get_animCurFrame():Int
	{
		return isAnimNull() ? 0 : animate.anim.curFrame;
	}
	
	override function set_animCurFrame(value:Int):Int
	{
		return isAnimNull() ? 0 : (animate.anim.curFrame = value);
	}
	override function getAnimNumFrames():Int return isAnimNull() ? 0 : animate.anim.length;

}
