package gameObjects;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.utils.AssetType;
import openfl.utils.Assets;
import gameObjects.*;
import gameObjects.shader.*;
import meta.states.*;
import flixel.math.FlxPoint;
import meta.data.*;
import math.*;
import modchart.*;
#if sys
import sys.FileSystem;
#end
using StringTools;

class StrumNote extends FlxSprite
{
	public var vec3Cache:Vector3 = new Vector3(); // for vector3 operations in modchart code
	public var defScale:FlxPoint = FlxPoint.get(); // for modcharts to keep the scaling

	public var colorSwap:ColorSwap;
	public var resetAnim:Float = 0;
	public var noteData:Int = 0;
	public var direction:Float = 90;//plan on doing scroll directions soon -bb
	public var downScroll:Bool = false;//plan on doing scroll directions soon -bb
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
		
	public var zIndex:Float = 0;
	public var desiredZIndex:Float = 0;
	public var z:Float = 0;

	override function destroy()
	{
		defScale.put();
		super.destroy();
	}	

	override function set_alpha(val:Float){
		return targetAlpha = val;
	}

	public var texture(default, set):String = null;
	private function set_texture(value:String):String {
		if(texture != value) {
			texture = value;
			reloadNote();
		}
		return value;
	}

	public function new(player:Int, x:Float, y:Float, leData:Int, ?parent:PlayField) {
		colorSwap = new ColorSwap();
		shader = colorSwap.shader;
		noteData = leData;
		this.noteData = leData;
		this.parent = parent;
		this.player = player;
		super(x, y);

		var skin:String = 'NOTE_assets';
		if(PlayState.arrowSkins[player] != null) skin = PlayState.arrowSkins[player];
		texture = skin; //Load texture and anims

		scrollFactor.set();
	}

	public function reloadNote()
	{
		isQuant=false;
		var lastAnim:String = null;
		if(animation.curAnim != null) lastAnim = animation.curAnim.name;
		var br:String = texture;
		if(PlayState.isPixelStage)
		{
			if((ClientPrefs.noteSkin == 'Quants' || ClientPrefs.noteSkin == "QuantStep")){
				if(Assets.exists(Paths.getPath("images/pixelUI/QUANT" + texture + ".png", IMAGE)) || FileSystem.exists(Paths.modsImages("pixelUI/QUANT" + texture))) {
					br = "QUANT" + texture;
					isQuant=true;
				}
			}
			loadGraphic(Paths.image('pixelUI/' + br));
			width = width / 4;
			height = height / 5;
			loadGraphic(Paths.image('pixelUI/' + br), true, Math.floor(width), Math.floor(height));

			antialiasing = false;
			setGraphicSize(Std.int(width * PlayState.daPixelZoom));

			animation.add('green', [6]);
			animation.add('red', [7]);
			animation.add('blue', [5]);
			animation.add('purple', [4]);
			switch (Math.abs(noteData))
			{
				case 0:
					animation.add('static', [0]);
					animation.add('pressed', [4, 8], 12, false);
					animation.add('confirm', [12, 16], 24, false);
				case 1:
					animation.add('static', [1]);
					animation.add('pressed', [5, 9], 12, false);
					animation.add('confirm', [13, 17], 24, false);
				case 2:
					animation.add('static', [2]);
					animation.add('pressed', [6, 10], 12, false);
					animation.add('confirm', [14, 18], 12, false);
				case 3:
					animation.add('static', [3]);
					animation.add('pressed', [7, 11], 12, false);
					animation.add('confirm', [15, 19], 24, false);
			}
		}
		else
		{
			if((ClientPrefs.noteSkin == 'Quants' || ClientPrefs.noteSkin == "QuantStep")){
				if(Assets.exists(Paths.getPath("images/QUANT" + texture + ".png", IMAGE)) || FileSystem.exists(Paths.modsImages("QUANT" + texture))) {
					br = "QUANT" + texture;
					isQuant=true;
					trace(br);
				}
			}
			frames = Paths.getSparrowAtlas(br);
			animation.addByPrefix('green', 'arrowUP');
			animation.addByPrefix('blue', 'arrowDOWN');
			animation.addByPrefix('purple', 'arrowLEFT');
			animation.addByPrefix('red', 'arrowRIGHT');

			antialiasing = ClientPrefs.globalAntialiasing;
			setGraphicSize(Std.int(width * 0.7));

			switch (Math.abs(noteData))
			{
				case 0:
					animation.addByPrefix('static', 'arrowLEFT');
					animation.addByPrefix('pressed', 'left press', 24, false);
					animation.addByPrefix('confirm', 'left confirm', 24, false);
				case 1:
					animation.addByPrefix('static', 'arrowDOWN');
					animation.addByPrefix('pressed', 'down press', 24, false);
					animation.addByPrefix('confirm', 'down confirm', 24, false);
				case 2:
					animation.addByPrefix('static', 'arrowUP');
					animation.addByPrefix('pressed', 'up press', 24, false);
					animation.addByPrefix('confirm', 'up confirm', 24, false);
				case 3:
					animation.addByPrefix('static', 'arrowRIGHT');
					animation.addByPrefix('pressed', 'right press', 24, false);
					animation.addByPrefix('confirm', 'right confirm', 24, false);
				case 4:
					animation.addByPrefix('static', 'arrowFX');
					animation.addByPrefix('pressed', 'fx press', 24, false);
					animation.addByPrefix('confirm', 'fx confirm', 24, false);
				case 5:
					animation.addByPrefix('static', 'arrowKNOB L');
					animation.addByPrefix('pressed', 'knob l press', 24, false);
					animation.addByPrefix('confirm', 'knob l confirm', 24, false);
				case 6:
					animation.addByPrefix('static', 'arrowKNOB R');
					animation.addByPrefix('pressed', 'knob r press', 24, false);
					animation.addByPrefix('confirm', 'knob r confirm', 24, false);
			}
		}
		defScale.copyFrom(scale);
		updateHitbox();

		if(lastAnim != null)
		{
			playAnim(lastAnim, true);
		}
	}

	public function postAddedToGroup() {
		playAnim('static');
		x -= swagWidth / 2;
		x = x - (swagWidth * 2) + (swagWidth * noteData) + 54;
		
		ID = noteData;
	}
	override function update(elapsed:Float) {
		if(resetAnim > 0) {
			resetAnim -= elapsed;
			if(resetAnim <= 0) {
				playAnim('static');
				resetAnim = 0;
			}
		}
		@:bypassAccessor
		super.set_alpha(targetAlpha * alphaMult);
		if(animation.curAnim != null){ //my bad i was upset
			if(animation.curAnim.name == 'confirm' && !PlayState.isPixelStage)
				centerOrigin();
			
		}

		super.update(elapsed);
	}

	public function playAnim(anim:String, ?force:Bool = false, ?note:Note) {
		animation.play(anim, force);
		centerOffsets();
		centerOrigin();


		if (animOffsets.exists(anim))
		{
			offset.set(offset.x + animOffsets.get(anim)[0],offset.y + animOffsets.get(anim)[1]);
		}

		if(animation.curAnim == null || animation.curAnim.name == 'static') {
			colorSwap.hue = 0;
			colorSwap.saturation = 0;
			colorSwap.brightness = 0;
		} else {
			if(note==null){
				colorSwap.hue = ClientPrefs.arrowHSV[noteData % 4][0] / 360;
				colorSwap.saturation = ClientPrefs.arrowHSV[noteData % 4][1] / 100;
				colorSwap.brightness = ClientPrefs.arrowHSV[noteData % 4][2] / 100;
			}else{
				colorSwap.hue = note.colorSwap.hue;
				colorSwap.saturation = note.colorSwap.saturation;
				colorSwap.brightness = note.colorSwap.brightness;
			}

			if(animation.curAnim.name == 'confirm' && !PlayState.isPixelStage) {
				centerOrigin();
			}
		}
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsets[name] = [x, y];
	}
}
