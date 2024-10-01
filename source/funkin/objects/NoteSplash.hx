package funkin.objects;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import funkin.objects.shader.*;
import funkin.data.*;
import funkin.states.*;

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
				// animation.curAnim.frameRate = 24 + FlxG.random.int(-2, 2);
		}

	}

	function loadAnims(skin:String) {
		frames = Paths.getSparrowAtlas(skin);
		switch(skin){
			default:
				for(i in 1...3){
					for(j in 0...PlayState.SONG.keys){
						animation.addByPrefix('note$j-$i', '${NoteAnimations.splashes[j]}', 24, false);
					}
				}
		}
	}

	override function update(elapsed:Float) {
		if(animation.curAnim != null)if(animation.curAnim.finished) kill();

		super.update(elapsed);
	}
}
