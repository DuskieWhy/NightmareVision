package funkin.backend;

import openfl.display.BitmapData;
import openfl.display.Bitmap;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.display.Sprite;

import flixel.FlxG;

/**
	The FPS class provides an easy-to-use monitor to display
	the current frame rate of an OpenFL project
**/
@:nullSafety
class DebugDisplay extends Sprite
{
	public static var instance:Null<DebugDisplay> = null;
	
	public static function init()
	{
		if (FlxG.game?.parent == null || instance != null) return;
		
		instance = new DebugDisplay(10, 3, 0xFFFFFF);
		instance.visible = ClientPrefs.showFPS;
		
		FlxG.game.parent.addChild(instance);
	}
	
	/**
	 * The visualized text showing the current fps
	 */
	final textField:TextField;
	
	/**
	 * The bg for the text
	 */
	final textUnderlay:Bitmap;
	
	/**
	 * If disabled, the fps counter will no longer update visually
	 */
	var canUpdate:Bool = true;
	
	/**
		The current frame rate, expressed using frames-per-second
	**/
	public var currentFPS(default, null):Int = 0;
	
	/**
		The current memory usage (WARNING: this is NOT your total program memory usage, rather it shows the garbage collector memory)
	**/
	public var memoryMegas(get, never):Float;
	
	@:noCompletion var times:Array<Float> = [];
	
	@:noCompletion var deltaTimeout:Float = 0.0;
	
	public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000)
	{
		super();
		
		textUnderlay = new Bitmap();
		textUnderlay.bitmapData = new BitmapData(1, 1, true, 0x6F000000);
		
		textField = new TextField();
		textField.selectable = false;
		textField.mouseEnabled = false;
		textField.defaultTextFormat = new TextFormat("_sans", 14, color);
		textField.autoSize = LEFT;
		textField.multiline = true;
		textField.text = "FPS: ";
		
		addChild(textUnderlay);
		addChild(textField);
		
		this.x = x;
		this.y = y;
		
		FlxG.signals.postStateSwitch.add(() -> updateText = __updateTxt);
	}
	
	// Event Handlers
	override function __enterFrame(deltaTime:Float):Void
	{
		final now:Float = haxe.Timer.stamp() * 1000;
		times.push(now);
		while (times[0] < now - 1000)
			times.shift();
			
		// prevents the overlay from updating every frame, why would you need to anyways @crowplexus
		if (deltaTimeout < 100)
		{
			deltaTimeout += deltaTime;
			return;
		}
		
		currentFPS = times.length < FlxG.updateFramerate ? times.length : FlxG.updateFramerate;
		updateText();
		textUnderlay.width = textField.width + 3;
		textUnderlay.height = textField.height;
		
		deltaTimeout = 0.0;
	}
	
	// rebind this function to set a custom fps counter
	dynamic function updateText():Void
	{
		__updateTxt();
	}
	
	function __updateTxt()
	{
		if (!canUpdate) return;
		
		textField.text = 'FPS: $currentFPS • Memory: ${flixel.util.FlxStringUtil.formatBytes(memoryMegas)}';
		
		textField.textColor = 0xFFFFFFFF;
		if (currentFPS < FlxG.drawFramerate * 0.5) textField.textColor = 0xFFFF0000;
	}
	
	inline function get_memoryMegas():Float
	{
		#if cpp
		return cpp.vm.Gc.memInfo64(cpp.vm.Gc.MEM_INFO_USAGE);
		#else
		return (cast openfl.system.System.totalMemoryNumber : UInt);
		#end
	}
}
