package gameObjects;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import gameObjects.shader.*;
import meta.data.*;
import meta.states.*;

class NoteSplash extends FlxSprite
{
	public var colorSwap:HSLColorSwap = null;
	private var idleAnim:String;
	private var textureLoaded:String = null;

	public function new(x:Float = 0, y:Float = 0, ?note:Int = 0) {
		super(x, y);

		var skin:String = 'noteSplashes';

		if(PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) skin = PlayState.SONG.splashSkin;

		loadAnims(skin);

		colorSwap = new HSLColorSwap();
		shader = colorSwap.shader;

		setupNoteSplash(x, y, note);
		antialiasing = ClientPrefs.globalAntialiasing;
	}

	public function setupNoteSplash(x:Float, y:Float, note:Int = 0, texture:String = null, hueColor:Float = 0, satColor:Float = 0, brtColor:Float = 0, ?field:PlayField) {
		//scale.set(1, 1);
		if (field!=null)
			setPosition(x - field.members[note].swagWidth * 0.95, y - field.members[note].swagWidth * 0.95);
		else
			setPosition(x - Note.swagWidth * 0.95, y - Note.swagWidth);
		

		if(texture == null) {
			texture = 'noteSplashes';
			if(PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) texture = PlayState.SONG.splashSkin;
		}

		if(textureLoaded != texture) {
			loadAnims(texture);
		}
		if(field!=null){
			scale.x *= field.scale;
			scale.y *= field.scale;
		}
		switch(texture){
			default:
				// alpha = 0.6;
				alpha = 1;
				antialiasing=true;
				colorSwap.hue = hueColor;
				colorSwap.saturation = satColor;
				colorSwap.lightness = brtColor;
				var animNum:Int = FlxG.random.int(1, 2);
				animation.play('note' + note + '-' + animNum, true);
				offset.set(-20, -20);
				animation.curAnim.frameRate = 24 + FlxG.random.int(-2, 2);
		}

	}

	function loadAnims(skin:String) {
		frames = Paths.getSparrowAtlas(skin);
		switch(skin){
			default:
				animation.addByPrefix("note0-1", "note splash purple 1", 24, false);
				animation.addByPrefix("note1-1", "note splash blue 1", 24, false);
				animation.addByPrefix("note2-1", "note splash green 1", 24, false);
				animation.addByPrefix("note3-1", "note splash red 1", 24, false);
				animation.addByPrefix("note4-1", "note splash purple 1", 24, false);
				animation.addByPrefix("note5-1", "LSLAMSPLASH", 12, false);
				animation.addByPrefix("note6-1", "RSLAMSPLASH", 12, false);

				animation.addByPrefix("note0-2", "note splash purple 1", 24, false);
				animation.addByPrefix("note1-2", "note splash blue 1", 24, false);
				animation.addByPrefix("note2-2", "note splash green 1", 24, false);
				animation.addByPrefix("note3-2", "note splash red 1", 24, false);
				animation.addByPrefix("note4-2", "note splash purple 1", 24, false);
				animation.addByPrefix("note5-2", "LSLAMSPLASH", 12, false);
				animation.addByPrefix("note6-2", "RSLAMSPLASH", 12, false);
		}
	}

	override function update(elapsed:Float) {
		if(animation.curAnim != null)if(animation.curAnim.finished) kill();

		super.update(elapsed);
	}
}
