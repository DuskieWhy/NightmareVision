package funkin;

import openfl.utils.Assets;

import haxe.Json;

// modified from modern psych
// much love okay

typedef ModMeta =
{
	name:String,
	global:Bool
}

typedef ModsList =
{
	enabled:Array<String>,
	disabled:Array<String>,
	all:Array<String>
}

class Mods
{
	/**
	 * The current primary loaded mod
	 */
	static public var currentModDirectory:String = '';
	
	public static final ignoreModFolders:Array<String> = [
		'characters',
		'custom_events',
		'custom_notetypes',
		'data',
		'songs',
		'music',
		'sounds',
		'shaders',
		'videos',
		'images',
		'stages',
		'weeks',
		'fonts',
		'scripts',
		'achievements',
		'noteskins'
	];
	
	/**
	 * makes `modsList.txt` in the case it doesnt exist
	 */
	static function checkFile()
	{
		if (!FunkinAssets.exists('modsList.txt'))
		{
			File.saveContent('modsList.txt', '');
		}
	}
	
	public static var globalMods:Array<String> = [];
	
	/**
	 * Refreshes all globally loaded mods
	 * @return 
	 */
	public static inline function pushGlobalMods():Array<String> // prob a better way to do this but idc
	{
		globalMods = [];
		for (mod in parseList().enabled)
		{
			var pack = getPack(mod);
			if (pack != null && pack.global) globalMods.push(mod);
		}
		
		return globalMods;
	}
	
	public static inline function getModDirectories():Array<String>
	{
		var list:Array<String> = [];
		#if MODS_ALLOWED
		var modsFolder:String = Paths.mods();
		if (FileSystem.exists(modsFolder))
		{
			for (folder in FileSystem.readDirectory(modsFolder))
			{
				var path = haxe.io.Path.join([modsFolder, folder]);
				if (FileSystem.isDirectory(path)
					&& !ignoreModFolders.contains(folder.toLowerCase())
					&& !list.contains(folder)) list.push(folder);
			}
		}
		#end
		return list;
	}
	
	public static inline function mergeAllTextsNamed(path:String, ?defaultDirectory:String = null, allowDuplicates:Bool = false)
	{
		if (defaultDirectory == null) defaultDirectory = Paths.getPrimaryPath();
		defaultDirectory = defaultDirectory.trim();
		if (!defaultDirectory.endsWith('/')) defaultDirectory += '/';
		if (!defaultDirectory.startsWith('assets/')) defaultDirectory = 'assets/$defaultDirectory';
		
		var mergedList:Array<String> = [];
		var paths:Array<String> = directoriesWithFile(defaultDirectory, path);
		
		var defaultPath:String = defaultDirectory + path;
		if (paths.contains(defaultPath))
		{
			paths.remove(defaultPath);
			paths.insert(0, defaultPath);
		}
		
		for (file in paths)
		{
			var list:Array<String> = CoolUtil.coolTextFile(file);
			for (value in list)
				if ((allowDuplicates || !mergedList.contains(value)) && value.length > 0) mergedList.push(value);
		}
		return mergedList;
	}
	
	public static inline function directoriesWithFile(path:String, fileToFind:String, mods:Bool = true)
	{
		var foldersToCheck:Array<String> = [];
		if (FileSystem.exists(path + fileToFind)) foldersToCheck.push(path + fileToFind);
		
		if (Paths.currentLevel != null && Paths.currentLevel != path)
		{
			@:privateAccess
			var pth:String = Paths.getLibraryPathForce(fileToFind, Paths.currentLevel);
			if (FileSystem.exists(pth)) foldersToCheck.push(pth);
		}
		
		#if MODS_ALLOWED
		if (mods)
		{
			// Global mods first
			for (mod in globalMods)
			{
				var folder:String = Paths.mods(mod + '/' + fileToFind);
				if (FileSystem.exists(folder) && !foldersToCheck.contains(folder)) foldersToCheck.push(folder);
			}
			
			// Then "content/" main folder
			var folder:String = Paths.mods(fileToFind);
			if (FileSystem.exists(folder) && !foldersToCheck.contains(folder)) foldersToCheck.push(Paths.mods(fileToFind));
			
			// And lastly, the loaded mod's folder
			if (Mods.currentModDirectory != null && Mods.currentModDirectory.length > 0)
			{
				var folder:String = Paths.mods(Mods.currentModDirectory + '/' + fileToFind);
				if (FileSystem.exists(folder) && !foldersToCheck.contains(folder)) foldersToCheck.push(folder);
			}
		}
		#end
		return foldersToCheck;
	}
	
	public static function getPack(?folder:String = null):ModMeta
	{
		#if MODS_ALLOWED
		if (folder == null) folder = Mods.currentModDirectory;
		
		var path = Paths.mods(folder + '/meta.json');
		if (FileSystem.exists(path))
		{
			try
			{
				final json = FunkinAssets.getContent(path);
				if (json != null && json.length > 0) return Json.parse(json);
			}
		}
		#end
		return null;
	}
	
	public static inline function parseList():ModsList
	{
		updateModList();
		var list:ModsList = {enabled: [], disabled: [], all: []};
		
		#if MODS_ALLOWED
		for (mod in CoolUtil.coolTextFile('modsList.txt'))
		{
			// trace('Mod: $mod');
			if (mod.trim().length < 1) continue;
			
			var dat = mod.split("|");
			list.all.push(dat[0]);
			if (dat[1] == "1") list.enabled.push(dat[0]);
			else list.disabled.push(dat[0]);
		}
		#end
		return list;
	}
	
	static function updateModList()
	{
		#if MODS_ALLOWED
		checkFile();
		
		// Find all that are already ordered
		var list:Array<{folder:String, enabled:Bool}> = [];
		var added:Array<String> = [];
		
		for (mod in CoolUtil.coolTextFile('modsList.txt'))
		{
			var dat:Array<String> = mod.split("|");
			var folder:String = dat[0];
			if (folder.trim().length > 0
				&& FileSystem.exists(Paths.mods(folder))
				&& FileSystem.isDirectory(Paths.mods(folder))
				&& !added.contains(folder))
			{
				added.push(folder);
				list.push({folder: folder, enabled: (dat[1] == "1")});
			}
		}
		
		// Scan for folders that aren't on modsList.txt yet
		for (folder in getModDirectories())
		{
			if (folder.trim().length > 0
				&& FileSystem.exists(Paths.mods(folder))
				&& FileSystem.isDirectory(Paths.mods(folder))
				&& !ignoreModFolders.contains(folder.toLowerCase())
				&& !added.contains(folder))
			{
				added.push(folder);
				list.push({folder: folder, enabled: true}); // i like it false by default. -bb //Well, i like it True! -Shadow Mario (2022)
				// Shadow Mario (2023): What the fuck was bb thinking
			}
		}
		
		// Now save file
		var fileStr:String = '';
		for (values in list)
		{
			// trace(values);
			if (fileStr.length > 0) fileStr += '\n';
			fileStr += values.folder + '|' + (values.enabled ? '1' : '0');
		}
		
		File.saveContent('modsList.txt', fileStr);
		#end
	}
	
	public static function loadTopMod()
	{
		Mods.currentModDirectory = '';
		
		#if MODS_ALLOWED
		var list:Array<String> = Mods.parseList().enabled;
		if (list != null && list[0] != null) Mods.currentModDirectory = list[0];
		#end
	}
}
