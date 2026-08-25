package funkin.video;

import funkin.input.Controls;

#if VIDEOS_ALLOWED
import hxvlc.flixel.FlxVideoSprite;
#if (hxvlc > "2.2.6")
import hxvlc.openfl.Location;
#else
import hxvlc.util.Location;
#end

class ConductorVideoSprite extends FunkinVideoSprite
{
	/**
	 * The max desync allowed before forced resync in miliseconds
	 */
	public var leniency:Int = 600;
	
	/**
	 * The Conductor time in miliseconds the video started at. used to keep time in sync.
	 */
	public var initialConductorTime:Float = 0;
	
	override function play():Bool
	{
		initialConductorTime = Conductor.songPosition;
		return super.play();
	}
	
	override function update(elapsed:Float)
	{
		if (isPlaying)
		{
			if (((Conductor.songPosition - initialConductorTime) - currentTime) > leniency)
			{
				bitmap.time = haxe.Int64.fromFloat(Conductor.songPosition - initialConductorTime);
			}
		}
		
		super.update(elapsed);
	}
}
#end
