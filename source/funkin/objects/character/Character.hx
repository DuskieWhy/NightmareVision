package funkin.objects.character;

import flixel.FlxSprite;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSort;

import funkin.objects.character.CharacterBuilder;

typedef AnimArray =
{
	var anim:String;
	var name:String;
	var fps:Int;
	var loop:Bool;
	var indices:Array<Int>;
	var offsets:Array<Int>;
}

class Character extends FlxSprite
{
	/**
	 * Disables all animations 
	 */
	public var voicelining:Bool = false;
	
	/**
	 * how much the camera moves with the characters sings animations
	 */
	public var camDisplacement:Float = 20;
	
	/**
	 * Map of characters animation offsets
	 * 
	 * applied in `playAnim`
	 */
	public var animOffsets:Map<String, Array<Dynamic>> = [];
	
	/**
	 * is the player character
	 * 
	 * changes some things like flipping them
	 */
	public var isPlayer:Bool = false;
	
	/**
	 * Character's json name
	 */
	public var curCharacter:String = CharacterBuilder.DEFAULT_CHARACTER;
	
	public var holdTimer:Float = 0;
	public var heyTimer:Float = 0;
	public var animTimer:Float = 0;
	public var specialAnim:Bool = false;
	public var stunned:Bool = false;
	
	/**
	 * Multiplier of how long a character holds the sing pose
	 */
	public var singDuration:Float = 4;
	
	public var idleSuffix:String = '';
	public var animSuffix:String = '';
	public var animSuffixExclusions = ['idle', 'danceLeft', 'danceRight', 'miss'];
	
	/**
	 * if true, character uses `danceLeft` and `danceRight` instead of `idle`
	 */
	public var danceIdle:Bool = false;
	
	public var skipDance:Bool = false;
	
	/**
	 * if an idle animation goes over a certain amount of frames, it wont play every couple of beats. set this to `true` to force the idle to play even if the animation isnt' complete
	**/
	public var forceDance:Bool = false;
	
	/**
	 * The characters health icon
	 */
	public var healthIcon:String = 'face';
	
	public var animationsArray:Array<AnimArray> = [];
	
	/**
	 * Character offsets defined by the json
	 */
	public var positionArray:Array<Float> = [0, 0];
	
	/**
	 * Camera offsets defined by the json
	 */
	public var cameraPosition:Array<Float> = [0, 0];
	
	/**
	 * how much the ghost anims move when played
	 */
	public var ghostDisplacement:Float = 40;
	
	/**
	 *	if enabled, ghosts will show on double notes for the character
	 */
	public var ghostsEnabled:Bool = false;
	
	/**
	 * Array of all ghosts
	 */
	public var doubleGhosts:Array<FlxSprite> = [];
	
	/**
	 * Array of all ghosts tweens
	 */
	public var ghostTweenGrp:Array<FlxTween> = [];
	
	/**
	 * Alpha that the ghosts doubles appear at
	 */
	public var ghostAlpha:Float = 0.6;
	
	/**
	 * Last hit row index
	 */
	public var mostRecentRow:Int = 0; // for ghost anims n shit
	
	// miss-poses coloring settings
	public var hasMissAnimations:Bool = false;
	public var useMissColoring:Bool = false;
	public var missColor = 0x71650090;
	public var resetColor(default, set) = FlxColor.WHITE;
	
	function set_resetColor(value:FlxColor)
	{
		color = resetColor;
		return value;
	}
	
	// Used on Character Editor
	public var imageFile:String = '';
	public var jsonScale:Float = 1;
	public var noAntialiasing:Bool = false;
	public var originalFlipX:Bool = false;
	public var skipJsonStuff:Bool = false;
	
	/**
	 * disables some functionality for use out of play
	 * 
	 * used in the Character editor
	 */
	public var debugMode:Bool = false;
	
	/**
	 * The Characters health bar colours stored as `[r,g,b]`
	 */
	public var healthColorArray:Array<Int> = [255, 0, 0];
	
	public var healthColour:Int = FlxColor.RED;
	
	public function new(x:Float = 0, y:Float = 0, character:String = 'bf', ?isPlayer:Bool = false, ?skipCreate:Bool = false)
	{
		super(x, y);
		
		curCharacter = character;
		this.isPlayer = isPlayer;
		
		if (!skipCreate) createNow();
	}
	
	// USED FOR THE EDITOR... DW ABOUT IT!
	public function createNow()
	{
		buildGhosts();
		onCreate();
	}
	
	function onCreate()
	{
		loadFile(CharacterBuilder.getCharacterFile(curCharacter));
		
		if (animOffsets.exists('singLEFTmiss') || animOffsets.exists('singDOWNmiss') || animOffsets.exists('singUPmiss') || animOffsets.exists('singRIGHTmiss')) hasMissAnimations = true;
		recalculateDanceIdle();
		dance();
	}
	
	function buildGhosts()
	{
		for (i in 0...4)
		{
			var ghost = new FlxSprite();
			ghost.visible = false;
			ghost.antialiasing = true;
			ghost.alpha = ghostAlpha;
			doubleGhosts.push(ghost);
		}
	}
	
	public function loadGraphicFromType(path:String, type:String)
	{
		switch (type)
		{
			case "packer":
				frames = Paths.getPackerAtlas(path);
				
			case "sparrow":
				frames = Paths.getMultiAtlas(path.split(','));
		}
	}
	
	// clean this up
	public function loadFile(json:CharacterFile)
	{
		animOffsets.clear();
		scale.set(1, 1);
		updateHitbox();
		
		final spriteType = FunkinAssets.exists(Paths.getPath('images/' + json.image + '.txt', TEXT, null, true), TEXT) ? 'packer' : "sparrow";
		
		// copy values over
		if (!skipJsonStuff) imageFile = json.image;
		skipJsonStuff = false;
		jsonScale = json.scale;
		positionArray = json.position;
		cameraPosition = json.camera_position;
		
		healthIcon = json.healthicon;
		singDuration = json.sing_duration;
		noAntialiasing = json.no_antialiasing;
		
		flipX = (json.flip_x != isPlayer);
		originalFlipX = (json.flip_x == true);
		
		loadGraphicFromType(imageFile, spriteType);
		
		if (jsonScale != 1)
		{
			scale.set(jsonScale, jsonScale);
			updateHitbox();
		}
		
		final shouldUseAntialiasing = !noAntialiasing && ClientPrefs.globalAntialiasing;
		antialiasing = shouldUseAntialiasing;
		
		if (json.healthbar_colors != null && json.healthbar_colors.length > 2)
		{
			// temp keep
			healthColorArray = json.healthbar_colors;
			
			healthColour = FlxColor.fromRGB(json.healthbar_colors[0], json.healthbar_colors[1], json.healthbar_colors[2]);
		}
		
		animationsArray = json.animations;
		if (animationsArray != null && animationsArray.length > 0)
		{
			for (anim in animationsArray)
			{
				final animAnim:String = '' + anim.anim;
				final animName:String = '' + anim.name;
				final animFps:Int = anim.fps;
				final animLoop:Bool = !!anim.loop; // Bruh
				final animIndices:Array<Int> = anim.indices;
				
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
			}
		}
		else
		{
			animation.addByPrefix('idle', 'BF idle dance', 24, false);
		}
	}
	
	override function update(elapsed:Float)
	{
		if (debugMode || isAnimNull())
		{
			super.update(elapsed);
			return;
		}
		
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
				if (specialAnim && (getAnimName() == 'hey' || getAnimName() == 'cheer'))
				{
					specialAnim = false;
					dance();
				}
				heyTimer = 0;
			}
		}
		else if (specialAnim && isAnimFinished())
		{
			specialAnim = false;
			dance();
		}
		else if (getAnimName().endsWith('miss') && isAnimFinished())
		{
			dance();
			animation.finish();
		}
		
		if (getAnimName().startsWith('sing'))
		{
			holdTimer += elapsed;
		}
		else if (isPlayer) holdTimer = 0;
		
		if (!isPlayer && holdTimer >= Conductor.stepCrotchet * 0.0011 * singDuration)
		{
			dance();
			holdTimer = 0;
		}
		
		if (isAnimFinished() && animation.exists(getAnimName() + '-loop')) playAnim(getAnimName() + '-loop');
		
		if (ghostsEnabled)
		{
			for (ghost in doubleGhosts)
				ghost.update(elapsed);
		}
		
		super.update(elapsed);
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
	 * Plays the characters idle animation
	 */
	public function dance()
	{
		if (!debugMode && !skipDance && !specialAnim && animTimer <= 0 && !voicelining)
		{
			if (danceIdle)
			{
				danced = !danced;
				
				if (danced) playAnim('danceRight' + idleSuffix);
				else playAnim('danceLeft' + idleSuffix, forceDance);
			}
			else if (animation.exists('idle' + idleSuffix))
			{
				playAnim('idle' + idleSuffix, forceDance);
			}
			
			if (useMissColoring) color = resetColor;
		}
	}
	
	public function playAnim(name:String, forced:Bool = false, reversed:Bool = false, frame:Int = 0):Void
	{
		specialAnim = false;
		
		var animName:String = name;
		
		var shouldExclude:Bool = false;
		for (e in animSuffixExclusions)
		{
			if (animName.toLowerCase().contains(e.toLowerCase()))
			{
				shouldExclude = true;
				break;
			}
		}
		
		if (shouldExclude) animName = name;
		else animName += animSuffix;
		
		if (useMissColoring && !name.contains('miss') || hasMissAnimations && name.contains('miss')) color = resetColor;
		else if (name.contains('miss'))
		{
			if (!hasMissAnimations && useMissColoring)
			{
				color = missColor;
				animName = animName.replace('miss', '');
			}
		}
		
		animation.play(animName, forced, reversed, frame);
		
		if (animOffsets.exists(animName))
		{
			final daOffset = animOffsets.get(animName);
			offset.set(daOffset[0], daOffset[1]);
		}
		
		if (curCharacter.startsWith('gf'))
		{
			if (animName == 'singLEFT') danced = true;
			else if (animName == 'singRIGHT') danced = false;
			
			if (animName == 'singUP' || animName == 'singDOWN')
			{
				danced = !danced;
			}
		}
	}
	
	public function returnDisplacePoint():FlxPoint
	{
		return switch (getAnimName().substr(4).split('-')[0].toLowerCase())
		{
			case 'up':
				FlxPoint.weak(0, -camDisplacement);
			case 'down':
				FlxPoint.weak(0, camDisplacement);
			case 'left':
				FlxPoint.weak(-camDisplacement, 0);
			case 'right':
				FlxPoint.weak(camDisplacement, 0);
			default:
				FlxPoint.weak();
		}
	}
	
	function sortAnims(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);
	}
	
	public var danceEveryNumBeats:Int = 2;
	
	private var settingCharacterUp:Bool = true;
	
	public function recalculateDanceIdle()
	{
		var lastDanceIdle:Bool = danceIdle;
		danceIdle = (animation.exists('danceLeft' + idleSuffix) && animation.exists('danceRight' + idleSuffix));
		
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
	
	public function playGhostAnim(ghostID = 0, animName:String, force:Bool = false, reversed:Bool = false, frame:Int = 0)
	{
		var ghost:FlxSprite = doubleGhosts[ghostID];
		ghost.scale.copyFrom(scale);
		ghost.frames = frames;
		ghost.animation.copyFrom(animation);
		ghost.antialiasing = antialiasing;
		ghost.x = x;
		ghost.y = y;
		ghost.flipX = flipX;
		ghost.flipY = flipY;
		ghost.alpha = alpha * ghostAlpha;
		ghost.visible = true;
		ghost.color = healthColour;
		ghost.animation.play(animName, force, reversed, frame);
		
		ghostTweenGrp[ghostID]?.cancel();
		
		final direction:String = animName.substring(4).split('-')[0];
		
		inline function resolveDir(xDir:Bool = false):Float
		{
			var output:Float = 0;
			switch (direction)
			{
				case 'UP':
					if (!xDir) output = -ghostDisplacement;
				case 'DOWN':
					if (!xDir) output = ghostDisplacement;
				case 'RIGHT':
					if (xDir) output = ghostDisplacement;
				case 'LEFT':
					if (xDir) output = -ghostDisplacement;
			}
			
			return output;
		}
		
		final moveX = x + resolveDir(true);
		final moveY = y + resolveDir(false);
		
		ghostTweenGrp[ghostID] = FlxTween.tween(ghost, {alpha: 0, x: moveX, y: moveY}, 0.75,
			{
				onComplete: (twn) -> {
					ghost.visible = false;
					ghostTweenGrp[ghostID] = null;
				}
			});
			
		if (animOffsets.exists(animName))
		{
			final daOffset = animOffsets.get(animName);
			ghost.offset.set(daOffset[0], daOffset[1]);
		}
	}
	
	override function destroy()
	{
		for (i in ghostTweenGrp)
		{
			i?.cancel();
			i = null;
		}
		
		ghostTweenGrp = FlxDestroyUtil.destroyArray(ghostTweenGrp);
		
		doubleGhosts = FlxDestroyUtil.destroyArray(doubleGhosts);
		
		animOffsets.clear();
		
		super.destroy();
	}
	
	/**
	 * explanatory
	 */
	public function getAnimName():String
	{
		return isAnimNull() ? '' : animation.curAnim.name;
	}
	
	/**
	 * explanatory
	 */
	public function isAnimNull():Bool
	{
		return (animation.curAnim == null);
	}
	
	/**
	 * explanatory
	 */
	public function isAnimFinished():Bool
	{
		return isAnimNull() ? false : animation.curAnim.finished;
	}
	
	public var animCurFrame(get, set):Int;
	
	function get_animCurFrame():Int
	{
		return isAnimNull() ? 0 : animation.curAnim.curFrame;
	}
	
	function set_animCurFrame(value:Int):Int
	{
		return isAnimNull() ? 0 : (animation.curAnim.curFrame = value);
	}
	
	public function getAnimNumFrames():Int return isAnimNull() ? 0 : animation.curAnim.numFrames;
	
	/**
	 * explanatory
	 */
	public function pauseAnim():Void
	{
		animation.pause();
	}
	
	/**
	 * explanatory
	 */
	public function resumeAnim():Void
	{
		animation.resume();
	}
	
	/**
	 * explanatory
	 */
	public function getAnimByName(name:String):Dynamic
	{
		return animation.getByName(name);
	}
}
