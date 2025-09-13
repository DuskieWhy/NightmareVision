package funkin.data;

import haxe.Json;

typedef StageFile =
{
	/**
	 * The default camera zoom that the game will be set to
	 */
	var defaultZoom:Float;
	
	/**
	 * If enabled, pixelUI will be enabled
	 */
	var isPixelStage:Bool;
	
	/**
	 * The boyfriend postion as [x, y]
	 */
	var boyfriend:Array<Float>;
	
	/**
	 * The girlfriend position as [x, y]
	 */
	var girlfriend:Array<Float>;
	
	/**
	 * The dad position as [x, y]
	 */
	var opponent:Array<Float>;
	
	/**
	 * If true, the girlfriend will not be loaded in anyway
	 */
	var ?hide_girlfriend:Null<Bool>;
	
	/**
	 * Additional offset for the boyfriend camera position as [x, y]
	 */
	var ?camera_boyfriend:Null<Array<Float>>;
	
	/**
	 * Addtional offset for the dad camera position as [x, y]
	 */
	var ?camera_opponent:Null<Array<Float>>;
	
	/**
	 * Additional offset for the girlfriend camera position as [x, y]
	 */
	var ?camera_girlfriend:Null<Array<Float>>;
	
	/**
	 * Multiplier onto the camera movement speed.
	 */
	var ?camera_speed:Null<Float>;
	
	/**
	 * The dad Characters Z index.
	 * 
	 * default is 0
	 */
	var ?dadZIndex:Null<Int>;
	
	/**
	 * The girlfriend Characters Z index.
	 * 
	 * default is 0
	 */
	var ?gfZIndex:Null<Int>;
	
	/**
	 * The boyfriend Characters Z index.
	 * 
	 * default is 0
	 */
	var ?bfZIndex:Null<Int>;
}

@:nullSafety
class StageData
{
	public static function getStageFile(stage:String):Null<StageFile>
	{
		var path = Paths.getPath('stages/$stage/data.json', TEXT, null, true);
		if (!FunkinAssets.exists(path, TEXT)) path = Paths.getPath('stages/$stage.json', TEXT, null, true);
		
		return FunkinAssets.exists(path, TEXT) ? cast FunkinAssets.parseJson(FunkinAssets.getContent(path)) : null;
	}
	
	public static function getTemplateStageFile():StageFile return
		{
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
