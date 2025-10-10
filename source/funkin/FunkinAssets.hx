package funkin;

import flixel.graphics.FlxGraphic;
import flixel.system.FlxAssets;

import openfl.media.Sound;

import funkin.backend.FunkinCache;

import openfl.utils.AssetType;
import openfl.display.BitmapData;
import openfl.Assets;

/**
 * backend for retrieving and caching assets
 */
@:nullSafety(Strict)
class FunkinAssets
{
	/**
	 * Handles the caching of assets collected through `Paths` 
	 */
	public static final cache:FunkinCache = new FunkinCache();
	
	/**
	 * Safer alternative to directly using `haxe.Json.parse`
	 */
	public static function parseJson(content:String, ?pos:haxe.PosInfos):Null<Any>
	{
		try
		{
			return haxe.Json.parse(content);
		}
		catch (e)
		{
			Logger.log('failed to parse content\nException: ${e.message}', WARN, false, pos);
			return null;
		}
	}
	
	/**
	 * Retrieves the content of a given file from its path
	 */
	public static function getContent(path:String):String
	{
		#if (MODS_ALLOWED || ASSET_REDIRECT)
		if (FileSystem.exists(path)) return File.getContent(path);
		else
		#end
		if (Assets.exists(path)) return Assets.getText(path);
		else
		{
			throw 'Couldnt find file at path [$path]';
		}
	}
	
	/**
	 * Retrives a bitmap instance from path.
	 * 
	 * Will return null in the case it cannot be found.
	 */
	public static function getBitmapData(path:String, useCache:Bool = true):Null<BitmapData>
	{
		var bitmap:Null<BitmapData> = null;
		#if (MODS_ALLOWED || ASSET_REDIRECT) if (FileSystem.exists(path)) bitmap = BitmapData.fromFile(path);
		else #end if (Assets.exists(path, IMAGE)) bitmap = Assets.getBitmapData(path, useCache);
		
		return bitmap;
	}
	
	/**
	 *	Returns whether a given path exists.
	 */
	public static function exists(path:String, ?type:AssetType):Bool
	{
		var exists:Bool = false;
		
		#if (MODS_ALLOWED || ASSET_REDIRECT)
		if (FileSystem.exists(path)) exists = true;
		else
		#end
		if (Assets.exists(path, type)) exists = true;
		
		return exists;
	}
	
	/**
	 * Reads a given directory and returns all file names inside.
	 * 
	 * if it could not be found, an empty array will be returned.
	 */
	public static function readDirectory(directory:String):Array<String>
	{
		#if (MODS_ALLOWED || ASSET_REDIRECT)
		return FileSystem.exists(directory) ? FileSystem.readDirectory(directory) : []; // doing a check because i want this to maintain parity with ther assets variation
		#else
		if (directory.trim().length == 0) return [];
		var dir = Assets.list().filter(string -> string.contains(directory));
		return dir.map(string -> string.replace(directory, '').replace('/', ''));
		#end
	}
	
	public static function isDirectory(directory:String):Bool
	{
		#if (MODS_ALLOWED || ASSET_REDIRECT)
		return FileSystem.isDirectory(directory);
		#else
		// this method is a bit chopped...
		if (directory.trim().length == 0) return false;
		return Assets.list().filter(path -> return path != directory && path.startsWith(directory)).length != 0;
		#end
	}
	
	/**
	 * retrieves a flxgraphic instance from key.
	 * 
	 * @param useCache Retrieves from the cache if possible. Otherwise, it will be cached
	 * @param allowGPU If true and is enabled in settings, the graphic will be cached on in video memory
	 */
	public static function getGraphicUnsafe(key:String, useCache:Bool = true, allowGPU:Bool = true):Null<FlxGraphic>
	{
		if (useCache && cache.currentTrackedGraphics.exists(key))
		{
			cache.localTrackedAssets.push(key);
			return cache.currentTrackedGraphics.get(key);
		}
		
		var bitmap:Null<BitmapData> = getBitmapData(key);
		
		if (bitmap != null)
		{
			return cache.cacheBitmap(key, bitmap, allowGPU);
		}
		else
		{
			Logger.log('graphic ($key) was not found', WARN);
			return null;
		}
	}
	
	/**
	 * retrieves a flxgraphic instance from key.
	 * 
	 * @param useCache Retrieves from the cache if possible. Otherwise, it will be cached
	 * @param allowGPU If true and is enabled in settings, the graphic will be cached on in video memory
	 */
	public static function getGraphic(key:String, useCache:Bool = true, allowGPU:Bool = true):FlxGraphic
	{
		final graphic:Null<FlxGraphic> = getGraphicUnsafe(key, useCache);
		
		if (graphic != null)
		{
			return graphic;
		}
		
		Logger.log('graphic ($key) was not found. Returning flixel-logo instead');
		
		return FlxG.bitmap.add('flixel/images/logo/default.png');
	}
	
	/**
	 * Retrives a Sound instance from key.
	 * 
	 * If the sound could not be found, a beep sound will be given in place.
	 * 
	 * @param useCache Retrieves from the cache if possible. Otherwise, it will be cached
	 */
	public static function getSound(key:String, useCache:Bool = true):Sound
	{
		final sound:Null<Sound> = getSoundUnsafe(key, useCache);
		
		if (sound != null)
		{
			return sound;
		}
		
		Logger.log('sound ($key) was not found. Returning beep instead');
		
		return FlxAssets.getSoundAddExtension('flixel/sounds/beep');
	}
	
	/**
	 * Retrives a Sound instance from key.
	 * 
	 * If the sound could not be found, null will be returned.
	 * 
	 * @param useCache Retrieves from the cache if possible. Otherwise, it will be cached
	 */
	public static function getSoundUnsafe(key:String, useCache:Bool = true):Null<Sound>
	{
		if (useCache && cache.currentTrackedSounds.exists(key))
		{
			cache.localTrackedAssets.push(key);
			return cache.currentTrackedSounds.get(key);
		}
		
		var sound:Null<Sound> = null;
		
		#if (MODS_ALLOWED || ASSET_REDIRECT) if (FileSystem.exists(key)) sound = Sound.fromFile(key);
		else #end if (Assets.exists(key, SOUND)) sound = Assets.getSound(key, true);
		
		if (sound != null)
		{
			cache.cacheSound(key, sound);
		}
		
		return sound;
	}
}
