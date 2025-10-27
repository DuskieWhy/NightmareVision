package funkin.scripts;

import flixel.math.FlxMath;
import flixel.math.FlxRandom;

class ScriptedFlxColor
{
	public static final BLACK:Int = FlxColor.BLACK;
	public static final BLUE:Int = FlxColor.BLUE;
	public static final CYAN:Int = FlxColor.CYAN;
	public static final GRAY:Int = FlxColor.GRAY;
	public static final GREEN:Int = FlxColor.GREEN;
	public static final LIME:Int = FlxColor.LIME;
	public static final MAGENTA:Int = FlxColor.MAGENTA;
	public static final ORANGE:Int = FlxColor.ORANGE;
	public static final PINK:Int = FlxColor.PINK;
	public static final PURPLE:Int = FlxColor.PURPLE;
	public static final RED:Int = FlxColor.RED;
	public static final TRANSPARENT:Int = FlxColor.TRANSPARENT;
	public static final WHITE:Int = FlxColor.WHITE;
	public static final YELLOW:Int = FlxColor.YELLOW;
	
	public static function fromCMYK(c:Float, m:Float, y:Float, b:Float, a:Float = 1):Int return cast FlxColor.fromCMYK(c, m, y, b, a);
	
	public static function fromHSB(h:Float, s:Float, b:Float, a:Float = 1):Int return cast FlxColor.fromHSB(h, s, b, a);
	
	public static function fromInt(num:Int):Int return cast FlxColor.fromInt(num);
	
	public static function fromRGBFloat(r:Float, g:Float, b:Float, a:Float = 1):Int return cast FlxColor.fromRGBFloat(r, g, b, a);
	
	public static function fromRGB(r:Int, g:Int, b:Int, a:Int = 255):Int return cast FlxColor.fromRGB(r, g, b, a);
	
	public static function getHSBColorWheel(a:Int = 255):Array<Int> return cast FlxColor.getHSBColorWheel(a);
	
	public static function gradient(color1:FlxColor, color2:FlxColor, steps:Int, ?ease:Float->Float):Array<Int> return cast FlxColor.gradient(color1, color2, steps, ease);
	
	public static function interpolate(color1:FlxColor, color2:FlxColor, factor:Float = 0.5):Int return cast FlxColor.interpolate(color1, color2, factor);
	
	public static function fromString(string:String):Int return cast FlxColor.fromString(string);
}

/**
 * Wrapper class to be used in place of `FlxG.random`. 
 * 
 * Necessary due to generics
 */
@:access(flixel.math.FlxRandom)
class ScriptedFlxRandom
{
	@:inheritDoc(flixel.math.FlxRandom.resetInitialSeed)
	public static inline function resetInitialSeed():Int
	{
		return FlxG.random.initialSeed = FlxRandom.rangeBound(Std.int(Math.random() * FlxMath.MAX_VALUE_INT));
	}
	
	@:inheritDoc(flixel.math.FlxRandom.int)
	public function int(min:Int = 0, max:Int = FlxMath.MAX_VALUE_INT, ?excludes:Array<Int>):Int
	{
		return FlxG.random.int(min, max, excludes);
	}
	
	@:inheritDoc(flixel.math.FlxRandom.float)
	public static function float(min:Float = 0, max:Float = 1, ?excludes:Array<Float>):Float
	{
		return FlxG.random.float(min, max, excludes);
	}
	
	@:inheritDoc(flixel.math.FlxRandom.floatNormal)
	public function floatNormal(mean:Float = 0, stdDev:Float = 1):Float
	{
		return FlxG.random.floatNormal(mean, stdDev);
	}
	
	@:inheritDoc(flixel.math.FlxRandom.bool)
	public static inline function bool(chance:Float = 50):Bool
	{
		return float(0, 100) < chance;
	}
	
	@:inheritDoc(flixel.math.FlxRandom.sign)
	public static inline function sign(chance:Float = 50):Int
	{
		return bool(chance) ? 1 : -1;
	}
	
	@:inheritDoc(flixel.math.FlxRandom.weightedPick)
	public static function weightedPick(weightsArray:Array<Float>):Int
	{
		return FlxG.random.weightedPick(weightsArray);
	}
	
	@:inheritDoc(flixel.math.FlxRandom.getObject)
	public static function getObject<T>(objects:Array<T>, ?weightsArray:Array<Float>, startIndex:Int = 0, ?endIndex:Null<Int>)
	{
		var selected:Null<T> = null;
		
		if (objects.length != 0)
		{
			weightsArray ??= [for (i in 0...objects.length) 1];
			
			endIndex ??= objects.length - 1;
			
			startIndex = Std.int(FlxMath.bound(startIndex, 0, objects.length - 1));
			endIndex = Std.int(FlxMath.bound(endIndex, 0, objects.length - 1));
			
			// Swap values if reversed
			if (endIndex < startIndex)
			{
				startIndex = startIndex + endIndex;
				endIndex = startIndex - endIndex;
				startIndex = startIndex - endIndex;
			}
			
			if (endIndex > weightsArray.length - 1)
			{
				endIndex = weightsArray.length - 1;
			}
			
			final arrayHelper = [for (i in startIndex...endIndex + 1) weightsArray[i]];
			
			selected = objects[startIndex + weightedPick(arrayHelper)];
		}
		
		return selected;
	}
	
	@:inheritDoc(flixel.math.FlxRandom.shuffle)
	public static function shuffle<T>(array:Array<T>):Void
	{
		var maxValidIndex = array.length - 1;
		for (i in 0...maxValidIndex)
		{
			var j = FlxG.random.int(i, maxValidIndex);
			var tmp = array[i];
			array[i] = array[j];
			array[j] = tmp;
		}
	}
	
	@:inheritDoc(flixel.math.FlxRandom.color)
	public static function color(?min:FlxColor, ?max:FlxColor, ?alpha:Int, greyScale:Bool = false):FlxColor
	{
		return FlxG.random.color(min, max, alpha, greyScale);
	}
}
