package funkin.utils;

import flixel.util.FlxSort;

/**
	Utility class for sorting methods
**/
@:nullSafety(Strict)
class SortUtil
{
	/**
		Sorts by Note time
	**/
	public static inline function sortByStrumTime(a:funkin.objects.note.Note, b:funkin.objects.note.Note):Int
	{
		if (a == null || b == null) return 0;
		
		return FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime);
	}
	
	/**
		Sorts by floats
	**/
	public static inline function laserSort(a:Float, b:Float):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, a, b);
	}
	
	/**
		Sorts by Event notes time
	**/
	public static inline function sortByTime(a:funkin.objects.note.Note.EventNote, b:funkin.objects.note.Note.EventNote):Int
	{
		if (a == null || b == null) return 0;
		
		return FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime);
	}
	
	/**
		Sorts by SpeedEvent's time
	**/
	public static inline function svSort(a:funkin.game.modchart.SpeedEvent, b:funkin.game.modchart.SpeedEvent):Int
	{
		if (a == null || b == null) return 0;
		
		return FlxSort.byValues(FlxSort.ASCENDING, a.startTime, b.startTime);
	}
	
	/**
		Sorts by FlxBasic's z values
	**/
	public static inline function sortByZ(order:Int, a:flixel.FlxBasic, b:flixel.FlxBasic):Int
	{
		if (a == null || b == null) return 0;
		
		return FlxSort.byValues(order, a.zIndex, b.zIndex);
	}
}
