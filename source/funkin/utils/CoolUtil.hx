package funkin.utils;

import openfl.display.BlendMode;

import flixel.addons.transition.FlxTransitionableState;
import flixel.FlxG;

/**
	General Utility class for more one off functions
**/
@:nullSafety(Strict)
class CoolUtil
{
	//-----------------------------------------------------------------//
	
	/**
		capitalizes the first letter of a given `String`
	**/
	public static inline function capitalize(text:String):String return text.charAt(0).toUpperCase() + text.substr(1).toLowerCase();
	
	/**
		Helper Function to Fix Save Files for Flixel 5

		-- EDIT: [November 29, 2023] --

		this function is used to get the save path, period.
		since newer flixel versions are being enforced anyways.
		@crowplexus
	**/
	@:access(flixel.util.FlxSave.validate)
	public static inline function getSavePath():String
	{
		@:nullSafety(Off)
		return '${FlxG.stage.application.meta.get('company')}/${flixel.util.FlxSave.validate(FlxG.stage.application.meta.get('file'))}';
	}
	
	/**
	 * Parses a text files and splits it by line 
	 * @param path The path to the txt file
	 * @return An array of the parsed lines
	 */
	public static function coolTextFile(path:String):Array<String>
	{
		var daList:Array<String> = [];
		if (FunkinAssets.exists(path, TEXT)) daList = FunkinAssets.getContent(path).trim().split('\n');
		
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
		Finds the most used Color on a given sprite 

		should be used lightly as its very performance heavy
	**/
	public static inline function dominantColor(sprite:Null<flixel.FlxSprite>):Int
	{
		if (sprite == null || sprite.pixels.image == null) return FlxColor.BLACK;
		
		var countByColor:Map<Int, Int> = [];
		for (col in 0...sprite.frameWidth)
		{
			for (row in 0...sprite.frameHeight)
			{
				var colorOfThisPixel:FlxColor = sprite.pixels.getPixel32(col, row);
				if (colorOfThisPixel.alphaFloat > 0.05)
				{
					colorOfThisPixel = FlxColor.fromRGB(colorOfThisPixel.red, colorOfThisPixel.green, colorOfThisPixel.blue, 255);
					var count:Int = countByColor.get(colorOfThisPixel) ?? 0;
					countByColor.set(colorOfThisPixel, count + 1);
				}
			}
		}
		
		var maxCount = 0;
		var maxKey:Int = 0;
		countByColor.set(FlxColor.BLACK, 0);
		for (key => count in countByColor)
		{
			if (count >= maxCount)
			{
				maxCount = count;
				maxKey = key;
			}
		}
		
		return maxKey;
	}
	
	/**
	 * Opens a given url on your browser
	 */
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
	
	/**
	 * Opens a windows alert
	 */
	public static function doPopUp(title:String, description:String = '')
	{
		FlxG.stage.window.alert(description, title);
		trace(description);
	}
	
	/**
	 * Returns a `FlxEase` from a string
	 * 
	 * Faster than using getProperty
	 */
	public static function getEaseFromString(ease:Null<String>)
	{
		if (ease == null) return FlxEase.linear;
		return switch (ease.toLowerCase().trim())
		{
			case 'backin': FlxEase.backIn;
			case 'backinout': FlxEase.backInOut;
			case 'backout': FlxEase.backOut;
			case 'bouncein': FlxEase.bounceIn;
			case 'bounceinout': FlxEase.bounceInOut;
			case 'bounceout': FlxEase.bounceOut;
			case 'circin': FlxEase.circIn;
			case 'circinout': FlxEase.circInOut;
			case 'circout': FlxEase.circOut;
			case 'cubein': FlxEase.cubeIn;
			case 'cubeinout': FlxEase.cubeInOut;
			case 'cubeout': FlxEase.cubeOut;
			case 'elasticin': FlxEase.elasticIn;
			case 'elasticinout': FlxEase.elasticInOut;
			case 'elasticout': FlxEase.elasticOut;
			case 'expoin': FlxEase.expoIn;
			case 'expoinout': FlxEase.expoInOut;
			case 'expoout': FlxEase.expoOut;
			case 'quadin': FlxEase.quadIn;
			case 'quadinout': FlxEase.quadInOut;
			case 'quadout': FlxEase.quadOut;
			case 'quartin': FlxEase.quartIn;
			case 'quartinout': FlxEase.quartInOut;
			case 'quartout': FlxEase.quartOut;
			case 'quintin': FlxEase.quintIn;
			case 'quintinout': FlxEase.quintInOut;
			case 'quintout': FlxEase.quintOut;
			case 'sinein': FlxEase.sineIn;
			case 'sineinout': FlxEase.sineInOut;
			case 'sineout': FlxEase.sineOut;
			case 'smoothstepin': FlxEase.smoothStepIn;
			case 'smoothstepinout': FlxEase.smoothStepInOut;
			case 'smoothstepout': FlxEase.smoothStepOut;
			case 'smootherstepin': FlxEase.smootherStepIn;
			case 'smootherstepinout': FlxEase.smootherStepInOut;
			case 'smootherstepout': FlxEase.smootherStepOut;
			default: FlxEase.linear;
		}
	}
	
	/**
	 * Gets a `openfl.display.BlendMode` from a string
	 */
	public static function getBlendFromString(blend:Null<String>):BlendMode
	{
		if (blend == null) return BlendMode.NORMAL;
		return switch (blend.toLowerCase().trim())
		{
			case 'add': BlendMode.ADD;
			case 'alpha': BlendMode.ALPHA;
			case 'darken': BlendMode.DARKEN;
			case 'difference': BlendMode.DIFFERENCE;
			case 'erase': BlendMode.ERASE;
			case 'hardlight': BlendMode.HARDLIGHT;
			case 'invert': BlendMode.INVERT;
			case 'layer': BlendMode.LAYER;
			case 'lighten': BlendMode.LIGHTEN;
			case 'multiply': BlendMode.MULTIPLY;
			case 'normal': BlendMode.NORMAL;
			case 'overlay': BlendMode.OVERLAY;
			case 'screen': BlendMode.SCREEN;
			case 'shader': BlendMode.SHADER;
			case 'subtract': BlendMode.SUBTRACT;
			default: BlendMode.NORMAL;
		}
	}
	
	/**
	 * Ensures an array at min has the amount of fields in a fallback
	 * 
	 * If the fallback is longer than the input, values in the fallback will be used.
	 */
	public static function correctArray<T>(input:Array<T>, fallback:Array<T>) // todo have a good name...
	{
		for (i in 0...input.length)
		{
			fallback[i] = input[i];
		}
		
		return fallback;
	}
	
	/**
	 * Copies Map information from one map to another
	 * @param from The Map we are copying from
	 * @param to The Map we are copying to
	 */
	public static function copyMapValues<K, V>(from:Map<K, V>, to:Map<K, V>)
	{
		for (k => v in from)
		{
			to.set(k, v);
		}
	}
	
	/**
	 * Cancels the music tracks fade in/out tween
	 * 
	 * If there is one
	 */
	public static function cancelMusicFadeTween()
	{
		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.fadeTween?.cancel();
			@:nullSafety(Off)
			FlxG.sound.music.fadeTween = null;
		}
	}
}
