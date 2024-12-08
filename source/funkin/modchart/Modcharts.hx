package funkin.modchart;

import flixel.math.FlxAngle;
import funkin.modchart.events.CallbackEvent;
import funkin.modchart.*;
import funkin.data.*;
import funkin.states.*;
import funkin.states.substates.*;
import funkin.objects.*;

class Modcharts
{
	static function numericForInterval(start, end, interval, func)
	{
		var index = start;
		while (index < end)
		{
			func(index);
			index += interval;
		}
	}

	static var songs = [];

	public static function isModcharted(songName:String)
	{
		if (songs.contains(songName.toLowerCase())) return true;

		// add other conditionals if needed

		// return true; // turns modchart system on for all songs, only use for like.. debugging
		return false;
	}

	public static function loadModchart(modManager:ModManager, songName:String)
	{
		switch (songName.toLowerCase())
		{
			default:
		}
	}
}
