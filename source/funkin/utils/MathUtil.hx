package funkin.utils;


class MathUtil {
    
    /**
		FlxMath.lerp but accounts for FPS.
	**/
	public static inline function fpsLerp(v1:Float,v2:Float,ratio:Float) return FlxMath.lerp(v1,v2,ratio * 60 * FlxG.elapsed); 

	/**
		crude version of FlxMath.wrap. supports floats though
	**/
	public static function wrap(value:Float, min:Float, max:Float):Float
	{
		if (value < min) return max;
		else if (value > max) return min;
		else return value;
	}
	
	// functions from basegame mathutil.hx, for the soundtray, i'll see if these are rlly necessary later

	public static function coolLerp(base:Float, target:Float, ratio:Float):Float
	{
		return base + cameraLerp(ratio) * (target - base);
	}

	public static function cameraLerp(lerp:Float):Float
	{
		return lerp * (FlxG.elapsed / (1 / 60));
	}

	public static function floorDecimal(value:Float, decimals:Int):Float
	{
		if(decimals < 1)
			return Math.floor(value);

		var tempMult:Float = 1;
		for (i in 0...decimals)
			tempMult *= 10;

		var newValue:Float = Math.floor(value * tempMult);
		return newValue / tempMult;
	}

	inline public static function numberArray(?min:Int, max:Int):Array<Int>
	{
		if (min == null) min = 0;
		return [for (i in min...max) i];
	}

}

