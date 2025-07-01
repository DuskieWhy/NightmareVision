package funkin.objects;

import flixel.FlxSprite;

import funkin.game.shaders.*;
import funkin.data.*;
import funkin.states.*;

class NoteSplash extends FlxSprite
{
	public static var handler:NoteSkinHelper;
	public static var keys:Int = 4;
	
	public var colorSwap:HSLColorSwap = null;
	
	private var idleAnim:String;
	private var textureLoaded:String = null;
	
	public var data:Int = 0;
	
	public function new(x:Float = 0, y:Float = 0, ?note:Int = 0)
	{
		super(x, y);
		
		var skin:String = getPlayStateSplash('noteSplashes');
		
		loadAnims(skin);
		
		colorSwap = new HSLColorSwap();
		shader = colorSwap.shader;
		
		setupNoteSplash(x, y, note);
		antialiasing = ClientPrefs.globalAntialiasing;
	}
	
	public function setupNoteSplash(x:Float, y:Float, note:Int = 0, texture:String = null, hueColor:Float = 0, satColor:Float = 0, brtColor:Float = 0, ?field:PlayField)
	{
		// scale.set(1, 1);
		if (field != null) setPosition(x - field.members[note].swagWidth * 0.95, y - field.members[note].swagWidth * 0.95);
		else setPosition(x - Note.swagWidth * 0.95, y - Note.swagWidth);
		
		if (texture == null)
		{
			texture = getPlayStateSplash('noteSplashes');
		}
		
		if (textureLoaded != texture)
		{
			loadAnims(texture);
		}
		if (field != null)
		{
			scale.x *= field.scale;
			scale.y *= field.scale;
		}
		data = note;
		switch (texture)
		{
			default:
				// alpha = 0.6;
				alpha = 1;
				antialiasing = true;
				colorSwap.hue = hueColor;
				colorSwap.saturation = satColor;
				colorSwap.lightness = brtColor;
				animation.play('note' + note, true);
				offset.set(-20, -20);
				// animation.curAnim.frameRate = 24 + FlxG.random.int(-2, 2);
		}
	}
	
	public function playAnim()
	{
		animation.play('note' + data, true);
	}
	
	function loadAnims(skin:String)
	{
		frames = Paths.getSparrowAtlas(skin);
		switch (skin)
		{
			default:
				for (i in 0...keys)
				{
					animation.addByPrefix(handler.data.noteSplashAnimations[i].anim, handler.data.noteSplashAnimations[i].xmlName, 24, false);
				}
		}
		
		textureLoaded = skin;
	}
	
	function getPlayStateSplash(?fallback:String = ''):String
	{
		if (PlayState.SONG != null)
		{
			return (PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) ? PlayState.SONG.splashSkin : fallback;
		}
		
		return fallback;
	}
	
	override function update(elapsed:Float)
	{
		if (animation.curAnim != null) if (animation.curAnim.finished) kill();
		
		super.update(elapsed);
	}
}
