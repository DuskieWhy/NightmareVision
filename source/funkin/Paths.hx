package funkin;

import openfl.system.System;
import flixel.FlxG;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import lime.utils.Assets;
#if sys
import sys.io.File;
import sys.FileSystem;
#end
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import haxe.Json;
import openfl.media.Sound;

using StringTools;

class Paths
{
	inline public static var SOUND_EXT = #if web "mp3" #else "ogg" #end;
	inline public static var VIDEO_EXT = "mp4";

	#if MODS_ALLOWED
	public static var ignoreModFolders:Array<String> = [
		'characters',
		'custom_events',
		'custom_notetypes',
		'data',
		'songs',
		'music',
		'sounds',
		'shaders',
		'noteskins',
		'videos',
		'images',
		'stages',
		'weeks',
		'fonts',
		'scripts',
		'achievements'
	];
	#end

	public static function excludeAsset(key:String)
	{
		if (!dumpExclusions.contains(key)) dumpExclusions.push(key);
	}

	public static var dumpExclusions:Array<String> = [
		'assets/music/freakyMenu.$SOUND_EXT',
		'assets/shared/music/breakfast.$SOUND_EXT',
		'assets/shared/music/tea-time.$SOUND_EXT',
	];

	/// haya I love you for the base cache dump I took to the max
	public static function clearUnusedMemory()
	{
		// clear non local assets in the tracked assets list
		for (key in currentTrackedAssets.keys())
		{
			// if it is not currently contained within the used local assets
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key))
			{
				// get rid of it
				var obj = currentTrackedAssets.get(key);
				@:privateAccess
				if (obj != null)
				{
					if (obj.bitmap != null && obj.bitmap.__texture != null) obj.bitmap.__texture.dispose();
					openfl.Assets.cache.removeBitmapData(key);
					FlxG.bitmap._cache.remove(key);
					obj.destroy();
					currentTrackedAssets.remove(key);
				}
			}
		}
		// run the garbage collector for good measure lmfao
		System.gc();
		#if cpp
		cpp.vm.Gc.compact();
		#end
	}

	// define the locally tracked assets
	public static var localTrackedAssets:Array<String> = [];

	public static function clearStoredMemory(?cleanUnused:Bool = false)
	{
		// clear anything not in the tracked assets list
		@:privateAccess
		for (key in FlxG.bitmap._cache.keys())
		{
			var obj = FlxG.bitmap._cache.get(key);
			if (obj != null && !currentTrackedAssets.exists(key))
			{
				if (obj.bitmap != null && obj.bitmap.__texture != null) obj.bitmap.__texture.dispose();
				openfl.Assets.cache.removeBitmapData(key);
				FlxG.bitmap._cache.remove(key);
				obj.destroy();
			}
		}

		// clear all sounds that are cached
		for (key in currentTrackedSounds.keys())
		{
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key) && key != null)
			{
				// trace('test: ' + dumpExclusions, key);
				Assets.cache.clear(key);
				currentTrackedSounds.remove(key);
			}
		}
		// flags everything to be cleared out next unused memory clear
		localTrackedAssets = [];
		openfl.Assets.cache.clear("songs");
	}

	static public var currentModDirectory:String = '';
	static public var currentLevel:String;

	static public function setCurrentLevel(name:String)
	{
		currentLevel = name.toLowerCase();
	}

	public static function getPath(file:String, ?type:AssetType = TEXT, ?library:Null<String> = null)
	{
		if (library != null) return getLibraryPath(file, library);

		if (currentLevel != null)
		{
			var levelPath:String = '';
			if (currentLevel != 'shared')
			{
				levelPath = getLibraryPathForce(file, currentLevel);
				if (OpenFlAssets.exists(levelPath, type)) return levelPath;
			}

			levelPath = getLibraryPathForce(file, "shared");
			if (OpenFlAssets.exists(levelPath, type)) return levelPath;
		}

		return getSharedPath(file);
	}

	static public function getLibraryPath(file:String, library = "shared")
	{
		return if (library == "shared") getSharedPath(file); else getLibraryPathForce(file, library);
	}

	inline static function getLibraryPathForce(file:String, library:String)
	{
		var returnPath = '$library:assets/$library/$file';
		return returnPath;
	}

	inline public static function getSharedPath(file:String = '')
	{
		return 'assets/shared/$file';
	}

	inline static public function file(file:String, type:AssetType = TEXT, ?library:String)
	{
		return getPath(file, type, library);
	}

	inline static public function txt(key:String, ?library:String)
	{
		return getPath('data/$key.txt', TEXT, library);
	}

	inline static public function xml(key:String, ?library:String)
	{
		return getPath('data/$key.xml', TEXT, library);
	}

	inline static public function json(key:String, ?library:String)
	{
		return getPath('songs/$key.json', TEXT, library);
	}

	inline static public function noteskin(key:String, ?library:String)
	{
		return getPath('noteskins/$key.json', TEXT, library);
	}

	inline static public function modsNoteskin(key:String)
	{
		return modFolders('noteskins/$key.json');
	}

	inline static public function shaderFragment(key:String, ?library:String)
	{
		return getPath('shaders/$key.frag', TEXT, library);
	}

	inline static public function shaderVertex(key:String, ?library:String)
	{
		return getPath('shaders/$key.vert', TEXT, library);
	}

	inline static public function lua(key:String, ?library:String)
	{
		return getPath('$key.lua', TEXT, library);
	}

	inline static public function getContent(asset:String):Null<String>
	{
		#if sys
		if (FileSystem.exists(asset)) return File.getContent(asset);
		#end
		if (Assets.exists(asset)) return Assets.getText(asset);

		trace('oh no its returning null NOOOO ($asset)');
		return null;
	}

	static public function video(key:String)
	{
		#if MODS_ALLOWED
		var file:String = modsVideo(key);
		if (FileSystem.exists(file))
		{
			return file;
		}
		#end
		return 'assets/videos/$key.$VIDEO_EXT';
	}

	inline static public function modTextureAtlas(key:String)
	{
		return modFolders('images/$key');
	}

	static public function textureAtlas(key:String, ?library:String)
	{
		var modp = modTextureAtlas(key);
		if (FileSystem.exists(modp)) return modp;

		return getPath(key, AssetType.BINARY, library);
	}

	static public function sound(key:String, ?library:String):Sound
	{
		var sound:Sound = returnSound('sounds', key, library);
		return sound;
	}

	inline static public function soundRandom(key:String, min:Int, max:Int, ?library:String)
	{
		return sound(key + FlxG.random.int(min, max), library);
	}

	inline static public function music(key:String, ?library:String):Sound
	{
		var file:Sound = returnSound('music', key, library);
		return file;
	}

	inline static public function voices(song:String, ?postFix:String):Null<openfl.media.Sound>
	{
		var songKey:String = '${formatToSongPath(song)}/Voices';
		if (postFix != null) songKey += '-$postFix';
		var voices = returnSound(null, songKey, 'songs');
		return voices;
	}

	inline static public function inst(song:String):Null<openfl.media.Sound>
	{
		var songKey:String = '${formatToSongPath(song)}/Inst';
		var inst = returnSound(null, songKey, 'songs');
		return inst;
	}

	inline static public function modsShaderFragment(key:String, ?library:String) return modFolders('shaders/' + key + '.frag');

	inline static public function modsShaderVertex(key:String, ?library:String) return modFolders('shaders/' + key + '.vert');

	inline static public function image(key:String, ?library:String):FlxGraphic
	{
		// streamlined the assets process more
		return returnGraphic(key, library);
	}

	static public function getTextFromFile(key:String, ?ignoreMods:Bool = false):String
	{
		#if sys
		#if MODS_ALLOWED
		if (!ignoreMods && FileSystem.exists(modFolders(key))) return File.getContent(modFolders(key));
		#end

		if (FileSystem.exists(getSharedPath(key))) return File.getContent(getSharedPath(key));

		if (currentLevel != null)
		{
			var levelPath:String = '';
			if (currentLevel != 'shared')
			{
				levelPath = getLibraryPathForce(key, currentLevel);
				if (FileSystem.exists(levelPath)) return File.getContent(levelPath);
			}

			levelPath = getLibraryPathForce(key, 'shared');
			if (FileSystem.exists(levelPath)) return File.getContent(levelPath);
		}
		#end
		return Assets.getText(getPath(key, TEXT));
	}

	inline static public function font(key:String)
	{
		#if MODS_ALLOWED
		var file:String = modsFont(key);
		if (FileSystem.exists(file))
		{
			return file;
		}
		#end
		return 'assets/fonts/$key';
	}

	inline static public function fileExists(key:String, type:AssetType, ?ignoreMods:Bool = false, ?library:String)
	{
		#if MODS_ALLOWED
		if (FileSystem.exists(mods(currentModDirectory + '/' + key)) || FileSystem.exists(mods(key)))
		{
			return true;
		}
		#end

		if (OpenFlAssets.exists(getPath(key, type)))
		{
			return true;
		}
		return false;
	}

	inline static public function getSparrowAtlas(key:String, ?library:String):FlxAtlasFrames
	{
		#if MODS_ALLOWED
		var imageLoaded:FlxGraphic = returnGraphic(key);
		var xmlExists:Bool = false;
		var xml = modsXml(key);
		if (FileSystem.exists(modsXml(key)))
		{
			xmlExists = true;
		}

		if (!xmlExists)
		{
			xml = getPath('images/$key.xml', null, library);
			if (FileSystem.exists(xml)) xmlExists = true;
		}

		return FlxAtlasFrames.fromSparrow((imageLoaded != null ? imageLoaded : image(key, library)),
			(xmlExists ? File.getContent(xml) : getPath('images/$key.xml', null, library)));
		#else
		return FlxAtlasFrames.fromSparrow(image(key, library), file('images/$key.xml', library));
		#end
	}

	inline static public function getPackerAtlas(key:String, ?library:String)
	{
		#if MODS_ALLOWED
		var imageLoaded:FlxGraphic = returnGraphic(key);
		var txtExists:Bool = false;
		if (FileSystem.exists(modsTxt(key)))
		{
			txtExists = true;
		}

		return FlxAtlasFrames.fromSpriteSheetPacker((imageLoaded != null ? imageLoaded : image(key, library)),
			(txtExists ? File.getContent(modsTxt(key)) : file('images/$key.txt', library)));
		#else
		return FlxAtlasFrames.fromSpriteSheetPacker(image(key, library), file('images/$key.txt', library));
		#end
	}

	inline static public function formatToSongPath(path:String)
	{
		return path.toLowerCase().replace(' ', '-');
	}

	// completely rewritten asset loading? fuck!
	public static var currentTrackedAssets:Map<String, FlxGraphic> = [];

	public static function returnGraphic(key:String, ?library:String, ?allowGPU:Bool = true)
	{
		var bitmap:BitmapData = null;
		var file:String = null;

		#if MODS_ALLOWED
		file = modsImages(key);
		if (currentTrackedAssets.exists(file))
		{
			localTrackedAssets.push(file);
			return currentTrackedAssets.get(file);
		}
		else if (FileSystem.exists(file)) bitmap = BitmapData.fromFile(file);
		else
		#end
		{
			file = getPath('images/$key.png', IMAGE, library);
			if (currentTrackedAssets.exists(file))
			{
				localTrackedAssets.push(file);
				return currentTrackedAssets.get(file);
			}
			else if (FileSystem.exists(file))
			{
				bitmap = BitmapData.fromFile(file);
			}
			else if (OpenFlAssets.exists(file, IMAGE))
			{
				bitmap = OpenFlAssets.getBitmapData(file);
			}
		}

		if (bitmap != null)
		{
			var retVal = cacheBitmap(file, bitmap, allowGPU);
			if (retVal != null) return retVal;
		}

		trace('oh no its returning null NOOOO ($file)');
		return null;
	}

	static public function cacheBitmap(file:String, ?bitmap:BitmapData = null, ?allowGPU:Bool = true)
	{
		if (bitmap == null)
		{
			#if MODS_ALLOWED
			if (FileSystem.exists(file)) bitmap = BitmapData.fromFile(file);
			else
			#end
			{
				if (OpenFlAssets.exists(file, IMAGE)) bitmap = OpenFlAssets.getBitmapData(file);
			}

			if (bitmap == null) return null;
		}

		localTrackedAssets.push(file);
		if (allowGPU && ClientPrefs.gpuCaching)
		{
			var texture:openfl.display3D.textures.RectangleTexture = FlxG.stage.context3D.createRectangleTexture(bitmap.width, bitmap.height, BGRA, true);
			texture.uploadFromBitmapData(bitmap);
			bitmap.image.data = null;
			bitmap.dispose();
			bitmap.disposeImage();
			bitmap = BitmapData.fromTexture(texture);
		}
		var newGraphic:FlxGraphic = FlxGraphic.fromBitmapData(bitmap, false, file);
		newGraphic.persist = true;
		newGraphic.destroyOnNoUse = false;
		currentTrackedAssets.set(file, newGraphic);
		return newGraphic;
	}

	public static var currentTrackedSounds:Map<String, Sound> = [];

	public static function returnSound(path:Null<String>, key:String, ?library:String)
	{
		#if MODS_ALLOWED
		var modLibPath:String = '';
		if (library != null) modLibPath = '$library';
		if (path != null) modLibPath += '$path';

		var file:String = modsSounds(modLibPath, key);
		if (FileSystem.exists(file))
		{
			if (!currentTrackedSounds.exists(file))
			{
				currentTrackedSounds.set(file, Sound.fromFile(file));
			}
			localTrackedAssets.push(file);
			return currentTrackedSounds.get(file);
		}
		#end

		// I hate this so god damn much
		var gottenPath:String = '$key.$SOUND_EXT';
		if (path != null) gottenPath = '$path/$gottenPath';
		gottenPath = strip(getPath(gottenPath, SOUND, library));
		// trace(gottenPath);
		if (!currentTrackedSounds.exists(gottenPath))
		{
			var retKey:String = (path != null) ? '$path/$key' : key;
			retKey = ((path == 'songs') ? 'songs:' : '') + getPath('$retKey.$SOUND_EXT', SOUND, library);
			if (OpenFlAssets.exists(retKey, SOUND))
			{
				// embedded sound
				currentTrackedSounds.set(gottenPath, OpenFlAssets.getSound(retKey));
			}
		}

		localTrackedAssets.push(gottenPath);
		return currentTrackedSounds.get(gottenPath);
	}

	inline public static function strip(path:String) return path.indexOf(':') != -1 ? path.substr(path.indexOf(':') + 1, path.length) : path;

	#if MODS_ALLOWED
	inline static public function mods(key:String = '')
	{
		return 'content/' + key;
	}

	inline static public function modsFont(key:String)
	{
		return modFolders('fonts/' + key);
	}

	inline static public function modsJson(key:String)
	{
		return modFolders('songs/' + key + '.json');
	}

	inline static public function modsVideo(key:String)
	{
		return modFolders('videos/' + key + '.' + VIDEO_EXT);
	}

	inline static public function modsSounds(path:String, key:String)
	{
		return modFolders(path + '/' + key + '.' + SOUND_EXT);
	}

	inline static public function modsImages(key:String)
	{
		return modFolders('images/' + key + '.png');
	}

	inline static public function modsXml(key:String)
	{
		return modFolders('images/' + key + '.xml');
	}

	inline static public function modsTxt(key:String)
	{
		return modFolders('images/' + key + '.txt');
	}

	/* Goes unused for now

		inline static public function modsShaderFragment(key:String, ?library:String)
		{
			return modFolders('shaders/'+key+'.frag');
		}
		inline static public function modsShaderVertex(key:String, ?library:String)
		{
			return modFolders('shaders/'+key+'.vert');
		}
		inline static public function modsAchievements(key:String) {
			return modFolders('achievements/' + key + '.json');
	}*/
	static public function modFolders(key:String, global:Bool = true)
	{
		if (currentModDirectory != null && currentModDirectory.length > 0)
		{
			var fileToCheck:String = mods(currentModDirectory + '/' + key);
			if (FileSystem.exists(fileToCheck))
			{
				return fileToCheck;
			}
		}

		var lol = getModDirectories();
		if (global) lol = getGlobalMods();

		for (mod in lol)
		{
			var fileToCheck:String = mods(mod + '/' + key);
			if (FileSystem.exists(fileToCheck)) return fileToCheck;
		}
		return 'content/' + key;
	}

	public static var globalMods:Array<String> = [];

	static public function getGlobalMods() return globalMods;

	static public function pushGlobalMods()
	{ // prob a better way to do this but idc
		globalMods = [];
		if (FileSystem.exists("modsList.txt"))
		{
			var list:Array<String> = CoolUtil.listFromString(File.getContent("modsList.txt"));
			for (i in list)
			{
				var dat = i.split("|");
				if (dat[1] == "1")
				{
					var folder = dat[0];
					var path = Paths.mods(folder + '/pack.json');
					if (FileSystem.exists(path))
					{
						try
						{
							var rawJson:String = File.getContent(path);
							if (rawJson != null && rawJson.length > 0)
							{
								var stuff:Dynamic = Json.parse(rawJson);
								var global:Bool = Reflect.getProperty(stuff, "runsGlobally");
								if (global) globalMods.push(dat[0]);
							}
						}
						catch (e:Dynamic)
						{
							// trace(e);
						}
					}
				}
			}
		}
		return globalMods;
	}

	static public function getModDirectories():Array<String>
	{
		var list:Array<String> = [];
		var modsFolder:String = mods();
		if (FileSystem.exists(modsFolder))
		{
			for (folder in FileSystem.readDirectory(modsFolder))
			{
				var path = haxe.io.Path.join([modsFolder, folder]);
				if (sys.FileSystem.isDirectory(path) && !ignoreModFolders.contains(folder) && !list.contains(folder))
				{
					list.push(folder);
				}
			}
		}
		return list;
	}
	#end
}
