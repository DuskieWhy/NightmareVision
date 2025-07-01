package funkin.objects;

import flixel.util.FlxSignal.FlxTypedSignal;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.group.FlxGroup.FlxTypedGroup;

import funkin.objects.character.Character;

typedef NoteSignal = FlxTypedSignal<(Note, PlayField) -> Void>;

// playfields should get a rework
// i feel more actual note handling should happen in here

class PlayField extends FlxTypedGroup<StrumNote>
{
	public var owner:Character;
	public var noteHitCallback:NoteSignal = new NoteSignal();
	public var noteMissCallback:NoteSignal = new NoteSignal();
	public var playAnims:Bool = true;
	public var autoPlayed:Bool = false;
	public var isPlayer:Bool = false;
	public var playerControls:Bool = false;
	public var inControl(default, set):Bool = true; // incase you want to lock up the playfield
	
	public var notes:Array<Note> = [];
	public var keyCount(default, set):Int = 0;
	@:isVar
	public var swagWidth(get, null):Float;
	
	public function get_swagWidth()
	{
		return Note.swagWidth * scale;
	}
	
	public var baseX:Float = 0;
	public var baseY:Float = 0;
	public var baseAlpha:Float = 1;
	public var offsetReceptors:Bool = false;
	public var player:Int = 0;
	public var scale(default, set):Float = 1;
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
	
	public function set_scale(value:Float)
	{
		for (strum in members)
		{
			var anim:String = '';
			if (strum.animation.curAnim != null) anim = strum.animation.curAnim.name;
			strum.playAnim("static", true);
			strum.setGraphicSize(Std.int(strum.frameWidth * 0.7 * value));
			strum.updateHitbox();
			strum.playAnim(anim, true);
		}
		for (note in notes)
		{
			if (note.isSustainNote) note.scale.set(note.baseScaleX * value, note.baseScaleY);
			else note.scale.set(note.baseScaleX * value, note.baseScaleY * value);
			
			note.defScale.copyFrom(note.scale);
			note.updateHitbox();
		}
		return scale = value;
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
	
	public function new(x:Float, y:Float, keyCount:Int = 4, ?who:Character, isPlayer:Bool = false, cpu:Bool = false, ?playerControls:Bool, player:Int = 0)
	{
		super();
		if (playerControls == null) playerControls = isPlayer;
		autoPlayed = cpu;
		owner = who;
		this.isPlayer = isPlayer;
		this.playerControls = playerControls;
		this.player = player;
		
		baseX = x;
		baseY = y;
		this.keyCount = keyCount;
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
	
	public function generateReceptors(?x:Float)
	{
		clearReceptors();
		for (data in 0...keyCount)
		{
			var babyArrow:StrumNote = new StrumNote(player, baseX, baseY, data, this);
			babyArrow.setGraphicSize(Std.int(babyArrow.width * scale));
			babyArrow.updateHitbox();
			babyArrow.downScroll = ClientPrefs.downScroll;
			babyArrow.alphaMult = alpha;
			add(babyArrow);
			babyArrow.postAddedToGroup();
			if (offsetReceptors) doReceptorOffset(babyArrow);
		}
	}
	
	public function doReceptorOffset(babyArrow:StrumNote)
	{
		if (offsetReceptors)
		{
			if (babyArrow.noteData > 1)
			{
				babyArrow.x += swagWidth * 3;
			}
			else
			{
				babyArrow.x -= swagWidth * 3;
			}
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
	
	inline public function remNote(note:Note)
	{
		notes.remove(note);
		note.scale.set(note.baseScaleX, note.baseScaleY);
		note.defScale.copyFrom(note.scale);
		note.updateHitbox();
		if (note.playField == this) note.playField = null;
	}
	
	inline public function addNote(note:Note)
	{
		notes.push(note);
		if (note.isSustainNote) note.scale.set(note.baseScaleX * scale, note.baseScaleY);
		else note.scale.set(note.baseScaleX * scale, note.baseScaleY * scale);
		
		note.defScale.copyFrom(note.scale);
		note.updateHitbox();
		if (note.playField != this) note.playField = this;
	}
	
	public function forEachNote(callback:Note->Void)
	{
		var i:Int = 0;
		var note:Note = null;
		
		while (i < notes.length)
		{
			note = notes[i++];
			
			if (note != null && note.exists && note.alive) callback(note);
		}
	}
	
	override function destroy()
	{
		noteHitCallback.removeAll();
		noteHitCallback.destroy();
		
		noteMissCallback.removeAll();
		noteMissCallback.destroy();
		
		super.destroy();
	}
}
