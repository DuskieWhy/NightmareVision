package funkin.data;

import flixel.animation.FlxAnimation;

import haxe.xml.Access;

import funkin.objects.Character;

@:nullSafety
class CharacterParser
{
	/**
	 * Fetches a characters data structure to be loaded to a character
	 * 
	 * supported formats are `psych`, `cne`, and `vslice`
	 */
	public static function fetchInfo(id:String):CharacterInfo
	{
		var charPath = Paths.findFileWithExts('data/characters/$id', ['json', 'xml']);
		
		if (!FunkinAssets.exists(charPath)) charPath = Paths.findFileWithExts('characters/$id', ['json', 'xml']);
		
		if (!FunkinAssets.exists(charPath)) charPath = Paths.getCorePath('data/characters/${Character.DEFAULT_CHARACTER}.json');
		
		var raw:String = '';
		
		try
		{
			raw = FunkinAssets.getContent(charPath);
		}
		catch (e) {}
		
		if (raw.trim().length != 0 && charPath.endsWith('.xml')) return fromCNE(raw); // if it was a xml its cne
		
		final rawJson:Null<Any> = FunkinAssets.parseJson5(raw);
		
		// if (rawJson == null) throw 'failed to parse json at $charPath'; // perhaps instead of throwing i could return a dummy thats flagged as invalid..
		
		// then check for vslice
		if (rawJson != null && Reflect.hasField(rawJson, 'version')) // idk if other formats use a version but for the time being i will assume its vslice
		{
			return fromVSlice(rawJson);
		}
		
		return validateData(rawJson);
	}
	
	/**
	 * Ensures the minimum required fields are not null.
	 */
	static function validateData(data:Null<Dynamic>):CharacterInfo
	{
		final baseInfo:CharacterInfo = getTemplateCharInfo();
		
		if (data == null) return baseInfo;
		
		data.sing_duration ??= baseInfo.sing_duration;
		data.no_antialiasing ??= baseInfo.no_antialiasing;
		data.flip_x ??= baseInfo.flip_x;
		data.healthicon ??= baseInfo.healthicon;
		data.healthbar_colour ??= baseInfo.healthbar_colour;
		data.vslice_sustains ??= baseInfo.vslice_sustains;
		data.image ??= baseInfo.image;
		data.dance_every ??= baseInfo.dance_every;
		data.position ??= baseInfo.position;
		data.camera_position ??= baseInfo.camera_position;
		data.animations ??= baseInfo.animations;
		data.scale ??= baseInfo.scale;
		
		return cast data;
	}
	
	/**
	 * Converts a cne character xml into a usable format for the engine
	 * 
	 * This does not parse every possible cne attribute so some things may be off
	 */
	public static function fromCNE(data:String):CharacterInfo
	{
		final xml = try
		{
			Xml.parse(data).firstElement();
		}
		catch (e)
			throw 'Failed to parse invalid xml\nException:$e';
			
		final access = new Access(xml);
		
		final baseInfo:CharacterInfo = getTemplateCharInfo();
		
		// not used for this sorry ig.
		// final isPlayer = access.x.exists('isPlayer') ? access.x.get('isPlayer') == 'true' : false;
		
		if (access.has.sprite) baseInfo.image = 'characters/' + access.att.sprite;
		
		if (access.has.holdTime)
		{
			final singDuration = Std.parseFloat(access.att.holdTime);
			if (!Math.isNaN(singDuration)) baseInfo.sing_duration = singDuration;
		}
		
		if (access.has.antialiasing) baseInfo.no_antialiasing = access.att.antialiasing == 'false';
		
		if (access.has.scale)
		{
			final scale = Std.parseFloat(access.att.scale);
			if (!Math.isNaN(scale)) baseInfo.scale = scale;
		}
		
		if (access.has.x)
		{
			final x = Std.parseFloat(access.att.x);
			if (!Math.isNaN(x)) baseInfo.position[0] = x;
		}
		
		if (access.has.y)
		{
			final y = Std.parseFloat(access.att.y);
			if (!Math.isNaN(y)) baseInfo.position[1] = y;
		}
		
		if (access.has.icon) baseInfo.healthicon = access.att.icon;
		
		if (access.has.flipX) baseInfo.flip_x = access.att.flipX == 'true';
		
		if (access.has.interval)
		{
			final danceEvery = Std.parseInt(access.att.interval);
			if (danceEvery != null) baseInfo.dance_every = danceEvery;
		}
		
		if (access.has.camx)
		{
			final x = Std.parseFloat(access.att.camx);
			if (!Math.isNaN(x)) baseInfo.camera_position[0] = x;
		}
		
		if (access.has.camy)
		{
			final y = Std.parseFloat(access.att.camy);
			if (!Math.isNaN(y)) baseInfo.camera_position[1] = y;
		}
		
		if (access.has.color)
		{
			final colour = FlxColor.fromString(access.att.color);
			if (colour != null) baseInfo.healthbar_colour = colour;
		}
		
		if (access.has.gameOverChar) baseInfo.gameover_character = access.att.gameOverChar;
		
		for (node in access.elements)
		{
			if (node.name == 'anim')
			{
				baseInfo.animations.push(cneAnimationToPsych(node));
			}
		}
		
		return baseInfo;
	}
	
	/**
	 * parses a VSlice character json into a usable format for the engine
	 */
	public static function fromVSlice(data:Dynamic):CharacterInfo
	{
		final baseInfo:CharacterInfo = getTemplateCharInfo();
		
		if (data == null) return baseInfo;
		
		final data:VSliceCharacterInfo = data;
		
		final assetPaths:Array<String> = [];
		
		if (data.assetPath != null) assetPaths.push(data.assetPath);
		
		if (data.singTime != null) baseInfo.sing_duration = data.singTime;
		
		if (data.isPixel != null) baseInfo.no_antialiasing = data.isPixel;
		
		if (data.scale != null) baseInfo.scale = data.scale;
		
		if (data.offsets != null) baseInfo.position = data.offsets;
		
		if (data.healthIcon != null && data.healthIcon.id != null) baseInfo.healthicon = data.healthIcon.id;
		
		if (data.flipX != null) baseInfo.flip_x = data.flipX;
		
		if (data.danceEvery != null)
		{
			final danceEvery = Std.int(data.danceEvery);
			if (!Math.isNaN(danceEvery)) baseInfo.dance_every = danceEvery;
		}
		
		if (data.cameraOffsets != null) baseInfo.camera_position = data.cameraOffsets;
		
		if (data.animations != null)
		{
			for (anim in data.animations)
			{
				baseInfo.animations.push(vSliceAnimationToPsych(anim));
				if (anim.assetPath != null && !assetPaths.contains(anim.assetPath)) assetPaths.push(anim.assetPath);
			}
		}
		
		baseInfo.image = assetPaths.join(',');
		
		return baseInfo;
	}
	
	/**
	 * converts a VSlice animation into a `AnimationInfo`
	 */
	static function vSliceAnimationToPsych(anim:VSliceAnimationInfo):AnimationInfo
	{
		final baseInfo:AnimationInfo = getTemplateAnimInfo();
		
		if (anim == null) return baseInfo;
		
		if (anim.offsets != null) baseInfo.offsets = [for (i in anim.offsets) Std.int(i)];
		
		if (anim.flipX != null) baseInfo.flipX = anim.flipX;
		
		if (anim.flipY != null) baseInfo.flipY = anim.flipY;
		
		if (anim.frameRate != null) baseInfo.fps = anim.frameRate;
		
		if (anim.frameIndices != null) baseInfo.indices = anim.frameIndices;
		
		if (anim.looped != null) baseInfo.loop = anim.looped;
		
		if (anim.name != null) baseInfo.anim = anim.name;
		
		if (baseInfo.anim.endsWith('-hold')) baseInfo.anim = baseInfo.anim.replace('-hold', '-loop'); // base game calls em hold
		
		if (anim.prefix != null) baseInfo.name = anim.prefix;
		
		return baseInfo;
	}
	
	/**
	 * Parses a xml node from a cne character to a `AnimationInfo`
	 */
	static function cneAnimationToPsych(node:Access)
	{
		final baseInfo:AnimationInfo = getTemplateAnimInfo();
		
		if (node.name != 'anim') return baseInfo;
		
		if (node.has.name) baseInfo.anim = node.att.name;
		
		if (node.has.anim) baseInfo.name = node.att.anim;
		
		if (node.has.x)
		{
			final x = Std.parseInt(node.att.x);
			if (x != null) baseInfo.offsets[0] = x;
		}
		
		if (node.has.y)
		{
			final y = Std.parseInt(node.att.y);
			if (y != null) baseInfo.offsets[1] = y;
		}
		
		if (node.has.fps)
		{
			final fps = Std.parseInt(node.att.fps);
			if (fps != null) baseInfo.fps = fps;
		}
		
		if (node.has.indices) baseInfo.indices = parseNumberRange(node.att.fps);
		
		return baseInfo;
	}
	
	/**
	 * Needed for cne anim parsing
	 * 
	 * https://github.com/CodenameCrew/CodenameEngine/blob/main/source/funkin/backend/utils/CoolUtil.hx
	 */
	inline static function parseNumberRange(input:String):Array<Int>
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
	
	static function getTemplateCharInfo():CharacterInfo
	{
		return {
			sing_duration: 4,
			no_antialiasing: false,
			flip_x: false,
			healthicon: 'face',
			healthbar_colour: FlxColor.GRAY,
			vslice_sustains: false,
			image: 'characters/BOYFRIEND',
			dance_every: 2,
			position: [0, 0],
			camera_position: [0, 0],
			animations: [],
			scale: 1
		};
	}
	
	static function getTemplateAnimInfo():AnimationInfo
	{
		return {
			offsets: [0, 0],
			flipX: false,
			flipY: false,
			fps: 24,
			indices: [],
			loop: false,
			anim: '',
			name: ''
		};
	}
}

/**
 * The animation structure to be used when loading a character's animations
 */
typedef AnimationInfo =
{
	/**
	 * The animation name/label
	 */
	var anim:String;
	
	/**
	 * The prefix or symbol name for a animation
	 */
	var name:String;
	
	/**
	 * The framerate for this animation
	 * 
	 * - Default is 24
	 */
	var fps:Int;
	
	/**
	 * Whether the animation should loop
	 */
	var loop:Bool;
	
	/**
	 * The given frame order for the animation
	 */
	var ?indices:Array<Int>;
	
	/**
	 * The offsets to the animation
	 */
	var offsets:Array<Int>;
	
	/**
	 * Whether this animation should be flipped horizontally
	 */
	var ?flipX:Bool;
	
	/**
	 * Whether this animation should be flipped vertically
	 */
	var ?flipY:Bool;
}

/**
 * The structure used to load a character
 */
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
	 * If the character should hold the last frame during a sing pose
	 */
	var ?vslice_sustains:Bool;
	
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

/**
 * Simplified structure of a VSlice characters data
 * 
 * used for conversion
 */
private typedef VSliceCharacterInfo =
{
	var ?singTime:Float;
	
	var ?isPixel:Bool;
	
	var ?danceEvery:Float;
	
	var ?scale:Float;
	
	var ?flipX:Bool;
	
	var ?cameraOffsets:Array<Float>;
	
	var ?offsets:Array<Float>;
	
	var ?assetPath:String;
	
	var ?healthIcon:VSliceIconInfo;
	
	var ?animations:Array<VSliceAnimationInfo>;
}

/**
 * Simplified structure of a VSlice characters health icon data
 * 
 * used for conversion
 */
private typedef VSliceIconInfo =
{
	var ?id:String;
}

/**
 * Simplified structure of a VSlice characters animation data
 * 
 * used for conversion
 */
private typedef VSliceAnimationInfo =
{
	var ?flipX:Bool;
	
	var ?flipY:Bool;
	
	var ?offsets:Array<Float>;
	
	var ?frameRate:Int;
	
	var ?frameIndices:Array<Int>;
	
	var ?assetPath:String;
	
	var ?looped:Bool;
	
	var ?name:String;
	
	var ?prefix:String;
}
