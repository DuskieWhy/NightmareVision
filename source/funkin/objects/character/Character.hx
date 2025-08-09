package funkin.objects.character;

import funkin.objects.character.CharacterData.AnimationInfo;
import funkin.objects.character.CharacterData.CharacterInfo;

// taking some things from base game
// add back miss anim stuff

/**
 * Bopper with extended features to be animated to the strums
 */
// NOT DONE NOT DONE NOT DONE
class Character extends Bopper
{
	public static final DEFAULT_CHARACTER:String = 'bf';
	
	public static function fetchInfo(file:String):CharacterInfo
	{
		var charPath:String = Paths.getPath('characters/$file.json', TEXT, null, true);
		
		if (!FunkinAssets.exists(charPath))
		{
			charPath = Paths.getPrimaryPath('characters/$DEFAULT_CHARACTER.json');
		}
		
		return cast FunkinAssets.parseJson(FunkinAssets.getContent(charPath)); // improve this
	}
	
	/**
	 * how much the camera moves with the characters sings animations
	 */
	public var camDisplacement:Float = 20;
	
	/**
	 * is the player character
	 * 
	 * changes some things like flipping them
	 */
	public var isPlayer:Bool = false;
	
	/**
	 * Character's json name
	 */
	public var curCharacter:String = DEFAULT_CHARACTER;
	
	public var holdTimer:Float = 0;
	
	public var animTimer:Float = 0;
	public var specialAnim:Bool = false;
	public var stunned:Bool = false;
	
	/**
	 * Multiplier of how long a character holds the sing pose
	 */
	public var singDuration:Float = 4;
	
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
	
	public var animations:Array<AnimationInfo> = [];
	
	// gameover suttffs
	public var gameoverCharacter:Null<String> = null;
	
	public var gameoverInitialDeathSound:Null<String> = null;
	
	public var gameoverLoopDeathSound:Null<String> = null;
	
	public var gameoverConfirmDeathSound:Null<String> = null;
	
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
	
	// Used on Character Editor
	public var isPlayerInEditor:Null<Bool> = null;
	public var imageFile:String = '';
	public var jsonScale:Float = 1;
	public var noAntialiasing:Bool = false;
	public var originalFlipX:Bool = false;
	
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
	
	public function new(x:Float = 0, y:Float = 0, character:String = 'bf', isPlayer:Bool = false)
	{
		super(x, y);
		
		this.curCharacter = character;
		this.isPlayer = isPlayer;
		
		genGhosts();
		
		loadFile(fetchInfo(curCharacter));
	}
	
	function genGhosts()
	{
		for (i in 0...4)
		{
			final ghost = new FlxSprite();
			ghost.visible = false;
			ghost.antialiasing = true;
			ghost.alpha = ghostAlpha;
			doubleGhosts.push(ghost);
		}
	}
	
	// clean this up
	public function loadFile(json:CharacterInfo)
	{
		animOffsets.clear();
		scale.set(1, 1);
		updateHitbox();
		
		this.jsonScale = json.scale;
		this.positionArray = json.position;
		this.cameraPosition = json.camera_position;
		
		this.healthIcon = json.healthicon;
		this.singDuration = json.sing_duration;
		this.noAntialiasing = json.no_antialiasing;
		
		this.flipX = (json.flip_x != isPlayer);
		this.originalFlipX = (json.flip_x == true);
		this.imageFile = json.image;
		
		this.antialiasing = !noAntialiasing && ClientPrefs.globalAntialiasing;
		
		this.danceEveryNumBeats = json.dance_every ?? 2;
		
		this.isPlayerInEditor = json._editor_isPlayer;
		
		this.gameoverCharacter = json.gameover_character;
		this.gameoverConfirmDeathSound = json.gameover_confirm_sound;
		this.gameoverLoopDeathSound = json.gameover_loop_sound;
		this.gameoverInitialDeathSound = json.gameover_intial_sound;
		
		loadAtlas(imageFile);
		
		if (jsonScale != 1)
		{
			scale.set(jsonScale, jsonScale);
			updateHitbox();
		}
		
		if (json.healthbar_colors != null && json.healthbar_colors.length > 2)
		{
			// temp keep
			this.healthColorArray = json.healthbar_colors;
			
			this.healthColour = FlxColor.fromRGB(json.healthbar_colors[0], json.healthbar_colors[1], json.healthbar_colors[2]);
		}
		else
		{
			this.healthColour = json.healthbar_colour;
		}
		
		this.animations = json.animations;
		if (animations != null && animations.length > 0)
		{
			for (anim in animations)
			{
				final animAnim:String = '' + anim.anim;
				final animName:String = '' + anim.name;
				final animFps:Int = anim.fps;
				final animLoop:Bool = !!anim.loop; // Bruh
				final animIndices:Array<Int> = anim.indices;
				
				final flipX = anim.flipX ?? false;
				final flipY = anim.flipY ?? false;
				
				if (animIndices != null && animIndices.length > 0)
				{
					addAnimByIndices(animAnim, animName, animIndices, animFps, animLoop, flipX, flipY);
				}
				else
				{
					addAnimByPrefix(animAnim, animName, animFps, animLoop, flipX, flipY);
				}
				
				if (anim.offsets != null && anim.offsets.length > 1)
				{
					addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
				}
			}
		}
		else
		{
			addAnimByPrefix('idle', 'BF idle dance', 24, false);
		}
		
		dance();
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
		
		if (specialAnim && isAnimFinished())
		{
			specialAnim = false;
			dance();
		}
		else if (getAnimName().endsWith('miss') && isAnimFinished())
		{
			dance();
			finishAnim();
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
		
		if (isAnimFinished() && hasAnim(getAnimName() + '-loop')) playAnim(getAnimName() + '-loop');
		
		if (ghostsEnabled)
		{
			for (ghost in doubleGhosts)
				ghost.update(elapsed);
		}
		
		super.update(elapsed);
	}
	
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
	override function dance(forced:Bool = false)
	{
		if (debugMode) return;
		super.dance(forced);
	}
	
	override function playAnim(animToPlay:String, isForced:Bool = false, isReversed:Bool = false, frame:Int = 0)
	{
		specialAnim = false;
		super.playAnim(animToPlay, isForced, isReversed, frame);
	}
	
	override function onBeatHit(beat:Int)
	{
		if (stunned || getAnimName().startsWith('sing')) return;
		super.onBeatHit(beat);
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
			ghost.offset.set(daOffset[0] * scale.x, daOffset[1] * scale.y);
		}
	}
	
	override function destroy()
	{
		for (i in ghostTweenGrp)
			i?.cancel();
			
		ghostTweenGrp = FlxDestroyUtil.destroyArray(ghostTweenGrp);
		
		doubleGhosts = FlxDestroyUtil.destroyArray(doubleGhosts);
		
		super.destroy();
	}
}
