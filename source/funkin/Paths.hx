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
	
	public static function getPath(file:String, ?type:AssetType = TEXT, ?parentFolder:String, checkMods:Bool = false):String
	{
		if (parentFolder != null) file = '$parentFolder/$file';
		
		#if MODS_ALLOWED
		if (checkMods)
		{
			final modPath:String = modFolders(file);
			
			if (FileSystem.exists(modPath)) return modPath;
		}
		#end
		
		#if ASSET_REDIRECT
		final embedPath = getCorePath().replace(CORE_DIRECTORY, trail + 'assets/embeds') + file;
		if (FunkinAssets.exists(embedPath)) return embedPath;
		#end
		
		return getCorePath(file);
	}
	
	public static inline function getCorePath(file:String = ''):String
	{
		return '$CORE_DIRECTORY/$file';
	}
	
	public static inline function txt(key:String, ?parentFolder:String, checkMods:Bool = true):String
	{
		return getPath('data/$key.txt', TEXT, parentFolder, checkMods);
	}
	
	public static inline function xml(key:String, ?parentFolder:String, checkMods:Bool = true):String
	{
		return getPath('data/$key.xml', TEXT, parentFolder, checkMods);
	}
	
	public static inline function json(key:String, ?parentFolder:String, checkMods:Bool = true):String
	{
		return getPath('songs/$key.json', TEXT, parentFolder, checkMods);
	}
	
	public static inline function noteskin(key:String, ?parentFolder:String, checkMods:Bool = true):String
	{
		return getPath('noteskins/$key.json', TEXT, parentFolder, checkMods);
	}
	
	public static inline function fragment(key:String, checkMods:Bool = true):String
	{
		return getPath('shaders/$key.frag', TEXT, null, checkMods);
	}
	
	public static inline function vertex(key:String, checkMods:Bool = true):String
	{
		return getPath('shaders/$key.vert', TEXT, null, checkMods);
	}
	
	static public function video(key:String, checkMods:Bool = true):String
	{
		return findFileWithExts('videos/$key', ['mp4', 'mov'], null, checkMods);
	}
	
	static public function textureAtlas(key:String, ?parentFolder:String, checkMods:Bool = true):String
	{
		return getPath('images/$key', BINARY, parentFolder, checkMods);
	}
	
	static public function sound(key:String, ?parentFolder:String, checkMods:Bool = true):Sound
	{
		final key = findFileWithExts('sounds/$key', ['ogg', 'wav'], parentFolder, checkMods);
		
		return FunkinAssets.getSound(key);
	}
	
	public static inline function soundRandom(key:String, min:Int, max:Int, ?parentFolder:String, checkMods:Bool = true):Sound
	{
		return sound(key + FlxG.random.int(min, max), parentFolder, checkMods);
	}
	
	public static inline function music(key:String, ?parentFolder:String, checkMods:Bool = true):Sound
	{
		final key = findFileWithExts('music/$key', ['ogg', 'wav'], parentFolder, checkMods);
		
		return FunkinAssets.getSound(key);
	}
	
	public static inline function voices(song:String, ?postFix:String, checkMods:Bool = true):Null<Sound>
	{
		var songKey:String = '${formatToSongPath(song)}/Voices';
		if (postFix != null) songKey += '-$postFix';
		
		songKey = findFileWithExts('songs/$songKey', ['ogg', 'wav'], null, checkMods);
		
		return FunkinAssets.getSoundUnsafe(songKey);
	}
	
	public static inline function inst(song:String, ?postFix:String, checkMods:Bool = true):Null<openfl.media.Sound>
	{
		var songKey:String = '${formatToSongPath(song)}/Inst';
		if (postFix != null) songKey += '-$postFix';
		
		songKey = findFileWithExts('songs/$songKey', ['ogg', 'wav'], null, checkMods);
		
		return FunkinAssets.getSound(songKey);
	}
	
	public static inline function image(key:String, ?parentFolder:String, allowGPU:Bool = true, checkMods:Bool = true):FlxGraphic
	{
		return FunkinAssets.getGraphic(getPath('images/$key.png', IMAGE, parentFolder, checkMods), true, allowGPU);
	}
	
	public static inline function font(key:String, checkMods:Bool = true):String
	{
		return findFileWithExts('fonts/$key', ['ttf', 'otf'], null, checkMods);
	}
	
	// uise this more
	public static function findFileWithExts(file:String, exts:Array<String>, ?parentFolder:String, checkMods:Bool = true):String
	{
		for (ext in exts)
		{
			final joined = getPath('$file.$ext', TEXT, parentFolder, checkMods);
			if (FunkinAssets.exists(joined)) return joined;
		}
		
		return getPath(file, TEXT, parentFolder, checkMods); // assuming u mightve added a ext already
	}
	
	public static function getTextFromFile(key:String, ?parentFolder:String, checkMods:Bool = true):String
	{
		key = getPath(key, TEXT, parentFolder, checkMods);
		
		return FunkinAssets.exists(key) ? FunkinAssets.getContent(key) : '';
	}
	
	public static inline function fileExists(key:String, type:AssetType = TEXT, ?parentFolder:String, checkMods:Bool = true):Bool
	{
		return FunkinAssets.exists(getPath(key, type, parentFolder, checkMods), type);
	}
	
	public static inline function getMultiAtlas(keys:Array<String>, ?parentFolder:String, ?allowGPU:Bool = true, checkMods:Bool = true):FlxAtlasFrames // from psych
	{
		final firstKey:Null<String> = keys.shift()?.trim();
		
		var frames = getAtlasFrames(firstKey, parentFolder, allowGPU, checkMods);
		
		if (keys.length != 0)
		{
			final originalCollection = frames;
			frames = new FlxAtlasFrames(originalCollection.parent);
			frames.addAtlas(originalCollection, true);
			for (i in keys)
			{
				final newFrames = getAtlasFrames(i.trim(), parentFolder, allowGPU, checkMods);
				if (newFrames != null)
				{
					frames.addAtlas(newFrames, false);
				}
			}
		}
		return frames;
	}
	
	/**
	 * Retrieves atlas frames from either `Sparrow` or `Packer` 
	 * 
	 * `Sparrow` has priority.
	 */
	public static inline function getAtlasFrames(key:String, ?parentFolder:String, allowGPU:Bool = true, checkMods:Bool = true):FlxAtlasFrames
	{
		final xmlPath = getPath('images/$key.xml', TEXT, parentFolder, checkMods);
		final txtPath = getPath('images/$key.txt', TEXT, parentFolder, checkMods);
		
		final graphic = image(key, parentFolder, allowGPU, checkMods);
		
		// sparrow
		if (FunkinAssets.exists(xmlPath))
		{
			@:nullSafety(Off) // until flixel does null safety
			return FlxAtlasFrames.fromSparrow(graphic, FunkinAssets.exists(xmlPath) ? FunkinAssets.getContent(xmlPath) : null);
		}
		
		@:nullSafety(Off) // until flixel does null safety
		return FlxAtlasFrames.fromSpriteSheetPacker(graphic, FunkinAssets.exists(txtPath) ? FunkinAssets.getContent(txtPath) : null);
	}
	
	public static inline function getSparrowAtlas(key:String, ?parentFolder:String, ?allowGPU:Bool = true, checkMods:Bool = true):FlxAtlasFrames
	{
		final xmlPath = getPath('images/$key.xml', TEXT, parentFolder, checkMods);
		@:nullSafety(Off) // until flixel does null safety
		return FlxAtlasFrames.fromSparrow(image(key, parentFolder, allowGPU, checkMods), FunkinAssets.exists(xmlPath) ? FunkinAssets.getContent(xmlPath) : null);
	}
	
	public static inline function getPackerAtlas(key:String, ?parentFolder:String, ?allowGPU:Bool = true, checkMods:Bool = true)
	{
		final txtPath = getPath('images/$key.txt', TEXT, parentFolder, checkMods);
		@:nullSafety(Off) // until flixel does null safety
		return FlxAtlasFrames.fromSpriteSheetPacker(image(key, parentFolder, allowGPU, checkMods), FunkinAssets.exists(txtPath) ? FunkinAssets.getContent(txtPath) : null);
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
		
		if (FunkinAssets.exists(getCorePath(directory))) folders.push(getCorePath(directory));
		
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
			
			if (Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
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
