package funkin.backend;

import haxe.PosInfos;

#if hscript_iris
using crowplexus.iris.utils.Ansi;
#end

import funkin.backend.plugins.DebugTextPlugin;

enum abstract Severity(Int)
{
	var PRINT;
	var WARN;
	var ERROR;
}

/**
 * basic custom tracing method
 * 
 * has support for ansi colour, showing the message on screen, and flixel debugger
 */
class Logger
{
	public static function log(data:Dynamic, severity:Severity = PRINT, showInGame:Bool = false, ?pos:PosInfos)
	{
		#if FLX_DEBUG
		switch (severity)
		{
			case ERROR:
				FlxG.log.error(data, pos);
				
			case WARN:
				FlxG.log.warn(data, pos);
				
			case PRINT:
		}
		#end
		
		var output:String = haxe.Log.formatOutput(data, pos);
		
		#if hscript_iris
		output = output.fg(getAnsiColourFromSeverity(severity)).reset();
		
		// added cuz vsc debugger nulls color term for me so.
		#if !FORCED_ANSI
		output = output.stripColor();
		#end
		#end
		if (showInGame)
		{
			DebugTextPlugin.addText(Std.string(data), getHexColourFromSeverity(severity));
		}
		
		#if sys
		Sys.println(output);
		#else
		trace(output); // idk others lol!
		#end
	}
	
	#if hscript_iris
	static function getAnsiColourFromSeverity(severity:Severity)
	{
		return switch (severity)
		{
			case ERROR: AnsiColor.RED;
			
			case WARN: AnsiColor.YELLOW;
			
			default: AnsiColor.WHITE;
		}
	}
	#end
	
	public static function getHexColourFromSeverity(severity:Severity)
	{
		return switch (severity)
		{
			case ERROR: FlxColor.RED;
			
			case WARN: FlxColor.YELLOW;
			
			default: FlxColor.WHITE;
		}
	}
}
