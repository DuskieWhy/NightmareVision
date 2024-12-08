package funkin.objects;

import openfl.errors.Error;
import flxanimate.AnimateFrames;
import flxanimate.animate.FlxSymbol;
import flxanimate.animate.FlxAnim;
import openfl.display.BitmapData;
import flxanimate.data.SpriteMapData;
import haxe.io.Bytes;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.util.FlxDestroyUtil;
import flxanimate.zip.Zip;
import flxanimate.data.AnimationData.AnimAtlas;
import flxanimate.frames.FlxAnimateFrames;
import openfl.utils.Assets;
import flxanimate.FlxAnimate;

// flxanim does not account for no atlas data so a path currently is required.
class AnimateCharacter extends flxanimate.AnimateSprite implements Icharacter
{
	public var offsets:Map<String, Array<Dynamic>> = new Map();

	public function addOffset() {}

	public function loadJson() {}

	public function playAnim(name:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		anim.play(name, Force, Reversed, Frame);
	}
}

// completely not done
interface Icharacter
{
	public function playAnim(name:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void;
	public var offsets:Map<String, Array<Dynamic>>;
	public function loadJson():Void;
	public function addOffset():Void;
}
