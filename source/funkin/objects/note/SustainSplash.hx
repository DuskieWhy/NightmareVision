package funkin.objects.note;

import funkin.data.*;
import funkin.objects.Bopper;
import funkin.game.shaders.RGBPalette.RGBShaderReference;

class SustainSplash extends FunkinSprite implements funkin.game.modchart.IModNote
{
	public var rgbShader:RGBShaderReference;
	
	public var data(get, set):Int;
	public var noteData:Int = 0;
	
	public var player:Int = 0;
	
	private var _note:Note;
	private var _strum:StrumNote;
	
	// internal thing to optimize loading frames
	@:noCompletion var _textureLoaded:Null<String> = null;
	
	public var skin:NoteSkin;
	
	public function new(x:Float = 0, y:Float = 0, noteData:Int = 0, player:Int = 0)
	{
		super(x, y);
		
		rgbShader = NoteUtil.initRGBShader(this, noteData, 0, player);
		
		addAnims(NoteUtil.getSkinFromID(player));
	}
	
	function addAnims(_skin:NoteSkin)
	{
		frames = Paths.getSparrowAtlas(_skin.sustainSplashTexture);
		
		final animData = _skin.susSplashAnims;
		
		var noteData = -1;
		for (group in animData)
		{
			noteData += 1;
			for (anim in group)
			{
				final animName = '${anim.anim}$noteData';
				
				animation.addByPrefix(animName, anim.xmlName, anim.fps, anim.looping);
				addOffset(animName, anim.offsets[0], anim.offsets[1]);
			}
		}
		
		animation.onFinish.add((anim) -> {
			if (anim.contains('start')) playAnim('loop$data', false);
			if (anim.contains('end')) kill();
		});
	}
	
	public override function playAnim(anim:String, force:Bool = false, isReversed:Bool = false, frame:Int = 0)
	{
		super.playAnim(anim, force, isReversed, frame);
		
		centerOffsets();
		centerOrigin();
	}
	
	public function setColors(?colors:Array<FlxColor>):Void
	{
		if (colors == null || skin == null) return;
		
		final sanitzedColourArray = colors ?? NoteUtil.colorToArray(skin.colors[data]);
		
		rgbShader.enabled = skin.inEngineColoring;
		rgbShader.setColors(sanitzedColourArray);
	}
	
	public function setupSplash(strum:StrumNote, ?note:Note, ?time:Float = 0.5, ?isPlayer:Bool = false, ?colourInput:Array<FlxColor>, ?field:PlayField)
	{
		this._note = note;
		this._strum = strum;
		
		data = note.noteData;
		
		visible = true;
		angle = 0;
		alpha = 1;
		
		this.player = field?.player ?? 0;
		
		skin = NoteUtil.getSkinFromID(player);
		
		antialiasing = skin.antialiasing;
		
		if (skin?.susSplashScale != null) scale.set(skin.susSplashScale, skin.susSplashScale);
		
		baseScale.copyFrom(scale);
		
		updateHitbox();
		
		playAnim('start$data', true);
		setColors(colourInput);
		_position();
		
		FlxTimer.wait(time, () -> {
			if (isPlayer && ClientPrefs.noteSplashes) playAnim('end$data', true);
			else kill();
		});
	}
	
	function _position()
	{
		if (_strum != null)
		{
			final _skin:NoteSkin = NoteUtil.getSkinFromID(player);
			
			final offsets = _skin.sustainSplashOffsets != null ? _skin.sustainSplashOffsets[data] : null;
			
			setPosition(_strum.x + (_strum.width - width) * .5, _strum.y + (_strum.height - height) * .5);
			spriteOffset.set(offsets?.x, offsets?.y);
		}
	}
	
	inline function get_data():Int return noteData;
	
	inline function set_data(v:Int):Int return noteData = v;
}
