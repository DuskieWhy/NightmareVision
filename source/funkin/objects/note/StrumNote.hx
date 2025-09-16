package funkin.objects.note;

import math.Vector3;

import flixel.FlxSprite;
import flixel.math.FlxPoint;

import funkin.objects.*;
import funkin.game.shaders.RGBPalette;
import funkin.game.shaders.RGBPalette.RGBShaderReference;
import funkin.states.*;
import funkin.data.*;

class StrumNote extends FlxSprite
{
	public var intThing:Int = 0;
	
	public var vec3Cache:Vector3 = new Vector3(); // for vector3 operations in modchart code
	public var defScale:FlxPoint = FlxPoint.get(); // for modcharts to keep the scaling
	
	public var resetAnim:Float = 0;
	public var noteData:Int = 0;
	public var direction:Float = 90;
	public var downScroll:Bool = false;
	public var sustainReduce:Bool = true;
	public var isQuant:Bool = false;
	public var player:Int;
	public var targetAlpha:Float = 1;
	public var alphaMult:Float;
	public var parent:PlayField;
	@:isVar
	public var swagWidth(get, null):Float;
	
	public var animOffsets:Map<String, Array<Float>> = new Map();
	
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
	
	public function new(player:Int, x:Float, y:Float, leData:Int, ?parent:PlayField)
	{
		// rgbShader.enabled = false;
		
		noteData = leData;
		this.noteData = leData;
		this.parent = parent;
		this.player = player;
		super(x, y);
		
		var skin:String = 'NOTE_assets';
		skin = NoteSkinHelper.arrowSkins[player];
		texture = skin; // Load texture and anims
		
		scrollFactor.set();
		
		rgbShader = new RGBShaderReference(this, Note.initializeGlobalRGBShader(leData));
		if (NoteSkinHelper.instance?.data?.inGameColoring ?? false) shader = rgbShader.shader;
	}
	
	public function handleColors(anim:String, ?note:Note = null)
	{
		if (rgbShader == null || !NoteSkinHelper.instance?.data?.inGameColoring ?? false) return;
		
		var arr:Array<FlxColor> = ClientPrefs.arrowRGBdef[noteData];
		if (ClientPrefs.noteSkin.contains('Quant'))
		{
			if (note != null) arr = ClientPrefs.arrowRGBquant[Note.quants.indexOf(note.quant)];
			if (anim == 'pressed') arr = ClientPrefs.arrowRGBquant[0];
		}
		
		if (noteData <= arr.length)
		{
			@:bypassAccessor
			{
				rgbShader.r = arr[0];
				rgbShader.g = arr[1];
				rgbShader.b = arr[2];
			}
		}
		
		rgbShader.enabled = anim != 'static';
	}
	
	public function reloadNote()
	{
		isQuant = false;
		var lastAnim:String = null;
		if (animation.curAnim != null) lastAnim = animation.curAnim.name;
		var br:String = texture;
		if (ClientPrefs.noteSkin.contains('Quant')) isQuant = NoteSkinHelper.instance.data.isQuants;
		
		if (NoteSkinHelper.instance.data.isPixel)
		{
			loadGraphic(Paths.image(br));
			width = width / NoteSkinHelper.instance.data.pixelSize[0];
			height = height / NoteSkinHelper.instance.data.pixelSize[1];
			loadGraphic(Paths.image(br), true, Math.floor(width), Math.floor(height));
			
			antialiasing = false;
			setGraphicSize(Std.int(width * NoteSkinHelper.instance.data.scale));
			loadPixelAnimations();
		}
		else
		{
			frames = Paths.getSparrowAtlas(br);
			
			setGraphicSize(Std.int(width * NoteSkinHelper.instance.data.scale));
			
			loadAnimations();
		}
		defScale.copyFrom(scale);
		updateHitbox();
		
		if (!NoteSkinHelper.instance.data.antialiasing) antialiasing = false;
		
		if (lastAnim != null)
		{
			playAnim(lastAnim, true);
		}
		
		handleColors('');
	}
	
	function loadAnimations()
	{
		for (i in 0...NoteSkinHelper.instance.data.receptorAnimations[noteData].length)
		{
			var anim = NoteSkinHelper.instance.data.receptorAnimations[noteData][i];
			
			animation.addByPrefix(anim.anim, anim.xmlName, 24, anim.looping);
			addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
		}
	}
	
	function loadPixelAnimations()
	{
		for (note in 0...NoteSkinHelper.keys)
		{
			animation.add(NoteSkinHelper.instance.data.noteAnimations[note][0].anim, [note + 4]);
		}
		
		animation.add('static', [noteData]);
		animation.add('pressed', [noteData + 4, noteData + 8], 12, false);
		animation.add('confirm', [noteData + 12, noteData + 16], 24, false);
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
		if (animation.curAnim != null)
		{ // my bad i was upset
			if (animation.curAnim.name == 'confirm' && !NoteSkinHelper.instance.data.isPixel) centerOrigin();
		}
		
		super.update(elapsed);
	}
	
	public function playAnim(anim:String, ?force:Bool = false, ?note:Note)
	{
		animation.play(anim, force);
		centerOffsets();
		centerOrigin();
		
		if (animOffsets.exists(anim))
		{
			offset.set(offset.x + animOffsets.get(anim)[0], offset.y + animOffsets.get(anim)[1]);
		}
		if (animation.curAnim?.name == 'confirm' && !NoteSkinHelper.instance.data.isPixel) centerOrigin();
		
		handleColors(anim, ClientPrefs.noteSkin.contains('Quant') ? note : null);
	}
	
	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsets[name] = [x, y];
	}
	
	override function destroy()
	{
		defScale.put();
		vec3Cache = null;
		super.destroy();
	}
}
