package funkin.utils;

class MathUtil
{
	/**
		FlxMath.lerp but accounts for FPS.
	**/
	public static inline function fpsLerp(v1:Float, v2:Float, ratio:Float) return FlxMath.lerp(v1, v2, FlxMath.getElapsedLerp(ratio, FlxG.elapsed));
	
	/**
		crude version of FlxMath.wrap. supports floats though
	**/
	public static function wrap(value:Float, min:Float, max:Float):Float
	{
		if (value < min) return max;
		else if (value > max) return min;
		else return value;
	}
	
	/**
	 * Alternative to `FlxMath.roundDecimal` but floors the value rather than rounding it
	 * @param value The number 
	 * @param precision The number of decimals
	 * @return The floored value
	 */
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
	public static inline function numberArray(?min:Int, max:Int):Array<Int>
	{
		if (min == null) min = 0;
		return [for (i in min...max) i];
	}
	
	/**
	 * Clamps/Bounds a value.
	 */
	public static overload extern inline function clamp(input:Float, min:Float, max:Float):Float
	{
		return FlxMath.bound(input, min, max);
	}
	
	/**
	 * Clamps/Bounds a value.
	 */
	public static overload extern inline function clamp(input:Int, min:Int, max:Int):Float
	{
		if (input < min) input = min;
		if (input > max) input = max;
		return input;
	}
}
