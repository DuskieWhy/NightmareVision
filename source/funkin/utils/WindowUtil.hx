package funkin.utils;

import openfl.Lib;

import lime.app.Application;

// WIP
// functions used to mess with some window properties for ease
class WindowUtil
{
	public static var monitorResolutionWidth(get, never):Float;
	public static var monitorResolutionHeight(get, never):Float;
	
	static function get_monitorResolutionWidth():Float return FlxG.stage.window.display.bounds.width;
	
	static function get_monitorResolutionHeight():Float return FlxG.stage.window.display.bounds.height;
	
	public static var defaultAppTitle(get, never):String;
	
	static function get_defaultAppTitle():String return Application.current.meta['name'];
	
	public static function setTitle(?arg:String, append:Bool = false)
	{
		if (arg == null) arg = defaultAppTitle;
		
		if (append) FlxG.stage.window.title += arg;
		else FlxG.stage.window.title = arg;
	}
	
	public static function setGameDimensions(width:Int, height:Int, cameras:Array<FlxCamera>)
	{
		var newWidth:Int = width;
		var newHeight:Int = height;
		var scaledHeight:Int = height;
		
		for (camera in cameras)
		{
			camera.width = FlxG.width;
			if (newHeight <= FlxG.height)
			{
				camera.height = Std.int(FlxG.height * (FlxG.width / newHeight));
				scaledHeight = camera.height;
			}
		}
		if (!FlxG.fullscreen)
		{
			FlxG.resizeWindow(newWidth, newHeight);
			FlxG.stage.window.x = Std.int((monitorResolutionWidth - newWidth) / 2);
			FlxG.stage.window.y = Std.int((monitorResolutionHeight - newHeight) / 2);
		}

		var s = new funkin.backend.FunkinRatioScaleMode();
		s.height = scaledHeight;
		FlxG.scaleMode = s;
	}
	
	public static inline function centerWindowOnPoint(?point:FlxPoint)
	{
		FlxG.stage.window.x = Std.int(point.x - (FlxG.stage.window.width / 2));
		FlxG.stage.window.y = Std.int(point.y - (FlxG.stage.window.height / 2));
	}
	
	public static inline function getCenterWindowPoint():FlxPoint
	{
		return FlxPoint.weak(FlxG.stage.window.x + (FlxG.stage.window.width / 2), FlxG.stage.window.y + (FlxG.stage.window.height / 2));
	}
	
	public static function exit()
	{
		openfl.system.System.exit(0);
	}
	
	#if FEATURE_DEBUG_TRACY
	/**
	 * Initialize the tracy profiler
	 * taken from base gamehttps://github.com/FunkinCrew/Funkin/blob/main/source/funkin/util/WindowUtil.hx
	 */
	public static function initTracy():Void
	{
		// Apply a marker to indicate frame end for the Tracy profiler.
		//  Do this only if Tracy is configured to prevent lag.
		openfl.Lib.current.stage.addEventListener(openfl.events.Event.EXIT_FRAME, (e:openfl.events.Event) -> {
			cpp.vm.tracy.TracyProfiler.frameMark();
		});
		
		cpp.vm.tracy.TracyProfiler.setThreadName("main");
	}
	#end
}
