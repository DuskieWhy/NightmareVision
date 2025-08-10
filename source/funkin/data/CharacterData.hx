package funkin.data;

import funkin.objects.Character;

class CharacterParser
{
	// wipppppp
	public static function fetchInfo(id:String):CharacterInfo
	{
		var charPath:String = Paths.getPath('characters/$id.json', TEXT, null, true);
		
		if (!FunkinAssets.exists(charPath))
		{
			charPath = Paths.getPrimaryPath('characters/${Character.DEFAULT_CHARACTER}.json');
		}
		
		var raw = null;
		
		try
		{
			raw = FunkinAssets.parseJson(FunkinAssets.getContent(charPath));
		}
		
		if (raw == null) throw 'failed to parse json at $charPath';
		
		if (Reflect.hasField(raw, 'version')) // idk if other formats use a version but for the time being i will assume its vslice
		{
			return fromVSlice(raw);
		}
		
		return cast raw;
	}
	
	// maybe make this cleaner
	public static function fromVSlice(data:Dynamic):CharacterInfo
	{
		final singDuration = data?.singTime ?? 6.1;
		final antialiasing = !data?.isPixel ?? true;
		final scale = data?.scale ?? 1.0;
		final danceEvery = data?.danceEvery ?? 2;
		final flipX = data?.flipX ?? false;
		final cameraPosition:Array<Float> = cast data?.cameraOffsets ?? [0, 0];
		final position:Array<Float> = cast data?.offsets ?? [0, 0];
		final icon = data?.healthIcon?.id ?? 'face';
		
		final animations:Array<AnimationInfo> = [];
		
		final assetPaths:Array<String> = [];
		if (data?.assetPath != null) assetPaths.push(data.assetPath);
		
		for (i in 0...data.animations.length)
		{
			//
			final vSliceAnim = data.animations[i];
			if (vSliceAnim != null)
			{
				// maybe i could make a cleaner converter with some extra funcs and typedefs...
				final flipX = vSliceAnim?.flipX ?? false;
				final flipY = vSliceAnim?.flipY ?? false;
				final offsets = vSliceAnim?.offsets ?? [0, 0];
				final fps = vSliceAnim?.frameRate ?? 24;
				final prefix = vSliceAnim?.prefix ?? '';
				final animTag = vSliceAnim?.name ?? '';
				final indices = vSliceAnim?.frameIndices ?? [];
				final looped = vSliceAnim?.looped ?? false;
				
				if (vSliceAnim.assetPath != null)
				{
					if (!assetPaths.contains(vSliceAnim.assetPath)) assetPaths.push(vSliceAnim.assetPath); // for multisparrow stuff
				}
				
				final animToPush:AnimationInfo =
					{
						flipY: flipY,
						flipX: flipX,
						offsets: offsets,
						fps: fps,
						anim: animTag,
						name: prefix,
						loop: looped,
						indices: indices
					}
					
				animations.push(animToPush);
			}
		}
		
		final info:CharacterInfo =
			{
				scale: scale,
				flip_x: flipX,
				camera_position: cameraPosition,
				position: position,
				no_antialiasing: !antialiasing,
				sing_duration: singDuration,
				healthicon: icon,
				healthbar_colour: FlxColor.GRAY,
				image: assetPaths.join(','),
				animations: animations,
				dance_every: danceEvery
			};
			
		return info;
	}
}

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
	
	var ?gameover_intial_sound:String;
	
	var ?gameover_loop_sound:String;
	
	var ?gameover_confirm_sound:String;
}
