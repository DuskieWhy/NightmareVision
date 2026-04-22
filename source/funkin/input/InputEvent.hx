package funkin.input;

import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.keyboard.FlxKey;

import funkin.input.Controls.Device;

import openfl.events.EventType;
import openfl.events.Event;

class InputEvent extends Event
{
	public static inline var INPUT_PRESSED:EventType<InputEvent> = "inputDown";
	
	public static inline var INPUT_RELEASED:EventType<InputEvent> = "inputUp";
	
	/**
	 * The note id/direction
	 */
	public var noteData:Int;
	
	/**
	 * The device of this input
	 */
	public var device:Device;
	
	/**
	 * The input ID of this input (FlxKey, FlxGamepadInputID, etc)
	 */
	public var inputID:Int;
	
	/**
	 * A value gotten from `lime.system.System.getTimer()` which tracks the milliseconds since the program has started
	 * You can get the latency with `InputEvent.timer` - System.getTimer()`
	 */
	public var timer:Float;
	
	/**
	 * Creates an `InputEvent`
	 * @param type 
	 * @param bubbles 
	 * @param cancelable 
	 * @param noteData 
	 * @param key 
	 * @param button 
	 */
	public function new(type:EventType<InputEvent>, bubbles:Bool = false, cancelable:Bool = false, noteData:Int, device:Device, inputID:Int, timer:Float)
	{
		super(type, bubbles, cancelable);
		
		this.noteData = noteData;
		this.device = device;
		this.inputID = inputID;
		this.timer = timer;
	}
	
	@:noCompletion override function __init():Void
	{
		super.__init();
		noteData = 0;
		inputID = -1;
		timer = 0;
	}
}
