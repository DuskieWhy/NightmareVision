package funkin.data;

#if MODS_ALLOWED
import sys.io.File;
import sys.FileSystem;
#else
import openfl.utils.Assets;
#end
import haxe.Json;
import funkin.data.Song;

typedef StageFile =
{
	var directory:String;
	var defaultZoom:Float;
	var isPixelStage:Bool;

	var boyfriend:Array<Dynamic>;
	var girlfriend:Array<Dynamic>;
	var opponent:Array<Dynamic>;
	var hide_girlfriend:Bool;

	var camera_boyfriend:Array<Float>;
	var camera_opponent:Array<Float>;
	var camera_girlfriend:Array<Float>;
	var camera_speed:Null<Float>;
}

class StageData
{
	public static var forceNextDirectory:String = null;

	public static function loadDirectory(SONG:SwagSong)
	{
		var stage:String = SONG.stage ?? 'stage';

		var stageFile:StageFile = getStageFile(stage);

		forceNextDirectory = stageFile?.directory ?? '';
	}

	public static function getStageFile(stage:String):StageFile
	{
		var rawJson:String = null;
		var path:String = Paths.getSharedPath('stages/' + stage + '.json');

		#if MODS_ALLOWED
		var modPath:String = Paths.modFolders('stages/' + stage + '.json');
		if (FileSystem.exists(modPath))
		{
			rawJson = File.getContent(modPath);
		}
		else if (FileSystem.exists(path))
		{
			rawJson = File.getContent(path);
		}
		#else
		if (Assets.exists(path))
		{
			rawJson = Assets.getText(path);
		}
		#end
	else
	{
		return null;
	}
		return cast Json.parse(rawJson);
	}

	public static function generateDefault():StageFile return
		{
			directory: "",
			isPixelStage: false,
			defaultZoom: 0.8,
			boyfriend: [500, 100],
			girlfriend: [0, 100],
			opponent: [-500, 100],
			hide_girlfriend: false,
			camera_boyfriend: [0, 0],
			camera_opponent: [0, 0],
			camera_girlfriend: [0, 0],
			camera_speed: 1
		}
}
