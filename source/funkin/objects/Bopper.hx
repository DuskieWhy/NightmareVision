package funkin.objects;

import openfl.display.Graphics;

import flixel.math.FlxRect;
import flixel.util.FlxDirectionFlags;

import animate.FlxAnimateFrames;
import animate.FlxAnimate;

import flixel.util.FlxSignal.FlxTypedSignal;

// highly based of base games bopper class
// i liked it alot
class Bopper extends FlxSprite
{
	@:inheritDoc(flixel.animation.FlxAnimationController.onFinish)
	public final onAnimationFinish = new FlxTypedSignal<(animName:String) -> Void>();
	
	@:inheritDoc(flixel.animation.FlxAnimationController.onFrameChange)
	public final onAnimationFrameChange = new FlxTypedSignal<(animName:String, frameNumber:Int, frameIndex:Int) -> Void>();
	
	@:inheritDoc(flixel.animation.FlxAnimationController.onLoop)
	public final onAnimationLoop = new FlxTypedSignal<(animName:String) -> Void>();
	
	/**
	 * Texture atlas instance. Initiated through `loadAtlas`.
	 */
	public var animateAtlas:Null<FlxAnimate> = null;
	
	/**
	 *	Animation offsets
	 * 
	 * applied through `playAnim`
	 */
	public var animOffsets:Map<String, Array<Float>> = [];
	
	/**
	 * However many beats between dances
	 */
	public var danceEveryNumBeats:Int = 2;
	
	/**
	 * Whether the bopper should dance left and right.
	 * - If true, alternate playing `danceLeft` and `danceRight`.
	 * - If false, play `idle` every time.
	 *
	 * You can manually set this value, or you can leave it as `null` to determine it automatically.
	 */
	public var alternatingDance:Null<Bool> = null;
	
	/**
	 * If `false`, playAnim will no longer function
	 * 
	 * used by `playAnimForDuration`'s `force` arguement.
	 */
	public var canPlayAnimations:Bool = true;
	
	/**
	 * internal tracker for alternating dance chars.
	 */
	var danced:Bool = false;
	
	/**
	 * Suffix added to the characters `dance` animation.
	 */
	public var idleSuffix:String = '';
	
	public var scalableOffsets:Bool = false;
	
	//-----
	
	public function new(x:Float = 0, y:Float = 0, danceEveryNumBeats:Int = 2)
	{
		super(x, y);
		this.danceEveryNumBeats = danceEveryNumBeats;
		
		this.animation.onFinish.add((anim) -> onAnimationFinish.dispatch(anim));
		this.animation.onFrameChange.add((anim, num, idx) -> onAnimationFrameChange.dispatch(anim, num, idx));
		this.animation.onLoop.add((anim) -> onAnimationLoop.dispatch(anim));
	}
	
	override function update(elapsed:Float)
	{
		animateAtlas?.update(elapsed);
		
		super.update(elapsed);
	}
	
	/**
	 * initiates the visual sprite for the class
	 * 
	 * If the path given is to a texture atlas, it will load a texture atlas
	 * @param path 
	 */
	public function loadAtlas(path:String)
	{
		final isAtlasSprite = FunkinAssets.exists(Paths.getPath('images/$path/Animation.json', TEXT, null, true));
		if (isAtlasSprite)
		{
			if (animateAtlas == null)
			{
				animateAtlas = new FlxAnimate();
				
				animateAtlas.animation.onFinish.add((anim) -> onAnimationFinish.dispatch(__prevPlayedAnimation));
				animateAtlas.animation.onFrameChange.add((anim, num, idx) -> onAnimationFrameChange.dispatch(__prevPlayedAnimation, num, idx));
				animateAtlas.animation.onLoop.add((anim) -> onAnimationLoop.dispatch(__prevPlayedAnimation));
			}
			
			animateAtlas.frames = FlxAnimateFrames.fromAnimate((Paths.getPath('images/$path', TEXT, null, true)));
		}
		else
		{
			animateAtlas = FlxDestroyUtil.destroy(animateAtlas);
			
			final frames = Paths.getMultiAtlas(path.split(','));
			if (frames != null)
			{
				this.frames = frames;
			}
		}
	}
	
	public function addOffset(anim:String, x:Float = 0, y:Float = 0):Void
	{
		animOffsets[anim] = [x, y];
	}
	
	/**
	 * Ensures a anim exists before playing
	 * 
	 * If there is no anim but there is a suffix, it will strip the suffix and try again
	 * 
	 * If still fails, `Null` is returned.
	 */
	public function correctAnimationName(animName:String):Null<String> // from base game !
	{
		if (hasAnim(animName)) return animName;
		
		// strip any post fix
		if (animName.lastIndexOf('-') != -1)
		{
			final correctedName = animName.substring(0, animName.lastIndexOf('-'));
			return correctAnimationName(correctedName);
		}
		else
		{
			// trace('missing anim ' + animName);
			return null;
		}
	}
	
	public function playAnim(animToPlay:String, isForced:Bool = false, isReversed:Bool = false, frame:Int = 0):Void
	{
		if (!canPlayAnimations) return;
		
		final correctedAnim = correctAnimationName(animToPlay);
		
		if (correctedAnim == null) return;
		
		if (animateAtlas != null)
		{
			animateAtlas.anim.play(correctedAnim, isForced, isReversed, frame);
			animateAtlas.update(0);
		}
		else animation.play(correctedAnim, isForced, isReversed, frame);
		
		final animationOffsets = animOffsets.get(correctedAnim);
		
		if (animationOffsets != null)
		{
			offset.set(animationOffsets[0], animationOffsets[1]);
			
			if (scalableOffsets)
			{
				offset.x *= scale.x;
				offset.y *= scale.y;
			}
		}
		
		__prevPlayedAnimation = animToPlay;
	}
	
	final forcedAnimationTimer:FlxTimer = new FlxTimer();
	
	/**
	 * Plays a animation for a given amount of time and will `dance` when it is done
	 * @param forced If true, the character will not play any other animation until the duration is complete
	 */
	public function playAnimForDuration(animToPlay:String, duration:Float = 0.6, forced:Bool = false)
	{
		if (forced) canPlayAnimations = true;
		playAnim(animToPlay, true);
		
		if (forced) canPlayAnimations = false;
		forcedAnimationTimer.start(duration, tmr -> {
			if (forced) canPlayAnimations = true;
			dance();
		});
	}
	
	public var canDance:Bool = true;
	
	/**
	 * Makes the sprite "dance".
	 */
	public function dance(forced:Bool = false):Void
	{
		if (alternatingDance == null)
		{
			recalculateDanceIdle();
		}
		
		if (!canDance) return;
		
		if (alternatingDance)
		{
			danced = !danced;
			if (danced) playAnim('danceRight$idleSuffix', forced);
			else playAnim('danceLeft$idleSuffix', forced);
		}
		else
		{
			playAnim('idle$idleSuffix', forced);
		}
	}
	
	/**
	 * Updates if the current character has a alternating `left/right` dance
	 */
	public function recalculateDanceIdle():Void
	{
		alternatingDance = hasAnim('danceLeft' + idleSuffix) && hasAnim('danceRight' + idleSuffix);
	}
	
	public function onBeatHit(beat:Int)
	{
		if (!isAnimNull() && beat % danceEveryNumBeats == 0) dance();
	}
	
	override function draw():Void
	{
		if (animateAtlas != null)
		{
			copyAtlasValues();
			animateAtlas.draw();
		}
		else
		{
			super.draw();
		}
	}
	
	inline function copyAtlasValues():Void
	{
		animateAtlas.x = x;
		animateAtlas.y = y;
		animateAtlas.shader = shader;
		animateAtlas.alpha = alpha;
		animateAtlas.visible = visible;
		animateAtlas.angle = angle;
		animateAtlas.antialiasing = antialiasing;
		animateAtlas.colorTransform = colorTransform;
		animateAtlas.color = color;
		animateAtlas.flipX = flipX;
		animateAtlas.flipY = flipY;
		
		animateAtlas.cameras = cameras;
		
		animateAtlas.scale.copyFrom(scale);
		animateAtlas.offset.copyFrom(offset);
		animateAtlas.scrollFactor.copyFrom(scrollFactor);
	}
	
	override function destroy()
	{
		onAnimationFinish.removeAll();
		onAnimationFrameChange.removeAll();
		onAnimationFinish.removeAll();
		
		super.destroy();
		
		animateAtlas = FlxDestroyUtil.destroy(animateAtlas);
	}
	
	// general functions needed for stuff
	var __prevPlayedAnimation:String = '';
	
	public inline function getAnimName():String return __prevPlayedAnimation;
	
	public inline function hasAnim(anim:String):Bool
	{
		if (animateAtlas != null) return animateAtlas.anim.exists(anim);
		else return animation.exists(anim);
	}
	
	public inline function isAnimNull():Bool
	{
		if (animateAtlas != null) return animateAtlas.anim.curAnim == null;
		else return animation.curAnim == null;
	}
	
	public inline function isAnimFinished():Bool
	{
		return isAnimNull() ? false : animateAtlas?.anim.finished ?? animation.curAnim.finished;
	}
	
	public inline function pauseAnim():Void
	{
		if (animateAtlas != null) animateAtlas.anim.pause();
		else animation.pause();
	}
	
	public inline function resumeAnim():Void
	{
		if (animateAtlas != null) animateAtlas.anim.resume();
		else animation.resume();
	}
	
	public inline function getAnimNumFrames():Int
	{
		if (isAnimNull()) return 0;
		
		return animateAtlas?.anim.numFrames ?? animation.curAnim.numFrames;
	}
	
	public var animCurFrame(get, set):Int;
	
	inline function get_animCurFrame():Int
	{
		return isAnimNull() ? 0 : animateAtlas?.anim.curAnim.curFrame ?? animation.curAnim.curFrame;
	}
	
	inline function set_animCurFrame(value:Int):Int
	{
		if (isAnimNull()) return 0;
		
		if (animateAtlas != null) return animateAtlas.anim.curAnim.curFrame = value;
		else return animation.curAnim.curFrame = value;
	}
	
	public function addAnimByPrefix(anim:String, prefix:String, fps:Int = 24, looping:Bool = true, flipX:Bool = false, flipY:Bool = false)
	{
		if (animateAtlas != null) animateAtlas.anim.addBySymbol(anim, prefix, fps, looping, flipX, flipY);
		else animation.addByPrefix(anim, prefix, fps, looping, flipX, flipY);
	}
	
	public function addAnimByIndices(anim:String, prefix:String, indices:Array<Int>, fps:Int = 24, looping:Bool = true, flipX:Bool = false, flipY:Bool = false)
	{
		if (animateAtlas != null) animateAtlas.anim.addBySymbolIndices(anim, prefix, indices, fps, looping, flipX, flipY);
		else animation.addByIndices(anim, prefix, indices, '', fps, looping, flipX, flipY);
	}
	
	public inline function removeAnim(anim:String)
	{
		if (animateAtlas != null) animateAtlas.anim.remove(anim);
		else animation.remove(anim);
	}
	
	public inline function finishAnim()
	{
		if (isAnimNull()) return;
		
		if (animateAtlas != null) animateAtlas.anim.finish();
		else animation.finish();
	}
	
	public inline function stopAnim()
	{
		if (isAnimNull()) return;
		
		if (animateAtlas != null) animateAtlas.anim.stop();
		else animation.stop();
	}
	
	override function get_width()
	{
		if (animateAtlas != null) return animateAtlas.width;
		else return super.get_width();
	}
	
	override function get_height()
	{
		if (animateAtlas != null) return animateAtlas.height;
		else return super.get_height();
	}
	
	#if FLX_DEBUG
	override function drawDebugOnCamera(camera:FlxCamera):Void
	{
		if (!camera.visible || !camera.exists) return;
		
		final isOnScreen = animateAtlas?.isOnScreen(camera) ?? isOnScreen(camera);
		
		if (!isOnScreen) return;
		
		if (animateAtlas != null)
		{
			var rect = animateAtlas.getBoundingBox(camera);
			var gfx:Graphics = animateAtlas.beginDrawDebug(camera);
			
			animateAtlas.drawDebugBoundingBox(gfx, rect, allowCollisions, immovable);
			
			animateAtlas.endDrawDebug(camera);
		}
		else
		{
			var rect = getBoundingBox(camera);
			var gfx:Graphics = beginDrawDebug(camera);
			
			drawDebugBoundingBox(gfx, rect, allowCollisions, immovable);
			
			endDrawDebug(camera);
		}
	}
	#end
}
