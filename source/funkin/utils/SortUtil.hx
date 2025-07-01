package funkin.utils;

import flixel.util.FlxSort;

/**
	Utility class for sorting methods
**/
class SortUtil
{
	/**
		Sorts by Note time
	**/
	inline public static function sortByStrumTime(Obj1:funkin.objects.Note, Obj2:funkin.objects.Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}
	
	/**
		Sorts by floats
	**/
	inline public static function laserSort(Obj1:Float, Obj2:Float):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1, Obj2);
	}
	
	/**
		Sorts by Event notes time
	**/
	inline public static function sortByTime(Obj1:funkin.objects.Note.EventNote, Obj2:funkin.objects.Note.EventNote):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}
	
	/**
		Sorts by SpeedEvent's time
	**/
	inline public static function svSort(Obj1:funkin.game.modchart.SpeedEvent, Obj2:funkin.game.modchart.SpeedEvent):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.startTime, Obj2.startTime);
	}
	
	/**
		Sorts by FlxBasic's z values
	**/
	inline public static function sortByZ(order:Int, a:flixel.FlxBasic, b:flixel.FlxBasic):Int
	{
		if (a == null || b == null) return 0;
		return FlxSort.byValues(order, a.zIndex, b.zIndex);
	}
}
