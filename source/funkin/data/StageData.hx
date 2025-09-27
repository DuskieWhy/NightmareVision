package funkin.data;

import funkin.data.CharacterData.AnimationInfo;

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
	
	/**
	 * Optional array of data to make background sprites.
	 */
	var ?stageObjects:Array<StageObject>;
}

typedef StageObject =
{
	/**
	 * ID attached to the object.
	 * 
	 * Used to identify the object in scripts.
	 */
	var ?id:String;
	
	/**
	 * The path to an asset to load.
	 * 
	 * This can be the path to a `Texture Atlas`, `Sparrow Atlas`, `Packer Atlas` or a regular image
	 * 
	 * If unused, a 1x1 graphic will be made
	 */
	var ?asset:String;
	
	/**
	 * Position to where the object should be as [x, y]
	 * 
	 * Default is [0, 0]
	 */
	var ?position:Array<Float>;
	
	/**
	 * The objects scrollFactor as [x, y]
	 * 
	 * Default is [1, 1]
	 */
	var ?scrollFactor:Array<Float>;
	
	/**
	 * Scale of the object as [x, y]
	 * 
	 * Default is [1, 1]
	 */
	var ?scale:Array<Float>;
	
	/**
	 * Sets the objects Alpha/Transparency from 0 - 1
	 */
	var ?alpha:Float;
	
	/**
	 * Whether the object should be flipped on the X axis
	 */
	var ?flipX:Bool;
	
	/**
	 * Whether the object should be flipped on the Y axis
	 */
	var ?flipY:Bool;
	
	/**
	 * The Z index of the object
	 * 
	 * Set this really high to go in front of the characters
	 * 
	 * Default is 0
	 */
	var ?zIndex:Int;
	
	/**
	 * The angle of the object in degrees
	 */
	var ?angle:Float;
	
	/**
	 * A hex colour to be multiplied over the sprite
	 * 
	 * If you are making a solid graphic and `asset` is not used, use this to change its colour
	 */
	var ?colour:String;
	
	/**
	 * Blend mode of the object
	 */
	var ?blend:String;
	
	/**
	 * unsupported currently
	 */
	var ?dance_every:Int;
	
	/**
	 * Whether the object should have antialiasing enabled.
	 */
	var ?antialiasing:Bool;
	
	/**
	 * If true, this object will only be added if `low Quality` is disabled.
	 */
	var ?highQuality:Bool;
	
	/**
	 * Provide the full class path to a type to create a custom class
	 * 
	 * `Keep note some other options here will not work if using a custom instance!`
	 * 
	 * By default, a `Bopper` is made
	 */
	var ?customInstance:String;
	
	/**
	 * Array of the fields to be used for an animation
	 * 
	 * The first animation in the array will be played on creation
	 * 
	 * Used if the `asset` exists
	 */
	var ?animations:Array<AnimationInfo>;
	
	/**
	 * Additional functionality that can be used in case there is more specific functions needed
	 * 
	 * These get called at the end of initialization
	 * 
	 * @param method The name of a function to call
	 * @param args Optional values to be used in the function
	 */
	var ?advancedCalls:Array<{method:String, ?args:Array<Dynamic>}>;
	
	// maybe a setproperty later
	var ?setProperties:Array<{property:String, value:Dynamic}>;
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
		
	/**
	 * Helper function to figure out a StageFile `customInstance` field
	 */
	public static function resolveObjectInstance(obj:String):Null<Class<Dynamic>> // add moire later
	{
		obj = obj.toLowerCase();
		
		if (obj.contains('tiledsprite')) return flixel.addons.display.FlxTiledSprite;
		else if (obj.contains('backdrop')) return flixel.addons.display.FlxBackdrop;
		else if (obj.contains('character')) return funkin.objects.Character;
		else if (obj.contains('flxbgsprite')) return flixel.system.FlxBGSprite;
		
		return null;
	}
}
