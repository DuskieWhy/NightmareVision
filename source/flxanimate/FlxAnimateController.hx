package flxanimate;

import flixel.animation.FlxAnimation;
import flixel.animation.FlxAnimationController;

// attempt at maintaining parity unfinished
// might scrap sigh!
class FlxAnimateController extends FlxAnimationController
{
	var _prevPlayedAnim:String = '';
	var _atlasRef:AnimateSprite;
	
	public function new(atlas:AnimateSprite)
	{
		_atlasRef = atlas;
		
		super(atlas);
	}
	
	override function add(name:String, frames:Array<Int>, frameRate:Float = 30.0, looped:Bool = true, flipX:Bool = false, flipY:Bool = false)
	{
		throw 'Cannot be used on an atlas!';
	}
	
	override function addByPrefix(name:String, prefix:String, frameRate:Float = 30.0, looped:Bool = true, flipX:Bool = false, flipY:Bool = false)
	{
		_atlasRef.anim.addBySymbol(name, prefix, frameRate, looped);
	}
	
	override function addByIndices(Name:String, Prefix:String, Indices:Array<Int>, Postfix:String, FrameRate:Float = 30, Looped:Bool = true, FlipX:Bool = false, FlipY:Bool = false)
	{
		_atlasRef.anim.addBySymbolIndices(Name, Prefix, Indices, FrameRate, Looped);
	}
	
	override function play(animName:String, force:Bool = false, reversed:Bool = false, frame:Int = 0)
	{
		_atlasRef.anim.play(animName, force, reversed, frame);
		_atlasRef.anim.update(0);
		_prevPlayedAnim = animName;
	}
	
	override function finish()
	{
		_atlasRef.anim.curFrame = _atlasRef.anim.length - 1;
	}
	
	override function exists(name:String):Bool
	{
		return _atlasRef.anim.existsByName(name);
	}
	
	override function destroy()
	{
		super.destroy();
	}
}
