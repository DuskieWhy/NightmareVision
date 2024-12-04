package funkin.utils;

class MathUtil
{
	/**
		FlxMath.lerp but accounts for FPS.
	**/
	public static inline function fpsLerp(v1:Float, v2:Float, ratio:Float) return FlxMath.lerp(v1, v2, ratio * 60 * FlxG.elapsed);

	/**
		crude version of FlxMath.wrap. supports floats though
	**/
	public static function wrap(value:Float, min:Float, max:Float):Float
	{
		if (value < min) return max;
		else if (value > max) return min;
		else return value;
	}

	public static function floorDecimal(value:Float, decimals:Int):Float
	{
		if (decimals < 1) return Math.floor(value);

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

	public function intClamp(input:Int, min:Int, max:Int):Int
	{
		if (input < min) input = min;
		if (input > max) input = max;
		return input;
	}

	public static function betterLerp(a:Float, b:Float, ratio:Float)
	{
		if (a == b) return b;
		if (Math.abs(b - a) < 0.001) // not the best
		{
			return b;
		}

		return fpsLerp(a, b, ratio);
	}
}
