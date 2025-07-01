package funkin.utils;

import openfl.Lib;

import lime.app.Application;

import flash.system.System;

// WIP
// functions used to mess with some window properties for ease
class WindowUtil
{
	public static var monitorResolutionWidth(get, never):Float;
	public static var monitorResolutionHeight(get, never):Float;
	
	static function get_monitorResolutionWidth():Float return openfl.system.Capabilities.screenResolutionX;
	
	static function get_monitorResolutionHeight():Float return openfl.system.Capabilities.screenResolutionY;
	
	public static var defaultAppTitle(get, never):String;
	
	static function get_defaultAppTitle():String return Application.current.meta['name'];
	
	public static function crashTheFuckingGame()
	{
		System.exit(0);
	}
	
	public static function getWindow()
	{
		return Application.current.window;
	}
	
	public static function setTitle(?arg:String, append:Bool = false)
	{
		if (arg == null) arg = defaultAppTitle;
		
		if (append) getWindow().title += arg;
		else getWindow().title = arg;
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
			// if(newWidth == newHeight){
			//     camera.y
			// }
		}
		if (!FlxG.fullscreen)
		{
			FlxG.resizeWindow(newWidth, newHeight);
			FlxG.stage.window.x = Std.int((monitorResolutionWidth - newWidth) / 2);
			FlxG.stage.window.y = Std.int((monitorResolutionHeight - newHeight) / 2);
		}
		
		// else {
		//     FlxG.stage.window.onResize = ()->{
		//         FlxG.resizeWindow(newWidth, newHeight);
		//     }
		// }
		var s = new funkin.backend.FunkinRatioScaleMode();
		s.height = scaledHeight;
		FlxG.scaleMode = s;
	}
	
	public static inline function centerWindowOnPoint(?point:FlxPoint)
	{
		Lib.application.window.x = Std.int(point.x - (Lib.application.window.width / 2));
		Lib.application.window.y = Std.int(point.y - (Lib.application.window.height / 2));
	}
	
	public static inline function getCenterWindowPoint():FlxPoint
	{
		return FlxPoint.get(Lib.application.window.x + (Lib.application.window.width / 2), Lib.application.window.y + (Lib.application.window.height / 2));
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
