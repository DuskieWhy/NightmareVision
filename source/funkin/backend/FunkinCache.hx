package funkin.backend;

import openfl.Assets;

import flixel.graphics.FlxGraphic;
import flixel.system.FlxAssets;

import openfl.display.BitmapData;
import openfl.media.Sound;

@:access(openfl.display.BitmapData)
@:nullSafety
class FunkinCache
{
	/**
	 * Clears all graphics and sounds that are considered inactive. Flags everything to be inactive as well.
	 * 
	 * use `clearUnusedMemory` afterwards to purge everything
	 */
	public function clearStoredMemory()
	{
		@:privateAccess
		for (key in FlxG.bitmap._cache.keys())
		{
			if (!currentTrackedGraphics.exists(key) && !key.startsWith('NMV_DEBUG'))
			{
				disposeGraphic(FlxG.bitmap.get(key));
			}
		}
		
		// clear all sounds that are cached
		for (key in currentTrackedSounds.keys())
		{
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key) && key != null)
			{
				Assets.cache.clear(key);
				currentTrackedSounds.remove(key);
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
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key))
			{
				disposeGraphic(currentTrackedGraphics.get(key));
				currentTrackedGraphics.remove(key);
			}
		}
		
		openfl.system.System.gc();
		#if cpp
		cpp.vm.Gc.compact();
		#end
	}
	
	public function new() {}
	
	public final currentTrackedGraphics:Map<String, FlxGraphic> = [];
	
	public final currentTrackedSounds:Map<String, Sound> = [];
	
	public final localTrackedAssets:Array<String> = [];
	
	public final dumpExclusions:Array<String> = ['assets/music/freakyMenu.${Paths.SOUND_EXT}'];
	
	public function excludeAsset(key:String)
	{
		if (!dumpExclusions.contains(key)) dumpExclusions.push(key);
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
			if (bitmap.__texture == null)
			{
				bitmap.image.premultiplied = true;
				bitmap.getTexture(FlxG.stage.context3D);
			}
			bitmap.getSurface();
			bitmap.disposeImage();
			
			@:nullSafety(Off)
			{
				bitmap.image.data = null;
				bitmap.image = null;
			}
			
			bitmap.readable = true;
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
}
