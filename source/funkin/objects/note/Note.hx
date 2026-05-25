package funkin.objects.note;

import funkin.backend.math.Vector3;

import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;

import funkin.data.*;
import funkin.game.shaders.*;
import funkin.game.shaders.RGBShader;
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

abstract QueueNote(Array<Dynamic>) to Array<Dynamic>
{
	public function new(strumTime:Float, sustainLength:Float, noteData:Int, noteType:Null<String>, isSustainNote:Bool = false, playField:Int = 0)
	{
		this = [strumTime, sustainLength, noteData, noteType, isSustainNote, false, playField, false, null];
	}
	
	public var strumTime(get, set):Float;
	public var sustainLength(get, set):Float;
	public var noteData(get, set):Int;
	public var noteType(get, set):Null<String>;
	public var isSustainNote(get, set):Bool;
	public var isSustainEnd(get, set):Bool;
	public var playField(get, set):Int;
	public var gfNote(get, set):Bool;
	public var tail(get, set):Null<Array<QueueNote>>;
	
	function get_strumTime():Float return this[0];
	
	function get_sustainLength():Float return this[1];
	
	function get_noteData():Int return this[2];
	
	function get_noteType():Null<String> return this[3];
	
	function get_isSustainNote():Bool return this[4];
	
	function get_isSustainEnd():Bool return this[5];
	
	function get_playField():Int return this[6];
	
	function get_gfNote():Bool return this[7];
	
	function get_tail():Null<Array<QueueNote>> return this[8];
	
	function set_strumTime(v:Float):Float return this[0] = v;
	
	function set_sustainLength(v:Float):Float return this[1] = v;
	
	function set_noteData(v:Int):Int return this[2] = v;
	
	function set_noteType(v:Null<String>):Null<String> return this[3] = v;
	
	function set_isSustainNote(v:Bool):Bool return this[4] = v;
	
	function set_isSustainEnd(v:Bool):Bool return this[5] = v;
	
	function set_playField(v:Int):Int return this[6] = v;
	
	function set_gfNote(v:Bool):Bool return this[7] = v;
	
	function set_tail(v:Null<Array<QueueNote>>):Null<Array<QueueNote>> return this[8] = v;
}

abstract NoteSharedTailState(Array<Dynamic>) to Array<Dynamic>
{
	public function new(parent:Note)
	{
		this = [parent, [], null, false];
	}
	
	public var parent(get, set):Note;
	public var tail(get, set):Array<Note>;
	public var splash(get, set):Null<SustainSplash>;
	public var missed(get, set):Bool;
	
	function get_parent():Note return this[0];
	
	function get_tail():Array<Note> return this[1];
	
	function get_splash():Null<SustainSplash> return this[2];
	
	function get_missed():Bool return this[3];
	
	function set_parent(v:Note):Note return this[0] = v;
	
	function set_tail(v:Array<Note>):Array<Note> return this[1] = v; // well this one is useless
	
	function set_splash(v:Null<SustainSplash>):Null<SustainSplash> return this[2] = v;
	
	function set_missed(v:Bool):Bool return this[3] = v;
}

class Note extends FunkinSprite implements funkin.game.modchart.IModNote
{
	public static var defaultNotes = ['No Animation', 'GF Sing', ''];
	
	var queueNote:Null<QueueNote> = null;
	
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
	
	// shared between a note and its tail to prevent some issues
	// its kind of  fuking stupid theres probably some other way to fix it but i cant think rn
	public var tailState:NoteSharedTailState;
	
	public var tail:Array<Note> = []; // for sustains
	public var parent:Null<Note> = null;
	
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
	
	public var rgbGraphics:RGBGraphics;
	public var rgbEnabled:Bool = true;
	public var reAssignable:Bool = true;
	
	public var inEditor:Bool = false;
	public var skipScale:Bool = false;
	public var gfNote:Bool = false;
	
	public var earlyHitMult:Float = 1;
	
	@:isVar
	public var daWidth(get, never):Float;
	
	inline function get_daWidth():Float return (playField == null ? Note.swagWidth : playField.swagWidth);
	
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
	public var singers:Array<Character> = null;
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
		
		switch (value)
		{
			case 'Alt Animation':
				animSuffix = '-alt';
				
			case 'Hurt Note':
				hitPriority = 0;
				ignoreNote = mustPress;
				missHealth = isSustainNote ? 0.1 : 0.3;
				hitCausesMiss = true;
				setCustomColor([0xFF101010, 0xFFFF0000, 0xFF990022]);
				
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
		}
		
		if (hitCausesMiss) canMiss = true;
		
		return noteType = value;
	}
	
	public function new(strumTime:Float = 0, noteData:Int = 0, ?prevNote:Note, sustainNote:Bool = false, inEditor:Bool = false, player:Int = 0)
	{
		super();
		
		this.player = player;
		this.prevNote = prevNote;
		this.isSustainNote = sustainNote;
		this.strumTime = strumTime;
		this.noteData = noteData;
		this.inEditor = inEditor;
		
		rgbEnabled = (NoteUtil.getSkinFromID(player)?.inEngineColoring ?? false);
		
		_resetTexture();
	}
	
	public inline function _reset():Void
	{
		exists = true;
		alive = true;
		garbage = spawned = false;
		reAssignable = true;
		
		hitPriority = 1;
		hitHealth = .023;
		missHealth = .0475;
		coyoteProgress = 0;
		
		noAnimation = noMissAnimation = ratingDisabled = hitCausesMiss = false;
		
		ignoreNote = canBeHit = tooLate = wasGoodHit = noteWasHit = hitByOpponent = false;
		
		owner = null;
		singers?.resize(0);
		
		tail.resize(0);
		sustainSplash = null;
		noteSplash = null;
		nextNote = null;
		clipRect = null;
		alpha = 1;
	}
	
	inline function get_tail():Array<Note> return tailState.tail;
	
	inline function _resetTexture():Void
	{
		if (ClientPrefs.quants && canQuant) quant = (prevNote?.quant ?? NoteUtil.getQuant(Conductor.getBeat(strumTime)));
		
		rgbGraphics = NoteUtil.getCurColors(noteData, quant, player);
		rgbEnabled = NoteUtil.getSkinFromID(player)?.inEngineColoring ?? false;
		
		updateColors();
		
		prefix = suffix = animSuffix = texture = '';
		
		playAnim(getDefaultAnim(), true);
		updateHitbox();
		
		baseScale.copyFrom(scale);
	}
	
	public function preRecycle(?queueNote:QueueNote, ?parent:Note, ?prevNote:Note):Void
	{
		_reset();
		
		this.parent = parent;
		
		if (parent != null)
		{
			tailState = parent.tailState;
			parent.coyoteProgress = 0;
		}
		else if (tailState == null || tailState.tail.length > 0)
		{
			tailState = new NoteSharedTailState(this);
		}
		else
		{
			tailState.missed = false;
			tailState.splash = null;
		}
		
		if (prevNote != null)
		{
			this.prevNote = prevNote;
			prevNote.nextNote = this;
		}
		
		if (queueNote != null)
		{
			this.queueNote = queueNote;
			
			gfNote = queueNote.gfNote;
			noteData = queueNote.noteData;
			isSustainEnd = queueNote.isSustainEnd;
			isSustainNote = queueNote.isSustainNote;
			player = lane = queueNote.playField;
			
			strumTime = queueNote.strumTime;
			sustainLength = queueNote.sustainLength;
		}
		
		mustPress = (player == 0);
		blockHit = isSustainNote;
		
		hitsoundDisabled = isSustainNote;
		
		_resetTexture();
		
		if (queueNote != null) noteType = queueNote.noteType;
		
		if (!inEditor) strumTime += ClientPrefs.noteOffset;
		
		updateVisualTime();
	}
	
	public function postRecycle():Void
	{
		noteScript?.executeFunc('setupNote', [this], this);
	}
	
	public inline function updateVisualTime():Void
	{
		visualTime = PlayState.instance.getNoteInitialTime(strumTime);
		visualLength = (PlayState.instance.getNoteInitialTime(strumTime + sustainLength) - visualTime);
	}
	
	public inline function getDefaultAnim():String
	{
		var anim:String = (isSustainNote ? (isSustainEnd ? 'holdend' : 'hold') : 'scroll');
		
		return (animation.exists('$anim$noteData') ? '$anim$noteData' : anim);
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
		
		var _skin:String = _texture;
		if (_skin.length < 1)
		{
			_skin = skin?.noteTexture;
			if (_skin == null || _skin.length < 1) _skin = 'NOTE_assets';
		}
		
		var animName:String = (animation.name ?? getDefaultAnim());
		
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
		
		rgbGraphics = NoteUtil.getCurColors(noteData, quant, player);
	}
	
	// SPECIFICALLY for note types, only use if u 100% do not want to have ur note re-colored
	public function setCustomColor(color:Array<FlxColor>)
	{
		var fallback = NoteUtil.getCurColors(noteData, quant, player);
		
		rgbGraphics = fallback;
		if (color != null || color.length == skin?.keys ?? 4)
		{
			reAssignable = false;
			rgbGraphics.setColors(color);
		}
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
	
	var _cacheRect:Null<FlxRect> = null; // jsut for pooling
	
	inline function getRect()
	{
		final rect = (clipRect ?? _cacheRect ?? (_cacheRect = FlxRect.get()));
		
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
			noteScript?.executeFunc("update", [this, elapsed], this);
		}
		
		if (rgbGraphics != null)
		{
			rgbGraphics.enabled = rgbEnabled;
			
			rgbGraphics.alpha = (alphaMod * alphaMod2) * (playField?.baseAlpha ?? 1.0);
		}
		
		var actualHitbox:Float = hitbox * earlyHitMult;
		
		var diff = (strumTime - Conductor.songPosition);
		noteDiff = diff;
		var absDiff = Math.abs(diff);
		canBeHit = absDiff <= actualHitbox;
		
		// file auto-formatting completely broke the coyote timer LOL
		// so unfortunately you will have to deal with this really ugly formatting
		if (!isSustainNote)
		{
			if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset && !wasGoodHit) tooLate = true;
		}
		else if (parent != null) // coyote timer
		{
			if (parent.coyoteProgress >= 1 && !wasGoodHit) tooLate = true;
		}
		
		if (tooLate && !inEditor && alpha > 0.3) alpha = 0.3;
	}
	
	public inline function isLate():Bool
	{
		return (strumTime < Conductor.songPosition - Conductor.safeZoneOffset && !wasGoodHit);
	}
	
	override function drawSimple(camera:FlxCamera)
	{
		super.drawSimple(camera);
		rgbGraphics.pushQuad(camera);
	}
	
	override function drawComplex(camera:FlxCamera)
	{
		super.drawComplex(camera);
		rgbGraphics.pushQuad(camera);
	}
	
	override public function destroy()
	{
		playField?.removeNote(this);
		
		prevNote = nextNote = parent = null;
		tailState = null;
		
		_cacheRect?.put();
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
