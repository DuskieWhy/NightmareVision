package funkin.objects.note;

import flixel.group.FlxContainer.FlxTypedContainer;
import flixel.util.FlxSignal.FlxTypedSignal;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.group.FlxGroup.FlxTypedGroup;

import funkin.objects.Character;
import funkin.data.*;

typedef NoteSignal = FlxTypedSignal<(Note, PlayField) -> Void>;

class PlayField extends FlxTypedContainer<StrumNote>
{
	public var _skin:NoteSkin;
	
	public var owner(default, set):Character;
	public var singers:Array<Null<Character>> = [];
	public var quants(default, set):Bool = ClientPrefs.quants;
	
	public var hasChangedSkin:Bool = false;
	
	private function set_quants(value:Bool)
	{
		quants = value;
		
		for (i in members)
		{
			if (i != null)
			{
				i.isQuant = quants;
				i.reloadNote();
			}
		}
		
		return value;
	}
	
	private function set_owner(value:Character)
	{
		owner = value;
		
		singers.remove(owner);
		singers.unshift(owner);
		
		return value;
	}
	
	public var onNoteHit:NoteSignal = new NoteSignal();
	public var onNoteMiss:NoteSignal = new NoteSignal();
	public var onMissPress:FlxTypedSignal<Int->Void> = new FlxTypedSignal<Int->Void>();
	
	public var playAnims:Bool = true;
	public var noteSplashes:Bool = false;
	public var autoPlayed:Bool = false;
	public var isPlayer:Bool = false;
	public var playerControls:Bool = false;
	public var inControl(default, set):Bool = true; // incase you want to lock up the playfield
	
	public var trackNoteSplashes:Bool = true;
	public var trackSustainSplashes:Bool = true; // splash angle follows sustain angle
	
	public var notes:Array<Note> = [];
	public var keyCount(default, set):Int = 0;
	
	public var swagWidth(get, never):Float;
	
	public var showRatings:Bool = false;
	
	public function get_swagWidth()
	{
		return Note.swagWidth;
	}
	
	public var baseX:Float = 0;
	public var baseY:Float = 0;
	public var baseAlpha:Float = 1;
	public var offsetReceptors:Bool = false;
	public var player:Int = 0;
	public var alpha(default, set):Float = 1;
	
	public function set_alpha(value:Float)
	{
		value = FlxMath.bound(value, 0, 1);
		for (strum in members)
		{
			strum.alphaMult = value;
		}
		return alpha = value;
	}
	
	public function set_keyCount(value:Int)
	{
		keyCount = value;
		if (members.length > 0) generateReceptors();
		return keyCount;
	}
	
	public function set_inControl(value:Bool)
	{
		if (!value)
		{
			for (strum in members)
			{
				strum.playAnim("static");
				strum.resetAnim = 0;
			}
		}
		return inControl = value;
	}
	
	public var splashLayer:FlxTypedContainer<FlxTypedContainer<Dynamic>>;
	
	/**
	 * The container that all notesplashes are held in
	 */
	public var grpNoteSplashes:FlxTypedContainer<NoteSplash>;
	
	/**
		The container that all sustain notesplashes are held in
	**/
	public var grpSusSplashes:FlxTypedContainer<SustainSplash>;
	
	public function new(x:Float, y:Float, keyCount:Int = 4, ?who:Character, isPlayer:Bool = false, cpu:Bool = false, ?playerControls:Bool, player:Int = 0, skin:String = 'default',
			?_skinInput:Null<NoteSkin> = null)
	{
		super();
		if (playerControls == null) playerControls = isPlayer;
		
		this.autoPlayed = cpu;
		
		this.owner = who;
		this.isPlayer = isPlayer;
		this.playerControls = playerControls;
		this.player = player;
		
		this.baseX = x;
		this.baseY = y;
		this.keyCount = keyCount;
		
		if (_skinInput != null) this._skin = _skinInput;
		else
		{
			this._skin = new NoteSkin(skin, keyCount, player);
			NoteUtil.noteskins.push(this._skin);
		}
		
		splashLayer = new FlxTypedContainer();
		
		grpNoteSplashes = new FlxTypedContainer<NoteSplash>();
		
		var splash:NoteSplash = new NoteSplash(100, 100, 0, player);
		grpNoteSplashes.add(splash);
		splash.alpha = 0.0;
		
		grpSusSplashes = new FlxTypedContainer<SustainSplash>();
		
		var sus = new SustainSplash(0, 0, 0, 0);
		grpSusSplashes.add(sus);
		sus.alpha = 0.0;
		
		splashLayer.add(grpSusSplashes);
		splashLayer.add(grpNoteSplashes);
		
		this.onNoteHit.add(noteHit);
		this.onNoteMiss.add(noteMiss);
		this.onMissPress.add(noteMissPress);
	}
	
	public function clearReceptors()
	{
		while (members.length > 0)
		{
			var note:StrumNote = members.pop();
			note.kill();
			note.destroy();
		}
	}
	
	public function generateReceptors()
	{
		clearReceptors();
		for (data in 0...keyCount)
		{
			var babyArrow:StrumNote = new StrumNote(player, baseX, baseY, data, this);
			babyArrow.downScroll = ClientPrefs.downScroll;
			babyArrow.alphaMult = alpha;
			add(babyArrow);
			babyArrow.postAddedToGroup();
		}
	}
	
	public function fadeIn(skip:Bool = false)
	{
		for (data in 0...members.length)
		{
			var babyArrow:StrumNote = members[data];
			if (skip) babyArrow.alpha = baseAlpha;
			else
			{
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {alpha: baseAlpha}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * data)});
			}
		}
	}
	
	public function getNotes(dir:Int, ?get:Note->Bool):Array<Note>
	{
		var collected:Array<Note> = [];
		for (note in notes)
		{
			if (note.alive && note.noteData == dir && !note.wasGoodHit && !note.tooLate && note.canBeHit)
			{
				if (get == null || get(note)) collected.push(note);
			}
		}
		return collected;
	}
	
	public function getTapNotes(dir:Int):Array<Note> return getNotes(dir, (note:Note) -> !note.isSustainNote);
	
	public function getHoldNotes(dir:Int):Array<Note> return getNotes(dir, (note:Note) -> note.isSustainNote);
	
	/**
	 * Removes a note from this
	 * @param note 
	 */
	public inline function removeNote(note:Note)
	{
		notes.remove(note);
		note.scale.copyFrom(note.baseScale);
		note.updateHitbox();
		
		if (note.playField == this) note.playField = null;
		
		if (PlayState.instance != null) PlayState.instance.notes.remove(note, true);
	}
	
	public inline function addNote(note:Note)
	{
		notes.push(note);
		
		note.player = player;
		
		// hotswapping catch all
		note.skin = _skin;
		note.texture = _skin.noteTexture;
		note.rgbEnabled = _skin.inEngineColoring;
		note.rgbShader.enabled = note.rgbEnabled;
		
		if (hasChangedSkin) note.updateColors();
		
		note.baseScale.copyFrom(note.scale);
		note.updateHitbox();
		if (note.playField != this || note.playField == null) note.playField = this;
	}
	
	public function forEachAliveNote(func:Note->Void)
	{
		for (note in notes)
			if (note != null && note.exists && note.alive) func(note);
	}
	
	inline function disposeNote(note:Note):Void
	{
		removeNote(note);
		
		note.kill();
		note.destroy();
	}
	
	public function noteHit(note:Note, field:PlayField):Void
	{
		var scriptFunc:String = '';
		if (field.playerControls) scriptFunc = 'goodNoteHit';
		else scriptFunc = field.ID == 1 ? 'opponentNoteHit' : 'extraNoteHit';
		
		final scriptArgs:Array<Dynamic> = [note, field.ID];
		
		PlayState.instance.scripts.call('${scriptFunc}Pre', scriptArgs);
		
		final strum:StrumNote = field.members[note.noteData];
		if (strum != null)
		{
			strum.lastNote = note;
			strum.playAnim('confirm', true);
			
			if (field.autoPlayed)
			{
				var time:Float = 0.15;
				if (note.isSustainNote && !note.isSustainEnd) time += 0.15;
				time /= PlayState.instance.playbackRate;
				
				strum.resetAnim = time;
			}
		}
		
		if (!note.isSustainNote)
		{
			for (sustain in note.tail)
				sustain.blockHit = false; // makes the hold note active when you press the base note
		}
		
		if (field.playerControls)
		{
			if (note.wasGoodHit || field.autoPlayed && (note.ignoreNote || note.hitCausesMiss || note.canMiss)) return;
			
			if (ClientPrefs.hitsoundVolume > 0 && !note.hitsoundDisabled) FlxG.sound.play(Paths.sound('hitsound'), ClientPrefs.hitsoundVolume);
			
			if (note.hitCausesMiss)
			{
				field.onNoteMiss.dispatch(note, field);
				
				note.wasGoodHit = true;
				
				if (!note.isSustainNote) disposeNote(note);
				
				return;
			}
			
			final susMult:Float = (note.isSustainNote ? 1 / PlayState.instance.holdSubdivisions : 1);
			
			PlayState.instance.health += note.hitHealth * PlayState.instance.healthGain * susMult;
		}
		
		var chars:Array<Null<Character>> = note.gfNote ? [PlayState.instance.gf] : field.singers;
		if (note.owner != null) chars = [note.owner];
		
		final noteRows = PlayState.instance.noteRows;
		
		for (char in chars)
		{
			if (note.noAnimation || char == null) continue;
			
			if (!note.hitCausesMiss)
			{
				var daAlt = '';
				if (note.noteType == 'Alt Animation') daAlt = '-alt';
				
				final animToPlay = _skin.singAnimations[Std.int(Math.abs(note.noteData))] + daAlt;
				
				char.holdTimer = 0;
				
				// ghost stuff
				final chord = noteRows[field.ID][note.row];
				
				if (!(char.vSliceSustains && note.isSustainNote))
				{
					if (ClientPrefs.jumpGhosts && char.ghostsEnabled && chord != null && chord.length > 1 && note.noteType != "Ghost Note")
					{
						final animNote = chord[0];
						daAlt = animNote.noteType == 'Alt Animation' ? '-alt' : '';
						final realAnim = _skin.singAnimations[Std.int(Math.abs(animNote.noteData))] + daAlt;
						
						if (char.mostRecentRow != note.row) char.playAnim(realAnim, true);
						
						if (note.nextNote != null && note.prevNote != null)
						{
							if (note != animNote && !note.nextNote.isSustainNote) char.playGhostAnim(chord.indexOf(note), animToPlay, true);
							else if (note.nextNote.isSustainNote)
							{
								char.playAnim(realAnim, true);
								char.playGhostAnim(chord.indexOf(note), animToPlay, true);
							}
						}
						char.mostRecentRow = note.row;
					}
					else
					{
						if (note.noteType != "Ghost Note") char.playAnim(animToPlay, true);
						else char.playGhostAnim(note.noteData, animToPlay, true);
					}
				}
				
				switch (note.noteType)
				{
					case 'Hey!' if (char.animation.exists('hey')):
						char.playAnimForDuration('hey', 0.6);
						char.specialAnim = true;
				}
			}
			else
			{
				switch (note.noteType)
				{
					case 'Hurt Note' if (char.animation.exists('hurt')):
						char.playAnim('hurt', true);
						char.specialAnim = true;
				}
			}
		}
		
		note.wasGoodHit = true;
		
		var ratingThing:funkin.game.Rating = funkin.game.Rating.judgeNote(note, Math.abs(note.strumTime - Conductor.songPosition + ClientPrefs.ratingOffset) / PlayState.instance?.playbackRate);
		final splashCheck = (playerControls ? ratingThing.name == 'sick' || ratingThing.name == 'epic' : true);
		
		if (splashCheck) spawnSplash(note);
		spawnSusSplash(note, field.playerControls);
		
		final globalScript = PlayState.instance.callNoteTypeScript(note.noteType, 'hit', scriptArgs);
		
		final noteScriptRet = PlayState.instance.callNoteTypeScript(note.noteType, scriptFunc, scriptArgs);
		if (noteScriptRet != ScriptConstants.STOP_FUNC) PlayState.instance.scripts.call(scriptFunc, scriptArgs, false, [note.noteType]);
		
		if (!note.isSustainNote) disposeNote(note);
	}
	
	function noteMiss(note:Note, field:PlayField):Void
	{
		final susMult:Float = (note.isSustainNote ? 1 / PlayState.instance.holdSubdivisions : 1);
		
		PlayState.instance.health -= note.missHealth * PlayState.instance.healthLoss * susMult;
		
		for (owner in field.singers)
		{
			var char:Character = owner;
			if (note.gfNote) char = PlayState.instance.gf;
			
			if (char != null && !note.noMissAnimation)
			{
				if (char.animTimer <= 0)
				{
					var daAlt = '';
					if (note.noteType == 'Alt Animation') daAlt = '-alt';
					
					var animToPlay:String = _skin.singAnimations[Std.int(Math.abs(note.noteData))] + 'miss' + daAlt;
					char.playAnim(animToPlay, true);
				}
			}
		}
		
		final scriptArgs:Array<Dynamic> = [note, field.ID];
		
		final noteScriptRet = PlayState.instance.callNoteTypeScript(note.noteType, 'noteMiss', scriptArgs);
		if (noteScriptRet != ScriptConstants.STOP_FUNC) PlayState.instance.scripts.call('noteMiss', scriptArgs, false, [note.noteType]);
		
		// hold note missing stuff, makes the hold unhittable (and kills it, might make it just transparent if i can fix some stuff)
		if (!note.hitCausesMiss && !note.canMiss)
		{
			final tail = (note.isSustainNote ? note.parent.tail : note.tail);
			for (sustain in tail)
			{
				sustain.blockHit = true;
				sustain.ignoreNote = true;
				sustain.alphaMod *= 0.3;
			}
		}
		
		// if the sustain splash exists, KILL KIL KILL IT KILL KI L KLLK LSKD:LKLK
		for (i in grpSusSplashes.members)
		{
			if (i.data == note.noteData)
			{
				// actually.. no need to kill it.. itll kill itself anwyays
				i.alpha = 0.0;
				i.visible = false;
			}
		}
		
		note.alphaMod *= 0.3;
	}
	
	function noteMissPress(key:Int):Void
	{
		if (ClientPrefs.ghostTapping) return;
		
		final char = PlayState.instance.playerStrums?.owner ?? PlayState.instance.boyfriend;
		var gf = PlayState.instance.gf;
		
		if (!char.stunned)
		{
			PlayState.instance.health -= 0.05 * PlayState.instance.healthLoss;
			
			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
			
			if (char.animTimer <= 0) char.playAnim(_skin.singAnimations[Std.int(Math.abs(key))] + 'miss', true);
		}
	}
	
	public function spawnSplash(note:Note):NoteSplash
	{
		if (ClientPrefs.noteSplashes
			&& note != null
			&& !note.hitCausesMiss
			&& !note.isSustainNote
			&& !note.noteSplashDisabled
			&& noteSplashes
			&& _skin?.splashesEnabled ?? true)
		{
			final strum:Null<StrumNote> = note.playField.members[note.noteData];
			if (strum != null)
			{
				final data = note.noteData;
				final skin:String = _skin.splashTexture;
				final colors = note.reColor;
				
				var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
				splash.setupNoteSplash(strum, note, skin, colors, this);
				grpNoteSplashes.add(splash);
				
				PlayState.instance.scripts.call('onSpawnNoteSplash', [splash, note]);
				
				return note.noteSplash = splash;
			}
		}
		
		return null;
	}
	
	public function spawnSusSplash(note:Note, isPlayer:Bool = false):SustainSplash
	{
		if (_skin?.sustainSplashes && note.tail.length > 0)
		{
			final strum:Null<StrumNote> = note.playField.members[note.noteData];
			if (strum != null)
			{
				final data = note.noteData;
				final colors = note.reColor;
				
				// sustain length + step length (all in ms) to time the ending of the sustain covering
				final time = ((note.sustainLength + (Conductor.stepCrotchet * 1.25)) / 1000);
				
				var splash:SustainSplash = grpSusSplashes.recycle(SustainSplash);
				splash.setupSplash(strum, note, time, isPlayer, colors, this);
				grpSusSplashes.add(splash);
				
				PlayState.instance.scripts.call('onSpawnSustainSplash', [splash, note]);
				
				return note.sustainSplash = splash;
			}
		}
		
		return null;
	}
	
	public inline function canInput():Bool
	{
		return (playerControls && inControl && !autoPlayed && (owner == null || !owner.stunned));
	}
	
	override function destroy()
	{
		onNoteHit.removeAll();
		onNoteHit.destroy();
		
		onNoteMiss.removeAll();
		onNoteMiss.destroy();
		
		onMissPress.removeAll();
		onMissPress.destroy();
		
		super.destroy();
	}
	
	public function changeSkin(newSkin:NoteSkin)
	{
		_skin = newSkin;
		NoteUtil.noteskins[player] = newSkin;
		
		// that way it checks the colors and re-assigns
		this.hasChangedSkin = true;
		
		forEachAlive((strum) -> {
			strum.skin = _skin;
			strum.texture = _skin.noteTexture;
			strum.useRGBShader = _skin.inEngineColoring;
			strum.rgbShader.enabled = strum.useRGBShader;
			strum.reloadNote();
			
			strum.playAnim('static');
			strum.resetAnim = 0;
		});
		
		forEachAliveNote((note) -> {
			note.skin = _skin;
			note.texture = _skin.noteTexture;
			note.rgbEnabled = _skin.inEngineColoring;
			note.rgbShader.enabled = note.rgbEnabled;
			note.loadNoteAnims();
			
			note.reloadNote('', note.texture, '');
			
			note.scale.set(_skin.noteScale, _skin.noteScale);
			note.baseScale.copyFrom(note.scale);
			
			note.reColor = NoteUtil.getCurColors(note.noteData, note.quant, note.player);
			note.rgbShader.setColors(note.reColor);
		});
		
		grpNoteSplashes.forEachAlive((splash) -> {
			splash.scale.set(_skin.splashScale, _skin.splashScale);
			splash.baseScale.copyFrom(splash.scale);
			
			splash.rgbShader.enabled = _skin.inEngineColoring;
		});
		grpSusSplashes.forEachAlive((splash) -> {
			splash.scale.set(_skin.susSplashScale, _skin.susSplashScale);
			splash.baseScale.copyFrom(splash.scale);
			
			splash.rgbShader.enabled = _skin.inEngineColoring;
		});
	}
	
	// just because
	override public function toString():String
	{
		var str = 'keys: $keyCount, pos: [x: $baseX, y: $baseY], skin: ${_skin.name}';
		
		if (owner != null && singers.length > 0)
		{
			var _singers = [];
			for (i in singers)
				_singers.push(i?.curCharacter ?? 'dad');
				
			str += ', owner: ${owner?.curCharacter ?? 'dad'}, singers: $_singers';
		}
		
		return '($str)';
	}
}
