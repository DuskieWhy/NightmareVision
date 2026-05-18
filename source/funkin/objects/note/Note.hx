package funkin.objects.note;

import funkin.backend.math.Vector3;

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

class Note extends FunkinSprite implements funkin.game.modchart.IModNote
{
	public static var defaultNotes = ['No Animation', 'GF Sing', ''];
	
	public var row:Int = 0;
	public var lane:Int = 0;
	
	public var noteScript:Null<FunkinScript> = null;
	
	public var visualTime:Float = 0;
	public var visualLength:Float = 0;
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
	public var hitPriority:Int = 1;
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
	
	// 0 to 1, 1 = missed
	public var coyoteProgress:Float = 0;
	
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
	public var reAssignable:Bool = true;
	public var reColor:Array<FlxColor>;
	
	public static var globalRgbShaders:Array<RGBPalette> = [];
	
	public var inEditor:Bool = false;
	public var skipScale:Bool = false;
	public var gfNote:Bool = false;
	
	private var earlyHitMult:Float = 0.5;
	
	@:isVar
	public var daWidth(get, never):Float;
	
	public function get_daWidth()
	{
		return playField == null ? Note.swagWidth : playField.swagWidth;
	}
	
	public static var swagWidth:Float = 160 * 0.7;
	
	public var noteSplashDisabled:Bool = false;
	public var noteSplashHue:Float = 0;
	public var noteSplashSat:Float = 0;
	public var noteSplashBrt:Float = 0;
	
	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var offsetAngle:Float = 0;
	public var multAlpha:Float = 1;
	public var multSpeed:Float = 1;
	
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
	public var prefix:String = '';
	public var suffix:String = '';
	
	public var noAnimation:Bool = false;
	public var noMissAnimation:Bool = false;
	public var hitCausesMiss:Bool = false;
	public var canMiss:Bool = false;
	public var distance:Float = 2000; // plan on doing scroll directions soon -bb
	
	public var hitsoundDisabled:Bool = false;
	
	public var player:Int = 0;
	
	public var owner:Character = null;
	public var playField(default, set):PlayField;
	public var sustainSplash:SustainSplash = null;
	public var noteSplash:NoteSplash = null;
	
	public var skin:NoteSkin;
	
	public var animSuffix = '';
	
	public function set_playField(field:PlayField)
	{
		if (playField != field)
		{
			if (playField != null && playField.notes.contains(this)) playField.removeNote(this);
			
			if (field != null && !field.notes.contains(this)) field.addNote(this);
		}
		return playField = field;
	}
	
	private function set_texture(value:String):String
	{
		if (texture == value) return texture;
		
		reloadNote('', value);
		
		return (texture = value);
	}
	
	private function set_noteType(value:String):String
	{
		noteScript = null;
		
		if (noteData > -1 && noteType != value)
		{
			switch (value)
			{
				case 'Alt Animation':
					animSuffix = '-alt';
				case 'Hurt Note':
					hitPriority = 0;
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
					// else noteScript = ChartEditorState.instance.notetypeScripts.get(value);
					
					if (noteScript != null) noteScript.executeFunc("setupNote", [this], this);
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
		
		if (ClientPrefs.quants && canQuant)
		{
			var beat = Conductor.getBeat(strumTime);
			if (prevNote != null && isSustainNote) quant = prevNote.quant;
			else quant = NoteUtil.getQuant(beat);
		}
		this.inEditor = inEditor;
		
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
			rgbShader = NoteUtil.initRGBShader(this, noteData, quant, player);
			rgbEnabled = NoteUtil.getSkinFromID(player)?.inEngineColoring ?? false;
			
			reColor = NoteUtil.getCurColors(noteData, quant, player);
			
			texture = '';
			
			if (!isSustainNote) playAnim(animation.exists('scroll') ? 'scroll' : 'scroll$noteData');
		}
		
		if (prevNote != null) prevNote.nextNote = this;
		
		if (isSustainNote && prevNote != null)
		{
			hitsoundDisabled = true;
			
			copyAngle = false;
			
			playAnim(animation.exists('holdend') ? 'holdend' : 'holdend$noteData');
			isSustainEnd = true;
			updateHitbox();
			
			animSuffix = prevNote.animSuffix;
			
			missHealth = 0.0475;
			
			if (prevNote.isSustainNote)
			{
				prevNote.playAnim(animation.exists('hold') ? 'hold' : 'hold$noteData');
				prevNote.isSustainEnd = false;
				
				prevNote.updateHitbox();
			}
		}
		else if (!isSustainNote) earlyHitMult = 1;
		
		baseScale.copyFrom(scale);
	}
	
	var lastNoteOffsetXForPixelAutoAdjusting:Float = 0;
	var lastNoteScaleToo:Float = 1;
	
	public var originalHeightForCalcs:Float = 6;
	
	public function reloadNote(?_prefix:String = '', ?_texture:String = '', ?_suffix:String = '')
	{
		// Fix null values
		if (_prefix == null) _prefix = '';
		if (_texture == null) _texture = '';
		if (_suffix == null) _suffix = '';
		
		// Save prefix/suffix only if provided
		if (_prefix.length > 0) this.prefix = _prefix;
		if (_suffix.length > 0) this.suffix = _suffix;
		
		if (noteScript != null) if (noteScript.executeFunc("onReloadNote", [this, _prefix, _texture, _suffix], this) == ScriptConstants.STOP_FUNC) return;
		
		skin ??= NoteUtil.getSkinFromID(player);
		
		rgbShader.setColors(reColor);
		
		var _skin:String = _texture;
		if (_skin.length < 1)
		{
			_skin = skin?.noteTexture;
			if (_skin == null || _skin.length < 1) _skin = 'NOTE_assets';
		}
		
		var animName:String = null;
		if (animation.curAnim != null) animName = animation.curAnim.name;
		
		var arraySkin:Array<String> = _skin.split('/');
		var lastIndex:Int = arraySkin.length - 1;
		
		arraySkin[lastIndex] = this.prefix + arraySkin[lastIndex] + this.suffix;
		
		var atlasPath:String = arraySkin.join('/');
		
		isQuant = ClientPrefs.quants && (skin?.quantsEnabled ?? true) && canQuant;
		
		frames = Paths.getSparrowAtlas(atlasPath);
		loadNoteAnims();
		
		if (animName != null) playAnim(animName, true);
		
		if (inEditor && !skipScale) setGraphicSize(ChartEditorState.GRID_SIZE, ChartEditorState.GRID_SIZE);
		
		baseScale.copyFrom(scale);
		
		updateHitbox();
		
		antialiasing = skin?.antialiasing ?? true;
		
		x += swagWidth * (noteData % (skin?.keys ?? 4));
		
		if (noteScript != null) noteScript.executeFunc("postReloadNote", [this, _prefix, _texture, _suffix], this);
	}
	
	public override function playAnim(anim:String, force:Bool = false, isReversed:Bool = false, frame:Int = 0)
	{
		super.playAnim(anim, force, isReversed, frame);
		
		centerOffsets();
		centerOrigin();
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
	
	function _loadNoteAnims()
	{
		final noteAnims = skin.noteAnims;
		final directionAnims = noteAnims[noteData % noteAnims.length];
		
		for (anim in directionAnims)
		{
			addAnimByPrefix(anim.anim, '${anim.xmlName}0', anim.fps, true);
			addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
		}
		
		setGraphicSize(Std.int(width * skin.noteScale));
		
		baseScale.copyFrom(scale);
	}
	
	public function updateColors()
	{
		if (!reAssignable) return;
		
		reColor = NoteUtil.getCurColors(noteData, quant, player);
		rgbShader.setColors(reColor);
	}
	
	// SPECIFICALLY for note types, only use if u 100% do not want to have ur note re-colored
	public function setCustomColor(color:Array<FlxColor>)
	{
		var fallback = NoteUtil.getCurColors(noteData, quant, player);
		
		reColor = fallback;
		if (color != null || color.length == skin?.keys ?? 4)
		{
			reAssignable = false;
			reColor = color;
		}
		rgbShader.setColors(reColor);
	}
	
	public function clip(strum:StrumNote)
	{
		if (strum.sustainReduce && wasGoodHit && Conductor.songPosition >= strumTime)
		{
			final x:Float = (x - strum.x - (strum.width - width) * .5), y:Float = (y - strum.y - strum.height * .5);
			final mag:Float = Math.sqrt(x * x + y * y);
			
			var swagRect:FlxRect = getRect();
			
			swagRect.y = (mag / scale.y);
			swagRect.height -= swagRect.y;
			
			clipRect = swagRect;
		}
	}
	
	inline function getRect()
	{
		final rect = (clipRect ?? new FlxRect());
		
		rect.x = 0;
		rect.y = 0;
		rect.width = frameWidth;
		rect.height = frameHeight;
		
		return rect;
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
		
		if (rgbShader != null)
		{
			rgbShader.enabled = rgbEnabled;
			
			rgbShader.alphaMult = (alphaMod * alphaMod2) * (playField?.baseAlpha ?? 1.0);
		}
		
		var actualHitbox:Float = hitbox * earlyHitMult;
		
		var diff = (strumTime - Conductor.songPosition);
		noteDiff = diff;
		var absDiff = Math.abs(diff);
		canBeHit = absDiff <= actualHitbox;
		
		if (!isSustainNote) if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset && !wasGoodHit) tooLate = true;
		else if (parent != null) // coyote timer
			if (parent.coyoteProgress >= 1 && !wasGoodHit) tooLate = true;
			
		if (tooLate && !inEditor)
		{
			if (alpha > 0.3) alpha = 0.3;
		}
	}
	
	override public function destroy()
	{
		if (playField != null) playField.removeNote(this);
		prevNote = null;
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
