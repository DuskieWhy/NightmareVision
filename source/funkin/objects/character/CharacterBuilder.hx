package funkin.objects.character;

import haxe.Json;

import funkin.objects.character.Character.AnimArray;

using StringTools;
typedef CharacterFile =
{
	/**
	 * Array of the actual animation data parsed via json.
	 */
	var animations:Array<AnimArray>;
	
	/**
	 * The path to the image of the character.
	 */
	var image:String;
	
	/**
	 * The scale of the character
	 */
	var scale:Float;
	
	/**
	 * A multiplier of time of how long a character will hold his animations.
	 */
	var sing_duration:Float;
	
	/**
	 * The characters health icon name.
	 */
	var healthicon:String;
	
	/**
	 * A base offset of the characters position stored as [x,y].
	 */
	var position:Array<Float>;
	
	/**
	 * A base offset of the characters camera position stored as [x,y].
	 */
	var camera_position:Array<Float>;
	
	/**
	 * Whether the character should be flipped.
	 */
	var flip_x:Bool;
	
	/**
	 * Whether the character should use antialiasing.
	 */
	var no_antialiasing:Bool;
	
	/**
	 * The characters health colours. Stored as [r,g,b] to 0-255.
	 */
	@:optional var healthbar_colors:Array<Int>;
	
	/**
	 * The characters health colour.
	 */
	var healthbar_colour:Int;
}

/**
 * Helper class to handle different character types
 */
class CharacterBuilder
{
	/**
	 * default char. used in case a character is missing
	 */
	public static final DEFAULT_CHARACTER:String = 'bf';
	
	public static function fromName(x:Float = 0, y:Float = 0, charName:String, isPlayer:Bool = false):Character
	{
		// temp we shouldnt be doing this twice
		final file = getCharacterFile(charName);
		
		switch (charName)
		{
			default:
				if (FunkinAssets.exists(Paths.textureAtlas(file.image + '/Animation.json')))
				{
					return new AnimateCharacter(x, y, charName, isPlayer);
				}
				else
				{
					return new Character(x, y, charName, isPlayer);
				}
		}
	}
	
	public static function getCharacterFile(character:String):CharacterFile
	{
		var charPath:String = Paths.getPath('characters/' + character + '.json', TEXT, null, true);
		
		if (!FunkinAssets.exists(charPath))
		{
			charPath = Paths.getPrimaryPath('characters/' + DEFAULT_CHARACTER + '.json');
		}
		
		return cast Json.parse(FunkinAssets.getContent(charPath));
	}
	public static function changeTypeReload(info:Array<Dynamic>, type:String, file:String)
	{
		trace('changing type to $type');
		var character:Dynamic;
		
		switch (type)
		{
			case 'atlas':
				character = new AnimateCharacter(info[0], info[1], info[2], info[3]);
				character.loadGraphicFromType(file, 'atlas');
			default:
				character = new Character(info[0], info[1], info[2], info[3], true);
				character.skipJsonStuff = true;
				character.imageFile = file;
				character.createNow();
		}
		
		return character;
	}
}
