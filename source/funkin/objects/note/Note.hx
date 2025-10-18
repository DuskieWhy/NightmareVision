package funkin.objects.note;

import math.Vector3;

import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;

import funkin.data.*;
import funkin.game.shaders.*;
import funkin.game.shaders.RGBPalette.RGBShaderReference;
import funkin.objects.Character;
import funkin.scripts.*;
import funkin.states.*;
import funkin.states.editors.ChartEditorState;

typedef EventNote =
{
	strumTime:Float,
	event:String,
	value1:String,
	value2:String
}

class Note extends FlxSprite
{
	public var row:Int = 0;
	public var lane:Int = 0;
	
	public var noteScript:Null<FunkinScript> = null;
	
	public var vec3Cache:Vector3 = new Vector3(); // for vector3 operations in modchart code
	public var defScale:FlxPoint = FlxPoint.get(); // for modcharts to keep the scaling
	
	public var mAngle:Float = 0;
	public var bAngle:Float = 0;
	public var visualTime:Float = 0;
	public var typeOffsetX:Float = 0; // used to offset notes, mainly for note types. use in place of offset.x and offset.y when offsetting notetypes
	public var typeOffsetY:Float = 0;
	
	public var noteDiff:Float = 1000;
	public var quant:Int = 4;
	
	public var z:Float = 0;
	public var garbage:Bool = false; // if this is true, the note will be removed in the next update cycle
	public var alphaMod:Float = 1;
	public var alphaMod2:Float = 1; // TODO: unhardcode this shit lmao
	
	public var extraData:Map<String, Dynamic> = [];
	public var hitbox:Float = Conductor.safeZoneOffset;
	public var isQuant:Bool = false; // mainly for color swapping, so it changes color depending on which set (quants or regular notes)
	public var canQuant:Bool = true;
	public var strumTime:Float = 0;
	
	public var mustPress:Bool = false;
	public var noteData:Int = 0;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;
	public var ignoreNote:Bool = false;
	public var hitByOpponent:Bool = false;
	public var noteWasHit:Bool = false;
	public var prevNote:Note;
	public var nextNote:Note;
	
	public var spawned:Bool = false;
	
	public var tail:Array<Note> = []; // for sustains
	public var parent:Note;
	
	/**
	 * if true, the note cannot be hit.
	 * 
	 */
	public var blockHit:Bool = false;
	
	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;
	public var isSustainEnd:Bool = false;
	public var noteType(default, set):String = null;
	
	public var alreadyShifted:Bool = false;
	
	public var eventName:String = '';
	public var eventLength:Int = 0;
	public var eventVal1:String = '';
	public var eventVal2:String = '';
	
	public var rgbShader:RGBShaderReference;
	public var rgbEnabled:Bool = true;
	
	public static var globalRgbShaders:Array<RGBPalette> = [];
	
	public var inEditor:Bool = false;
	public var skipScale:Bool = false;
	public var gfNote:Bool = false;
	public var baseScaleX:Float = 1;
	public var baseScaleY:Float = 1;
	
	private var earlyHitMult:Float = 0.5;
	
	@:isVar
	public var daWidth(get, never):Float;
	
	public function get_daWidth()
	{
		return playField == null ? Note.swagWidth : playField.swagWidth;
	}
	
	public static var swagWidth:Float = 160 * 0.7;
	
	public var noteSplashDisabled:Bool = false;
	public var noteSplashTexture:Null<String> = null;
	public var noteSplashHue:Float = 0;
	public var noteSplashSat:Float = 0;
	public var noteSplashBrt:Float = 0;
	
	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var offsetAngle:Float = 0;
	public var multAlpha:Float = 1;
	public var multSpeed(default, set):Float = 1;
	
	public var copyX:Bool = true;
	public var copyY:Bool = true;
	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;
	
	public var hitHealth:Float = 0.023;
	public var missHealth:Float = 0.0475;
	public var rating:String = 'unknown';
	public var ratingMod:Float = 0; // 9 = unknown, 0.25 = shit, 0.5 = bad, 0.75 = good, 1 = sick
	public var ratingDisabled:Bool = false;
	
	public var texture(default, set):String = null;
	
	public var noAnimation:Bool = false;
	public var noMissAnimation:Bool = false;
	public var hitCausesMiss:Bool = false;
	public var canMiss:Bool = false;
	public var distance:Float = 2000; // plan on doing scroll directions soon -bb
	
	public var hitsoundDisabled:Bool = false;
	
	public var player:Int = 0;
	
	public var owner:Character = null;
	public var playField(default, set):PlayField;
	public var desiredPlayfield:PlayField; // incase a note should be put into a specific playfield
	
	public static var defaultNotes = ['No Animation', 'GF Sing', ''];
	
	public function set_playField(field:PlayField)
	{
		if (playField != field)
		{
			if (playField != null && playField.notes.contains(this)) playField.removeNote(this);
			
			if (field != null && !field.notes.contains(this)) field.addNote(this);
		}
		return playField = field;
	}
	
	private function set_multSpeed(value:Float):Float
	{
		resizeByRatio(value / multSpeed);
		multSpeed = value;
		return value;
	}
	
	public function resizeByRatio(ratio:Float)
	{
		// for some fuckin reason this shit is still crashing but i cant figure it out. data got that 👀👀👀
		try // why try catch
		{
			if (isSustainNote && (skipScale || !isSustainEnd))
			{
				scale.y *= ratio;
				baseScaleY = scale.y;
				defScale.y = scale.y;
				updateHitbox();
			}
		}
		catch (e) {}
	}
	
	private function set_texture(value:String):String
	{
		if (texture == value) return texture;
		
		reloadNote('', value);
		
		return (texture = value);
	}
	
	private function set_noteType(value:String):String
	{
		noteSplashTexture = PlayState.SONG.splashSkin;
		
		noteScript = null;
		
		if (noteData > -1 && noteType != value)
		{
			switch (value)
			{
				case "Test Owner Note":
					owner = PlayState.instance.gf;
				case 'Hurt Note':
					ignoreNote = mustPress;
					missHealth = isSustainNote ? 0.1 : 0.3;
					hitCausesMiss = true;
					rgbShader.r = 0xFF101010;
					rgbShader.g = 0xFFFF0000;
					rgbShader.b = 0xFF990022;
					
				case 'No Animation':
					noAnimation = true;
					noMissAnimation = true;
				case 'GF Sing':
					gfNote = true;
				case 'Ghost Note':
					alpha = 0.8;
					color = 0xffa19f9f;
				default:
					if (!inEditor) noteScript = PlayState.instance.noteTypeScripts.getScript(value);
					else noteScript = ChartEditorState.instance.notetypeScripts.get(value);
					
					if (noteScript != null)
					{
						noteScript.executeFunc("setupNote", [this], this);
					}
			}
			noteType = value;
		}
		if (hitCausesMiss) canMiss = true;
		
		return value;
	}
	
	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false, ?inEditor:Bool = false, ?player:Int = 0)
	{
		super();
		
		if (prevNote == null) prevNote = this;
		
		this.prevNote = prevNote;
		this.player = player;
		isSustainNote = sustainNote;
		
		if ((ClientPrefs.noteSkin == 'Quants' || ClientPrefs.noteSkin == "QuantStep") && canQuant)
		{
			var beat = Conductor.getBeatInMeasure(strumTime);
			if (prevNote != null && isSustainNote) quant = prevNote.quant;
			else quant = NoteSkinHelper.getQuant(beat);
		}
		this.inEditor = inEditor;
		
		x += (ClientPrefs.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X) + 50;
		// MAKE SURE ITS DEFINITELY OFF SCREEN?
		y -= 2000;
		this.strumTime = strumTime;
		if (!inEditor)
		{
			this.strumTime += ClientPrefs.noteOffset;
			visualTime = PlayState.instance.getNoteInitialTime(this.strumTime);
		}
		
		this.noteData = noteData;
		
		if (noteData > -1)
		{
			rgbEnabled = NoteSkinHelper.instance?.data?.inGameColoring ?? false;
			
			rgbShader = NoteSkinHelper.initRGBShader(this, noteData, quant);
			
			texture = '';
			
			x += swagWidth * (noteData % NoteSkinHelper.keys);
			if (!isSustainNote) animation.play('scroll$noteData');
		}
		
		if (prevNote != null) prevNote.nextNote = this;
		
		if (isSustainNote && prevNote != null)
		{
			hitsoundDisabled = true;
			
			offsetX += width / 2;
			copyAngle = false;
			
			animation.play('holdend$noteData');
			isSustainEnd = true;
			updateHitbox();
			
			offsetX -= width / 2;
			
			if (NoteSkinHelper.instance.data.isPixel) offsetX += 30;
			
			if (prevNote.isSustainNote)
			{
				prevNote.animation.play('hold$noteData');
				prevNote.scale.y *= Conductor.stepCrotchet / 100 * 1.05;
				prevNote.isSustainEnd = false;
				if (PlayState.instance != null)
				{
					prevNote.scale.y *= PlayState.instance.songSpeed;
				}
				
				if (NoteSkinHelper.instance.data.isPixel)
				{
					prevNote.scale.y *= 1.19;
					prevNote.scale.y *= (6 / height); // Auto adjust note size
				}
				prevNote.updateHitbox();
				prevNote.baseScaleX = prevNote.scale.x;
				prevNote.baseScaleY = prevNote.scale.y;
				// prevNote.setGraphicSize();
			}
			
			if (NoteSkinHelper.instance.data.isPixel)
			{
				scale.y *= PlayState.daPixelZoom;
				updateHitbox();
			}
		}
		else if (!isSustainNote)
		{
			earlyHitMult = 1;
		}
		x += offsetX;
		baseScaleX = scale.x;
		baseScaleY = scale.y;
	}
	
	var lastNoteOffsetXForPixelAutoAdjusting:Float = 0;
	var lastNoteScaleToo:Float = 1;
	
	public var originalHeightForCalcs:Float = 6;
	
	public function reloadNote(?prefix:String = '', ?texture:String = '', ?suffix:String = '')
	{
		if (prefix == null) prefix = '';
		if (texture == null) texture = '';
		if (suffix == null) suffix = '';
		
		if (noteScript != null) if (noteScript.executeFunc("onReloadNote", [this, prefix, texture, suffix], this) == ScriptConstants.Function_Stop) return;
		
		var skin:String = texture;
		if (texture.length < 1)
		{
			skin = NoteSkinHelper.arrowSkins[player];
			if (skin == null || skin.length < 1)
			{
				skin = 'NOTE_assets';
			}
		}
		
		var animName:String = null;
		if (animation.curAnim != null)
		{
			animName = animation.curAnim.name;
		}
		
		var arraySkin:Array<String> = skin.split('/');
		arraySkin[arraySkin.length - 1] = prefix + arraySkin[arraySkin.length - 1] + suffix;
		
		var lastScaleY:Float = scale.y;
		var blahblah:String = arraySkin.join('/');
		isQuant = (ClientPrefs.noteSkin == 'Quants' || ClientPrefs.noteSkin == "QuantStep") && NoteSkinHelper.instance.data.isQuants;
		if (NoteSkinHelper.instance.data.isPixel)
		{
			if (isSustainNote)
			{
				loadGraphic(Paths.image(blahblah + NoteSkinHelper.instance.data.sustainSuffix));
				width = width / 4;
				height = height / 2;
				originalHeightForCalcs = height;
				loadGraphic(Paths.image(blahblah + NoteSkinHelper.instance.data.sustainSuffix), true, Math.floor(width), Math.floor(height));
			}
			else
			{
				loadGraphic(Paths.image(blahblah));
				width = width / NoteSkinHelper.instance.data.pixelSize[0];
				height = height / NoteSkinHelper.instance.data.pixelSize[1];
				loadGraphic(Paths.image(blahblah), true, Math.floor(width), Math.floor(height));
			}
			setGraphicSize(Std.int(width * NoteSkinHelper.instance.data.scale));
			loadPixelNoteAnims();
			
			if (isSustainNote)
			{
				offsetX += lastNoteOffsetXForPixelAutoAdjusting;
				lastNoteOffsetXForPixelAutoAdjusting = (width - 7) * (NoteSkinHelper.instance.data.scale / 2);
				offsetX -= lastNoteOffsetXForPixelAutoAdjusting;
			}
		}
		else
		{
			frames = Paths.getSparrowAtlas(blahblah);
			loadNoteAnims();
		}
		if (isSustainNote)
		{
			scale.y = lastScaleY;
		}
		updateHitbox();
		baseScaleX = scale.x;
		baseScaleY = scale.y;
		
		if (animName != null) animation.play(animName, true);
		
		if (inEditor && !skipScale)
		{
			setGraphicSize(ChartEditorState.GRID_SIZE, ChartEditorState.GRID_SIZE);
			updateHitbox();
			baseScaleX = scale.x;
			baseScaleY = scale.y;
		}
		
		if (!NoteSkinHelper.instance.data.antialiasing) antialiasing = false;
		
		if (noteScript != null) noteScript.executeFunc("postReloadNote", [this, prefix, texture, suffix], this);
	}
	
	public function loadNoteAnims()
	{
		if (noteScript != null)
		{
			if (noteScript.exists("loadNoteAnims") && Reflect.isFunction(noteScript.get("loadNoteAnims")))
			{
				noteScript.executeFunc("loadNoteAnims", [this], this, ["super" => _loadNoteAnims]);
				return;
			}
		}
		_loadNoteAnims();
	}
	
	public function loadPixelNoteAnims()
	{
		if (noteScript != null)
		{
			if (noteScript.exists("loadPixelNoteAnims") && Reflect.isFunction(noteScript.get("loadNoteAnims")))
			{
				noteScript.executeFunc("loadPixelNoteAnims", [this], this, ["super" => _loadPixelNoteAnims]);
				return;
			}
		}
		_loadPixelNoteAnims();
	}
	
	function _loadNoteAnims()
	{
		for (i in 0...NoteSkinHelper.instance.data.noteAnimations[noteData].length)
		{
			var anim = NoteSkinHelper.instance.data.noteAnimations[noteData][i];
			animation.addByPrefix(anim.anim, '${anim.xmlName}0', 24, true);
		}
		
		setGraphicSize(Std.int(width * NoteSkinHelper.instance.data.scale));
		updateHitbox();
		baseScaleX = scale.x;
		baseScaleY = scale.y;
	}
	
	function _loadPixelNoteAnims()
	{
		if (isSustainNote)
		{
			animation.add('holdend$noteData', [noteData + 4]);
			animation.add('hold$noteData', [noteData]);
		}
		else animation.add('scroll$noteData', [noteData + 4]);
	}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (!inEditor)
		{
			if (noteScript != null)
			{
				noteScript.executeFunc("update", [this, elapsed], this);
			}
		}
		
		if (rgbShader != null) rgbShader.alphaMult = (alphaMod * alphaMod2) * (playField?.baseAlpha ?? 1.0);
		
		var actualHitbox:Float = hitbox * earlyHitMult;
		
		var diff = (strumTime - Conductor.songPosition);
		noteDiff = diff;
		var absDiff = Math.abs(diff);
		canBeHit = absDiff <= actualHitbox;
		if (hitByOpponent) wasGoodHit = true;
		
		if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset && !wasGoodHit) tooLate = true;
		
		if (tooLate && !inEditor)
		{
			if (alpha > 0.3) alpha = 0.3;
		}
	}
	
	override public function destroy()
	{
		if (playField != null) playField.removeNote(this);
		prevNote = null;
		vec3Cache = null;
		defScale.put();
		super.destroy();
	}
	
	// for some reason flixel decides to round the rect? im not sure why you would want that behavior that should be something you do if u want
	override function set_clipRect(rect:FlxRect)
	{
		clipRect = rect;
		if (frames != null) frame = frames.frames[animation.frameIndex];
		return rect;
	}
}
