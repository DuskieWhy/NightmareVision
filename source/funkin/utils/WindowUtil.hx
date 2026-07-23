package funkin.utils;

import lime.app.Application;

import openfl.Lib;

/**
 * Utility class to make accessing window properties a bit easier
 */
@:nullSafety
class WindowUtil
{
	/**
	 * The width of the display in pixels.
	 */
	public static var monitorResolutionWidth(get, never):Float;
	
	/**
	 * The height of the display in pixels.
	 */
	public static var monitorResolutionHeight(get, never):Float;
	
	static function get_monitorResolutionWidth():Float return FlxG.stage.window.display.bounds.width;
	
	static function get_monitorResolutionHeight():Float return FlxG.stage.window.display.bounds.height;
	
	public static var defaultAppTitle(get, never):String;
	
	@:nullSafety(Off)
	static function get_defaultAppTitle():String return Application.current.meta['name'];
	
	/**
	 * The current window width in pixels.
	 */
	public static var windowWidth(get, never):Int;
	
	static inline function get_windowWidth():Int return FlxG.stage.window.width;
	
	/**
	 * The current window height in pixels.
	 */
	public static var windowHeight(get, never):Int;
	
	static inline function get_windowHeight():Int return FlxG.stage.window.height;
	
	/**
	 * The current `x` position of the window on the screen.
	 */
	public static var windowX(get, set):Int;
	
	static inline function get_windowX():Int return FlxG.stage.window.x;
	
	static inline function set_windowX(value:Int):Int
	{
		FlxG.stage.window.x = value;
		return value;
	}
	
	/**
	 * The current `y` position of the window on the screen.
	 */
	public static var windowY(get, set):Int;
	
	static inline function get_windowY():Int return FlxG.stage.window.y;
	
	static inline function set_windowY(value:Int):Int
	{
		FlxG.stage.window.y = value;
		return value;
	}
	
	/**
	 * Gets or sets the window's borderless state.
	 */
	public static var borderless(get, set):Bool;
	
	static inline function get_borderless():Bool return FlxG.stage.window.borderless;
	
	static inline function set_borderless(value:Bool):Bool
	{
		FlxG.stage.window.borderless = value;
		return value;
	}
	
	/**
	 * Gets or sets the window opacity. Range is `0.0` (invisible) to `1.0` (fully opaque).
	 * 
	 * Note: Not supported on all platforms.
	 */
	public static var opacity(get, set):Float;
	
	static inline function get_opacity():Float return FlxG.stage.window.opacity;
	
	static inline function set_opacity(value:Float):Float
	{
		FlxG.stage.window.opacity = value;
		return value;
	}
	
	/**
	 * Gets or sets the window's minimized state.
	 */
	public static var minimized(get, set):Bool;
	
	static inline function get_minimized():Bool return FlxG.stage.window.minimized;
	
	static inline function set_minimized(value:Bool):Bool
	{
		FlxG.stage.window.minimized = value;
		return value;
	}
	
	/**
	 * Gets or sets the window's maximized state.
	 */
	public static var maximized(get, set):Bool;
	
	static inline function get_maximized():Bool return FlxG.stage.window.maximized;
	
	static inline function set_maximized(value:Bool):Bool
	{
		FlxG.stage.window.maximized = value;
		return value;
	}
	
	/**
	 * Returns a `FlxPoint` representing the monitor's resolution.
	 */
	public static inline function getMonitorResolution():FlxPoint
	{
		return FlxPoint.weak(monitorResolutionWidth, monitorResolutionHeight);
	}
	
	/**
	 * Returns a `FlxPoint` representing the window's current position.
	 */
	public static inline function getWindowPosition():FlxPoint
	{
		return FlxPoint.weak(FlxG.stage.window.x, FlxG.stage.window.y);
	}
	
	/**
	 * Returns a `FlxPoint` representing the window's current size.
	 */
	public static inline function getWindowSize():FlxPoint
	{
		return FlxPoint.weak(FlxG.stage.window.width, FlxG.stage.window.height);
	}
	
	/**
	 * Sets the window title. Optionally append to, prepend to, or replace the current title.
	 * @param arg The string to apply. Defaults to the application name if `null`.
	 * @param append If `true`, appends `arg` to the current title.
	 * @param prepend If `true`, prepends `arg` to the current title. Takes priority over `append`.
	 */
	public static function setTitle(?arg:String, append:Bool = false, prepend:Bool = false)
	{
		arg ??= defaultAppTitle;
		
		if (prepend) FlxG.stage.window.title = arg + FlxG.stage.window.title;
		else if (append) FlxG.stage.window.title += arg;
		else FlxG.stage.window.title = arg;
	}
	
	/**
	 * Resets the window title to the default application name.
	 */
	public static inline function resetTitle()
	{
		FlxG.stage.window.title = defaultAppTitle;
	}
	
	/**
	 * Moves the window to an absolute position on the screen.
	 * @param x The target `x` coordinate.
	 * @param y The target `y` coordinate.
	 */
	public static inline function setWindowPosition(x:Int, y:Int)
	{
		FlxG.stage.window.x = x;
		FlxG.stage.window.y = y;
	}
	
	/**
	 * Centers the window on the monitor.
	 */
	public static inline function centerWindow()
	{
		FlxG.stage.window.x = Std.int((monitorResolutionWidth - FlxG.stage.window.width) / 2);
		FlxG.stage.window.y = Std.int((monitorResolutionHeight - FlxG.stage.window.height) / 2);
	}
	
	/**
	 * Centers the window around a given point.
	 * @param point The point to center on. Uses `(0, 0)` if `null`.
	 */
	public static inline function centerWindowOnPoint(?point:FlxPoint)
	{
		FlxG.stage.window.x = Std.int((point?.x ?? 0) - (FlxG.stage.window.width / 2));
		FlxG.stage.window.y = Std.int((point?.y ?? 0) - (FlxG.stage.window.height / 2));
	}
	
	/**
	 * Returns the center point of the window in screen coordinates.
	 */
	public static inline function getCenterWindowPoint():FlxPoint
	{
		return FlxPoint.weak(FlxG.stage.window.x + (FlxG.stage.window.width / 2), FlxG.stage.window.y + (FlxG.stage.window.height / 2));
	}
	
	/**
	 * Checks whether the window fits entirely within the monitor bounds.
	 */
	public static inline function isWindowOnScreen():Bool
	{
		return FlxG.stage.window.x >= 0
			&& FlxG.stage.window.y >= 0
			&& FlxG.stage.window.x + FlxG.stage.window.width <= monitorResolutionWidth
			&& FlxG.stage.window.y + FlxG.stage.window.height <= monitorResolutionHeight;
	}
	
	/**
	 * If the window is partially or fully off-screen, re-centers it on the monitor.
	 */
	public static inline function clampWindowToScreen()
	{
		if (!isWindowOnScreen()) centerWindow();
	}
	
	/**
	 * Flashes the window in the taskbar to grab the user's attention.
	 * 
	 * Note: Behavior varies by platform.
	 */
	public static inline function flash()
	{
		FlxG.stage.window.alert('', '');
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
	
	/**
	 * Gracefully exits the application.
	 */
	public static function exit()
	{
		openfl.system.System.exit(0);
	}
	
	#if FEATURE_DEBUG_TRACY
	/**
	 * Initialize the tracy profiler.
	 * Taken from base game: https://github.com/FunkinCrew/Funkin/blob/main/source/funkin/util/WindowUtil.hx
	 */
	public static function initTracy():Void
	{
		openfl.Lib.current.stage.addEventListener(openfl.events.Event.EXIT_FRAME, (e:openfl.events.Event) -> {
			cpp.vm.tracy.TracyProfiler.frameMark();
		});
		
		cpp.vm.tracy.TracyProfiler.setThreadName("main");
	}
	#end
	
	/**
	 * Resizes the windows and repositions it to be the in the position it opened in.
	 */
	public static function resetWindow()
	{
		final window = lime.app.Application.current.window;
		
		if (window == null) return;
		
		final dpi = lime.system.System.getDisplay(0)?.dpi ?? 96;
		
		final dpiScale = dpi / 96;
		
		@:privateAccess
		{
			window.width = Std.int(Main.startMeta.width * dpiScale);
			window.height = Std.int(Main.startMeta.height * dpiScale);
		}
		
		centerWindow();
	}
}
