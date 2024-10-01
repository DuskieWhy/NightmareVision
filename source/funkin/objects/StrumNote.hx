package funkin.objects;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.utils.AssetType;
import openfl.utils.Assets;
import funkin.objects.*;
import funkin.objects.shader.*;
import funkin.states.*;
import flixel.math.FlxPoint;
import funkin.data.*;
import funkin.modchart.*;
import math.Vector3;
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
		vec3Cache = null;
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
		trace(PlayState.arrowSkins[player]);
		if(PlayState.arrowSkins[player] != null && PlayState.arrowSkins[player] != '' && PlayState.arrowSkins[player] != '0') skin = PlayState.arrowSkins[player];
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
			loadPixelAnimations();
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

			antialiasing = ClientPrefs.globalAntialiasing;
			setGraphicSize(Std.int(width * 0.7));

			loadAnimations();
		}
		defScale.copyFrom(scale);
		updateHitbox();

		if(lastAnim != null)
		{
			playAnim(lastAnim, true);
		}
	}
	
	function loadAnimations(){
		for(note in 0...PlayState.SONG.keys){ animation.addByPrefix(NoteAnimations.notes[note], NoteAnimations.receptors[noteData]); }

		animation.addByPrefix('static', NoteAnimations.receptors[noteData]);
		animation.addByPrefix('pressed', NoteAnimations.receptorsPress[noteData], 24, false);
		animation.addByPrefix('confirm', NoteAnimations.receptorsConfirm[noteData], 24, false);
	}
	
	function loadPixelAnimations(){
		var frame = NoteAnimations.pixelFrames[noteData];
		for(note in 0...PlayState.SONG.keys){ animation.add(NoteAnimations.notes[note],  [note + 4]);}

		animation.add('static', [frame]);
		animation.add('pressed', [frame + 4, frame + 8], 12, false);
		animation.add('confirm', [frame + 12, frame + 16], 24, false);
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
