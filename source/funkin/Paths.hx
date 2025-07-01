package funkin;

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
	
	public static var currentLevel:Null<String> = null;
	
	static public function setCurrentLevel(?name:String):Void
	{
		currentLevel = name?.toLowerCase() ?? null;
	}
	
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
		
		if (currentLevel != null)
		{
			var levelPath:String = getLibraryPathForce(file, currentLevel);
			
			if (FunkinAssets.exists(levelPath, type)) return levelPath;
		}
		
		#if ASSET_REDIRECT
		final embedCheck = getPrimaryPath().replace(CORE_DIRECTORY, 'assets') + file;
		if (Assets.exists(embedCheck)) return embedCheck;
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
	
	public static inline function modsNoteskin(key:String)
	{
		return modFolders('noteskins/$key.json');
	}
	
	public static inline function lua(key:String, ?library:String):String
	{
		return getPath('$key.lua', TEXT, library);
	}
	
	static public function video(key:String):String
	{
		#if MODS_ALLOWED
		var file:String = modsVideo(key);
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
		final key = Paths.getPath('sounds/$key.$SOUND_EXT', SOUND, library, true);
		
		return FunkinAssets.getSound(key);
	}
	
	public static inline function soundRandom(key:String, min:Int, max:Int, ?library:String):Null<openfl.media.Sound>
	{
		return sound(key + FlxG.random.int(min, max), library);
	}
	
	public static inline function music(key:String, ?library:String):Null<openfl.media.Sound>
	{
		final path = Paths.getPath('music/$key.$SOUND_EXT', SOUND, library, true);
		
		return FunkinAssets.getSound(path);
	}
	
	public static inline function voices(song:String, ?postFix:String, safety:Bool = true):Null<openfl.media.Sound>
	{
		var songKey:String = '${formatToSongPath(song)}/Voices';
		if (postFix != null) songKey += '-$postFix';
		
		songKey = Paths.getPath('songs/$songKey.$SOUND_EXT', SOUND, null, true);
		
		return FunkinAssets.getSound(songKey, true, safety);
	}
	
	public static inline function inst(song:String):Null<openfl.media.Sound>
	{
		var songKey:String = '${formatToSongPath(song)}/Inst';
		
		songKey = Paths.getPath('songs/$songKey.$SOUND_EXT', SOUND, null, true);
		
		return FunkinAssets.getSound(songKey);
	}
	
	public static inline function image(key:String, ?library:String, allowGPU:Bool = true):Null<FlxGraphic>
	{
		final key = Paths.getPath('images/$key.png', IMAGE, library, true);
		
		return FunkinAssets.getGraphic(key, true, allowGPU);
	}
	
	static public function getTextFromFile(key:String, ignoreMods:Bool = false):String
	{
		#if sys
		#if MODS_ALLOWED
		if (!ignoreMods && FileSystem.exists(modFolders(key))) return File.getContent(modFolders(key));
		#end
		
		if (FileSystem.exists(getPrimaryPath(key))) return File.getContent(getPrimaryPath(key));
		
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
		
		if (FunkinAssets.exists(getPath(key, type)))
		{
			return true;
		}
		return false;
	}
	
	public static inline function getMultiAtlas(keys:Array<String>, ?library:String, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		// todo add wat for this to work with fucking uhhhhh packeratlas
		var frames = Paths.getSparrowAtlas(keys.shift().trim(), library, allowGPU);
		
		if (keys.length != 0)
		{
			for (i in keys)
			{
				final newFrames = getSparrowAtlas(i.trim(), library, allowGPU);
				if (newFrames != null)
				{
					frames.addAtlas(newFrames, true);
				}
			}
		}
		return frames;
	}
	
	public static inline function getSparrowAtlas(key:String, ?library:String, ?allowGPU:Bool = true):FlxAtlasFrames
	{
		final xml = getPath('images/$key.xml', TEXT, library, true);
		final img = image(key, library, allowGPU);
		
		return FlxAtlasFrames.fromSparrow(img, FunkinAssets.getContent(xml));
	}
	
	public static inline function getPackerAtlas(key:String, ?library:String, ?allowGPU:Bool = true)
	{
		#if MODS_ALLOWED
		var imageLoaded:FlxGraphic = image(key, library, allowGPU);
		var txtExists:Bool = false;
		if (FileSystem.exists(modsTxt(key)))
		{
			txtExists = true;
		}
		
		return FlxAtlasFrames.fromSpriteSheetPacker((imageLoaded != null ? imageLoaded : image(key, library, allowGPU)),
			(txtExists ? File.getContent(modsTxt(key)) : getPath('images/$key.txt', TEXT, library)));
		#else
		return FlxAtlasFrames.fromSpriteSheetPacker(image(key, library, allowGPU), getPath('images/$key.txt', TEXT, library));
		#end
	}
	
	public static inline function formatToSongPath(path:String):String
	{
		return path.toLowerCase().replace(' ', '-');
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
	
	static public function modFolders(key:String):String
	{
		if (Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
		{
			var fileToCheck:String = mods(Mods.currentModDirectory + '/' + key);
			if (FileSystem.exists(fileToCheck))
			{
				return fileToCheck;
			}
		}
		
		for (mod in Mods.globalMods)
		{
			var fileToCheck:String = mods(mod + '/' + key);
			if (FileSystem.exists(fileToCheck)) return fileToCheck;
		}
		return '$MODS_DIRECTORY/' + key;
	}
	#end
}
