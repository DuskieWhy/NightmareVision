package funkin.objects.note;

import funkin.backend.math.Vector3;

import flixel.FlxSprite;
import flixel.math.FlxPoint;

import funkin.objects.*;
import funkin.game.shaders.RGBPalette;
import funkin.game.shaders.RGBPalette.RGBShaderReference;
import funkin.states.*;
import funkin.data.*;

class StrumNote extends FunkinSprite implements funkin.game.modchart.IModNote
{
	public var intThing:Int = 0;
	
	public var resetAnim:Float = 0;
	public var noteData:Int = 0;
	public var direction:Float = 90;
	public var downScroll:Bool = false;
	public var sustainReduce:Bool = true;
	public var isQuant:Bool = false;
	public var player:Int;
	public var targetAlpha:Float = 1;
	public var alphaMult:Float = 1;
	public var parent:PlayField;
	@:isVar
	public var swagWidth(get, null):Float;
	
	public function get_swagWidth()
	{
		return parent == null ? Note.swagWidth : parent.swagWidth;
	}
	
	// public var zIndex:Float = 0;
	// public var desiredZIndex:Float = 0;
	public var z:Float = 0;
	
	override function set_alpha(val:Float)
	{
		return targetAlpha = val;
	}
	
	public var texture(default, set):String = null;
	
	private function set_texture(value:String):String
	{
		if (texture != value)
		{
			texture = value;
			reloadNote();
		}
		return value;
	}
	
	public var rgbShader:RGBShaderReference;
	public var useRGBShader:Bool = true;
	
	public var skin:NoteSkin;
	
	public function new(player:Int, x:Float, y:Float, leData:Int, ?parent:PlayField)
	{
		noteData = leData;
		this.noteData = leData;
		this.parent = parent;
		this.player = player;
		super(x, y);
		
		skin = NoteUtil.getSkinFromID(parent?.player ?? 0);
		
		texture = skin.noteTexture; // Load texture and anims
		
		scrollFactor.set();
		
		useRGBShader = skin.inEngineColoring;
		
		rgbShader = NoteUtil.initRGBShader(this, noteData, 0, player);
		rgbShader.enabled = useRGBShader;
		isQuant = parent?.quants ?? ClientPrefs.quants;
		
		handleColors();
	}
	
	public var lastNote:Null<Note> = null;
	public function handleColors(anim:String = '', ?note:Note)
	{
		if (!useRGBShader) return;
		
		note ??= lastNote;
		lastNote = note;
		
		final fallback = skin.colors != null ? NoteUtil.colorToArray(skin.colors[noteData]) : NoteUtil.getCurColors(noteData, (isQuant && note != null) ? note.quant : 4, player);
		
		var arr:Array<FlxColor> = note?.rgbShader?.colorArray ?? [];
		if (arr == null || arr.length <= 0) arr = fallback;
		// if (arr == null || arr.length <= 0) arr = NoteUtil.getCurColors(noteData, (isQuant && note != null) ? note.quant : 4, player);
		
		if (isQuant && anim == 'pressed') arr = ClientPrefs.arrowRGBquant[0];
		
		if (rgbShader != null)
		{
			rgbShader.setColors(arr);
			
			rgbShader.enabled = (anim != 'static');
		}
	}
	
	public function reloadNote()
	{
		var lastAnim:String = null;
		if (animation.curAnim != null) lastAnim = animation.curAnim.name;
		var br:String = texture;
		
		frames = Paths.getAtlasFrames(br);
		
		setGraphicSize(Std.int(width * skin.receptorScale));
		
		loadAnimations();
		
		baseScale.copyFrom(scale);
		updateHitbox();
		
		antialiasing = skin.antialiasing;
		
		if (lastAnim != null) playAnim(lastAnim, true);
		
		handleColors();
	}
	
	function loadAnimations()
	{
		var noteAnims = skin.receptorAnims;
		var directionAnims = noteAnims[noteData % noteAnims.length];
		
		for (anim in directionAnims)
			addAnim(anim);
	}
	
	function addAnim(_anim:funkin.data.NoteSkin.Animation)
	{
		final anim = _anim ?? NoteUtil.fallbackReceptorAnims[0];
		
		if (!hasAnim(anim.anim))
		{
			animation.addByPrefix(anim.anim, anim.xmlName, anim.fps, anim.looping);
			addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
		}
	}
	
	public function postAddedToGroup()
	{
		playAnim('static');
		x -= swagWidth / 2;
		x = x - (swagWidth * 2) + (swagWidth * noteData) + 54;
		
		ID = noteData;
	}
	
	override function update(elapsed:Float)
	{
		if (resetAnim > 0)
		{
			resetAnim -= elapsed;
			if (resetAnim <= 0)
			{
				playAnim('static');
				resetAnim = 0;
			}
		}
		@:bypassAccessor
		super.set_alpha(targetAlpha * alphaMult);
		
		super.update(elapsed);
	}
	
	public override function playAnim(anim:String, force:Bool = false, isReversed:Bool = false, frame:Int = 0)
	{
		super.playAnim(anim, force, isReversed, frame);
		
		centerOffsets();
		centerOrigin();
		
		handleColors(anim);
	}
}
