package funkin.objects.note;

import funkin.scripts.FunkinScript;

import flixel.math.FlxRect;

// notes desperately need some cleanup and fixes
// this will be properly done eventually probably...

typedef EventNoteAdvanced =
{
	var strumTime:Float;
	var eventName:String;
	var params:Array<Dynamic>;
}

typedef EventNoteLegacy =
{
	/**
	 * The time (miliseconds) that the event will trigger at
	 */
	var strumTime:Float;
	
	/**
	 * The events name
	 */
	var eventName:String;
	
	/**
	 * The events value1
	 */
	var value1:String;
	
	/**
	 * The events value2
	 */
	var value2:String;
}

@:nullSafety
class Note2 extends FlxSprite
{
	/**
	 * The given notes corresponding noteData. from 0-3 in normal circumstances.
	 * 
	 * Event Notes are `-1`
	 */
	public var noteData:Int = 0;
	
	/**
	 * The time (miliseconds) that the note should be hit at.
	 */
	public var strumTime:Float = 0;
	
	/**
	 * When true, the note will be destroyed next cycle.
	 */
	public var garbage:Bool = false;
	
	/**
	 * Attached script for more customizable features.
	 */
	public var script:Null<FunkinScript> = null;
	
	/**
	 * A optional parented playfield.
	 */
	public var playField:Null<PlayField> = null;
	
	public function new()
	{
		super();
	}
	
	/**
	 * Loads a note texture and adds its animations.
	 */
	public function loadNote(tex:String) {}
	
	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}
	
	override function destroy()
	{
		// if (playField != null) playField.removeNote(this);
		super.destroy();
	}
	
	override function set_clipRect(rect:FlxRect) // fix for undesired flixel behavior and rounding FlxRects..
	{
		clipRect = rect;
		if (frames != null) frame = frames.frames[animation.frameIndex];
		return rect;
	}
}
