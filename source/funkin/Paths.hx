package funkin;

import haxe.io.Path;
import haxe.Json;

import openfl.system.System;
import openfl.utils.AssetType;
import openfl.utils.Assets;
import openfl.display.BitmapData;
import openfl.media.Sound;

import flixel.FlxG;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.FlxGraphic;

// @:nullSafety

/**
 * Primary class used to simplify retrieving and finding assets.
 */
class Paths
{
	#if ASSET_REDIRECT
	public static inline final trail = #if macos '../../../../../../../' #else '../../../../' #end;
	#end
	
	/**
	 * Primary asset directory
	 */
	public static inline final CORE_DIRECTORY = #if ASSET_REDIRECT trail + 'assets/game' #else 'assets' #end;
	
	/**
	 * Mod directory
	 */
	public static inline final MODS_DIRECTORY = #if ASSET_REDIRECT trail + 'content' #else 'content' #end;
	
	public static inline final SOUND_EXT = "ogg";
	public static inline final VIDEO_EXT = "mp4";
	
	// thinking of removing parentfolder its pointless ?
	public static function getPath(file:String, ?type:AssetType = TEXT, ?parentFolder:String, checkMods:Bool = false):String
	{
		#if MODS_ALLOWED
		if (checkMods)
		{
			final modPath:String = modFolders(parentFolder == null ? file : parentFolder + '/' + file);
			
			if (FileSystem.exists(modPath)) return modPath;
		}
		#end
		
		if (parentFolder != null) return getLibraryPath(file, parentFolder);
		
		#if ASSET_REDIRECT
		final embedCheck = getPrimaryPath().replace(CORE_DIRECTORY, trail + 'assets/embeds') + file;
		if (FunkinAssets.exists(embedCheck))
		{
			return embedCheck;
		}
		#end
		
		return getPrimaryPath(file);
	}
	
	public static function getLibraryPath(file:String, parentFolder:Null<String>):String
	{
		return parentFolder == null ? getPrimaryPath(file) : getLibraryPathForce(file, parentFolder);
	}
	
	static inline function getLibraryPathForce(file:String, library:String):String
	{
		return '$CORE_DIRECTORY/$library/$file';
	}
	
	public static inline function getPrimaryPath(file:String = ''):String
	{
		return '$CORE_DIRECTORY/$file';
	}
	
	public static inline function txt(key:String, ?library:String):String
	{
		return getPath('data/$key.txt', TEXT, library, true);
	}
	
	public static inline function xml(key:String, ?library:String):String
	{
		return getPath('data/$key.xml', TEXT, library, true);
	}
	
	public static inline function json(key:String, ?library:String):String
	{
		return getPath('songs/$key.json', TEXT, library, true);
	}
	
	public static inline function noteskin(key:String, ?library:String):String
	{
		return getPath('noteskins/$key.json', TEXT, library, true);
	}
	
	public static inline function shaderFrag(key:String):String
	{
		return getPath('shaders/$key.frag', TEXT, null, true);
	}
	
	public static inline function shaderVert(key:String):String
	{
		return getPath('shaders/$key.vert', TEXT, null, true);
	}
	
	static public function video(key:String):String
	{
		#if MODS_ALLOWED
		final file:String = modsVideo(key);
		if (FileSystem.exists(file))
		{
			return file;
		}
		#end
		return '$CORE_DIRECTORY/videos/$key.$VIDEO_EXT';
	}
	
	static public function textureAtlas(key:String, ?library:String):String
	{
		return getPath('images/$key', AssetType.BINARY, library, true);
	}
	
	static public function sound(key:String, ?library:String):Null<openfl.media.Sound>
	{
		final key = getPath('sounds/$key.$SOUND_EXT', SOUND, library, true);
		
		return FunkinAssets.getSound(key);
	}
	
	public static inline function soundRandom(key:String, min:Int, max:Int, ?library:String):Null<openfl.media.Sound>
	{
		return sound(key + FlxG.random.int(min, max), library);
	}
	
	public static inline function music(key:String, ?library:String):Null<openfl.media.Sound>
	{
		final path = getPath('music/$key.$SOUND_EXT', SOUND, library, true);
		
		return FunkinAssets.getSound(path);
	}
	
	public static inline function voices(song:String, ?postFix:String, safety:Bool = true):Null<openfl.media.Sound>
	{
		var songKey:String = '${formatToSongPath(song)}/Voices';
		if (postFix != null) songKey += '-$postFix';
		
		songKey = getPath('songs/$songKey.$SOUND_EXT', SOUND, null, true);
		
		return FunkinAssets.getSound(songKey, true, safety);
	}
	
	public static inline function inst(song:String):Null<openfl.media.Sound>
	{
		var songKey:String = '${formatToSongPath(song)}/Inst';
		
		songKey = getPath('songs/$songKey.$SOUND_EXT', SOUND, null, true);
		
		return FunkinAssets.getSound(songKey);
	}
	
	public static inline function image(key:String, ?library:String, allowGPU:Bool = true):FlxGraphic
	{
		final key = getPath('images/$key.png', IMAGE, library, true);
		
		final cacheGraphic = FunkinAssets.getGraphic(key, true, allowGPU);
		
		if (cacheGraphic == null)
		{
			return FlxG.bitmap.add('flixel/images/logo/default.png'); // to be compliant with nullsafety
		}
		else
		{
			return cacheGraphic;
		}
	}
	
	// uise this more
	public static function findFileWithExts(file:String, exts:Array<String>):String
	{
		for (ext in exts)
		{
			final joined = getPath('$file.$ext', TEXT, null, true);
			if (FunkinAssets.exists(joined)) return joined;
		}
		
		return getPath('$file.${exts[0]}', TEXT, null, true);
	}
	
	static public function getTextFromFile(key:String, ignoreMods:Bool = false):String
	{
		final path = Paths.getPath(key, TEXT, null, !ignoreMods);
		
		return FunkinAssets.getContent(path);
	}
	
	public static inline function font(key:String):String
	{
		#if MODS_ALLOWED
		var file:String = modsFont(key);
		if (FileSystem.exists(file))
		{
			return file;
		}
		#end
		return '$CORE_DIRECTORY/fonts/$key';
	}
	
	public static inline function fileExists(key:String, type:AssetType, ?ignoreMods:Bool = false, ?library:String):Bool
	{
		#if MODS_ALLOWED
		if (FileSystem.exists(mods(Mods.currentModDirectory + '/' + key)) || FileSystem.exists(mods(key)))
		{
			return true;
		}
		#end
		
		return FunkinAssets.exists(getPath(key, type));
	}
	
	public static inline function getMultiAtlas(keys:Array<String>, ?library:String, ?allowGPU:Bool = true):FlxAtlasFrames // from psych
	{
		// todo add wat for this to work with fucking uhhhhh packeratlas
		var frames = getAtlasFrames(keys.shift().trim(), library, allowGPU);
		
		if (keys.length != 0)
		{
			// odd
			final originalCollection = frames;
			frames = new FlxAtlasFrames(originalCollection.parent);
			frames.addAtlas(originalCollection, true);
			for (i in keys)
			{
				final newFrames = getAtlasFrames(i.trim(), library, allowGPU);
				if (newFrames != null)
				{
					frames.addAtlas(newFrames, false); // ? okay
				}
			}
		}
		return frames;
	}
	
	/**
	 * Retrieves atlas frames of either `sparrow` or `packer` 
	 * @param key 
	 * @param library 
	 * @param allowGPU 
	 */
	public static inline function getAtlasFrames(key:String, ?library:String, allowGPU:Bool = true):FlxAtlasFrames
	{
		final xmlPath = getPath('images/$key.xml', TEXT, library, true);
		final txtPath = getPath('images/$key.txt', TEXT, library, true);
		
		final graphic = image(key, library, allowGPU);
		
		// packer
		if (FunkinAssets.exists(txtPath))
		{
			return FlxAtlasFrames.fromSpriteSheetPacker(graphic, FunkinAssets.getContent(txtPath));
		}
		
		return FlxAtlasFrames.fromSparrow(graphic, FunkinAssets.getContent(xmlPath));
	}
	
	public static inline function getSparrowAtlas(key:String, ?library:String, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		final xml = getPath('images/$key.xml', TEXT, library, true);
		final img = image(key, library, allowGPU);
		
		return FlxAtlasFrames.fromSparrow(img, FunkinAssets.getContent(xml));
	}
	
	public static inline function getPackerAtlas(key:String, ?library:String, ?allowGPU:Bool = true)
	{
		return FlxAtlasFrames.fromSpriteSheetPacker(image(key, library, allowGPU), FunkinAssets.getContent(getPath('images/$key.txt', TEXT, library, true)));
	}
	
	public static inline function formatToSongPath(path:String):String
	{
		return path.toLowerCase().replace(' ', '-');
	}
	
	/**
	 * Lists all files found within a given directory
	 * 
	 * if `checkMods`, they will be loaded in order of
	 * 
	 * `content/globalMods/`, `content/`, `content/currentMod/`.
	 */
	public static function listAllFilesInDirectory(directory:String, checkMods:Bool = true) // based of psychs Mods.directoriesWithFile
	{
		// todo maybe make this recursive ?
		var folders:Array<String> = [];
		var files:Array<String> = [];
		
		if (FunkinAssets.exists(getPrimaryPath(directory))) folders.push(getPrimaryPath(directory));
		
		#if MODS_ALLOWED
		if (checkMods)
		{
			for (mod in Mods.globalMods)
			{
				final folder = mods('$mod/$directory');
				if (FileSystem.exists(folder) && !folders.contains(folder)) folders.push(folder);
			}
			
			final folder = mods(directory);
			if (FileSystem.exists(folder) && !folders.contains(folder)) folders.push(folder);
			
			if (Mods.currentModDirectory?.length > 0)
			{
				final folder = mods('${Mods.currentModDirectory}/$directory');
				if (FileSystem.exists(folder) && !folders.contains(folder)) folders.push(folder);
			}
		}
		#end
		
		for (folder in folders)
		{
			for (file in FunkinAssets.readDirectory(folder))
			{
				final path = Path.join([folder, file]);
				if (!files.contains(path)) files.push(path);
			}
		}
		
		return files;
	}
	
	#if MODS_ALLOWED
	public static inline function mods(key:String = ''):String
	{
		return '$MODS_DIRECTORY/' + key;
	}
	
	public static inline function modsFont(key:String):String
	{
		return modFolders('fonts/' + key);
	}
	
	public static inline function modsJson(key:String):String
	{
		return modFolders('songs/' + key + '.json');
	}
	
	public static inline function modsVideo(key:String):String
	{
		return modFolders('videos/' + key + '.' + VIDEO_EXT);
	}
	
	public static inline function modsSounds(path:String, key:String):String
	{
		return modFolders(path + '/' + key + '.' + SOUND_EXT);
	}
	
	public static inline function modsImages(key:String):String
	{
		return modFolders('images/' + key + '.png');
	}
	
	public static inline function modsXml(key:String):String
	{
		return modFolders('images/' + key + '.xml');
	}
	
	public static inline function modsTxt(key:String):String
	{
		return modFolders('images/' + key + '.txt');
	}
	
	public static inline function modsNoteskin(key:String)
	{
		return modFolders('noteskins/$key.json');
	}
	
	static public function modFolders(key:String):String
	{
		if (Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
		{
			final fileToCheck:String = mods(Mods.currentModDirectory + '/' + key);
			if (FileSystem.exists(fileToCheck))
			{
				return fileToCheck;
			}
		}
		
		for (mod in Mods.globalMods)
		{
			final fileToCheck:String = mods(mod + '/' + key);
			if (FileSystem.exists(fileToCheck)) return fileToCheck;
		}
		return '$MODS_DIRECTORY/$key';
	}
	#end
}
