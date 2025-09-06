package funkin.backend;

import flixel.addons.transition.FlxTransitionableState;

import openfl.events.ErrorEvent;
import openfl.errors.Error;
import openfl.events.UncaughtErrorEvent;
import openfl.Lib;

// todo more witht his actually...
@:nullSafety
class CrashHandler
{
	public static function init()
	{
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onUncaughtError);
		//
		#if cpp
		untyped __global__.__hxcpp_set_critical_error_handler(onCriticalError);
		#end
	}
	
	static function onCriticalError(message:String):Void
	{
		throw Std.string(message);
	}
	
	static function onUncaughtError(event:UncaughtErrorEvent)
	{
		FlxTransitionableState.skipNextTransIn = FlxTransitionableState.skipNextTransOut = true;
		
		var curFlxState:String = 'N/A';
		
		if (FlxG.state != null)
		{
			final cl = Type.getClass(FlxG.state);
			if (cl != null) curFlxState = 'FlxState: ' + (Type.getClassName(cl) ?? 'N/A');
			FlxG.state.persistentUpdate = FlxG.state.persistentDraw = false;
		}
		
		var message:String = Std.string(event.error);
		
		if (Std.isOfType(event.error, Error))
		{
			message = cast(event.error, Error).message;
		}
		else if (Std.isOfType(event.error, ErrorEvent))
		{
			message = cast(event.error, ErrorEvent).text;
		}
		
		var stackMessage:String = '';
		
		for (stackItem in haxe.CallStack.exceptionStack(true))
		{
			switch (stackItem)
			{
				case Method(classname, method):
					stackMessage += 'Function($classname.$method)';
				case CFunction:
					stackMessage += 'Function ';
				case Module(m):
					stackMessage += 'Module($m)';
				case LocalFunction(v):
					stackMessage += 'LocalFunction($v)';
				case FilePos(s, file, line, column):
					stackMessage += file + " (line " + line + ")";
			}
			
			stackMessage += '\n';
		}
		
		event.preventDefault();
		event.stopPropagation();
		event.stopImmediatePropagation();
		
		final callstackMessage = stackMessage.trim().length == 0 ? ' N/A' : '\n$stackMessage';
		
		var fullReport = '$curFlxState\n\nException caught: $message\n\nCallstack:$callstackMessage';
		
		FlxG.switchState(() -> new FallbackState(fullReport, () -> FlxG.switchState(() -> new MainMenuState())));
	}
}
