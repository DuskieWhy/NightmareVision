package funkin.backend;

import haxe.ds.IntMap;

import flixel.util.FlxStringUtil;

import openfl.Assets;

import flixel.graphics.FlxGraphic;

import openfl.display.BitmapData;
import openfl.media.Sound;

class CacheMap<T>
{
	public function new() {}
	
	public var cache:Map<String, T> = [];
	public var permanentKeys:Array<String> = [];
	
	public function get(key:String):Null<T> return cache.get(key);
	
	public function exists(key:String) return cache.exists(key);
	
	public function set(key:String, value:T) cache.set(key, value);
	
	public function remove(key:String) return cache.remove(key);
	
	public function keys() return cache.keys();
	
	/**
	 * Adds a key to be considered permanent to the cache.
	 */
	public function addPermanentKey(key:String)
	{
		if (!permanentKeys.contains(key)) permanentKeys.push(key);
	}
}

@:access(openfl.display.BitmapData)
@:nullSafety
@:allow(funkin.FunkinAssets)
class FunkinCache
{
	/**
	 * Clears all graphics and sounds that are considered inactive. Flags everything to be inactive as well.
	 * 
	 * use `clearUnusedMemory` afterwards to purge everything
	 */
	public function clearStoredMemory() // maybe rename
	{
		// @:privateAccess
		// for (key in FlxG.bitmap._cache.keys())
		// {
		// 	// ok this is dumb fix this later
		// 	if (!currentTrackedGraphics.exists(key)
		// 		&& !key.startsWith('pixels')
		// 		&& !key.contains('editors/notification_neutral.png')
		// 		&& !key.contains('editors/notification_success.png')
		// 		&& !key.contains('editors/notification_warn.png')) // for haxeui is a bit hacky will do for now //find out hwo to avoid haxeui nicer or just do a different caching method //rewrite soonish ok.
		// 	{
		// 		disposeGraphic(FlxG.bitmap.get(key));
		// 	}
		// }
		
		// clear all sounds that are cached
		for (key in currentTrackedSounds.keys())
		{
			if (!localTrackedAssets.contains(key) && !currentTrackedSounds.permanentKeys.contains(key))
			{
				removeFromCache(key);
			}
		}
		// flags everything to be cleared out next unused memory clear
		localTrackedAssets.resize(0);
		openfl.Assets.cache.clear("songs");
	}
	
	/**
	 * Clears the graphics cache of any inactive graphics.
	 */
	public function clearUnusedMemory()
	{
		for (key in currentTrackedGraphics.keys())
		{
			if (!localTrackedAssets.contains(key) && !currentTrackedGraphics.permanentKeys.contains(key))
			{
				removeFromCache(key);
			}
		}
		
		openfl.system.System.gc();
		#if cpp
		cpp.vm.Gc.compact();
		#end
	}
	
	function new() {}
	
	public final currentTrackedGraphics:CacheMap<FlxGraphic> = new CacheMap();
	
	public final currentTrackedSounds:CacheMap<Sound> = new CacheMap();
	
	public final localTrackedAssets:Array<String> = [];
	
	/**
	 * Removes a asset from the cache
	 * @param key 
	 * @param disposeToo 
	 * @return Bool
	 */
	public function removeFromCache(key:String, disposeToo:Bool = true):Bool
	{
		if (currentTrackedGraphics.exists(key))
		{
			if (disposeToo) disposeGraphic(currentTrackedGraphics.get(key));
			currentTrackedGraphics.remove(key);
			
			#if VERBOSE_LOGS
			Logger.log('Cleared Graphic [$key]');
			#end
			
			return true;
		}
		
		if (currentTrackedSounds.exists(key))
		{
			if (disposeToo) Assets.cache.clear(key);
			currentTrackedSounds.remove(key);
			
			#if VERBOSE_LOGS
			Logger.log('Cleared Sound [$key]');
			#end
			
			return true;
		}
		
		return false;
	}
	
	/**
	 * Disposes of a flxgraphic
	 * 
	 * frees its gpu texture as well.
	 * @param graphic 
	 */
	public function disposeGraphic(graphic:Null<FlxGraphic>)
	{
		if (graphic != null && graphic.bitmap != null && graphic.bitmap.__texture != null) graphic.bitmap.__texture.dispose();
		@:nullSafety(Off) FlxG.bitmap.remove(graphic);
	}
	
	/**
	 * Caches and returns a new `FlxGraphic` instance.
	 * @param key the id to use in the cache.
	 * @param bitmap The bitmap to use.
	 * @param allowGPU if true, will only store in video memory.
	 */
	public function cacheBitmap(key:String, bitmap:BitmapData, allowGPU:Bool = true):FlxGraphic
	{
		if (allowGPU && ClientPrefs.gpuCaching)
		{
			bitmap.disposeImage();
		}
		
		var newGraphic:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, key);
		newGraphic.persist = true;
		newGraphic.destroyOnNoUse = false;
		
		localTrackedAssets.push(key);
		currentTrackedGraphics.set(key, newGraphic);
		return newGraphic;
	}
	
	public function cacheSound(key:String, sound:Sound):Sound
	{
		currentTrackedSounds.set(key, sound);
		
		localTrackedAssets.push(key);
		
		return sound;
	}
	
	public function toString():String
	{
		final bmpCache = [for (key in currentTrackedGraphics.keys()) key];
		final sndCache = [for (key in currentTrackedSounds.keys()) key];
		
		return 'Bmp Cache: $bmpCache\nSnd Cache: $sndCache';
	}
}
