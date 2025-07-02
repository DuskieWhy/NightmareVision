package funkin.data;

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
	public static var forceNextDirectory:Null<String> = null;
	
	public static function loadDirectory(SONG:SwagSong)
	{
		var stage:String = SONG.stage ?? 'stage';
		
		var stageFile:StageFile = getStageFile(stage);
		
		forceNextDirectory = stageFile?.directory ?? '';
	}
	
	public static function getStageFile(stage:String):Null<StageFile>
	{
		var path = Paths.getPath('stages/$stage/data.json', TEXT, null, true);
		if (!FunkinAssets.exists(path, TEXT)) path = Paths.getPath('stages/$stage.json', TEXT, null, true);
		
		return FunkinAssets.exists(path, TEXT) ? cast Json.parse(FunkinAssets.getContent(path)) : null;
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
