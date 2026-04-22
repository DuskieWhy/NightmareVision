package funkin.data;

import flixel.util.FlxStringUtil.LabelValuePair;
import flixel.util.FlxStringUtil;

import haxe.Json;

import funkin.states.*;

typedef WeekFile =
{
	// JSON variables
	var songs:Array<Dynamic>;
	var weekCharacters:Array<String>;
	var weekBackground:String;
	var weekBefore:String;
	var storyName:String;
	var weekName:String;
	var freeplayColor:Array<Int>;
	var startUnlocked:Bool;
	var hiddenUntilUnlocked:Bool;
	var hideStoryMode:Bool;
	var hideFreeplay:Bool;
	var difficulties:Array<String>;
}

class WeekData
{
	public static var weeksLoaded:Map<String, WeekData> = new Map<String, WeekData>();
	public static var weeksList:Array<String> = [];
	
	static final _fields = Type.getInstanceFields(WeekData);
	
	// JSON variables
	public var songs:Array<Dynamic> = [];
	public var weekCharacters:Array<String> = [];
	public var weekBackground:String = '';
	public var weekBefore:String = '';
	public var storyName:String = '';
	public var weekName:String = '';
	public var freeplayColor:Array<Int> = [255, 255, 255];
	public var startUnlocked:Bool = true;
	public var hiddenUntilUnlocked:Bool = false;
	public var hideStoryMode:Bool = false;
	public var hideFreeplay:Bool = false;
	public var difficulties:Array<String> = [];
	
	public var fileName:String;
	public var folder:String = '';
	
	public static function createWeekFile():WeekFile
	{
		var weekFile:WeekFile =
			{
				songs: [
					["Bopeebo", "dad", [146, 113, 253]],
					["Fresh", "dad", [146, 113, 253]],
					["Dad Battle", "dad", [146, 113, 253]]
				],
				weekCharacters: ['dad', 'bf', 'gf'],
				weekBackground: 'stage',
				weekBefore: 'tutorial',
				storyName: 'Your New Week',
				weekName: 'Custom Week',
				freeplayColor: [146, 113, 253],
				startUnlocked: true,
				hiddenUntilUnlocked: false,
				hideStoryMode: false,
				hideFreeplay: false,
				difficulties: ['Easy', 'Normal', 'Hard']
			};
		return weekFile;
	}
	
	public function new(weekFile:WeekFile, fileName:String)
	{
		for (field in Reflect.fields(weekFile))
		{
			if (_fields.contains(field))
			{
				Reflect.setField(this, field, Reflect.field(weekFile, field));
			}
		}
		
		this.fileName = fileName;
	}
	
	public static function reloadWeekFiles(isStoryMode:Null<Bool> = false)
	{
		weeksList = [];
		weeksLoaded.clear();
		#if MODS_ALLOWED
		var directories:Array<String> = [Paths.mods(), Paths.getCorePath()];
		var originalLength:Int = directories.length;
		
		for (mod in Mods.parseList().enabled)
		{
			directories.push(Paths.mods(mod + '/'));
		}
		#else
		var directories:Array<String> = [Paths.getCorePath()];
		var originalLength:Int = directories.length;
		#end
		
		var txtPath = Paths.getPath('data/weeks/weekList.txt');
		if (!FunkinAssets.exists(txtPath)) txtPath = Paths.getPath('weeks/weekList.txt');
		
		final sexList:Array<String> = CoolUtil.coolTextFile(txtPath);
		
		for (i in 0...sexList.length)
		{
			for (j in 0...directories.length)
			{
				var fileToCheck:String = directories[j] + 'weeks/' + sexList[i] + '.json';
				if (!weeksLoaded.exists(sexList[i]))
				{
					var week:WeekFile = getWeekFile(fileToCheck);
					if (week != null)
					{
						var weekFile:WeekData = new WeekData(week, sexList[i]);
						
						#if MODS_ALLOWED
						if (j >= originalLength)
						{
							weekFile.folder = directories[j].substring(Paths.mods().length, directories[j].length - 1);
						}
						#end
						
						if (weekFile != null
							&& (isStoryMode == null
								|| (isStoryMode && !weekFile.hideStoryMode)
								|| (!isStoryMode && !weekFile.hideFreeplay)))
						{
							weeksLoaded.set(sexList[i], weekFile);
							weeksList.push(sexList[i]);
						}
					}
				}
			}
		}
		
		#if MODS_ALLOWED
		for (i in 0...directories.length)
		{
			var directory:String = directories[i] + 'data/weeks/';
			if (!FunkinAssets.exists(directory)) directory = directories[i] + 'weeks/';
			
			if (FunkinAssets.exists(directory))
			{
				var listOfWeeks:Array<String> = CoolUtil.coolTextFile(directory + 'weekList.txt');
				for (daWeek in listOfWeeks)
				{
					var path:String = directory + daWeek + '.json';
					if (FunkinAssets.exists(path))
					{
						addWeek(daWeek, path, directories[i], i, originalLength);
					}
				}
				
				for (file in FunkinAssets.readDirectory(directory))
				{
					final path = Path.join([directory, file]);
					if (!FunkinAssets.isDirectory(path) && file.endsWith('.json'))
					{
						addWeek(file.withoutExtension(), path, directories[i], i, originalLength);
					}
				}
			}
		}
		#end
	}
	
	static function addWeek(weekToCheck:String, path:String, directory:String, i:Int, originalLength:Int)
	{
		if (!weeksLoaded.exists(weekToCheck))
		{
			var week:WeekFile = getWeekFile(path);
			if (week != null)
			{
				var weekFile:WeekData = new WeekData(week, weekToCheck);
				if (i >= originalLength)
				{
					#if MODS_ALLOWED
					weekFile.folder = directory.substring(Paths.mods().length, directory.length - 1);
					#end
				}
				if ((PlayState.isStoryMode && !weekFile.hideStoryMode) || (!PlayState.isStoryMode && !weekFile.hideFreeplay))
				{
					weeksLoaded.set(weekToCheck, weekFile);
					weeksList.push(weekToCheck);
				}
			}
		}
	}
	
	static function getWeekFile(path:String):WeekFile
	{
		final raw:Null<String> = FunkinAssets.exists(path, TEXT) ? FunkinAssets.getContent(path) : null;
		
		return FunkinAssets.parseJson5(raw);
	}
	
	//   FUNCTIONS YOU WILL PROBABLY NEVER NEED TO USE
	// To use on PlayState.hx or Highscore stuff
	public static function getWeekFileName():String
	{
		return weeksList[PlayState.storyMeta.curWeek] ?? '';
	}
	
	public static function getCurrentWeek():Null<WeekData>
	{
		return weeksLoaded.get(weeksList[PlayState.storyMeta.curWeek]);
	}
	
	public static function setDirectoryFromWeek(?data:WeekData):Void
	{
		Mods.currentModDirectory = '';
		if (data != null && data.folder != null && data.folder.length > 0)
		{
			Mods.currentModDirectory = data.folder;
		}
	}
	
	public function toString()
	{
		return FlxStringUtil.getDebugString([
			LabelValuePair.weak("songs", songs),
			LabelValuePair.weak("difficulties", difficulties)
		]);
	}
}
