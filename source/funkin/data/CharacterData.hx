package funkin.data;

import flixel.animation.FlxAnimation;

import haxe.xml.Access;

import funkin.objects.Character;

class CharacterParser
{
	// wipppppp
	public static function fetchInfo(id:String):CharacterInfo
	{
		var charPath = Paths.findFileAndAddExts('characters/$id', ['json', 'xml']);
		
		if (!FunkinAssets.exists(charPath))
		{
			charPath = Paths.getPrimaryPath('characters/${Character.DEFAULT_CHARACTER}.json');
		}
		
		var raw:Null<String> = null;
		
		try
		{
			raw = FunkinAssets.getContent(charPath);
		}
		
		if (charPath.endsWith('.xml')) return fromCNE(raw); // check if its cne
		
		final rawJson:Null<Any> = FunkinAssets.parseJson(raw);
		
		if (rawJson == null) throw 'failed to parse json at $charPath';
		
		// then check for vslice
		if (Reflect.hasField(rawJson, 'version')) // idk if other formats use a version but for the time being i will assume its vslice
		{
			return fromVSlice(rawJson);
		}
		
		return cast rawJson;
	}
	
	// dont expect this to be that good aha wip
	public static function fromCNE(data:Dynamic):CharacterInfo
	{
		var xml = Xml.parse(data).firstElement();
		
		final access = new Access(xml);
		
		final animations:Array<AnimationInfo> = [];
		
		// not used for this sorry ig.
		final isPlayer = access.x.exists('isPlayer') ? access.x.get('isPlayer') == 'true' : false;
		
		// from https://github.com/CodenameCrew/CodenameEngine/blob/main/source/funkin/backend/utils/CoolUtil.hx
		inline function parseNumberRange(input:String):Array<Int>
		{
			var result:Array<Int> = [];
			var parts:Array<String> = input.split(",");
			
			for (part in parts)
			{
				part = part.trim();
				var idx = part.indexOf("..");
				if (idx != -1)
				{
					var start = Std.parseInt(part.substring(0, idx).trim());
					var end = Std.parseInt(part.substring(idx + 2).trim());
					
					if (start == null || end == null)
					{
						continue;
					}
					
					if (start < end)
					{
						for (j in start...end + 1)
						{
							result.push(j);
						}
					}
					else
					{
						for (j in end...start + 1)
						{
							result.push(start + end - j);
						}
					}
				}
				else
				{
					var num = Std.parseInt(part);
					if (num != null)
					{
						result.push(num);
					}
				}
			}
			return result;
		}
		
		for (node in access.elements)
		{
			if (node.name == 'anim')
			{
				final anim = node.x.get('name');
				final prefix = node.x.get('anim');
				final xOffset = node.x.exists('x') ? Std.parseInt(node.x.get('x')) : 0;
				final yOffset = node.x.exists('y') ? Std.parseInt(node.x.get('y')) : 0;
				final fps = node.x.exists('fps') ? Std.parseInt(node.x.get('fps')) : 24;
				final loops = node.x.exists('loop') ? node.x.get('loop') == 'true' : false;
				final indices = node.x.exists('indices') ? parseNumberRange(node.x.get('indices')) : [];
				
				animations.push(
					{
						anim: anim,
						name: prefix,
						offsets: [xOffset, yOffset],
						fps: fps,
						loop: loops,
						indices: indices
					});
			}
		}
		
		final texture = 'characters/' + (access.x.exists('sprite') ? access.x.get('sprite') : 'BOYFRIEND');
		final flipX = access.x.exists('flipX') ? access.x.get('flipX') == 'true' : false;
		final icon = access.x.exists('icon') ? access.x.get('icon') : 'face';
		final healthColour = access.x.exists('color') ? FlxColor.fromString(access.x.get('color')) : FlxColor.GRAY;
		final x = access.x.exists('x') ? Std.parseFloat(access.x.get('x')) : 0.0;
		final y = access.x.exists('y') ? Std.parseFloat(access.x.get('y')) : 0.0;
		final antialiasing = access.x.exists('antialiasing') ? true : true;
		final scale = access.x.exists('scale') ? Std.parseFloat(access.x.get('scale')) : 1;
		final singDuration = access.x.exists('holdTime') ? Std.parseFloat(access.x.get('holdTime')) : 6.1;
		final danceEvery = access.x.exists('interval') ? Std.parseInt(access.x.get('interval')) : 2;
		
		final info:CharacterInfo =
			{
				image: texture,
				position: [x, y],
				camera_position: [0, 0],
				animations: animations,
				healthbar_colour: healthColour,
				healthicon: icon,
				flip_x: flipX,
				sing_duration: singDuration,
				scale: scale,
				no_antialiasing: !antialiasing,
				dance_every: danceEvery
			}
			
		return info;
	}
	
	// wip
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
