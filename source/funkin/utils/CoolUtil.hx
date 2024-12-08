package funkin.utils;

import flixel.addons.transition.FlxTransitionableState;
import flixel.math.FlxPoint;
import flixel.FlxG;
import openfl.utils.Assets;

class CoolUtil
{
	inline public static function scale(x:Float, l1:Float, h1:Float, l2:Float, h2:Float):Float return ((x - l1) * (h2 - l2) / (h1 - l1) + l2);

	inline public static function clamp(n:Float, l:Float, h:Float)
	{
		if (n > h) n = h;
		if (n < l) n = l;
		return n;
	}

	public static function rotate(x:Float, y:Float, angle:Float, ?point:FlxPoint):FlxPoint
	{
		var p = point == null ? FlxPoint.weak() : point;
		p.set((x * Math.cos(angle)) - (y * Math.sin(angle)), (x * Math.sin(angle)) + (y * Math.cos(angle)));
		return p;
	}

	inline public static function quantizeAlpha(f:Float, interval:Float)
	{
		return Std.int((f + interval / 2) / interval) * interval;
	}

	inline public static function quantize(f:Float, interval:Float)
	{
		return Std.int((f + interval / 2) / interval) * interval;
	}

	//-----------------------------------------------------------------//

	/**
		sorting method that goes by FlxBasic's z values
	**/
	inline public static function sortByZ(order:Int, a:FlxBasic, b:FlxBasic):Int
	{
		if (a == null || b == null) return 0;
		return flixel.util.FlxSort.byValues(order, a.zIndex, b.zIndex);
	}

	/**
		capatalizes the first letter of a string.
	**/
	inline public static function capitalize(text:String):String return text.charAt(0).toUpperCase() + text.substr(1).toLowerCase();

	@:access(flixel.util.FlxSave.validate)
	inline public static function getSavePath():String
	{
		return '${FlxG.stage.application.meta.get('company')}/${flixel.util.FlxSave.validate(FlxG.stage.application.meta.get('file'))}';
	}

	public static function coolTextFile(path:String):Array<String>
	{
		var daList:Array<String> = [];
		#if sys
		if (FileSystem.exists(path)) daList = File.getContent(path).trim().split('\n');
		else
		#end
		if (Assets.exists(path)) daList = Assets.getText(path).trim().split('\n');

		for (i in 0...daList.length)
		{
			daList[i] = daList[i].trim();
		}

		return daList;
	}

	public static function listFromString(string:String):Array<String>
	{
		var daList:Array<String> = [];
		daList = string.trim().split('\n');

		for (i in 0...daList.length)
		{
			daList[i] = daList[i].trim();
		}

		return daList;
	}

	/**
		goes through every pixel a sprites graphic to find its most prominent color. very expensive
	**/
	public static function dominantColor(sprite:flixel.FlxSprite):Int
	{
		var countByColor:Map<Int, Int> = [];
		for (col in 0...sprite.frameWidth)
		{
			for (row in 0...sprite.frameHeight)
			{
				var colorOfThisPixel:Int = sprite.pixels.getPixel32(col, row);
				if (colorOfThisPixel != 0)
				{
					if (countByColor.exists(colorOfThisPixel))
					{
						countByColor[colorOfThisPixel] = countByColor[colorOfThisPixel] + 1;
					}
					else if (countByColor[colorOfThisPixel] != 13520687 - (2 * 13520687))
					{
						countByColor[colorOfThisPixel] = 1;
					}
				}
			}
		}
		var maxCount = 0;
		var maxKey:Int = 0; // after the loop this will store the max color
		countByColor[flixel.util.FlxColor.BLACK] = 0;
		for (key in countByColor.keys())
		{
			if (countByColor[key] >= maxCount)
			{
				maxCount = countByColor[key];
				maxKey = key;
			}
		}
		return maxKey;
	}

	public static function browserLoad(site:String)
	{
		#if linux
		Sys.command('/usr/bin/xdg-open', [site]);
		#else
		FlxG.openURL(site);
		#end
	}

	inline public static function openFolder(folder:String, absolute:Bool = false)
	{
		#if sys
		if (!absolute) folder = Sys.getCwd() + '$folder';

		folder = folder.replace('/', '\\');
		if (folder.endsWith('/')) folder.substr(0, folder.length - 1);

		#if linux
		var command:String = '/usr/bin/xdg-open';
		#else
		var command:String = 'explorer.exe';
		#end
		Sys.command(command, [folder]);
		trace('$command $folder');
		#else
		FlxG.error("Platform is not supported for CoolUtil.openFolder");
		#end
	}

	/**
		helper to quickly set transSkips
	**/
	public static inline function setTransSkip(into:Bool = true, outof:Bool = true)
	{
		FlxTransitionableState.skipNextTransIn = into;
		FlxTransitionableState.skipNextTransOut = outof;
	}
}
