package funkin.objects.note;

import flixel.FlxSprite;

import funkin.game.shaders.*;
import funkin.game.shaders.RGBPalette.RGBShaderReference;
import funkin.data.*;
import funkin.states.*;

@:nullSafety
class NoteSplash extends FlxSprite
{
	/**
	 * Shader applied to the notesplash to support custom colours
	 */
	public var rgbShader:RGBShaderReference;
	
	/**
	 * The notedata of the splash
	 */
	public var data:Int = 0;
	
	// internal thing to optimize loading frames
	@:noCompletion var _textureLoaded:Null<String> = null;
	
	public function new(x:Float = 0, y:Float = 0, noteData:Int = 0)
	{
		super(x, y);
		
		rgbShader = NoteSkinHelper.initRGBShader(this, noteData);
		
		loadAnims(getPlayStateSplash('noteSplashes'));
		setupNoteSplash(x, y, noteData);
	}
	
	public function setupNoteSplash(x:Float = 0, y:Float = 0, note:Int = 0, ?texture:String, ?quantIdx:Int, ?field:PlayField)
	{
		final swagWidth = field?.members[note].swagWidth ?? Note.swagWidth;
		setPosition(x - swagWidth * 0.95, y - swagWidth);
		
		final quant = quantIdx ?? 4;
		
		texture ??= getPlayStateSplash('noteSplashes');
		
		if (_textureLoaded != texture)
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
				alpha = 1;
				antialiasing = true;
				animation.play('note' + note, true);
				offset.set(-20, -20);
		}
		
		if (NoteSkinHelper.shaderEnabled) rgbShader.setColors(NoteSkinHelper.getCurColors(note, quant));
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
				final data = NoteSkinHelper.instance?.data.noteSplashAnimations ?? NoteSkinHelper.DEFAULT_NOTESPLASH_ANIMATIONS;
				
				for (noteData in 0...NoteSkinHelper.keys)
				{
					if (data[noteData] == null || data[noteData].anim == null || data[noteData].xmlName == null) continue;
					
					@:nullSafety(Off)
					animation.addByPrefix(data[noteData].anim, data[noteData].xmlName, 24, false);
				}
		}
		
		_textureLoaded = skin;
	}
	
	function getPlayStateSplash(fallback:String):String
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
