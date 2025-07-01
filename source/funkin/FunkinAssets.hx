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
@:nullSafety
class FunkinAssets
{
	public static final cache:FunkinCache = new FunkinCache();
	
	/**
	 * Parses a txt file instance
	 */
	public static function getContent(path:String):String
	{
		var content:String = '';
		#if (MODS_ALLOWED || ASSET_REDIRECT)
		if (FileSystem.exists(path)) content = File.getContent(path);
		else
		#end
		if (Assets.exists(path)) content = Assets.getText(path);
		else
		{
			throw 'Couldnt find file at path [$path]';
		}
		
		return content;
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
	 *	Returns wheter a given path exists.
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
	 */
	public static function readDirectory(directory:String):Array<String>
	{
		#if (MODS_ALLOWED || ASSET_REDIRECT)
		return FileSystem.readDirectory(directory);
		#else
		var dir = Assets.list().filter(string -> string.contains(directory));
		return dir.map(string -> string.replace(directory, '').replace('/', ''));
		#end
	}
	
	/**
	 * retrieves a flxgraphic instance from key.
	 * 
	 * @param useCache Retrieves from the cache if possible. Otherwise, it will be cached
	 * @param allowGPU If true and is enabled in settings, the graphic will be cached on in video memory
	 */
	public static function getGraphic(key:String, useCache:Bool = true, allowGPU:Bool = true):Null<FlxGraphic>
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
	 * Retrives a sound instance from path.
	 * 
	 * @param useCache Retrieves from the cache if possible. Otherwise, it will be cached
	 * @param safety If true, will return a flixel Beep rather than null.
	 */
	public static function getSound(key:String, useCache:Bool = true, safety:Bool = true):Null<Sound>
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
			return sound;
		}
		else if (safety)
		{
			Logger.log('sound ($key) was not found. Returning beep instead', WARN);
			
			return FlxAssets.getSoundAddExtension('flixel/sounds/beep');
		}
		else
		{
			Logger.log('sound ($key) was not found', WARN);
			
			return null;
		}
	}
}
