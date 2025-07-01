package funkin.objects;

import math.Vector3;

import flixel.FlxSprite;
import flixel.math.FlxPoint;

import funkin.objects.*;
import funkin.game.shaders.*;
import funkin.states.*;
import funkin.data.*;

class StrumNote extends FlxSprite
{
	public static var handler:NoteSkinHelper;
	public static var keys:Int = 4;
	
	public var intThing:Int = 0;
	
	public var vec3Cache:Vector3 = new Vector3(); // for vector3 operations in modchart code
	public var defScale:FlxPoint = FlxPoint.get(); // for modcharts to keep the scaling
	
	public var colorSwap:ColorSwap;
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
	
	public function new(player:Int, x:Float, y:Float, leData:Int, ?parent:PlayField)
	{
		// handler = PlayState.noteSkin;
		
		colorSwap = new ColorSwap();
		shader = colorSwap.shader;
		noteData = leData;
		this.noteData = leData;
		this.parent = parent;
		this.player = player;
		super(x, y);
		
		var skin:String = 'NOTE_assets';
		skin = NoteSkinHelper.arrowSkins[player];
		texture = skin; // Load texture and anims
		
		scrollFactor.set();
	}
	
	public function reloadNote()
	{
		isQuant = false;
		var lastAnim:String = null;
		if (animation.curAnim != null) lastAnim = animation.curAnim.name;
		var br:String = texture;
		if (handler.data.isPixel)
		{
			if ((ClientPrefs.noteSkin == 'Quants' || ClientPrefs.noteSkin == "QuantStep")) isQuant = handler.data.isQuants;
			loadGraphic(Paths.image(br));
			width = width / handler.data.pixelSize[0];
			height = height / handler.data.pixelSize[1];
			loadGraphic(Paths.image(br), true, Math.floor(width), Math.floor(height));
			
			antialiasing = false;
			setGraphicSize(Std.int(width * handler.data.scale));
			loadPixelAnimations();
		}
		else
		{
			if ((ClientPrefs.noteSkin == 'Quants' || ClientPrefs.noteSkin == "QuantStep")) isQuant = handler.data.isQuants;
			frames = Paths.getSparrowAtlas(br);
			
			antialiasing = ClientPrefs.globalAntialiasing;
			setGraphicSize(Std.int(width * handler.data.scale));
			
			loadAnimations();
		}
		defScale.copyFrom(scale);
		updateHitbox();
		
		antialiasing = handler.data.antialiasing;
		if (handler.data.antialiasing) antialiasing = ClientPrefs.globalAntialiasing;
		
		if (lastAnim != null)
		{
			playAnim(lastAnim, true);
		}
	}
	
	function loadAnimations()
	{
		// what?
		// for(note in 0...keys){ animation.addByPrefix(handler.data.noteAnimations[note][0].anim, handler.data.receptorAnimations[noteData][0].anim ); }
		for (i in 0...handler.data.receptorAnimations[noteData].length)
		{
			if (handler != null)
			{
				var anim = handler.data.receptorAnimations[noteData][i];
				
				animation.addByPrefix(anim.anim, anim.xmlName, 24, anim.looping);
				addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
			}
		}
	}
	
	function loadPixelAnimations()
	{
		for (note in 0...keys)
		{
			animation.add(handler.data.noteAnimations[note][0].anim, [note + 4]);
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
			if (animation.curAnim.name == 'confirm' && !handler.data.isPixel) centerOrigin();
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
		
		if (animation.curAnim == null || animation.curAnim.name == 'static')
		{
			colorSwap.hue = 0;
			colorSwap.saturation = 0;
			colorSwap.brightness = 0;
		}
		else
		{
			if (note == null)
			{
				colorSwap.hue = ClientPrefs.arrowHSV[noteData % 4][0] / 360;
				colorSwap.saturation = ClientPrefs.arrowHSV[noteData % 4][1] / 100;
				colorSwap.brightness = ClientPrefs.arrowHSV[noteData % 4][2] / 100;
			}
			else
			{
				colorSwap.hue = note.colorSwap.hue;
				colorSwap.saturation = note.colorSwap.saturation;
				colorSwap.brightness = note.colorSwap.brightness;
			}
			
			if (animation.curAnim.name == 'confirm' && !handler.data.isPixel)
			{
				centerOrigin();
			}
		}
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
