package funkin.objects.character;

typedef AnimationInfo =
{
	var anim:String;
	var name:String;
	var fps:Int;
	var loop:Bool;
	var indices:Array<Int>;
	var offsets:Array<Int>;
	
	var ?flipX:Bool;
	var ?flipY:Bool;
}

typedef CharacterInfo =
{
	/**
	 * Array of the actual animation data parsed via json.
	 */
	var animations:Array<AnimationInfo>;
	
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
	var ?healthbar_colors:Array<Int>;
	
	/**
	 * The characters health colour.
	 */
	var healthbar_colour:Int;
	
	/**
	 * How many beats between the characters `dance`
	 */
	var ?dance_every:Int;
	
	/**
	 * Enables characters offsets to be adjusted according to characters scale
	 */
	var ?scalableOffsets:Bool;
	
	/**
	 * Used for the character editor
	 */
	var ?_editor_isPlayer:Bool;
	
	/**
	 * optional character to be used for `GameOverSubstate`. Has priority over the static vars
	 */
	var ?gameover_character:String;
}
