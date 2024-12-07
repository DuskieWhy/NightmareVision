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

	/**
		Makes a number array
		* @param	min starting number. default is 0
		* @param	max ending number
		* @return the new array
	**/
	inline public static function numberArray(min:Int = 0, max:Int):Array<Int>
	{
		return [for (i in min...max) i];
	}

	/**
		Clamps/Bounds a value. for Ints though.
		* @param	input the value to clamp
		* @return The clamped Value
	**/
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
