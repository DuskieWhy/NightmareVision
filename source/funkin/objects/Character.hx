package funkin.objects;

import funkin.objects.*;
import funkin.data.*;
import funkin.states.*;
import funkin.states.substates.*;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.effects.FlxTrail;
import flixel.animation.FlxBaseAnimation;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import funkin.data.Section.SwagSection;
#if MODS_ALLOWED
import sys.io.File;
import sys.FileSystem;
#end
import openfl.utils.AssetType;
import openfl.utils.Assets;
import haxe.Json;
import haxe.format.JsonParser;

using StringTools;

typedef CharacterFile =
{
	var animations:Array<AnimArray>;
	var image:String;
	var scale:Float;
	var sing_duration:Float;
	var healthicon:String;

	var position:Array<Float>;
	var camera_position:Array<Float>;

	var flip_x:Bool;
	var no_antialiasing:Bool;
	var healthbar_colors:Array<Int>;
}

typedef AnimArray =
{
	var anim:String;
	var name:String;
	var fps:Int;
	var loop:Bool;
	var indices:Array<Int>;
	var offsets:Array<Int>;
	@:optional var cameraOffset:Array<Float>;
}

// @:build(funkin.utils.MacroUtil.buildFlxSprite())
class Character extends FlxSprite
{
	public var mostRecentRow:Int = 0; // for ghost anims n shit

	public var voicelining:Bool = false;

	public var idleAnims:Array<String> = ['idle'];
	public var animOffsets:Map<String, Array<Dynamic>>;
	public var camOffsets:Map<String, Array<Float>> = [];
	public var debugMode:Bool = false;

	public var isPlayer:Bool = false;
	public var curCharacter:String = DEFAULT_CHARACTER;

	public var holdTimer:Float = 0;
	public var heyTimer:Float = 0;
	public var animTimer:Float = 0;
	public var specialAnim:Bool = false;
	public var animationNotes:Array<Dynamic> = [];
	public var stunned:Bool = false;
	public var singDuration:Float = 4; // Multiplier of how long a character holds the sing pose
	public var idleSuffix:String = '';
	public var animSuffix:String = '';
	public var animSuffixExclusions = ['idle', 'danceLeft', 'danceRight', 'miss'];
	public var danceIdle:Bool = false; // Character use "danceLeft" and "danceRight" instead of "idle"
	public var skipDance:Bool = false;

	public var healthIcon:String = 'face';
	public var animationsArray:Array<AnimArray> = [];

	public var positionArray:Array<Float> = [0, 0];
	public var cameraPosition:Array<Float> = [0, 0];

	public var ghostsEnabled:Bool = true;
	public var doubleGhosts:Array<FlxSprite> = [];
	public var ghostID:Int = 0;
	public var ghostAnim:String = '';
	public var ghostTweenGRP:Array<FlxTween> = [];

	public var hasMissAnimations:Bool = false;

	// Used on Character Editor
	public var imageFile:String = '';
	public var jsonScale:Float = 1;
	public var noAntialiasing:Bool = false;
	public var originalFlipX:Bool = false;
	public var healthColorArray:Array<Int> = [255, 0, 0];

	public var baseCameraDisplacement:Float = 20;

	public static final DEFAULT_CHARACTER:String = 'bf'; // In case a character is missing, it will use BF on its place

	public static function getCharacterFile(character:String):CharacterFile
	{
		var characterPath:String = 'characters/' + character + '.json';

		#if MODS_ALLOWED
		var path:String = Paths.modFolders(characterPath);
		if (!FileSystem.exists(path))
		{
			path = Paths.getSharedPath(characterPath);
		}

		if (!FileSystem.exists(path))
		#else
		var path:String = Paths.getSharedPath(characterPath);
		if (!Assets.exists(path))
		#end
		{
			path = Paths.getSharedPath('characters/' + DEFAULT_CHARACTER +
				'.json'); // If a character couldn't be found, change him to BF just to prevent a crash
		}

		#if MODS_ALLOWED
		var rawJson = File.getContent(path);
		#else
		var rawJson = Assets.getText(path);
		#end

		return cast Json.parse(rawJson);
	}

	public function new(x:Float, y:Float, ?character:String = 'bf', ?isPlayer:Bool = false)
	{
		super(x, y);

		animOffsets = new Map();
		curCharacter = character;
		this.isPlayer = isPlayer;
		antialiasing = ClientPrefs.globalAntialiasing;

		for (i in 0...4)
		{
			var ghost = new FlxSprite();
			ghost.visible = false;
			ghost.antialiasing = true;
			ghost.alpha = 0.6;
			doubleGhosts.push(ghost);
		}
		var library:String = null;
		switch (curCharacter)
		{
			// case 'your character name in case you want to hardcode them instead':

			default:
				var json:CharacterFile = getCharacterFile(curCharacter);
				var spriteType = "sparrow";
				// sparrow
				// packer
				// texture
				#if MODS_ALLOWED
				var modTxtToFind:String = Paths.modsTxt(json.image);
				var txtToFind:String = Paths.getPath('images/' + json.image + '.txt', TEXT);

				// var modTextureToFind:String = Paths.modFolders("images/"+json.image);
				// var textureToFind:String = Paths.getPath('images/' + json.image, new AssetType();

				if (FileSystem.exists(modTxtToFind) || FileSystem.exists(txtToFind) || Assets.exists(txtToFind))
				#else
				if (Assets.exists(Paths.getPath('images/' + json.image + '.txt', TEXT)))
				#end
				{
					spriteType = "packer";
				}

				#if MODS_ALLOWED
				var modAnimToFind:String = Paths.modFolders('images/' + json.image + '/Animation.json');
				var animToFind:String = Paths.getPath('images/' + json.image + '/Animation.json', TEXT);

				// var modTextureToFind:String = Paths.modFolders("images/"+json.image);
				// var textureToFind:String = Paths.getPath('images/' + json.image, new AssetType();

				if (FileSystem.exists(modAnimToFind) || FileSystem.exists(animToFind) || Assets.exists(animToFind))
				#else
				if (Assets.exists(Paths.getPath('images/' + json.image + '/Animation.json', TEXT)))
				#end
				{
					spriteType = "texture";
				}

				switch (spriteType)
				{
					case "packer":
						frames = Paths.getPackerAtlas(json.image);

					case "sparrow":
						frames = Paths.getSparrowAtlas(json.image);

					// case "texture":
					// 	frames = AtlasFrameMaker.construct(json.image);
				}
				imageFile = json.image;

				if (json.scale != 1)
				{
					jsonScale = json.scale;
					setGraphicSize(Std.int(width * jsonScale));
					updateHitbox();
				}

				positionArray = json.position;
				cameraPosition = json.camera_position;

				healthIcon = json.healthicon;
				singDuration = json.sing_duration;
				flipX = !!json.flip_x;
				if (json.no_antialiasing)
				{
					antialiasing = false;
					noAntialiasing = true;
				}

				if (json.healthbar_colors != null && json.healthbar_colors.length > 2) healthColorArray = json.healthbar_colors;

				antialiasing = !noAntialiasing;
				if (!ClientPrefs.globalAntialiasing) antialiasing = false;

				animationsArray = json.animations;
				if (animationsArray != null && animationsArray.length > 0)
				{
					for (anim in animationsArray)
					{
						var animAnim:String = '' + anim.anim;
						var animName:String = '' + anim.name;
						var animFps:Int = anim.fps;
						var animLoop:Bool = !!anim.loop; // Bruh
						var animIndices:Array<Int> = anim.indices;
						var camOffset:Null<Array<Float>> = anim.cameraOffset;
						if (camOffset == null)
						{
							switch (animAnim)
							{
								case 'singLEFT' | 'singLEFTmiss' | 'singLEFT-alt':
									camOffset = [-30, 0];
								case 'singRIGHT' | 'singRIGHTmiss' | 'singRIGHT-alt':
									camOffset = [30, 0];
								case 'singUP' | 'singUPmiss' | 'singUP-alt':
									camOffset = [0, -30];
								case 'singDOWN' | 'singDOWNmiss' | 'singDOWN-alt':
									camOffset = [0, 30];
								default:
									camOffset = [0, 0];
							}
						}
						if (animIndices != null && animIndices.length > 0)
						{
							animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
						}
						else
						{
							animation.addByPrefix(animAnim, animName, animFps, animLoop);
						}

						if (anim.offsets != null && anim.offsets.length > 1)
						{
							addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
						}
						camOffsets[anim.anim] = [camOffset[0], camOffset[1]];
					}
				}
				else
				{
					quickAnimAdd('idle', 'BF idle dance');
				}
				// trace('Loaded file to character ' + curCharacter);
		}
		originalFlipX = flipX;

		if (animOffsets.exists('singLEFTmiss') || animOffsets.exists('singDOWNmiss') || animOffsets.exists('singUPmiss') || animOffsets.exists('singRIGHTmiss'))
			hasMissAnimations = true;
		recalculateDanceIdle();
		dance();

		if (isPlayer)
		{
			flipX = !flipX;

			/*// Doesn't flip for BF, since his are already in the right place???
				if (!curCharacter.startsWith('bf'))
				{
					// var animArray
					if(animation.getByName('singLEFT') != null && animation.getByName('singRIGHT') != null)
					{
						var oldRight = animation.getByName('singRIGHT').frames;
						animation.getByName('singRIGHT').frames = animation.getByName('singLEFT').frames;
						animation.getByName('singLEFT').frames = oldRight;
					}

					// IF THEY HAVE MISS ANIMATIONS??
					if (animation.getByName('singLEFTmiss') != null && animation.getByName('singRIGHTmiss') != null)
					{
						var oldMiss = animation.getByName('singRIGHTmiss').frames;
						animation.getByName('singRIGHTmiss').frames = animation.getByName('singLEFTmiss').frames;
						animation.getByName('singLEFTmiss').frames = oldMiss;
					}
			}*/
		}

		// switch(curCharacter)
		// {
		// 	case 'pico-speaker':
		// 		skipDance = true;
		// 		loadMappedAnims();
		// 		playAnim("shoot1");
		// }
	}

	override function update(elapsed:Float)
	{
		if (!debugMode && animation.curAnim != null)
		{
			if (animTimer > 0)
			{
				animTimer -= elapsed;
				if (animTimer <= 0)
				{
					animTimer = 0;
					dance();
				}
			}
			if (heyTimer > 0)
			{
				heyTimer -= elapsed;
				if (heyTimer <= 0)
				{
					if (specialAnim && (animation.curAnim.name == 'hey' || animation.curAnim.name == 'cheer'))
					{
						specialAnim = false;
						dance();
					}
					heyTimer = 0;
				}
			}
			else if (specialAnim && animation.curAnim.finished)
			{
				trace("special done");
				specialAnim = false;
				dance();
			}
			else if (animation.curAnim.name.endsWith('miss') && animation.curAnim.finished)
			{
				dance();
				animation.curAnim.finish();
			}

			// switch(curCharacter)
			// {
			// 	case 'pico-speaker':
			// 		if(animationNotes.length > 0 && Conductor.songPosition > animationNotes[0][0])
			// 		{
			// 			var noteData:Int = 1;
			// 			if(animationNotes[0][1] > 2) noteData = 3;

			// 			noteData += FlxG.random.int(0, 1);
			// 			playAnim('shoot' + noteData, true);
			// 			animationNotes.shift();
			// 		}
			// 		if(animation.curAnim.finished) playAnim(animation.curAnim.name, false, false, animation.curAnim.frames.length - 3);
			// }

			if (animation.curAnim.name.startsWith('sing'))
			{
				holdTimer += elapsed;
			}
			else if (isPlayer) holdTimer = 0;

			if (!isPlayer && holdTimer >= Conductor.stepCrotchet * 0.0011 * singDuration)
			{
				dance();
				holdTimer = 0;
			}

			if (animation.curAnim.finished && animation.getByName(animation.curAnim.name + '-loop') != null)
			{
				playAnim(animation.curAnim.name + '-loop');
			}
		}
		if (ghostsEnabled)
		{
			for (ghost in doubleGhosts)
				ghost.update(elapsed);
		}

		super.update(elapsed);

		if (!debugMode)
		{
			if (animation.curAnim != null)
			{
				var name = animation.curAnim.name;
				if (name.startsWith("hold"))
				{
					if (name.endsWith("Start") && animation.curAnim.finished)
					{
						var newName = name.substring(0, name.length - 5);
						var singName = "sing" + name.substring(3, name.length - 5);
						if (animation.getByName(newName) != null)
						{
							playAnim(newName, true);
						}
						else
						{
							playAnim(singName, true);
						}
					}
				}
			}
		}
	}

	public var danced:Bool = false;

	override function draw()
	{
		if (ghostsEnabled)
		{
			for (ghost in doubleGhosts)
			{
				if (ghost.visible) ghost.draw();
			}
		}
		super.draw();
	}

	/**
	 * FOR GF DANCING SHIT
	 */
	public function dance()
	{
		if (!debugMode && !skipDance && !specialAnim && animTimer <= 0 && !voicelining)
		{
			if (danceIdle)
			{
				danced = !danced;

				if (danced) playAnim('danceRight' + idleSuffix);
				else playAnim('danceLeft' + idleSuffix);
			}
			else if (animation.getByName('idle' + idleSuffix) != null)
			{
				playAnim('idle' + idleSuffix);
			}
		}
	}

	public function playAnim(name:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		specialAnim = false;

		var animationName:String = name;

		// weird ass method but hey, it works
		var p:Int = 0;
		for (e in animSuffixExclusions)
		{
			if (animationName.toLowerCase().contains(e.toLowerCase())) p++;
		}

		if (p > 0) animationName = name;
		else animationName += animSuffix;

		animation.play(animationName, Force, Reversed, Frame);

		var daOffset = animOffsets.get(animationName);
		if (animOffsets.exists(animationName))
		{
			offset.set(daOffset[0], daOffset[1]);
		}
		else offset.set(0, 0);

		if (curCharacter.startsWith('gf'))
		{
			if (animationName == 'singLEFT')
			{
				danced = true;
			}
			else if (animationName == 'singRIGHT')
			{
				danced = false;
			}

			if (animationName == 'singUP' || animationName == 'singDOWN')
			{
				danced = !danced;
			}
		}
	}

	inline public function returnDisplacePoint():FlxPoint
	{
		var displace:FlxPoint = FlxPoint.weak();
		switch (animation.curAnim.name.substr(4).split('-')[0].toLowerCase())
		{
			case 'up' | 'up-alt':
				return displace.set(0, -baseCameraDisplacement);
			case 'down' | 'down-alt':
				return displace.set(0, baseCameraDisplacement);
			case 'left' | 'left-alt':
				return displace.set(-baseCameraDisplacement, 0);
			case 'right' | 'right-alt':
				return displace.set(baseCameraDisplacement, 0);
			default:
				return displace;
		}
	}

	// function loadMappedAnims():Void
	// {
	// 	var noteData:Array<SwagSection> = Song.loadFromJson('picospeaker', Paths.formatToSongPath(PlayState.SONG.song)).notes;
	// 	for (section in noteData) {
	// 		for (songNotes in section.sectionNotes) {
	// 			animationNotes.push(songNotes);
	// 		}
	// 	}
	// 	TankmenBG.animationNotes = animationNotes;
	// 	animationNotes.sort(sortAnims);
	// }

	function sortAnims(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);
	}

	public var danceEveryNumBeats:Int = 2;

	private var settingCharacterUp:Bool = true;

	public function recalculateDanceIdle()
	{
		var lastDanceIdle:Bool = danceIdle;
		danceIdle = (animation.getByName('danceLeft' + idleSuffix) != null && animation.getByName('danceRight' + idleSuffix) != null);

		if (settingCharacterUp)
		{
			danceEveryNumBeats = (danceIdle ? 1 : 2);
		}
		else if (lastDanceIdle != danceIdle)
		{
			var calc:Float = danceEveryNumBeats;
			if (danceIdle) calc /= 2;
			else calc *= 2;

			danceEveryNumBeats = Math.round(Math.max(calc, 1));
		}
		settingCharacterUp = false;
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsets[name] = [x, y];
	}

	public function switchOffset(offset1:String, offset2:String)
	{
		animOffsets[offset1] = [animOffsets[offset2][0], animOffsets[offset2][1]];
		animOffsets[offset2] = [animOffsets[offset1][0], animOffsets[offset1][1]];
	}

	public function quickAnimAdd(name:String, anim:String)
	{
		animation.addByPrefix(name, anim, 24, false);
	}

	public function playGhostAnim(ghostID = 0, AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0)
	{
		var ghost:FlxSprite = doubleGhosts[ghostID];
		ghost.scale.copyFrom(scale);
		ghost.frames = frames;
		ghost.animation.copyFrom(animation);
		ghost.antialiasing = antialiasing;
		// ghost.shader = shader;
		ghost.antialiasing = antialiasing;
		ghost.x = x;
		ghost.y = y;
		ghost.flipX = flipX;
		ghost.flipY = flipY;
		ghost.alpha = alpha * 0.6;
		ghost.visible = true;
		ghost.color = FlxColor.fromRGB(healthColorArray[0], healthColorArray[1], healthColorArray[2]);
		ghost.animation.play(AnimName, Force, Reversed, Frame);
		if (ghostTweenGRP[ghostID] != null) ghostTweenGRP[ghostID].cancel();

		var direction:String = AnimName.substring(4).split('-')[0];

		// rewrite this
		var directionMap:Map<String, Array<Float>> = ['UP' => [0, -45], 'DOWN' => [0, 45], 'RIGHT' => [45, 0], 'LEFT' => [-45, 0],];
		// had to add alt cuz it kept crashing on room code LOL

		var moveX = x;
		var moveY = y;

		if (directionMap.exists(direction))
		{
			var dir = directionMap.get(direction);
			moveX += dir[0];
			moveY += dir[1];
		}

		ghostTweenGRP[ghostID] = FlxTween.tween(ghost, {alpha: 0, x: moveX, y: moveY}, 0.75,
			{
				ease: FlxEase.linear,
				onComplete: function(twn:FlxTween) {
					ghost.visible = false;
					// ghostTweenGRP[ghostID].destroy(); // maybe?

					ghostTweenGRP[ghostID] = null;
				}
			});

		var daOffset = animOffsets.get(AnimName);
		if (animOffsets.exists(AnimName)) ghost.offset.set(daOffset[0], daOffset[1]);
		else ghost.offset.set(0, 0);
	}
}
